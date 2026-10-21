import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, model_validator

# ==================== FINANCIAL ACCOUNTS ====================

class FinancialAccountCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Nome da conta (ex: Caixa da Loja, Banco do Brasil)")
    account_type: str = Field(default="CASH", description="Tipo de conta: CASH, BANK, OTHER")
    bank_name: Optional[str] = Field(None, max_length=100, description="Nome da instituicao financeira se tipo BANK")
    account_number: Optional[str] = Field(None, max_length=50, description="Numero da conta / agencia")
    initial_balance_cents: int = Field(default=0, description="Saldo inicial de abertura em centavos")
    is_default: bool = Field(default=False, description="Se e a conta padrao do tipo")
    notes: Optional[str] = Field(None, description="Observacoes")


class FinancialAccountUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    is_active: Optional[bool] = None
    is_default: Optional[bool] = None
    notes: Optional[str] = None


class FinancialAccountResponse(BaseModel):
    id: str
    name: str
    account_type: str
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    initial_balance_cents: int
    current_balance_cents: int
    is_active: bool
    is_default: bool
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== CASH FLOW ENTRIES ====================

class CashFlowEntryCreate(BaseModel):
    account_id: str = Field(..., description="ID da conta financeira")
    entry_type: str = Field(..., description="Tipo de movimento: CREDIT ou DEBIT")
    amount_cents: int = Field(..., gt=0, description="Valor em centavos (positivo)")
    category: str = Field(..., description="Categoria financeira")
    nature: str = Field(default="BUSINESS", description="BUSINESS (operacional) ou PERSONAL_WITHDRAWAL (retirada de socios)")
    description: str = Field(..., min_length=2, description="Descricao do lancamento")
    source_type: str = Field(default="MANUAL", description="Origem: MANUAL, SALE, RECEIVABLE_PAYMENT, etc.")
    source_id: Optional[str] = Field(None, description="ID do documento de origem")
    payment_method: str = Field(default="CASH", description="Meio de pagamento")
    occurred_at: Optional[datetime.datetime] = Field(None, description="Data/hora da realizacao")
    notes: Optional[str] = Field(None, description="Observacoes")


class CashFlowEntryResponse(BaseModel):
    id: str
    account_id: str
    account_name: Optional[str] = None
    entry_type: str
    amount_cents: int
    category: str
    nature: str
    description: str
    source_type: str
    source_id: Optional[str] = None
    payment_method: str
    occurred_at: datetime.datetime
    reversal_of_id: Optional[str] = None
    is_reversal: bool
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== TRANSFERS ====================

class FinancialTransferCreate(BaseModel):
    source_account_id: str = Field(..., description="Conta de origem (debito)")
    destination_account_id: str = Field(..., description="Conta de destino (credito)")
    amount_cents: int = Field(..., gt=0, description="Valor da transferencia em centavos")
    transfer_date: Optional[datetime.datetime] = Field(None, description="Data da transferencia")
    description: Optional[str] = Field("Transferencia entre contas", description="Descricao")
    notes: Optional[str] = Field(None, description="Observacoes")


class FinancialTransferResponse(BaseModel):
    transfer_id: str
    source_account_id: str
    source_account_name: str
    destination_account_id: str
    destination_account_name: str
    amount_cents: int
    transfer_date: datetime.datetime
    source_entry_id: str
    destination_entry_id: str
    description: str
    notes: Optional[str] = None


# ==================== ACCOUNTS PAYABLE ====================

class AccountPayableCreate(BaseModel):
    description: str = Field(..., min_length=2, description="Descricao da obrigacao (ex: Boleto Fornecedor Arroz, Aluguel)")
    beneficiary: str = Field(..., min_length=2, description="Nome do favorecido/fornecedor/banco")
    category: str = Field(..., description="Categoria: FORNECEDOR, ENERGIA, ALUGUEL, FRETE, MANUTENCAO, EMPRESTIMO, CARTAO_CREDITO, RETIRADA_SOCIO, IMPOSTO, OUTROS")
    nature: str = Field(default="BUSINESS", description="BUSINESS (operacional) ou PERSONAL_WITHDRAWAL (particular sócios)")
    original_amount_cents: int = Field(..., gt=0, description="Valor nominal em centavos")
    due_date: datetime.datetime = Field(..., description="Data de vencimento")
    payment_method: str = Field(default="BOLETO", description="Forma de pagamento prevista: BOLETO, PIX, TRANSFERENCIA, CHEQUE, CARTAO_CREDITO, DINHEIRO, OUTRO")
    purchase_id: Optional[str] = Field(None, description="Vinculo opcional com compra de insumos")
    total_installments: int = Field(default=1, ge=1, description="Numero total de parcelas a gerar")
    installment_due_dates: Optional[List[datetime.datetime]] = Field(None, description="Datas de vencimento customizadas por parcela")
    is_recurrent: bool = Field(default=False, description="Se e uma despesa recorrente")
    recurrence_period: Optional[str] = Field(None, description="Periodicidade: MONTHLY, WEEKLY, YEARLY")
    notes: Optional[str] = Field(None, description="Observacoes adicionais / numero da nota / linha digitavel")


class AccountPayableCancelRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Justificativa do cancelamento da obrigacao")


class PayablePaymentCreate(BaseModel):
    amount_cents: int = Field(..., gt=0, description="Valor pago em centavos")
    account_id: Optional[str] = Field(None, description="Vínculo interno opcional para compatibilidade contábil")
    payment_method: str = Field(default="BOLETO", description="Meio de pagamento efetivo")
    payment_date: Optional[datetime.datetime] = Field(None, description="Data/hora do desembolso")
    notes: Optional[str] = Field(None, description="Comprovante / observacoes")
    expected_balance_cents: Optional[int] = Field(None, ge=0, description="Saldo conferido na revisão; precondição aditiva")
    payment_business_date: Optional[datetime.date] = Field(None, description="Dia civil do pagamento em UTC-03, sem horário informado")
    expected_bill_revision: Optional[int] = Field(None, strict=True, ge=1)

    @model_validator(mode="after")
    def one_date_representation(self):
        if self.payment_date is not None and self.payment_business_date is not None:
            raise ValueError("Use payment_date ou payment_business_date, não ambos.")
        return self


class PayablePaymentCancelRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Justificativa do estorno do pagamento")


class PayablePaymentResponse(BaseModel):
    id: str
    payable_id: str
    account_id: str
    account_name: Optional[str] = None
    payment_date: datetime.datetime
    amount_cents: int
    payment_method: str
    status: str
    reversal_reason: Optional[str] = None
    reversal_of_id: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime
    bill_revision_id: Optional[str] = None
    stock_cents: Optional[int] = None
    business_cents: Optional[int] = None
    personal_cents: Optional[int] = None
    unclassified_cents: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class AccountPayableResponse(BaseModel):
    id: str
    payable_number: int
    description: str
    beneficiary: str
    category: str
    nature: str
    original_amount_cents: int
    paid_amount_cents: int
    balance_cents: int
    due_date: datetime.datetime
    payment_method: str
    status: str  # OPEN, PARTIAL, PAID, CANCELED
    is_overdue: bool = False
    purchase_id: Optional[str] = None
    installment_number: int = 1
    total_installments: int = 1
    installment_group_id: Optional[str] = None
    is_recurrent: bool = False
    recurrence_period: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime
    payments_count: int = 0
    superseded_by_id: Optional[str] = None
    financial_bill: Optional[dict] = None

    model_config = ConfigDict(from_attributes=True)


class AccountPayableDetailResponse(AccountPayableResponse):
    payments: List[PayablePaymentResponse] = []
    payment_review_version: int = 1


# ==================== TREASURY SUMMARY ====================

class TreasurySummaryResponse(BaseModel):
    total_available_cents: int
    cash_balance_cents: int
    bank_balance_cents: int
    open_receivables_cents: int
    overdue_receivables_cents: int
    open_payables_cents: int
    overdue_payables_cents: int
    route_cash_pending_cents: int
    projected_net_cents: int
    period_business_expenses_cents: int = 0
    period_personal_withdrawals_cents: int = 0
    accounts: List[FinancialAccountResponse] = []
