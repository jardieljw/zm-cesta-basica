import uuid
import datetime
from typing import Optional, List, Tuple
from sqlalchemy import select, func, desc
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.sales import SalesReceivable, ReceivablePayment, Sale, SaleItem
from app.models.customers import Customer
from app.models.dispatches import StockDispatch
from app.models.financial import FinancialAccount, CashFlowEntry
from app.models.base import utc_now
from app.schemas.receivables import ReceivablePaymentCreate, ReceivablePaymentCancelRequest
from app.services.financial import record_cash_flow_entry, get_default_financial_account


def list_receivables(
    db: Session,
    customer_id: Optional[str] = None,
    status_filter: Optional[str] = None,
    overdue_only: bool = False,
    sale_date_from: Optional[datetime.datetime] = None,
    sale_date_to: Optional[datetime.datetime] = None,
    due_date_from: Optional[datetime.datetime] = None,
    due_date_to: Optional[datetime.datetime] = None,
    basket_type_id: Optional[str] = None,
    min_amount_cents: Optional[int] = None,
    max_amount_cents: Optional[int] = None,
    limit: int = 100,
    offset: int = 0,
) -> List[SalesReceivable]:
    """
    Lists receivables with comprehensive filtering:
    - customer, status, overdue_only
    - sale date range (sale_date_from, sale_date_to)
    - due date range (due_date_from, due_date_to)
    - basket type sold
    - original amount range (min_amount_cents, max_amount_cents)
    """
    stmt = (
        select(SalesReceivable)
        .options(
            selectinload(SalesReceivable.customer),
            selectinload(SalesReceivable.sale).selectinload(Sale.items).selectinload(SaleItem.basket_type),
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
    if due_date_from:
        stmt = stmt.where(SalesReceivable.due_date >= due_date_from)
    if due_date_to:
        stmt = stmt.where(SalesReceivable.due_date <= due_date_to)
    if sale_date_from:
        stmt = stmt.where(SalesReceivable.sale.has(Sale.sale_date >= sale_date_from))
    if sale_date_to:
        stmt = stmt.where(SalesReceivable.sale.has(Sale.sale_date <= sale_date_to))
    if basket_type_id:
        stmt = stmt.where(SalesReceivable.sale.has(Sale.items.any(SaleItem.basket_type_id == basket_type_id)))
    if min_amount_cents is not None:
        stmt = stmt.where(SalesReceivable.original_amount_cents >= min_amount_cents)
    if max_amount_cents is not None:
        stmt = stmt.where(SalesReceivable.original_amount_cents <= max_amount_cents)

    stmt = stmt.order_by(SalesReceivable.due_date.asc(), desc(SalesReceivable.created_at)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())


def get_receivable(db: Session, receivable_id: str) -> SalesReceivable:
    """Retrieves single receivable with payments, customer and sale details."""
    stmt = (
        select(SalesReceivable)
        .options(
            selectinload(SalesReceivable.customer),
            selectinload(SalesReceivable.sale).selectinload(Sale.items).selectinload(SaleItem.basket_type),
            selectinload(SalesReceivable.payments).selectinload(ReceivablePayment.financial_account),
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


def get_payment_repass_status(payment: ReceivablePayment, db: Session) -> str:
    """
    Distinguishes direct company receipts from route cash pending or completed repass:
    - DIRECT_COMPANY: payment received directly at store or via Pix/Card into company account
    - PENDING_REPASS: cash collected by route collector on open dispatch, still in transit
    - REPASSED: cash collected by route collector and settled upon dispatch conclusion
    """
    if not payment.dispatch_id:
        return "DIRECT_COMPANY"
    if payment.payment_method.upper() in ["PIX", "CARD"]:
        return "DIRECT_COMPANY"

    dispatch = db.get(StockDispatch, payment.dispatch_id)
    if dispatch and dispatch.status == "CONCLUDED":
        return "REPASSED"
    return "PENDING_REPASS"


def record_receivable_payment(
    db: Session, receivable_id: str, data: ReceivablePaymentCreate
) -> ReceivablePayment:
    """
    Records a payment or partial amortization on a receivable:
    - Validates positive amount <= remaining balance
    - Distinguishes direct company receipts from route collections
    - If direct to company, atomically registers credit entry in treasury cash_flow_entries
    - If route cash, money remains in custody of collector until dispatch repayment
    - Synchronizes sale payment_status
    """
    receivable = db.execute(
        select(SalesReceivable)
        .options(selectinload(SalesReceivable.sale), selectinload(SalesReceivable.customer))
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

    is_route_cash = (data.dispatch_id is not None) and (data.payment_method.upper() == "CASH")
    target_account = None

    if not is_route_cash:
        if data.account_id:
            target_account = db.get(FinancialAccount, data.account_id)
            if not target_account or not target_account.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Conta financeira informada nao encontrada ou inativa.",
                )
        else:
            acc_type = "BANK" if data.payment_method.upper() in ["PIX", "CARD", "TRANSFER"] else "CASH"
            target_account = get_default_financial_account(db, acc_type)

    payment_id = str(uuid.uuid4())
    payment_date = data.payment_date or utc_now()

    payment = ReceivablePayment(
        id=payment_id,
        receivable_id=receivable.id,
        dispatch_id=data.dispatch_id,
        account_id=target_account.id if target_account else None,
        payment_date=payment_date,
        amount_cents=data.amount_cents,
        payment_method=data.payment_method.upper(),
        status="CONFIRMED",
        notes=data.notes.strip() if data.notes else None,
        created_at=utc_now(),
    )
    db.add(payment)

    # Post treasury cash flow if received directly by company
    if target_account:
        cust_label = receivable.customer.name if receivable.customer else "Cliente"
        record_cash_flow_entry(
            db=db,
            account_id=target_account.id,
            entry_type="CREDIT",
            amount_cents=data.amount_cents,
            category="RECEBIMENTO_CLIENTE",
            description=f"Recebimento de fiado ref. Venda #{receivable.sale.sale_number if receivable.sale else ''} ({cust_label})",
            nature="BUSINESS",
            source_type="RECEIVABLE_PAYMENT",
            source_id=payment.id,
            payment_method=data.payment_method.upper(),
            occurred_at=payment_date,
            notes=data.notes,
        )

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
    Cancels/reverses a payment, adjusting receivable balance and posting reversal in treasury if applicable.
    """
    payment = db.execute(
        select(ReceivablePayment)
        .options(
            selectinload(ReceivablePayment.receivable).selectinload(SalesReceivable.sale),
            selectinload(ReceivablePayment.financial_account),
        )
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

    # Reverse cash flow entry if money had entered treasury
    if payment.account_id:
        orig_entry = db.execute(
            select(CashFlowEntry).where(
                CashFlowEntry.source_type == "RECEIVABLE_PAYMENT",
                CashFlowEntry.source_id == payment.id,
                CashFlowEntry.is_reversal.is_(False),
            )
        ).scalars().first()
        record_cash_flow_entry(
            db=db,
            account_id=payment.account_id,
            entry_type="DEBIT",
            amount_cents=payment.amount_cents,
            category="RECEBIMENTO_CLIENTE",
            description=f"Estorno recebimento fiado #{payment.id[:8]}: {data.reason.strip()}",
            nature="BUSINESS",
            source_type="RECEIVABLE_PAYMENT",
            source_id=payment.id,
            payment_method=payment.payment_method,
            occurred_at=utc_now(),
            is_reversal=True,
            reversal_of_id=orig_entry.id if orig_entry else None,
            allow_duplicate_source=True,
        )

    payment.status = "REVERSED"
    payment.reversal_reason = data.reason.strip()
    db.flush()
    return payment
