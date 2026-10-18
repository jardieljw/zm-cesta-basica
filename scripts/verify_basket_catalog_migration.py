"""Back up the live database and verify the catalog migration on a separate copy."""
import hashlib
import json
import sqlite3
import sys
from pathlib import Path
from alembic import command
from alembic.config import Config

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
from app.core.backup import create_backup


def snapshot(path):
    with sqlite3.connect(path) as db:
        tables = [row[0] for row in db.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('sqlite_sequence','alembic_version')")]
        result = {}
        for table in tables:
            quoted = '"' + table.replace('"', '""') + '"'
            columns = [row[1] for row in db.execute(f'PRAGMA table_info({quoted})') if row[1] != 'removed_at']
            fields = ','.join('"' + column.replace('"', '""') + '"' for column in columns)
            rows = sorted(db.execute(f'SELECT {fields} FROM {quoted}').fetchall(), key=repr)
            result[table] = (len(rows), hashlib.sha256(repr(rows).encode()).hexdigest())
        assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []
        return result


def main():
    backup = create_backup(tag='before_basket_catalog')
    backup_path = Path(backup['backup_path']).resolve()
    copy_path = backup_path.with_name(backup_path.stem + '_migrationcheck.db')
    assert copy_path.parent == (ROOT / 'backend' / 'backups').resolve()
    with sqlite3.connect(backup_path) as source, sqlite3.connect(copy_path) as target:
        source.backup(target)
    original = snapshot(copy_path)
    config = Config(str(ROOT / 'backend' / 'alembic.ini'))
    config.set_main_option('script_location', str(ROOT / 'backend' / 'alembic'))
    config.set_main_option('sqlalchemy.url', f'sqlite:///{copy_path.as_posix()}')
    command.upgrade(config, 'head')
    assert snapshot(copy_path) == original
    with sqlite3.connect(copy_path) as db:
        assert all(row[0] is None for row in db.execute('SELECT removed_at FROM basket_types'))
    command.downgrade(config, 'f8b9c0d1e208')
    assert snapshot(copy_path) == original
    command.upgrade(config, 'head')
    assert snapshot(copy_path) == original
    print(json.dumps({'backup': str(backup_path), 'verified_copy': str(copy_path),
                      'tables_verified': len(original), 'rows_verified': sum(value[0] for value in original.values()),
                      'integrity_ok': True, 'foreign_keys_ok': True, 'original_database_modified': False}))


if __name__ == '__main__':
    main()
