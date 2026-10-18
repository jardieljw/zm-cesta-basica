import asyncio
import sqlite3
from contextlib import closing
from pathlib import Path

import pytest
from app.core.config import settings
from app.core.database_maintenance import DatabaseGate
from app.core.backup import BackupError
from app.core import new_database


def headers(authenticated_device, key='new-bank-request'):
    return {**authenticated_device[2], 'X-Idempotency-Key': key}


def add_product(client, authenticated_device, name='Before'):
    response = client.post('/api/v1/products', json={
        'name': name, 'category': 'ALIMENTACAO', 'base_unit': 'UN'},
        headers=authenticated_device[2])
    assert response.status_code in (200, 201), response.text


def reset(client, authenticated_device, key='new-bank-request'):
    return client.post('/api/v1/backup/new-database',
        json={'confirmation': 'NOVO BANCO'}, headers=headers(authenticated_device, key))


def test_new_database_is_active_migrated_empty_and_previous_data_backed_up(client, authenticated_device):
    add_product(client, authenticated_device)
    response = reset(client, authenticated_device)
    assert response.status_code == 200, response.text
    result = response.json()
    assert result['integrity_ok']
    assert client.get('/api/v1/products', headers=authenticated_device[2]).json() == []
    with closing(sqlite3.connect(result['safety_backup_path'])) as backup:
        assert backup.execute('SELECT name FROM products').fetchone()[0] == 'Before'
    with closing(sqlite3.connect(settings.DATABASE_PATH)) as active:
        assert active.execute('SELECT version_num FROM alembic_version').fetchone()
        assert active.execute('SELECT COUNT(*) FROM paired_devices').fetchone()[0] >= 1
        assert active.execute('SELECT COUNT(*) FROM financial_accounts').fetchone()[0] == 1
        assert active.execute('PRAGMA foreign_key_check').fetchall() == []
        for table in ['products', 'customers', 'sales', 'purchases', 'inventory_movements', 'cash_flow_entries']:
            assert active.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0] == 0
    assert client.get('/api/v1/devices', headers=authenticated_device[2]).status_code == 200
    # Existing restore action can recover the former business database.
    restored = client.post('/api/v1/backup/restore', headers=authenticated_device[2],
        json={'backup_filename': result['safety_backup_filename']})
    assert restored.status_code == 200, restored.text
    assert len(client.get('/api/v1/products', headers=authenticated_device[2]).json()) == 1
    replay = reset(client, authenticated_device).json()
    assert replay == {**result, 'operation_replayed': True}
    assert len(client.get('/api/v1/products', headers=authenticated_device[2]).json()) == 1


def test_retry_does_not_erase_new_data_even_after_another_new_database(client, authenticated_device):
    first = reset(client, authenticated_device, 'first').json()
    assert reset(client, authenticated_device, 'second').status_code == 200
    add_product(client, authenticated_device, 'New data')
    replay = reset(client, authenticated_device, 'first')
    assert replay.status_code == 200, replay.text
    assert replay.json() == {**first, 'operation_replayed': True}
    assert len(client.get('/api/v1/products', headers=authenticated_device[2]).json()) == 1


@pytest.mark.parametrize('failure', ['backup', 'migration', 'activation'])
def test_failure_preserves_current_database(client, authenticated_device, monkeypatch, failure):
    add_product(client, authenticated_device)
    def fail(*args, **kwargs):
        raise BackupError('simulated failure')
    if failure == 'backup':
        monkeypatch.setattr(new_database, 'create_backup', fail)
    elif failure == 'migration':
        monkeypatch.setattr(new_database.command, 'upgrade', fail)
    else:
        original = new_database.restore_backup
        def fail_activation(source, **kwargs):
            if Path(source).name.startswith('new_database_'):
                # Simulate a target changed before activation verification fails.
                original(source, **kwargs)
                fail()
            return original(source, **kwargs)
        monkeypatch.setattr(new_database, 'restore_backup', fail_activation)
    response = reset(client, authenticated_device)
    assert response.status_code == 500
    assert response.json()['detail']['error_code'] == 'NEW_DATABASE_FAILED'
    assert len(client.get('/api/v1/products', headers=authenticated_device[2]).json()) == 1


def test_explicit_confirmation_and_request_key_are_required(client, authenticated_device):
    assert client.post('/api/v1/backup/new-database', headers=headers(authenticated_device),
        json={'confirmation': 'no'}).status_code == 422
    assert client.post('/api/v1/backup/new-database', headers=authenticated_device[2],
        json={'confirmation': 'NOVO BANCO'}).status_code == 422


def test_maintenance_waits_for_old_requests_and_blocks_new_requests():
    async def exercise():
        gate = DatabaseGate()
        await gate.acquire(False)
        write_started = asyncio.Event()
        finish_write = asyncio.Event()
        read_started = asyncio.Event()
        async def writer():
            await gate.acquire(True)
            write_started.set()
            await finish_write.wait()
            await gate.release(True)
        async def reader():
            await gate.acquire(False)
            read_started.set()
            await gate.release(False)
        write = asyncio.create_task(writer())
        await asyncio.sleep(0)
        read = asyncio.create_task(reader())
        await asyncio.sleep(0)
        assert not write_started.is_set() and not read_started.is_set()
        await gate.release(False)
        await write_started.wait()
        assert not read_started.is_set()
        finish_write.set()
        await asyncio.gather(write, read)
        assert read_started.is_set()
    asyncio.run(exercise())


def test_new_database_rejects_fallback_master_without_real_token(client, authenticated_device, test_session):
    device = authenticated_device[0]
    device.device_public_id = 'windows-local-master'
    test_session.commit()
    for authorization in [None, 'Bearer invalid-token']:
        request_headers = {'X-Idempotency-Key': 'strict-auth-test'}
        if authorization:
            request_headers['Authorization'] = authorization
        response = client.post('/api/v1/backup/new-database',
            headers=request_headers, json={'confirmation': 'NOVO BANCO'})
        assert response.status_code == 401


def test_fresh_migrated_database_runs_the_existing_operational_cycle(client, authenticated_device, tmp_path):
    from test_phase9_e2e_robustness import test_complete_phase9_end_to_end_operational_cycle
    response = reset(client, authenticated_device)
    assert response.status_code == 200, response.text
    test_complete_phase9_end_to_end_operational_cycle(client, authenticated_device, tmp_path)


def test_backup_cleanup_keeps_previous_business_databases(tmp_path, monkeypatch):
    import importlib.util
    from types import SimpleNamespace
    spec = importlib.util.spec_from_file_location('backup_cli_test',
        Path(__file__).resolve().parents[2] / 'scripts' / 'backup_cli.py')
    cli = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cli)
    names = ['estoque_backup_manual_latest.db', 'estoque_backup_manual_old.db',
        'estoque_backup_pre_new_previous.db']
    for name in names:
        (tmp_path / name).write_bytes(b'test fixture')
    monkeypatch.setattr(cli, 'list_backups', lambda: [
        {'filename': name, 'path': str(tmp_path / name)} for name in names])
    assert cli.cmd_cleanup(SimpleNamespace(keep=1)) == 0
    assert (tmp_path / names[0]).exists()
    assert not (tmp_path / names[1]).exists()
    assert (tmp_path / names[2]).exists()
