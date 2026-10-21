from typing import Literal
from pydantic import Field, model_validator
from app.schemas.financial_imports import FinancialInput, FinancialImportContext, EntityId


class InstallmentResolve(FinancialImportContext):
    action: Literal['LINK', 'DISTINCT', 'CANCEL']
    occurrence_id: EntityId | None = None
    series_id: EntityId | None = None
    expected_revision: int = Field(strict=True, ge=0)
    expected_snapshot: str = Field(pattern=r'^[a-f0-9]{64}$')
    evidence_item_id: EntityId | None = None
    from_number: int | None = Field(None, strict=True, ge=1, le=1000)
    reason: str = Field(min_length=3, max_length=1000)

    @model_validator(mode='after')
    def shape(self):
        if self.action == 'CANCEL':
            if not self.series_id or not self.evidence_item_id or not self.from_number or self.occurrence_id:
                raise ValueError('Informe serie, evidencia e primeira parcela cancelada.')
        elif not self.occurrence_id or self.evidence_item_id or self.from_number or (self.action == 'LINK') != bool(self.series_id):
            raise ValueError('Informe a ocorrencia e a decisao de vinculo.')
        return self
