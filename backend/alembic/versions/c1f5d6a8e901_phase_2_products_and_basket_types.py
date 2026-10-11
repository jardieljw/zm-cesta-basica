"""Phase 2: Product barcodes, prices, basket type categories and customization

Revision ID: c1f5d6a8e901
Revises: 06d734cf2223
Create Date: 2026-10-11 00:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c1f5d6a8e901'
down_revision: Union[str, None] = '06d734cf2223'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('products', schema=None) as batch_op:
        batch_op.add_column(sa.Column('barcode', sa.String(length=50), nullable=True))
        batch_op.add_column(sa.Column('cost_price_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('sale_price_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.create_unique_constraint('uq_products_barcode', ['barcode'])

    with op.batch_alter_table('basket_types', schema=None) as batch_op:
        batch_op.add_column(sa.Column('category', sa.String(length=50), nullable=False, server_default='PADRAO'))
        batch_op.add_column(sa.Column('default_price_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('allows_customization', sa.Boolean(), nullable=False, server_default='0'))


def downgrade() -> None:
    with op.batch_alter_table('basket_types', schema=None) as batch_op:
        batch_op.drop_column('allows_customization')
        batch_op.drop_column('default_price_cents')
        batch_op.drop_column('category')

    with op.batch_alter_table('products', schema=None) as batch_op:
        batch_op.drop_constraint('uq_products_barcode', type_='unique')
        batch_op.drop_column('sale_price_cents')
        batch_op.drop_column('cost_price_cents')
        batch_op.drop_column('barcode')
