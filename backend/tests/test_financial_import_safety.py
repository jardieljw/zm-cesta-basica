"""Regression requirements for the financial import audit, using isolated DBs."""
import datetime
from dataclasses import replace
import uuid
import pytest
from sqlalchemy import func, select
from app.models.financial import AccountPayable, CashFlowEntry
from app.services import financial_pdf_readers as pdf
from app.services.financial_readers import READERS, parse_csv
from test_financial_imports import FinancialAPI, PREFIX
from test_financial_pdf import pdf_bytes, card_pdf, upload_preview
from test_financial_semantic_obligations import setup_card_statement
from test_financial_readers import preview, confirm
from app.models.purchases import Purchase


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def classify(api, statement, items, categories, revision=0):
    return api.post(f"/statements/{statement['id']}/semantic-reviews", {
        'expected_revision': revision,
        'items': [{'item_id': i['id'], 'semantic_category': c} for i, c in zip(items, categories)],
    })


def test_tabular_keeps_missing_controls_absent_and_flags_unread_rows():
    result = pdf.parse_local(pdf_bytes([[('Fatura compilada', None), ('date title amount', None),
        ('2026-10-01 Loja A 10,00', None), ('2026-10-02 Loja B 5,OO', None)]]))
    assert len(result['items']) == 1
    assert 'due_on' not in result['extracted_header']
    assert 'total_amount_cents' not in result['extracted_header']
    assert 'period_start' not in result['extracted_header']
    assert {'PDF_UNPARSED_MONEY_ROW', 'PDF_BILL_HEADER_REQUIRED'}.issubset({e['code'] for e in result['errors']})


def test_tabular_explicit_controls_work_for_single_cycle_and_correct_source(api):
    content = pdf_bytes([[('Fatura Vencimento 20/10/2026', None), ('date title amount', None),
                         ('2026-10-01 Loja A 10,00', None), ('Total da fatura 10,00', None)]])
    result, _, _ = upload_preview(api, api.source('CREDIT_CARD'), content)
    assert result['status'] == 'READY'
    assert result['reader_version'] == '4'
    assert result['detected_source_type'] == 'CREDIT_CARD'
    assert result['extracted_header']['due_on'] == '2026-10-20'
    assert all(c['matches'] for c in result['checks'])


def test_compilation_preserves_actual_date_and_blocks_multiple_cycles():
    result = pdf.parse_local(pdf_bytes([[('Fatura compilada', None),
        ('FATURA_REFERENCIA DATA_LANCAMENTO DESCRICAO VALOR_RS', None),
        ('2026-10-20 2026-10-01 Loja A 10,00', None),
        ('2026-11-20 2026-11-01 Loja B 20,00', None)]]))
    assert [i['data']['transaction_date'] for s in result['segments'] for i in s['items']] == ['2026-10-01', '2026-11-01']
    assert result['segments'][0]['items'][0]['data']['description'] == 'Loja A'
    assert result['content_type'] == 'MULTI_CYCLE_COMPILATION' and len(result['segments']) == 2


def test_two_explicit_due_dates_block_combined_bill():
    result = pdf.parse_local(pdf_bytes([[('Fatura Vencimento 20/10/2026', None), ('date title amount', None),
        ('2026-10-01 Loja A 10,00', None), ('Fatura Vencimento 20/11/2026', None),
        ('date title amount', None), ('2026-11-01 Loja B 20,00', None)]]))
    assert result['content_type'] == 'MULTI_CYCLE_COMPILATION' and len(result['segments']) == 2
    assert {s['extracted_header']['due_on'] for s in result['segments']} == {'2026-10-20','2026-11-20'}


def test_csv_direction_column_cannot_be_silently_discarded():
    result = parse_csv('Data;Lançamento;Valor;Tipo\n01/10/2026;Compra;100,00;D\n'.encode(), READERS['itau_account_csv'].options)
    assert not result['items']
    assert result['errors'][0]['code'] == 'CSV_DIRECTION_MAPPING_REQUIRED'


@pytest.mark.parametrize('delta', [-10, -4, -1, 1, 4, 10])
def test_every_cent_difference_remains_visible_without_invented_charge(api, delta):
    _, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000 + delta, '2026-10-20')
    review = classify(api, st, items, ['PURCHASE_BUSINESS'])
    assert review['status'] == 'DRAFT'
    assert review['equation_difference_cents'] == delta
    assert review['financial_charges_cents'] == 0
    assert api.post(f"/statements/{st['id']}/generate-obligations", {}, expected=(409,))['detail']['error_code'] == 'BILL_REVIEW_NOT_BALANCED'


@pytest.mark.parametrize('content,total,categories', [
    (b'date,title,amount\n2026-10-01,Loja,"100,00"\n2026-10-02,Estorno,"-20,00"\n', 8000, ['PURCHASE_BUSINESS', 'REFUND_CREDIT']),
    (b'date,title,amount\n2026-10-01,Saldo anterior,"100,00"\n2026-10-02,Loja,"20,00"\n', 12000, ['PREVIOUS_BALANCE', 'PURCHASE_BUSINESS']),
    (b'date,title,amount\n2026-10-01,Saldo anterior,"100,00"\n2026-10-02,Pagamento,"-100,00"\n2026-10-03,Loja,"20,00"\n', 2000,
     ['PREVIOUS_BALANCE', 'BILL_PAYMENT', 'PURCHASE_BUSINESS']),
])
def test_unallocated_credits_or_previous_balance_create_no_partial_debt(api, test_session, content, total, categories):
    _, _, st, items = setup_card_statement(api, content, total, '2026-10-20')
    assert classify(api, st, items, categories)['is_balanced']
    response = api.post(f"/statements/{st['id']}/generate-obligations", {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_BILL_ALLOCATION_REQUIRED'
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(AccountPayable)) == 0


def test_current_ignored_decision_never_posts_money(api, test_session):
    st, items, _ = api.stage(api.source(), [{'transaction_date': '2026-10-01', 'amount_cents': -500, 'description': 'Ignorado'}])
    api.review(items[0], action='IGNORE')
    assert api.post(f"/statements/{st['id']}/post-to-treasury", {})['entries_posted'] == 0
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)) == 0


def test_overlapping_bank_evidence_and_transfers_never_auto_post(api, test_session):
    source = api.source()
    for _ in range(2):
        st, _, _ = api.stage(source, [{'transaction_date': '2026-10-01', 'amount_cents': 500,
                                     'description': 'Transferencia propria', 'transaction_kind': 'TRANSFER'}])
        assert api.post(f"/statements/{st['id']}/post-to-treasury", {}, expected=(409,))['detail']['error_code'] == 'FINANCIAL_CASH_REVIEW_REQUIRED'
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)) == 0


def test_wrong_password_does_not_poison_correct_password_retry(api, monkeypatch):
    calls = []
    content = card_pdf()
    def extract(data, password=None):
        calls.append(password)
        if password == 'correct-synthetic':
            return pdf.parse_local(data)
        report = pdf.empty_report()
        report['errors'] = [{'code': 'PDF_PASSWORD_REQUIRED'}]
        return report
    monkeypatch.setattr('app.services.financial_previews.extract_pdf', extract)
    source = api.source('CREDIT_CARD')
    response = api.client.post(PREFIX + '/documents', params={'filename': 'example.pdf'}, content=content,
                              headers={**api.headers, 'Content-Type': 'application/pdf', 'X-Idempotency-Key': str(uuid.uuid4())})
    document = response.json()['document']
    payload = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto', 'password': 'wrong-synthetic'}
    result = api.post('/documents/' + document['id'] + '/previews', payload, expected=(422,))
    assert result['detail']['error_code'] == 'PDF_PASSWORD_REQUIRED'
    payload['password'] = 'correct-synthetic'
    result = api.post('/documents/' + document['id'] + '/previews', payload)['preview']
    assert result['status'] == 'READY'
    assert calls == ['wrong-synthetic', 'correct-synthetic']


def test_international_word_is_not_bank_inter():
    result = pdf.parse_local(pdf_bytes([[('Banco Exemplo - FATURA', None), ('Compras internacionais - Transacoes', None)]]))
    assert result.get('detected_institution') is None
    assert result['errors'][0]['code'] == 'PDF_LAYOUT_UNSUPPORTED'


def test_old_approved_review_cannot_override_current_draft(api):
    _, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000, '2026-10-20')
    old = classify(api, st, items, ['PURCHASE_BUSINESS'])
    classify(api, st, items, ['CONTEXT_ONLY'], revision=1)
    response = api.post(f"/statements/{st['id']}/generate-obligations", {'review_id': old['id']}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_BILL_REVISION_CONFLICT'


def test_credit_cannot_be_classified_as_positive_purchase(api):
    _, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Credito,"-10,00"\n', -1000, '2026-10-20')
    result = api.post(f"/statements/{st['id']}/semantic-reviews", {
        'expected_revision': 0, 'items': [{'item_id': items[0]['id'], 'semantic_category': 'PURCHASE_BUSINESS'}],
    }, expected=(409,))
    assert result['detail']['error_code'] == 'FINANCIAL_BILL_CATEGORY_SIGN'


def test_readers_advertise_card_capability_and_reject_stale_version(api):
    readers = api.get('/readers')
    assert next(r for r in readers if r['id'] == 'nubank_card_csv')['source_types'] == ['CREDIT_CARD']
    source = api.source()
    document = api.document()['document']
    result = api.post('/documents/' + document['id'] + '/previews', {
        'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto', 'expected_reader_version': '1',
    }, expected=(422,))
    assert result['detail']['error_code'] == 'INVALID_FINANCIAL_DATA'


@pytest.mark.parametrize('controls', [
    {'total_inflows_cents': 1},
    {'total_outflows_cents': 4999},
    {'opening_balance_cents': 10000, 'closing_balance_cents': 5001},
])
def test_csv_declared_bank_controls_are_checked_without_silent_adjustment(api, controls):
    p, _, _ = preview(api, api.source(), b'Data;Valor;Descricao\n01/10/2026;-50,00;Compra\n')
    result = confirm(api, p, expected=(409,), **controls)
    assert result['detail']['error_code'] == 'FINANCIAL_IMPORT_CONTROL_MISMATCH'
    assert api.get('/statements') == []


def test_csv_controls_keep_operator_provenance_and_optional_absence(api):
    p, _, _ = preview(api, api.source(), b'Data;Valor;Descricao\n01/10/2026;-50,00;Compra\n')
    result = confirm(api, p, period_start='2026-10-01', period_end='2026-10-31',
                     opening_balance_cents=10000, closing_balance_cents=5000)
    assert result['statement']['total_inflows_cents'] is None
    events = api.get('/audit?entity_id=' + p['id'])
    event = next(e for e in events if e['event_type'] == 'IMPORT_HEADER_DECLARED')
    assert event['details']['origin'] == 'OPERATOR_DECLARATION'
    assert event['details']['fields']['closing_balance_cents'] == 5000
    assert 'total_inflows_cents' not in event['details']['fields']


def test_older_reader_preview_cannot_authorize_new_debt_but_history_remains(api, monkeypatch):
    _, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000, '2026-10-20')
    classify(api, st, items, ['PURCHASE_BUSINESS'])
    monkeypatch.setitem(READERS, 'generic_csv', replace(READERS['generic_csv'], version='next-test-version'))
    response = api.post(f"/statements/{st['id']}/generate-obligations", {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_REIMPORT_REQUIRED'
    assert len(api.get(f"/statements/{st['id']}/items")) == 1
    assert api.get(f"/statements/{st['id']}/obligations") == []


def test_second_document_same_card_and_due_date_cannot_duplicate_debt(api):
    source, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000, '2026-10-20')
    classify(api, st, items, ['PURCHASE_BUSINESS'])
    existing = api.post(f"/statements/{st['id']}/generate-obligations", {})
    p, _, _ = preview(api, source, b'date,title,amount\n2026-10-01,Outra descricao,"100,00"\n',
                      opts={'columns': {'transaction_date': 'date', 'amount': 'amount', 'description': 'title'},
                            'delimiter': ',', 'date_format': 'YYYY-MM-DD', 'decimal_separator': ',',
                            'amount_convention': 'CHARGES_POSITIVE'})
    other = confirm(api, p, statement_type='CARD_BILL', due_on='2026-10-20', total_amount_cents=10000)['statement']
    other_items = api.get(f"/statements/{other['id']}/items")
    classify(api, other, other_items, ['PURCHASE_BUSINESS'])
    response = api.post(f"/statements/{other['id']}/generate-obligations", {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_BILL_CYCLE_ALREADY_REPRESENTED'
    replay = api.post(f"/statements/{st['id']}/generate-obligations", {})
    assert [(o['id'], o['account_payable_id'], o['amount_cents']) for o in replay['obligations']] == [
        (o['id'], o['account_payable_id'], o['amount_cents']) for o in existing['obligations']]


@pytest.mark.parametrize('status', ['PAID', 'CANCELED', 'MISSING'])
def test_link_to_paid_canceled_or_missing_purchase_payable_creates_no_new_debt(api, test_session, status):
    purchase = Purchase(id=str(uuid.uuid4()), purchase_number=999, status='CONFIRMED',
                        total_amount_cents=10000, payment_method='CARTAO_CREDITO')
    test_session.add(purchase)
    if status != 'MISSING':
        test_session.add(AccountPayable(id=str(uuid.uuid4()), payable_number=888,
            description='Titulo existente', beneficiary='Fornecedor', category='FORNECEDOR', nature='BUSINESS',
            original_amount_cents=10000, balance_cents=0 if status == 'PAID' else 10000,
            paid_amount_cents=10000 if status == 'PAID' else 0,
            due_date=datetime.datetime(2026, 10, 20), payment_method='CARTAO_CREDITO',
            status=status, purchase_id=purchase.id))
    test_session.commit()
    _, _, st, items = setup_card_statement(api, b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000, '2026-10-20')
    api.post(f"/statements/{st['id']}/semantic-reviews", {'expected_revision': 0,
        'items': [{'item_id': items[0]['id'], 'semantic_category': 'PURCHASE_BUSINESS', 'purchase_id': purchase.id}]})
    response = api.post(f"/statements/{st['id']}/generate-obligations", {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_PURCHASE_ALLOCATION_REQUIRED'
    assert api.get(f"/statements/{st['id']}/obligations") == []
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(AccountPayable)) == (0 if status == 'MISSING' else 1)
