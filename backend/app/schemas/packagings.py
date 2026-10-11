from typing import Optional, Any
from pydantic import BaseModel, Field, ConfigDict, field_validator

class PackagingBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Nome da embalagem comercial (ex: 'Fardo c/ 10 un', 'Saco 5 kg')")
    quantity_in_base_units: int = Field(..., gt=0, description="Fator de conversao estrito para a unidade base de estoque (> 0)")
    is_default: bool = Field(default=False, description="Indica se e a embalagem padrao de compra")
    is_active: bool = Field(default=True, description="Status ativo da embalagem")

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome da embalagem não pode ser vazio ou conter apenas espaços.")
        return v

class PackagingCreate(PackagingBase):
    pass

class PackagingUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    quantity_in_base_units: Optional[int] = Field(None, gt=0)
    is_default: Optional[bool] = None
    is_active: Optional[bool] = None

    @field_validator("name", mode="before")
    @classmethod
    def validate_name(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("Nome da embalagem não pode ser vazio ou conter apenas espaços.")
        return v

class PackagingResponse(PackagingBase):
    id: str
    product_id: str

    model_config = ConfigDict(from_attributes=True)
