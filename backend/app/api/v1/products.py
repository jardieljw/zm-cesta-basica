import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, or_
from sqlalchemy.orm import Session, selectinload
from app.core.database import get_db
from app.api.deps import get_current_device, get_idempotency_key
from app.core.idempotency import process_transactional_idempotency
from fastapi.responses import JSONResponse
from app.services.product_catalog import check_product_deletion, delete_unused_product
from app.models.auth import PairedDevice
from app.models.products import Product, ProductPackaging, BasketType, RecipeVersion, RecipeItem
from app.models.base import utc_now
from app.schemas.products import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    ProductInactivationResponse,
    ProductDeletionCheck,
    ProductDeletionResponse,
)
from app.schemas.packagings import (
    PackagingCreate,
    PackagingUpdate,
    PackagingResponse,
)

router = APIRouter()


@router.get("/products/{product_id}/deletion-check", response_model=ProductDeletionCheck)
def product_deletion_check(
    product_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    return check_product_deletion(db, product_id)


@router.delete("/products/{product_id}/permanent", response_model=ProductDeletionResponse)
def permanently_delete_unused_product(
    product_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    def callback(session):
        response = delete_unused_product(session, product_id)
        return status.HTTP_200_OK, response.model_dump(mode="json")

    result = process_transactional_idempotency(
        db, idempotency_key, "PRODUCT_PERMANENT_DELETE", {"product_id": product_id}, callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())

# --- PRODUTOS E INSUMOS ---

@router.get("/products", response_model=List[ProductResponse])
def list_products(
    category: Optional[str] = Query(None, description="Filtrar por categoria"),
    is_active: Optional[bool] = Query(None, description="Filtrar por status ativo/inativo"),
    search: Optional[str] = Query(None, description="Busca por nome, SKU ou codigo de barras"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista todos os produtos e insumos cadastrados com filtros opcionais."""
    stmt = select(Product).options(selectinload(Product.packagings)).where(Product.removed_at.is_(None)).order_by(Product.name.asc())

    if category:
        stmt = stmt.where(Product.category == category.strip().upper())
    if is_active is not None:
        stmt = stmt.where(Product.is_active == is_active)
    if search:
        search_term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Product.name.ilike(search_term),
                Product.sku.ilike(search_term),
                Product.barcode.ilike(search_term),
            )
        )

    products = db.execute(stmt).scalars().all()
    return products


@router.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    data: ProductCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Cadastra um novo produto ou insumo no sistema."""
    # Validar unicidade de SKU se informado
    if data.sku:
        existing_sku = db.execute(
            select(Product).where(Product.sku == data.sku.strip())
        ).scalar_one_or_none()
        if existing_sku:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Ja existe um produto cadastrado com o SKU '{data.sku}'.",
            )

    # Validar unicidade de Barcode se informado
    if data.barcode:
        existing_barcode = db.execute(
            select(Product).where(Product.barcode == data.barcode.strip())
        ).scalar_one_or_none()
        if existing_barcode:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Ja existe um produto cadastrado com o codigo de barras '{data.barcode}'.",
            )

    new_product = Product(
        id=str(uuid.uuid4()),
        name=data.name.strip(),
        sku=data.sku.strip() if data.sku else None,
        barcode=data.barcode.strip() if data.barcode else None,
        category=data.category.strip().upper(),
        base_unit=data.base_unit.strip().upper(),
        minimum_stock=data.minimum_stock,
        cost_price_cents=data.cost_price_cents,
        cost_price_microcents=data.cost_price_microcents if data.cost_price_microcents > 0 else (data.cost_price_cents * 10000),
        sale_price_cents=data.sale_price_cents,
        notes=data.notes,
        is_active=data.is_active,
        created_at=utc_now(),
        updated_at=utc_now(),
    )

    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product


@router.get("/products/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Obtem os dados detalhados de um produto por ID."""
    product = db.execute(
        select(Product).options(selectinload(Product.packagings)).where(Product.id == product_id)
    ).scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )
    return product


@router.put("/products/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: str,
    data: ProductUpdate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Atualiza as informacoes cadastrais de um produto."""
    product = db.execute(
        select(Product).options(selectinload(Product.packagings)).where(Product.id == product_id)
    ).scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    if product.removed_at is not None:
        raise HTTPException(409, detail={"error_code": "PRODUCT_REMOVED", "message": "Este produto foi excluído do catálogo."})
    fields_set = data.model_fields_set

    # Validar e atualizar SKU (permite limpar com null/vazio)
    if "sku" in fields_set:
        norm_sku = data.sku.strip() if data.sku and data.sku.strip() else None
        if norm_sku != product.sku:
            if norm_sku is not None:
                existing_sku = db.execute(
                    select(Product).where(Product.sku == norm_sku, Product.id != product_id)
                ).scalar_one_or_none()
                if existing_sku:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Ja existe outro produto cadastrado com o SKU '{norm_sku}'.",
                    )
            product.sku = norm_sku

    # Validar e atualizar Barcode (permite limpar com null/vazio)
    if "barcode" in fields_set:
        norm_barcode = data.barcode.strip() if data.barcode and data.barcode.strip() else None
        if norm_barcode != product.barcode:
            if norm_barcode is not None:
                existing_barcode = db.execute(
                    select(Product).where(Product.barcode == norm_barcode, Product.id != product_id)
                ).scalar_one_or_none()
                if existing_barcode:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Ja existe outro produto cadastrado com o codigo de barras '{norm_barcode}'.",
                    )
            product.barcode = norm_barcode

    if "name" in fields_set and data.name is not None:
        product.name = data.name.strip()
    if "category" in fields_set and data.category is not None:
        product.category = data.category.strip().upper()

    if "base_unit" in fields_set and data.base_unit is not None:
        norm_unit = data.base_unit.strip().upper()
        if norm_unit != product.base_unit:
            has_packagings = db.execute(
                select(ProductPackaging.id).where(ProductPackaging.product_id == product_id)
            ).first() is not None
            has_recipes = db.execute(
                select(RecipeItem.id).where(RecipeItem.product_id == product_id)
            ).first() is not None
            if has_packagings or has_recipes:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Nao e possivel alterar a unidade-base de um produto que ja possui embalagens comerciais ou receitas vinculadas. Inative o produto e cadastre um novo para evitar distorcao de conversoes historicas.",
                )
            product.base_unit = norm_unit

    if "minimum_stock" in fields_set and data.minimum_stock is not None:
        product.minimum_stock = data.minimum_stock
    if "cost_price_cents" in fields_set and data.cost_price_cents is not None:
        product.cost_price_cents = data.cost_price_cents
        if "cost_price_microcents" not in fields_set or data.cost_price_microcents is None:
            product.cost_price_microcents = data.cost_price_cents * 10000
    if "cost_price_microcents" in fields_set and data.cost_price_microcents is not None:
        product.cost_price_microcents = data.cost_price_microcents
    if "sale_price_cents" in fields_set and data.sale_price_cents is not None:
        product.sale_price_cents = data.sale_price_cents
    if "notes" in fields_set:
        product.notes = data.notes.strip() if data.notes and data.notes.strip() else None

    if "is_active" in fields_set and data.is_active is not None:
        if data.is_active is False and product.is_active is True:
            # Verifica se esta em uso na receita ativa de cestas ativas
            active_baskets = db.execute(
                select(BasketType.name)
                .join(RecipeVersion, RecipeVersion.basket_type_id == BasketType.id)
                .join(RecipeItem, RecipeItem.recipe_version_id == RecipeVersion.id)
                .where(
                    RecipeItem.product_id == product_id,
                    RecipeVersion.status == "ACTIVE",
                    BasketType.is_active == True,
                )
            ).scalars().all()
            if active_baskets:
                baskets_str = ", ".join(f"'{n}'" for n in sorted(set(active_baskets)))
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Nao e possivel inativar o produto '{product.name}' pois ele esta em uso na receita ativa de: {baskets_str}. Crie uma nova versao de receita sem este produto antes de inativa-lo.",
                )
            for pkg in product.packagings:
                pkg.is_active = False
                pkg.is_default = False
        product.is_active = data.is_active

    product.updated_at = utc_now()
    db.commit()
    db.refresh(product)
    return product


@router.delete("/products/{product_id}", response_model=ProductInactivationResponse)
def inactivate_product(
    product_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """
    Inativa (soft delete) um produto.
    Preserva vínculos e histórico. Exclusão definitiva de produtos nunca usados
    existe em /products/{product_id}/permanent.
    Rejeita a inativacao se o produto estiver em uso na receita ativa de qualquer cesta ativa.
    """
    product = db.execute(
        select(Product).options(selectinload(Product.packagings)).where(Product.id == product_id)
    ).scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    # Verifica se esta em uso na receita ativa de cestas ativas
    active_baskets = db.execute(
        select(BasketType.name)
        .join(RecipeVersion, RecipeVersion.basket_type_id == BasketType.id)
        .join(RecipeItem, RecipeItem.recipe_version_id == RecipeVersion.id)
        .where(
            RecipeItem.product_id == product_id,
            RecipeVersion.status == "ACTIVE",
            BasketType.is_active == True,
        )
    ).scalars().all()

    if active_baskets:
        baskets_str = ", ".join(f"'{n}'" for n in sorted(set(active_baskets)))
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Nao e possivel inativar o produto '{product.name}' pois ele esta em uso na receita ativa de: {baskets_str}. Crie uma nova versao de receita sem este produto antes de inativa-lo.",
        )

    product.is_active = False
    for pkg in product.packagings:
        pkg.is_active = False
        pkg.is_default = False
    product.updated_at = utc_now()
    db.commit()

    return ProductInactivationResponse(
        id=product.id,
        name=product.name,
        is_active=False,
        message="Produto inativado com sucesso. O cadastro e seu histórico foram preservados.",
    )


# --- EMBALAGENS E FATORES DE CONVERSAO ---

@router.get("/products/{product_id}/packagings", response_model=List[PackagingResponse])
def list_packagings(
    product_id: str,
    is_active: Optional[bool] = Query(None, description="Filtrar por status ativo/inativo"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista as embalagens comerciais cadastradas para um produto especifico."""
    product = db.execute(
        select(Product).where(Product.id == product_id)
    ).scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    stmt = (
        select(ProductPackaging)
        .where(ProductPackaging.product_id == product_id)
        .order_by(ProductPackaging.is_default.desc(), ProductPackaging.name.asc())
    )
    if is_active is not None:
        stmt = stmt.where(ProductPackaging.is_active == is_active)

    packagings = db.execute(stmt).scalars().all()
    return packagings


@router.post("/products/{product_id}/packagings", response_model=PackagingResponse, status_code=status.HTTP_201_CREATED)
def create_packaging(
    product_id: str,
    data: PackagingCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Cadastra uma nova embalagem comercial com fator de conversao estrito para o produto."""
    product = db.execute(
        select(Product).where(Product.id == product_id)
    ).scalar_one_or_none()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    if not product.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel cadastrar embalagens comerciais para o produto '{product.name}', pois ele esta inativo.",
        )

    if data.quantity_in_base_units <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O fator de conversao da embalagem para a unidade base deve ser estritamente positivo (> 0).",
        )

    if data.is_default and not data.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uma embalagem inativa nao pode ser definida como embalagem padrao de compra.",
        )

    # Se a nova embalagem for padrao, remove a marcacao padrao das outras embalagens deste produto
    if data.is_default:
        sibling_packagings = db.execute(
            select(ProductPackaging).where(ProductPackaging.product_id == product_id)
        ).scalars().all()
        for p in sibling_packagings:
            p.is_default = False

    new_packaging = ProductPackaging(
        id=str(uuid.uuid4()),
        product_id=product_id,
        name=data.name.strip(),
        quantity_in_base_units=data.quantity_in_base_units,
        is_default=data.is_default,
        is_active=data.is_active,
    )

    db.add(new_packaging)
    db.commit()
    db.refresh(new_packaging)
    return new_packaging


@router.put("/packagings/{packaging_id}", response_model=PackagingResponse)
def update_packaging(
    packaging_id: str,
    data: PackagingUpdate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Atualiza uma embalagem comercial existente."""
    packaging = db.execute(
        select(ProductPackaging).where(ProductPackaging.id == packaging_id)
    ).scalar_one_or_none()

    if not packaging:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Embalagem '{packaging_id}' nao encontrada.",
        )

    fields_set = data.model_fields_set

    if "quantity_in_base_units" in fields_set and data.quantity_in_base_units is not None:
        if data.quantity_in_base_units <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O fator de conversao da embalagem para a unidade base deve ser estritamente positivo (> 0).",
            )
        packaging.quantity_in_base_units = data.quantity_in_base_units

    if "name" in fields_set and data.name is not None:
        packaging.name = data.name.strip()

    target_active = data.is_active if "is_active" in fields_set and data.is_active is not None else packaging.is_active
    target_default = data.is_default if "is_default" in fields_set and data.is_default is not None else packaging.is_default

    if target_default and not target_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uma embalagem inativa nao pode ser definida como embalagem padrao de compra.",
        )

    if "is_active" in fields_set and data.is_active is not None:
        packaging.is_active = data.is_active
        if not packaging.is_active:
            packaging.is_default = False

    if "is_default" in fields_set and data.is_default is not None:
        if data.is_default and packaging.is_active:
            sibling_packagings = db.execute(
                select(ProductPackaging).where(
                    ProductPackaging.product_id == packaging.product_id,
                    ProductPackaging.id != packaging_id,
                )
            ).scalars().all()
            for p in sibling_packagings:
                p.is_default = False
            packaging.is_default = True
        elif not data.is_default:
            packaging.is_default = False

    db.commit()
    db.refresh(packaging)
    return packaging


@router.delete("/packagings/{packaging_id}", response_model=PackagingResponse)
def inactivate_packaging(
    packaging_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Inativa (soft delete) uma embalagem comercial existente e remove sua condicao de padrao."""
    packaging = db.execute(
        select(ProductPackaging).where(ProductPackaging.id == packaging_id)
    ).scalar_one_or_none()

    if not packaging:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Embalagem '{packaging_id}' nao encontrada.",
        )

    packaging.is_active = False
    packaging.is_default = False
    db.commit()
    db.refresh(packaging)
    return packaging
