"""Phase 7: Treasury, payables, receivables and financial management

Revision ID: f7a8b9c0d107
Revises: f6a7b8c9d006
Create Date: 2026-10-12 01:00:00.000000

"""
from typing import Sequence, Union
import datetime
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'f7a8b9c0d107'
down_revision: Union[str, None] = 'f6a7b8c9d006'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create financial_accounts table
    op.create_table(
        'financial_accounts',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('account_type', sa.String(length=30), nullable=False),
        sa.Column('bank_name', sa.String(length=100), nullable=True),
        sa.Column('account_number', sa.String(length=50), nullable=True),
        sa.Column('initial_balance_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('current_balance_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column('is_default', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('financial_accounts', schema=None) as batch_op:
        batch_op.create_index('ix_financial_accounts_name', ['name'], unique=False)
        batch_op.create_index('ix_financial_accounts_account_type', ['account_type'], unique=False)
        batch_op.create_index('ix_financial_accounts_is_active', ['is_active'], unique=False)
        batch_op.create_index('ix_financial_accounts_is_default', ['is_default'], unique=False)

    # Seed default "Caixa Físico da Loja" account
    op.execute(
        sa.text(
            "INSERT INTO financial_accounts (id, name, account_type, initial_balance_cents, current_balance_cents, is_active, is_default, notes, created_at, updated_at) "
            "VALUES ('00000000-0000-0000-0000-caixa0000001', 'Caixa Físico da Loja', 'CASH', 0, 0, 1, 1, 'Caixa físico padrão do armazém da loja', "
            "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )
    )

    # 2. Create cash_flow_entries table
    op.create_table(
        'cash_flow_entries',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('account_id', sa.String(length=36), nullable=False),
        sa.Column('entry_type', sa.String(length=20), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('nature', sa.String(length=30), nullable=False, server_default='BUSINESS'),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('source_type', sa.String(length=30), nullable=False),
        sa.Column('source_id', sa.String(length=36), nullable=True),
        sa.Column('payment_method', sa.String(length=50), nullable=False, server_default='CASH'),
        sa.Column('occurred_at', sa.DateTime(), nullable=False),
        sa.Column('reversal_of_id', sa.String(length=36), nullable=True),
        sa.Column('is_reversal', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['account_id'], ['financial_accounts.id']),
        sa.ForeignKeyConstraint(['reversal_of_id'], ['cash_flow_entries.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('cash_flow_entries', schema=None) as batch_op:
        batch_op.create_index('ix_cash_flow_entries_account_id', ['account_id'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_entry_type', ['entry_type'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_category', ['category'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_nature', ['nature'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_source_type', ['source_type'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_source_id', ['source_id'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_occurred_at', ['occurred_at'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_is_reversal', ['is_reversal'], unique=False)
        batch_op.create_index('ix_cash_flow_entries_reversal_of_id', ['reversal_of_id'], unique=False)

    # Triggers for cash_flow_entries append-only enforcement
    op.execute(
        """
        CREATE TRIGGER IF NOT EXISTS trg_prevent_cash_flow_entries_update
        BEFORE UPDATE ON cash_flow_entries
        BEGIN
            SELECT RAISE(ABORT, 'cash_flow_entries is append-only: updates are forbidden');
        END;
        """
    )
    op.execute(
        """
        CREATE TRIGGER IF NOT EXISTS trg_prevent_cash_flow_entries_delete
        BEFORE DELETE ON cash_flow_entries
        BEGIN
            SELECT RAISE(ABORT, 'cash_flow_entries is append-only: deletes are forbidden');
        END;
        """
    )

    # 3. Create accounts_payable table
    op.create_table(
        'accounts_payable',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('payable_number', sa.Integer(), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('beneficiary', sa.String(length=200), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('nature', sa.String(length=30), nullable=False, server_default='BUSINESS'),
        sa.Column('original_amount_cents', sa.Integer(), nullable=False),
        sa.Column('paid_amount_cents', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('balance_cents', sa.Integer(), nullable=False),
        sa.Column('due_date', sa.DateTime(), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=False, server_default='BOLETO'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='OPEN'),
        sa.Column('purchase_id', sa.String(length=36), nullable=True),
        sa.Column('installment_number', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('total_installments', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('installment_group_id', sa.String(length=36), nullable=True),
        sa.Column('is_recurrent', sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column('recurrence_period', sa.String(length=20), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['purchase_id'], ['purchases.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('accounts_payable', schema=None) as batch_op:
        batch_op.create_index('ix_accounts_payable_payable_number', ['payable_number'], unique=True)
        batch_op.create_index('ix_accounts_payable_beneficiary', ['beneficiary'], unique=False)
        batch_op.create_index('ix_accounts_payable_category', ['category'], unique=False)
        batch_op.create_index('ix_accounts_payable_nature', ['nature'], unique=False)
        batch_op.create_index('ix_accounts_payable_due_date', ['due_date'], unique=False)
        batch_op.create_index('ix_accounts_payable_status', ['status'], unique=False)
        batch_op.create_index('ix_accounts_payable_purchase_id', ['purchase_id'], unique=False)
        batch_op.create_index('ix_accounts_payable_installment_group_id', ['installment_group_id'], unique=False)

    # 4. Create payable_payments table
    op.create_table(
        'payable_payments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('payable_id', sa.String(length=36), nullable=False),
        sa.Column('account_id', sa.String(length=36), nullable=False),
        sa.Column('payment_date', sa.DateTime(), nullable=False),
        sa.Column('amount_cents', sa.Integer(), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=False, server_default='BOLETO'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='CONFIRMED'),
        sa.Column('reversal_reason', sa.Text(), nullable=True),
        sa.Column('reversal_of_id', sa.String(length=36), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['account_id'], ['financial_accounts.id']),
        sa.ForeignKeyConstraint(['payable_id'], ['accounts_payable.id']),
        sa.ForeignKeyConstraint(['reversal_of_id'], ['payable_payments.id']),
        sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('payable_payments', schema=None) as batch_op:
        batch_op.create_index('ix_payable_payments_payable_id', ['payable_id'], unique=False)
        batch_op.create_index('ix_payable_payments_account_id', ['account_id'], unique=False)
        batch_op.create_index('ix_payable_payments_payment_date', ['payment_date'], unique=False)
        batch_op.create_index('ix_payable_payments_status', ['status'], unique=False)

    # 5. Update sales table (add account_id)
    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.add_column(sa.Column('account_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_sales_account_id', 'financial_accounts', ['account_id'], ['id'])
        batch_op.create_index('ix_sales_account_id', ['account_id'], unique=False)

    # 6. Update receivable_payments table (add account_id)
    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.add_column(sa.Column('account_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_receivable_payments_account_id', 'financial_accounts', ['account_id'], ['id'])
        batch_op.create_index('ix_receivable_payments_account_id', ['account_id'], unique=False)

    # 7. Update dispatch_repayments table (add account_id)
    with op.batch_alter_table('dispatch_repayments', schema=None) as batch_op:
        batch_op.add_column(sa.Column('account_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_dispatch_repayments_account_id', 'financial_accounts', ['account_id'], ['id'])
        batch_op.create_index('ix_dispatch_repayments_account_id', ['account_id'], unique=False)

    # 8. Update purchases table (add payment_mode, due_date, account_id)
    with op.batch_alter_table('purchases', schema=None) as batch_op:
        batch_op.add_column(sa.Column('payment_mode', sa.String(length=30), nullable=False, server_default='CASH_IMMEDIATE'))
        batch_op.add_column(sa.Column('due_date', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('account_id', sa.String(length=36), nullable=True))
        batch_op.create_foreign_key('fk_purchases_account_id', 'financial_accounts', ['account_id'], ['id'])
        batch_op.create_index('ix_purchases_payment_mode', ['payment_mode'], unique=False)
        batch_op.create_index('ix_purchases_account_id', ['account_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('purchases', schema=None) as batch_op:
        batch_op.drop_index('ix_purchases_account_id')
        batch_op.drop_index('ix_purchases_payment_mode')
        batch_op.drop_constraint('fk_purchases_account_id', type_='foreignkey')
        batch_op.drop_column('account_id')
        batch_op.drop_column('due_date')
        batch_op.drop_column('payment_mode')

    with op.batch_alter_table('dispatch_repayments', schema=None) as batch_op:
        batch_op.drop_index('ix_dispatch_repayments_account_id')
        batch_op.drop_constraint('fk_dispatch_repayments_account_id', type_='foreignkey')
        batch_op.drop_column('account_id')

    with op.batch_alter_table('receivable_payments', schema=None) as batch_op:
        batch_op.drop_index('ix_receivable_payments_account_id')
        batch_op.drop_constraint('fk_receivable_payments_account_id', type_='foreignkey')
        batch_op.drop_column('account_id')

    with op.batch_alter_table('sales', schema=None) as batch_op:
        batch_op.drop_index('ix_sales_account_id')
        batch_op.drop_constraint('fk_sales_account_id', type_='foreignkey')
        batch_op.drop_column('account_id')

    op.drop_table('payable_payments')
    op.drop_table('accounts_payable')

    op.execute("DROP TRIGGER IF EXISTS trg_prevent_cash_flow_entries_delete")
    op.execute("DROP TRIGGER IF EXISTS trg_prevent_cash_flow_entries_update")

    op.drop_table('cash_flow_entries')
    op.drop_table('financial_accounts')
