import uuid
import datetime
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy import select, func, desc, or_, and_
from sqlalchemy.orm import Session, selectinload
from fastapi import HTTPException, status

from app.models.financial import (
    FinancialAccount,
    CashFlowEntry,
    AccountPayable,
    PayablePayment,
)
from app.models.purchases import Purchase
from app.models.sales import SalesReceivable
from app.models.dispatches import StockDispatch
from app.models.base import utc_now
from app.core.business_dates import business_today, business_day_start
from app.schemas.financial import (
    FinancialAccountCreate,
    FinancialAccountUpdate,
    CashFlowEntryCreate,
    FinancialTransferCreate,
    FinancialTransferResponse,
    AccountPayableCreate,
    AccountPayableCancelRequest,
    PayablePaymentCreate,
    PayablePaymentCancelRequest,
    TreasurySummaryResponse,
    FinancialAccountResponse,
)


def generate_next_payable_number(db: Session) -> int:
    """Generates the next sequential unique payable number under active transaction lock."""
    stmt = select(func.coalesce(func.max(AccountPayable.payable_number), 0))
    max_num = db.execute(stmt).scalar_one()
    return int(max_num) + 1


def ensure_default_financial_account(db: Session) -> FinancialAccount:
    """Ensures at least one default active financial account exists."""
    acc = db.execute(
        select(FinancialAccount).where(FinancialAccount.is_active.is_(True))
    ).scalars().first()
    if not acc:
        now = utc_now()
        acc = FinancialAccount(
            id="00000000-0000-0000-0000-caixa0000001",
            name="Caixa Físico da Loja",
            account_type="CASH",
            initial_balance_cents=0,
            current_balance_cents=0,
            is_active=True,
            is_default=True,
            notes="Caixa físico padrão do armazém da loja",
            created_at=now,
            updated_at=now,
        )
        db.add(acc)
        db.commit()
    return acc


def get_default_financial_account(db: Session, account_type: Optional[str] = None) -> Optional[FinancialAccount]:
    """Retrieves the default active financial account for the given type, or falls back to the first active account."""
    stmt = select(FinancialAccount).where(FinancialAccount.is_active.is_(True))
    if account_type:
        stmt = stmt.where(FinancialAccount.account_type == account_type)

    stmt_default = stmt.where(FinancialAccount.is_default.is_(True)).order_by(FinancialAccount.created_at.asc()).limit(1)
    acc = db.execute(stmt_default).scalar_one_or_none()
    if acc:
        return acc

    stmt_fallback = stmt.order_by(FinancialAccount.created_at.asc()).limit(1)
    acc = db.execute(stmt_fallback).scalar_one_or_none()
    if acc:
        return acc

    return ensure_default_financial_account(db)


def calculate_account_balance(db: Session, account_id: str) -> int:
    """Calculates live exact ledger balance: initial_balance + credits - debits."""
    acc = db.get(FinancialAccount, account_id)
    if not acc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Conta '{account_id}' nao encontrada.")

    credits_stmt = select(func.coalesce(func.sum(CashFlowEntry.amount_cents), 0)).where(
        CashFlowEntry.account_id == account_id,
        CashFlowEntry.entry_type == "CREDIT",
    )
    credits_sum = db.execute(credits_stmt).scalar_one()

    debits_stmt = select(func.coalesce(func.sum(CashFlowEntry.amount_cents), 0)).where(
        CashFlowEntry.account_id == account_id,
        CashFlowEntry.entry_type == "DEBIT",
    )
    debits_sum = db.execute(debits_stmt).scalar_one()

    return int(acc.initial_balance_cents + credits_sum - debits_sum)


def record_cash_flow_entry(
    db: Session,
    account_id: str,
    entry_type: str,
    amount_cents: int,
    category: str,
    description: str,
    nature: str = "BUSINESS",
    source_type: str = "MANUAL",
    source_id: Optional[str] = None,
    payment_method: str = "CASH",
    occurred_at: Optional[datetime.datetime] = None,
    notes: Optional[str] = None,
    reversal_of_id: Optional[str] = None,
    is_reversal: bool = False,
    allow_duplicate_source: bool = False,
) -> CashFlowEntry:
    """
    Appends an immutable entry to cash_flow_entries and atomically updates account current balance.
    Guarantees no double-counting by checking source_type and source_id unless allow_duplicate_source=True.
    """
    if amount_cents <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Valor do lancamento deve ser maior que zero ({amount_cents} informado).",
        )

    acc = db.get(FinancialAccount, account_id)
    if not acc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Conta financeira '{account_id}' nao encontrada.")
    if not acc.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Conta financeira '{acc.name}' esta inativa.")

    # Duplicate check for source document
    if source_id and not allow_duplicate_source and not is_reversal:
        existing = db.execute(
            select(CashFlowEntry).where(
                CashFlowEntry.source_type == source_type,
                CashFlowEntry.source_id == source_id,
                CashFlowEntry.is_reversal.is_(False),
            )
        ).scalars().first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Lancamento de tesouraria ja existente para a operacao {source_type} #{source_id}.",
            )

    now = utc_now()
    entry = CashFlowEntry(
        id=str(uuid.uuid4()),
        account_id=acc.id,
        entry_type=entry_type,
        amount_cents=amount_cents,
        category=category,
        nature=nature,
        description=description.strip(),
        source_type=source_type,
        source_id=source_id,
        payment_method=payment_method,
        occurred_at=occurred_at or now,
        reversal_of_id=reversal_of_id,
        is_reversal=is_reversal,
        notes=notes.strip() if notes else None,
        created_at=now,
    )
    db.add(entry)

    # Atomically adjust account balance
    if entry_type == "CREDIT":
        acc.current_balance_cents += amount_cents
    elif entry_type == "DEBIT":
        acc.current_balance_cents -= amount_cents
    acc.updated_at = now

    db.flush()
    return entry


# ==================== FINANCIAL ACCOUNTS ====================

def list_financial_accounts(
    db: Session,
    is_active: Optional[bool] = None,
    account_type: Optional[str] = None,
) -> List[FinancialAccount]:
    """Lists financial accounts with up-to-date live balance verification."""
    ensure_default_financial_account(db)
    stmt = select(FinancialAccount)
    if is_active is not None:
        stmt = stmt.where(FinancialAccount.is_active == is_active)
    if account_type is not None:
        stmt = stmt.where(FinancialAccount.account_type == account_type)

    stmt = stmt.order_by(FinancialAccount.is_default.desc(), FinancialAccount.name.asc())
    accounts = list(db.execute(stmt).scalars().all())

    # Ensure current_balance_cents matches live ledger
    for acc in accounts:
        live_bal = calculate_account_balance(db, acc.id)
        if acc.current_balance_cents != live_bal:
            acc.current_balance_cents = live_bal
            db.flush()

    return accounts


def get_financial_account(db: Session, account_id: str) -> FinancialAccount:
    """Retrieves single financial account with balance verification."""
    acc = db.get(FinancialAccount, account_id)
    if not acc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Conta '{account_id}' nao encontrada.")
    acc.current_balance_cents = calculate_account_balance(db, acc.id)
    db.flush()
    return acc


def create_financial_account(db: Session, data: FinancialAccountCreate) -> FinancialAccount:
    """Creates a financial account and unsets other defaults if marked default."""
    if data.is_default:
        db.execute(
            select(FinancialAccount).where(FinancialAccount.account_type == data.account_type)
        )
        existing_defaults = db.execute(
            select(FinancialAccount).where(
                FinancialAccount.account_type == data.account_type,
                FinancialAccount.is_default.is_(True),
            )
        ).scalars().all()
        for d in existing_defaults:
            d.is_default = False

    now = utc_now()
    acc = FinancialAccount(
        id=str(uuid.uuid4()),
        name=data.name.strip(),
        account_type=data.account_type.upper(),
        bank_name=data.bank_name.strip() if data.bank_name else None,
        account_number=data.account_number.strip() if data.account_number else None,
        initial_balance_cents=data.initial_balance_cents,
        current_balance_cents=data.initial_balance_cents,
        is_active=True,
        is_default=data.is_default,
        notes=data.notes.strip() if data.notes else None,
        created_at=now,
        updated_at=now,
    )
    db.add(acc)
    db.flush()
    return acc


def update_financial_account(db: Session, account_id: str, data: FinancialAccountUpdate) -> FinancialAccount:
    """Updates non-monetary attributes of a financial account."""
    acc = get_financial_account(db, account_id)

    if data.name is not None:
        acc.name = data.name.strip()
    if data.bank_name is not None:
        acc.bank_name = data.bank_name.strip() if data.bank_name else None
    if data.account_number is not None:
        acc.account_number = data.account_number.strip() if data.account_number else None
    if data.is_active is not None:
        acc.is_active = data.is_active
    if data.notes is not None:
        acc.notes = data.notes.strip() if data.notes else None
    if data.is_default is not None:
        if data.is_default:
            other_defaults = db.execute(
                select(FinancialAccount).where(
                    FinancialAccount.account_type == acc.account_type,
                    FinancialAccount.id != acc.id,
                    FinancialAccount.is_default.is_(True),
                )
            ).scalars().all()
            for od in other_defaults:
                od.is_default = False
        acc.is_default = data.is_default

    acc.updated_at = utc_now()
    db.flush()
    return acc


# ==================== TRANSFERS ====================

def transfer_between_accounts(db: Session, data: FinancialTransferCreate) -> FinancialTransferResponse:
    """
    Executes atomic transfer between financial accounts:
    - Debits source account (TRANSFER_OUT)
    - Credits destination account (TRANSFER_IN)
    - Links both entries under same transfer ID
    """
    if data.source_account_id == data.destination_account_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Conta de origem e conta de destino devem ser distintas.",
        )

    src_acc = get_financial_account(db, data.source_account_id)
    dst_acc = get_financial_account(db, data.destination_account_id)

    if not src_acc.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Conta de origem '{src_acc.name}' esta inativa.")
    if not dst_acc.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Conta de destino '{dst_acc.name}' esta inativa.")

    transfer_id = str(uuid.uuid4())
    transfer_date = data.transfer_date or utc_now()
    desc_text = data.description.strip() if data.description else "Transferencia entre contas"

    # 1. Debit source
    src_entry = record_cash_flow_entry(
        db=db,
        account_id=src_acc.id,
        entry_type="DEBIT",
        amount_cents=data.amount_cents,
        category="TRANSFERENCIA",
        description=f"{desc_text} para {dst_acc.name}",
        nature="BUSINESS",
        source_type="TRANSFER",
        source_id=transfer_id,
        payment_method="BANK_TRANSFER" if (src_acc.account_type == "BANK" or dst_acc.account_type == "BANK") else "CASH",
        occurred_at=transfer_date,
        notes=data.notes,
        allow_duplicate_source=True,
    )

    # 2. Credit destination
    dst_entry = record_cash_flow_entry(
        db=db,
        account_id=dst_acc.id,
        entry_type="CREDIT",
        amount_cents=data.amount_cents,
        category="TRANSFERENCIA",
        description=f"{desc_text} de {src_acc.name}",
        nature="BUSINESS",
        source_type="TRANSFER",
        source_id=transfer_id,
        payment_method="BANK_TRANSFER" if (src_acc.account_type == "BANK" or dst_acc.account_type == "BANK") else "CASH",
        occurred_at=transfer_date,
        notes=data.notes,
        allow_duplicate_source=True,
    )

    return FinancialTransferResponse(
        transfer_id=transfer_id,
        source_account_id=src_acc.id,
        source_account_name=src_acc.name,
        destination_account_id=dst_acc.id,
        destination_account_name=dst_acc.name,
        amount_cents=data.amount_cents,
        transfer_date=transfer_date,
        source_entry_id=src_entry.id,
        destination_entry_id=dst_entry.id,
        description=desc_text,
        notes=data.notes,
    )


# ==================== ACCOUNTS PAYABLE ====================

def create_account_payable(db: Session, data: AccountPayableCreate) -> List[AccountPayable]:
    """
    Creates one or multiple installment payable titles under active transaction lock.
    If total_installments > 1, splits total amount with exact penny precision and sets installment_group_id.
    """
    if data.total_installments <= 1:
        payable_id = str(uuid.uuid4())
        num = generate_next_payable_number(db)
        now = utc_now()
        payable = AccountPayable(
            id=payable_id,
            payable_number=num,
            description=data.description.strip(),
            beneficiary=data.beneficiary.strip(),
            category=data.category.upper(),
            nature=data.nature.upper(),
            original_amount_cents=data.original_amount_cents,
            paid_amount_cents=0,
            balance_cents=data.original_amount_cents,
            due_date=data.due_date,
            payment_method=data.payment_method.upper(),
            status="OPEN",
            purchase_id=data.purchase_id,
            installment_number=1,
            total_installments=1,
            installment_group_id=None,
            is_recurrent=data.is_recurrent,
            recurrence_period=data.recurrence_period.upper() if data.recurrence_period else None,
            notes=data.notes.strip() if data.notes else None,
            created_at=now,
            updated_at=now,
        )
        db.add(payable)
        db.flush()
        return [payable]

    # Multi-installment generation
    group_id = str(uuid.uuid4())
    n = data.total_installments
    base_amount = data.original_amount_cents // n
    remainder = data.original_amount_cents % n

    created_payables: List[AccountPayable] = []
    base_due = data.due_date
    base_num = generate_next_payable_number(db)

    for i in range(n):
        inst_num = i + 1
        inst_amount = base_amount + (1 if i < remainder else 0)

        if data.installment_due_dates and i < len(data.installment_due_dates):
            inst_due = data.installment_due_dates[i]
        else:
            # Add approx 30 days per installment
            inst_due = base_due + datetime.timedelta(days=30 * i)

        p_id = str(uuid.uuid4())
        num = base_num + i
        now = utc_now()

        p = AccountPayable(
            id=p_id,
            payable_number=num,
            description=f"{data.description.strip()} (Parcela {inst_num}/{n})",
            beneficiary=data.beneficiary.strip(),
            category=data.category.upper(),
            nature=data.nature.upper(),
            original_amount_cents=inst_amount,
            paid_amount_cents=0,
            balance_cents=inst_amount,
            due_date=inst_due,
            payment_method=data.payment_method.upper(),
            status="OPEN",
            purchase_id=data.purchase_id,
            installment_number=inst_num,
            total_installments=n,
            installment_group_id=group_id,
            is_recurrent=data.is_recurrent,
            recurrence_period=data.recurrence_period.upper() if data.recurrence_period else None,
            notes=data.notes.strip() if data.notes else None,
            created_at=now,
            updated_at=now,
        )
        db.add(p)
        created_payables.append(p)

    db.flush()
    return created_payables


def record_payable_payment(db: Session, payable_id: str, data: PayablePaymentCreate) -> PayablePayment:
    """
    Records full or partial payment of an account payable:
    - Validates amount does not exceed remaining balance
    - Debits financial account in cash_flow_entries
    - Updates payable balance and status (PARTIAL or PAID)
    """
    payable = db.execute(
        select(AccountPayable).options(selectinload(AccountPayable.payments)).where(AccountPayable.id == payable_id)
    ).scalar_one_or_none()

    if not payable:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error_code": "PAYABLE_NOT_FOUND", "message": "Conta a pagar não encontrada."})

    # The callback runs under the existing BEGIN IMMEDIATE transaction. Replay
    # is resolved before this callback, including when a prior payment quit the title.
    if data.expected_balance_cents is not None and data.expected_balance_cents != payable.balance_cents:
        raise HTTPException(status_code=409, detail={"error_code": "PAYABLE_BALANCE_CHANGED", "message": "O saldo mudou. Confira o valor atualizado antes de registrar."})

    if data.expected_balance_cents is not None and data.payment_method.upper() not in {"DINHEIRO", "PIX", "BOLETO", "TRANSFERENCIA", "CHEQUE", "CARTAO_CREDITO", "OUTRO"}:
        raise HTTPException(status_code=400, detail={"error_code": "PAYABLE_PAYMENT_METHOD_INVALID", "message": "Selecione uma forma de pagamento válida."})

    if payable.status not in ["OPEN", "PARTIAL"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "PAYABLE_NOT_OPEN", "message": "Esta conta não está aberta para pagamento."},
        )

    if data.amount_cents > payable.balance_cents:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "PAYABLE_AMOUNT_EXCEEDS_BALANCE", "message": "O valor informado excede o saldo em aberto."},
        )

    acc = (get_financial_account(db, data.account_id)
           if data.account_id is not None else get_default_financial_account(db))
    payment_id = str(uuid.uuid4())
    now = utc_now()
    payment_date = (business_day_start(data.payment_business_date)
                    if data.payment_business_date is not None else data.payment_date or now)

    payment = PayablePayment(
        id=payment_id,
        payable_id=payable.id,
        account_id=acc.id,
        payment_date=payment_date,
        amount_cents=data.amount_cents,
        payment_method=data.payment_method.upper(),
        status="CONFIRMED",
        notes=data.notes.strip() if data.notes else None,
        created_at=now,
    )
    from app.services.financial_payment_composition import snapshot_payment
    snapshot_payment(db, payable, payment, data.expected_bill_revision)
    db.add(payment)

    # Post immutable cash flow debit
    record_cash_flow_entry(
        db=db,
        account_id=acc.id,
        entry_type="DEBIT",
        amount_cents=data.amount_cents,
        category=payable.category,
        nature=payable.nature,
        description=f"Pagamento obrigacao #{payable.payable_number} - {payable.description} ({payable.beneficiary})",
        source_type="PAYABLE_PAYMENT",
        source_id=payment.id,
        payment_method=data.payment_method.upper(),
        occurred_at=payment_date,
        notes=data.notes,
    )

    payable.paid_amount_cents += data.amount_cents
    payable.balance_cents = payable.original_amount_cents - payable.paid_amount_cents
    payable.status = "PAID" if payable.balance_cents == 0 else "PARTIAL"
    payable.updated_at = now

    db.flush()
    return payment


def cancel_payable_payment(db: Session, payment_id: str, data: PayablePaymentCancelRequest) -> PayablePayment:
    """
    Cancels/reverses a payment made on an account payable:
    - Restores payable balance and status
    - Appends reverse credit movement in cash_flow_entries
    - Marks payment as REVERSED
    """
    payment = db.execute(
        select(PayablePayment).options(selectinload(PayablePayment.payable)).where(PayablePayment.id == payment_id)
    ).scalar_one_or_none()

    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Pagamento '{payment_id}' nao encontrado.")

    if payment.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Apenas pagamentos confirmados podem ser estornados. Status atual: {payment.status}.",
        )

    payable = payment.payable
    if payable.superseded_by_id:
        raise HTTPException(409, detail={'error_code': 'FINANCIAL_BILL_REPLACEMENT_CONFLICT', 'message': 'O saldo deste titulo foi transferido. Confira o vinculo antes de estornar.'})
    acc = get_financial_account(db, payment.account_id)
    now = utc_now()

    # Restore payable balance
    payable.paid_amount_cents -= payment.amount_cents
    payable.balance_cents = payable.original_amount_cents - payable.paid_amount_cents
    payable.status = "PARTIAL" if payable.paid_amount_cents > 0 else "OPEN"
    payable.updated_at = now

    orig_entry = db.execute(
        select(CashFlowEntry).where(
            CashFlowEntry.source_type == "PAYABLE_PAYMENT",
            CashFlowEntry.source_id == payment.id,
            CashFlowEntry.is_reversal.is_(False),
        )
    ).scalars().first()

    # Append reversal credit to account
    record_cash_flow_entry(
        db=db,
        account_id=acc.id,
        entry_type="CREDIT",
        amount_cents=payment.amount_cents,
        category=payable.category,
        nature=payable.nature,
        description=f"Estorno pagamento #{payment.id[:8]} da obrigacao #{payable.payable_number}: {data.reason.strip()}",
        source_type="PAYABLE_PAYMENT",
        source_id=payment.id,
        payment_method=payment.payment_method,
        occurred_at=now,
        is_reversal=True,
        reversal_of_id=orig_entry.id if orig_entry else None,
        allow_duplicate_source=True,
    )

    payment.status = "REVERSED"
    payment.reversal_reason = data.reason.strip()
    db.flush()
    return payment


def cancel_account_payable(db: Session, payable_id: str, data: AccountPayableCancelRequest) -> AccountPayable:
    """Cancels an open payable title with zero payments made."""
    payable = db.execute(
        select(AccountPayable).options(selectinload(AccountPayable.payments)).where(AccountPayable.id == payable_id)
    ).scalar_one_or_none()

    if not payable:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Obrigacao a pagar '{payable_id}' nao encontrada.")

    from app.models.financial_bill_cycles import FinancialBillCycle
    if payable.superseded_by_id or db.scalar(select(FinancialBillCycle.id).where(FinancialBillCycle.payable_id == payable.id)):
        raise HTTPException(409, detail={'error_code': 'FINANCIAL_BILL_REPLACEMENT_CONFLICT', 'message': 'Esta cobranca exige revisao de seus vinculos antes de cancelar.'})

    if payable.status == "CANCELED":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Titulo a pagar ja se encontra cancelado.")

    if payable.paid_amount_cents > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Nao e possivel cancelar titulo com pagamentos efetuados ({payable.paid_amount_cents} centavos pagos). Estorne os pagamentos primeiro.",
        )

    payable.status = "CANCELED"
    payable.balance_cents = 0
    now = utc_now()
    payable.updated_at = now
    reason_clean = data.reason.strip()
    if payable.notes:
        payable.notes += f" | Cancelado: {reason_clean}"
    else:
        payable.notes = f"Cancelado: {reason_clean}"

    db.flush()
    return payable


def generate_next_recurrence_payable(db: Session, payable_id: str) -> AccountPayable:
    """
    Generates the next occurrence for a recurring payable (e.g. monthly rent, utilities):
    - Validates that the original payable has is_recurrent=True
    - Calculates next due date according to recurrence_period (MONTHLY = +30 days, WEEKLY = +7 days, YEARLY = +365 days)
    - Creates a new OPEN payable title with the next sequential payable number
    """
    payable = get_account_payable(db, payable_id)
    if not payable.is_recurrent:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Obrigacao #{payable.payable_number} nao esta configurada como recorrente.",
        )

    period = (payable.recurrence_period or "MONTHLY").upper()
    if period == "WEEKLY":
        delta = datetime.timedelta(days=7)
    elif period == "YEARLY":
        delta = datetime.timedelta(days=365)
    else:  # MONTHLY default
        delta = datetime.timedelta(days=30)

    next_due = payable.due_date + delta
    now = utc_now()
    p_id = str(uuid.uuid4())
    p_num = generate_next_payable_number(db)

    next_payable = AccountPayable(
        id=p_id,
        payable_number=p_num,
        description=f"{payable.description} (Recorrencia)",
        beneficiary=payable.beneficiary,
        category=payable.category,
        nature=payable.nature,
        original_amount_cents=payable.original_amount_cents,
        paid_amount_cents=0,
        balance_cents=payable.original_amount_cents,
        due_date=next_due,
        payment_method=payable.payment_method,
        status="OPEN",
        purchase_id=None,
        installment_number=payable.installment_number + 1,
        total_installments=payable.total_installments,
        installment_group_id=payable.installment_group_id,
        is_recurrent=True,
        recurrence_period=payable.recurrence_period,
        notes=f"Gerado a partir da recorrencia #{payable.payable_number}",
        created_at=now,
        updated_at=now,
    )
    db.add(next_payable)
    db.flush()
    return next_payable


def get_account_payable(db: Session, payable_id: str) -> AccountPayable:
    """Retrieves single payable with payment history."""
    stmt = (
        select(AccountPayable)
        .options(selectinload(AccountPayable.payments))
        .where(AccountPayable.id == payable_id)
    )
    payable = db.execute(stmt).scalar_one_or_none()
    if not payable:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Obrigacao '{payable_id}' nao encontrada.")
    return payable


def list_accounts_payable(
    db: Session,
    due_date_from: Optional[datetime.datetime] = None,
    due_date_to: Optional[datetime.datetime] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    category: Optional[str] = None,
    beneficiary: Optional[str] = None,
    status_filter: Optional[str] = None,
    nature: Optional[str] = None,
    overdue_only: bool = False,
    limit: int = 100,
    offset: int = 0,
    source_id: Optional[str] = None,
    merchant: Optional[str] = None,
    summary_only: bool = False,
    source_query: Optional[str] = None,
) -> List[AccountPayable]:
    """Lists accounts payable with multi-criteria filtering."""
    from app.services.financial_import_removals import hidden_payables
    stmt = select(AccountPayable).options(selectinload(AccountPayable.payments)).where(AccountPayable.id.not_in(hidden_payables(db)))

    if due_date_from:
        stmt = stmt.where(func.date(AccountPayable.due_date) >= due_date_from.date().isoformat())
    if due_date_to:
        stmt = stmt.where(func.date(AccountPayable.due_date) <= due_date_to.date().isoformat())

    if source_id or source_query or merchant:
        from app.models.financial_bill_cycles import FinancialBillCycle, FinancialBillCycleRevision
        from app.models.financial_imports import FinancialStatementItem, FinancialSource
        cycles = select(FinancialBillCycle.payable_id)
        if source_id:
            cycles = cycles.where(FinancialBillCycle.source_id == source_id)
        if source_query:
            sources = select(FinancialSource.id).where(or_(
                FinancialSource.name.icontains(source_query.strip(), autoescape=True),
                FinancialSource.institution.icontains(source_query.strip(), autoescape=True)))
            cycles = cycles.where(FinancialBillCycle.source_id.in_(sources))
        if merchant:
            matching = select(FinancialStatementItem.statement_id).where(
                func.json_extract(FinancialStatementItem.normalized_data, '$.description').icontains(merchant.strip(), autoescape=True))
            cycles = cycles.join(FinancialBillCycleRevision, and_(
                FinancialBillCycleRevision.cycle_id == FinancialBillCycle.id,
                FinancialBillCycleRevision.revision == FinancialBillCycle.revision)).where(
                    FinancialBillCycleRevision.statement_id.in_(matching))
        stmt = stmt.where(AccountPayable.id.in_(cycles))

    if year:
        # SQLite strftime filter for year
        stmt = stmt.where(func.strftime('%Y', AccountPayable.due_date) == str(year))
    if month:
        m_str = f"{month:02d}"
        stmt = stmt.where(func.strftime('%m', AccountPayable.due_date) == m_str)

    if category:
        stmt = stmt.where(AccountPayable.category == category.upper())
    if beneficiary:
        stmt = stmt.where(AccountPayable.beneficiary.ilike(f"%{beneficiary.strip()}%"))
    if status_filter:
        stmt = stmt.where(AccountPayable.status == status_filter.upper())
    if nature:
        stmt = stmt.where(AccountPayable.nature == nature.upper())
    if overdue_only:
        stmt = stmt.where(
            func.date(AccountPayable.due_date) < business_today(utc_now()).isoformat(),
            AccountPayable.status.in_(["OPEN", "PARTIAL"]),
        )

    if summary_only:
        # The same predicates, before pagination; a matching item counts its bill once.
        rows = db.execute(stmt.with_only_columns(AccountPayable.balance_cents, AccountPayable.paid_amount_cents,
            AccountPayable.status, AccountPayable.due_date)).all()
        today = business_today(utc_now())
        return dict(count=len(rows), open_cents=sum(r.balance_cents for r in rows if r.status in {'OPEN','PARTIAL'}),
            overdue_cents=sum(r.balance_cents for r in rows if r.status in {'OPEN','PARTIAL'} and r.due_date.date() < today),
            paid_cents=sum(r.paid_amount_cents for r in rows), business_today=today.isoformat())
    stmt = stmt.order_by(AccountPayable.due_date.asc(), desc(AccountPayable.payable_number)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())


# ==================== CASH FLOW ENTRIES LISTING ====================

def list_cash_flow_entries(
    db: Session,
    account_id: Optional[str] = None,
    entry_type: Optional[str] = None,
    category: Optional[str] = None,
    nature: Optional[str] = None,
    source_type: Optional[str] = None,
    start_date: Optional[datetime.datetime] = None,
    end_date: Optional[datetime.datetime] = None,
    limit: int = 100,
    offset: int = 0,
) -> List[CashFlowEntry]:
    """Lists entries from cash flow ledger with filters."""
    stmt = select(CashFlowEntry).options(selectinload(CashFlowEntry.account))

    if account_id:
        stmt = stmt.where(CashFlowEntry.account_id == account_id)
    if entry_type:
        stmt = stmt.where(CashFlowEntry.entry_type == entry_type.upper())
    if category:
        stmt = stmt.where(CashFlowEntry.category == category.upper())
    if nature:
        stmt = stmt.where(CashFlowEntry.nature == nature.upper())
    if source_type:
        stmt = stmt.where(CashFlowEntry.source_type == source_type.upper())
    if start_date:
        stmt = stmt.where(CashFlowEntry.occurred_at >= start_date)
    if end_date:
        stmt = stmt.where(CashFlowEntry.occurred_at <= end_date)

    stmt = stmt.order_by(desc(CashFlowEntry.occurred_at), desc(CashFlowEntry.created_at)).limit(limit).offset(offset)
    return list(db.execute(stmt).scalars().all())


# ==================== TREASURY SUMMARY ====================

def get_treasury_summary(
    db: Session,
    start_date: Optional[datetime.datetime] = None,
    end_date: Optional[datetime.datetime] = None,
) -> TreasurySummaryResponse:
    """
    Computes consolidated treasury metrics:
    - Real available cash (cash vs bank accounts)
    - Future commitments (open receivables, open payables, route cash in custody)
    - Projected net balance
    - Period operational business expenses vs personal withdrawals
    """
    accounts = list_financial_accounts(db, is_active=True)

    cash_bal = sum(a.current_balance_cents for a in accounts if a.account_type == "CASH")
    bank_bal = sum(a.current_balance_cents for a in accounts if a.account_type == "BANK")
    total_avail = sum(a.current_balance_cents for a in accounts)

    now = utc_now()

    # Open and overdue receivables
    rec_stmt = select(SalesReceivable).where(SalesReceivable.status.in_(["OPEN", "PARTIAL"]))
    open_receivables = list(db.execute(rec_stmt).scalars().all())
    open_rec_cents = sum(r.balance_cents for r in open_receivables)
    overdue_rec_cents = sum(
        r.balance_cents for r in open_receivables
        if (r.due_date.replace(tzinfo=datetime.timezone.utc) if r.due_date.tzinfo is None else r.due_date) < now
    )

    # Open and overdue payables
    pay_stmt = select(AccountPayable).where(AccountPayable.status.in_(["OPEN", "PARTIAL"]))
    open_payables = list(db.execute(pay_stmt).scalars().all())
    open_pay_cents = sum(p.balance_cents for p in open_payables)
    overdue_pay_cents = sum(
        p.balance_cents for p in open_payables
        if (p.due_date.replace(tzinfo=datetime.timezone.utc) if p.due_date.tzinfo is None else p.due_date) < now
    )

    # Pending route cash from open dispatches
    open_disp_stmt = select(StockDispatch).where(StockDispatch.status == "OPEN")
    open_dispatches = list(db.execute(open_disp_stmt).scalars().all())
    route_cash_pending = 0
    # From dispatches, calculate expected cash pending repayment
    from app.services.dispatches import calculate_dispatch_reconciliation
    for d in open_dispatches:
        try:
            recon = calculate_dispatch_reconciliation(db, d.id)
            if recon.pending_cash_cents > 0:
                route_cash_pending += recon.pending_cash_cents
        except Exception:
            pass

    projected_net = total_avail + open_rec_cents - open_pay_cents

    # Period expense segregation
    period_stmt = select(CashFlowEntry).where(CashFlowEntry.entry_type == "DEBIT")
    if start_date:
        period_stmt = period_stmt.where(CashFlowEntry.occurred_at >= start_date)
    if end_date:
        period_stmt = period_stmt.where(CashFlowEntry.occurred_at <= end_date)

    entries = list(db.execute(period_stmt).scalars().all())
    biz_expenses = sum(e.amount_cents for e in entries if e.nature == "BUSINESS")
    personal_withdrawals = sum(e.amount_cents for e in entries if e.nature == "PERSONAL_WITHDRAWAL")

    return TreasurySummaryResponse(
        total_available_cents=total_avail,
        cash_balance_cents=cash_bal,
        bank_balance_cents=bank_bal,
        open_receivables_cents=open_rec_cents,
        overdue_receivables_cents=overdue_rec_cents,
        open_payables_cents=open_pay_cents,
        overdue_payables_cents=overdue_pay_cents,
        route_cash_pending_cents=route_cash_pending,
        projected_net_cents=projected_net,
        period_business_expenses_cents=biz_expenses,
        period_personal_withdrawals_cents=personal_withdrawals,
        accounts=[FinancialAccountResponse.model_validate(a) for a in accounts],
    )
