import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.api.deps import get_current_device, get_idempotency_key
from app.models.auth import PairedDevice
from app.schemas.financial import (
    FinancialAccountCreate,
    FinancialAccountUpdate,
    FinancialAccountResponse,
    CashFlowEntryCreate,
    CashFlowEntryResponse,
    FinancialTransferCreate,
    FinancialTransferResponse,
    TreasurySummaryResponse,
)
from app.services.financial import (
    list_financial_accounts,
    get_financial_account,
    create_financial_account,
    update_financial_account,
    list_cash_flow_entries,
    record_cash_flow_entry,
    transfer_between_accounts,
    get_treasury_summary,
)

router = APIRouter()


@router.get("/treasury/accounts", response_model=List[FinancialAccountResponse])
def get_accounts(
    is_active: Optional[bool] = Query(None, description="Filtrar por status ativo"),
    account_type: Optional[str] = Query(None, description="Filtrar por tipo (CASH, BANK, OTHER)"),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Lista contas financeiras cadastradas com seus saldos atuais verificados."""
    accounts = list_financial_accounts(db, is_active=is_active, account_type=account_type)
    return [FinancialAccountResponse.model_validate(a) for a in accounts]


@router.post("/treasury/accounts", response_model=FinancialAccountResponse, status_code=status.HTTP_201_CREATED)
def post_account(
    data: FinancialAccountCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Cadastra uma nova conta financeira (caixa físico, banco ou cofre)."""
    def callback(session: Session):
        acc = create_financial_account(session, data)
        resp = FinancialAccountResponse.model_validate(acc).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="FINANCIAL_ACCOUNT_CREATE",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.get("/treasury/accounts/{account_id}", response_model=FinancialAccountResponse)
def get_account_by_id(
    account_id: str,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta detalhes de uma conta financeira especifica."""
    acc = get_financial_account(db, account_id)
    return FinancialAccountResponse.model_validate(acc)


@router.patch("/treasury/accounts/{account_id}", response_model=FinancialAccountResponse)
def patch_account(
    account_id: str,
    data: FinancialAccountUpdate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Atualiza dados cadastrais de uma conta financeira."""
    acc = update_financial_account(db, account_id, data)
    return FinancialAccountResponse.model_validate(acc)


@router.get("/treasury/entries", response_model=List[CashFlowEntryResponse])
def get_cash_flow_entries(
    account_id: Optional[str] = Query(None, description="Filtrar por conta"),
    entry_type: Optional[str] = Query(None, description="CREDIT ou DEBIT"),
    category: Optional[str] = Query(None, description="Categoria"),
    nature: Optional[str] = Query(None, description="BUSINESS ou PERSONAL_WITHDRAWAL"),
    source_type: Optional[str] = Query(None, description="Origem da movimentacao"),
    start_date: Optional[datetime.datetime] = Query(None, description="Data inicial"),
    end_date: Optional[datetime.datetime] = Query(None, description="Data final"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta o livro-caixa imutavel da empresa com filtros operacionais."""
    entries = list_cash_flow_entries(
        db=db,
        account_id=account_id,
        entry_type=entry_type,
        category=category,
        nature=nature,
        source_type=source_type,
        start_date=start_date,
        end_date=end_date,
        limit=limit,
        offset=offset,
    )
    return [
        CashFlowEntryResponse(
            id=e.id,
            account_id=e.account_id,
            account_name=e.account.name if e.account else None,
            entry_type=e.entry_type,
            amount_cents=e.amount_cents,
            category=e.category,
            nature=e.nature,
            description=e.description,
            source_type=e.source_type,
            source_id=e.source_id,
            payment_method=e.payment_method,
            occurred_at=e.occurred_at,
            reversal_of_id=e.reversal_of_id,
            is_reversal=e.is_reversal,
            notes=e.notes,
            created_at=e.created_at,
        )
        for e in entries
    ]


@router.post("/treasury/entries", response_model=CashFlowEntryResponse, status_code=status.HTTP_201_CREATED)
def post_manual_entry(
    data: CashFlowEntryCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Registra uma entrada ou saida manual direta na tesouraria (ex: aporte, sangria, ajuste de caixa)."""
    def callback(session: Session):
        entry = record_cash_flow_entry(
            db=session,
            account_id=data.account_id,
            entry_type=data.entry_type.upper(),
            amount_cents=data.amount_cents,
            category=data.category.upper(),
            nature=data.nature.upper(),
            description=data.description,
            source_type=data.source_type.upper() if data.source_type else "MANUAL",
            source_id=data.source_id,
            payment_method=data.payment_method.upper(),
            occurred_at=data.occurred_at,
            notes=data.notes,
        )
        resp = CashFlowEntryResponse(
            id=entry.id,
            account_id=entry.account_id,
            account_name=entry.account.name if entry.account else None,
            entry_type=entry.entry_type,
            amount_cents=entry.amount_cents,
            category=entry.category,
            nature=entry.nature,
            description=entry.description,
            source_type=entry.source_type,
            source_id=entry.source_id,
            payment_method=entry.payment_method,
            occurred_at=entry.occurred_at,
            reversal_of_id=entry.reversal_of_id,
            is_reversal=entry.is_reversal,
            notes=entry.notes,
            created_at=entry.created_at,
        ).model_dump(mode="json")
        return status.HTTP_201_CREATED, resp

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="TREASURY_ENTRY_MANUAL",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.post("/treasury/transfers", response_model=FinancialTransferResponse, status_code=status.HTTP_201_CREATED)
def post_transfer(
    data: FinancialTransferCreate,
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
    idempotency_key: Optional[str] = Depends(get_idempotency_key),
):
    """Transfere recursos entre contas financeiras (ex: deposito de caixa fisico para conta bancaria)."""
    def callback(session: Session):
        transfer_resp = transfer_between_accounts(session, data)
        return status.HTTP_201_CREATED, transfer_resp.model_dump(mode="json")

    result = process_transactional_idempotency(
        db=db,
        idempotency_key=idempotency_key,
        operation_type="TREASURY_TRANSFER",
        payload=data.model_dump(mode="json"),
        business_callback=callback,
    )
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


@router.get("/treasury/summary", response_model=TreasurySummaryResponse)
def get_summary(
    start_date: Optional[datetime.datetime] = Query(None, description="Data inicial do periodo para analise de fluxo"),
    end_date: Optional[datetime.datetime] = Query(None, description="Data final do periodo"),
    db: Session = Depends(get_db),
    device: PairedDevice = Depends(get_current_device),
):
    """Consulta indicadores consolidados de tesouraria: saldos reais, compromissos futuros e saldo projetado."""
    return get_treasury_summary(db, start_date=start_date, end_date=end_date)
