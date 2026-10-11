import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field

class ReceivablePaymentCreate(BaseModel):
    amount_cents: int = Field(..., gt=0, description="Valor do pagamento / amortizacao em centavos")
    payment_method: str = Field(default="CASH", description="Forma de pagamento (CASH, PIX, CARD, OTHER)")
    payment_date: Optional[datetime.datetime] = Field(None, description="Data do recebimento (padrao now)")
    notes: Optional[str] = Field(None, description="Observacoes sobre o recebimento")

class ReceivablePaymentCancelRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Justificativa do estorno do pagamento")

class ReceivablePaymentResponse(BaseModel):
    id: str
    receivable_id: str
    payment_date: datetime.datetime
    amount_cents: int
    payment_method: str
    status: str
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
    due_date: datetime.datetime
    original_amount_cents: int
    paid_amount_cents: int
    balance_cents: int
    status: str # OPEN, PARTIAL, PAID, CANCELED
    is_overdue: bool = False
    notes: Optional[str] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime
    payments_count: int = 0

    model_config = ConfigDict(from_attributes=True)

class SalesReceivableDetailResponse(SalesReceivableResponse):
    sale_date: datetime.datetime
    payments: List[ReceivablePaymentResponse]
