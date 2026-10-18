"""basket catalog removal preserving history

Revision ID: f9c0d1e2f309
Revises: f8b9c0d1e208
Create Date: 2026-10-14 16:52:38.698656

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f9c0d1e2f309'
down_revision: Union[str, None] = 'f8b9c0d1e208'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('basket_types', sa.Column('removed_at', sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column('basket_types', 'removed_at')
