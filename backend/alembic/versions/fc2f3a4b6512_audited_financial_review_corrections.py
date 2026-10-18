"""audited financial review corrections

Revision ID: fc2f3a4b6512
Revises: fb1e2f3a5411
Create Date: 2026-10-15 22:52:14.833891

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fc2f3a4b6512'
down_revision: Union[str, None] = 'fb1e2f3a5411'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Additive only: no original decision, alias or cash row is rewritten.
    op.create_table('financial_review_corrections',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('item_id', sa.String(36), sa.ForeignKey('financial_statement_items.id'), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('review_status', sa.String(12), nullable=False),
        sa.Column('transaction_id', sa.String(36), sa.ForeignKey('financial_transactions.id')),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('item_id', 'revision', name='uq_fin_review_revision'),
        sa.CheckConstraint('revision > 0', name='ck_fin_review_revision'),
        sa.CheckConstraint("(review_status = 'IGNORED' AND transaction_id IS NULL) OR "
                           "(review_status IN ('NEW','LINKED') AND transaction_id IS NOT NULL)", name='ck_fin_correction_review'),
    )
    op.create_index('ix_financial_review_corrections_transaction_id', 'financial_review_corrections', ['transaction_id'])
    op.create_table('financial_identity_changes',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('source_id', sa.String(36), sa.ForeignKey('financial_sources.id'), nullable=False),
        sa.Column('namespace', sa.String(50), nullable=False),
        sa.Column('external_id', sa.String(255), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('previous_transaction_id', sa.String(36)),
        sa.Column('transaction_id', sa.String(36)),
        sa.Column('correction_id', sa.String(36), sa.ForeignKey('financial_review_corrections.id')),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['transaction_id', 'source_id'], ['financial_transactions.id', 'financial_transactions.source_id']),
        sa.ForeignKeyConstraint(['previous_transaction_id', 'source_id'], ['financial_transactions.id', 'financial_transactions.source_id']),
        sa.UniqueConstraint('source_id', 'namespace', 'external_id', 'revision', name='uq_fin_identity_revision'),
        sa.CheckConstraint('revision > 0', name='ck_fin_identity_revision'),
        sa.CheckConstraint('transaction_id IS NOT previous_transaction_id', name='ck_fin_identity_change'),
    )
    for table in ('financial_review_corrections', 'financial_identity_changes'):
        for operation in ('UPDATE', 'DELETE'):
            op.execute(f'CREATE TRIGGER IF NOT EXISTS trg_{table}_no_{operation.lower()} '
                       f'BEFORE {operation} ON {table} BEGIN '
                       "SELECT RAISE(ABORT, 'financial evidence is immutable'); END;")
    op.execute("""
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
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_identity_change_insert BEFORE INSERT ON financial_identity_changes
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_identity_changes
     WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id), 0) + 1
 OR NEW.previous_transaction_id IS NOT CASE
     WHEN EXISTS (SELECT 1 FROM financial_identity_changes WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id)
     THEN (SELECT transaction_id FROM financial_identity_changes WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id ORDER BY revision DESC LIMIT 1)
     ELSE (SELECT transaction_id FROM financial_transaction_identities WHERE source_id = NEW.source_id AND namespace = NEW.namespace AND external_id = NEW.external_id)
     END
BEGIN SELECT RAISE(ABORT, 'invalid financial identity change'); END;
""")


def downgrade() -> None:
    for table in ('financial_identity_changes', 'financial_review_corrections'):
        if op.get_bind().execute(sa.text(f'SELECT 1 FROM {table} LIMIT 1')).first():
            raise RuntimeError('Cannot downgrade populated financial corrections; preserve history and restore a verified backup instead.')
    op.drop_table('financial_identity_changes')
    op.drop_index('ix_financial_review_corrections_transaction_id', table_name='financial_review_corrections')
    op.drop_table('financial_review_corrections')
