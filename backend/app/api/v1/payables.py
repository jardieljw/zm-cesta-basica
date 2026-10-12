import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.financial import AccountPayable, PayablePayment
from app.models.base import utc_now
from app.schemas.financial import (
    AccountPayableCreate,
    AccountPayableResponse,
    AccountPayableDetailResponse,
    AccountPayableCancelRequest,
    PayablePaymentCreate,
    PayablePaymentCancelRequest,
    PayablePaymentResponse,
)
from app.services.financial import (
    list_accounts_payable,
    get_account_payable,
    create_account_payable,
    record_payable_payment,
    cancel_payable_payment,
    cancel_account_payable,
    generate_next_recurrence_payable,
)

router = APIRouter()


def serialize_payable(p: AccountPayable) -> AccountPayableResponse:
    now = utc_now()
    due = p.due_date
    if due.tzinfo is None and now.tzinfo is not None:
        due = due.replace(tzinfo=datetime.timezone.utc)
    is_overdue = due < now and p.status in ["OPEN", "PARTIAL"]

    c_at = p.created_at
    if c_at.tzinfo is None and now.tzinfo is not None:
        c_at = c_at.replace(tzinfo=datetime.timezone.utc)
    u_at = p.updated_at
    if u_at.tzinfo is None and now.tzinfo is not None:
        u_at = u_at.replace(tzinfo=datetime.timezone.utc)

    return AccountPayableResponse(
        id=p.id,
        payable_number=p.payable_number,
        description=p.description,
        beneficiary=p.beneficiary,
        category=p.category,
        nature=p.nature,
        original_amount_cents=p.original_amount_cents,
        paid_amount_cents=p.paid_amount_cents,
        balance_cents=p.balance_cents,
        due_date=due,
        payment_method=p.payment_method,
        status=p.status,
        is_overdue=is_overdue,
        purchase_id=p.purchase_id,
        installment_number=p.installment_number,
        total_installments=p.total_installments,
        installment_group_id=p.installment_group_id,
        is_recurrent=p.is_recurrent,
        recurrence_period=p.recurrence_period,
        notes=p.notes,
        created_at=c_at,
        updated_at=u_at,
        payments_count=len(p.payments) if p.payments else 0,
    )


def serialize_payable_detail(p: AccountPayable) -> AccountPayableDetailResponse:
    base = serialize_payable(p)
    payments = [
        PayablePaymentResponse(
            id=pay.id,
            payable_id=pay.payable_id,
            account_id=pay.account_id,
            account_name=pay.account.name if pay.account else None,
            payment_date=pay.payment_date,
            amount_cents=pay.amount_cents,
            payment_method=pay.payment_method,
            status=pay.status,
            reversal_reason=pay.reversal_reason,
            reversal_of_id=pay.reversal_of_id,
            notes=pay.notes,
            created_at=pay.created_at,
        )
        for pay in p.payments
    ]
    return AccountPayableDetailResponse(
        **base.model_dump(),
        payments=payments,
    )


@router.get("/payables", response_model=List[AccountPayableResponse])
def get_payables(
    due_date_from: Optional[datetime.datetime] = Query(None, description="Vencimento inicial"),
    due_date_to: Optional[datetime.datetime] = Query(None, description="Vencimento final"),
    month: Optional[int] = Query(None, ge=1, le=12, description="Mes do vencimento (1 a 12)"),
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Ano do vencimento"),
    category: Optional[str] = Query(None, description="Categoria"),
    beneficiary: Optional[str] = Query(None, description="Nome do favorecido/fornecedor"),
    status: Optional[str] = Query(None, description="OPEN, PARTIAL, PAID, CANCELED"),
    nature: Optional[str] = Query(None, description="BUSINESS ou PERSONAL_WITHDRAWAL"),
    overdue_only: bool = Query(False, description="Apenas titulos vencidos"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta contas a pagar com filtros por periodo, mes, ano, categoria, favorecido e situacao."""
    payables = list_accounts_payable(
        db=db,
        due_date_from=due_date_from,
        due_date_to=due_date_to,
        month=month,
        year=year,
        category=category,
        beneficiary=beneficiary,
        status_filter=status,
        nature=nature,
        overdue_only=overdue_only,
        limit=limit,
        offset=offset,
    )
    return [serialize_payable(p) for p in payables]


@router.post("/payables", response_model=List[AccountPayableResponse], status_code=status.HTTP_201_CREATED)
def post_payable(
    data: AccountPayableCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Cadastra uma obrigacao a pagar (individual ou parcelada com diferentes vencimentos).
    Envolvido em transacao idempotente via X-Idempotency-Key.
    """
    def callback(session: Session):
        created_list = create_account_payable(session, data)
        resp = [serialize_payable(p).model_dump(mode="json") for p in created_list]
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="ACCOUNT_PAYABLE_CREATE",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.get("/payables/{payable_id}", response_model=AccountPayableDetailResponse)
def get_payable_by_id(
    payable_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes de uma conta a pagar com historico de pagamentos."""
    payable = get_account_payable(db, payable_id)
    return serialize_payable_detail(payable)


@router.post("/payables/{payable_id}/payments", response_model=PayablePaymentResponse, status_code=status.HTTP_201_CREATED)
def post_payable_payment(
    payable_id: str,
    data: PayablePaymentCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra um pagamento parcial ou total de uma obrigacao, debitando a respectiva conta na tesouraria.
    """
    def callback(session: Session):
        payment = record_payable_payment(session, payable_id, data)
        resp = PayablePaymentResponse(
            id=payment.id,
            payable_id=payment.payable_id,
            account_id=payment.account_id,
            account_name=payment.account.name if payment.account else None,
            payment_date=payment.payment_date,
            amount_cents=payment.amount_cents,
            payment_method=payment.payment_method,
            status=payment.status,
            reversal_reason=payment.reversal_reason,
            reversal_of_id=payment.reversal_of_id,
            notes=payment.notes,
            created_at=payment.created_at,
        ).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PAYABLE_PAYMENT_CREATE",
        payload={"payable_id": payable_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/payables/{payable_id}/cancel", response_model=AccountPayableResponse)
def post_cancel_payable(
    payable_id: str,
    data: AccountPayableCancelRequest,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Cancela um titulo a pagar aberto sem pagamentos efetuados."""
    def callback(session: Session):
        payable = cancel_account_payable(session, payable_id, data)
        resp = serialize_payable(payable).model_dump(mode="json")
        return status.HTTP_200_OK, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="ACCOUNT_PAYABLE_CANCEL",
        payload={"payable_id": payable_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/payables/payments/{payment_id}/cancel", response_model=PayablePaymentResponse)
def post_cancel_payment(
    payment_id: str,
    data: PayablePaymentCancelRequest,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Estorna um pagamento efetuado, restabelecendo o saldo do titulo e creditando o valor na conta financeira."""
    def callback(session: Session):
        payment = cancel_payable_payment(session, payment_id, data)
        resp = PayablePaymentResponse(
            id=payment.id,
            payable_id=payment.payable_id,
            account_id=payment.account_id,
            account_name=payment.account.name if payment.account else None,
            payment_date=payment.payment_date,
            amount_cents=payment.amount_cents,
            payment_method=payment.payment_method,
            status=payment.status,
            reversal_reason=payment.reversal_reason,
            reversal_of_id=payment.reversal_of_id,
            notes=payment.notes,
            created_at=payment.created_at,
        ).model_dump(mode="json")
        return status.HTTP_200_OK, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="PAYABLE_PAYMENT_CANCEL",
        payload={"payment_id": payment_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/payables/{payable_id}/next-recurrence", response_model=AccountPayableResponse, status_code=status.HTTP_201_CREATED)
def post_next_recurrence(
    payable_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Gera a proxima parcela / ciclo de uma despesa recorrente."""
    def callback(session: Session):
        payable = generate_next_recurrence_payable(session, payable_id)
        resp = serialize_payable(payable).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="ACCOUNT_PAYABLE_NEXT_RECURRENCE",
        payload={"payable_id": payable_id},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())

