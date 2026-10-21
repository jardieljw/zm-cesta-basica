"""Imported installment agenda, separate from payable debt. Evidence is append-only."""
from sqlalchemy import String, Integer, Date, DateTime, ForeignKey, UniqueConstraint, CheckConstraint, JSON, event, DDL
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, utc_now


class InstallmentSeries(Base):
    __tablename__ = 'financial_installment_series'
    __table_args__ = (CheckConstraint('total BETWEEN 1 AND 1000 AND base_number BETWEEN 1 AND total', name='ck_series_numbers'),
        CheckConstraint('amount_cents > 0 AND (base_day IS NULL OR base_day BETWEEN 1 AND 31)', name='ck_series_estimate'),
        CheckConstraint("length(base_reference)=7 AND base_reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(base_reference,1,4) >= '0001' AND substr(base_reference,6,2) BETWEEN '01' AND '12'", name='ck_series_reference'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    source_id: Mapped[str] = mapped_column(ForeignKey('financial_sources.id'), nullable=False, index=True)
    origin_item_id: Mapped[str] = mapped_column(ForeignKey('financial_statement_items.id'), nullable=False, unique=True)
    description: Mapped[str] = mapped_column(String(2000), nullable=False)
    match_key: Mapped[str] = mapped_column(String(2000), nullable=False)
    base_reference: Mapped[str] = mapped_column(String(7), nullable=False)
    base_number: Mapped[int] = mapped_column(Integer, nullable=False)
    total: Mapped[int] = mapped_column(Integer, nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    base_day: Mapped[int | None] = mapped_column(Integer)
    provenance: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[object] = mapped_column(DateTime, default=utc_now, nullable=False)


class InstallmentOccurrence(Base):
    __tablename__ = 'financial_installment_occurrences'
    __table_args__ = (UniqueConstraint('revision_id', 'item_id', name='uq_installment_revision_item'),
        CheckConstraint('number BETWEEN 1 AND total AND total <= 1000 AND amount_cents > 0', name='ck_occurrence_numbers'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    revision_id: Mapped[str] = mapped_column(ForeignKey('financial_bill_cycle_revisions.id'), nullable=False, index=True)
    item_id: Mapped[str] = mapped_column(ForeignKey('financial_statement_items.id'), nullable=False)
    series_id: Mapped[str | None] = mapped_column(ForeignKey('financial_installment_series.id'))
    slot_key: Mapped[str] = mapped_column(String(64), nullable=False)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    total: Mapped[int] = mapped_column(Integer, nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)


class InstallmentForecast(Base):
    __tablename__ = 'financial_installment_forecasts'
    __table_args__ = (UniqueConstraint('series_id', 'number', name='uq_series_forecast_number'),
        CheckConstraint('number BETWEEN 1 AND 1000 AND amount_cents > 0', name='ck_forecast_values'),
        CheckConstraint("length(reference)=7 AND reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(reference,1,4) >= '0001' AND substr(reference,6,2) BETWEEN '01' AND '12'", name='ck_forecast_reference'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    series_id: Mapped[str] = mapped_column(ForeignKey('financial_installment_series.id'), nullable=False, index=True)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    reference: Mapped[str] = mapped_column(String(7), nullable=False, index=True)
    estimated_due_on: Mapped[object | None] = mapped_column(Date)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)


class InstallmentDecision(Base):
    __tablename__ = 'financial_installment_decisions'
    __table_args__ = (UniqueConstraint('occurrence_id', name='uq_installment_decision'),
        CheckConstraint("action IN ('LINK','DISTINCT','CANCEL')", name='ck_installment_action'),
        CheckConstraint("(action = 'CANCEL' AND occurrence_id IS NULL AND evidence_item_id IS NOT NULL AND from_number IS NOT NULL AND from_number BETWEEN 1 AND 1000) OR (action != 'CANCEL' AND occurrence_id IS NOT NULL AND evidence_item_id IS NULL AND from_number IS NULL)", name='ck_installment_decision_shape'))
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    occurrence_id: Mapped[str | None] = mapped_column(ForeignKey('financial_installment_occurrences.id'))
    series_id: Mapped[str] = mapped_column(ForeignKey('financial_installment_series.id'), nullable=False, index=True)
    action: Mapped[str] = mapped_column(String(12), nullable=False)
    evidence_item_id: Mapped[str | None] = mapped_column(ForeignKey('financial_statement_items.id'))
    from_number: Mapped[int | None] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(String(1000), nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey('paired_devices.id'), nullable=False)
    created_at: Mapped[object] = mapped_column(DateTime, default=utc_now, nullable=False)


TABLES = [InstallmentSeries.__table__, InstallmentOccurrence.__table__, InstallmentForecast.__table__, InstallmentDecision.__table__]
TRIGGERS = []
for table in TABLES:
    for operation in ('UPDATE', 'DELETE'):
        sql = f"CREATE TRIGGER IF NOT EXISTS trg_{table.name}_no_{operation.lower()} BEFORE {operation} ON {table.name} BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END"
        TRIGGERS.append(sql)
        event.listen(table, 'after_create', DDL(sql).execute_if(dialect='sqlite'))

GUARDS = [
    (InstallmentSeries.__table__, """CREATE TRIGGER trg_installment_series_insert BEFORE INSERT ON financial_installment_series
WHEN (SELECT source_type FROM financial_sources WHERE id=NEW.source_id) != 'CREDIT_CARD'
 OR NOT EXISTS(SELECT 1 FROM financial_statement_items i JOIN financial_statements s ON s.id=i.statement_id WHERE i.id=NEW.origin_item_id AND s.source_id=NEW.source_id)
 OR length(NEW.base_reference) != 7 OR substr(NEW.base_reference,6,2) NOT BETWEEN '01' AND '12'
BEGIN SELECT RAISE(ABORT, 'invalid installment origin'); END"""),
    (InstallmentOccurrence.__table__, """CREATE TRIGGER trg_installment_occurrence_insert BEFORE INSERT ON financial_installment_occurrences
WHEN NOT EXISTS(SELECT 1 FROM financial_bill_cycle_revisions r JOIN financial_statement_items i ON i.statement_id=r.statement_id WHERE r.id=NEW.revision_id AND i.id=NEW.item_id
 AND json_extract(i.normalized_data,'$.installment_number')=NEW.number AND json_extract(i.normalized_data,'$.total_installments')=NEW.total AND json_extract(i.normalized_data,'$.amount_cents')=NEW.amount_cents)
 OR (NEW.series_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_installment_series s JOIN financial_bill_cycles c ON c.source_id=s.source_id JOIN financial_bill_cycle_revisions r ON r.cycle_id=c.id WHERE s.id=NEW.series_id AND r.id=NEW.revision_id AND s.total=NEW.total))
BEGIN SELECT RAISE(ABORT, 'invalid installment occurrence'); END"""),
    (InstallmentForecast.__table__, """CREATE TRIGGER trg_installment_forecast_insert BEFORE INSERT ON financial_installment_forecasts
WHEN NEW.number > (SELECT total FROM financial_installment_series WHERE id=NEW.series_id)
 OR NEW.amount_cents != (SELECT amount_cents FROM financial_installment_series WHERE id=NEW.series_id)
 OR length(NEW.reference) != 7 OR substr(NEW.reference,6,2) NOT BETWEEN '01' AND '12'
 OR (NEW.estimated_due_on IS NOT NULL AND strftime('%Y-%m',NEW.estimated_due_on) IS NOT NEW.reference)
BEGIN SELECT RAISE(ABORT, 'invalid installment forecast'); END"""),
    (InstallmentDecision.__table__, """CREATE TRIGGER trg_installment_decision_insert BEFORE INSERT ON financial_installment_decisions
WHEN (NEW.occurrence_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_installment_occurrences o JOIN financial_bill_cycle_revisions r ON r.id=o.revision_id JOIN financial_bill_cycles c ON c.id=r.cycle_id JOIN financial_installment_series s ON s.source_id=c.source_id WHERE o.id=NEW.occurrence_id AND s.id=NEW.series_id AND s.total=o.total AND o.series_id IS NULL))
 OR (NEW.action='CANCEL' AND (NEW.from_number > (SELECT total FROM financial_installment_series WHERE id=NEW.series_id)
 OR NOT EXISTS(SELECT 1 FROM financial_statement_items i JOIN financial_statements st ON st.id=i.statement_id JOIN financial_installment_series s ON s.source_id=st.source_id JOIN financial_bill_cycle_items m ON m.item_id=i.id WHERE i.id=NEW.evidence_item_id AND s.id=NEW.series_id AND m.role='CREDIT')))
BEGIN SELECT RAISE(ABORT, 'invalid installment decision'); END"""),
]
for table, sql in GUARDS:
    TRIGGERS.append(sql)
    event.listen(table, 'after_create', DDL(sql.replace('%', '%%')).execute_if(dialect='sqlite'))
