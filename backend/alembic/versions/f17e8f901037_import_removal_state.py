"""Reversible import withdrawal; no modification of existing financial facts."""
from alembic import op
import sqlalchemy as sa
revision = 'f17e8f901037'
down_revision = 'f06d7e8f0926'
branch_labels = depends_on = None

RESTORED_GUARD = "CREATE TRIGGER IF NOT EXISTS trg_substituted_payable_guard BEFORE UPDATE ON accounts_payable\nWHEN OLD.superseded_by_id IS NOT NULL AND (NEW.superseded_by_id IS NOT OLD.superseded_by_id\n OR NEW.status != OLD.status OR NEW.balance_cents != OLD.balance_cents OR NEW.paid_amount_cents != OLD.paid_amount_cents OR NEW.original_amount_cents != OLD.original_amount_cents)\n AND NOT (NEW.superseded_by_id IS NULL AND NEW.balance_cents = OLD.balance_cents\n AND NEW.paid_amount_cents = OLD.paid_amount_cents AND NEW.original_amount_cents = OLD.original_amount_cents\n AND NEW.status = CASE WHEN OLD.balance_cents=0 THEN 'PAID' WHEN OLD.paid_amount_cents>0 THEN 'PARTIAL' ELSE 'OPEN' END\n AND EXISTS(SELECT 1 FROM financial_import_removals r\n WHERE r.removed=1 AND EXISTS(SELECT 1 FROM json_each(r.effects,'$.represented_payables_to_restore') a WHERE a.value=OLD.id)\n AND EXISTS(SELECT 1 FROM json_each(r.effects,'$.payable_ids') b WHERE b.value=OLD.superseded_by_id)))\nBEGIN SELECT RAISE(ABORT, 'represented payable cannot be reopened'); END"
LEGACY_GUARD = "CREATE TRIGGER IF NOT EXISTS trg_substituted_payable_guard BEFORE UPDATE ON accounts_payable\nWHEN OLD.superseded_by_id IS NOT NULL AND (NEW.superseded_by_id IS NOT OLD.superseded_by_id\n OR NEW.status != OLD.status OR NEW.balance_cents != OLD.balance_cents OR NEW.paid_amount_cents != OLD.paid_amount_cents OR NEW.original_amount_cents != OLD.original_amount_cents)\nBEGIN SELECT RAISE(ABORT, 'represented payable cannot be reopened'); END"

def upgrade():
    op.create_table('financial_import_removals',
        sa.Column('document_id',sa.String(36),sa.ForeignKey('financial_documents.id'),primary_key=True),
        sa.Column('generation',sa.Integer(),nullable=False),
        sa.Column('removed',sa.Boolean(),nullable=False),
        sa.Column('effects',sa.JSON(),nullable=False),
        sa.Column('updated_by',sa.String(36),sa.ForeignKey('paired_devices.id'),nullable=False),
        sa.Column('updated_at',sa.DateTime(),nullable=False),
        sa.CheckConstraint('generation > 0',name='ck_import_removal_generation'))
    op.execute('DROP TRIGGER IF EXISTS trg_substituted_payable_guard')
    op.execute(RESTORED_GUARD)

def downgrade():
    bind=op.get_bind()
    if bind.scalar(sa.text('SELECT COUNT(*) FROM financial_import_removals')):
        raise RuntimeError('Cannot discard recorded import withdrawals')
    op.execute('DROP TRIGGER IF EXISTS trg_substituted_payable_guard')
    op.execute(LEGACY_GUARD)
    op.drop_table('financial_import_removals')
