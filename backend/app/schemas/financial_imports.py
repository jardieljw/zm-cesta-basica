"""Structured input contract; no PDF parsing, AI or Gmail dependency."""
import datetime
from typing import Annotated, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator, StringConstraints, BeforeValidator

MAX_MONEY = 9_000_000_000_000_000
Money = Annotated[int, Field(strict=True, ge=-MAX_MONEY, le=MAX_MONEY)]
PositiveMoney = Annotated[int, Field(strict=True, gt=0, le=MAX_MONEY)]
NonnegativeMoney = Annotated[int, Field(strict=True, ge=0, le=MAX_MONEY)]
EntityId = Annotated[str, Field(min_length=1, max_length=36)]


def calendar_date(value):
    if type(value) is datetime.date:
        return value
    if isinstance(value, str) and len(value) == 10 and value[4] == "-" and value[7] == "-":
        return datetime.date.fromisoformat(value)
    raise ValueError("Informar data de calendario no formato AAAA-MM-DD, sem timestamp ou fuso presumido.")


CalendarDate = Annotated[datetime.date, BeforeValidator(calendar_date)]


class FinancialInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class FinancialSourceCreate(FinancialInput):
    source_type: Literal["BANK_ACCOUNT", "CREDIT_CARD"]
    financial_account_id: Optional[EntityId] = None
    name: str = Field(min_length=2, max_length=100)
    institution: str = Field(min_length=2, max_length=100)
    holder_type: Literal["PF", "PJ"]
    holder_name: Optional[str] = Field(None, min_length=2, max_length=200)
    holder_document: Optional[str] = Field(None, min_length=3, max_length=30)
    branch: Optional[str] = Field(None, min_length=1, max_length=30)
    currency: str = Field("BRL", pattern=r"^[A-Z]{3}$")

    @model_validator(mode="after")
    def account_shape(self):
        if (self.source_type == "BANK_ACCOUNT") != (self.financial_account_id is not None):
            raise ValueError("Conta bancaria exige financial_account_id; cartao nao representa conta de caixa.")
        return self


class FinancialSourceResponse(FinancialSourceCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str
    created_by: str
    created_at: datetime.datetime
    current_balance_cents: Optional[int] = None


class FinancialDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    sha256: str
    filename: str
    media_type: str
    size_bytes: int
    created_by: str
    created_at: datetime.datetime


class FinancialTransactionData(FinancialInput):
    transaction_date: CalendarDate
    purchase_date: Optional[CalendarDate] = None
    booking_date: Optional[CalendarDate] = None
    transaction_time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}(:\d{2})?$")
    utc_offset_minutes: Optional[int] = Field(None, strict=True, ge=-840, le=840)
    date_kind: Literal["AS_REPORTED", "PURCHASE", "BOOKING"] = "AS_REPORTED"
    amount_cents: Money
    description: str = Field(min_length=1, max_length=2000)
    transaction_kind: Literal[
        "PURCHASE", "BILL_PAYMENT", "TRANSFER", "FEE", "INTEREST", "TAX",
        "REFUND", "DEPOSIT", "WITHDRAWAL", "OTHER",
    ] = "OTHER"
    external_id_namespace: Optional[str] = Field(None, min_length=1, max_length=50)
    external_id: Optional[str] = Field(None, min_length=1, max_length=255)
    counterparty_name: Optional[str] = Field(None, min_length=1, max_length=200)
    counterparty_document: Optional[str] = Field(None, min_length=1, max_length=30)
    counterparty_institution: Optional[str] = Field(None, min_length=1, max_length=100)
    counterparty_branch: Optional[str] = Field(None, min_length=1, max_length=30)
    counterparty_account: Optional[str] = Field(None, min_length=1, max_length=60)
    card_last_four: Optional[str] = Field(None, pattern=r"^[0-9]{4}$")
    installment_number: Optional[int] = Field(None, strict=True, ge=1, le=1000)
    total_installments: Optional[int] = Field(None, strict=True, ge=1, le=1000)

    @model_validator(mode="after")
    def complete_facts(self):
        for kind, field in (("PURCHASE", "purchase_date"), ("BOOKING", "booking_date")):
            if self.date_kind == kind and getattr(self, field) not in (None, self.transaction_date):
                raise ValueError("A data principal diverge da data identificada na fonte.")
        if self.amount_cents == 0:
            raise ValueError("Linha de saldo ou subtotal nao e uma transacao de valor zero.")
        if (self.external_id is None) != (self.external_id_namespace is None):
            raise ValueError("Identificador externo exige seu namespace de origem.")
        if self.transaction_time is not None:
            datetime.time.fromisoformat(self.transaction_time)
        elif self.utc_offset_minutes is not None:
            raise ValueError("Fuso nao pode ser atribuido a transacao sem horario conhecido.")
        if (self.installment_number is None) != (self.total_installments is None):
            raise ValueError("Informar numero e total de parcelas juntos.")
        if self.installment_number is not None and self.installment_number > self.total_installments:
            raise ValueError("Numero da parcela excede o total.")
        return self


class FinancialItemCreate(FinancialInput):
    position: int = Field(strict=True, gt=0, le=1000000)
    page_number: Optional[int] = Field(None, strict=True, gt=0, le=10000)
    raw_text: Optional[Annotated[str, StringConstraints(strip_whitespace=False, max_length=8000)]] = None
    data: FinancialTransactionData


class FinancialStatementCreate(FinancialInput):
    document_id: EntityId
    source_id: EntityId
    statement_type: Literal["BANK_STATEMENT", "CARD_BILL", "TRANSACTION_RECEIPT"]
    period_start: Optional[CalendarDate] = None
    period_end: Optional[CalendarDate] = None
    issued_on: Optional[CalendarDate] = None
    closing_on: Optional[CalendarDate] = None
    due_on: Optional[CalendarDate] = None
    opening_balance_cents: Optional[Money] = None
    closing_balance_cents: Optional[Money] = None
    total_inflows_cents: Optional[NonnegativeMoney] = None
    total_outflows_cents: Optional[NonnegativeMoney] = None
    total_amount_cents: Optional[Money] = None
    minimum_payment_cents: Optional[NonnegativeMoney] = None
    items: list[FinancialItemCreate] = Field(min_length=0, max_length=2000)

    @model_validator(mode="after")
    def statement_shape(self):
        if (self.period_start is None) != (self.period_end is None):
            raise ValueError("Periodo exige inicio e fim.")
        if self.period_start and self.period_end < self.period_start:
            raise ValueError("Fim do periodo anterior ao inicio.")
        if self.statement_type == "CARD_BILL":
            if self.due_on is None or self.total_amount_cents is None:
                raise ValueError("Fatura exige vencimento e valor total informado pelo banco.")
            if self.minimum_payment_cents is not None and self.minimum_payment_cents > max(self.total_amount_cents, 0):
                raise ValueError("Pagamento minimo excede o total da fatura.")
            if self.closing_on and self.due_on < self.closing_on:
                raise ValueError("Vencimento anterior ao fechamento.")
            if any(getattr(self, f) is not None for f in (
                "opening_balance_cents", "closing_balance_cents", "total_inflows_cents", "total_outflows_cents",
            )):
                raise ValueError("Saldos e entradas/saidas de conta pertencem ao extrato bancario.")
        elif any(getattr(self, f) is not None for f in ("closing_on", "due_on", "total_amount_cents", "minimum_payment_cents")):
            raise ValueError("Vencimento e totais de fatura pertencem a CARD_BILL.")
        if len({i.position for i in self.items}) != len(self.items):
            raise ValueError("Posicoes das linhas devem ser distintas.")
        return self


class FinancialItemReview(FinancialInput):
    action: Literal["NEW", "LINK", "IGNORE"]
    transaction_id: Optional[EntityId] = None
    reason: str = Field(min_length=3, max_length=1000)

    @model_validator(mode="after")
    def review_shape(self):
        if (self.action == "LINK") != (self.transaction_id is not None):
            raise ValueError("Somente LINK exige transaction_id.")
        return self


class FinancialReconciliationCreate(FinancialInput):
    transaction_id: EntityId
    cash_flow_entry_id: EntityId
    amount_cents: PositiveMoney
    reason: str = Field(min_length=3, max_length=1000)


class FinancialReviewCorrectionCreate(FinancialItemReview):
    expected_revision: int = Field(strict=True, ge=0)


class FinancialReconciliationVoid(FinancialInput):
    reason: str = Field(min_length=3, max_length=1000)
