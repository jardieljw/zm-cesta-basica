import uuid
import datetime
from typing import Optional, List, Tuple, Dict
from sqlalchemy import select, func
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.purchases import Purchase, PurchaseItem
from app.models.products import Product, ProductPackaging
from app.models.movements import InventoryMovement
from app.models.base import utc_now
from app.schemas.purchases import PurchaseCreate
from app.services.inventory import (
    get_product_stock,
    validate_sufficient_product_stock,
    record_inventory_movement,
)

def generate_next_purchase_number(db: Session) -> int:
    """Generates the next sequential unique purchase number under active transaction."""
    stmt = select(func.coalesce(func.max(Purchase.purchase_number), 0))
    max_num = db.execute(stmt).scalar_one()
    return int(max_num) + 1

def update_product_cost_price(
    db: Session,
    product: Product,
    packaging: Optional[ProductPackaging],
    unit_price_cents: int,
) -> None:
    """Updates product reference cost price from purchase item price under active transaction."""
    if unit_price_cents <= 0:
        return

    if not packaging:
        product.cost_price_cents = unit_price_cents
    else:
        if product.base_unit.upper() in ("UNIT", "UN") and packaging.quantity_in_base_units > 1:
            product.cost_price_cents = int(round(unit_price_cents / packaging.quantity_in_base_units))
        else:
            default_pkg = next(
                (p for p in product.packagings if p.is_default and p.is_active),
                None,
            )
            if default_pkg and default_pkg.quantity_in_base_units > 0 and packaging.id != default_pkg.id:
                ratio = packaging.quantity_in_base_units / default_pkg.quantity_in_base_units
                product.cost_price_cents = int(round(unit_price_cents / ratio))
            else:
                product.cost_price_cents = unit_price_cents

    product.updated_at = utc_now()
    db.add(product)

def create_purchase_entity(db: Session, data: PurchaseCreate) -> Purchase:
    """
    Creates a new purchase record with packaging conversions and atomic ledger movements.
    Executed under active transaction lock.
    """
    purchase_id = str(uuid.uuid4())
    purchase_number = generate_next_purchase_number(db)
    purchase_date = data.purchase_date or utc_now()
    status_str = data.status.upper()

    purchase = Purchase(
        id=purchase_id,
        purchase_number=purchase_number,
        status=status_str,
        purchase_date=purchase_date,
        supplier_name=data.supplier_name.strip() if data.supplier_name else None,
        total_amount_cents=0,
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
    )
    db.add(purchase)

    total_purchase_cents = 0
    items_to_create: List[PurchaseItem] = []

    for item_data in data.items:
        product = db.get(Product, item_data.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Produto '{item_data.product_id}' nao encontrado.",
            )
        if not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Produto '{product.name}' esta inativo e nao pode ser adquirido.",
            )

        packaging: Optional[ProductPackaging] = None
        quantity_in_base = 0

        if item_data.packaging_id:
            packaging = db.get(ProductPackaging, item_data.packaging_id)
            if not packaging or packaging.product_id != product.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Embalagem '{item_data.packaging_id}' invalida para o produto '{product.name}'.",
                )
            if not packaging.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Embalagem '{packaging.name}' esta inativa.",
                )
            # Automatic packaging conversion
            quantity_in_base = int(round(item_data.packages_count * packaging.quantity_in_base_units))
        else:
            # Purchased directly in base units
            if product.base_unit.upper() in ("UNIT", "UN") and item_data.packages_count % 1 != 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Para produtos com unidade base UNIT/UN sem embalagem, a quantidade deve ser um numero inteiro (produto '{product.name}').",
                )
            quantity_in_base = int(round(item_data.packages_count))

        if quantity_in_base <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Quantidade convertida para unidade base deve ser maior que zero (produto '{product.name}').",
            )

        item_total_cents = int(round(item_data.packages_count * item_data.unit_price_cents))
        total_purchase_cents += item_total_cents

        item_entity = PurchaseItem(
            id=str(uuid.uuid4()),
            purchase_id=purchase_id,
            product_id=product.id,
            packaging_id=packaging.id if packaging else None,
            packages_count=item_data.packages_count,
            quantity_in_base_units=quantity_in_base,
            unit_price_cents=item_data.unit_price_cents,
            total_price_cents=item_total_cents,
        )
        items_to_create.append(item_entity)

    purchase.total_amount_cents = total_purchase_cents
    for it in items_to_create:
        db.add(it)

    # If confirmed, append atomic inventory movements to ledger and update product reference cost price
    if status_str == "CONFIRMED":
        for it in items_to_create:
            record_inventory_movement(
                db=db,
                item_type="PRODUCT",
                movement_type="PURCHASE",
                quantity_delta=it.quantity_in_base_units,
                source_type="PURCHASE",
                source_id=purchase.id,
                product_id=it.product_id,
                occurred_at=purchase.purchase_date,
                reason=(
                    f"Compra #{purchase.purchase_number}"
                    + (f" - Fornecedor: {purchase.supplier_name}" if purchase.supplier_name else "")
                ),
            )
            prod = db.get(Product, it.product_id)
            pkg = db.get(ProductPackaging, it.packaging_id) if it.packaging_id else None
            if prod:
                update_product_cost_price(db, prod, pkg, it.unit_price_cents)

    db.flush()
    return purchase

def confirm_purchase_entity(db: Session, purchase_id: str) -> Purchase:
    """Confirms a draft purchase, posting movements to inventory ledger and updating cost prices."""
    purchase = db.execute(
        select(Purchase).options(selectinload(Purchase.items)).where(Purchase.id == purchase_id)
    ).scalar_one_or_none()

    if not purchase:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Compra '{purchase_id}' nao encontrada.",
        )

    if purchase.status != "DRAFT":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas compras em rascunho (DRAFT) podem ser confirmadas. Status atual: {purchase.status}.",
        )

    purchase.status = "CONFIRMED"

    for it in purchase.items:
        # Append movement
        record_inventory_movement(
            db=db,
            item_type="PRODUCT",
            movement_type="PURCHASE",
            quantity_delta=it.quantity_in_base_units,
            source_type="PURCHASE",
            source_id=purchase.id,
            product_id=it.product_id,
            occurred_at=purchase.purchase_date,
            reason=(
                f"Compra #{purchase.purchase_number}"
                + (f" - Fornecedor: {purchase.supplier_name}" if purchase.supplier_name else "")
            ),
        )

        # Update cost price
        product = db.get(Product, it.product_id)
        pkg = db.get(ProductPackaging, it.packaging_id) if it.packaging_id else None
        if product:
            update_product_cost_price(db, product, pkg, it.unit_price_cents)

    db.flush()
    return purchase

def cancel_purchase_entity(
    db: Session, purchase_id: str, reason: Optional[str] = None
) -> Tuple[Purchase, int]:
    """
    Cancels a purchase. If CONFIRMED, strictly verifies current live stock is sufficient
    for all products before posting reverse movements (PURCHASE_CANCEL).
    Rejects with HTTP 409 if any product has insufficient stock, preventing negative inventory.
    """
    purchase = db.execute(
        select(Purchase).options(selectinload(Purchase.items)).where(Purchase.id == purchase_id)
    ).scalar_one_or_none()

    if not purchase:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Compra '{purchase_id}' nao encontrada.",
        )

    if purchase.status == "CANCELED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A compra #{purchase.purchase_number} ja se encontra cancelada.",
        )

    if purchase.status == "DRAFT":
        purchase.status = "CANCELED"
        db.flush()
        return purchase, 0

    if purchase.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Status de compra invalido para cancelamento: '{purchase.status}'.",
        )

    # For CONFIRMED purchases: verify stock sufficiency for each product
    required_reversals: Dict[str, int] = {}
    for it in purchase.items:
        required_reversals[it.product_id] = required_reversals.get(it.product_id, 0) + it.quantity_in_base_units

    for prod_id, needed_qty in required_reversals.items():
        validate_sufficient_product_stock(db, prod_id, needed_qty)

    # Fetch original movements created for this purchase
    orig_movements = db.execute(
        select(InventoryMovement).where(
            InventoryMovement.source_type == "PURCHASE",
            InventoryMovement.source_id == purchase.id,
            InventoryMovement.movement_type == "PURCHASE",
        )
    ).scalars().all()

    purchase.status = "CANCELED"

    reversal_count = 0
    clean_reason = reason.strip() if reason else ""
    reversal_reason = (
        f"Cancelamento/Estorno da Compra #{purchase.purchase_number}"
        + (f": {clean_reason}" if clean_reason else "")
    )

    for orig in orig_movements:
        record_inventory_movement(
            db=db,
            item_type=orig.item_type,
            movement_type="PURCHASE_CANCEL",
            quantity_delta=-orig.quantity_delta,
            source_type="PURCHASE",
            source_id=purchase.id,
            product_id=orig.product_id,
            basket_type_id=orig.basket_type_id,
            production_batch_id=orig.production_batch_id,
            reversal_of_id=orig.id,
            reason=reversal_reason,
            occurred_at=utc_now(),
        )
        reversal_count += 1

    db.flush()
    return purchase, reversal_count
