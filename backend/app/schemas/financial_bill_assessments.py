"""Manual, attributed evidence checks; never a commercial authorization."""
from typing import Literal

from pydantic import Field, model_validator

from app.schemas.financial_imports import FinancialInput, CalendarDate, Money, EntityId


class BillHeader(FinancialInput):
    due_on: CalendarDate
    total_amount_cents: Money
    period_start: CalendarDate | None = None
    period_end: CalendarDate | None = None

    @model_validator(mode="after")
    def period(self):
        if (self.period_start is None) != (self.period_end is None):
            raise ValueError("Informar ambas as datas do periodo.")
        if self.period_start and self.period_end < self.period_start:
            raise ValueError("Periodo invertido.")
        return self


class EvidenceLocator(FinancialInput):
    page_number: int | None = Field(None, strict=True, ge=1, le=10000)
    line_start: int | None = Field(None, strict=True, ge=1, le=10000)
    line_end: int | None = Field(None, strict=True, ge=1, le=10000)

    @model_validator(mode="after")
    def locator(self):
        if self.page_number is None and self.line_start is None:
            raise ValueError("Informar pagina ou registro de origem.")
        if self.line_end is not None and (self.line_start is None or self.line_end < self.line_start):
            raise ValueError("Intervalo de registros invalido.")
        return self


class BillReferenceItem(FinancialInput):
    preview_position: int | None = Field(None, strict=True, ge=1, le=2000)
    transaction_date: CalendarDate
    amount_cents: Money
    description: str = Field(min_length=1, max_length=2000)


class BillEvidenceCreate(EvidenceLocator):
    document_id: EntityId
    role: Literal["HEADER", "DETAILS"]
    source_id: EntityId
    currency: str = Field(pattern=r"^[A-Z]{3}$")
    identity_reason: str = Field(min_length=3, max_length=1000)
    # Manually transcribed claims, not facts extracted by an automated PDF reader.
    header: BillHeader
    items: list[BillReferenceItem] = Field(default_factory=list, max_length=2000)

    @model_validator(mode="after")
    def role_shape(self):
        if self.role == "HEADER" and self.items:
            raise ValueError("Cabecalho nao recebe detalhes de transacao.")
        return self


class BillObservation(FinancialInput):
    key: str = Field(pattern=r"^[a-z0-9_-]{1,40}$")
    reason: str = Field(min_length=3, max_length=1000)


class BillFindingResolution(EvidenceLocator):
    finding_id: str = Field(min_length=1, max_length=150)
    reason: str = Field(min_length=3, max_length=1000)
    document_id: EntityId


class BillAssessmentCreate(FinancialInput):
    expected_revision: int = Field(strict=True, ge=0)
    expected_source_id: EntityId
    expected_result_sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    reason: str = Field(min_length=3, max_length=1000)
    header: BillHeader | None = None
    evidence: list[BillEvidenceCreate] = Field(default_factory=list, max_length=20)
    observations: list[BillObservation] = Field(default_factory=list, max_length=100)
    resolutions: list[BillFindingResolution] = Field(default_factory=list, max_length=8200)

    @model_validator(mode="after")
    def distinct_keys(self):
        for values in ([o.key for o in self.observations], [r.finding_id for r in self.resolutions]):
            if len(set(values)) != len(values):
                raise ValueError("Referencias repetidas.")
        if sum(len(e.items) for e in self.evidence) > 2000:
            raise ValueError("Limite de detalhes excedido.")
        return self
