"""Phase 3: Inventory movements indexes and ledger append-only triggers

Revision ID: d2e6f7a8b902
Revises: c1f5d6a8e901
Create Date: 2026-10-11 11:35:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'd2e6f7a8b902'
down_revision: Union[str, None] = 'c1f5d6a8e901'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Create performance indexes for inventory ledger
    with op.batch_alter_table('inventory_movements', schema=None) as batch_op:
        batch_op.create_index('ix_inventory_movements_product_id', ['product_id'], unique=False)
        batch_op.create_index('ix_inventory_movements_basket_type_id', ['basket_type_id'], unique=False)
        batch_op.create_index('ix_inventory_movements_production_batch_id', ['production_batch_id'], unique=False)
        batch_op.create_index('ix_inventory_movements_movement_type', ['movement_type'], unique=False)
        batch_op.create_index('ix_inventory_movements_source_id', ['source_id'], unique=False)
        batch_op.create_index('ix_inventory_movements_occurred_at', ['occurred_at'], unique=False)

    # Create SQLite triggers enforcing strictly append-only ledger
    op.execute("""
        CREATE TRIGGER IF NOT EXISTS trg_prevent_inventory_movements_update
        BEFORE UPDATE ON inventory_movements
        BEGIN
            SELECT RAISE(ABORT, 'inventory_movements is append-only: updates are forbidden');
        END;
    """)

    op.execute("""
        CREATE TRIGGER IF NOT EXISTS trg_prevent_inventory_movements_delete
        BEFORE DELETE ON inventory_movements
        BEGIN
            SELECT RAISE(ABORT, 'inventory_movements is append-only: deletes are forbidden');
        END;
    """)

def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_prevent_inventory_movements_delete;")
    op.execute("DROP TRIGGER IF EXISTS trg_prevent_inventory_movements_update;")

    with op.batch_alter_table('inventory_movements', schema=None) as batch_op:
        batch_op.drop_index('ix_inventory_movements_occurred_at')
        batch_op.drop_index('ix_inventory_movements_source_id')
        batch_op.drop_index('ix_inventory_movements_movement_type')
        batch_op.drop_index('ix_inventory_movements_production_batch_id')
        batch_op.drop_index('ix_inventory_movements_basket_type_id')
        batch_op.drop_index('ix_inventory_movements_product_id')
