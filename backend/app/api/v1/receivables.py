import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.sales import SalesReceivable, ReceivablePayment
from app.models.base import utc_now
from app.schemas.receivables import (
    ReceivablePaymentCreate,
    ReceivablePaymentCancelRequest,
    ReceivablePaymentResponse,
    SalesReceivableResponse,
    SalesReceivableDetailResponse,
)
from app.services.receivables import (
    list_receivables,
    get_receivable,
    record_receivable_payment,
    cancel_receivable_payment,
    get_payment_repass_status,
)

router = APIRouter()


def serialize_receivable(r: SalesReceivable) -> SalesReceivableResponse:
    now = utc_now()
    due = r.due_date
    if due.tzinfo is None and now.tzinfo is not None:
        due = due.replace(tzinfo=datetime.timezone.utc)
    is_overdue = due < now and r.status in ["OPEN", "PARTIAL"]

    basket_summary = None
    if r.sale and r.sale.items:
        names = [item.basket_type.name for item in r.sale.items if item.basket_type]
        if names:
            basket_summary = ", ".join(dict.fromkeys(names))

    return SalesReceivableResponse(
        id=r.id,
        sale_id=r.sale_id,
        sale_number=r.sale.sale_number if r.sale else 0,
        customer_id=r.customer_id,
        customer_name=r.customer.name if r.customer else "",
        sale_date=r.sale.sale_date if r.sale else r.created_at,
        due_date=r.due_date,
        original_amount_cents=r.original_amount_cents,
        paid_amount_cents=r.paid_amount_cents,
        balance_cents=r.balance_cents,
        status=r.status,
        is_overdue=is_overdue,
        basket_types_summary=basket_summary,
        notes=r.notes,
        created_at=r.created_at,
        updated_at=r.updated_at,
        payments_count=len(r.payments) if r.payments else 0,
    )


def serialize_receivable_detail(r: SalesReceivable, db: Session) -> SalesReceivableDetailResponse:
    base = serialize_receivable(r)
    payments = [
        ReceivablePaymentResponse(
            id=p.id,
            receivable_id=p.receivable_id,
            dispatch_id=p.dispatch_id,
            account_id=p.account_id,
            account_name=p.financial_account.name if p.financial_account else None,
            payment_date=p.payment_date,
            amount_cents=p.amount_cents,
            payment_method=p.payment_method,
            status=p.status,
            is_route_collection=(p.dispatch_id is not None and p.payment_method.upper() == "CASH"),
            repass_status=get_payment_repass_status(p, db),
            reversal_reason=p.reversal_reason,
            reversal_of_id=p.reversal_of_id,
            notes=p.notes,
            created_at=p.created_at,
        )
        for p in r.payments
    ]
    return SalesReceivableDetailResponse(
        **base.model_dump(),
        payments=payments,
    )


@router.get("/receivables", response_model=List[SalesReceivableResponse])
def get_receivables(
    customer_id: Optional[str] = Query(None, description="Filtrar por cliente"),
    status: Optional[str] = Query(None, description="Filtrar por situacao (OPEN, PARTIAL, PAID)"),
    overdue_only: bool = Query(False, description="Apenas titulos vencidos"),
    sale_date_from: Optional[datetime.datetime] = Query(None, description="Data da venda inicial"),
    sale_date_to: Optional[datetime.datetime] = Query(None, description="Data da venda final"),
    due_date_from: Optional[datetime.datetime] = Query(None, description="Data de vencimento inicial"),
    due_date_to: Optional[datetime.datetime] = Query(None, description="Data de vencimento final"),
    basket_type_id: Optional[str] = Query(None, description="Filtrar por tipo de cesta vendida"),
    min_amount_cents: Optional[int] = Query(None, description="Valor minimo em centavos"),
    max_amount_cents: Optional[int] = Query(None, description="Valor maximo em centavos"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta titulos a receber com filtros por cliente, vencimento, venda, cesta e valores."""
    receivables = list_receivables(
        db=db,
        customer_id=customer_id,
        status_filter=status,
        overdue_only=overdue_only,
        sale_date_from=sale_date_from,
        sale_date_to=sale_date_to,
        due_date_from=due_date_from,
        due_date_to=due_date_to,
        basket_type_id=basket_type_id,
        min_amount_cents=min_amount_cents,
        max_amount_cents=max_amount_cents,
        limit=limit,
        offset=offset,
    )
    return [serialize_receivable(r) for r in receivables]


@router.get("/receivables/{receivable_id}", response_model=SalesReceivableDetailResponse)
def get_receivable_by_id(
    receivable_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes de um titulo com lista de pagamentos e amortizacoes."""
    receivable = get_receivable(db, receivable_id)
    return serialize_receivable_detail(receivable, db)


@router.post("/receivables/{receivable_id}/payments", response_model=ReceivablePaymentResponse, status_code=status.HTTP_201_CREATED)
def post_receivable_payment(
    receivable_id: str,
    data: ReceivablePaymentCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra um pagamento ou amortizacao parcial de um fiado.
    Envolvido em transacao idempotente via X-Idempotency-Key.
    """
    def callback(session: Session):
        payment = record_receivable_payment(session, receivable_id, data)
        repass_st = get_payment_repass_status(payment, session)
        resp = ReceivablePaymentResponse(
            id=payment.id,
            receivable_id=payment.receivable_id,
            dispatch_id=payment.dispatch_id,
            account_id=payment.account_id,
            account_name=payment.financial_account.name if payment.financial_account else None,
            payment_date=payment.payment_date,
            amount_cents=payment.amount_cents,
            payment_method=payment.payment_method,
            status=payment.status,
            is_route_collection=(payment.dispatch_id is not None and payment.payment_method.upper() == "CASH"),
            repass_status=repass_st,
            reversal_reason=payment.reversal_reason,
            reversal_of_id=payment.reversal_of_id,
            notes=payment.notes,
            created_at=payment.created_at,
        ).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="RECEIVABLE_PAYMENT_CREATE",
        payload={"receivable_id": receivable_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )

    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/receivables/payments/{payment_id}/cancel", response_model=ReceivablePaymentResponse)
def post_cancel_payment(
    payment_id: str,
    data: ReceivablePaymentCancelRequest,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Estorna um pagamento recebido, restabelecendo o saldo devedor do titulo.
    """
    def callback(session: Session):
        payment = cancel_receivable_payment(session, payment_id, data)
        repass_st = get_payment_repass_status(payment, session)
        resp = ReceivablePaymentResponse(
            id=payment.id,
            receivable_id=payment.receivable_id,
            dispatch_id=payment.dispatch_id,
            account_id=payment.account_id,
            account_name=payment.financial_account.name if payment.financial_account else None,
            payment_date=payment.payment_date,
            amount_cents=payment.amount_cents,
            payment_method=payment.payment_method,
            status=payment.status,
            is_route_collection=(payment.dispatch_id is not None and payment.payment_method.upper() == "CASH"),
            repass_status=repass_st,
            reversal_reason=payment.reversal_reason,
            reversal_of_id=payment.reversal_of_id,
            notes=payment.notes,
            created_at=payment.created_at,
        ).model_dump(mode="json")
        return status.HTTP_200_OK, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="RECEIVABLE_PAYMENT_CANCEL",
        payload={"payment_id": payment_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )

    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())
