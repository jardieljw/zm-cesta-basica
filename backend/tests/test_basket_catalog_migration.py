from pathlib import Path
import sqlite3
from alembic import command
from alembic.config import Config
from app.models.products import BasketType, Product, RecipeVersion, RecipeItem
from app.models.production import ProductionBatch
from app.models.movements import InventoryMovement


def test_catalog_migration_preserves_populated_history_and_foreign_keys(test_session, test_db_path):
    test_session.add(Product(id='migration-product', name='Sabonete', category='LIMPEZA', base_unit='UN'))
    test_session.add(BasketType(id='migration-basket', code='MIGRATION', name='Cesta existente'))
    test_session.flush()
    test_session.add(RecipeVersion(id='migration-recipe', basket_type_id='migration-basket', version_number=1))
    test_session.flush()
    test_session.add(RecipeItem(id='migration-item', recipe_version_id='migration-recipe',
                               product_id='migration-product', quantity_in_base_units=2, section='LIMPEZA'))
    test_session.add(ProductionBatch(id='migration-batch', batch_number=1, basket_type_id='migration-basket',
                                    recipe_version_id='migration-recipe', quantity_produced=3))
    test_session.flush()
    test_session.add(InventoryMovement(id='migration-movement', item_type='BASKET',
                                      basket_type_id='migration-basket', quantity_delta=3,
                                      movement_type='ASSEMBLY_PRODUCE', source_type='PRODUCTION', source_id='migration-batch'))
    test_session.commit()
    backend = Path(__file__).resolve().parents[1]
    config = Config(str(backend / 'alembic.ini'))
    config.set_main_option('script_location', str(backend / 'alembic'))
    config.set_main_option('sqlalchemy.url', f'sqlite:///{test_db_path.as_posix()}')
    command.stamp(config, 'f9c0d1e2f309')
    command.downgrade(config, 'f8b9c0d1e208')

    def snapshot():
        with sqlite3.connect(test_db_path) as db:
            tables = [row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('alembic_version','sqlite_sequence')")]
            result = {}
            for table in tables:
                columns = [row[1] for row in db.execute(f'PRAGMA table_info("{table}")') if row[1] != 'removed_at']
                fields = ','.join(f'"{column}"' for column in columns)
                result[table] = sorted(db.execute(f'SELECT {fields} FROM "{table}"').fetchall(), key=repr)
            return result

    original = snapshot()
    command.upgrade(config, 'f9c0d1e2f309')
    assert snapshot() == original
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('SELECT removed_at FROM basket_types').fetchone() == (None,)
        assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []
        assert db.execute('SELECT version_num FROM alembic_version').fetchone() == ('f9c0d1e2f309',)
    command.downgrade(config, 'f8b9c0d1e208')
    assert snapshot() == original
    command.upgrade(config, 'f9c0d1e2f309')
