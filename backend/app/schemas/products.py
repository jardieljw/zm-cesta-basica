import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator
from app.schemas.packagings import PackagingResponse

class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, description="Nome do produto ou insumo")
    sku: Optional[str] = Field(None, max_length=100, description="Codigo SKU interno unico")
    barcode: Optional[str] = Field(None, max_length=50, description="Codigo de barras / EAN opcional unico")
    category: str = Field(..., min_length=1, max_length=50, description="Categoria (ALIMENTACAO, LIMPEZA, CARNE, OUTROS, INSUMO)")
    base_unit: str = Field(..., min_length=1, max_length=20, description="Unidade de medida base no estoque (KG, UN, LT, G, ML)")
    minimum_stock: int = Field(default=0, ge=0, description="Estoque minimo de seguranca em unidades base")
    cost_price_cents: int = Field(default=0, ge=0, description="Preco de custo base de referencia em centavos")
    cost_price_microcents: int = Field(default=0, ge=0, description="Preco de custo CMPM unitario em microcentavos (escala fixa 10^-4 centavos)")
    sale_price_cents: int = Field(default=0, ge=0, description="Preco de venda base de referencia em centavos")
    notes: Optional[str] = Field(None, description="Observacoes adicionais")
    is_active: bool = Field(default=True, description="Status ativo do produto")

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome do produto não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("category", "base_unit", mode="before")
    @classmethod
    def validate_category_and_unit(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if not v:
                raise ValueError("Categoria e unidade base não podem ser vazias.")
        return v

    @field_validator("sku", "barcode", "notes", mode="before")
    @classmethod
    def normalize_empty_to_none(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    sku: Optional[str] = Field(None, max_length=100)
    barcode: Optional[str] = Field(None, max_length=50)
    category: Optional[str] = Field(None, min_length=1, max_length=50)
    base_unit: Optional[str] = Field(None, min_length=1, max_length=20)
    minimum_stock: Optional[int] = Field(None, ge=0)
    cost_price_cents: Optional[int] = Field(None, ge=0)
    cost_price_microcents: Optional[int] = Field(None, ge=0)
    sale_price_cents: Optional[int] = Field(None, ge=0)
    notes: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("name", mode="before")
    @classmethod
    def validate_name_update(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome do produto não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("category", "base_unit", mode="before")
    @classmethod
    def validate_category_and_unit_update(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if not v:
                raise ValueError("Categoria e unidade base não podem ser vazias.")
        return v

    @field_validator("sku", "barcode", "notes", mode="before")
    @classmethod
    def normalize_empty_to_none_update(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class ProductResponse(ProductBase):
    id: str
    created_at: datetime.datetime
    updated_at: datetime.datetime
    packagings: List[PackagingResponse] = []

    model_config = ConfigDict(from_attributes=True)

class ProductInactivationResponse(BaseModel):
    id: str
    name: str
    is_active: bool
    message: str


class ProductDeletionCheck(BaseModel):
    id: str
    name: str
    blockers: List[dict] = []
    can_delete: bool
    reasons: List[str]


class ProductDeletionResponse(BaseModel):
    id: str
    name: str
    deleted: bool
    deletion_mode: str = "PERMANENT"
    removed_packagings_count: int
