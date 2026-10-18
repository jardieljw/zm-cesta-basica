"""Complete the purchase payment method column on migrated databases.

Revision ID: f8b9c0d1e208
Revises: f7a8b9c0d107
"""
from alembic import op
import sqlalchemy as sa

revision = 'f8b9c0d1e208'
down_revision = 'f7a8b9c0d107'
branch_labels = None
depends_on = None


def upgrade():
    columns = {column['name'] for column in sa.inspect(op.get_bind()).get_columns('purchases')}
    if 'payment_method' not in columns:
        op.add_column('purchases', sa.Column('payment_method', sa.String(50),
            nullable=False, server_default='DINHEIRO'))


def downgrade():
    columns = {column['name'] for column in sa.inspect(op.get_bind()).get_columns('purchases')}
    if 'payment_method' in columns:
        op.drop_column('purchases', 'payment_method')
