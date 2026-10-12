import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.models.dispatches import StockDispatch
from app.schemas.dispatches import (
    ResponsiblePersonCreate,
    ResponsiblePersonUpdate,
    ResponsiblePersonResponse,
    ResponsiblePersonCustodyResponse,
    StockDispatchCreate,
    StockDispatchResponse,
    StockDispatchDetailResponse,
    DispatchItemResponse,
    DispatchReturnCreate,
    DispatchReturnResponse,
    DispatchLossCreate,
    DispatchLossResponse,
    DispatchExpenseCreate,
    DispatchExpenseResponse,
    DispatchRepaymentCreate,
    DispatchRepaymentResponse,
    DispatchReconciliationResponse,
    DispatchSettlementCreate,
    DispatchSettlementInvestigationUpdate,
    DispatchSettlementResponse,
)
from app.services.dispatches import (
    create_responsible_person,
    update_responsible_person,
    get_responsible_person,
    list_responsible_persons,
    get_responsible_person_custody,
    create_dispatch,
    get_dispatch,
    list_dispatches,
    cancel_dispatch,
    record_dispatch_return,
    record_dispatch_loss,
    record_dispatch_expense,
    record_dispatch_repayment,
    calculate_dispatch_reconciliation,
    execute_dispatch_settlement,
    update_settlement_investigation,
)

router = APIRouter(prefix="/dispatches", tags=["Expedição / Custódia"])


class CancelDispatchBody(BaseModel):
    reason: str


def serialize_dispatch(d: StockDispatch) -> StockDispatchResponse:
    total_qty = sum(it.quantity for it in d.items)
    total_val = sum(it.quantity * it.unit_price_cents for it in d.items)
    return StockDispatchResponse(
        id=d.id,
        dispatch_number=d.dispatch_number,
        responsible_person_id=d.responsible_person_id,
        responsible_person_name=d.responsible_person.name if d.responsible_person else None,
        dispatch_date=d.dispatch_date,
        status=d.status,
        total_items_quantity=total_qty,
        total_reference_amount_cents=total_val,
        notes=d.notes,
        created_at=d.created_at,
        updated_at=d.updated_at,
    )


def serialize_dispatch_detail(d: StockDispatch) -> StockDispatchDetailResponse:
    base = serialize_dispatch(d)
    items = [
        DispatchItemResponse(
            id=it.id,
            dispatch_id=it.dispatch_id,
            basket_type_id=it.basket_type_id,
            basket_type_name=it.basket_type.name if it.basket_type else None,
            production_batch_id=it.production_batch_id,
            quantity=it.quantity,
            unit_price_cents=it.unit_price_cents,
            total_price_cents=it.quantity * it.unit_price_cents,
            notes=it.notes,
        )
        for it in d.items
    ]
    latest_st = None
    if d.settlements:
        latest_st = d.settlements[-1].status

    return StockDispatchDetailResponse(
        **base.model_dump(),
        items=items,
        sales_count=len(d.sales) if d.sales else 0,
        returns_count=len(d.returns) if d.returns else 0,
        losses_count=len(d.losses) if d.losses else 0,
        expenses_count=len(d.expenses) if d.expenses else 0,
        repayments_count=len(d.repayments) if d.repayments else 0,
        has_settlement=len(d.settlements) > 0,
        settlement_status=latest_st,
    )


# ==================== RESPONSIBLE PERSONS ====================

@router.post("/responsible-persons", response_model=ResponsiblePersonResponse, status_code=status.HTTP_201_CREATED)
def post_responsible_person(
    data: ResponsiblePersonCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Cadastra uma nova pessoa responsável por entregas ou custódia de cestas."""
    person = create_responsible_person(db, data)
    db.commit()
    return ResponsiblePersonResponse.model_validate(person)


@router.get("/responsible-persons", response_model=List[ResponsiblePersonResponse])
def get_responsible_persons(
    is_active: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Lista as pessoas responsáveis cadastradas com filtros de status e busca textual."""
    persons = list_responsible_persons(db, is_active=is_active, search=search)
    return [ResponsiblePersonResponse.model_validate(p) for p in persons]


@router.get("/responsible-persons/{person_id}", response_model=ResponsiblePersonResponse)
def get_responsible_person_detail(
    person_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes de uma pessoa responsável."""
    person = get_responsible_person(db, person_id)
    return ResponsiblePersonResponse.model_validate(person)


@router.put("/responsible-persons/{person_id}", response_model=ResponsiblePersonResponse)
def put_responsible_person(
    person_id: str,
    data: ResponsiblePersonUpdate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Atualiza dados cadastrais de uma pessoa responsável."""
    person = update_responsible_person(db, person_id, data)
    db.commit()
    return ResponsiblePersonResponse.model_validate(person)


@router.get("/responsible-persons/{person_id}/custody", response_model=ResponsiblePersonCustodyResponse)
def get_custody_balance(
    person_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta o saldo atual de cestas em trânsito sob custódia de um responsável."""
    return get_responsible_person_custody(db, person_id)


# ==================== STOCK DISPATCHES ====================

@router.post("", response_model=StockDispatchDetailResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch(
    data: StockDispatchCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Registra uma nova saída física de cestas para custódia externa sob BEGIN IMMEDIATE.
    Transfere formalmente o saldo do armazém da loja (STORE) para trânsito (TRANSIT).
    """
    def callback(session: Session):
        dispatch = create_dispatch(session, data)
        resp = serialize_dispatch_detail(dispatch).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_CREATE",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.get("", response_model=List[StockDispatchResponse])
def get_dispatches(
    responsible_person_id: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    start_date: Optional[datetime.datetime] = Query(None),
    end_date: Optional[datetime.datetime] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Lista saídas físicas por período, status ou responsável."""
    dispatches = list_dispatches(
        db=db,
        responsible_person_id=responsible_person_id,
        status_filter=status_filter,
        start_date=start_date,
        end_date=end_date,
        limit=limit,
        offset=offset,
    )
    return [serialize_dispatch(d) for d in dispatches]


@router.get("/{dispatch_id}", response_model=StockDispatchDetailResponse)
def get_dispatch_detail(
    dispatch_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes completos de uma saída física."""
    dispatch = get_dispatch(db, dispatch_id)
    return serialize_dispatch_detail(dispatch)


@router.post("/{dispatch_id}/cancel", response_model=StockDispatchResponse)
def post_cancel_dispatch(
    dispatch_id: str,
    body: CancelDispatchBody,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Cancela uma saída aberta sem operações subsequentes, retornando cestas ao estoque da loja."""
    dispatch = cancel_dispatch(db, dispatch_id, body.reason)
    db.commit()
    return serialize_dispatch(dispatch)


# ==================== RETURNS & LOSSES ====================

@router.post("/{dispatch_id}/returns", response_model=DispatchReturnResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch_return(
    dispatch_id: str,
    data: DispatchReturnCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Registra devolução física de cestas intactas de volta ao estoque da loja."""
    def callback(session: Session):
        ret = record_dispatch_return(session, dispatch_id, data)
        resp = DispatchReturnResponse(
            id=ret.id,
            dispatch_id=ret.dispatch_id,
            basket_type_id=ret.basket_type_id,
            basket_type_name=ret.basket_type.name if ret.basket_type else None,
            production_batch_id=ret.production_batch_id,
            quantity=ret.quantity,
            returned_at=ret.returned_at,
            notes=ret.notes,
            created_at=ret.created_at,
        ).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_RETURN",
        payload={"dispatch_id": dispatch_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/{dispatch_id}/losses", response_model=DispatchLossResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch_loss(
    dispatch_id: str,
    data: DispatchLossCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Registra avaria ou perda operacional de cestas durante o trânsito com justificativa obrigatória."""
    def callback(session: Session):
        loss = record_dispatch_loss(session, dispatch_id, data)
        resp = DispatchLossResponse(
            id=loss.id,
            dispatch_id=loss.dispatch_id,
            basket_type_id=loss.basket_type_id,
            basket_type_name=loss.basket_type.name if loss.basket_type else None,
            production_batch_id=loss.production_batch_id,
            quantity=loss.quantity,
            occurred_at=loss.occurred_at,
            reason=loss.reason,
            created_at=loss.created_at,
        ).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_LOSS",
        payload={"dispatch_id": dispatch_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


# ==================== EXPENSES & REPAYMENTS ====================

@router.post("/{dispatch_id}/expenses", response_model=DispatchExpenseResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch_expense(
    dispatch_id: str,
    data: DispatchExpenseCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Registra despesa de rota autorizada que abate do dinheiro esperado em mãos."""
    def callback(session: Session):
        expense = record_dispatch_expense(session, dispatch_id, data)
        resp = DispatchExpenseResponse.model_validate(expense).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_EXPENSE",
        payload={"dispatch_id": dispatch_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/{dispatch_id}/repayments", response_model=DispatchRepaymentResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch_repayment(
    dispatch_id: str,
    data: DispatchRepaymentCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Registra repasse financeiro de dinheiro entregue pelo responsável à empresa."""
    def callback(session: Session):
        repayment = record_dispatch_repayment(session, dispatch_id, data)
        resp = DispatchRepaymentResponse.model_validate(repayment).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_REPAYMENT",
        payload={"dispatch_id": dispatch_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


# ==================== RECONCILIATION & SETTLEMENT ====================

@router.get("/{dispatch_id}/reconciliation", response_model=DispatchReconciliationResponse)
def get_reconciliation(
    dispatch_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """
    Retorna a conferência em tempo real da saída física:
    - Equação física de 4 termos (Retiradas = Vendidas + Devolvidas + Perdidas + Em Custódia)
    - Equação financeira segregada (Dinheiro Esperado vs Dinheiro Entregue vs Pix Direto)
    - Destaque claro de eventuais divergências físicas e financeiras.
    """
    return calculate_dispatch_reconciliation(db, dispatch_id)


@router.post("/{dispatch_id}/settlement", response_model=DispatchSettlementResponse, status_code=status.HTTP_201_CREATED)
def post_dispatch_settlement(
    dispatch_id: str,
    data: DispatchSettlementCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """
    Realiza o fechamento operacional / conferência formal da saída física:
    - Se todas as quantidades e valores baterem sem divergências, conclui a saída.
    - Se houver divergências não justificadas, registra como PENDING_INVESTIGATION sem mascarar dados.
    """
    def callback(session: Session):
        settlement = execute_dispatch_settlement(session, dispatch_id, data)
        resp = DispatchSettlementResponse.model_validate(settlement).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="DISPATCH_SETTLEMENT",
        payload={"dispatch_id": dispatch_id, **data.model_dump(mode="json")},
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.put("/{dispatch_id}/settlement/investigation", response_model=DispatchSettlementResponse)
def put_settlement_investigation(
    dispatch_id: str,
    data: DispatchSettlementInvestigationUpdate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Documenta investigação e resolução de divergências apuradas na conferência."""
    settlement = update_settlement_investigation(db, dispatch_id, data)
    db.commit()
    return DispatchSettlementResponse.model_validate(settlement)
