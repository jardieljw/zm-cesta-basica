"""Evidence and reconciliation, separate from the company's cash ledger.

Amounts are signed: bank credits positive; card charges positive. Unknown times
remain NULL. A source is bank/card identity, never another balance or debt book.
"""
import datetime
from typing import Optional

from sqlalchemy import (
    String, Integer, Date, Time, DateTime, Text, LargeBinary, JSON,
    ForeignKey, ForeignKeyConstraint, CheckConstraint, UniqueConstraint, Index, event, DDL, text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, utc_now


class FinancialSource(Base):
    __tablename__ = "financial_sources"
    __table_args__ = (
        CheckConstraint("source_type IN ('BANK_ACCOUNT','CREDIT_CARD')", name="ck_fin_source_type"),
        CheckConstraint("holder_type IN ('PF','PJ')", name="ck_fin_source_holder"),
        CheckConstraint("length(currency) = 3", name="ck_fin_source_currency"),
        CheckConstraint("(source_type = 'BANK_ACCOUNT' AND financial_account_id IS NOT NULL) OR "
                        "(source_type = 'CREDIT_CARD' AND financial_account_id IS NULL)", name="ck_fin_source_account"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    source_type: Mapped[str] = mapped_column(String(20), nullable=False)
    financial_account_id: Mapped[Optional[str]] = mapped_column(ForeignKey("financial_accounts.id"), unique=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    institution: Mapped[str] = mapped_column(String(100), nullable=False)
    holder_type: Mapped[str] = mapped_column(String(2), nullable=False)
    holder_name: Mapped[Optional[str]] = mapped_column(String(200))
    holder_document: Mapped[Optional[str]] = mapped_column(String(30))
    branch: Mapped[Optional[str]] = mapped_column(String(30))
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="BRL")
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialDocument(Base):
    __tablename__ = "financial_documents"
    __table_args__ = (
        CheckConstraint("size_bytes > 0 AND size_bytes <= 10485760", name="ck_fin_document_size"),
        CheckConstraint("length(sha256) = 64", name="ck_fin_document_hash"),
        CheckConstraint("length(content) = size_bytes", name="ck_fin_document_content"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    filename: Mapped[str] = mapped_column(String(200), nullable=False)
    media_type: Mapped[str] = mapped_column(String(80), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[bytes] = mapped_column(LargeBinary, nullable=False, deferred=True)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialImportPreview(Base):
    """Immutable output of a versioned reader, including invalid rows for review."""
    __tablename__ = "financial_import_previews"
    __table_args__ = (
        UniqueConstraint("document_id", "source_id", "request_sha256", name="uq_fin_preview_request"),
        CheckConstraint("status IN ('READY','INVALID')", name="ck_fin_preview_status"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    document_id: Mapped[str] = mapped_column(ForeignKey("financial_documents.id"), nullable=False)
    source_id: Mapped[str] = mapped_column(ForeignKey("financial_sources.id"), nullable=False)
    reader_id: Mapped[str] = mapped_column(String(50), nullable=False)
    reader_version: Mapped[str] = mapped_column(String(20), nullable=False)
    options: Mapped[dict] = mapped_column(JSON, nullable=False)
    request_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    result_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(10), nullable=False)
    result: Mapped[dict] = mapped_column(JSON, nullable=False, deferred=True)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialStatement(Base):
    __tablename__ = "financial_statements"
    __table_args__ = (
        UniqueConstraint("document_id", "source_id", "payload_sha256", name="uq_fin_statement_payload"),
        CheckConstraint("statement_type IN ('BANK_STATEMENT','CARD_BILL','TRANSACTION_RECEIPT')", name="ck_fin_statement_type"),
        CheckConstraint("period_start IS NULL OR period_end IS NULL OR period_end >= period_start", name="ck_fin_statement_period"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    document_id: Mapped[str] = mapped_column(ForeignKey("financial_documents.id"), nullable=False, index=True)
    source_id: Mapped[str] = mapped_column(ForeignKey("financial_sources.id"), nullable=False, index=True)
    preview_id: Mapped[Optional[str]] = mapped_column(ForeignKey("financial_import_previews.id"), index=True)
    statement_type: Mapped[str] = mapped_column(String(24), nullable=False)
    payload_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    period_start: Mapped[Optional[datetime.date]] = mapped_column(Date)
    period_end: Mapped[Optional[datetime.date]] = mapped_column(Date)
    issued_on: Mapped[Optional[datetime.date]] = mapped_column(Date)
    closing_on: Mapped[Optional[datetime.date]] = mapped_column(Date)
    due_on: Mapped[Optional[datetime.date]] = mapped_column(Date)
    opening_balance_cents: Mapped[Optional[int]] = mapped_column(Integer)
    closing_balance_cents: Mapped[Optional[int]] = mapped_column(Integer)
    total_inflows_cents: Mapped[Optional[int]] = mapped_column(Integer)
    total_outflows_cents: Mapped[Optional[int]] = mapped_column(Integer)
    total_amount_cents: Mapped[Optional[int]] = mapped_column(Integer)
    minimum_payment_cents: Mapped[Optional[int]] = mapped_column(Integer)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialTransaction(Base):
    """A reviewed external event. Its evidence may occur in multiple documents."""
    __tablename__ = "financial_transactions"
    __table_args__ = (
        UniqueConstraint("id", "source_id", name="uq_fin_transaction_source"),
        UniqueConstraint("source_id", "external_id_namespace", "external_id", name="uq_fin_transaction_external"),
        CheckConstraint("amount_cents != 0 AND amount_cents BETWEEN -9000000000000000 AND 9000000000000000", name="ck_fin_transaction_amount"),
        CheckConstraint("(external_id IS NULL AND external_id_namespace IS NULL) OR "
                        "(external_id IS NOT NULL AND external_id_namespace IS NOT NULL)", name="ck_fin_transaction_external"),
        CheckConstraint("utc_offset_minutes IS NULL OR (transaction_time IS NOT NULL AND utc_offset_minutes BETWEEN -840 AND 840)", name="ck_fin_transaction_offset"),
        CheckConstraint("(installment_number IS NULL AND total_installments IS NULL) OR "
                        "(installment_number IS NOT NULL AND total_installments IS NOT NULL AND installment_number >= 1 AND total_installments >= installment_number)", name="ck_fin_transaction_installments"),
        CheckConstraint("(transaction_time IS NULL AND time_precision IS NULL) OR "
                        "(transaction_time IS NOT NULL AND time_precision IS NOT NULL AND time_precision IN ('MINUTE','SECOND'))", name="ck_fin_transaction_time"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    source_id: Mapped[str] = mapped_column(ForeignKey("financial_sources.id"), nullable=False, index=True)
    external_id_namespace: Mapped[Optional[str]] = mapped_column(String(50))
    # SQLite does not enforce VARCHAR lengths. Keep the historic declaration to
    # avoid rebuilding immutable referenced tables; the API accepts up to 255.
    external_id: Mapped[Optional[str]] = mapped_column(String(200))
    transaction_date: Mapped[datetime.date] = mapped_column(Date, nullable=False, index=True)
    purchase_date: Mapped[Optional[datetime.date]] = mapped_column(Date)
    booking_date: Mapped[Optional[datetime.date]] = mapped_column(Date)
    transaction_time: Mapped[Optional[datetime.time]] = mapped_column(Time)
    time_precision: Mapped[Optional[str]] = mapped_column(String(6))
    utc_offset_minutes: Mapped[Optional[int]] = mapped_column(Integer)
    date_kind: Mapped[str] = mapped_column(String(20), nullable=False, default="AS_REPORTED")
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    transaction_kind: Mapped[str] = mapped_column(String(24), nullable=False, default="OTHER")
    counterparty_name: Mapped[Optional[str]] = mapped_column(String(200))
    counterparty_document: Mapped[Optional[str]] = mapped_column(String(30))
    counterparty_institution: Mapped[Optional[str]] = mapped_column(String(100))
    counterparty_branch: Mapped[Optional[str]] = mapped_column(String(30))
    counterparty_account: Mapped[Optional[str]] = mapped_column(String(60))
    card_last_four: Mapped[Optional[str]] = mapped_column(String(4))
    installment_number: Mapped[Optional[int]] = mapped_column(Integer)
    total_installments: Mapped[Optional[int]] = mapped_column(Integer)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialTransactionIdentity(Base):
    __tablename__ = "financial_transaction_identities"
    __table_args__ = (
        UniqueConstraint("source_id", "namespace", "external_id", name="uq_fin_external_identity"),
        ForeignKeyConstraint(["transaction_id", "source_id"],
                             ["financial_transactions.id", "financial_transactions.source_id"]),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    transaction_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    source_id: Mapped[str] = mapped_column(ForeignKey("financial_sources.id"), nullable=False)
    namespace: Mapped[str] = mapped_column(String(50), nullable=False)
    external_id: Mapped[str] = mapped_column(String(200), nullable=False)


class FinancialStatementItem(Base):
    __tablename__ = "financial_statement_items"
    __table_args__ = (
        UniqueConstraint("statement_id", "position", name="uq_fin_statement_item_position"),
        CheckConstraint("position > 0", name="ck_fin_item_position"),
        CheckConstraint("page_number IS NULL OR page_number > 0", name="ck_fin_item_page"),
        CheckConstraint("review_status IN ('PENDING','NEW','LINKED','IGNORED')", name="ck_fin_item_status"),
        CheckConstraint("(review_status = 'PENDING' AND transaction_id IS NULL AND reviewed_by IS NULL AND reviewed_at IS NULL) OR "
                        "(review_status = 'IGNORED' AND transaction_id IS NULL AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL) OR "
                        "(review_status IN ('NEW','LINKED') AND transaction_id IS NOT NULL AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)", name="ck_fin_item_review"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    statement_id: Mapped[str] = mapped_column(ForeignKey("financial_statements.id"), nullable=False, index=True)
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    page_number: Mapped[Optional[int]] = mapped_column(Integer)
    raw_text: Mapped[Optional[str]] = mapped_column(Text)
    normalized_data: Mapped[dict] = mapped_column(JSON, nullable=False)
    review_status: Mapped[str] = mapped_column(String(12), default="PENDING", nullable=False, index=True)
    transaction_id: Mapped[Optional[str]] = mapped_column(ForeignKey("financial_transactions.id"), index=True)
    reviewed_by: Mapped[Optional[str]] = mapped_column(ForeignKey("paired_devices.id"))
    reviewed_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)


class FinancialReviewCorrection(Base):
    """Append-only replacement for an item's completed review, never its facts."""
    __tablename__ = "financial_review_corrections"
    __table_args__ = (
        UniqueConstraint("item_id", "revision", name="uq_fin_review_revision"),
        CheckConstraint("revision > 0", name="ck_fin_review_revision"),
        CheckConstraint("(review_status = 'IGNORED' AND transaction_id IS NULL) OR "
                        "(review_status IN ('NEW','LINKED') AND transaction_id IS NOT NULL)", name="ck_fin_correction_review"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    item_id: Mapped[str] = mapped_column(ForeignKey("financial_statement_items.id"), nullable=False)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    review_status: Mapped[str] = mapped_column(String(12), nullable=False)
    transaction_id: Mapped[Optional[str]] = mapped_column(ForeignKey("financial_transactions.id"), index=True)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialIdentityChange(Base):
    """Current ID ownership is the last change, or its original immutable alias."""
    __tablename__ = "financial_identity_changes"
    __table_args__ = (
        UniqueConstraint("source_id", "namespace", "external_id", "revision", name="uq_fin_identity_revision"),
        ForeignKeyConstraint(["transaction_id", "source_id"], ["financial_transactions.id", "financial_transactions.source_id"]),
        ForeignKeyConstraint(["previous_transaction_id", "source_id"], ["financial_transactions.id", "financial_transactions.source_id"]),
        CheckConstraint("revision > 0", name="ck_fin_identity_revision"),
        CheckConstraint("transaction_id IS NOT previous_transaction_id", name="ck_fin_identity_change"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    source_id: Mapped[str] = mapped_column(ForeignKey("financial_sources.id"), nullable=False)
    namespace: Mapped[str] = mapped_column(String(50), nullable=False)
    external_id: Mapped[str] = mapped_column(String(255), nullable=False)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    previous_transaction_id: Mapped[Optional[str]] = mapped_column(String(36))
    transaction_id: Mapped[Optional[str]] = mapped_column(String(36))
    correction_id: Mapped[Optional[str]] = mapped_column(ForeignKey("financial_review_corrections.id"))
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialReconciliation(Base):
    """Evidence allocation only: linking never posts another cash movement."""
    __tablename__ = "financial_reconciliations"
    __table_args__ = (
        CheckConstraint("amount_cents > 0 AND amount_cents <= 9000000000000000", name="ck_fin_reconciliation_amount"),
        CheckConstraint("(voided_at IS NULL AND voided_by IS NULL AND void_reason IS NULL) OR "
                        "(voided_at IS NOT NULL AND voided_by IS NOT NULL AND void_reason IS NOT NULL)", name="ck_fin_reconciliation_void"),
        Index("uq_fin_reconciliation_active", "transaction_id", "cash_flow_entry_id", unique=True,
              sqlite_where=text("voided_at IS NULL")),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    transaction_id: Mapped[str] = mapped_column(ForeignKey("financial_transactions.id"), nullable=False, index=True)
    cash_flow_entry_id: Mapped[str] = mapped_column(ForeignKey("cash_flow_entries.id"), nullable=False, index=True)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    voided_by: Mapped[Optional[str]] = mapped_column(ForeignKey("paired_devices.id"))
    voided_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    void_reason: Mapped[Optional[str]] = mapped_column(Text)


class FinancialImportAudit(Base):
    __tablename__ = "financial_import_audit"
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    event_type: Mapped[str] = mapped_column(String(40), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(30), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    actor_id: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    details: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


FINANCIAL_IMPORT_TABLE_NAMES = frozenset({
    "financial_bill_assessments", "financial_bill_evidence", "financial_bill_assessment_links",
    "financial_bill_semantic_reviews", "financial_bill_semantic_items", "financial_bill_obligations",
    "financial_sources", "financial_documents", "financial_statements", "financial_statement_items",
    "financial_transactions", "financial_transaction_identities", "financial_reconciliations", "financial_import_audit",
    "financial_import_previews",
    "financial_review_corrections", "financial_identity_changes",
})


# Original evidence, identities and reviewed facts cannot be silently rewritten.
# Table-level protections also apply to direct SQL, not just application services.
IMMUTABLE_TABLES = (
    FinancialDocument.__table__, FinancialStatement.__table__, FinancialTransaction.__table__,
    FinancialTransactionIdentity.__table__, FinancialImportAudit.__table__,
    FinancialImportPreview.__table__,
    FinancialReviewCorrection.__table__, FinancialIdentityChange.__table__,
)
for _table in IMMUTABLE_TABLES:
    for _operation in ("UPDATE", "DELETE"):
        event.listen(_table, "after_create", DDL(
            f"CREATE TRIGGER IF NOT EXISTS trg_{_table.name}_no_{_operation.lower()} "
            f"BEFORE {_operation} ON {_table.name} BEGIN "
            "SELECT RAISE(ABORT, 'financial evidence is immutable'); END;"
        ).execute_if(dialect="sqlite"))

event.listen(FinancialReviewCorrection.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_correction_insert BEFORE INSERT ON financial_review_corrections
WHEN (SELECT review_status FROM financial_statement_items WHERE id = NEW.item_id) = 'PENDING'
 OR NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_review_corrections WHERE item_id = NEW.item_id), 0) + 1
 OR (NEW.transaction_id IS NOT NULL AND
     (SELECT source_id FROM financial_transactions WHERE id = NEW.transaction_id) !=
     (SELECT s.source_id FROM financial_statements s JOIN financial_statement_items i ON i.statement_id = s.id WHERE i.id = NEW.item_id))
 OR EXISTS (SELECT 1 FROM financial_reconciliations r WHERE r.voided_at IS NULL AND
     (r.transaction_id = NEW.transaction_id OR r.transaction_id = CASE
      WHEN EXISTS (SELECT 1 FROM financial_review_corrections WHERE item_id = NEW.item_id)
      THEN (SELECT transaction_id FROM financial_review_corrections WHERE item_id = NEW.item_id ORDER BY revision DESC LIMIT 1)
      ELSE (SELECT transaction_id FROM financial_statement_items WHERE id = NEW.item_id) END))
BEGIN SELECT RAISE(ABORT, 'invalid financial review correction'); END;
""").execute_if(dialect="sqlite"))

event.listen(FinancialIdentityChange.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_identity_change_insert BEFORE INSERT ON financial_identity_changes
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_identity_changes
     WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id), 0) + 1
 OR NEW.previous_transaction_id IS NOT CASE
     WHEN EXISTS (SELECT 1 FROM financial_identity_changes WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id)
     THEN (SELECT transaction_id FROM financial_identity_changes WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id ORDER BY revision DESC LIMIT 1)
     ELSE (SELECT transaction_id FROM financial_transaction_identities WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id)
     END
BEGIN SELECT RAISE(ABORT, 'invalid financial identity change'); END;
""").execute_if(dialect="sqlite"))

event.listen(FinancialStatementItem.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_items_review_only BEFORE UPDATE ON financial_statement_items
WHEN OLD.review_status != 'PENDING' OR NEW.id != OLD.id OR NEW.statement_id != OLD.statement_id
 OR NEW.position != OLD.position OR NEW.page_number IS NOT OLD.page_number
 OR NEW.raw_text IS NOT OLD.raw_text OR NEW.normalized_data != OLD.normalized_data
BEGIN SELECT RAISE(ABORT, 'original financial item cannot be changed'); END;
""").execute_if(dialect="sqlite"))
event.listen(FinancialSource.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_sources_identity BEFORE UPDATE ON financial_sources
WHEN NEW.id != OLD.id OR NEW.source_type != OLD.source_type
 OR NEW.financial_account_id IS NOT OLD.financial_account_id OR NEW.currency != OLD.currency
BEGIN SELECT RAISE(ABORT, 'source identity cannot be changed'); END;
""").execute_if(dialect="sqlite"))
event.listen(FinancialSource.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_sources_no_delete BEFORE DELETE ON financial_sources
BEGIN SELECT RAISE(ABORT, 'financial source cannot be deleted'); END;
""").execute_if(dialect="sqlite"))
event.listen(FinancialStatementItem.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_items_no_delete BEFORE DELETE ON financial_statement_items
BEGIN SELECT RAISE(ABORT, 'financial evidence cannot be deleted'); END;
""").execute_if(dialect="sqlite"))
event.listen(FinancialReconciliation.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_reconciliations_void_only BEFORE UPDATE ON financial_reconciliations
WHEN OLD.voided_at IS NOT NULL OR NEW.id != OLD.id OR NEW.transaction_id != OLD.transaction_id
 OR NEW.cash_flow_entry_id != OLD.cash_flow_entry_id OR NEW.amount_cents != OLD.amount_cents
 OR NEW.reason != OLD.reason OR NEW.created_by != OLD.created_by OR NEW.created_at != OLD.created_at
 OR NEW.voided_at IS NULL
BEGIN SELECT RAISE(ABORT, 'reconciliation can only be voided'); END;
""").execute_if(dialect="sqlite"))
event.listen(FinancialReconciliation.__table__, "after_create", DDL("""
CREATE TRIGGER IF NOT EXISTS trg_financial_reconciliations_no_delete BEFORE DELETE ON financial_reconciliations
BEGIN SELECT RAISE(ABORT, 'reconciliation cannot be deleted'); END;
""").execute_if(dialect="sqlite"))
