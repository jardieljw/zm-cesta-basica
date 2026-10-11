import datetime
import math
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status, Header
from sqlalchemy import select, func, or_, desc, asc
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.products import Product, BasketType
from app.models.movements import InventoryMovement
from app.schemas.movements import (
    MovementResponse,
    MovementListResponse,
    ProductStockSummary,
    ProductStockDetailResponse,
    StockAdjustmentCreate,
    StockAdjustmentResponse,
)
from app.services.inventory import (
    get_product_stock,
    get_basket_stock,
    get_all_products_stock_map,
    execute_stock_adjustment,
)

router = APIRouter()

@router.get("/inventory/summary", response_model=List[ProductStockSummary])
def get_inventory_summary(
    category: Optional[str] = Query(None, description="Filtrar por categoria"),
    below_minimum_only: bool = Query(False, description="Exibir apenas produtos com estoque abaixo do minimo"),
    search: Optional[str] = Query(None, description="Busca por nome, SKU ou codigo de barras"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Retorna o resumo consolidado de estoque atual de todos os produtos ativos."""
    stmt = select(Product).where(Product.is_active == True).order_by(Product.name.asc())

    if category:
        stmt = stmt.where(Product.category == category.strip().upper())
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
    stock_map = get_all_products_stock_map(db)

    results: List[ProductStockSummary] = []
    for p in products:
        stock = stock_map.get(p.id, 0)
        is_below = stock < p.minimum_stock

        if below_minimum_only and not is_below:
            continue

        results.append(
            ProductStockSummary(
                product_id=p.id,
                product_name=p.name,
                sku=p.sku,
                barcode=p.barcode,
                category=p.category,
                base_unit=p.base_unit,
                current_stock=stock,
                minimum_stock=p.minimum_stock,
                is_below_minimum=is_below,
                cost_price_cents=p.cost_price_cents,
                sale_price_cents=p.sale_price_cents,
            )
        )

    return results

@router.get("/inventory/movements", response_model=MovementListResponse)
def list_movements(
    product_id: Optional[str] = Query(None, description="Filtrar por produto"),
    basket_type_id: Optional[str] = Query(None, description="Filtrar por tipo de cesta"),
    production_batch_id: Optional[str] = Query(None, description="Filtrar por lote de producao"),
    movement_type: Optional[str] = Query(None, description="Filtrar por tipo de movimento"),
    source_type: Optional[str] = Query(None, description="Filtrar por origem do movimento"),
    start_date: Optional[datetime.datetime] = Query(None, description="Data inicial do periodo"),
    end_date: Optional[datetime.datetime] = Query(None, description="Data final do periodo"),
    page: int = Query(1, ge=1, description="Numero da pagina"),
    page_size: int = Query(50, ge=1, le=500, description="Registros por pagina"),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Extrato paginado do livro-razao contabil de estoque com filtros flexiveis."""
    base_stmt = select(InventoryMovement).options(
        selectinload(InventoryMovement.product),
        selectinload(InventoryMovement.basket_type),
    )

    count_stmt = select(func.count(InventoryMovement.id))

    filters = []
    if product_id:
        filters.append(InventoryMovement.product_id == product_id.strip())
    if basket_type_id:
        filters.append(InventoryMovement.basket_type_id == basket_type_id.strip())
    if production_batch_id:
        filters.append(InventoryMovement.production_batch_id == production_batch_id.strip())
    if movement_type:
        filters.append(InventoryMovement.movement_type == movement_type.strip().upper())
    if source_type:
        filters.append(InventoryMovement.source_type == source_type.strip().upper())
    if start_date:
        filters.append(InventoryMovement.occurred_at >= start_date)
    if end_date:
        filters.append(InventoryMovement.occurred_at <= end_date)

    if filters:
        base_stmt = base_stmt.where(*filters)
        count_stmt = count_stmt.where(*filters)

    total = db.execute(count_stmt).scalar_one()

    offset = (page - 1) * page_size
    query_stmt = (
        base_stmt.order_by(desc(InventoryMovement.occurred_at), desc(InventoryMovement.id))
        .offset(offset)
        .limit(page_size)
    )

    movements = db.execute(query_stmt).scalars().all()

    items = [
        MovementResponse(
            id=m.id,
            item_type=m.item_type,
            product_id=m.product_id,
            product_name=m.product.name if m.product else None,
            basket_type_id=m.basket_type_id,
            basket_type_name=m.basket_type.name if m.basket_type else None,
            production_batch_id=m.production_batch_id,
            movement_type=m.movement_type,
            quantity_delta=m.quantity_delta,
            source_type=m.source_type,
            source_id=m.source_id,
            reversal_of_id=m.reversal_of_id,
            occurred_at=m.occurred_at,
            reason=m.reason,
            running_balance=None,
        )
        for m in movements
    ]

    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return MovementListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )

@router.get("/inventory/products/{product_id}/stock", response_model=ProductStockDetailResponse)
def get_product_stock_detail(
    product_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Consulta o saldo atual em estoque de um produto especifico."""
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    stock = get_product_stock(db, product_id)
    return ProductStockDetailResponse(
        product_id=product.id,
        product_name=product.name,
        sku=product.sku,
        category=product.category,
        base_unit=product.base_unit,
        current_stock=stock,
        minimum_stock=product.minimum_stock,
        is_below_minimum=stock < product.minimum_stock,
        cost_price_cents=product.cost_price_cents,
        sale_price_cents=product.sale_price_cents,
    )

@router.get("/inventory/baskets/{basket_type_id}/stock")
def get_basket_stock_detail(
    basket_type_id: str,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Consulta o saldo atual em estoque de uma cesta padrao acabada."""
    basket = db.get(BasketType, basket_type_id)
    if not basket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cesta '{basket_type_id}' nao encontrada.",
        )

    stock = get_basket_stock(db, basket_type_id)
    return {
        "basket_type_id": basket.id,
        "basket_code": basket.code,
        "basket_name": basket.name,
        "current_stock": stock,
        "tracks_finished_stock": basket.tracks_finished_stock,
        "default_price_cents": basket.default_price_cents,
    }

@router.get("/inventory/products/{product_id}/movements", response_model=List[MovementResponse])
def get_product_movements_ledger(
    product_id: str,
    movement_type: Optional[str] = Query(None, description="Filtrar por tipo de movimento"),
    start_date: Optional[datetime.datetime] = Query(None),
    end_date: Optional[datetime.datetime] = Query(None),
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
):
    """Extrato contabil cronologico de um produto com calculo de saldo progressivo fiel."""
    product = db.get(Product, product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Produto '{product_id}' nao encontrado.",
        )

    stmt = (
        select(InventoryMovement)
        .options(selectinload(InventoryMovement.product))
        .where(
            InventoryMovement.product_id == product_id,
            InventoryMovement.basket_type_id.is_(None),
        )
    )

    if movement_type:
        stmt = stmt.where(InventoryMovement.movement_type == movement_type.strip().upper())
    if start_date:
        stmt = stmt.where(InventoryMovement.occurred_at >= start_date)
    if end_date:
        stmt = stmt.where(InventoryMovement.occurred_at <= end_date)

    stmt = stmt.order_by(asc(InventoryMovement.occurred_at), asc(InventoryMovement.id))
    movements = db.execute(stmt).scalars().all()

    # Calculate cumulative prior balance before start_date if date window is applied
    prior_balance = 0
    if start_date:
        prior_stmt = select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).where(
            InventoryMovement.product_id == product_id,
            InventoryMovement.basket_type_id.is_(None),
            InventoryMovement.occurred_at < start_date,
        )
        prior_balance = int(db.execute(prior_stmt).scalar_one() or 0)

    running = prior_balance
    results: List[MovementResponse] = []
    for m in movements:
        running += m.quantity_delta
        results.append(
            MovementResponse(
                id=m.id,
                item_type=m.item_type,
                product_id=m.product_id,
                product_name=product.name,
                basket_type_id=None,
                basket_type_name=None,
                production_batch_id=m.production_batch_id,
                movement_type=m.movement_type,
                quantity_delta=m.quantity_delta,
                source_type=m.source_type,
                source_id=m.source_id,
                reversal_of_id=m.reversal_of_id,
                occurred_at=m.occurred_at,
                reason=m.reason,
                running_balance=running,
            )
        )

    # Return newest first with accurate running balances
    results.reverse()
    return results

@router.post(
    "/inventory/adjustments",
    response_model=StockAdjustmentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_stock_adjustment(
    data: StockAdjustmentCreate,
    db: Session = Depends(get_db),
    current_device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra um ajuste manual de estoque com auditoria estrita.
    Suporta operacoes de entrada (IN), saida/avaria (OUT), perda (LOSS) e balanço/contagem fisica (COUNT).
    Protegido por chave de idempotencia X-Idempotency-Key.
    """
    def _execute(session: Session):
        resp = execute_stock_adjustment(session, data)
        return status.HTTP_201_CREATED, resp.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="ADJUSTMENTS",
        payload=data.model_dump(mode="json"),
        business_callback=_execute,
    )

    data_dict = result.to_json_dict()
    return data_dict
