"""Phase 5: Sales, customers, receivables and payments

Revision ID: f5a6b7c8d905
Revises: e4f5a6b7c804
Create Date: 2026-10-11 18:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'f5a6b7c8d905'
down_revision: Union[str, None] = 'e4f5a6b7c804'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create customers table
    op.create_table(
        'customers',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('document_cpf_cnpj', sa.String(length=20), nullable=True),
        sa.Column('phone', sa.String(length=50), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('credit_limit_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('customers', schema=None) as batch_op:
        batch_op.create_index('ix_customers_name', ['name'], unique=False)
        batch_op.create_index('ix_customers_document_cpf_cnpj', ['document_cpf_cnpj'], unique=False)
        batch_op.create_index('ix_customers_is_active', ['is_active'], unique=False)

    # 2. Update sales table
    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.add_column(sa.Column('customer_id', sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column('sale_mode', sa.String(length=30), nullable=False, server_default='DIRECT_STORE'))
        batch_op.add_column(sa.Column('payment_mode', sa.String(length=30), nullable=False, server_default='CASH_IMMEDIATE'))
        batch_op.add_column(sa.Column('payment_status', sa.String(length=20), nullable=False, server_default='PAID'))
        batch_op.create_foreign_key('fk_sales_customer_id', 'customers', ['customer_id'], ['id'])
        batch_op.create_index('ix_sales_customer_id', ['customer_id'], unique=False)
        batch_op.create_index('ix_sales_status', ['status'], unique=False)
        batch_op.create_index('ix_sales_sale_mode', ['sale_mode'], unique=False)
        batch_op.create_index('ix_sales_payment_mode', ['payment_mode'], unique=False)
        batch_op.create_index('ix_sales_payment_status', ['payment_status'], unique=False)
        batch_op.create_index('ix_sales_sale_date', ['sale_date'], unique=False)

    # 3. Update sale_items table
    with op.batch_alter_table('sale_items', schema=None) as batch_op:
        batch_op.add_column(sa.Column('unit_cost_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('total_cost_cents', sa.Integer(), nullable=False, server_default='0'))
        batch_op.create_index('ix_sale_items_sale_id', ['sale_id'], unique=False)
        batch_op.create_index('ix_sale_items_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_sale_items_production_batch_id', ['production_batch_id'], unique=False)

    # 4. Create sales_receivables table
    op.create_table(
        'sales_receivables',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('sale_id', sa.String(length=36), nullable=False),
        sa.Column('customer_id', sa.String(length=36), nullable=False),
        sa.Column('due_date', sa.DateTime(), nullable=False),
        sa.Column('original_amount_cents', sa.Integer(), nullable=False),
        sa.Column('paid_amount_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('balance_cents', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='OPEN'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ),
        sa.ForeignKeyConstraint(['sale_id'], ['sales.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('sales_receivables', schema=None) as batch_op:
        batch_op.create_index('ix_sales_receivables_sale_id', ['sale_id'], unique=False)
        batch_op.create_index('ix_sales_receivables_customer_id', ['customer_id'], unique=False)
        batch_op.create_index('ix_sales_receivables_due_date', ['due_date'], unique=False)
        batch_op.create_index('ix_sales_receivables_status', ['status'], unique=False)

    # 5. Create receivable_payments table
    op.create_table(
        'receivable_payments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('receivable_id', sa.String(length=36), nullable=False),
        sa.Column('payment_date', sa.DateTime(), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=False, server_default='CASH'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='CONFIRMED'),
        sa.Column('reversal_reason', sa.Text(), nullable=True),
        sa.Column('reversal_of_id', sa.String(length=36), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['receivable_id'], ['sales_receivables.id'], ),
        sa.ForeignKeyConstraint(['reversal_of_id'], ['receivable_payments.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.create_index('ix_receivable_payments_receivable_id', ['receivable_id'], unique=False)
        batch_op.create_index('ix_receivable_payments_payment_date', ['payment_date'], unique=False)
        batch_op.create_index('ix_receivable_payments_status', ['status'], unique=False)


def downgrade() -> None:
    # 5. Drop receivable_payments
    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.drop_index('ix_receivable_payments_status')
        batch_op.drop_index('ix_receivable_payments_payment_date')
        batch_op.drop_index('ix_receivable_payments_receivable_id')
    op.drop_table('receivable_payments')

    # 4. Drop sales_receivables
    with op.batch_alter_table('sales_receivables', schema=None) as batch_op:
        batch_op.drop_index('ix_sales_receivables_status')
        batch_op.drop_index('ix_sales_receivables_due_date')
        batch_op.drop_index('ix_sales_receivables_customer_id')
        batch_op.drop_index('ix_sales_receivables_sale_id')
    op.drop_table('sales_receivables')

    # 3. Drop columns from sale_items
    with op.batch_alter_table('sale_items', schema=None) as batch_op:
        batch_op.drop_index('ix_sale_items_production_batch_id')
        batch_op.drop_index('ix_sale_items_basket_type_id')
        batch_op.drop_index('ix_sale_items_sale_id')
        batch_op.drop_column('total_cost_cents')
        batch_op.drop_column('unit_cost_cents')

    # 2. Drop columns from sales
    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.drop_index('ix_sales_sale_date')
        batch_op.drop_index('ix_sales_payment_status')
        batch_op.drop_index('ix_sales_payment_mode')
        batch_op.drop_index('ix_sales_sale_mode')
        batch_op.drop_index('ix_sales_status')
        batch_op.drop_index('ix_sales_customer_id')
        batch_op.drop_constraint('fk_sales_customer_id', type_='foreignkey')
        batch_op.drop_column('payment_status')
        batch_op.drop_column('payment_mode')
        batch_op.drop_column('sale_mode')
        batch_op.drop_column('customer_id')

    # 1. Drop customers table
    with op.batch_alter_table('customers', schema=None) as batch_op:
        batch_op.drop_index('ix_customers_is_active')
        batch_op.drop_index('ix_customers_document_cpf_cnpj')
        batch_op.drop_index('ix_customers_name')
    op.drop_table('customers')
