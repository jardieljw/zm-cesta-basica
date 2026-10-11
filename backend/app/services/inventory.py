import uuid
import datetime
from typing import Optional, Dict, List, Tuple
from sqlalchemy import select, func, and_
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.movements import InventoryMovement
from app.models.products import Product, BasketType
from app.models.base import utc_now
from app.schemas.movements import StockAdjustmentCreate, StockAdjustmentResponse

def get_product_stock(db: Session, product_id: str) -> int:
    """Calculates live on-hand stock for a product from the append-only ledger."""
    stmt = select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).where(
        InventoryMovement.product_id == product_id,
        InventoryMovement.basket_type_id.is_(None),
    )
    return int(db.execute(stmt).scalar_one() or 0)

def get_basket_stock(db: Session, basket_type_id: str) -> int:
    """Calculates live finished stock for a standard basket type."""
    stmt = select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).where(
        InventoryMovement.basket_type_id == basket_type_id,
        InventoryMovement.production_batch_id.is_(None),
    )
    return int(db.execute(stmt).scalar_one() or 0)

def get_batch_stock(db: Session, production_batch_id: str) -> int:
    """Calculates live stock for a custom production batch."""
    stmt = select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).where(
        InventoryMovement.production_batch_id == production_batch_id,
        InventoryMovement.basket_type_id.is_not(None),
    )
    return int(db.execute(stmt).scalar_one() or 0)

def get_all_products_stock_map(db: Session) -> Dict[str, int]:
    """Returns a dictionary mapping product_id to current calculated stock."""
    stmt = (
        select(
            InventoryMovement.product_id,
            func.coalesce(func.sum(InventoryMovement.quantity_delta), 0).label("stock"),
        )
        .where(
            InventoryMovement.product_id.is_not(None),
            InventoryMovement.basket_type_id.is_(None),
        )
        .group_by(InventoryMovement.product_id)
    )
    rows = db.execute(stmt).all()
    return {r[0]: int(r[1]) for r in rows if r[0] is not None}

def validate_sufficient_product_stock(
    db: Session, product_id: str, quantity_needed: int
) -> int:
    """
    Validates that live product stock is greater than or equal to quantity_needed.
    Raises HTTP 409 Conflict if stock is insufficient.
    Returns current stock.
    """
    current_stock = get_product_stock(db, product_id)
    if current_stock < quantity_needed:
        prod = db.get(Product, product_id)
        name = prod.name if prod else product_id
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "INSUFFICIENT_STOCK",
                "message": (
                    f"Saldo insuficiente para o produto '{name}'. "
                    f"Saldo atual: {current_stock}, solicitado: {quantity_needed}."
                ),
                "product_id": product_id,
                "current_stock": current_stock,
                "requested_quantity": quantity_needed,
                "required_for_reversal": quantity_needed,
            },
        )
    return current_stock

def validate_sufficient_basket_stock(
    db: Session, basket_type_id: str, quantity_needed: int
) -> int:
    """Validates that finished basket stock is sufficient."""
    current_stock = get_basket_stock(db, basket_type_id)
    if current_stock < quantity_needed:
        bt = db.get(BasketType, basket_type_id)
        name = bt.name if bt else basket_type_id
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error_code": "INSUFFICIENT_STOCK",
                "message": (
                    f"Saldo insuficiente para a cesta '{name}'. "
                    f"Saldo atual: {current_stock}, solicitado: {quantity_needed}."
                ),
                "basket_type_id": basket_type_id,
                "current_stock": current_stock,
                "requested_quantity": quantity_needed,
            },
        )
    return current_stock

def record_inventory_movement(
    db: Session,
    item_type: str,
    movement_type: str,
    quantity_delta: int,
    source_type: str,
    source_id: str,
    product_id: Optional[str] = None,
    basket_type_id: Optional[str] = None,
    production_batch_id: Optional[str] = None,
    reversal_of_id: Optional[str] = None,
    reason: Optional[str] = None,
    occurred_at: Optional[datetime.datetime] = None,
) -> InventoryMovement:
    """
    Appends an immutable movement record to inventory_movements.
    If quantity_delta is negative, stock sufficiency must have been checked under BEGIN IMMEDIATE.
    """
    movement = InventoryMovement(
        id=str(uuid.uuid4()),
        item_type=item_type,
        product_id=product_id,
        basket_type_id=basket_type_id,
        production_batch_id=production_batch_id,
        movement_type=movement_type,
        quantity_delta=quantity_delta,
        source_type=source_type,
        source_id=source_id,
        reversal_of_id=reversal_of_id,
        occurred_at=occurred_at or utc_now(),
        reason=reason,
    )
    db.add(movement)
    return movement

def execute_stock_adjustment(
    db: Session, data: StockAdjustmentCreate
) -> StockAdjustmentResponse:
    """
    Executes a manual stock adjustment (IN, OUT, LOSS, COUNT) under active transaction.
    Guarantees strict auditability and prevents negative balance on downward adjustments.
    """
    product = None
    basket = None
    previous_stock = 0

    target_product_id = None
    target_basket_type_id = None

    if data.item_type == "PRODUCT":
        product = db.get(Product, data.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Produto '{data.product_id}' nao encontrado.",
            )
        if not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Produto '{product.name}' esta inativo e nao permite ajustes manuais de estoque.",
            )
        target_product_id = product.id
        previous_stock = get_product_stock(db, data.product_id)
    elif data.item_type == "BASKET":
        basket = db.get(BasketType, data.basket_type_id)
        if not basket:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cesta '{data.basket_type_id}' nao encontrada.",
            )
        if not basket.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cesta '{basket.name}' esta inativa e nao permite ajustes manuais de estoque.",
            )
        target_basket_type_id = basket.id
        previous_stock = get_basket_stock(db, data.basket_type_id)

    # Compute delta and movement_type
    effective_delta = 0
    movement_type = ""

    if data.adjustment_type == "IN":
        effective_delta = int(data.quantity_delta) # type: ignore
        movement_type = "ADJUSTMENT_IN"
    elif data.adjustment_type == "OUT":
        effective_delta = -int(data.quantity_delta) # type: ignore
        movement_type = "ADJUSTMENT_OUT"
    elif data.adjustment_type == "LOSS":
        effective_delta = -int(data.quantity_delta) # type: ignore
        movement_type = "LOSS"
    elif data.adjustment_type == "COUNT":
        target = int(data.physical_count) # type: ignore
        effective_delta = target - previous_stock
        if effective_delta >= 0:
            movement_type = "ADJUSTMENT_IN"
        else:
            movement_type = "ADJUSTMENT_OUT"

    # Enforce non-negative stock constraint
    if effective_delta < 0:
        requested_decrease = abs(effective_delta)
        if previous_stock < requested_decrease:
            name = product.name if product else (basket.name if basket else "")
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error_code": "INSUFFICIENT_STOCK",
                    "message": (
                        f"Saldo insuficiente para ajuste negativo no item '{name}'. "
                        f"Saldo atual: {previous_stock}, decrescimo solicitado: {requested_decrease}."
                    ),
                    "current_stock": previous_stock,
                    "requested_decrease": requested_decrease,
                },
            )

    movement_id = str(uuid.uuid4())
    movement = InventoryMovement(
        id=movement_id,
        item_type=data.item_type,
        product_id=target_product_id,
        basket_type_id=target_basket_type_id,
        production_batch_id=None,
        movement_type=movement_type,
        quantity_delta=effective_delta,
        source_type="ADJUSTMENT",
        source_id=movement_id,
        reversal_of_id=None,
        occurred_at=utc_now(),
        reason=data.reason.strip(),
    )
    db.add(movement)
    db.flush()

    new_stock = previous_stock + effective_delta

    return StockAdjustmentResponse(
        movement_id=movement.id,
        item_type=data.item_type,
        product_id=data.product_id,
        product_name=product.name if product else None,
        basket_type_id=data.basket_type_id,
        basket_type_name=basket.name if basket else None,
        adjustment_type=data.adjustment_type,
        movement_type=movement_type,
        previous_stock=previous_stock,
        quantity_delta=effective_delta,
        new_stock=new_stock,
        reason=data.reason.strip(),
        occurred_at=movement.occurred_at,
    )
