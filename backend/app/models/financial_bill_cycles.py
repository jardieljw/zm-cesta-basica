"""One operational bill per selected source/cycle; immutable evidence revisions."""
from sqlalchemy import String, Integer, Date, DateTime, Text, JSON, ForeignKey, UniqueConstraint, CheckConstraint, Index, text, event, DDL
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, utc_now


class FinancialBillCycle(Base):
    __tablename__ = 'financial_bill_cycles'
    __table_args__ = (UniqueConstraint('source_id', 'reference', name='uq_bill_source_cycle'),
                      CheckConstraint("length(reference)=7 AND reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(reference,6,2) BETWEEN '01' AND '12'", name='ck_bill_reference'),
                      CheckConstraint('revision >= 0', name='ck_bill_cycle_revision'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    source_id: Mapped[str] = mapped_column(ForeignKey('financial_sources.id'), nullable=False, index=True)
    reference: Mapped[str] = mapped_column(String(7), nullable=False)
    revision: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payable_id: Mapped[str | None] = mapped_column(ForeignKey('accounts_payable.id'), unique=True)
    created_at: Mapped[object] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialBillCycleRevision(Base):
    __tablename__ = 'financial_bill_cycle_revisions'
    __table_args__ = (
        UniqueConstraint('cycle_id', 'revision', name='uq_bill_cycle_revision'),
        CheckConstraint('revision > 0', name='ck_bill_revision_positive'),
        CheckConstraint("destination IN ('PENDING','HISTORY','OPEN','CREDIT')", name='ck_bill_destination'),
        CheckConstraint("details_status IN ('RECONCILED','AVAILABLE_UNRECONCILED','SUMMARY_ONLY')", name='ck_bill_details'),
        CheckConstraint('stock_cents >= 0 AND business_cents >= 0 AND personal_cents >= 0 AND unclassified_cents >= 0 AND stock_cents + business_cents + personal_cents + unclassified_cents = MAX(total_cents, 0)', name='ck_bill_composition'),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    cycle_id: Mapped[str] = mapped_column(ForeignKey('financial_bill_cycles.id'), nullable=False, index=True)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    statement_id: Mapped[str] = mapped_column(ForeignKey('financial_statements.id'), nullable=False, index=True)
    preview_id: Mapped[str] = mapped_column(ForeignKey('financial_import_previews.id'), nullable=False)
    command_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    total_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    due_on: Mapped[object] = mapped_column(Date, nullable=False)
    destination: Mapped[str] = mapped_column(String(16), nullable=False)
    details_status: Mapped[str] = mapped_column(String(32), nullable=False)
    difference_cents: Mapped[int | None] = mapped_column(Integer)
    control_origin: Mapped[str] = mapped_column(String(24), nullable=False)
    provenance: Mapped[dict] = mapped_column(JSON, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    stock_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    business_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    personal_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    unclassified_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey('paired_devices.id'), nullable=False)
    created_at: Mapped[object] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialBillCycleItem(Base):
    __tablename__ = 'financial_bill_cycle_items'
    __table_args__ = (UniqueConstraint('revision_id', 'item_id', name='uq_bill_revision_item'),
        CheckConstraint("role IN ('PURCHASE','CHARGE','PAYMENT','CREDIT','PREVIOUS_BALANCE','UNKNOWN')", name='ck_bill_item_role'),
        CheckConstraint("purpose IN ('UNSPECIFIED','BUSINESS','PERSONAL_WITHDRAWAL','STOCK')", name='ck_bill_item_purpose'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    revision_id: Mapped[str] = mapped_column(ForeignKey('financial_bill_cycle_revisions.id'), nullable=False, index=True)
    item_id: Mapped[str] = mapped_column(ForeignKey('financial_statement_items.id'), nullable=False)
    role: Mapped[str] = mapped_column(String(24), nullable=False)
    purpose: Mapped[str] = mapped_column(String(24), nullable=False)


class FinancialBillPayableLink(Base):
    __tablename__ = 'financial_bill_payable_links'
    __table_args__ = (UniqueConstraint('cycle_id', 'payable_id', 'kind', name='uq_bill_cycle_payable_kind'),
        Index('uq_bill_represented_payable', 'payable_id', unique=True, sqlite_where=text("kind != 'PRIMARY'")),
        CheckConstraint("kind IN ('PRIMARY','PURCHASE','PREVIOUS_BALANCE','LEGACY')", name='ck_bill_link_kind'),
        CheckConstraint('amount_cents > 0', name='ck_bill_link_amount'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    cycle_id: Mapped[str] = mapped_column(ForeignKey('financial_bill_cycles.id'), nullable=False, index=True)
    revision_id: Mapped[str] = mapped_column(ForeignKey('financial_bill_cycle_revisions.id'), nullable=False)
    payable_id: Mapped[str] = mapped_column(ForeignKey('accounts_payable.id'), nullable=False)
    kind: Mapped[str] = mapped_column(String(24), nullable=False)
    item_id: Mapped[str | None] = mapped_column(ForeignKey('financial_statement_items.id'))
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey('paired_devices.id'), nullable=False)
    created_at: Mapped[object] = mapped_column(DateTime, default=utc_now, nullable=False)


CYCLE_TABLES = (FinancialBillCycle.__table__, FinancialBillCycleRevision.__table__, FinancialBillCycleItem.__table__, FinancialBillPayableLink.__table__)
TRIGGERS = []
for table in CYCLE_TABLES:
    for operation in (('DELETE',) if table.name == 'financial_bill_cycles' else ('UPDATE', 'DELETE')):
        sql = f"CREATE TRIGGER IF NOT EXISTS trg_{table.name}_no_{operation.lower()} BEFORE {operation} ON {table.name} BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END"
        TRIGGERS.append(sql)
        event.listen(table, 'after_create', DDL(sql.replace('%', '%%')).execute_if(dialect='sqlite'))

GUARDS = [
    (FinancialBillCycle.__table__, """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_insert BEFORE INSERT ON financial_bill_cycles
WHEN (SELECT source_type FROM financial_sources WHERE id=NEW.source_id) != 'CREDIT_CARD' OR NEW.revision != 0 OR NEW.payable_id IS NOT NULL
BEGIN SELECT RAISE(ABORT, 'invalid bill source'); END"""),
    (FinancialBillCycleRevision.__table__, """CREATE TRIGGER IF NOT EXISTS trg_bill_revision_insert BEFORE INSERT ON financial_bill_cycle_revisions
WHEN NEW.revision != (SELECT revision + 1 FROM financial_bill_cycles WHERE id=NEW.cycle_id)
 OR (SELECT source_id FROM financial_statements WHERE id=NEW.statement_id) != (SELECT source_id FROM financial_bill_cycles WHERE id=NEW.cycle_id)
 OR (SELECT preview_id FROM financial_statements WHERE id=NEW.statement_id) IS NOT NEW.preview_id
 OR (SELECT total_amount_cents FROM financial_statements WHERE id=NEW.statement_id) != NEW.total_cents
 OR (SELECT due_on FROM financial_statements WHERE id=NEW.statement_id) != NEW.due_on
 OR strftime('%Y-%m', NEW.due_on) != (SELECT reference FROM financial_bill_cycles WHERE id=NEW.cycle_id)
BEGIN SELECT RAISE(ABORT, 'invalid bill revision'); END"""),
    (FinancialBillCycleItem.__table__, """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_item_insert BEFORE INSERT ON financial_bill_cycle_items
WHEN (SELECT statement_id FROM financial_statement_items WHERE id=NEW.item_id) != (SELECT statement_id FROM financial_bill_cycle_revisions WHERE id=NEW.revision_id)
BEGIN SELECT RAISE(ABORT, 'item belongs to another bill'); END"""),
    (FinancialBillPayableLink.__table__, """CREATE TRIGGER IF NOT EXISTS trg_bill_payable_link_insert BEFORE INSERT ON financial_bill_payable_links
WHEN (SELECT cycle_id FROM financial_bill_cycle_revisions WHERE id=NEW.revision_id) != NEW.cycle_id
BEGIN SELECT RAISE(ABORT, 'link belongs to another bill'); END"""),
    (FinancialBillCycle.__table__, """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_update BEFORE UPDATE ON financial_bill_cycles
WHEN NEW.id != OLD.id OR NEW.source_id != OLD.source_id OR NEW.reference != OLD.reference
 OR NEW.revision != OLD.revision + 1 OR (OLD.payable_id IS NOT NULL AND NEW.payable_id IS NOT OLD.payable_id)
 OR NOT EXISTS(SELECT 1 FROM financial_bill_cycle_revisions WHERE cycle_id=NEW.id AND revision=NEW.revision)
BEGIN SELECT RAISE(ABORT, 'invalid bill cycle transition'); END"""),
]
for table, sql in GUARDS:
    TRIGGERS.append(sql)
    event.listen(table, 'after_create', DDL(sql.replace('%', '%%')).execute_if(dialect='sqlite'))

from app.models.financial import PayablePayment, AccountPayable
PAYMENT_GUARDS = [
    (PayablePayment.__table__, """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_revision_insert BEFORE INSERT ON payable_payments
WHEN (NEW.bill_revision_id IS NULL AND EXISTS(SELECT 1 FROM financial_bill_cycles WHERE payable_id=NEW.payable_id))
 OR (NEW.bill_revision_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_bill_cycles c JOIN financial_bill_cycle_revisions r ON r.cycle_id=c.id WHERE c.payable_id=NEW.payable_id AND r.id=NEW.bill_revision_id AND r.revision=c.revision))
BEGIN SELECT RAISE(ABORT, 'invalid payment bill revision'); END"""),
    (PayablePayment.__table__, """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_no_delete BEFORE DELETE ON payable_payments
WHEN OLD.bill_revision_id IS NOT NULL
BEGIN SELECT RAISE(ABORT, 'payment composition is immutable'); END"""),
    (PayablePayment.__table__, """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_snapshot BEFORE UPDATE ON payable_payments
WHEN NEW.bill_revision_id IS NOT OLD.bill_revision_id OR NEW.stock_cents IS NOT OLD.stock_cents
 OR NEW.business_cents IS NOT OLD.business_cents OR NEW.personal_cents IS NOT OLD.personal_cents
 OR NEW.unclassified_cents IS NOT OLD.unclassified_cents
 OR (OLD.bill_revision_id IS NOT NULL AND (NEW.amount_cents != OLD.amount_cents OR NEW.payable_id != OLD.payable_id OR NEW.account_id != OLD.account_id))
BEGIN SELECT RAISE(ABORT, 'payment composition is immutable'); END"""),
    (AccountPayable.__table__, """CREATE TRIGGER IF NOT EXISTS trg_substituted_payable_guard BEFORE UPDATE ON accounts_payable
WHEN OLD.superseded_by_id IS NOT NULL AND (NEW.superseded_by_id IS NOT OLD.superseded_by_id
 OR NEW.status != OLD.status OR NEW.balance_cents != OLD.balance_cents OR NEW.paid_amount_cents != OLD.paid_amount_cents OR NEW.original_amount_cents != OLD.original_amount_cents)
 AND NOT (NEW.superseded_by_id IS NULL AND NEW.balance_cents = OLD.balance_cents
 AND NEW.paid_amount_cents = OLD.paid_amount_cents AND NEW.original_amount_cents = OLD.original_amount_cents
 AND NEW.status = CASE WHEN OLD.balance_cents=0 THEN 'PAID' WHEN OLD.paid_amount_cents>0 THEN 'PARTIAL' ELSE 'OPEN' END
 AND EXISTS(SELECT 1 FROM financial_import_entries e
 WHERE EXISTS(SELECT 1 FROM json_each(e.retained_effects,'$.represented_payables_to_restore') a WHERE a.value=OLD.id)
 AND EXISTS(SELECT 1 FROM json_each(e.retained_effects,'$.payable_ids') b WHERE b.value=OLD.superseded_by_id)
 AND NOT EXISTS(SELECT 1 FROM json_each(e.released_effects,'$.represented_payables_to_restore') x WHERE x.value=OLD.id)))
BEGIN SELECT RAISE(ABORT, 'represented payable cannot be reopened'); END"""),
]
for table, sql in PAYMENT_GUARDS:
    TRIGGERS.append(sql)
    event.listen(table, 'after_create', DDL(sql.replace('%', '%%')).execute_if(dialect='sqlite'))
