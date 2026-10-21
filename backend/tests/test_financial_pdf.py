"""PDFs generated in memory: invented identities, no customer documents."""
import copy
import json
import sqlite3
import subprocess
import uuid

import pytest
from sqlalchemy import text

from app.core.backup import create_backup, restore_backup
from app.services import financial_pdf_readers as reader
from app.services import financial_pdf_runtime as runtime
from test_financial_imports import FinancialAPI, PREFIX, books


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def pdf_bytes(pages):
    """Small valid text PDF with exact layout/color, without another dependency."""
    objects = [b'<< /Type /Catalog /Pages 2 0 R >>', b'',
               b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>']
    kids = []
    for rows in pages:
        page_id = len(objects) + 1
        kids.append(f'{page_id} 0 R')
        stream = []
        for row in rows:
            label, amount, *color = row
            y = 760 - len(stream) * 22
            safe = label.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')
            stream.append(f'0 0 0 rg BT /F1 10 Tf 30 {y} Td ({safe}) Tj ET')
            if amount is not None:
                # Card table in PicPay lives in the left half of the page.
                x = 275 if label.startswith(('10/12', '11/12')) else 500
                rgb = color[0] if color else '0 0 0'
                stream[-1] += f' {rgb} rg BT /F1 10 Tf {x} {y} Td ({amount}) Tj ET'
        content = '\n'.join(stream).encode('cp1252')
        objects.extend([f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Resources << /Font << /F1 3 0 R >> >> /Contents {page_id+1} 0 R >>'.encode(),
                        f'<< /Length {len(content)} >>\nstream\n'.encode() + content + b'\nendstream'])
    objects[1] = f'<< /Type /Pages /Kids [{" ".join(kids)}] /Count {len(kids)} >>'.encode()
    result, offsets = b'%PDF-1.4\n', [0]
    for i, obj in enumerate(objects, 1):
        offsets.append(len(result))
        result += f'{i} 0 obj\n'.encode() + obj + b'\nendobj\n'
    start = len(result)
    result += f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode()
    result += b''.join(f'{offset:010d} 00000 n \n'.encode() for offset in offsets[1:])
    return result + f'trailer\n<< /Root 1 0 R /Size {len(objects)+1} >>\nstartxref\n{start}\n%%EOF'.encode()


def card_pdf(bank='NUBANK', mismatch=False, color='0.42353 0.75686 0.0549'):
    if bank == 'NUBANK':
        return pdf_bytes([[('Nubank FATURA 10 AGO 2025', None), ('DE 10 JUL A 10 AGO', None),
                           ('Resumo da fatura atual', None), ('Fatura anterior', '0,00'),
                           ('Pagamento recebido', '-5,00'), ('Total de compras', '10,00'),
                           ('Outros lançamentos', '0,00'), ('Total a pagar', '5,00'),
                           ('Pagamento mínimo', '1,00'), ('Transações', None),
                           ('10 JUL Loja exemplo - 1/2', '10,00' if not mismatch else '10,01'),
                           ('11 JUL Crédito exemplo', '5,00', color)]])
    return pdf_bytes([[('PicPay Vencimento: 25-12-2025 Fechamento: 18-12-2025', None),
                       ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'),
                       ('Despesas do mês', '10,00'), ('Créditos e estornos', '0,00'), ('Total da fatura', '5,00')],
                      [('Transações Nacionais', None), ('10/12 Loja exemplo PARC01/02', '10,00'),
                       ('11/12 Crédito exemplo', '-5,00')]])


def account_pdf():
    period = ('01 DE JULHO DE 2025 a 31 DE JULHO DE 2025 VALORES EM R$', None)
    return pdf_bytes([[('Nu Pagamentos', None), period, ('Saldo inicial', '0,00'),
                       ('Total de entradas', '+10,00'), ('Total de saídas', '-5,00'),
                       ('Saldo final do período', '5,00'), ('Movimentações', None),
                       ('14 JUL 2025 Total de entradas', '+10,00'), ('Transferência recebida', '10,00'),
                       ('Total de saídas', '-5,00'), ('Tem alguma dúvida?', None)],
                      [('Nu Pagamentos', None), ('Empresa exemplo', None), period, ('Pagamento de fatura', '5,00')]])


def upload_preview(api, source, content, **changes):
    response = api.client.post(PREFIX + '/documents', params={'filename': 'synthetic.pdf'}, content=content,
                               headers={**api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())})
    assert response.status_code in (200, 201), response.text
    doc = response.json()['document']
    state = api.get('/documents/' + doc['id'] + '/import-state')
    request = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto',
        'expected_generation': state['current_generation'],
        **({'explicit_reprocess':True,'expected_root_preview_id':state['root_preview_id']}
           if state['active_import'] else {}), **changes}
    return api.post('/documents/' + doc['id'] + '/previews', request)['preview'], doc, request


def confirm(api, preview, **changes):
    expected = changes.pop('expected', (200, 201))
    return api.post('/previews/' + preview['id'] + '/confirm', {
        'import_id':preview['import_id'],'expected_generation':preview['generation'],
        'expected_source_id': preview['source_id'], 'expected_result_sha256': preview['result_sha256'],
        'statement_type': preview['extracted_header']['statement_type'], **changes,
    }, expected=expected)


@pytest.mark.parametrize('bank,year', [('NUBANK', '2025-07-10'), ('PICPAY', '2025-12-10')])
def test_pdf_auto_multibank_preserves_original_evidence_and_never_posts_payments(api, test_db_path, bank, year):
    source = api.source('CREDIT_CARD')
    before = books(test_db_path)
    content = card_pdf(bank)
    preview, doc, request = upload_preview(api, source, content)
    assert preview['status'] == 'READY' and preview['items_count'] == 2
    assert preview['detected_institution'] == bank and preview['affects_ledger'] is False
    assert all(c['matches'] for c in preview['checks'])
    assert 'pages' not in preview and 'items' not in preview and 'result' not in preview
    items = api.get('/previews/' + preview['id'] + '/items')
    assert [i['data']['amount_cents'] for i in items] == [1000, -500]
    assert items[0]['data']['transaction_date'] == year
    assert items[0]['data']['installment_number'] == 1
    assert all(i['data']['transaction_time'] is None and i['data']['purchase_date'] is None for i in items)
    assert api.get('/previews/' + preview['id'] + '/pages?limit=1')[0]['page_number'] == 1
    assert api.client.get(PREFIX + '/documents/' + doc['id'] + '/content', headers=api.headers).content == content
    replay = api.post('/documents/' + doc['id'] + '/previews', request)
    assert replay['duplicate'] and replay['preview']['id'] == preview['id']
    staged = confirm(api, preview)['statement']
    assert staged['total_amount_cents'] == 500 and staged['due_on'] == preview['extracted_header']['due_on']
    pending = api.get('/statements/' + staged['id'] + '/items')
    assert all(i['page_number'] and i['raw_text'] for i in pending)
    assert api.get('/transactions') == [] and books(test_db_path) == before
    assert confirm(api, preview)['duplicate']


def test_pdf_account_carries_direction_date_across_page_and_excludes_repeated_headers(api):
    preview, _, _ = upload_preview(api, api.source(), account_pdf())
    assert preview['status'] == 'READY', api.get('/previews/' + preview['id'] + '/errors')
    items = api.get('/previews/' + preview['id'] + '/items')
    assert [i['page_number'] for i in items] == [1, 2]
    assert [i['data']['amount_cents'] for i in items] == [1000, -500]
    assert all(i['data']['transaction_date'] == '2025-07-14' for i in items)
    assert 'Empresa exemplo' not in items[0]['raw_text']
    assert confirm(api, preview)['statement']['closing_balance_cents'] == 500


@pytest.mark.parametrize('content,code', [
    (pdf_bytes([[('Documento privado de outro layout', None)]]), 'PDF_LAYOUT_UNSUPPORTED'),
    (pdf_bytes([[]]), 'PDF_OCR_OR_TEXT_REQUIRED'),
    (b'%PDF-1.4\nmalformed private data', 'PDF_INVALID_OR_UNREADABLE'),
    (card_pdf(mismatch=True), 'PDF_SUMMARY_DETAIL_MISMATCH'),
    (card_pdf(color='1 0 0'), 'PDF_AMOUNT_SIGN_AMBIGUOUS'),
])
def test_bad_unknown_or_ambiguous_pdf_cannot_confirm_or_echo_data_in_errors(api, content, code):
    p, _, _ = upload_preview(api, api.source('CREDIT_CARD'), content)
    assert p['status'] == 'INVALID'
    errors = api.get('/previews/' + p['id'] + '/errors')
    assert code in {e['code'] for e in errors}
    assert 'private' not in json.dumps(errors) and 'Documento privado' not in json.dumps(errors)
    assert api.post('/previews/' + p['id'] + '/confirm', {'expected_source_id': p['source_id'],
        'expected_result_sha256': p['result_sha256'], 'statement_type': 'CARD_BILL'}, expected=(409,))
    assert api.get('/statements') == []
    if code == 'PDF_LAYOUT_UNSUPPORTED':
        assert 'Documento privado' in api.get('/previews/' + p['id'] + '/pages')[0]['text']


def test_source_type_and_header_contradictions_block_confirmation(api):
    p, _, _ = upload_preview(api, api.source(), card_pdf())
    assert p['status'] == 'INVALID'
    assert api.get('/previews/' + p['id'] + '/errors')[0]['code'] == 'PDF_SOURCE_TYPE_MISMATCH'
    p, _, _ = upload_preview(api, api.source('CREDIT_CARD'), card_pdf())
    for changed in ({'total_amount_cents': 501}, {'due_on': '2025-08-11'}, {'statement_type': 'BANK_STATEMENT'}):
        assert confirm(api, p, **changed, expected=(409,))['detail']['error_code'] == 'FINANCIAL_PDF_HEADER_CONFLICT'


def test_pdf_worker_runs_before_write_lock_and_cached_result_never_reextracts(api, test_engine, monkeypatch):
    from app.services import financial_previews
    real = financial_previews.extract_pdf
    calls = []
    def outside_lock(content):
        # The engine's begin listener itself issues BEGIN IMMEDIATE.
        with test_engine.begin() as connection:
            connection.execute(text('SELECT 1'))
        calls.append(True)
        return real(content)
    monkeypatch.setattr(financial_previews, 'extract_pdf', outside_lock)
    p, doc, request = upload_preview(api, api.source('CREDIT_CARD'), card_pdf())
    api.post('/documents/' + doc['id'] + '/previews', request)
    assert calls == [True]
    assert api.get('/previews/' + p['id'])['status'] == 'READY'


def test_pdf_pages_are_authenticated_paginated_and_noncacheable(api):
    p, _, _ = upload_preview(api, api.source('CREDIT_CARD'), card_pdf('PICPAY'))
    path = PREFIX + '/previews/' + p['id'] + '/pages'
    assert api.client.get(path).status_code == 401
    assert api.client.get(path + '?limit=41', headers=api.headers).status_code == 422
    assert api.get('/previews/' + p['id'] + '/pages?offset=1&limit=1')[0]['page_number'] == 2
    response = api.client.get(path, headers=api.headers)
    assert response.headers['cache-control'] == 'no-store'


def test_pdf_backup_restores_original_pages_checks_and_item_provenance(api, test_db_path, tmp_path):
    content = card_pdf('PICPAY')
    p, doc, _ = upload_preview(api, api.source('CREDIT_CARD'), content)
    statement = confirm(api, p)['statement']
    backup, restored = tmp_path / 'pdf.db', tmp_path / 'pdf-restored.db'
    create_backup(source_path=test_db_path, destination_path=backup)
    restore_backup(backup, target_path=restored)
    with sqlite3.connect(restored) as db:
        assert db.execute('SELECT content FROM financial_documents WHERE id=?', (doc['id'],)).fetchone()[0] == content
        report = json.loads(db.execute('SELECT result FROM financial_import_previews WHERE id=?', (p['id'],)).fetchone()[0])
        assert len(report['pages']) == 2 and all(c['matches'] for c in report['checks'])
        assert db.execute('SELECT page_number FROM financial_statement_items WHERE statement_id=? ORDER BY position', (statement['id'],)).fetchall() == [(2,), (2,)]
        assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall() == []


def test_worker_timeout_and_failure_are_sanitized_and_release_slot(monkeypatch):
    def timeout(*args, **kwargs):
        raise subprocess.TimeoutExpired('private command', 20, output=b'private')
    monkeypatch.setattr(runtime.subprocess, 'run', timeout)
    result = runtime.extract_pdf(b'%PDF-private')
    assert result['errors'][0]['code'] == 'PDF_PROCESSING_TIMEOUT' and not result['complete']
    assert 'private' not in json.dumps(result)
    monkeypatch.setattr(runtime.subprocess, 'run', lambda *a, **kw: subprocess.CompletedProcess([], 1, b'private'))
    assert runtime.extract_pdf(b'')['errors'][0]['code'] == 'PDF_PROCESSING_FAILED'


def test_busy_worker_and_frozen_runtime_are_explicit(monkeypatch):
    runtime.WORKERS.acquire()
    try:
        assert runtime.extract_pdf(b'')['errors'][0]['code'] == 'PDF_PROCESSING_BUSY'
    finally:
        runtime.WORKERS.release()
    monkeypatch.setattr(runtime.sys, 'frozen', True, raising=False)
    assert runtime.extract_pdf(b'')['errors'][0]['code'] == 'PDF_RUNTIME_UNAVAILABLE'


def test_transient_worker_failure_does_not_cache_invalid_preview(api, monkeypatch):
    from app.services import financial_previews
    real = financial_previews.extract_pdf
    failed = reader.empty_report()
    reader.error(failed, 'PDF_PROCESSING_TIMEOUT')
    monkeypatch.setattr(financial_previews, 'extract_pdf', lambda c: copy.deepcopy(failed))
    source = api.source('CREDIT_CARD')
    response = api.client.post(PREFIX + '/documents', params={'filename': 'retry.pdf'}, content=card_pdf(), headers={
        **api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())})
    doc = response.json()['document']
    request = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto'}
    assert api.post('/documents/' + doc['id'] + '/previews', request, expected=(503,))['detail']['error_code'] == 'PDF_PROCESSING_TIMEOUT'
    assert api.get('/previews') == []
    monkeypatch.setattr(financial_previews, 'extract_pdf', real)
    assert api.post('/documents/' + doc['id'] + '/previews', request)['preview']['status'] == 'READY'


def test_pdf_page_and_content_limits(monkeypatch):
    monkeypatch.setattr(reader, 'MAX_PAGES', 1)
    r = reader.parse_local(card_pdf('PICPAY'))
    assert r['errors'][0]['code'] == 'PDF_PAGE_LIMIT' and not r['complete']
    monkeypatch.setattr(reader, 'MAX_PAGES', 40)
    monkeypatch.setattr(reader, 'MAX_CHARS', 5)
    r = reader.parse_local(card_pdf())
    assert r['errors'][0]['code'] == 'PDF_CONTENT_LIMIT' and not r['complete']


def test_pdf_password_required_does_not_echo_password_or_pdf(monkeypatch):
    import pdfplumber
    from pdfminer.pdfdocument import PDFPasswordIncorrect
    def password(*args, **kwargs):
        raise PDFPasswordIncorrect('private password')
    monkeypatch.setattr(pdfplumber, 'open', password)
    result = reader.parse_local(b'%PDF-private')
    assert result['errors'][0]['code'] == 'PDF_PASSWORD_REQUIRED' and 'private' not in json.dumps(result)


def test_pdf_minimum_payment_columns_and_summary_provenance():
    content = pdf_bytes([[('PicPay Vencimento: 25-12-2025 Fechamento: 18-12-2025', None),
        ('Pagamento mínimo Pagamento total', None), ('1,00 5,00', None),
        ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'), ('Despesas do mês', '10,00'),
        ('Créditos e estornos', '0,00'), ('Total da fatura', '5,00')],
        [('Transações Nacionais', None), ('10/12 Loja', '10,00'), ('11/12 Crédito', '-5,00')]])
    result = reader.parse_local(content)
    assert result['errors'] == [] and result['extracted_header']['minimum_payment_cents'] == 100
    assert result['reported_summary']['payments'] == -500
    assert result['field_sources']['summary.payments']['page_number'] == 1


def test_unrecognized_money_rows_cannot_hide_behind_balanced_totals():
    # Two unsupported rows cancel out: global totals alone cannot detect loss.
    content = pdf_bytes([[('PicPay Vencimento: 25-12-2025 Fechamento: 18-12-2025', None),
        ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'), ('Despesas do mês', '10,00'),
        ('Créditos e estornos', '0,00'), ('Total da fatura', '5,00')],
        [('Transações Nacionais', None), ('10/12 Loja', '10,00'), ('11/12 Crédito', '-5,00'),
         ('Linha com data em outro formato', '3,00'), ('Outra linha em formato desconhecido', '-3,00')]])
    result = reader.parse_local(content)
    assert all(c['matches'] for c in result['checks'])
    assert [e['code'] for e in result['errors']] == ['PDF_UNPARSED_MONEY_ROW', 'PDF_UNPARSED_MONEY_ROW']


def test_nubank_named_purchase_heading_is_checked_as_section_control():
    content = pdf_bytes([[('Nubank FATURA 10 AGO 2025', None), ('DE 10 JUL A 10 AGO', None),
        ('Resumo da fatura atual', None), ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'),
        ('Total de compras', '10,00'), ('Outros lançamentos', '0,00'), ('Total a pagar', '5,00'),
        ('Transações', None), ('Pessoa fictícia', 'R$10,00'), ('10 JUL •••• 1234 Loja', 'R$10,00'),
        ('Pagamentos e Financiamentos', '-R$5,00'), ('11 JUL Crédito', '-R$5,00')]])
    result = reader.parse_local(content)
    assert result['errors'] == []
    assert len(result['items']) == 2 and result['items'][0]['data']['card_last_four'] == '1234'
    assert [s['matches'] for s in result['section_controls']] == [True, True]


@pytest.mark.parametrize('minimum', ['-1,00', '6,00'])
def test_pdf_inconsistent_minimum_payment_is_blocked_before_confirmation(minimum):
    content = pdf_bytes([[('PicPay Vencimento: 25-12-2025 Fechamento: 18-12-2025', None),
        ('Pagamento mínimo Pagamento total', None), (minimum + ' 5,00', None),
        ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'), ('Despesas do mês', '10,00'),
        ('Créditos e estornos', '0,00'), ('Total da fatura', '5,00')],
        [('Transações Nacionais', None), ('10/12 Loja', '10,00'), ('11/12 Crédito', '-5,00')]])
    result = reader.parse_local(content)
    assert result['errors'] == [{'code': 'PDF_INVALID_HEADER_OR_ITEMS', 'page_number': None, 'fields': []}]


def test_period_evidence_points_to_its_actual_page_instead_of_bill_cover():
    content = pdf_bytes([[('Nubank FATURA 10 AGO 2025', None), ('Resumo da fatura atual', None),
        ('Fatura anterior', '0,00'), ('Pagamento recebido', '-5,00'), ('Total de compras', '10,00'),
        ('Outros lançamentos', '0,00'), ('Total a pagar', '5,00')],
        [('Transações de 10 JUL a 10 AGO', None), ('10 JUL Loja', '10,00'), ('11 JUL Crédito', '-5,00')]])
    result = reader.parse_local(content)
    assert result['errors'] == []
    assert result['field_sources']['period_start']['page_number'] == 2
    assert result['field_sources']['due_on']['page_number'] == 1


def test_device_revoked_during_pdf_extraction_cannot_write_preview(api, test_engine, monkeypatch):
    from app.services import financial_previews
    real = financial_previews.extract_pdf
    def revoke(content):
        report = real(content)
        with test_engine.begin() as connection:
            connection.execute(text('UPDATE paired_devices SET is_active=0'))
        return report
    monkeypatch.setattr(financial_previews, 'extract_pdf', revoke)
    source = api.source('CREDIT_CARD')
    doc = api.client.post(PREFIX + '/documents', params={'filename': 'synthetic.pdf'}, content=card_pdf(), headers={
        **api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())}).json()['document']
    assert api.post('/documents/' + doc['id'] + '/previews', {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto'},
                    expected=(401,))['detail']['error_code'] == 'FINANCIAL_AUTH_REQUIRED'
    with test_engine.connect() as connection:
        assert connection.execute(text('SELECT COUNT(*) FROM financial_import_previews')).scalar() == 0


def test_pdf_optional_bill_assessment_validates_effective_extracted_header(api):
    source = api.source('CREDIT_CARD')
    p, doc, _ = upload_preview(api, source, card_pdf())
    reference = pdf_bytes([[('Referencia manual ficticia', None)]])
    response = api.client.post(PREFIX + '/documents', params={'filename': 'reference.pdf'}, content=reference,
        headers={**api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())})
    ref = response.json()['document']
    header = {'due_on': '2025-08-10', 'total_amount_cents': 500, 'period_start': '2025-07-10', 'period_end': '2025-08-10'}
    common = {'source_id': source['id'], 'currency': 'BRL', 'identity_reason': 'Referencia sintetica conferida', 'header': header, 'page_number': 1}
    assessment = api.post('/previews/' + p['id'] + '/bill-assessments', {
        'expected_revision': 0, 'expected_source_id': source['id'], 'expected_result_sha256': p['result_sha256'],
        'reason': 'Conferencia manual sintetica', 'header': header,
        'evidence': [{**common, 'document_id': doc['id'], 'role': 'HEADER'},
                     {**common, 'document_id': ref['id'], 'role': 'DETAILS', 'items': [
                         {'preview_position': 1, 'transaction_date': '2025-07-10', 'amount_cents': 1000, 'description': 'Loja exemplo - 1/2'},
                         {'preview_position': 2, 'transaction_date': '2025-07-11', 'amount_cents': -500, 'description': 'Crédito exemplo'}]}],
    })['assessment']
    assert assessment['status'] == 'VERIFIED'
    # No repeated manual header is needed; it comes from this PDF's preview.
    staged = confirm(api, p, assessment_id=assessment['id'])
    assert staged['assessment_id'] == assessment['id']
    assert staged['statement']['total_amount_cents'] == 500
