import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator

class PurchaseItemCreate(BaseModel):
    product_id: str = Field(..., description="ID do produto a ser adquirido")
    packaging_id: Optional[str] = Field(None, description="ID da embalagem comercial (opcional)")
    packages_count: float = Field(..., gt=0, description="Quantidade de embalagens ou unidades adquiridas")
    unit_price_cents: int = Field(..., ge=0, description="Preco unitario por embalagem (ou por unidade se packaging_id for null) em centavos")

    @field_validator("product_id", mode="before")
    @classmethod
    def validate_product_id(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("product_id nao pode ser vazio.")
        return v

class PurchaseCreate(BaseModel):
    supplier_name: Optional[str] = Field(None, max_length=200, description="Nome ou razao social do fornecedor")
    purchase_date: Optional[datetime.datetime] = Field(None, description="Data da compra/recebimento")
    payment_mode: str = Field(default="CASH_IMMEDIATE", description="'CASH_IMMEDIATE' ou 'CREDIT_TERM'")
    due_date: Optional[datetime.datetime] = Field(None, description="Data de vencimento se compra a prazo (CREDIT_TERM)")
    account_id: Optional[str] = Field(None, description="Conta financeira para pagamento se CASH_IMMEDIATE")
    notes: Optional[str] = Field(None, max_length=1000, description="Observacoes adicionais ou numero da NF-e")
    status: str = Field(default="CONFIRMED", description="'CONFIRMED' ou 'DRAFT'")
    items: List[PurchaseItemCreate] = Field(..., min_length=1, description="Lista de itens da compra")

    @field_validator("status", mode="before")
    @classmethod
    def validate_status(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if v not in ("CONFIRMED", "DRAFT"):
                raise ValueError("Status invalido. Valores aceitos: CONFIRMED, DRAFT.")
        return v

    @field_validator("payment_mode", mode="before")
    @classmethod
    def validate_payment_mode(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if v not in ("CASH_IMMEDIATE", "CREDIT_TERM"):
                raise ValueError("payment_mode invalido. Valores aceitos: CASH_IMMEDIATE, CREDIT_TERM.")
        return v

    @field_validator("supplier_name", "notes", mode="before")
    @classmethod
    def normalize_strings(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class PurchaseItemResponse(BaseModel):
    id: str
    purchase_id: str
    product_id: str
    product_name: str
    product_base_unit: str
    packaging_id: Optional[str] = None
    packaging_name: Optional[str] = None
    packages_count: float
    quantity_in_base_units: int
    unit_price_cents: int
    total_price_cents: int

    model_config = ConfigDict(from_attributes=True)

class PurchaseResponse(BaseModel):
    id: str
    purchase_number: int
    status: str
    purchase_date: datetime.datetime
    payment_mode: str = "CASH_IMMEDIATE"
    due_date: Optional[datetime.datetime] = None
    account_id: Optional[str] = None
    payable_id: Optional[str] = None
    supplier_name: Optional[str] = None
    total_amount_cents: int
    notes: Optional[str] = None
    created_at: datetime.datetime
    items: List[PurchaseItemResponse] = []

    model_config = ConfigDict(from_attributes=True)

class PurchaseListResponse(BaseModel):
    items: List[PurchaseResponse]
    total: int
    page: int
    page_size: int
    total_pages: int

class PurchaseCancelRequest(BaseModel):
    reason: Optional[str] = Field(None, max_length=500, description="Motivo do estorno / cancelamento da compra")

class PurchaseCancelResponse(BaseModel):
    purchase: PurchaseResponse
    reversal_movements_count: int
    message: str
