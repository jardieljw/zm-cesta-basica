"""Backfill is exercised only on populated, independently copied databases."""
import copy
import datetime as dt
import hashlib
import importlib.util
import json
import sqlite3
import uuid
from pathlib import Path

import pytest
from alembic import command
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from test_financial_imports_migration import config
from test_financial_import_removal_migration import rows
from test_financial_import_lifecycle import api, read, identity, plan, remove
from test_financial_bill_cycles import integrate


def module(name):
    path = Path(__file__).resolve().parents[1] / 'alembic' / 'versions' / name
    spec = importlib.util.spec_from_file_location('migration_' + path.stem, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def legacy_copy(path, target, withdrawals=()):
    with sqlite3.connect(path) as source, sqlite3.connect(target) as db:
        source.backup(db)
        db.execute('PRAGMA foreign_keys=OFF')
        for action in ('insert', 'update', 'delete'):
            db.execute('DROP TRIGGER IF EXISTS trg_fin_import_legacy_no_' + action)
        db.execute('DROP TRIGGER IF EXISTS trg_substituted_payable_guard')
        db.execute(module('f17e8f901037_import_removal_state.py').RESTORED_GUARD)
        db.execute('DROP TABLE financial_import_entry_segments')
        db.execute('DROP TABLE financial_import_entries')
        for p, effects in withdrawals:
            db.execute('INSERT INTO financial_import_removals VALUES (?,?,?,?,?,?)',
                       (p['document_id'], 3, 0, json.dumps(effects), p['created_by'], '2026-10-20'))
        db.commit()
    command.stamp(config(target), 'f28f901a1048')


def open_bill(api, source=None, content=None):
    p = read(api, source or api.source('CREDIT_CARD'), **({'content': content} if content else {}))
    c = {**identity(p), 'expected_source_id': p['source_id'],
         'expected_result_sha256': p['result_sha256'], 'expected_revision': 0,
         'reference': '2026-10', 'due_on': '2026-10-24', 'total_amount_cents': 10000,
         'controls_confirmed': True, 'destination': 'OPEN', 'reason': 'Saldo conferido no documento'}
    return p, integrate(api, p, c)


def test_populated_copy_preserves_rows_confirmed_root_and_reactivated_legacy_retention(
        api, test_db_path, test_session, tmp_path):
    from app.models.financial_imports import FinancialImportPreview
    from app.services.financial_import_removals import hidden_payables
    p, first = open_bill(api)
    other, second = open_bill(api, content=b'date,title,amount\n2026-10-01,Outra,"100,00"\n')
    effects = plan(api, other)['effects']
    remove(api, other)
    original = test_session.get(FinancialImportPreview, p['id'])
    report = copy.deepcopy(original.result)
    report['errors'].append({'code': 'PDF_LAYOUT_UNSUPPORTED', 'fields': []})
    later = FinancialImportPreview(id=str(uuid.uuid4()), document_id=p['document_id'],
        source_id=p['source_id'], reader_id=original.reader_id, reader_version='future-invalid',
        options={}, request_sha256='e' * 64, result_sha256='f' * 64, status='INVALID',
        result=report, created_by=p['created_by'], created_at=dt.datetime(2099, 1, 1))
    test_session.add(later)
    test_session.commit()
    source, target = tmp_path / 'legacy-source.db', tmp_path / 'migration-copy.db'
    legacy_copy(test_db_path, source, [(other, effects)])
    with sqlite3.connect(source) as db, sqlite3.connect(target) as dest:
        db.backup(dest)
    before = rows(source)
    command.upgrade(config(target), 'f39a012b2159')
    after = rows(target)
    assert all(after[name] == data for name, data in before.items())
    assert rows(source) == before
    with sqlite3.connect(target) as db:
        assert db.execute('SELECT root_preview_id FROM financial_import_entries WHERE document_id=?',
                          (p['document_id'],)).fetchone()[0] == p['id']
        entry = db.execute('SELECT state,effects,retained_effects FROM financial_import_entries WHERE document_id=?',
                           (other['document_id'],)).fetchone()
        assert entry[0] == 'ACTIVE'
        assert second['payable_id'] not in json.loads(entry[1])['payable_ids']
        assert second['payable_id'] in json.loads(entry[2])['payable_ids']
        assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []
        with pytest.raises(sqlite3.IntegrityError, match='read only'):
            db.execute('UPDATE financial_import_removals SET removed=1')
    engine = create_engine('sqlite:///' + target.as_posix())
    with Session(engine) as session:
        assert second['payable_id'] in hidden_payables(session)
        assert first['payable_id'] not in hidden_payables(session)
    engine.dispose()


def test_ambiguous_confirmations_refuse_before_ddl_and_leave_source_unchanged(
        api, test_db_path, test_session, tmp_path):
    from app.models.financial_imports import FinancialImportPreview, FinancialStatement
    p = read(api, api.source('BANK_ACCOUNT'))
    original = test_session.get(FinancialImportPreview, p['id'])
    other = FinancialImportPreview(id=str(uuid.uuid4()), document_id=p['document_id'],
        source_id=p['source_id'], reader_id=original.reader_id, reader_version='other', options={},
        request_sha256='c' * 64, result_sha256='d' * 64, status=original.status,
        result=copy.deepcopy(original.result), created_by=p['created_by'])
    test_session.add(other)
    test_session.flush()
    for preview in (original, other):
        test_session.add(FinancialStatement(id=str(uuid.uuid4()), document_id=p['document_id'],
            source_id=p['source_id'], preview_id=preview.id, statement_type='BANK_STATEMENT',
            payload_sha256=hashlib.sha256(preview.id.encode()).hexdigest(), created_by=p['created_by']))
    test_session.commit()
    target = tmp_path / 'ambiguous-copy.db'
    legacy_copy(test_db_path, target)
    before = rows(target)
    with pytest.raises(RuntimeError, match='ambiguous active roots'):
        command.upgrade(config(target), 'f39a012b2159')
    assert rows(target) == before
    with sqlite3.connect(target) as db:
        assert db.execute("SELECT COUNT(*) FROM sqlite_master WHERE name='financial_import_entries'").fetchone()[0] == 0


def test_confirmed_bank_evidence_and_reconciliation_survive_populated_copy(api, test_db_path, tmp_path):
    from test_financial_readers import preview, confirm
    source = api.source('BANK_ACCOUNT')
    p, _, _ = preview(api, source, b'Data;Valor;Descricao\n01/10/2026;-10,00;Movimento\n')
    statement = confirm(api, p, period_start='2026-10-01', period_end='2026-10-01')['statement']
    item = api.get('/statements/' + statement['id'] + '/items')[0]
    transaction = api.review(item)['transaction']
    cash = api.entry(source['financial_account_id'], amount=1000)
    api.post('/reconciliations', {**identity(p), 'transaction_id': transaction['id'],
        'cash_flow_entry_id': cash['id'], 'amount_cents': 1000, 'reason': 'Movimento existente conferido'})
    target = tmp_path / 'bank-copy.db'
    legacy_copy(test_db_path, target)
    before = rows(target)
    command.upgrade(config(target), 'f39a012b2159')
    after = rows(target)
    assert all(after[name] == data for name, data in before.items())
    with sqlite3.connect(target) as db:
        assert db.execute('SELECT statement_id FROM financial_import_entries').fetchone()[0] == statement['id']
        assert db.execute('SELECT COUNT(*) FROM financial_reconciliations').fetchone()[0] == 1
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []
