"""audited bill semantic review and obligations

Revision ID: fe4b5c6d8714
Revises: fd3a4b5c7613
Create Date: 2026-10-17 21:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fe4b5c6d8714'
down_revision: Union[str, None] = 'fd3a4b5c7613'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'financial_bill_semantic_reviews',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('statement_id', sa.String(36), sa.ForeignKey('financial_statements.id'), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('declared_total_cents', sa.Integer(), nullable=False),
        sa.Column('previous_balance_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('purchases_business_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('purchases_personal_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('financial_charges_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('payments_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('refunds_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('equation_difference_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_balanced', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column('status', sa.String(20), nullable=False, server_default='DRAFT'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('statement_id', 'revision', name='uq_fin_bill_semantic_revision'),
        sa.CheckConstraint('revision > 0', name='ck_fin_bill_semantic_revision'),
        sa.CheckConstraint("status IN ('DRAFT','APPROVED')", name='ck_fin_bill_semantic_status'),
    )
    op.create_index('ix_financial_bill_semantic_reviews_statement_id', 'financial_bill_semantic_reviews', ['statement_id'])

    op.create_table(
        'financial_bill_semantic_items',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('review_id', sa.String(36), sa.ForeignKey('financial_bill_semantic_reviews.id'), nullable=False),
        sa.Column('item_id', sa.String(36), sa.ForeignKey('financial_statement_items.id'), nullable=False),
        sa.Column('semantic_category', sa.String(30), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('purchase_id', sa.String(36), sa.ForeignKey('purchases.id'), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.UniqueConstraint('review_id', 'item_id', name='uq_fin_bill_semantic_item'),
        sa.CheckConstraint(
            "semantic_category IN ('PURCHASE_BUSINESS','PURCHASE_PERSONAL','BILL_PAYMENT','PREVIOUS_BALANCE','FINANCIAL_CHARGES','REFUND_CREDIT','CONTEXT_ONLY')",
            name='ck_fin_bill_item_semantic_cat',
        ),
    )
    op.create_index('ix_financial_bill_semantic_items_review_id', 'financial_bill_semantic_items', ['review_id'])
    op.create_index('ix_financial_bill_semantic_items_item_id', 'financial_bill_semantic_items', ['item_id'])
    op.create_index('ix_financial_bill_semantic_items_purchase_id', 'financial_bill_semantic_items', ['purchase_id'])

    op.create_table(
        'financial_bill_obligations',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('statement_id', sa.String(36), sa.ForeignKey('financial_statements.id'), nullable=False),
        sa.Column('review_id', sa.String(36), sa.ForeignKey('financial_bill_semantic_reviews.id'), nullable=False),
        sa.Column('account_payable_id', sa.String(36), sa.ForeignKey('accounts_payable.id'), nullable=False),
        sa.Column('component_type', sa.String(30), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('purchase_id', sa.String(36), sa.ForeignKey('purchases.id'), nullable=True),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('statement_id', 'account_payable_id', name='uq_fin_bill_obligation_payable'),
    )
    op.create_index('ix_financial_bill_obligations_statement_id', 'financial_bill_obligations', ['statement_id'])
    op.create_index('ix_financial_bill_obligations_review_id', 'financial_bill_obligations', ['review_id'])
    op.create_index('ix_financial_bill_obligations_account_payable_id', 'financial_bill_obligations', ['account_payable_id'])
    op.create_index('ix_financial_bill_obligations_purchase_id', 'financial_bill_obligations', ['purchase_id'])

    for table in ('financial_bill_semantic_reviews', 'financial_bill_semantic_items', 'financial_bill_obligations'):
        for operation in ('UPDATE', 'DELETE'):
            op.execute(
                f"CREATE TRIGGER IF NOT EXISTS trg_{table}_no_{operation.lower()} BEFORE {operation} ON {table} "
                "BEGIN SELECT RAISE(ABORT, 'financial evidence is immutable'); END;"
            )

    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_fin_bill_semantic_rev_insert BEFORE INSERT ON financial_bill_semantic_reviews
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_bill_semantic_reviews WHERE statement_id = NEW.statement_id), 0) + 1
 OR (SELECT statement_type FROM financial_statements WHERE id = NEW.statement_id) != 'CARD_BILL'
BEGIN SELECT RAISE(ABORT, 'invalid financial bill semantic review'); END;""")

    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_fin_bill_semantic_item_insert BEFORE INSERT ON financial_bill_semantic_items
WHEN (SELECT statement_id FROM financial_statement_items WHERE id = NEW.item_id) != (SELECT statement_id FROM financial_bill_semantic_reviews WHERE id = NEW.review_id)
BEGIN SELECT RAISE(ABORT, 'semantic item must belong to the same statement as review'); END;""")

    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_fin_bill_obligation_insert BEFORE INSERT ON financial_bill_obligations
WHEN (SELECT is_balanced FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != 1
  OR (SELECT status FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != 'APPROVED'
  OR (SELECT statement_id FROM financial_bill_semantic_reviews WHERE id = NEW.review_id) != NEW.statement_id
BEGIN SELECT RAISE(ABORT, 'obligations require an approved and balanced bill review'); END;""")


def downgrade() -> None:
    for table in ('financial_bill_obligations', 'financial_bill_semantic_items', 'financial_bill_semantic_reviews'):
        if op.get_bind().execute(sa.text(f'SELECT 1 FROM {table} LIMIT 1')).first():
            raise RuntimeError('Cannot downgrade populated bill semantics; preserve history and restore a verified backup instead.')
    for table in ('financial_bill_obligations', 'financial_bill_semantic_items', 'financial_bill_semantic_reviews'):
        op.drop_table(table)
