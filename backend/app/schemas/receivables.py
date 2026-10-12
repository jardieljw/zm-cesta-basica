import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field

class ReceivablePaymentCreate(BaseModel):
    amount_cents: int = Field(..., gt=0, description="Valor do pagamento / amortizacao em centavos")
    payment_method: str = Field(default="CASH", description="Forma de pagamento (CASH, PIX, CARD, OTHER)")
    account_id: Optional[str] = Field(None, description="Conta financeira de destino do recurso (se recebimento na empresa)")
    dispatch_id: Optional[str] = Field(None, description="ID da saida fisica/despacho onde ocorreu o recebimento na rota")
    payment_date: Optional[datetime.datetime] = Field(None, description="Data do recebimento (padrao now)")
    notes: Optional[str] = Field(None, description="Observacoes sobre o recebimento")

class ReceivablePaymentCancelRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Justificativa do estorno do pagamento")

class ReceivablePaymentResponse(BaseModel):
    id: str
    receivable_id: str
    dispatch_id: Optional[str] = None
    account_id: Optional[str] = None
    account_name: Optional[str] = None
    payment_date: datetime.datetime
    amount_cents: int
    payment_method: str
    status: str
    is_route_collection: bool = False
    repass_status: str = "DIRECT_COMPANY"  # DIRECT_COMPANY, PENDING_REPASS, REPASSED
    reversal_reason: Optional[str] = None
    reversal_of_id: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class SalesReceivableResponse(BaseModel):
    id: str
    sale_id: str
    sale_number: int
    customer_id: str
    customer_name: str
    sale_date: Optional[datetime.datetime] = None
    due_date: datetime.datetime
    original_amount_cents: int
    paid_amount_cents: int
    balance_cents: int
    status: str  # OPEN, PARTIAL, PAID, CANCELED
    is_overdue: bool = False
    basket_types_summary: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime
    payments_count: int = 0

    model_config = ConfigDict(from_attributes=True)

class SalesReceivableDetailResponse(SalesReceivableResponse):
    sale_date: datetime.datetime
    payments: List[ReceivablePaymentResponse]
