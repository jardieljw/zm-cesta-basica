"""Catalog removal independent of canceled history; optional recipe price."""
from alembic import op
import sqlalchemy as sa
revision = 'f28f901a1048'
down_revision = 'f17e8f901037'
branch_labels = depends_on = None

def upgrade():
    op.add_column('products', sa.Column('removed_at', sa.DateTime(), nullable=True))
    op.add_column('recipe_versions', sa.Column('suggested_price_cents', sa.Integer(), nullable=True))
    op.create_table('sale_recipe_references',
        sa.Column('sale_item_id', sa.String(36), sa.ForeignKey('sale_items.id'), primary_key=True),
        sa.Column('recipe_version_id', sa.String(36), sa.ForeignKey('recipe_versions.id'), primary_key=True))
    for action in ('UPDATE', 'DELETE'):
        op.execute(f"CREATE TRIGGER IF NOT EXISTS trg_sale_recipe_references_{action.lower()} BEFORE {action} "
            "ON sale_recipe_references BEGIN SELECT RAISE(ABORT, 'sale recipe references are immutable'); END;")

def downgrade():
    db = op.get_bind()
    if db.exec_driver_sql("SELECT 1 FROM products WHERE removed_at IS NOT NULL UNION ALL SELECT 1 FROM recipe_versions WHERE status='REMOVED' OR suggested_price_cents IS NOT NULL UNION ALL SELECT 1 FROM sale_recipe_references LIMIT 1").first():
        raise RuntimeError('Não remover suporte a exclusões/receitas já utilizadas nesta versão.')
    op.drop_column('recipe_versions', 'suggested_price_cents')
    op.drop_column('products', 'removed_at')
    op.drop_table('sale_recipe_references')
