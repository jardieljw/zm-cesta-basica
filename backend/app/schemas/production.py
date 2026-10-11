import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator, AliasChoices


class CustomItemInput(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    product_id: str = Field(..., description="ID do produto/insumo")
    quantity_in_base_units: int = Field(
        ...,
        validation_alias=AliasChoices("quantity_in_base_units", "quantity_base_units"),
        gt=0,
        description="Quantidade por cesta na unidade base de estoque",
    )
    section: Optional[str] = Field(default="PERSONALIZADO", description="Secao do insumo (ALIMENTACAO, LIMPEZA, etc)")

    @field_validator("section", mode="before")
    @classmethod
    def normalize_section(cls, v: Any) -> str:
        if isinstance(v, str):
            v = v.strip().upper()
            return v if v else "PERSONALIZADO"
        return "PERSONALIZADO"


class ProductionBatchCreate(BaseModel):
    basket_type_id: str = Field(..., description="ID do tipo de cesta a produzir")
    quantity_produced: int = Field(..., gt=0, description="Quantidade de cestas a montar (inteiro positivo)")
    is_custom: bool = Field(default=False, description="Indica se a montagem e de cesta personalizada")
    is_direct_sale: bool = Field(default=False, description="Indica se a montagem e para venda direta imediata")
    custom_description: Optional[str] = Field(None, max_length=500, description="Descricao obrigatoria para montagens personalizadas")
    custom_items: Optional[List[CustomItemInput]] = Field(None, description="Lista de insumos consumidos (obrigatorio se is_custom=True)")
    occurred_at: Optional[datetime.datetime] = Field(None, description="Data/hora da montagem (padrao: UTC atual)")
    notes: Optional[str] = Field(None, description="Observacoes operacionais da ordem de producao")

    @field_validator("custom_description", mode="before")
    @classmethod
    def normalize_custom_description(cls, v: Any) -> Optional[str]:
        if isinstance(v, str):
            v = v.strip()
            return v if v else None
        return v


class ProductionPreviewRequest(BaseModel):
    basket_type_id: str = Field(..., description="ID do tipo de cesta a simular")
    quantity_produced: int = Field(..., gt=0, description="Quantidade de cestas a simular (inteiro positivo)")
    is_custom: bool = Field(default=False, description="Indica se e simulacao de cesta personalizada")
    is_direct_sale: bool = Field(default=False, description="Indica se e simulacao de venda direta")
    custom_description: Optional[str] = Field(None, max_length=500, description="Descricao para montagens personalizadas")
    custom_items: Optional[List[CustomItemInput]] = Field(None, description="Lista de insumos da cesta personalizada")
    notes: Optional[str] = Field(None, description="Observacoes operacionais opcionais")

    @field_validator("custom_description", mode="before")
    @classmethod
    def normalize_custom_description(cls, v: Any) -> Optional[str]:
        if isinstance(v, str):
            v = v.strip()
            return v if v else None
        return v


class ProductionPreviewItemResponse(BaseModel):
    product_id: str
    product_name: str
    product_base_unit: str
    section: str
    quantity_per_basket: int
    quantity_required: int
    current_stock: int
    is_sufficient: bool
    missing_quantity: int
    unit_cost_microcents: int
    total_cost_cents: int


class ProductionPreviewResponse(BaseModel):
    can_produce: bool
    basket_type_id: str
    basket_type_name: str
    recipe_version_number: Optional[int] = None
    quantity_produced: int
    estimated_unit_cost_cents: int
    estimated_total_cost_cents: int
    items: List[ProductionPreviewItemResponse]
    missing_items: List[ProductionPreviewItemResponse]


class ProductionBatchItemResponse(BaseModel):
    id: str
    product_id: str
    product_name: str
    product_base_unit: str
    section: str
    quantity_consumed_base_units: int
    unit_cost_microcents: int
    total_cost_cents: int

    model_config = ConfigDict(from_attributes=True)


class ProductionBatchResponse(BaseModel):
    id: str
    batch_number: int
    basket_type_id: str
    basket_type_name: str
    recipe_version_id: Optional[str] = None
    recipe_version_number: Optional[int] = None
    quantity_produced: int
    quantity_disassembled: int = 0
    current_batch_stock: int
    status: str
    is_custom: bool
    is_direct_sale: bool
    custom_description: Optional[str] = None
    occurred_at: datetime.datetime
    unit_cost_cents: int
    total_cost_cents: int
    canceled_at: Optional[datetime.datetime] = None
    cancellation_reason: Optional[str] = None
    notes: Optional[str] = None
    items: List[ProductionBatchItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


class ProductionBatchListResponse(BaseModel):
    items: List[ProductionBatchResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class DisassemblyTriageItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    product_id: str = Field(..., description="ID do produto na composicao do lote")
    intact_quantity: int = Field(
        default=0,
        validation_alias=AliasChoices("intact_quantity", "quantity_intact_base_units"),
        ge=0,
        description="Quantidade intacta que retorna ao estoque (STORE)",
    )
    loss_quantity: int = Field(
        default=0,
        validation_alias=AliasChoices("loss_quantity", "quantity_loss_base_units"),
        ge=0,
        description="Quantidade avariada/violada lançada como perda (ASSEMBLY_LOSS)",
    )
    loss_reason: Optional[str] = Field(None, description="Motivo especifico da perda/avaria")


class DisassemblyRequest(BaseModel):
    quantity_to_disassemble: Optional[int] = Field(None, gt=0, description="Quantidade de cestas a desmontar (padrao: total)")
    reason: str = Field(..., min_length=3, max_length=500, description="Motivo obrigatorio para auditoria e rastreabilidade")
    triage_items: Optional[List[DisassemblyTriageItem]] = Field(None, description="Triagem detalhada item a item (se omitido, 100% retorna ao estoque)")

    @field_validator("reason", mode="before")
    @classmethod
    def validate_reason(cls, v: Any) -> str:
        if isinstance(v, str):
            v = v.strip()
            if len(v) < 3:
                raise ValueError("Motivo da desmontagem deve ter no minimo 3 caracteres.")
            return v
        raise ValueError("Motivo da desmontagem e obrigatorio.")


class CancelBatchRequest(BaseModel):
    reason: str = Field(..., min_length=3, max_length=500, description="Motivo do cancelamento / estorno")

    @field_validator("reason", mode="before")
    @classmethod
    def validate_reason(cls, v: Any) -> str:
        if isinstance(v, str):
            v = v.strip()
            if len(v) < 3:
                raise ValueError("Motivo do estorno deve ter no minimo 3 caracteres.")
            return v
        raise ValueError("Motivo do estorno e obrigatorio.")


class DisassemblyResponse(BaseModel):
    batch_id: str
    batch_number: int
    quantity_disassembled: int
    status: str
    intact_items_returned: int
    loss_items_recorded: int
    occurred_at: datetime.datetime
    message: str
