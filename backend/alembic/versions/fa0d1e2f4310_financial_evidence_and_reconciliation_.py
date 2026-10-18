"""financial evidence and reconciliation foundation

Revision ID: fa0d1e2f4310
Revises: f9c0d1e2f309
Create Date: 2026-10-15 21:30:25.667092

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fa0d1e2f4310'
down_revision: Union[str, None] = 'f9c0d1e2f309'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Additive only: existing financial/stock tables and indexes are preserved.
    op.create_table('financial_documents',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('sha256', sa.String(length=64), nullable=False),
    sa.Column('filename', sa.String(length=200), nullable=False),
    sa.Column('media_type', sa.String(length=80), nullable=False),
    sa.Column('size_bytes', sa.Integer(), nullable=False),
    sa.Column('content', sa.LargeBinary(), nullable=False),
    sa.Column('created_by', sa.String(length=36), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.CheckConstraint('length(content) = size_bytes', name='ck_fin_document_content'),
    sa.CheckConstraint('length(sha256) = 64', name='ck_fin_document_hash'),
    sa.CheckConstraint('size_bytes > 0 AND size_bytes <= 10485760', name='ck_fin_document_size'),
    sa.ForeignKeyConstraint(['created_by'], ['paired_devices.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('sha256')
    )
    op.create_table('financial_import_audit',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('event_type', sa.String(length=40), nullable=False),
    sa.Column('entity_type', sa.String(length=30), nullable=False),
    sa.Column('entity_id', sa.String(length=36), nullable=False),
    sa.Column('actor_id', sa.String(length=36), nullable=False),
    sa.Column('details', sa.JSON(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.ForeignKeyConstraint(['actor_id'], ['paired_devices.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('financial_import_audit', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_import_audit_entity_id'), ['entity_id'], unique=False)

    op.create_table('financial_sources',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('source_type', sa.String(length=20), nullable=False),
    sa.Column('financial_account_id', sa.String(length=36), nullable=True),
    sa.Column('name', sa.String(length=100), nullable=False),
    sa.Column('institution', sa.String(length=100), nullable=False),
    sa.Column('holder_type', sa.String(length=2), nullable=False),
    sa.Column('holder_name', sa.String(length=200), nullable=True),
    sa.Column('holder_document', sa.String(length=30), nullable=True),
    sa.Column('branch', sa.String(length=30), nullable=True),
    sa.Column('currency', sa.String(length=3), nullable=False),
    sa.Column('created_by', sa.String(length=36), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.CheckConstraint("(source_type = 'BANK_ACCOUNT' AND financial_account_id IS NOT NULL) OR (source_type = 'CREDIT_CARD' AND financial_account_id IS NULL)", name='ck_fin_source_account'),
    sa.CheckConstraint("holder_type IN ('PF','PJ')", name='ck_fin_source_holder'),
    sa.CheckConstraint("source_type IN ('BANK_ACCOUNT','CREDIT_CARD')", name='ck_fin_source_type'),
    sa.CheckConstraint('length(currency) = 3', name='ck_fin_source_currency'),
    sa.ForeignKeyConstraint(['created_by'], ['paired_devices.id'], ),
    sa.ForeignKeyConstraint(['financial_account_id'], ['financial_accounts.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('financial_account_id')
    )
    op.create_table('financial_statements',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('document_id', sa.String(length=36), nullable=False),
    sa.Column('source_id', sa.String(length=36), nullable=False),
    sa.Column('statement_type', sa.String(length=24), nullable=False),
    sa.Column('payload_sha256', sa.String(length=64), nullable=False),
    sa.Column('period_start', sa.Date(), nullable=True),
    sa.Column('period_end', sa.Date(), nullable=True),
    sa.Column('issued_on', sa.Date(), nullable=True),
    sa.Column('closing_on', sa.Date(), nullable=True),
    sa.Column('due_on', sa.Date(), nullable=True),
    sa.Column('opening_balance_cents', sa.Integer(), nullable=True),
    sa.Column('closing_balance_cents', sa.Integer(), nullable=True),
    sa.Column('total_inflows_cents', sa.Integer(), nullable=True),
    sa.Column('total_outflows_cents', sa.Integer(), nullable=True),
    sa.Column('total_amount_cents', sa.Integer(), nullable=True),
    sa.Column('minimum_payment_cents', sa.Integer(), nullable=True),
    sa.Column('created_by', sa.String(length=36), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.CheckConstraint("statement_type IN ('BANK_STATEMENT','CARD_BILL','TRANSACTION_RECEIPT')", name='ck_fin_statement_type'),
    sa.CheckConstraint('period_start IS NULL OR period_end IS NULL OR period_end >= period_start', name='ck_fin_statement_period'),
    sa.ForeignKeyConstraint(['created_by'], ['paired_devices.id'], ),
    sa.ForeignKeyConstraint(['document_id'], ['financial_documents.id'], ),
    sa.ForeignKeyConstraint(['source_id'], ['financial_sources.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('document_id', 'source_id', 'payload_sha256', name='uq_fin_statement_payload')
    )
    with op.batch_alter_table('financial_statements', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_statements_document_id'), ['document_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_financial_statements_source_id'), ['source_id'], unique=False)

    op.create_table('financial_transactions',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('source_id', sa.String(length=36), nullable=False),
    sa.Column('external_id_namespace', sa.String(length=50), nullable=True),
    sa.Column('external_id', sa.String(length=200), nullable=True),
    sa.Column('transaction_date', sa.Date(), nullable=False),
    sa.Column('transaction_time', sa.Time(), nullable=True),
    sa.Column('time_precision', sa.String(length=6), nullable=True),
    sa.Column('utc_offset_minutes', sa.Integer(), nullable=True),
    sa.Column('date_kind', sa.String(length=20), nullable=False),
    sa.Column('amount_cents', sa.Integer(), nullable=False),
    sa.Column('description', sa.Text(), nullable=False),
    sa.Column('transaction_kind', sa.String(length=24), nullable=False),
    sa.Column('counterparty_name', sa.String(length=200), nullable=True),
    sa.Column('counterparty_document', sa.String(length=30), nullable=True),
    sa.Column('counterparty_institution', sa.String(length=100), nullable=True),
    sa.Column('counterparty_branch', sa.String(length=30), nullable=True),
    sa.Column('counterparty_account', sa.String(length=60), nullable=True),
    sa.Column('card_last_four', sa.String(length=4), nullable=True),
    sa.Column('installment_number', sa.Integer(), nullable=True),
    sa.Column('total_installments', sa.Integer(), nullable=True),
    sa.Column('created_by', sa.String(length=36), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.CheckConstraint("(transaction_time IS NULL AND time_precision IS NULL) OR (transaction_time IS NOT NULL AND time_precision IS NOT NULL AND time_precision IN ('MINUTE','SECOND'))", name='ck_fin_transaction_time'),
    sa.CheckConstraint('(external_id IS NULL AND external_id_namespace IS NULL) OR (external_id IS NOT NULL AND external_id_namespace IS NOT NULL)', name='ck_fin_transaction_external'),
    sa.CheckConstraint('(installment_number IS NULL AND total_installments IS NULL) OR (installment_number IS NOT NULL AND total_installments IS NOT NULL AND installment_number >= 1 AND total_installments >= installment_number)', name='ck_fin_transaction_installments'),
    sa.CheckConstraint('amount_cents != 0 AND amount_cents BETWEEN -9000000000000000 AND 9000000000000000', name='ck_fin_transaction_amount'),
    sa.CheckConstraint('utc_offset_minutes IS NULL OR (transaction_time IS NOT NULL AND utc_offset_minutes BETWEEN -840 AND 840)', name='ck_fin_transaction_offset'),
    sa.ForeignKeyConstraint(['created_by'], ['paired_devices.id'], ),
    sa.ForeignKeyConstraint(['source_id'], ['financial_sources.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('id', 'source_id', name='uq_fin_transaction_source'),
    sa.UniqueConstraint('source_id', 'external_id_namespace', 'external_id', name='uq_fin_transaction_external')
    )
    with op.batch_alter_table('financial_transactions', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_transactions_source_id'), ['source_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_financial_transactions_transaction_date'), ['transaction_date'], unique=False)

    op.create_table('financial_reconciliations',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('transaction_id', sa.String(length=36), nullable=False),
    sa.Column('cash_flow_entry_id', sa.String(length=36), nullable=False),
    sa.Column('amount_cents', sa.Integer(), nullable=False),
    sa.Column('reason', sa.Text(), nullable=False),
    sa.Column('created_by', sa.String(length=36), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.Column('voided_by', sa.String(length=36), nullable=True),
    sa.Column('voided_at', sa.DateTime(), nullable=True),
    sa.Column('void_reason', sa.Text(), nullable=True),
    sa.CheckConstraint('(voided_at IS NULL AND voided_by IS NULL AND void_reason IS NULL) OR (voided_at IS NOT NULL AND voided_by IS NOT NULL AND void_reason IS NOT NULL)', name='ck_fin_reconciliation_void'),
    sa.CheckConstraint('amount_cents > 0 AND amount_cents <= 9000000000000000', name='ck_fin_reconciliation_amount'),
    sa.ForeignKeyConstraint(['cash_flow_entry_id'], ['cash_flow_entries.id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['paired_devices.id'], ),
    sa.ForeignKeyConstraint(['transaction_id'], ['financial_transactions.id'], ),
    sa.ForeignKeyConstraint(['voided_by'], ['paired_devices.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('financial_reconciliations', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_reconciliations_cash_flow_entry_id'), ['cash_flow_entry_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_financial_reconciliations_transaction_id'), ['transaction_id'], unique=False)
        batch_op.create_index('uq_fin_reconciliation_active', ['transaction_id', 'cash_flow_entry_id'], unique=True, sqlite_where=sa.text('voided_at IS NULL'))

    op.create_table('financial_statement_items',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('statement_id', sa.String(length=36), nullable=False),
    sa.Column('position', sa.Integer(), nullable=False),
    sa.Column('page_number', sa.Integer(), nullable=True),
    sa.Column('raw_text', sa.Text(), nullable=True),
    sa.Column('normalized_data', sa.JSON(), nullable=False),
    sa.Column('review_status', sa.String(length=12), nullable=False),
    sa.Column('transaction_id', sa.String(length=36), nullable=True),
    sa.Column('reviewed_by', sa.String(length=36), nullable=True),
    sa.Column('reviewed_at', sa.DateTime(), nullable=True),
    sa.CheckConstraint("(review_status = 'PENDING' AND transaction_id IS NULL AND reviewed_by IS NULL AND reviewed_at IS NULL) OR (review_status = 'IGNORED' AND transaction_id IS NULL AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL) OR (review_status IN ('NEW','LINKED') AND transaction_id IS NOT NULL AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)", name='ck_fin_item_review'),
    sa.CheckConstraint("review_status IN ('PENDING','NEW','LINKED','IGNORED')", name='ck_fin_item_status'),
    sa.CheckConstraint('page_number IS NULL OR page_number > 0', name='ck_fin_item_page'),
    sa.CheckConstraint('position > 0', name='ck_fin_item_position'),
    sa.ForeignKeyConstraint(['reviewed_by'], ['paired_devices.id'], ),
    sa.ForeignKeyConstraint(['statement_id'], ['financial_statements.id'], ),
    sa.ForeignKeyConstraint(['transaction_id'], ['financial_transactions.id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('statement_id', 'position', name='uq_fin_statement_item_position')
    )
    with op.batch_alter_table('financial_statement_items', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_statement_items_review_status'), ['review_status'], unique=False)
        batch_op.create_index(batch_op.f('ix_financial_statement_items_statement_id'), ['statement_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_financial_statement_items_transaction_id'), ['transaction_id'], unique=False)

    op.create_table('financial_transaction_identities',
    sa.Column('id', sa.String(length=36), nullable=False),
    sa.Column('transaction_id', sa.String(length=36), nullable=False),
    sa.Column('source_id', sa.String(length=36), nullable=False),
    sa.Column('namespace', sa.String(length=50), nullable=False),
    sa.Column('external_id', sa.String(length=200), nullable=False),
    sa.ForeignKeyConstraint(['source_id'], ['financial_sources.id'], ),
    sa.ForeignKeyConstraint(['transaction_id', 'source_id'], ['financial_transactions.id', 'financial_transactions.source_id'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('source_id', 'namespace', 'external_id', name='uq_fin_external_identity')
    )
    with op.batch_alter_table('financial_transaction_identities', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_financial_transaction_identities_transaction_id'), ['transaction_id'], unique=False)

    _create_protection_triggers()


def downgrade() -> None:
    # A downgrade may not silently destroy financial evidence already received.
    tables = ('financial_sources', 'financial_documents', 'financial_statements',
              'financial_statement_items', 'financial_transactions',
              'financial_transaction_identities', 'financial_reconciliations', 'financial_import_audit')
    connection = op.get_bind()
    for table in tables:
        if connection.execute(sa.text(f'SELECT 1 FROM {table} LIMIT 1')).first():
            raise RuntimeError('Financial evidence exists; downgrade refused to preserve history. Use a verified recovery plan.')

    with op.batch_alter_table('financial_transaction_identities', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_financial_transaction_identities_transaction_id'))

    op.drop_table('financial_transaction_identities')
    with op.batch_alter_table('financial_statement_items', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_financial_statement_items_transaction_id'))
        batch_op.drop_index(batch_op.f('ix_financial_statement_items_statement_id'))
        batch_op.drop_index(batch_op.f('ix_financial_statement_items_review_status'))

    op.drop_table('financial_statement_items')
    with op.batch_alter_table('financial_reconciliations', schema=None) as batch_op:
        batch_op.drop_index('uq_fin_reconciliation_active', sqlite_where=sa.text('voided_at IS NULL'))
        batch_op.drop_index(batch_op.f('ix_financial_reconciliations_transaction_id'))
        batch_op.drop_index(batch_op.f('ix_financial_reconciliations_cash_flow_entry_id'))

    op.drop_table('financial_reconciliations')
    with op.batch_alter_table('financial_transactions', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_financial_transactions_transaction_date'))
        batch_op.drop_index(batch_op.f('ix_financial_transactions_source_id'))

    op.drop_table('financial_transactions')
    with op.batch_alter_table('financial_statements', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_financial_statements_source_id'))
        batch_op.drop_index(batch_op.f('ix_financial_statements_document_id'))

    op.drop_table('financial_statements')
    op.drop_table('financial_sources')
    with op.batch_alter_table('financial_import_audit', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_financial_import_audit_entity_id'))

    op.drop_table('financial_import_audit')
    op.drop_table('financial_documents')


def _create_protection_triggers():
    # Frozen migration definitions, independent of future application models.
    for table in ('financial_documents', 'financial_statements', 'financial_transactions',
                  'financial_transaction_identities', 'financial_import_audit'):
        for operation in ('UPDATE', 'DELETE'):
            op.execute(f"CREATE TRIGGER IF NOT EXISTS trg_{table}_no_{operation.lower()} "
                       f"BEFORE {operation} ON {table} BEGIN "
                       "SELECT RAISE(ABORT, 'financial evidence is immutable'); END;")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_sources_identity BEFORE UPDATE ON financial_sources
WHEN NEW.id != OLD.id OR NEW.source_type != OLD.source_type
 OR NEW.financial_account_id IS NOT OLD.financial_account_id OR NEW.currency != OLD.currency
BEGIN SELECT RAISE(ABORT, 'source identity cannot be changed'); END;
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_sources_no_delete BEFORE DELETE ON financial_sources
BEGIN SELECT RAISE(ABORT, 'financial source cannot be deleted'); END;
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_items_review_only BEFORE UPDATE ON financial_statement_items
WHEN OLD.review_status != 'PENDING' OR NEW.id != OLD.id OR NEW.statement_id != OLD.statement_id
 OR NEW.position != OLD.position OR NEW.page_number IS NOT OLD.page_number
 OR NEW.raw_text IS NOT OLD.raw_text OR NEW.normalized_data != OLD.normalized_data
BEGIN SELECT RAISE(ABORT, 'original financial item cannot be changed'); END;
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_items_no_delete BEFORE DELETE ON financial_statement_items
BEGIN SELECT RAISE(ABORT, 'financial evidence cannot be deleted'); END;
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_reconciliations_void_only BEFORE UPDATE ON financial_reconciliations
WHEN OLD.voided_at IS NOT NULL OR NEW.id != OLD.id OR NEW.transaction_id != OLD.transaction_id
 OR NEW.cash_flow_entry_id != OLD.cash_flow_entry_id OR NEW.amount_cents != OLD.amount_cents
 OR NEW.reason != OLD.reason OR NEW.created_by != OLD.created_by OR NEW.created_at != OLD.created_at
 OR NEW.voided_at IS NULL
BEGIN SELECT RAISE(ABORT, 'reconciliation can only be voided'); END;
""")
    op.execute("""
CREATE TRIGGER IF NOT EXISTS trg_financial_reconciliations_no_delete BEFORE DELETE ON financial_reconciliations
BEGIN SELECT RAISE(ABORT, 'reconciliation cannot be deleted'); END;
""")
