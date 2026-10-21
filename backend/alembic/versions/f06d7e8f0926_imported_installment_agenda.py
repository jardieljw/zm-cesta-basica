"""Imported installment agenda; additive, no retroactive debt or projections."""
from alembic import op
revision = "f06d7e8f0926"
down_revision = "ff5c6d7e9815"
branch_labels = depends_on = None

SQL = [
    """CREATE TABLE financial_installment_series (
	id VARCHAR(36) NOT NULL, 
	source_id VARCHAR(36) NOT NULL, 
	origin_item_id VARCHAR(36) NOT NULL, 
	description VARCHAR(2000) NOT NULL, 
	match_key VARCHAR(2000) NOT NULL, 
	base_reference VARCHAR(7) NOT NULL, 
	base_number INTEGER NOT NULL, 
	total INTEGER NOT NULL, 
	amount_cents INTEGER NOT NULL, 
	base_day INTEGER, 
	provenance JSON NOT NULL, 
	created_at DATETIME NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_series_numbers CHECK (total BETWEEN 1 AND 1000 AND base_number BETWEEN 1 AND total), 
	CONSTRAINT ck_series_estimate CHECK (amount_cents > 0 AND (base_day IS NULL OR base_day BETWEEN 1 AND 31)), 
	CONSTRAINT ck_series_reference CHECK (length(base_reference)=7 AND base_reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(base_reference,1,4) >= '0001' AND substr(base_reference,6,2) BETWEEN '01' AND '12'), 
	FOREIGN KEY(source_id) REFERENCES financial_sources (id), 
	UNIQUE (origin_item_id), 
	FOREIGN KEY(origin_item_id) REFERENCES financial_statement_items (id)
)""",
    """CREATE INDEX ix_financial_installment_series_source_id ON financial_installment_series (source_id)""",
    """CREATE TABLE financial_installment_occurrences (
	id VARCHAR(36) NOT NULL, 
	revision_id VARCHAR(36) NOT NULL, 
	item_id VARCHAR(36) NOT NULL, 
	series_id VARCHAR(36), 
	slot_key VARCHAR(64) NOT NULL, 
	number INTEGER NOT NULL, 
	total INTEGER NOT NULL, 
	amount_cents INTEGER NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_installment_revision_item UNIQUE (revision_id, item_id), 
	CONSTRAINT ck_occurrence_numbers CHECK (number BETWEEN 1 AND total AND total <= 1000 AND amount_cents > 0), 
	FOREIGN KEY(revision_id) REFERENCES financial_bill_cycle_revisions (id), 
	FOREIGN KEY(item_id) REFERENCES financial_statement_items (id), 
	FOREIGN KEY(series_id) REFERENCES financial_installment_series (id)
)""",
    """CREATE INDEX ix_financial_installment_occurrences_revision_id ON financial_installment_occurrences (revision_id)""",
    """CREATE TABLE financial_installment_forecasts (
	id VARCHAR(36) NOT NULL, 
	series_id VARCHAR(36) NOT NULL, 
	number INTEGER NOT NULL, 
	reference VARCHAR(7) NOT NULL, 
	estimated_due_on DATE, 
	amount_cents INTEGER NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_series_forecast_number UNIQUE (series_id, number), 
	CONSTRAINT ck_forecast_values CHECK (number BETWEEN 1 AND 1000 AND amount_cents > 0), 
	CONSTRAINT ck_forecast_reference CHECK (length(reference)=7 AND reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(reference,1,4) >= '0001' AND substr(reference,6,2) BETWEEN '01' AND '12'), 
	FOREIGN KEY(series_id) REFERENCES financial_installment_series (id)
)""",
    """CREATE INDEX ix_financial_installment_forecasts_reference ON financial_installment_forecasts (reference)""",
    """CREATE INDEX ix_financial_installment_forecasts_series_id ON financial_installment_forecasts (series_id)""",
    """CREATE TABLE financial_installment_decisions (
	id VARCHAR(36) NOT NULL, 
	occurrence_id VARCHAR(36), 
	series_id VARCHAR(36) NOT NULL, 
	action VARCHAR(12) NOT NULL, 
	evidence_item_id VARCHAR(36), 
	from_number INTEGER, 
	reason VARCHAR(1000) NOT NULL, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_installment_decision UNIQUE (occurrence_id), 
	CONSTRAINT ck_installment_action CHECK (action IN ('LINK','DISTINCT','CANCEL')), 
	CONSTRAINT ck_installment_decision_shape CHECK ((action = 'CANCEL' AND occurrence_id IS NULL AND evidence_item_id IS NOT NULL AND from_number IS NOT NULL AND from_number BETWEEN 1 AND 1000) OR (action != 'CANCEL' AND occurrence_id IS NOT NULL AND evidence_item_id IS NULL AND from_number IS NULL)), 
	FOREIGN KEY(occurrence_id) REFERENCES financial_installment_occurrences (id), 
	FOREIGN KEY(series_id) REFERENCES financial_installment_series (id), 
	FOREIGN KEY(evidence_item_id) REFERENCES financial_statement_items (id), 
	FOREIGN KEY(created_by) REFERENCES paired_devices (id)
)""",
    """CREATE INDEX ix_financial_installment_decisions_series_id ON financial_installment_decisions (series_id)""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_series_no_update BEFORE UPDATE ON financial_installment_series BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_series_no_delete BEFORE DELETE ON financial_installment_series BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_occurrences_no_update BEFORE UPDATE ON financial_installment_occurrences BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_occurrences_no_delete BEFORE DELETE ON financial_installment_occurrences BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_forecasts_no_update BEFORE UPDATE ON financial_installment_forecasts BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_forecasts_no_delete BEFORE DELETE ON financial_installment_forecasts BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_decisions_no_update BEFORE UPDATE ON financial_installment_decisions BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_installment_decisions_no_delete BEFORE DELETE ON financial_installment_decisions BEGIN SELECT RAISE(ABORT, 'installment evidence is immutable'); END""",
    """CREATE TRIGGER trg_installment_series_insert BEFORE INSERT ON financial_installment_series
WHEN (SELECT source_type FROM financial_sources WHERE id=NEW.source_id) != 'CREDIT_CARD'
 OR NOT EXISTS(SELECT 1 FROM financial_statement_items i JOIN financial_statements s ON s.id=i.statement_id WHERE i.id=NEW.origin_item_id AND s.source_id=NEW.source_id)
 OR length(NEW.base_reference) != 7 OR substr(NEW.base_reference,6,2) NOT BETWEEN '01' AND '12'
BEGIN SELECT RAISE(ABORT, 'invalid installment origin'); END""",
    """CREATE TRIGGER trg_installment_occurrence_insert BEFORE INSERT ON financial_installment_occurrences
WHEN NOT EXISTS(SELECT 1 FROM financial_bill_cycle_revisions r JOIN financial_statement_items i ON i.statement_id=r.statement_id WHERE r.id=NEW.revision_id AND i.id=NEW.item_id
 AND json_extract(i.normalized_data,'$.installment_number')=NEW.number AND json_extract(i.normalized_data,'$.total_installments')=NEW.total AND json_extract(i.normalized_data,'$.amount_cents')=NEW.amount_cents)
 OR (NEW.series_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_installment_series s JOIN financial_bill_cycles c ON c.source_id=s.source_id JOIN financial_bill_cycle_revisions r ON r.cycle_id=c.id WHERE s.id=NEW.series_id AND r.id=NEW.revision_id AND s.total=NEW.total))
BEGIN SELECT RAISE(ABORT, 'invalid installment occurrence'); END""",
    """CREATE TRIGGER trg_installment_forecast_insert BEFORE INSERT ON financial_installment_forecasts
WHEN NEW.number > (SELECT total FROM financial_installment_series WHERE id=NEW.series_id)
 OR NEW.amount_cents != (SELECT amount_cents FROM financial_installment_series WHERE id=NEW.series_id)
 OR length(NEW.reference) != 7 OR substr(NEW.reference,6,2) NOT BETWEEN '01' AND '12'
 OR (NEW.estimated_due_on IS NOT NULL AND strftime('%Y-%m',NEW.estimated_due_on) IS NOT NEW.reference)
BEGIN SELECT RAISE(ABORT, 'invalid installment forecast'); END""",
    """CREATE TRIGGER trg_installment_decision_insert BEFORE INSERT ON financial_installment_decisions
WHEN (NEW.occurrence_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_installment_occurrences o JOIN financial_bill_cycle_revisions r ON r.id=o.revision_id JOIN financial_bill_cycles c ON c.id=r.cycle_id JOIN financial_installment_series s ON s.source_id=c.source_id WHERE o.id=NEW.occurrence_id AND s.id=NEW.series_id AND s.total=o.total AND o.series_id IS NULL))
 OR (NEW.action='CANCEL' AND (NEW.from_number > (SELECT total FROM financial_installment_series WHERE id=NEW.series_id)
 OR NOT EXISTS(SELECT 1 FROM financial_statement_items i JOIN financial_statements st ON st.id=i.statement_id JOIN financial_installment_series s ON s.source_id=st.source_id JOIN financial_bill_cycle_items m ON m.item_id=i.id WHERE i.id=NEW.evidence_item_id AND s.id=NEW.series_id AND m.role='CREDIT')))
BEGIN SELECT RAISE(ABORT, 'invalid installment decision'); END"""
]

def upgrade():
    for statement in SQL:
        op.execute(statement)

def downgrade():
    connection = op.get_bind()
    tables = ['financial_installment_decisions', 'financial_installment_forecasts', 'financial_installment_occurrences', 'financial_installment_series']
    if any(connection.exec_driver_sql("SELECT 1 FROM " + t + " LIMIT 1").first() for t in tables):
        raise RuntimeError("Installment evidence exists; preserve history and revert application version instead.")
    for table in tables:
        op.drop_table(table)
