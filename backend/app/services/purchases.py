import uuid
import datetime
from decimal import Decimal, ROUND_HALF_EVEN
from typing import Optional, List, Tuple, Dict
from sqlalchemy import select, func
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.purchases import Purchase, PurchaseItem
from app.models.products import Product, ProductPackaging
from app.models.movements import InventoryMovement
from app.models.financial import FinancialAccount, CashFlowEntry, AccountPayable, PayablePayment
from app.models.financial_bill_semantics import FinancialBillObligation, FinancialBillSemanticItem
from app.models.base import utc_now
from app.schemas.purchases import PurchaseCreate, PurchaseDraftUpdate, PurchaseItemCreate
from app.services.inventory import (
    get_product_stock,
    validate_sufficient_product_stock,
    record_inventory_movement,
)
from app.services.financial import (
    record_cash_flow_entry,
    get_default_financial_account,
    generate_next_payable_number,
)

def _process_purchase_financial_impact(db: Session, purchase: Purchase) -> None:
    """Handles financial impact for confirmed purchases: open payable for CREDIT_TERM or immediate cash debit for CASH_IMMEDIATE."""
    pay_method = (purchase.payment_method or ("BOLETO" if purchase.payment_mode == "CREDIT_TERM" else "DINHEIRO")).upper()

    if purchase.payment_mode == "CREDIT_TERM":
        p_num = generate_next_payable_number(db)
        due = purchase.due_date or (purchase.purchase_date + datetime.timedelta(days=30))
        payable = AccountPayable(
            id=str(uuid.uuid4()),
            payable_number=p_num,
            description=f"Compra #{purchase.purchase_number}" + (f" ({purchase.supplier_name})" if purchase.supplier_name else ""),
            beneficiary=purchase.supplier_name or "Fornecedor",
            category="FORNECEDOR",
            nature="BUSINESS",
            original_amount_cents=purchase.total_amount_cents,
            paid_amount_cents=0,
            balance_cents=purchase.total_amount_cents,
            due_date=due,
            payment_method=pay_method,
            status="OPEN",
            purchase_id=purchase.id,
            installment_number=1,
            total_installments=1,
            created_at=utc_now(),
            updated_at=utc_now(),
        )
        db.add(payable)
    else:  # CASH_IMMEDIATE
        target_acc = db.get(FinancialAccount, purchase.account_id) if purchase.account_id else get_default_financial_account(db, "CASH" if pay_method == "DINHEIRO" else "BANK")
        if target_acc and purchase.total_amount_cents > 0:
            p_num = generate_next_payable_number(db)
            payable = AccountPayable(
                id=str(uuid.uuid4()),
                payable_number=p_num,
                description=f"Compra #{purchase.purchase_number}" + (f" ({purchase.supplier_name})" if purchase.supplier_name else ""),
                beneficiary=purchase.supplier_name or "Fornecedor",
                category="FORNECEDOR",
                nature="BUSINESS",
                original_amount_cents=purchase.total_amount_cents,
                paid_amount_cents=purchase.total_amount_cents,
                balance_cents=0,
                due_date=purchase.purchase_date,
                payment_method=pay_method,
                status="PAID",
                purchase_id=purchase.id,
                installment_number=1,
                total_installments=1,
                created_at=utc_now(),
                updated_at=utc_now(),
            )
            db.add(payable)
            payment = PayablePayment(
                id=str(uuid.uuid4()),
                payable_id=payable.id,
                account_id=target_acc.id,
                payment_date=purchase.purchase_date,
                amount_cents=purchase.total_amount_cents,
                payment_method=pay_method,
                status="CONFIRMED",
                notes=f"Pagamento a vista ({pay_method}) na Compra #{purchase.purchase_number}",
                created_at=utc_now(),
            )
            db.add(payment)
            record_cash_flow_entry(
                db=db,
                account_id=target_acc.id,
                entry_type="DEBIT",
                amount_cents=purchase.total_amount_cents,
                category="COMPRA_INSUMOS",
                description=f"Pagamento a vista Compra #{purchase.purchase_number}" + (f" ({purchase.supplier_name})" if purchase.supplier_name else ""),
                nature="BUSINESS",
                source_type="PURCHASE",
                source_id=purchase.id,
                payment_method=pay_method,
                occurred_at=purchase.purchase_date,
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
    quantity_in_base_units: int = 0,
    total_price_cents: int = 0,
) -> None:
    """Updates product reference cost price and microcents CMPM under active transaction."""
    if unit_price_cents <= 0:
        return

    # 1. Update CMPM in microcents if quantity and total are provided
    if quantity_in_base_units > 0 and total_price_cents > 0:
        unit_compra_micro = int(
            (Decimal(total_price_cents) * Decimal(10000) / Decimal(quantity_in_base_units))
            .quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
        )
        stock_after = get_product_stock(db, product.id)
        stock_before = max(0, stock_after - quantity_in_base_units)

        current_cmpm = product.cost_price_microcents or (product.cost_price_cents * 10000)
        if stock_before > 0 and current_cmpm > 0:
            new_cmpm = int(
                (
                    (Decimal(stock_before) * Decimal(current_cmpm) + Decimal(quantity_in_base_units) * Decimal(unit_compra_micro))
                    / Decimal(stock_before + quantity_in_base_units)
                ).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
            )
        else:
            new_cmpm = unit_compra_micro

        product.cost_price_microcents = new_cmpm

    # 2. Update reference cost_price_cents
    if not packaging:
        product.cost_price_cents = unit_price_cents
    else:
        if product.base_unit.upper() in ("UNIT", "UN") and packaging.quantity_in_base_units > 1:
            product.cost_price_cents = int(
                (Decimal(unit_price_cents) / Decimal(packaging.quantity_in_base_units))
                .quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
            )
        else:
            default_pkg = next(
                (p for p in product.packagings if p.is_default and p.is_active),
                None,
            )
            if default_pkg and default_pkg.quantity_in_base_units > 0 and packaging.id != default_pkg.id:
                ratio = packaging.quantity_in_base_units / default_pkg.quantity_in_base_units
                product.cost_price_cents = int(
                    (Decimal(unit_price_cents) / Decimal(ratio))
                    .quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
                )
            else:
                product.cost_price_cents = unit_price_cents

    if product.cost_price_microcents == 0 and product.cost_price_cents > 0:
        product.cost_price_microcents = product.cost_price_cents * 10000

    product.updated_at = utc_now()
    db.add(product)


def _build_purchase_items(
    db: Session,
    purchase_id: str,
    items_data: List[PurchaseItemCreate],
    reusable_inactive_pairs: Optional[set[Tuple[str, Optional[str]]]] = None,
) -> Tuple[List[PurchaseItem], int]:
    reusable_inactive_pairs = reusable_inactive_pairs or set()
    items: List[PurchaseItem] = []
    total_purchase_cents = 0

    for item_data in items_data:
        product = db.get(Product, item_data.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Produto '{item_data.product_id}' nao encontrado.",
            )

        same_existing_reference = (product.id, item_data.packaging_id) in reusable_inactive_pairs
        if not product.is_active and not same_existing_reference:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Produto '{product.name}' esta inativo e nao pode ser adquirido.",
            )

        packaging: Optional[ProductPackaging] = None
        if item_data.packaging_id:
            packaging = db.get(ProductPackaging, item_data.packaging_id)
            if not packaging or packaging.product_id != product.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Embalagem '{item_data.packaging_id}' invalida para o produto '{product.name}'.",
                )
            if not packaging.is_active and not same_existing_reference:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Embalagem '{packaging.name}' esta inativa.",
                )
            quantity_in_base = int(round(item_data.packages_count * packaging.quantity_in_base_units))
        else:
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
        items.append(
            PurchaseItem(
                id=str(uuid.uuid4()),
                purchase_id=purchase_id,
                product_id=product.id,
                packaging_id=packaging.id if packaging else None,
                packages_count=item_data.packages_count,
                quantity_in_base_units=quantity_in_base,
                unit_price_cents=item_data.unit_price_cents,
                total_price_cents=item_total_cents,
            )
        )

    return items, total_purchase_cents


def _ensure_draft_has_no_effects(db: Session, purchase_id: str) -> None:
    has_movements = db.scalar(
        select(InventoryMovement.id)
        .where(
            InventoryMovement.source_type == "PURCHASE",
            InventoryMovement.source_id == purchase_id,
        )
        .limit(1)
    )
    has_payable = db.scalar(
        select(AccountPayable.id)
        .where(AccountPayable.purchase_id == purchase_id)
        .limit(1)
    )
    has_cash_entry = db.scalar(
        select(CashFlowEntry.id)
        .where(
            CashFlowEntry.source_type == "PURCHASE",
            CashFlowEntry.source_id == purchase_id,
        )
        .limit(1)
    )
    has_bill_item = db.scalar(
        select(FinancialBillSemanticItem.id)
        .where(FinancialBillSemanticItem.purchase_id == purchase_id)
        .limit(1)
    )
    has_bill_obligation = db.scalar(
        select(FinancialBillObligation.id)
        .where(FinancialBillObligation.purchase_id == purchase_id)
        .limit(1)
    )
    if (
        has_movements
        or has_payable
        or has_cash_entry
        or has_bill_item
        or has_bill_obligation
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este rascunho possui efeitos ou evidencias financeiras e nao pode ser editado ou excluido.",
        )

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
        payment_mode=data.payment_mode.upper() if data.payment_mode else "CASH_IMMEDIATE",
        payment_method=data.payment_method.upper() if data.payment_method else "DINHEIRO",
        due_date=data.due_date,
        account_id=data.account_id,
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
            db.flush()
            prod = db.get(Product, it.product_id)
            pkg = db.get(ProductPackaging, it.packaging_id) if it.packaging_id else None
            if prod:
                update_product_cost_price(db, prod, pkg, it.unit_price_cents, it.quantity_in_base_units, it.total_price_cents)

        # Process financial impact (open payable if credit, cash flow debit if cash immediate)
        _process_purchase_financial_impact(db, purchase)

    db.flush()
    return purchase


def update_purchase_draft_entity(
    db: Session, purchase_id: str, data: PurchaseDraftUpdate
) -> Purchase:
    purchase = db.execute(
        select(Purchase)
        .options(selectinload(Purchase.items))
        .where(Purchase.id == purchase_id)
    ).scalar_one_or_none()
    if not purchase:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Compra nao encontrada.")
    if purchase.status != "DRAFT":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Apenas compras em rascunho podem ser editadas.",
        )

    _ensure_draft_has_no_effects(db, purchase.id)
    reusable_inactive_pairs = {(item.product_id, item.packaging_id) for item in purchase.items}
    new_items, total_purchase_cents = _build_purchase_items(
        db, purchase.id, data.items, reusable_inactive_pairs
    )

    provided = data.model_fields_set
    for field in (
        "supplier_name",
        "purchase_date",
        "payment_mode",
        "payment_method",
        "due_date",
        "account_id",
        "notes",
    ):
        if field in provided:
            value = getattr(data, field)
            if field == "purchase_date" and value is None:
                continue
            setattr(purchase, field, value)
    purchase.items = new_items
    purchase.total_amount_cents = total_purchase_cents
    db.flush()
    return purchase


def delete_purchase_draft_entity(db: Session, purchase_id: str) -> int:
    purchase = db.get(Purchase, purchase_id)
    if not purchase:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Compra nao encontrada.")
    if purchase.status != "DRAFT":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Apenas compras em rascunho podem ser excluidas.",
        )

    _ensure_draft_has_no_effects(db, purchase.id)
    purchase_number = purchase.purchase_number
    db.delete(purchase)
    db.flush()
    return purchase_number


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
        db.flush()

        # Update cost price
        product = db.get(Product, it.product_id)
        pkg = db.get(ProductPackaging, it.packaging_id) if it.packaging_id else None
        if product:
            update_product_cost_price(db, product, pkg, it.unit_price_cents, it.quantity_in_base_units, it.total_price_cents)

    # Process financial impact (open payable if credit, cash flow debit if cash immediate)
    _process_purchase_financial_impact(db, purchase)

    db.flush()
    return purchase

def cancel_purchase_entity(
    db: Session, purchase_id: str, reason: Optional[str] = None
) -> Tuple[Purchase, int]:
    """
    Cancels a purchase. If CONFIRMED, strictly verifies current live stock is sufficient
    for all products before posting reverse movements (PURCHASE_CANCEL).
    Rejects with HTTP 409 if any product has insufficient stock, preventing negative inventory.
    Reverses linked open payables or debits in cash flow.
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
    if db.scalar(select(AccountPayable.id).where(AccountPayable.purchase_id == purchase.id, AccountPayable.superseded_by_id.is_not(None))):
        raise HTTPException(409, detail={'error_code': 'FINANCIAL_BILL_REPLACEMENT_CONFLICT', 'message': 'Esta compra possui saldo representado em fatura; confira o vinculo antes de cancelar.'})
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

    # Check and reverse all linked AccountPayable titles and cash entries
    linked_payables = list(db.execute(
        select(AccountPayable).options(selectinload(AccountPayable.payments)).where(AccountPayable.purchase_id == purchase.id)
    ).scalars().all())

    for linked_payable in linked_payables:
        if linked_payable.status == "OPEN" and linked_payable.paid_amount_cents == 0:
            linked_payable.status = "CANCELED"
            linked_payable.balance_cents = 0
            linked_payable.updated_at = utc_now()
        elif linked_payable.status in ["PAID", "PARTIAL"]:
            # Reverse confirmed payments in treasury
            for pay in linked_payable.payments:
                if pay.status == "CONFIRMED":
                    pay.status = "REVERSED"
                    pay.reversal_reason = f"Estorno automatico por cancelamento da compra #{purchase.purchase_number}"
                    orig_entry = db.execute(
                        select(CashFlowEntry).where(
                            CashFlowEntry.source_type.in_(["PAYABLE_PAYMENT", "PURCHASE"]),
                            CashFlowEntry.source_id.in_([pay.id, purchase.id]),
                            CashFlowEntry.is_reversal.is_(False),
                        )
                    ).scalars().first()
                    record_cash_flow_entry(
                        db=db,
                        account_id=pay.account_id,
                        entry_type="CREDIT",
                        amount_cents=pay.amount_cents,
                        category="COMPRA_INSUMOS",
                        description=f"Estorno por cancelamento da Compra #{purchase.purchase_number}",
                        nature="BUSINESS",
                        source_type="PURCHASE",
                        source_id=purchase.id,
                        is_reversal=True,
                        reversal_of_id=orig_entry.id if orig_entry else None,
                        occurred_at=utc_now(),
                        allow_duplicate_source=True,
                    )
            linked_payable.status = "CANCELED"
            linked_payable.balance_cents = 0
            linked_payable.updated_at = utc_now()

    db.flush()
    return purchase, reversal_count
