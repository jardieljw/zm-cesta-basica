"""Phase 4: Production batches, custom compositions and microcents CMPM

Revision ID: e4f5a6b7c804
Revises: d2e6f7a8b902
Create Date: 2026-10-11 16:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'e4f5a6b7c804'
down_revision: Union[str, None] = 'd2e6f7a8b902'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add cost_price_microcents to products
    with op.batch_alter_table('products', schema=None) as batch_op:
        batch_op.add_column(sa.Column('cost_price_microcents', sa.Integer(), nullable=False, server_default='0'))

    # Backfill cost_price_microcents from cost_price_cents where available
    op.execute("""
        UPDATE products
        SET cost_price_microcents = cost_price_cents * 10000
        WHERE cost_price_cents > 0 AND cost_price_microcents = 0;
    """)

    # 2. Add cost columns, cancellation tracking, and performance indexes to production_batches
    with op.batch_alter_table('production_batches', schema=None) as batch_op:
        batch_op.add_column(sa.Column('unit_cost_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('total_cost_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('canceled_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('cancellation_reason', sa.Text(), nullable=True))
        batch_op.create_index('ix_production_batches_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_production_batches_recipe_version_id', ['recipe_version_id'], unique=False)
        batch_op.create_index('ix_production_batches_status', ['status'], unique=False)
        batch_op.create_index('ix_production_batches_is_custom', ['is_custom'], unique=False)
        batch_op.create_index('ix_production_batches_occurred_at', ['occurred_at'], unique=False)

    # 3. Add cost columns and indexes to production_batch_items
    with op.batch_alter_table('production_batch_items', schema=None) as batch_op:
        batch_op.add_column(sa.Column('unit_cost_microcents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('total_cost_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.create_index('ix_production_batch_items_batch_id', ['batch_id'], unique=False)
        batch_op.create_index('ix_production_batch_items_product_id', ['product_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('production_batch_items', schema=None) as batch_op:
        batch_op.drop_index('ix_production_batch_items_product_id')
        batch_op.drop_index('ix_production_batch_items_batch_id')
        batch_op.drop_column('total_cost_cents')
        batch_op.drop_column('unit_cost_microcents')

    with op.batch_alter_table('production_batches', schema=None) as batch_op:
        batch_op.drop_index('ix_production_batches_occurred_at')
        batch_op.drop_index('ix_production_batches_is_custom')
        batch_op.drop_index('ix_production_batches_status')
        batch_op.drop_index('ix_production_batches_recipe_version_id')
        batch_op.drop_index('ix_production_batches_basket_type_id')
        batch_op.drop_column('cancellation_reason')
        batch_op.drop_column('canceled_at')
        batch_op.drop_column('total_cost_cents')
        batch_op.drop_column('unit_cost_cents')

    with op.batch_alter_table('products', schema=None) as batch_op:
        batch_op.drop_column('cost_price_microcents')
