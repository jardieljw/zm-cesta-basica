"""Contracts for credit card bill semantic reviews and obligations."""
import datetime
from typing import Literal, Optional

from pydantic import Field, model_validator

from app.schemas.financial_imports import FinancialInput, FinancialImportContext, EntityId, Money


SemanticCategory = Literal[
    "PURCHASE_BUSINESS",
    "PURCHASE_PERSONAL",
    "BILL_PAYMENT",
    "PREVIOUS_BALANCE",
    "FINANCIAL_CHARGES",
    "REFUND_CREDIT",
    "CONTEXT_ONLY",
]


class BillSemanticItemInput(FinancialInput):
    item_id: EntityId
    semantic_category: SemanticCategory
    purchase_id: Optional[EntityId] = None
    notes: Optional[str] = Field(None, max_length=1000)


class BillSemanticReviewCreate(FinancialImportContext):
    expected_revision: int = Field(strict=True, ge=0)
    notes: Optional[str] = Field(None, max_length=2000)
    items: list[BillSemanticItemInput] = Field(default_factory=list, max_length=5000)

    @model_validator(mode="after")
    def distinct_items(self):
        ids = [i.item_id for i in self.items]
        if len(ids) != len(set(ids)):
            raise ValueError("Linhas repetidas na revisao semantica.")
        return self


class BillSemanticItemResponse(FinancialInput):
    id: str
    item_id: str
    position: Optional[int] = None
    description: Optional[str] = None
    transaction_date: Optional[str] = None
    amount_cents: int
    semantic_category: str
    purchase_id: Optional[str] = None
    notes: Optional[str] = None


class BillSemanticReviewResponse(FinancialInput):
    id: str
    statement_id: str
    revision: int
    declared_total_cents: int
    previous_balance_cents: int
    purchases_business_cents: int
    purchases_personal_cents: int
    financial_charges_cents: int
    payments_cents: int
    refunds_cents: int
    equation_difference_cents: int
    is_balanced: bool
    status: str
    notes: Optional[str] = None
    created_by: str
    created_at: datetime.datetime
    items: list[BillSemanticItemResponse] = Field(default_factory=list)


class BillGenerateObligationsRequest(FinancialImportContext):
    review_id: Optional[EntityId] = None
    notes: Optional[str] = Field(None, max_length=1000)


class BillObligationResponse(FinancialInput):
    id: str
    statement_id: str
    review_id: str
    account_payable_id: str
    payable_number: Optional[int] = None
    component_type: str
    amount_cents: int
    purchase_id: Optional[str] = None
    status: Optional[str] = None
    due_date: Optional[datetime.datetime] = None
    description: Optional[str] = None
    category: Optional[str] = None
    nature: Optional[str] = None
    created_at: datetime.datetime
