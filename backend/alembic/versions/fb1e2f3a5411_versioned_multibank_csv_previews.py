"""versioned multibank CSV previews

Revision ID: fb1e2f3a5411
Revises: fa0d1e2f4310
Create Date: 2026-10-15 22:23:46.882021

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fb1e2f3a5411'
down_revision: Union[str, None] = 'fa0d1e2f4310'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Additive SQLite DDL only. Referenced immutable tables are never rebuilt,
    # renamed or copied, and foreign key enforcement is never disabled.
    op.create_table(
        'financial_import_previews',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('document_id', sa.String(36), sa.ForeignKey('financial_documents.id'), nullable=False),
        sa.Column('source_id', sa.String(36), sa.ForeignKey('financial_sources.id'), nullable=False),
        sa.Column('reader_id', sa.String(50), nullable=False),
        sa.Column('reader_version', sa.String(20), nullable=False),
        sa.Column('options', sa.JSON(), nullable=False),
        sa.Column('request_sha256', sa.String(64), nullable=False),
        sa.Column('result_sha256', sa.String(64), nullable=False),
        sa.Column('status', sa.String(10), nullable=False),
        sa.Column('result', sa.JSON(), nullable=False),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('document_id', 'source_id', 'request_sha256', name='uq_fin_preview_request'),
        sa.CheckConstraint("status IN ('READY','INVALID')", name='ck_fin_preview_status'),
    )
    # SQLite supports a nullable REFERENCES column natively. Alembic's generic
    # add_column(ForeignKey) would try an unsupported ALTER ADD CONSTRAINT.
    op.execute('ALTER TABLE financial_statements ADD COLUMN preview_id VARCHAR(36) REFERENCES financial_import_previews(id)')
    op.create_index('ix_financial_statements_preview_id', 'financial_statements', ['preview_id'])
    op.add_column('financial_transactions', sa.Column('purchase_date', sa.Date(), nullable=True))
    op.add_column('financial_transactions', sa.Column('booking_date', sa.Date(), nullable=True))
    for operation in ('UPDATE', 'DELETE'):
        op.execute(f'CREATE TRIGGER IF NOT EXISTS trg_financial_import_previews_no_{operation.lower()} '
                   f'BEFORE {operation} ON financial_import_previews BEGIN '
                   "SELECT RAISE(ABORT, 'financial evidence is immutable'); END;")
    # SQLite's historic VARCHAR(200) declarations do not restrict string length.
    # Full 255-character identities already fit without destructive table DDL.


def downgrade() -> None:
    tables = ('financial_import_previews', 'financial_statement_items', 'financial_statements',
              'financial_transaction_identities', 'financial_transactions', 'financial_reconciliations',
              'financial_import_audit', 'financial_documents', 'financial_sources')
    if any(op.get_bind().execute(sa.text(f'SELECT 1 FROM {table} LIMIT 1')).first() for table in tables):
        raise RuntimeError('Cannot downgrade populated financial evidence; preserve history and restore a verified backup instead.')
    op.drop_index('ix_financial_statements_preview_id', table_name='financial_statements')
    # Native DROP COLUMN (SQLite >= 3.35) preserves every other column/trigger.
    op.execute('ALTER TABLE financial_statements DROP COLUMN preview_id')
    op.execute('ALTER TABLE financial_transactions DROP COLUMN booking_date')
    op.execute('ALTER TABLE financial_transactions DROP COLUMN purchase_date')
    op.drop_table('financial_import_previews')
