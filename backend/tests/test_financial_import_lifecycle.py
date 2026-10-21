"""Lifecycle regressions use disposable databases and real domain services."""
import sqlite3
import uuid
import copy
import hashlib
from concurrent.futures import ThreadPoolExecutor
import pytest

from test_financial_bill_cycles import api, bill, integrate


CONTENT = b'date,title,amount\n2026-10-01,Compra,"100,00"\n'


def read(api, source, content=CONTENT, filename='fatura.csv', **changes):
    document = api.document(content, filename=filename)['document']
    state = api.get('/documents/' + document['id'] + '/import-state')
    payload = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'csv_auto',
               'expected_generation': state['current_generation'], **changes}
    return api.post('/documents/' + document['id'] + '/previews', payload)['preview']


def identity(p):
    return {'import_id': p['import_id'], 'expected_generation': p['generation']}


def plan(api, p):
    return api.get('/documents/' + p['document_id'] + '/removal?import_id=' +
                   p['import_id'] + '&expected_generation=' + str(p['generation']))


def remove(api, p):
    value = plan(api, p)
    return api.post('/documents/' + p['document_id'] + '/remove',
                    {**identity(p), 'expected_snapshot': value['snapshot']})


def counts(path):
    with sqlite3.connect(path) as db:
        return tuple(db.execute('SELECT COUNT(*) FROM ' + table).fetchone()[0]
                     for table in ('financial_documents', 'financial_import_previews',
                                   'financial_import_entries', 'accounts_payable'))


def test_upload_does_not_restore_history_and_read_creates_one_generation(api, test_db_path):
    source = api.source('CREDIT_CARD')
    first = read(api, source)
    remove(api, first)
    before = counts(test_db_path)
    assert api.get('/previews') == []
    api.document(CONTENT, filename='outro-nome.csv')
    assert api.get('/previews') == [] and counts(test_db_path) == before
    second = read(api, source)
    assert second['generation'] == first['generation'] + 1
    assert second['import_id'] != first['import_id']
    assert second['id'] == first['id']  # immutable reader cache can be reused
    assert counts(test_db_path)[:3] == (1, 1, 2)
    assert [p['import_id'] for p in api.get('/previews')] == [second['import_id']]
    assert counts(test_db_path)[3] == 0


def test_other_bytes_and_same_name_do_not_restore_a_and_opening_is_read_only(api, test_db_path):
    source = api.source('CREDIT_CARD')
    first = read(api, source)
    remove(api, first)
    second = read(api, source, CONTENT.replace(b'Compra', b'Outra compra'))
    before = counts(test_db_path)
    for _ in range(4):
        assert api.get('/previews/' + second['id'])['import_id'] == second['import_id']
        api.get('/previews?limit=1&offset=0')
    assert counts(test_db_path) == before
    assert [p['document_id'] for p in api.get('/previews')] == [second['document_id']]
    assert api.get('/documents/' + first['document_id'] + '/import-state')['active_import'] is None


def test_concurrent_read_and_replay_never_duplicate_generation(api, test_db_path):
    source = api.source('CREDIT_CARD')
    doc = api.document(CONTENT)['document']
    payload = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'csv_auto',
               'expected_generation': 0}
    path = '/documents/' + doc['id'] + '/previews'
    key = str(uuid.uuid4())
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda _: api.post(path, payload, key=key), range(2)))
    assert responses[0] == responses[1]
    assert counts(test_db_path)[:3] == (1, 1, 1)
    denied = api.post(path, payload, expected=(409,))
    assert denied['detail']['error_code'] == 'FINANCIAL_IMPORT_GENERATION_CONFLICT'


def test_removed_generation_cannot_confirm_and_pending_removal_keeps_old_withdrawals(api, test_db_path):
    p = read(api, api.source('CREDIT_CARD'))
    command = {**identity(p), 'expected_source_id': p['source_id'],
               'expected_result_sha256': p['result_sha256'], 'expected_revision': 0,
               'reference': '2026-10', 'due_on': '2026-10-24', 'total_amount_cents': 10000,
               'controls_confirmed': True, 'destination': 'OPEN', 'reason': 'Conferido o saldo devido'}
    result = integrate(api, p, command)
    remove(api, p)
    second = read(api, {'id': p['source_id']})
    stale = integrate(api, p, command, expected=(409,))
    assert stale['detail']['error_code'] == 'FINANCIAL_IMPORT_GENERATION_CONFLICT'
    assert api.client.get('/api/v1/payables', headers=api.headers).json() == []
    assert plan(api, second)['payables'] == []
    remove(api, second)
    assert api.client.get('/api/v1/payables', headers=api.headers).json() == []
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('SELECT status,balance_cents FROM accounts_payable WHERE id=?',
                          (result['payable_id'],)).fetchone() == ('CANCELED', 0)
        assert db.execute('SELECT COUNT(*) FROM financial_import_removals').fetchone()[0] == 0


def test_old_client_is_refused_without_persisting_a_read(api, test_db_path):
    source = api.source('CREDIT_CARD')
    doc = api.document(CONTENT)['document']
    response = api.post('/documents/' + doc['id'] + '/previews',
                        {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'csv_auto'},
                        expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_CLIENT_UPDATE_REQUIRED'
    assert counts(test_db_path)[:3] == (1, 0, 0)


def test_five_historical_interpretations_stay_out_after_reimport(api, test_db_path, test_session):
    from app.models.financial_imports import FinancialImportPreview
    source = api.source('CREDIT_CARD')
    p = read(api, source)
    other_sources = [api.source('CREDIT_CARD') for _ in range(4)]
    original = test_session.get(FinancialImportPreview, p['id'])
    for index, other_source in enumerate(other_sources):
        test_session.add(FinancialImportPreview(id=str(uuid.uuid4()), document_id=p['document_id'],
            source_id=other_source['id'], reader_id=original.reader_id, reader_version=str(index),
            options={}, request_sha256=hashlib.sha256(str(index).encode()).hexdigest(),
            result_sha256=original.result_sha256, status=original.status,
            result=copy.deepcopy(original.result), created_by=p['created_by']))
    test_session.commit()
    assert len(api.get('/previews')) == 1
    remove(api, p)
    before = counts(test_db_path)
    api.document(CONTENT, filename='nome-distinto.csv')
    assert api.get('/previews') == [] and counts(test_db_path) == before
    again = read(api, source)
    assert counts(test_db_path)[:3] == (1, 5, 2)
    assert [r['import_id'] for r in api.get('/previews')] == [again['import_id']]


def test_segments_share_generation_and_cache_without_creating_extra_cards(api, test_db_path):
    from test_financial_e3 import HEADERS
    source = api.source('CREDIT_CARD')
    content = (HEADERS + f'{source["institution"]},Fatura Cartão de Crédito,Outubro/2026,,24/10/2026,"100,00",,,\n'
               + f'{source["institution"]},Fatura Cartão de Crédito,Novembro/2026,,24/11/2026,"50,00",,,\n').encode()
    root = read(api, source, content)
    def select(p, key):
        return api.post('/previews/' + p['id'] + '/select-segment', {
            **identity(p), 'expected_result_sha256': p['result_sha256'],
            'segment_key': key, 'source_id': source['id']})['preview']
    first, second = select(root, '1'), select(root, '2')
    assert first['import_id'] == second['import_id'] == root['import_id']
    assert len(api.get('/previews')) == 1
    before = counts(test_db_path)
    remove(api, root)
    again = read(api, source, content)
    child = select(again, '1')
    assert child['id'] == first['id'] and child['import_id'] != first['import_id']
    assert counts(test_db_path)[1] == before[1]
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('SELECT COUNT(DISTINCT import_id) FROM financial_import_entry_segments').fetchone()[0] == 2
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []
    other = read(api, source, CONTENT)
    with sqlite3.connect(test_db_path) as db:
        with pytest.raises(sqlite3.IntegrityError, match='segment belongs'):
            db.execute('INSERT INTO financial_import_entry_segments(import_id,segment_key,preview_id,parent_preview_id) VALUES (?,?,?,?)',
                (other['import_id'], '1', child['id'], other['id']))
        with pytest.raises(sqlite3.IntegrityError, match='invalid import metadata'):
            db.execute('UPDATE financial_import_entries SET root_preview_id=? WHERE id=?', (child['id'], other['import_id']))


def test_historical_item_command_does_not_mutate_reused_statement_in_new_generation(api, test_db_path):
    from test_financial_readers import preview, confirm
    source = api.source('BANK_ACCOUNT')
    content = b'Data;Valor;Descricao\n01/10/2026;-10,00;Movimento\n'
    p, _, _ = preview(api, source, content)
    statement = confirm(api, p, period_start='2026-10-01', period_end='2026-10-01')['statement']
    item = api.get('/statements/' + statement['id'] + '/items')[0]
    command = {**identity(p), 'action': 'NEW', 'reason': 'Movimento conferido'}
    remove(api, p)
    again, _, _ = preview(api, source, content)
    confirmed = confirm(api, again, period_start='2026-10-01', period_end='2026-10-01')['statement']
    assert confirmed['id'] == statement['id']
    stale = api.post('/items/' + item['id'] + '/review', command, expected=(409,))
    assert stale['detail']['error_code'] == 'FINANCIAL_IMPORT_GENERATION_CONFLICT'
    assert api.get('/transactions') == []
    result = api.post('/items/' + item['id'] + '/review', {**command, **identity(again)})
    assert result['transaction'] and counts(test_db_path)[3] == 0


def test_pdf_replay_and_reimport_reuse_read_cache_without_restoring_a_charge(api, test_db_path):
    from test_financial_pdf import card_pdf, upload_preview
    source = api.source('CREDIT_CARD')
    content = card_pdf()
    p, doc, request = upload_preview(api, source, content)
    remove(api, p)
    before = counts(test_db_path)
    again, same_doc, _ = upload_preview(api, source, content)
    assert same_doc['id'] == doc['id'] and again['id'] == p['id']
    assert again['generation'] == 2 and counts(test_db_path)[1] == before[1]
    assert again['recorded_payables_count'] == 0
    assert len(api.get('/previews')) == 1


@pytest.mark.parametrize('code,status', [('PDF_PASSWORD_REQUIRED', 422), ('PDF_PROCESSING_TIMEOUT', 503)])
def test_unfinished_pdf_read_does_not_persist_an_import(api, test_db_path, monkeypatch, code, status):
    from app.services import financial_previews
    from test_financial_pdf import card_pdf
    monkeypatch.setattr(financial_previews, 'extract_pdf', lambda *args, **kwargs: {'errors': [{'code': code}]})
    response = api.client.post('/api/v1/financial-imports/documents', params={'filename': 'protegido.pdf'},
        content=card_pdf(), headers={**api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())})
    doc = response.json()['document']
    source = api.source('CREDIT_CARD')
    failed = api.post('/documents/' + doc['id'] + '/previews', {
        'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto', 'expected_generation': 0},
        expected=(status,))
    assert failed['detail']['error_code'] == code
    assert counts(test_db_path)[:3] == (1, 0, 0)


def test_independently_changed_withdrawn_account_blocks_reinstatement(api, test_session):
    from app.models.financial import AccountPayable
    p = read(api, api.source('CREDIT_CARD'))
    command = {**identity(p), 'expected_source_id': p['source_id'], 'expected_result_sha256': p['result_sha256'],
        'expected_revision': 0, 'reference': '2026-10', 'due_on': '2026-10-24', 'total_amount_cents': 10000,
        'controls_confirmed': True, 'destination': 'OPEN', 'reason': 'Saldo devido conferido'}
    result = integrate(api, p, command)
    remove(api, p)
    title = test_session.get(AccountPayable, result['payable_id'])
    title.description = 'Conta alterada por decisão independente'
    test_session.commit()
    again = read(api, {'id': p['source_id']})
    denied = integrate(api, again, {**command, **identity(again), 'expected_revision': 1}, expected=(409,))
    assert denied['detail']['error_code'] == 'FINANCIAL_IMPORT_REINSTATEMENT_CONFLICT'
    assert api.client.get('/api/v1/payables', headers=api.headers).json() == []
