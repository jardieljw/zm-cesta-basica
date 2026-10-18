import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator

class RecipeItemBase(BaseModel):
    product_id: str = Field(..., min_length=1, description="ID do produto/insumo ativo")
    quantity_in_base_units: int = Field(..., gt=0, description="Quantidade necessaria do insumo na unidade-base (> 0)")
    section: str = Field(default="ALIMENTACAO", min_length=1, max_length=50, description="Secao fisica/logica (ex: ALIMENTACAO, LIMPEZA, CARNE, OUTROS)")
    is_required: bool = Field(default=True, description="Indica se o item e obrigatorio")

    @field_validator("product_id", mode="before")
    @classmethod
    def validate_product_id(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("product_id não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("section", mode="before")
    @classmethod
    def validate_section(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if not v:
                raise ValueError("Seção não pode ser vazia.")
        return v

class RecipeItemCreate(RecipeItemBase):
    pass

class RecipeItemResponse(RecipeItemBase):
    id: str
    recipe_version_id: str
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    product_base_unit: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class RecipeVersionCreate(BaseModel):
    notes: Optional[str] = Field(None, description="Observacoes sobre a revisao da receita")
    items: List[RecipeItemCreate] = Field(..., min_length=1, description="Lista de insumos componentes (minimo 1 item)")

class RecipeVersionResponse(BaseModel):
    id: str
    basket_type_id: str
    version_number: int
    status: str # ACTIVE, ARCHIVED
    created_at: datetime.datetime
    notes: Optional[str] = None
    items: List[RecipeItemResponse] = []

    model_config = ConfigDict(from_attributes=True)

class BasketTypeBase(BaseModel):
    code: str = Field(..., min_length=1, max_length=50, description="Codigo unico (ex: BASICA_TIPO_1, NATALINA, CARNE)")
    name: str = Field(..., min_length=1, max_length=100, description="Nome da cesta")
    description: Optional[str] = Field(None, description="Descricao detalhada da cesta")
    category: str = Field(default="PADRAO", min_length=1, max_length=50, description="Categoria da cesta (PADRAO, NATALINA, CARNE, PERSONALIZADA)")
    default_price_cents: int = Field(default=0, ge=0, description="Preco de venda sugerido/padrao em centavos")
    allows_customization: bool = Field(default=False, description="Indica se a cesta aceita customizacao na venda")
    tracks_finished_stock: bool = Field(default=True, description="Indica se o saldo de cestas acabadas e controlado")
    is_active: bool = Field(default=True, description="Status ativo do tipo de cesta")

    @field_validator("code", "category", mode="before")
    @classmethod
    def validate_code_and_category(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if not v:
                raise ValueError("Código e categoria não podem ser vazios.")
        return v

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome da cesta não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("description", mode="before")
    @classmethod
    def normalize_description(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class BasketTypeCreate(BasketTypeBase):
    pass

class BasketTypeUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    category: Optional[str] = Field(None, min_length=1, max_length=50)
    default_price_cents: Optional[int] = Field(None, ge=0)
    allows_customization: Optional[bool] = None
    tracks_finished_stock: Optional[bool] = None
    is_active: Optional[bool] = None

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome da cesta não pode ser vazio ou conter apenas espaços.")
        return v

    @field_validator("category", mode="before")
    @classmethod
    def validate_category(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip().upper()
            if not v:
                raise ValueError("Categoria não pode ser vazia.")
        return v

    @field_validator("description", mode="before")
    @classmethod
    def normalize_description(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                return None
        return v

class BasketTypeResponse(BasketTypeBase):
    id: str
    removed_at: Optional[datetime.datetime] = None
    active_recipe: Optional[RecipeVersionResponse] = None

    model_config = ConfigDict(from_attributes=True)

class BasketTypeInactivationResponse(BaseModel):
    id: str
    code: str
    name: str
    is_active: bool
    message: str


class BasketDeletionCheck(BaseModel):
    id: str
    name: str
    can_delete: bool
    deletion_mode: str
    reasons: List[str] = []
    history_reasons: List[str] = []


class BasketDeletionResponse(BaseModel):
    id: str
    name: str
    deleted: bool
    deletion_mode: str
    removed_recipes_count: int = 0
