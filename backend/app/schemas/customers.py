import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, ConfigDict, Field, field_validator

class CustomerCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=200, description="Nome ou Razao Social do cliente")
    document_cpf_cnpj: Optional[str] = Field(None, max_length=20, description="CPF ou CNPJ (opcional)")
    phone: Optional[str] = Field(None, max_length=50, description="Telefone de contato")
    address: Optional[str] = Field(None, description="Endereco de entrega")
    credit_limit_cents: int = Field(default=0, ge=0, description="Limite de credito concedido (0 = ilimitado/sem teto)")
    notes: Optional[str] = Field(None, description="Observacoes gerais")

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v or len(v) < 2:
                raise ValueError("Nome do cliente não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("document_cpf_cnpj", "phone", "address", "notes", mode="before")
    @classmethod
    def normalize_empty_to_none(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class CustomerUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    document_cpf_cnpj: Optional[str] = Field(None, max_length=20)
    phone: Optional[str] = Field(None, max_length=50)
    address: Optional[str] = None
    credit_limit_cents: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None
    notes: Optional[str] = None

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v or len(v) < 2:
                raise ValueError("Nome do cliente não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("document_cpf_cnpj", "phone", "address", "notes", mode="before")
    @classmethod
    def normalize_empty_to_none(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class CustomerResponse(BaseModel):
    id: str
    name: str
    document_cpf_cnpj: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    credit_limit_cents: int
    is_active: bool
    notes: Optional[str] = None
    current_debt_cents: int = 0
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class CustomerStatementEntry(BaseModel):
    id: str
    occurred_at: datetime.datetime
    entry_type: str # SALE_IMMEDIATE, SALE_CREDIT, RECEIVABLE_PAYMENT
    description: str
    amount_cents: int
    reference_id: str

class CustomerStatementResponse(BaseModel):
    customer: CustomerResponse
    credit_limit_cents: int
    current_debt_cents: int
    available_credit_cents: Optional[int] # None if credit_limit_cents == 0
    entries: List[CustomerStatementEntry]
