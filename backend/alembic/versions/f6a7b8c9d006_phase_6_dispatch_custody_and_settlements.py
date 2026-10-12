"""Phase 6: Stock dispatch, custody, conference and settlements

Revision ID: f6a7b8c9d006
Revises: f5a6b7c8d905
Create Date: 2026-10-12 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'f6a7b8c9d006'
down_revision: Union[str, None] = 'f5a6b7c8d905'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create responsible_persons table
    op.create_table(
        'responsible_persons',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('phone', sa.String(length=50), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('responsible_persons', schema=None) as batch_op:
        batch_op.create_index('ix_responsible_persons_name', ['name'], unique=False)
        batch_op.create_index('ix_responsible_persons_is_active', ['is_active'], unique=False)

    # 2. Create stock_dispatches table
    op.create_table(
        'stock_dispatches',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_number', sa.Integer(), nullable=False),
        sa.Column('responsible_person_id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_date', sa.DateTime(), nullable=False),
        sa.Column('status', sa.String(length=30), nullable=False, server_default='OPEN'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['responsible_person_id'], ['responsible_persons.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('stock_dispatches', schema=None) as batch_op:
        batch_op.create_index('ix_stock_dispatches_dispatch_number', ['dispatch_number'], unique=True)
        batch_op.create_index('ix_stock_dispatches_responsible_person_id', ['responsible_person_id'], unique=False)
        batch_op.create_index('ix_stock_dispatches_dispatch_date', ['dispatch_date'], unique=False)
        batch_op.create_index('ix_stock_dispatches_status', ['status'], unique=False)

    # 3. Create dispatch_items table
    op.create_table(
        'dispatch_items',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('basket_type_id', sa.String(length=36), nullable=False),
        sa.Column('production_batch_id', sa.String(length=36), nullable=True),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('unit_price_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['basket_type_id'], ['basket_types.id']),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.ForeignKeyConstraint(['production_batch_id'], ['production_batches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_items', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_items_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_items_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_dispatch_items_production_batch_id', ['production_batch_id'], unique=False)

    # 4. Create dispatch_returns table
    op.create_table(
        'dispatch_returns',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('basket_type_id', sa.String(length=36), nullable=False),
        sa.Column('production_batch_id', sa.String(length=36), nullable=True),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('returned_at', sa.DateTime(), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['basket_type_id'], ['basket_types.id']),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.ForeignKeyConstraint(['production_batch_id'], ['production_batches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_returns', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_returns_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_returns_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_dispatch_returns_production_batch_id', ['production_batch_id'], unique=False)

    # 5. Create dispatch_losses table
    op.create_table(
        'dispatch_losses',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('basket_type_id', sa.String(length=36), nullable=False),
        sa.Column('production_batch_id', sa.String(length=36), nullable=True),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('occurred_at', sa.DateTime(), nullable=False),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['basket_type_id'], ['basket_types.id']),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.ForeignKeyConstraint(['production_batch_id'], ['production_batches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_losses', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_losses_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_losses_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_dispatch_losses_production_batch_id', ['production_batch_id'], unique=False)

    # 6. Create dispatch_expenses table
    op.create_table(
        'dispatch_expenses',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('expense_date', sa.DateTime(), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('receipt_ref', sa.String(length=100), nullable=True),
        sa.Column('authorized_by', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_expenses', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_expenses_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_expenses_expense_date', ['expense_date'], unique=False)

    # 7. Create dispatch_repayments table
    op.create_table(
        'dispatch_repayments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('repayment_date', sa.DateTime(), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=False, server_default='CASH'),
        sa.Column('received_by', sa.String(length=100), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_repayments', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_repayments_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_repayments_repayment_date', ['repayment_date'], unique=False)

    # 8. Create dispatch_settlements table
    op.create_table(
        'dispatch_settlements',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('dispatch_id', sa.String(length=36), nullable=False),
        sa.Column('audited_by', sa.String(length=100), nullable=False),
        sa.Column('settled_at', sa.DateTime(), nullable=False),
        sa.Column('total_dispatched_qty', sa.Integer(), nullable=False),
        sa.Column('total_sold_qty', sa.Integer(), nullable=False),
        sa.Column('total_returned_qty', sa.Integer(), nullable=False),
        sa.Column('total_lost_qty', sa.Integer(), nullable=False),
        sa.Column('total_remaining_custody_qty', sa.Integer(), nullable=False),
        sa.Column('basket_discrepancy_qty', sa.Integer(), nullable=False),
        sa.Column('expected_cash_cents', sa.Integer(), nullable=False),
        sa.Column('actual_repaid_cash_cents', sa.Integer(), nullable=False),
        sa.Column('cash_discrepancy_cents', sa.Integer(), nullable=False),
        sa.Column('direct_company_received_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('status', sa.String(length=30), nullable=False, server_default='RESOLVED'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('investigation_notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['dispatch_id'], ['stock_dispatches.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('dispatch_settlements', schema=None) as batch_op:
        batch_op.create_index('ix_dispatch_settlements_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_dispatch_settlements_status', ['status'], unique=False)
        batch_op.create_index('ix_dispatch_settlements_settled_at', ['settled_at'], unique=False)

    # 9. Update inventory_movements table (location_type and responsible_person_id)
    with op.batch_alter_table('inventory_movements', schema=None) as batch_op:
        batch_op.add_column(sa.Column('location_type', sa.String(length=20), nullable=False, server_default='STORE'))
        batch_op.add_column(sa.Column('responsible_person_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_inventory_movements_responsible_person', 'responsible_persons', ['responsible_person_id'], ['id'])
        batch_op.create_index('ix_inventory_movements_location_type', ['location_type'], unique=False)
        batch_op.create_index('ix_inventory_movements_responsible_person_id', ['responsible_person_id'], unique=False)

    # 10. Update sales table (dispatch_id and responsible_person_id)
    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.add_column(sa.Column('dispatch_id', sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column('responsible_person_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_sales_dispatch_id', 'stock_dispatches', ['dispatch_id'], ['id'])
        batch_op.create_foreign_key('fk_sales_responsible_person_id', 'responsible_persons', ['responsible_person_id'], ['id'])
        batch_op.create_index('ix_sales_dispatch_id', ['dispatch_id'], unique=False)
        batch_op.create_index('ix_sales_responsible_person_id', ['responsible_person_id'], unique=False)

    # 11. Update receivable_payments table (dispatch_id)
    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.add_column(sa.Column('dispatch_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_receivable_payments_dispatch_id', 'stock_dispatches', ['dispatch_id'], ['id'])
        batch_op.create_index('ix_receivable_payments_dispatch_id', ['dispatch_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.drop_index('ix_receivable_payments_dispatch_id')
        batch_op.drop_constraint('fk_receivable_payments_dispatch_id', type_='foreignkey')
        batch_op.drop_column('dispatch_id')

    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.drop_index('ix_sales_responsible_person_id')
        batch_op.drop_index('ix_sales_dispatch_id')
        batch_op.drop_constraint('fk_sales_responsible_person_id', type_='foreignkey')
        batch_op.drop_constraint('fk_sales_dispatch_id', type_='foreignkey')
        batch_op.drop_column('responsible_person_id')
        batch_op.drop_column('dispatch_id')

    with op.batch_alter_table('inventory_movements', schema=None) as batch_op:
        batch_op.drop_index('ix_inventory_movements_responsible_person_id')
        batch_op.drop_index('ix_inventory_movements_location_type')
        batch_op.drop_constraint('fk_inventory_movements_responsible_person', type_='foreignkey')
        batch_op.drop_column('responsible_person_id')
        batch_op.drop_column('location_type')

    op.drop_table('dispatch_settlements')
    op.drop_table('dispatch_repayments')
    op.drop_table('dispatch_expenses')
    op.drop_table('dispatch_losses')
    op.drop_table('dispatch_returns')
    op.drop_table('dispatch_items')
    op.drop_table('stock_dispatches')
    op.drop_table('responsible_persons')
