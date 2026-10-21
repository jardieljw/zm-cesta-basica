"""Version one of the explicit, atomic single-cycle integration command."""
from typing import Literal
from pydantic import Field, model_validator
from app.schemas.financial_imports import FinancialInput, CalendarDate, Money, EntityId


class BillItemDecision(FinancialInput):
    position: int = Field(strict=True, ge=1, le=2000)
    purpose: Literal['UNSPECIFIED', 'BUSINESS', 'PERSONAL_WITHDRAWAL', 'STOCK'] = 'UNSPECIFIED'
    role: Literal['PURCHASE', 'CHARGE', 'PAYMENT', 'CREDIT', 'PREVIOUS_BALANCE', 'UNKNOWN'] | None = None


class BillReplacement(FinancialInput):
    payable_id: EntityId
    expected_balance_cents: int = Field(strict=True, gt=0)
    kind: Literal['PURCHASE', 'PREVIOUS_BALANCE', 'LEGACY']
    position: int | None = Field(None, strict=True, ge=1, le=2000)
    reason: str = Field(min_length=3, max_length=1000)


class BillCycleIntegrate(FinancialInput):
    import_id: EntityId | None = None
    expected_generation: int | None = Field(None, strict=True, ge=1)
    version: Literal[1] = 1
    expected_source_id: EntityId
    expected_result_sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    expected_revision: int = Field(strict=True, ge=0)
    reference: str = Field(pattern=r'^\d{4}-(0[1-9]|1[0-2])$')
    due_on: CalendarDate
    total_amount_cents: Money
    destination: Literal['PENDING', 'HISTORY', 'OPEN']
    controls_confirmed: bool = False
    accept_details_pending: bool = False
    due_conflict_resolved: bool = False
    accept_content_change: bool = False
    estimate_installment_day: bool = True
    control_preview_id: EntityId | None = None
    reason: str = Field(min_length=3, max_length=1000)
    items: list[BillItemDecision] = Field(default_factory=list, max_length=2000)
    replacements: list[BillReplacement] = Field(default_factory=list, max_length=2000)

    @model_validator(mode='after')
    def distinct(self):
        if len({i.position for i in self.items}) != len(self.items) or len({r.payable_id for r in self.replacements}) != len(self.replacements):
            raise ValueError('Decisoes repetidas.')
        if self.reference != self.due_on.strftime('%Y-%m'):
            raise ValueError('A referencia deve identificar o mes de vencimento confirmado.')
        return self
