import logging
import sqlite3
import os
from contextlib import closing
import tempfile
import uuid
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import select, inspect
from sqlalchemy.orm import Session

from app.core.backup import BackupError, check_sqlite_integrity, create_backup, restore_backup
from app.core.config import settings
from app.core.database import create_db_engine
from app.core.idempotency import process_transactional_idempotency
from app.models.idempotency import IdempotencyRecord
from app.models import Base
from app.services.financial import ensure_default_financial_account

logger = logging.getLogger(__name__)
OPERATION = 'NEW_DATABASE'


def create_and_activate_database(engine, key: str, payload: dict) -> dict:
    """Called only under the exclusive request barrier, with auth session closed."""
    with Session(engine) as db:
        existing = db.scalar(select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key))
        if existing is not None:
            def no_reexecution(_):
                raise BackupError('Incomplete database maintenance record')
            result = process_transactional_idempotency(db, key, OPERATION, payload, no_reexecution).to_json_dict()
            result['operation_replayed'] = True
            return result

    active = settings.DATABASE_PATH
    safety = create_backup(tag=f'pre_new_{uuid.uuid4().hex[:8]}')
    fd, name = tempfile.mkstemp(prefix='new_database_', suffix='.db', dir=active.parent)
    os.close(fd)
    prepared = Path(name)
    new_engine = None
    activation_started = False
    try:
        config = Config()
        config.set_main_option('script_location', str(Path(__file__).resolve().parents[2] / 'alembic'))
        config.set_main_option('sqlalchemy.url', f'sqlite:///{prepared.as_posix()}')
        command.upgrade(config, 'head')
        # Identity belongs to the installation; business history belongs to its database.
        with closing(sqlite3.connect(safety['backup_path'])) as source, closing(sqlite3.connect(prepared)) as target:
            for table, where in [('paired_devices', ''), ('idempotency_records', " WHERE operation_type = 'NEW_DATABASE'")]:
                cursor = source.execute(f'SELECT * FROM {table}{where}')
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if rows:
                    target.executemany(f"INSERT INTO {table} ({','.join(columns)}) VALUES ({','.join('?' for _ in columns)})", rows)
            target.commit()
        new_engine = create_db_engine(f'sqlite:///{prepared.as_posix()}')
        schema = inspect(new_engine)
        for table in Base.metadata.tables.values():
            actual = {column['name'] for column in schema.get_columns(table.name)}
            missing = {column.name for column in table.columns} - actual
            if missing:
                raise BackupError(f'Migrated schema is missing {table.name}: {sorted(missing)}')
        with Session(new_engine) as db:
            ensure_default_financial_account(db)
            result = {
                'status': 'success', 'active_database_path': str(active.resolve()),
                'safety_backup_filename': safety['backup_filename'],
                'safety_backup_path': safety['backup_path'], 'integrity_ok': True,
                'message': 'Novo banco vazio criado e ativado. Pareamentos preservados.',
                'operation_replayed': False}
            process_transactional_idempotency(db, key, OPERATION, payload, lambda _: (200, result))
        new_engine.dispose()
        with closing(sqlite3.connect(prepared)) as db:
            if db.execute('PRAGMA foreign_key_check').fetchall():
                raise BackupError('Fresh database failed foreign key validation')
        if not check_sqlite_integrity(prepared):
            raise BackupError('Fresh database failed integrity validation')
        engine.dispose()
        activation_started = True
        restore_backup(prepared, target_path=active)
        engine.dispose()
        return result
    except Exception:
        if activation_started:
            engine.dispose()
            restore_backup(Path(safety['backup_path']), target_path=active)
            engine.dispose()
        logger.exception('New database activation failed; previous database retained/restored')
        raise
    finally:
        if new_engine is not None:
            new_engine.dispose()
        for suffix in ['', '-wal', '-shm']:
            Path(str(prepared) + suffix).unlink(missing_ok=True)
