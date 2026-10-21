"""Single bill cycles, represented balances and payment composition; additive only."""
from alembic import op
import sqlalchemy as sa
revision = 'ff5c6d7e9815'
down_revision = 'fe4b5c6d8714'
branch_labels = depends_on = None

TABLES = [
    """CREATE TABLE financial_bill_cycles (
	id VARCHAR(36) NOT NULL, 
	source_id VARCHAR(36) NOT NULL, 
	reference VARCHAR(7) NOT NULL, 
	revision INTEGER NOT NULL, 
	payable_id VARCHAR(36), 
	created_at DATETIME NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_bill_source_cycle UNIQUE (source_id, reference), 
	CONSTRAINT ck_bill_reference CHECK (length(reference)=7 AND reference GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]' AND substr(reference,6,2) BETWEEN '01' AND '12'), 
	CONSTRAINT ck_bill_cycle_revision CHECK (revision >= 0), 
	FOREIGN KEY(source_id) REFERENCES financial_sources (id), 
	UNIQUE (payable_id), 
	FOREIGN KEY(payable_id) REFERENCES accounts_payable (id)
)""",
    """CREATE INDEX ix_financial_bill_cycles_source_id ON financial_bill_cycles (source_id)""",
    """CREATE TABLE financial_bill_cycle_revisions (
	id VARCHAR(36) NOT NULL, 
	cycle_id VARCHAR(36) NOT NULL, 
	revision INTEGER NOT NULL, 
	statement_id VARCHAR(36) NOT NULL, 
	preview_id VARCHAR(36) NOT NULL, 
	command_sha256 VARCHAR(64) NOT NULL, 
	total_cents INTEGER NOT NULL, 
	due_on DATE NOT NULL, 
	destination VARCHAR(16) NOT NULL, 
	details_status VARCHAR(32) NOT NULL, 
	difference_cents INTEGER, 
	control_origin VARCHAR(24) NOT NULL, 
	provenance JSON NOT NULL, 
	reason TEXT NOT NULL, 
	stock_cents INTEGER NOT NULL, 
	business_cents INTEGER NOT NULL, 
	personal_cents INTEGER NOT NULL, 
	unclassified_cents INTEGER NOT NULL, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_bill_cycle_revision UNIQUE (cycle_id, revision), 
	CONSTRAINT ck_bill_revision_positive CHECK (revision > 0), 
	CONSTRAINT ck_bill_destination CHECK (destination IN ('PENDING','HISTORY','OPEN','CREDIT')), 
	CONSTRAINT ck_bill_details CHECK (details_status IN ('RECONCILED','AVAILABLE_UNRECONCILED','SUMMARY_ONLY')), 
	CONSTRAINT ck_bill_composition CHECK (stock_cents >= 0 AND business_cents >= 0 AND personal_cents >= 0 AND unclassified_cents >= 0 AND stock_cents + business_cents + personal_cents + unclassified_cents = MAX(total_cents, 0)), 
	FOREIGN KEY(cycle_id) REFERENCES financial_bill_cycles (id), 
	FOREIGN KEY(statement_id) REFERENCES financial_statements (id), 
	FOREIGN KEY(preview_id) REFERENCES financial_import_previews (id), 
	FOREIGN KEY(created_by) REFERENCES paired_devices (id)
)""",
    """CREATE INDEX ix_financial_bill_cycle_revisions_cycle_id ON financial_bill_cycle_revisions (cycle_id)""",
    """CREATE INDEX ix_financial_bill_cycle_revisions_statement_id ON financial_bill_cycle_revisions (statement_id)""",
    """CREATE TABLE financial_bill_cycle_items (
	id VARCHAR(36) NOT NULL, 
	revision_id VARCHAR(36) NOT NULL, 
	item_id VARCHAR(36) NOT NULL, 
	role VARCHAR(24) NOT NULL, 
	purpose VARCHAR(24) NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_bill_revision_item UNIQUE (revision_id, item_id), 
	CONSTRAINT ck_bill_item_role CHECK (role IN ('PURCHASE','CHARGE','PAYMENT','CREDIT','PREVIOUS_BALANCE','UNKNOWN')), 
	CONSTRAINT ck_bill_item_purpose CHECK (purpose IN ('UNSPECIFIED','BUSINESS','PERSONAL_WITHDRAWAL','STOCK')), 
	FOREIGN KEY(revision_id) REFERENCES financial_bill_cycle_revisions (id), 
	FOREIGN KEY(item_id) REFERENCES financial_statement_items (id)
)""",
    """CREATE INDEX ix_financial_bill_cycle_items_revision_id ON financial_bill_cycle_items (revision_id)""",
    """CREATE TABLE financial_bill_payable_links (
	id VARCHAR(36) NOT NULL, 
	cycle_id VARCHAR(36) NOT NULL, 
	revision_id VARCHAR(36) NOT NULL, 
	payable_id VARCHAR(36) NOT NULL, 
	kind VARCHAR(24) NOT NULL, 
	item_id VARCHAR(36), 
	amount_cents INTEGER NOT NULL, 
	reason TEXT NOT NULL, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_bill_cycle_payable_kind UNIQUE (cycle_id, payable_id, kind), 
	CONSTRAINT ck_bill_link_kind CHECK (kind IN ('PRIMARY','PURCHASE','PREVIOUS_BALANCE','LEGACY')), 
	CONSTRAINT ck_bill_link_amount CHECK (amount_cents > 0), 
	FOREIGN KEY(cycle_id) REFERENCES financial_bill_cycles (id), 
	FOREIGN KEY(revision_id) REFERENCES financial_bill_cycle_revisions (id), 
	FOREIGN KEY(payable_id) REFERENCES accounts_payable (id), 
	FOREIGN KEY(item_id) REFERENCES financial_statement_items (id), 
	FOREIGN KEY(created_by) REFERENCES paired_devices (id)
)""",
    """CREATE INDEX ix_financial_bill_payable_links_cycle_id ON financial_bill_payable_links (cycle_id)""",
    """CREATE UNIQUE INDEX uq_bill_represented_payable ON financial_bill_payable_links (payable_id) WHERE kind != 'PRIMARY'""",
]

CHANGES = [
    """ALTER TABLE accounts_payable ADD COLUMN superseded_by_id VARCHAR(36) REFERENCES accounts_payable(id) CONSTRAINT ck_payable_substituted CHECK ((superseded_by_id IS NULL AND status != 'SUBSTITUTED') OR (superseded_by_id IS NOT NULL AND superseded_by_id != id AND status = 'SUBSTITUTED'))""",
    """ALTER TABLE payable_payments ADD COLUMN bill_revision_id VARCHAR(36) REFERENCES financial_bill_cycle_revisions(id)""",
    """ALTER TABLE payable_payments ADD COLUMN stock_cents INTEGER""",
    """ALTER TABLE payable_payments ADD COLUMN business_cents INTEGER""",
    """ALTER TABLE payable_payments ADD COLUMN personal_cents INTEGER""",
    """ALTER TABLE payable_payments ADD COLUMN unclassified_cents INTEGER CONSTRAINT ck_payment_bill_composition CHECK ((stock_cents IS NULL AND business_cents IS NULL AND personal_cents IS NULL AND unclassified_cents IS NULL AND bill_revision_id IS NULL) OR (bill_revision_id IS NOT NULL AND stock_cents IS NOT NULL AND business_cents IS NOT NULL AND personal_cents IS NOT NULL AND unclassified_cents IS NOT NULL AND stock_cents >= 0 AND business_cents >= 0 AND personal_cents >= 0 AND unclassified_cents >= 0 AND stock_cents + business_cents + personal_cents + unclassified_cents = amount_cents))""",
]

TRIGGERS = [
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_cycles_no_delete BEFORE DELETE ON financial_bill_cycles BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_cycle_revisions_no_update BEFORE UPDATE ON financial_bill_cycle_revisions BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_cycle_revisions_no_delete BEFORE DELETE ON financial_bill_cycle_revisions BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_cycle_items_no_update BEFORE UPDATE ON financial_bill_cycle_items BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_cycle_items_no_delete BEFORE DELETE ON financial_bill_cycle_items BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_payable_links_no_update BEFORE UPDATE ON financial_bill_payable_links BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_payable_links_no_delete BEFORE DELETE ON financial_bill_payable_links BEGIN SELECT RAISE(ABORT, 'bill history is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_insert BEFORE INSERT ON financial_bill_cycles
WHEN (SELECT source_type FROM financial_sources WHERE id=NEW.source_id) != 'CREDIT_CARD' OR NEW.revision != 0 OR NEW.payable_id IS NOT NULL
BEGIN SELECT RAISE(ABORT, 'invalid bill source'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_bill_revision_insert BEFORE INSERT ON financial_bill_cycle_revisions
WHEN NEW.revision != (SELECT revision + 1 FROM financial_bill_cycles WHERE id=NEW.cycle_id)
 OR (SELECT source_id FROM financial_statements WHERE id=NEW.statement_id) != (SELECT source_id FROM financial_bill_cycles WHERE id=NEW.cycle_id)
 OR (SELECT preview_id FROM financial_statements WHERE id=NEW.statement_id) IS NOT NEW.preview_id
 OR (SELECT total_amount_cents FROM financial_statements WHERE id=NEW.statement_id) != NEW.total_cents
 OR (SELECT due_on FROM financial_statements WHERE id=NEW.statement_id) != NEW.due_on
 OR strftime('%Y-%m', NEW.due_on) != (SELECT reference FROM financial_bill_cycles WHERE id=NEW.cycle_id)
BEGIN SELECT RAISE(ABORT, 'invalid bill revision'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_item_insert BEFORE INSERT ON financial_bill_cycle_items
WHEN (SELECT statement_id FROM financial_statement_items WHERE id=NEW.item_id) != (SELECT statement_id FROM financial_bill_cycle_revisions WHERE id=NEW.revision_id)
BEGIN SELECT RAISE(ABORT, 'item belongs to another bill'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_bill_payable_link_insert BEFORE INSERT ON financial_bill_payable_links
WHEN (SELECT cycle_id FROM financial_bill_cycle_revisions WHERE id=NEW.revision_id) != NEW.cycle_id
BEGIN SELECT RAISE(ABORT, 'link belongs to another bill'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_bill_cycle_update BEFORE UPDATE ON financial_bill_cycles
WHEN NEW.id != OLD.id OR NEW.source_id != OLD.source_id OR NEW.reference != OLD.reference
 OR NEW.revision != OLD.revision + 1 OR (OLD.payable_id IS NOT NULL AND NEW.payable_id IS NOT OLD.payable_id)
 OR NOT EXISTS(SELECT 1 FROM financial_bill_cycle_revisions WHERE cycle_id=NEW.id AND revision=NEW.revision)
BEGIN SELECT RAISE(ABORT, 'invalid bill cycle transition'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_revision_insert BEFORE INSERT ON payable_payments
WHEN (NEW.bill_revision_id IS NULL AND EXISTS(SELECT 1 FROM financial_bill_cycles WHERE payable_id=NEW.payable_id))
 OR (NEW.bill_revision_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM financial_bill_cycles c JOIN financial_bill_cycle_revisions r ON r.cycle_id=c.id WHERE c.payable_id=NEW.payable_id AND r.id=NEW.bill_revision_id AND r.revision=c.revision))
BEGIN SELECT RAISE(ABORT, 'invalid payment bill revision'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_no_delete BEFORE DELETE ON payable_payments
WHEN OLD.bill_revision_id IS NOT NULL
BEGIN SELECT RAISE(ABORT, 'payment composition is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_payment_bill_snapshot BEFORE UPDATE ON payable_payments
WHEN NEW.bill_revision_id IS NOT OLD.bill_revision_id OR NEW.stock_cents IS NOT OLD.stock_cents
 OR NEW.business_cents IS NOT OLD.business_cents OR NEW.personal_cents IS NOT OLD.personal_cents
 OR NEW.unclassified_cents IS NOT OLD.unclassified_cents
 OR (OLD.bill_revision_id IS NOT NULL AND (NEW.amount_cents != OLD.amount_cents OR NEW.payable_id != OLD.payable_id OR NEW.account_id != OLD.account_id))
BEGIN SELECT RAISE(ABORT, 'payment composition is immutable'); END""",
    """CREATE TRIGGER IF NOT EXISTS trg_substituted_payable_guard BEFORE UPDATE ON accounts_payable
WHEN OLD.superseded_by_id IS NOT NULL AND (NEW.superseded_by_id IS NOT OLD.superseded_by_id
 OR NEW.status != OLD.status OR NEW.balance_cents != OLD.balance_cents OR NEW.paid_amount_cents != OLD.paid_amount_cents OR NEW.original_amount_cents != OLD.original_amount_cents)
BEGIN SELECT RAISE(ABORT, 'represented payable cannot be reopened'); END""",
]


def upgrade():
    for sql in TABLES + CHANGES + TRIGGERS:
        op.execute(sql)


def downgrade():
    bind = op.get_bind()
    for name in ('financial_bill_cycles', 'financial_bill_cycle_revisions', 'financial_bill_cycle_items', 'financial_bill_payable_links'):
        if bind.execute(sa.text('SELECT COUNT(*) FROM '+name)).scalar():
            raise RuntimeError('preserve history: bill cycles cannot be discarded')
    if bind.execute(sa.text('SELECT COUNT(*) FROM payable_payments WHERE bill_revision_id IS NOT NULL')).scalar():
        raise RuntimeError('preserve history: payment compositions cannot be discarded')
    for sql in TRIGGERS:
        name = sql.split('EXISTS ',1)[1].split()[0]
        op.execute('DROP TRIGGER IF EXISTS '+name)
    for name in ('unclassified_cents','personal_cents','business_cents','stock_cents','bill_revision_id'):
        op.execute('ALTER TABLE payable_payments DROP COLUMN '+name)
    op.execute('ALTER TABLE accounts_payable DROP COLUMN superseded_by_id')
    for name in ('financial_bill_payable_links','financial_bill_cycle_items','financial_bill_cycle_revisions','financial_bill_cycles'):
        op.drop_table(name)
