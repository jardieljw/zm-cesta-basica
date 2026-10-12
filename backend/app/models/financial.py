import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, Boolean, event, DDL
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session
from app.models.base import Base, utc_now

class FinancialAccount(Base):
    __tablename__ = "financial_accounts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    account_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # CASH, BANK, OTHER
    bank_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    account_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    initial_balance_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    current_balance_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    entries: Mapped[List["CashFlowEntry"]] = relationship("CashFlowEntry", back_populates="account")
    payable_payments: Mapped[List["PayablePayment"]] = relationship("PayablePayment", back_populates="account")


class CashFlowEntry(Base):
    __tablename__ = "cash_flow_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    account_id: Mapped[str] = mapped_column(String(36), ForeignKey("financial_accounts.id"), nullable=False, index=True)
    entry_type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)  # CREDIT, DEBIT
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # VENDAS, RECEBIMENTO_CLIENTE, REPASSE_ROTA, COMPRA_INSUMOS, FORNECEDOR, ENERGIA, ALUGUEL, FRETE, MANUTENCAO, EMPRESTIMO, CARTAO_CREDITO, RETIRADA_SOCIO, TRANSFERENCIA, APORTE, OUTROS
    nature: Mapped[str] = mapped_column(String(30), default="BUSINESS", nullable=False, index=True)  # BUSINESS, PERSONAL_WITHDRAWAL
    description: Mapped[str] = mapped_column(Text, nullable=False)
    source_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # SALE, RECEIVABLE_PAYMENT, DISPATCH_REPAYMENT, PAYABLE_PAYMENT, PURCHASE, TRANSFER, MANUAL
    source_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    payment_method: Mapped[str] = mapped_column(String(50), default="CASH", nullable=False)  # CASH, PIX, CARD, BANK_TRANSFER, CHECK, OTHER
    occurred_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    reversal_of_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("cash_flow_entries.id"), nullable=True, index=True)
    is_reversal: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    account: Mapped["FinancialAccount"] = relationship("FinancialAccount", back_populates="entries")
    reversal_parent: Mapped[Optional["CashFlowEntry"]] = relationship("CashFlowEntry", remote_side=[id])


class AccountPayable(Base):
    __tablename__ = "accounts_payable"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    payable_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    beneficiary: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # FORNECEDOR, ENERGIA, ALUGUEL, FRETE, MANUTENCAO, EMPRESTIMO, CARTAO_CREDITO, RETIRADA_SOCIO, IMPOSTO, OUTROS
    nature: Mapped[str] = mapped_column(String(30), default="BUSINESS", nullable=False, index=True)  # BUSINESS, PERSONAL_WITHDRAWAL
    original_amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    paid_amount_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    balance_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    due_date: Mapped[datetime.datetime] = mapped_column(DateTime, nullable=False, index=True)
    payment_method: Mapped[str] = mapped_column(String(50), default="BOLETO", nullable=False)  # BOLETO, PIX, TRANSFERENCIA, CHEQUE, CARTAO_CREDITO, DINHEIRO, OUTRO
    status: Mapped[str] = mapped_column(String(20), default="OPEN", nullable=False, index=True)  # OPEN, PARTIAL, PAID, CANCELED
    purchase_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("purchases.id"), nullable=True, index=True)
    installment_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    total_installments: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    installment_group_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    is_recurrent: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    recurrence_period: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)  # MONTHLY, WEEKLY, YEARLY
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    purchase: Mapped[Optional["app.models.purchases.Purchase"]] = relationship("app.models.purchases.Purchase")
    payments: Mapped[List["PayablePayment"]] = relationship("PayablePayment", back_populates="payable", cascade="all, delete-orphan")


class PayablePayment(Base):
    __tablename__ = "payable_payments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    payable_id: Mapped[str] = mapped_column(String(36), ForeignKey("accounts_payable.id"), nullable=False, index=True)
    account_id: Mapped[str] = mapped_column(String(36), ForeignKey("financial_accounts.id"), nullable=False, index=True)
    payment_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    payment_method: Mapped[str] = mapped_column(String(50), default="BOLETO", nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="CONFIRMED", nullable=False, index=True)  # CONFIRMED, REVERSED
    reversal_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reversal_of_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("payable_payments.id"), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    payable: Mapped["AccountPayable"] = relationship("AccountPayable", back_populates="payments")
    account: Mapped["FinancialAccount"] = relationship("FinancialAccount", back_populates="payable_payments")


@event.listens_for(Session, "before_flush")
def enforce_cash_flow_entries_append_only(session, flush_context, instances):
    """Enforces strictly append-only ledger for cash flow entries."""
    for obj in session.dirty:
        if isinstance(obj, CashFlowEntry) and session.is_modified(obj, include_collections=False):
            raise ValueError("Violacao de Livro-Caixa: Registros de cash_flow_entries sao estritamente append-only e nao podem ser alterados.")
    for obj in session.deleted:
        if isinstance(obj, CashFlowEntry):
            raise ValueError("Violacao de Livro-Caixa: Registros de cash_flow_entries sao estritamente append-only e nao podem ser excluidos.")


_trg_update_cash_flow_ddl = DDL("""
CREATE TRIGGER IF NOT EXISTS trg_prevent_cash_flow_entries_update
BEFORE UPDATE ON cash_flow_entries
BEGIN
    SELECT RAISE(ABORT, 'cash_flow_entries is append-only: updates are forbidden');
END;
""")

_trg_delete_cash_flow_ddl = DDL("""
CREATE TRIGGER IF NOT EXISTS trg_prevent_cash_flow_entries_delete
BEFORE DELETE ON cash_flow_entries
BEGIN
    SELECT RAISE(ABORT, 'cash_flow_entries is append-only: deletes are forbidden');
END;
""")

event.listen(
    CashFlowEntry.__table__,
    "after_create",
    _trg_update_cash_flow_ddl.execute_if(dialect="sqlite"),
)
event.listen(
    CashFlowEntry.__table__,
    "after_create",
    _trg_delete_cash_flow_ddl.execute_if(dialect="sqlite"),
)
