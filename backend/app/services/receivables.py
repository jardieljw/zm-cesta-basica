import uuid
import datetime
from typing import Optional, List, Tuple
from sqlalchemy import select, func, desc
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.sales import SalesReceivable, ReceivablePayment, Sale
from app.models.customers import Customer
from app.models.dispatches import StockDispatch
from app.models.base import utc_now
from app.schemas.receivables import ReceivablePaymentCreate, ReceivablePaymentCancelRequest


def list_receivables(
    db: Session,
    customer_id: Optional[str] = None,
    status_filter: Optional[str] = None,
    overdue_only: bool = False,
    limit: int = 100,
    offset: int = 0,
) -> List[SalesReceivable]:
    """Lists receivables with customer and sale details."""
    stmt = (
        select(SalesReceivable)
        .options(
            selectinload(SalesReceivable.customer),
            selectinload(SalesReceivable.sale),
            selectinload(SalesReceivable.payments),
        )
    )
    if customer_id:
        stmt = stmt.where(SalesReceivable.customer_id == customer_id)
    if status_filter:
        stmt = stmt.where(SalesReceivable.status == status_filter)
    if overdue_only:
        stmt = stmt.where(
            SalesReceivable.due_date < utc_now(),
            SalesReceivable.status.in_(["OPEN", "PARTIAL"]),
        )

    stmt = stmt.order_by(SalesReceivable.due_date.asc(), desc(SalesReceivable.created_at)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())


def get_receivable(db: Session, receivable_id: str) -> SalesReceivable:
    """Retrieves single receivable with payments, customer and sale."""
    stmt = (
        select(SalesReceivable)
        .options(
            selectinload(SalesReceivable.customer),
            selectinload(SalesReceivable.sale),
            selectinload(SalesReceivable.payments),
        )
        .where(SalesReceivable.id == receivable_id)
    )
    receivable = db.execute(stmt).scalar_one_or_none()
    if not receivable:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Titulo a receber '{receivable_id}' nao encontrado.",
        )
    return receivable


def record_receivable_payment(
    db: Session, receivable_id: str, data: ReceivablePaymentCreate
) -> ReceivablePayment:
    """
    Records a payment or partial amortization on a receivable:
    - Validates that amount is positive and does not exceed balance.
    - Updates receivable balance and status (PARTIAL or PAID).
    - Synchronizes sale payment_status.
    - Prepares clean audit trail for Phase 6 route settlement and Phase 7 treasury.
    """
    receivable = db.execute(
        select(SalesReceivable)
        .options(selectinload(SalesReceivable.sale))
        .where(SalesReceivable.id == receivable_id)
    ).scalar_one_or_none()

    if not receivable:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Titulo a receber '{receivable_id}' nao encontrado.",
        )

    if receivable.status not in ["OPEN", "PARTIAL"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas titulos abertos ou parciais podem receber pagamentos. Status atual: {receivable.status}.",
        )

    if data.amount_cents > receivable.balance_cents:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Valor informado ({data.amount_cents} centavos) excede o saldo devedor restante "
                f"do titulo ({receivable.balance_cents} centavos)."
            ),
        )

    if data.dispatch_id:
        dispatch = db.get(StockDispatch, data.dispatch_id)
        if not dispatch:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Saida #{data.dispatch_id} nao encontrada.",
            )

    payment = ReceivablePayment(
        id=str(uuid.uuid4()),
        receivable_id=receivable.id,
        dispatch_id=data.dispatch_id,
        payment_date=data.payment_date or utc_now(),
        amount_cents=data.amount_cents,
        payment_method=data.payment_method,
        status="CONFIRMED",
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
    )
    db.add(payment)

    receivable.paid_amount_cents += data.amount_cents
    receivable.balance_cents = receivable.original_amount_cents - receivable.paid_amount_cents
    if receivable.balance_cents == 0:
        receivable.status = "PAID"
    else:
        receivable.status = "PARTIAL"
    receivable.updated_at = utc_now()

    if receivable.sale:
        receivable.sale.payment_status = "PAID" if receivable.status == "PAID" else "PARTIAL"

    db.flush()
    return payment


def cancel_receivable_payment(
    db: Session, payment_id: str, data: ReceivablePaymentCancelRequest
) -> ReceivablePayment:
    """
    Cancels/reverses a payment, adjusting the receivable balance and status accordingly.
    """
    payment = db.execute(
        select(ReceivablePayment)
        .options(selectinload(ReceivablePayment.receivable).selectinload(SalesReceivable.sale))
        .where(ReceivablePayment.id == payment_id)
    ).scalar_one_or_none()

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pagamento '{payment_id}' nao encontrado.",
        )

    if payment.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas pagamentos confirmados podem ser estornados. Status atual: {payment.status}.",
        )

    receivable = payment.receivable
    receivable.paid_amount_cents -= payment.amount_cents
    receivable.balance_cents = receivable.original_amount_cents - receivable.paid_amount_cents
    if receivable.paid_amount_cents > 0:
        receivable.status = "PARTIAL"
    else:
        receivable.status = "OPEN"
    receivable.updated_at = utc_now()

    if receivable.sale:
        receivable.sale.payment_status = "PARTIAL" if receivable.status == "PARTIAL" else "PENDING"

    payment.status = "REVERSED"
    payment.reversal_reason = data.reason.strip()
    db.flush()
    return payment
