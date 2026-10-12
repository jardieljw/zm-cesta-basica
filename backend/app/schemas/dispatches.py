import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


# ==================== RESPONSIBLE PERSON ====================

class ResponsiblePersonCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=200, description="Nome da pessoa responsável")
    phone: Optional[str] = Field(None, max_length=50, description="Telefone / WhatsApp para contato")
    is_active: bool = Field(default=True, description="Status ativo")
    notes: Optional[str] = Field(None, description="Observações gerais")


class ResponsiblePersonUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    phone: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None
    notes: Optional[str] = None


class ResponsiblePersonResponse(BaseModel):
    id: str
    name: str
    phone: Optional[str] = None
    is_active: bool
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


class CustodyBasketBalance(BaseModel):
    basket_type_id: str
    basket_type_name: str
    balance: int


class ResponsiblePersonCustodyResponse(BaseModel):
    responsible_person_id: str
    responsible_person_name: str
    total_custody_baskets: int
    baskets: List[CustodyBasketBalance]


# ==================== DISPATCH ITEMS & DISPATCH ====================

class DispatchItemCreate(BaseModel):
    basket_type_id: str = Field(..., description="ID do tipo de cesta")
    production_batch_id: Optional[str] = Field(None, description="ID do lote de cesta personalizada (se aplicável)")
    quantity: int = Field(..., gt=0, description="Quantidade de cestas retiradas")
    unit_price_cents: Optional[int] = Field(0, ge=0, description="Preço/valor de referência em centavos")
    notes: Optional[str] = Field(None, description="Personalizações ou observações do item")


class DispatchItemResponse(BaseModel):
    id: str
    dispatch_id: str
    basket_type_id: str
    basket_type_name: Optional[str] = None
    production_batch_id: Optional[str] = None
    quantity: int
    unit_price_cents: int
    total_price_cents: int
    notes: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class StockDispatchCreate(BaseModel):
    responsible_person_id: str = Field(..., description="ID da pessoa responsável que retira as mercadorias")
    dispatch_date: Optional[datetime.datetime] = Field(None, description="Data e horário da saída física (UTC)")
    notes: Optional[str] = Field(None, description="Observações da expedição")
    items: List[DispatchItemCreate] = Field(..., min_length=1, description="Lista de cestas retiradas")


class StockDispatchResponse(BaseModel):
    id: str
    dispatch_number: int
    responsible_person_id: str
    responsible_person_name: Optional[str] = None
    dispatch_date: datetime.datetime
    status: str
    total_items_quantity: int
    total_reference_amount_cents: int
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


class StockDispatchDetailResponse(StockDispatchResponse):
    items: List[DispatchItemResponse]
    sales_count: int = 0
    returns_count: int = 0
    losses_count: int = 0
    expenses_count: int = 0
    repayments_count: int = 0
    has_settlement: bool = False
    settlement_status: Optional[str] = None


# ==================== RETURNS & LOSSES ====================

class DispatchReturnCreate(BaseModel):
    basket_type_id: str = Field(..., description="ID da cesta que retornou intacta")
    production_batch_id: Optional[str] = Field(None, description="ID do lote se personalizada")
    quantity: int = Field(..., gt=0, description="Quantidade de cestas intactas retornadas")
    returned_at: Optional[datetime.datetime] = Field(None, description="Data e horário do retorno")
    notes: Optional[str] = Field(None, description="Observações da conferência de retorno")


class DispatchReturnResponse(BaseModel):
    id: str
    dispatch_id: str
    basket_type_id: str
    basket_type_name: Optional[str] = None
    production_batch_id: Optional[str] = None
    quantity: int
    returned_at: datetime.datetime
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


class DispatchLossCreate(BaseModel):
    basket_type_id: str = Field(..., description="ID da cesta avariada/perdida")
    production_batch_id: Optional[str] = Field(None, description="ID do lote se personalizada")
    quantity: int = Field(..., gt=0, description="Quantidade perdida/avariada")
    reason: str = Field(..., min_length=3, description="Justificativa textual obrigatória da avaria/perda")
    occurred_at: Optional[datetime.datetime] = Field(None, description="Data e horário da perda")


class DispatchLossResponse(BaseModel):
    id: str
    dispatch_id: str
    basket_type_id: str
    basket_type_name: Optional[str] = None
    production_batch_id: Optional[str] = None
    quantity: int
    occurred_at: datetime.datetime
    reason: str
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== EXPENSES & REPAYMENTS ====================

class DispatchExpenseCreate(BaseModel):
    amount_cents: int = Field(..., gt=0, description="Valor da despesa autorizada em centavos")
    description: str = Field(..., min_length=2, description="Descrição da despesa (ex: Combustível, Pedágio)")
    receipt_ref: Optional[str] = Field(None, description="Número de comprovante ou cupom fiscal")
    authorized_by: Optional[str] = Field(None, description="Nome de quem autorizou a despesa")
    expense_date: Optional[datetime.datetime] = Field(None, description="Data da despesa")


class DispatchExpenseResponse(BaseModel):
    id: str
    dispatch_id: str
    expense_date: datetime.datetime
    amount_cents: int
    description: str
    receipt_ref: Optional[str] = None
    authorized_by: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


class DispatchRepaymentCreate(BaseModel):
    amount_cents: int = Field(..., gt=0, description="Valor repassado à empresa em centavos")
    payment_method: str = Field(default="CASH", description="Forma de repasse (CASH, PIX, TRANSFER)")
    received_by: Optional[str] = Field(None, description="Colaborador que recebeu o dinheiro na empresa")
    repayment_date: Optional[datetime.datetime] = Field(None, description="Data e horário do repasse")
    notes: Optional[str] = Field(None, description="Observações do repasse")


class DispatchRepaymentResponse(BaseModel):
    id: str
    dispatch_id: str
    repayment_date: datetime.datetime
    amount_cents: int
    payment_method: str
    received_by: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


# ==================== SETTLEMENT & RECONCILIATION ====================

class DispatchItemReconciliation(BaseModel):
    basket_type_id: str
    basket_type_name: str
    production_batch_id: Optional[str] = None
    dispatched_qty: int
    sold_qty: int
    returned_qty: int
    lost_qty: int
    remaining_custody_qty: int
    discrepancy_qty: int


class DispatchSettlementResponse(BaseModel):
    id: str
    dispatch_id: str
    audited_by: str
    settled_at: datetime.datetime
    total_dispatched_qty: int
    total_sold_qty: int
    total_returned_qty: int
    total_lost_qty: int
    total_remaining_custody_qty: int
    basket_discrepancy_qty: int
    expected_cash_cents: int
    actual_repaid_cash_cents: int
    cash_discrepancy_cents: int
    direct_company_received_cents: int
    status: str
    notes: Optional[str] = None
    investigation_notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)


class DispatchReconciliationResponse(BaseModel):
    dispatch_id: str
    dispatch_number: int
    responsible_person_id: str
    responsible_person_name: str
    dispatch_date: datetime.datetime
    dispatch_status: str

    # 4-term physical equation totals
    total_dispatched_qty: int
    total_sold_qty: int
    total_returned_qty: int
    total_lost_qty: int
    total_remaining_custody_qty: int
    basket_discrepancy_qty: int

    # Financial equation
    cash_sales_cents: int
    direct_company_received_cents: int
    credit_sales_cents: int
    cash_debt_collected_cents: int
    expenses_cents: int
    expected_cash_cents: int
    actual_repaid_cash_cents: int
    pending_cash_cents: int
    cash_discrepancy_cents: int

    # Flags
    has_basket_discrepancy: bool
    has_cash_discrepancy: bool

    # Details
    items_reconciliation: List[DispatchItemReconciliation]
    returns: List[DispatchReturnResponse]
    losses: List[DispatchLossResponse]
    expenses: List[DispatchExpenseResponse]
    repayments: List[DispatchRepaymentResponse]
    latest_settlement: Optional[DispatchSettlementResponse] = None


class DispatchSettlementCreate(BaseModel):
    audited_by: str = Field(..., min_length=2, description="Nome do auditor/responsável pela conferência na empresa")
    settled_at: Optional[datetime.datetime] = Field(None, description="Data da conferência")
    notes: Optional[str] = Field(None, description="Observações da conferência")
    investigation_notes: Optional[str] = Field(None, description="Notas iniciais de investigação se houver divergência")


class DispatchSettlementInvestigationUpdate(BaseModel):
    investigation_notes: str = Field(..., min_length=3, description="Documentação detalhada da investigação e resolução")
    mark_as_resolved: bool = Field(default=False, description="Se True, altera status para RESOLVED se divergências foram justificadas")
