"""Append-only semantic classifications and obligations bound to credit card bills."""
import datetime
from typing import Optional

from sqlalchemy import (
    String, Integer, Boolean, Text, DateTime, ForeignKey,
    UniqueConstraint, CheckConstraint, event, DDL,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, utc_now


class FinancialBillSemanticReview(Base):
    __tablename__ = "financial_bill_semantic_reviews"
    __table_args__ = (
        UniqueConstraint("statement_id", "revision", name="uq_fin_bill_semantic_revision"),
        CheckConstraint("revision > 0", name="ck_fin_bill_semantic_revision"),
        CheckConstraint("status IN ('DRAFT','APPROVED')", name="ck_fin_bill_semantic_status"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    statement_id: Mapped[str] = mapped_column(ForeignKey("financial_statements.id"), nullable=False, index=True)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    declared_total_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    previous_balance_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    purchases_business_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    purchases_personal_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    financial_charges_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    payments_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    refunds_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    equation_difference_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_balanced: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="DRAFT", nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    items: Mapped[list["FinancialBillSemanticItem"]] = relationship(
        "FinancialBillSemanticItem", back_populates="review", cascade="all, delete-orphan",
    )
    obligations: Mapped[list["FinancialBillObligation"]] = relationship(
        "FinancialBillObligation", back_populates="review",
    )


class FinancialBillSemanticItem(Base):
    __tablename__ = "financial_bill_semantic_items"
    __table_args__ = (
        UniqueConstraint("review_id", "item_id", name="uq_fin_bill_semantic_item"),
        CheckConstraint(
            "semantic_category IN ('PURCHASE_BUSINESS','PURCHASE_PERSONAL','BILL_PAYMENT','PREVIOUS_BALANCE','FINANCIAL_CHARGES','REFUND_CREDIT','CONTEXT_ONLY')",
            name="ck_fin_bill_item_semantic_cat",
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    review_id: Mapped[str] = mapped_column(ForeignKey("financial_bill_semantic_reviews.id"), nullable=False, index=True)
    item_id: Mapped[str] = mapped_column(ForeignKey("financial_statement_items.id"), nullable=False, index=True)
    semantic_category: Mapped[str] = mapped_column(String(30), nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    purchase_id: Mapped[Optional[str]] = mapped_column(ForeignKey("purchases.id"), nullable=True, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text)

    review: Mapped["FinancialBillSemanticReview"] = relationship("FinancialBillSemanticReview", back_populates="items")


class FinancialBillObligation(Base):
    __tablename__ = "financial_bill_obligations"
    __table_args__ = (
        UniqueConstraint("statement_id", "account_payable_id", name="uq_fin_bill_obligation_payable"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    statement_id: Mapped[str] = mapped_column(ForeignKey("financial_statements.id"), nullable=False, index=True)
    review_id: Mapped[str] = mapped_column(ForeignKey("financial_bill_semantic_reviews.id"), nullable=False, index=True)
    account_payable_id: Mapped[str] = mapped_column(ForeignKey("accounts_payable.id"), nullable=False, index=True)
    component_type: Mapped[str] = mapped_column(String(30), nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    purchase_id: Mapped[Optional[str]] = mapped_column(ForeignKey("purchases.id"), nullable=True, index=True)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    review: Mapped["FinancialBillSemanticReview"] = relationship("FinancialBillSemanticReview", back_populates="obligations")


SEMANTIC_TRIGGERS = []
for table in (
    FinancialBillSemanticReview.__table__,
    FinancialBillSemanticItem.__table__,
    FinancialBillObligation.__table__,
):
    for operation in ("UPDATE", "DELETE"):
        sql = (
            f"CREATE TRIGGER IF NOT EXISTS trg_{table.name}_no_{operation.lower()} BEFORE {operation} ON {table.name} "
            "BEGIN SELECT RAISE(ABORT, 'financial evidence is immutable'); END;"
        )
        SEMANTIC_TRIGGERS.append(sql)
        event.listen(table, "after_create", DDL(sql).execute_if(dialect="sqlite"))

SEMANTIC_INSERT_TRIGGERS = [
    (
        FinancialBillSemanticReview.__table__,
        """CREATE TRIGGER IF NOT EXISTS trg_fin_bill_semantic_rev_insert BEFORE INSERT ON financial_bill_semantic_reviews
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_bill_semantic_reviews WHERE statement_id = NEW.statement_id), 0) + 1
 OR (SELECT statement_type FROM financial_statements WHERE id = NEW.statement_id) != 'CARD_BILL'
BEGIN SELECT RAISE(ABORT, 'invalid financial bill semantic review'); END;""",
    ),
    (
        FinancialBillSemanticItem.__table__,
        """CREATE TRIGGER IF NOT EXISTS trg_fin_bill_semantic_item_insert BEFORE INSERT ON financial_bill_semantic_items
WHEN (SELECT statement_id FROM financial_statement_items WHERE id = NEW.item_id) != (SELECT statement_id FROM financial_bill_semantic_reviews WHERE id = NEW.review_id)
BEGIN SELECT RAISE(ABORT, 'semantic item must belong to the same statement as review'); END;""",
    ),
    (
        FinancialBillObligation.__table__,
        """CREATE TRIGGER IF NOT EXISTS trg_fin_bill_obligation_insert BEFORE INSERT ON financial_bill_obligations
WHEN (SELECT is_balanced FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != 1
  OR (SELECT status FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != 'APPROVED'
  OR (SELECT statement_id FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != NEW.statement_id
BEGIN SELECT RAISE(ABORT, 'obligations require an approved and balanced bill review'); END;""",
    ),
]

for table, sql in SEMANTIC_INSERT_TRIGGERS:
    SEMANTIC_TRIGGERS.append(sql)
    event.listen(table, "after_create", DDL(sql).execute_if(dialect="sqlite"))
