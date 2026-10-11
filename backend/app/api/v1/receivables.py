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
)

router = APIRouter()


def serialize_receivable(r: SalesReceivable) -> SalesReceivableResponse:
    now = utc_now()
    due = r.due_date
    if due.tzinfo is None and now.tzinfo is not None:
        due = due.replace(tzinfo=datetime.timezone.utc)
    is_overdue = due < now and r.status in ["OPEN", "PARTIAL"]

    return SalesReceivableResponse(
        id=r.id,
        sale_id=r.sale_id,
        sale_number=r.sale.sale_number if r.sale else 0,
        customer_id=r.customer_id,
        customer_name=r.customer.name if r.customer else "",
        due_date=r.due_date,
        original_amount_cents=r.original_amount_cents,
        paid_amount_cents=r.paid_amount_cents,
        balance_cents=r.balance_cents,
        status=r.status,
        is_overdue=is_overdue,
        notes=r.notes,
        created_at=r.created_at,
        updated_at=r.updated_at,
        payments_count=len(r.payments) if r.payments else 0,
    )


def serialize_receivable_detail(r: SalesReceivable) -> SalesReceivableDetailResponse:
    base = serialize_receivable(r)
    payments = [
        ReceivablePaymentResponse(
            id=p.id,
            receivable_id=p.receivable_id,
            payment_date=p.payment_date,
            amount_cents=p.amount_cents,
            payment_method=p.payment_method,
            status=p.status,
            reversal_reason=p.reversal_reason,
            reversal_of_id=p.reversal_of_id,
            notes=p.notes,
            created_at=p.created_at,
        )
        for p in r.payments
    ]
    return SalesReceivableDetailResponse(
        **base.model_dump(),
        sale_date=r.sale.sale_date if r.sale else r.created_at,
        payments=payments,
    )


@router.get("/receivables", response_model=List[SalesReceivableResponse])
def get_receivables(
    customer_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    overdue_only: bool = Query(False),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta titulos a receber decorrentes de vendas fiadas."""
    receivables = list_receivables(
        db=db,
        customer_id=customer_id,
        status_filter=status,
        overdue_only=overdue_only,
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
    return serialize_receivable_detail(receivable)


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
        resp = ReceivablePaymentResponse.model_validate(payment).model_dump(mode="json")
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
        resp = ReceivablePaymentResponse.model_validate(payment).model_dump(mode="json")
        return status.HTTP_200_OK, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="RECEIVABLE_PAYMENT_CANCEL",
        payload={"payment_id": payment_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )

    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())
