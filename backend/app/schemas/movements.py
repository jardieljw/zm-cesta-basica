import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator, model_validator

class MovementResponse(BaseModel):
    id: str
    item_type: str
    product_id: Optional[str] = None
    product_name: Optional[str] = None
    basket_type_id: Optional[str] = None
    basket_type_name: Optional[str] = None
    production_batch_id: Optional[str] = None
    movement_type: str
    quantity_delta: int
    source_type: str
    source_id: str
    reversal_of_id: Optional[str] = None
    occurred_at: datetime.datetime
    reason: Optional[str] = None
    running_balance: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

class MovementListResponse(BaseModel):
    items: List[MovementResponse]
    total: int
    page: int
    page_size: int
    total_pages: int

class ProductStockSummary(BaseModel):
    product_id: str
    product_name: str
    sku: Optional[str] = None
    barcode: Optional[str] = None
    category: str
    base_unit: str
    current_stock: int
    minimum_stock: int
    is_below_minimum: bool
    cost_price_cents: int
    sale_price_cents: int

class ProductStockDetailResponse(BaseModel):
    product_id: str
    product_name: str
    sku: Optional[str] = None
    category: str
    base_unit: str
    current_stock: int
    minimum_stock: int
    is_below_minimum: bool
    cost_price_cents: int
    sale_price_cents: int

class StockAdjustmentCreate(BaseModel):
    item_type: str = Field(default="PRODUCT", description="'PRODUCT' ou 'BASKET'")
    product_id: Optional[str] = Field(None, description="ID do produto (obrigatorio se item_type for PRODUCT)")
    basket_type_id: Optional[str] = Field(None, description="ID da cesta (obrigatorio se item_type for BASKET)")
    adjustment_type: str = Field(..., description="'IN', 'OUT', 'LOSS', ou 'COUNT'")
    quantity_delta: Optional[int] = Field(None, description="Quantidade absoluta para ajuste (IN, OUT, LOSS)")
    physical_count: Optional[int] = Field(None, ge=0, description="Saldo fisico contado em estoque (COUNT)")
    reason: str = Field(..., min_length=3, max_length=500, description="Justificativa textual obrigatoria para auditoria")

    @field_validator("reason", mode="before")
    @classmethod
    def validate_reason(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if len(v) < 3:
                raise ValueError("A justificativa de ajuste deve conter pelo menos 3 caracteres.")
        return v

    @field_validator("adjustment_type", mode="before")
    @classmethod
    def validate_adjustment_type(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if v not in ("IN", "OUT", "LOSS", "COUNT"):
                raise ValueError("Tipo de ajuste invalido. Valores aceitos: IN, OUT, LOSS, COUNT.")
        return v

    @field_validator("item_type", mode="before")
    @classmethod
    def validate_item_type(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if v not in ("PRODUCT", "BASKET"):
                raise ValueError("Tipo de item invalido. Valores aceitos: PRODUCT, BASKET.")
        return v

    @model_validator(mode="after")
    def validate_adjustment_payload(self) -> "StockAdjustmentCreate":
        if self.item_type == "PRODUCT":
            if not self.product_id:
                raise ValueError("product_id e obrigatorio para ajustes de produto.")
            self.basket_type_id = None
        elif self.item_type == "BASKET":
            if not self.basket_type_id:
                raise ValueError("basket_type_id e obrigatorio para ajustes de cesta.")
            self.product_id = None

        if self.adjustment_type in ("IN", "OUT", "LOSS"):
            if self.quantity_delta is None or self.quantity_delta <= 0:
                raise ValueError(f"quantity_delta deve ser um inteiro positivo para ajustes do tipo {self.adjustment_type}.")
        elif self.adjustment_type == "COUNT":
            if self.physical_count is None:
                raise ValueError("physical_count e obrigatorio para contagem de inventario (COUNT).")

        return self

class StockAdjustmentResponse(BaseModel):
    movement_id: str
    item_type: str
    product_id: Optional[str] = None
    product_name: Optional[str] = None
    basket_type_id: Optional[str] = None
    basket_type_name: Optional[str] = None
    adjustment_type: str
    movement_type: str
    previous_stock: int
    quantity_delta: int
    new_stock: int
    reason: str
    occurred_at: datetime.datetime
