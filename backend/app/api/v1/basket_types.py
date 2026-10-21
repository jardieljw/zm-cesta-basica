import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, or_, func
from sqlalchemy.orm import Session, selectinload
from app.core.database import get_db
from app.api.deps import get_current_device, get_idempotency_key
from app.core.idempotency import process_transactional_idempotency
from fastapi.responses import JSONResponse
from app.services.basket_catalog import check_basket_deletion, delete_basket_from_catalog, require_catalog_entry
from app.schemas.recipes import BasketDeletionCheck, BasketDeletionResponse
from app.models.auth import PairedDevice
from app.models.products import Product, BasketType, RecipeVersion, RecipeItem
from app.models.base import utc_now
from app.services.basket_stock_policy import validate_disable_finished_stock
from app.schemas.recipes import (
    BasketTypeCreate,
    BasketTypeUpdate,
    BasketTypeResponse,
    BasketTypeInactivationResponse,
    RecipeVersionCreate,
    RecipeVersionResponse,
    RecipeItemResponse,
)

router = APIRouter()


def _format_recipe_version_response(recipe: RecipeVersion) -> RecipeVersionResponse:
    item_responses = []
    sorted_items = sorted(recipe.items, key=lambda it: (it.section, it.product.name if it.product else ""))
    for item in sorted_items:
        prod_name = item.product.name if item.product else None
        prod_cat = item.product.category if item.product else None
        prod_unit = item.product.base_unit if item.product else None
        item_responses.append(
            RecipeItemResponse(
                id=item.id,
                recipe_version_id=item.recipe_version_id,
                product_id=item.product_id,
                product_name=prod_name,
                product_category=prod_cat,
                product_base_unit=prod_unit,
                quantity_in_base_units=item.quantity_in_base_units,
                section=item.section,
                is_required=item.is_required,
            )
        )
    from sqlalchemy.orm import object_session
    from app.services.recipe_lifecycle import check_recipe
    check = check_recipe(object_session(recipe), recipe)
    return RecipeVersionResponse(
        **check,
        id=recipe.id,
        basket_type_id=recipe.basket_type_id,
        version_number=recipe.version_number,
        status=recipe.status,
        created_at=recipe.created_at,
        notes=recipe.notes,
        items=item_responses,
        suggested_price_cents=recipe.suggested_price_cents,
    )


@router.get('/basket-types/{basket_type_id}/deletion-check', response_model=BasketDeletionCheck)
def basket_deletion_check(basket_type_id: str, db: Session = Depends(get_db),
                          current_device: PairedDevice = Depends(get_current_device)):
    return check_basket_deletion(db, basket_type_id)


@router.delete('/basket-types/{basket_type_id}/catalog', response_model=BasketDeletionResponse)
def remove_basket_from_catalog(basket_type_id: str, db: Session = Depends(get_db),
                               current_device: PairedDevice = Depends(get_current_device),
                               idempotency_key: Optional[str] = Depends(get_idempotency_key)):
    def callback(session):
        response = delete_basket_from_catalog(session, basket_type_id)
        return status.HTTP_200_OK, response.model_dump(mode='json')
    result = process_transactional_idempotency(db, idempotency_key, 'BASKET_CATALOG_DELETE',
                                              {'basket_type_id': basket_type_id}, callback)
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


# --- TIPOS DE CESTAS ---

@router.get("/basket-types", response_model=List[BasketTypeResponse])
def list_basket_types(
    category: Optional[str] = Query(None, description="Filtrar por categoria"),
    is_active: Optional[bool] = Query(None, description="Filtrar por status ativo/inativo"),
    search: Optional[str] = Query(None, description="Busca por nome ou codigo"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista todos os tipos de cestas com indicacao da receita ativa."""
    stmt = (
        select(BasketType)
        .options(
            selectinload(BasketType.recipes)
            .selectinload(RecipeVersion.items)
            .selectinload(RecipeItem.product)
        )
        .where(BasketType.removed_at.is_(None))
        .order_by(BasketType.name.asc())
    )

    if category:
        stmt = stmt.where(BasketType.category == category.strip().upper())
    if is_active is not None:
        stmt = stmt.where(BasketType.is_active == is_active)
    if search:
        search_term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                BasketType.name.ilike(search_term),
                BasketType.code.ilike(search_term),
            )
        )

    basket_types = db.execute(stmt).scalars().all()
    results = []
    for bt in basket_types:
        active_rec = next((r for r in bt.recipes if r.status == "ACTIVE"), None)
        active_rec_resp = _format_recipe_version_response(active_rec) if active_rec else None

        results.append(
            BasketTypeResponse(
                id=bt.id,
                code=bt.code,
                name=bt.name,
                description=bt.description,
                category=bt.category,
                default_price_cents=bt.default_price_cents,
                allows_customization=bt.allows_customization,
                tracks_finished_stock=bt.tracks_finished_stock,
                is_active=bt.is_active,
                removed_at=bt.removed_at,
                active_recipe=active_rec_resp,
            )
        )
    return results


@router.post("/basket-types", response_model=BasketTypeResponse, status_code=status.HTTP_201_CREATED)
def create_basket_type(
    data: BasketTypeCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Cadastra um novo tipo de cesta comercial."""
    existing_code = db.execute(
        select(BasketType).where(BasketType.code == data.code.strip().upper())
    ).scalar_one_or_none()

    if existing_code:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ja existe um tipo de cesta cadastrado com o codigo '{data.code}'.",
        )

    new_basket_type = BasketType(
        id=str(uuid.uuid4()),
        code=data.code.strip().upper(),
        name=data.name.strip(),
        description=data.description,
        category=data.category.strip().upper(),
        default_price_cents=data.default_price_cents,
        allows_customization=data.allows_customization,
        tracks_finished_stock=data.tracks_finished_stock,
        is_active=data.is_active,
    )

    db.add(new_basket_type)
    db.commit()
    db.refresh(new_basket_type)

    return BasketTypeResponse(
        id=new_basket_type.id,
        code=new_basket_type.code,
        name=new_basket_type.name,
        description=new_basket_type.description,
        category=new_basket_type.category,
        default_price_cents=new_basket_type.default_price_cents,
        allows_customization=new_basket_type.allows_customization,
        tracks_finished_stock=new_basket_type.tracks_finished_stock,
        is_active=new_basket_type.is_active,
        active_recipe=None,
    )


@router.get("/basket-types/{basket_type_id}", response_model=BasketTypeResponse)
def get_basket_type(
    basket_type_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Obtem informacoes detalhadas de um tipo de cesta, incluindo a receita ativa."""
    bt = db.execute(
        select(BasketType)
        .options(
            selectinload(BasketType.recipes)
            .selectinload(RecipeVersion.items)
            .selectinload(RecipeItem.product)
        )
        .where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    active_rec = next((r for r in bt.recipes if r.status == "ACTIVE"), None)
    active_rec_resp = _format_recipe_version_response(active_rec) if active_rec else None

    return BasketTypeResponse(
        id=bt.id,
        code=bt.code,
        name=bt.name,
        description=bt.description,
        category=bt.category,
        default_price_cents=bt.default_price_cents,
        allows_customization=bt.allows_customization,
        tracks_finished_stock=bt.tracks_finished_stock,
        is_active=bt.is_active,
        removed_at=bt.removed_at,
        active_recipe=active_rec_resp,
    )


@router.put("/basket-types/{basket_type_id}", response_model=BasketTypeResponse)
def update_basket_type(
    basket_type_id: str,
    data: BasketTypeUpdate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Atualiza as propriedades comerciais de um tipo de cesta."""
    bt = db.execute(
        select(BasketType)
        .options(
            selectinload(BasketType.recipes)
            .selectinload(RecipeVersion.items)
            .selectinload(RecipeItem.product)
        )
        .where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    require_catalog_entry(bt)
    fields_set = data.model_fields_set

    if data.tracks_finished_stock is False:
        validate_disable_finished_stock(db, bt)

    if "name" in fields_set and data.name is not None:
        bt.name = data.name.strip()
    if "description" in fields_set:
        bt.description = data.description.strip() if data.description and data.description.strip() else None
    if "category" in fields_set and data.category is not None:
        bt.category = data.category.strip().upper()
    if "default_price_cents" in fields_set and data.default_price_cents is not None:
        bt.default_price_cents = data.default_price_cents
    if "allows_customization" in fields_set and data.allows_customization is not None:
        bt.allows_customization = data.allows_customization
    if "tracks_finished_stock" in fields_set and data.tracks_finished_stock is not None:
        bt.tracks_finished_stock = data.tracks_finished_stock
    if "is_active" in fields_set and data.is_active is not None:
        bt.is_active = data.is_active

    db.commit()
    db.refresh(bt)

    active_rec = next((r for r in bt.recipes if r.status == "ACTIVE"), None)
    active_rec_resp = _format_recipe_version_response(active_rec) if active_rec else None

    return BasketTypeResponse(
        id=bt.id,
        code=bt.code,
        name=bt.name,
        description=bt.description,
        category=bt.category,
        default_price_cents=bt.default_price_cents,
        allows_customization=bt.allows_customization,
        tracks_finished_stock=bt.tracks_finished_stock,
        is_active=bt.is_active,
        removed_at=bt.removed_at,
        active_recipe=active_rec_resp,
    )


@router.delete("/basket-types/{basket_type_id}", response_model=BasketTypeInactivationResponse)
def inactivate_basket_type(
    basket_type_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """
    Inativa (soft delete) um tipo de cesta.
    A exclusao fisica e proibida para preservar historico de vendas e montagens.
    """
    bt = db.execute(
        select(BasketType).where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    require_catalog_entry(bt)
    bt.is_active = False
    db.commit()

    return BasketTypeInactivationResponse(
        id=bt.id,
        code=bt.code,
        name=bt.name,
        is_active=False,
        message="Tipo de cesta inativado com sucesso. A exclusao fisica e proibida para preservar o historico transacional.",
    )


# --- VERSIONAMENTO IMUTAVEL DE RECEITAS PADRAO ---

@router.get("/basket-types/{basket_type_id}/recipes", response_model=List[RecipeVersionResponse])
def list_recipe_versions(
    basket_type_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lista todas as versoes historicas e ativas de receitas para um tipo de cesta."""
    bt = db.execute(
        select(BasketType).where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    recipes = db.execute(
        select(RecipeVersion)
        .options(
            selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
        )
        .where(RecipeVersion.basket_type_id == basket_type_id, RecipeVersion.status != "REMOVED")
        .order_by(RecipeVersion.version_number.desc())
    ).scalars().all()

    return [_format_recipe_version_response(r) for r in recipes]


@router.get("/basket-types/{basket_type_id}/recipes/active", response_model=RecipeVersionResponse)
def get_active_recipe_version(
    basket_type_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Obtem a versao de receita atualmente ATIVA de um tipo de cesta."""
    bt = db.execute(
        select(BasketType).where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    recipe = db.execute(
        select(RecipeVersion)
        .options(
            selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
        )
        .where(
            RecipeVersion.basket_type_id == basket_type_id,
            RecipeVersion.status == "ACTIVE",
        )
    ).scalar_one_or_none()

    if not recipe:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Nenhuma receita ativa encontrada para o tipo de cesta '{bt.name}'.",
        )

    return _format_recipe_version_response(recipe)


@router.get("/basket-types/{basket_type_id}/recipes/{version_number}", response_model=RecipeVersionResponse)
def get_recipe_version_by_number(
    basket_type_id: str,
    version_number: int,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Obtem uma versao historica especifica de receita por seu numero."""
    recipe = db.execute(
        select(RecipeVersion)
        .options(
            selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
        )
        .where(
            RecipeVersion.basket_type_id == basket_type_id,
            RecipeVersion.version_number == version_number,
        )
    ).scalar_one_or_none()

    if not recipe:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Versao de receita {version_number} nao encontrada para a cesta informada.",
        )

    return _format_recipe_version_response(recipe)


@router.post("/basket-types/{basket_type_id}/recipes", response_model=RecipeVersionResponse, status_code=status.HTTP_201_CREATED)
def create_recipe_version(
    basket_type_id: str, data: RecipeVersionCreate,
    db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    def callback(session):
        recipe = _create_recipe_version(basket_type_id, data, session)
        return 201, recipe.model_dump(mode='json')
    result = process_transactional_idempotency(db, idempotency_key, 'RECIPE_CREATE',
        dict(basket_type_id=basket_type_id, **data.model_dump(mode='json')), callback)
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())

def _create_recipe_version(basket_type_id, data, db):
    """
    Cria uma nova versao de receita para o tipo de cesta.
    Regras estritas de integridade:
    1. A versao criada torna-se ACTIVE e qualquer versao ativa anterior e arquivada como ARCHIVED.
    2. Versoes anteriores sao imutaveis.
    3. Todos os insumos devem existir e estar ATIVOS no sistema.
    4. Cada item deve ter quantidade > 0.
    5. Proibida duplicidade do mesmo produto na mesma receita.
    """
    bt = db.execute(
        select(BasketType).where(BasketType.id == basket_type_id)
    ).scalar_one_or_none()

    if not bt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tipo de cesta '{basket_type_id}' nao encontrado.",
        )

    require_catalog_entry(bt)

    if not bt.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel criar receita para o tipo de cesta '{bt.name}', pois ele esta inativo.",
        )

    if not data.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A receita deve conter ao menos 1 item/insumo.",
        )

    # Validar unicidade dos produtos na receita
    seen_products = set()
    for item in data.items:
        if item.product_id in seen_products:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"O produto ID '{item.product_id}' foi adicionado mais de uma vez na receita. Consolide as quantidades em um unico item.",
            )
        seen_products.add(item.product_id)

        if item.quantity_in_base_units <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"A quantidade do item ID '{item.product_id}' deve ser estritamente positiva (> 0).",
            )

    # Validar se todos os insumos existem e estao ATIVOS
    products_stmt = select(Product).where(Product.id.in_(list(seen_products)))
    products = {p.id: p for p in db.execute(products_stmt).scalars().all()}

    for pid in seen_products:
        if pid not in products:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Produto/Insumo com ID '{pid}' nao foi encontrado no sistema.",
            )
        p = products[pid]
        if not p.is_active or p.removed_at is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"O insumo '{p.name}' (ID: {p.id}) esta INATIVO no sistema e nao pode ser utilizado em novas receitas.",
            )

    # Obter a versao atual mais alta
    max_ver = db.execute(
        select(func.max(RecipeVersion.version_number)).where(
            RecipeVersion.basket_type_id == basket_type_id
        )
    ).scalar_one_or_none()

    next_version_number = (max_ver or 0) + 1

    # Arquivar versao ativa atual
    current_active = db.execute(
        select(RecipeVersion).where(
            RecipeVersion.basket_type_id == basket_type_id,
            RecipeVersion.status == "ACTIVE",
        )
    ).scalar_one_or_none()

    if current_active:
        current_active.status = "ARCHIVED"

    # Criar nova versao
    new_version = RecipeVersion(
        id=str(uuid.uuid4()),
        basket_type_id=basket_type_id,
        version_number=next_version_number,
        status="ACTIVE",
        created_at=utc_now(),
        notes=data.notes,
        suggested_price_cents=data.suggested_price_cents,
    )
    db.add(new_version)
    db.flush()

    # Adicionar itens da receita
    for item_data in data.items:
        recipe_item = RecipeItem(
            id=str(uuid.uuid4()),
            recipe_version_id=new_version.id,
            product_id=item_data.product_id,
            quantity_in_base_units=item_data.quantity_in_base_units,
            section=item_data.section.strip().upper(),
            is_required=item_data.is_required,
        )
        db.add(recipe_item)

    db.flush()

    # Recarregar receita com os relacionamentos completos
    loaded_recipe = db.execute(
        select(RecipeVersion)
        .options(
            selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
        )
        .where(RecipeVersion.id == new_version.id)
    ).scalar_one()

    return _format_recipe_version_response(loaded_recipe)



# Recipe actions revalidate dependencies inside the same write transaction.
from app.services.recipe_lifecycle import get_recipe, check_recipe, mutate_recipe

@router.get('/basket-types/{basket_type_id}/recipes/{version_number}/deletion-check')
def recipe_deletion_check(basket_type_id: str, version_number: int,
        db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device)):
    return check_recipe(db, get_recipe(db, basket_type_id, version_number))

def _recipe_action(db, key, basket_id, number, action, data=None):
    def callback(session):
        value = mutate_recipe(session, basket_id, number, action, data)
        result = value if isinstance(value, dict) else _format_recipe_version_response(value).model_dump(mode='json')
        return 200, result
    result = process_transactional_idempotency(db, key, 'RECIPE_' + action.upper(),
        dict(basket_id=basket_id, number=number, data=data.model_dump(mode='json') if data else None), callback)
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())

@router.put('/basket-types/{basket_type_id}/recipes/{version_number}')
def update_recipe(basket_type_id: str, version_number: int, data: RecipeVersionCreate,
        db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device),
        idempotency_key: Optional[str] = Depends(get_idempotency_key)):
    return _recipe_action(db, idempotency_key, basket_type_id, version_number, 'edit', data)

@router.delete('/basket-types/{basket_type_id}/recipes/{version_number}')
def delete_recipe(basket_type_id: str, version_number: int,
        db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device),
        idempotency_key: Optional[str] = Depends(get_idempotency_key)):
    return _recipe_action(db, idempotency_key, basket_type_id, version_number, 'remove')

@router.post('/basket-types/{basket_type_id}/recipes/{version_number}/activate')
def activate_recipe(basket_type_id: str, version_number: int,
        db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device),
        idempotency_key: Optional[str] = Depends(get_idempotency_key)):
    return _recipe_action(db, idempotency_key, basket_type_id, version_number, 'activate')

@router.post('/basket-types/{basket_type_id}/recipes/{version_number}/deactivate')
def deactivate_recipe(basket_type_id: str, version_number: int,
        db: Session = Depends(get_db), current_device: PairedDevice = Depends(get_current_device),
        idempotency_key: Optional[str] = Depends(get_idempotency_key)):
    return _recipe_action(db, idempotency_key, basket_type_id, version_number, 'deactivate')
