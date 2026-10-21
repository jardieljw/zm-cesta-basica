"""Audit evidence, not acceptance tests: assertions reproduce CURRENT defects.

Run separately with backend/tests on PYTHONPATH and -p conftest. Every write
uses the repository's isolated test fixtures. No company files are inputs.
Passing means the described defect reproduced; it does NOT approve importing.
"""
import uuid

import pytest
from sqlalchemy import func, select

from app.models.financial import AccountPayable, CashFlowEntry
from app.services import financial_pdf_readers as pdf
from app.services.financial_readers import READERS, parse_csv
from test_financial_imports import FinancialAPI, PREFIX
from test_financial_pdf import pdf_bytes, upload_preview
from test_financial_semantic_obligations import setup_card_statement


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def review(api, statement, items, categories):
    return api.post(f"/statements/{statement['id']}/semantic-reviews", {
        "expected_revision": 0,
        "items": [{"item_id": item['id'], "semantic_category": category}
                  for item, category in zip(items, categories)],
    })


def test_AUD01_tabular_invents_due_total_and_silently_skips_unread_row():
    content = pdf_bytes([[('Fatura compilada de exemplo', None),
        ('date title amount', None), ('2026-10-01 Loja A 10,00', None),
        ('2026-10-02 Loja B 5,OO', None)]])
    result = pdf.parse_local(content)
    assert result['errors'] == []
    assert len(result['items']) == 1
    assert result['extracted_header']['due_on'] == '2026-10-01'
    assert result['extracted_header']['total_amount_cents'] == 1000
    assert result['checks'] == []


def test_AUD02_csv_debit_indicator_is_ignored_and_amount_becomes_credit():
    content = 'Data;Lançamento;Valor;Tipo\n01/10/2026;Compra;100,00;D\n'.encode()
    result = parse_csv(content, READERS['itau_account_csv'].options)
    assert result['errors'] == []
    assert result['items'][0]['data']['amount_cents'] == 10000
    assert result['warnings'][0]['code'] == 'UNMAPPED_COLUMNS_PRESERVED_IN_ORIGINAL'


def test_AUD03_four_cent_difference_is_turned_into_unreported_charge(api):
    _, _, statement, items = setup_card_statement(api,
        b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10004, '2026-10-20')
    result = review(api, statement, items, ['PURCHASE_BUSINESS'])
    assert result['is_balanced'] is True
    assert result['equation_difference_cents'] == 0
    assert result['financial_charges_cents'] == 4


def test_AUD04_refund_does_not_reduce_generated_payables(api):
    _, _, statement, items = setup_card_statement(api,
        b'date,title,amount\n2026-10-01,Loja,"100,00"\n2026-10-02,Estorno,"-20,00"\n',
        8000, '2026-10-20')
    result = review(api, statement, items, ['PURCHASE_BUSINESS', 'REFUND_CREDIT'])
    assert result['is_balanced'] is True
    obligations = api.post(f"/statements/{statement['id']}/generate-obligations", {})['obligations']
    assert sum(o['amount_cents'] for o in obligations) == 10000
    assert sum(o['amount_cents'] for o in obligations) != statement['total_amount_cents']


def test_AUD05_previous_outstanding_balance_has_no_obligation(api):
    _, _, statement, items = setup_card_statement(api,
        b'date,title,amount\n2026-10-01,Saldo anterior,"100,00"\n2026-10-02,Loja,"20,00"\n',
        12000, '2026-10-20')
    result = review(api, statement, items, ['PREVIOUS_BALANCE', 'PURCHASE_BUSINESS'])
    assert result['is_balanced'] is True
    obligations = api.post(f"/statements/{statement['id']}/generate-obligations", {})['obligations']
    assert sum(o['amount_cents'] for o in obligations) == 2000


def test_AUD06_ignored_bank_item_still_posts_to_cash_book(api, test_session):
    source = api.source()
    statement, items, _ = api.stage(source, [{
        'transaction_date': '2026-10-01', 'amount_cents': -500,
        'description': 'Linha descartada pelo operador'}])
    api.review(items[0], action='IGNORE')
    result = api.post(f"/statements/{statement['id']}/post-to-treasury", {})
    assert result['entries_posted'] == 1
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)
        .where(CashFlowEntry.source_type == 'BANK_IMPORT')) == 1


def test_AUD07_overlapping_files_without_ids_both_post_same_fact(api, test_session):
    source = api.source()
    data = {'transaction_date': '2026-10-01', 'amount_cents': 500,
            'description': 'Mesma evidencia em PDF e CSV'}
    for _ in range(2):
        statement, _, _ = api.stage(source, [data])
        assert api.post(f"/statements/{statement['id']}/post-to-treasury", {})['entries_posted'] == 1
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)
        .where(CashFlowEntry.source_type == 'BANK_IMPORT')) == 2


def test_AUD08_transfer_is_classified_as_revenue_without_review(api, test_session):
    source = api.source()
    statement, _, _ = api.stage(source, [{
        'transaction_date': '2026-10-01', 'amount_cents': 500,
        'description': 'Transferencia entre minhas contas', 'transaction_kind': 'TRANSFER'}])
    api.post(f"/statements/{statement['id']}/post-to-treasury", {})
    test_session.rollback()
    entry = test_session.scalar(select(CashFlowEntry).where(CashFlowEntry.source_type == 'BANK_IMPORT'))
    assert entry.category == 'RECEITA'
    assert entry.nature == 'BUSINESS'


def test_AUD09_wrong_password_preview_is_reused_for_correct_password(api, monkeypatch):
    calls = []
    def extract(content, password=None):
        calls.append(password)
        result = pdf.empty_report()
        result['errors'] = [{'code': 'PDF_PASSWORD_REQUIRED'}]
        return result
    monkeypatch.setattr('app.services.financial_previews.extract_pdf', extract)
    source = api.source('CREDIT_CARD')
    result, document, request = upload_preview(api, source,
        pdf_bytes([[('Documento sintetico', None)]]), password='wrong-synthetic')
    retry = api.post('/documents/' + document['id'] + '/previews',
        {**request, 'password': 'correct-synthetic'})['preview']
    assert retry['id'] == result['id']
    assert calls == ['wrong-synthetic']


def test_AUD10_bank_name_in_counterparty_can_trigger_wrong_pdf_adapter():
    content = pdf_bytes([[('Banco Exemplo - FATURA', None),
        ('Compras internacionais - Transacoes', None)]])
    result = pdf.parse_local(content)
    assert result['detected_institution'] == 'INTER'
    assert result['errors']


def test_AUD11_reference_date_replaces_actual_transaction_date_in_tabular_pdf():
    content = pdf_bytes([[('Fatura compilada', None),
        ('FATURA_REFERENCIA DATA_LANCAMENTO DESCRICAO VALOR_RS', None),
        ('2026-10-20 2026-10-01 Loja exemplo 10,00', None)]])
    result = pdf.parse_local(content)
    assert result['errors'] == []
    assert result['items'][0]['data']['transaction_date'] == '2026-10-20'
    assert '2026-10-01' in result['items'][0]['data']['description']


def test_AUD12_two_billing_cycles_are_combined_under_first_due_date():
    content = pdf_bytes([[('Fatura Vencimento 20/10/2026', None),
        ('date title amount', None), ('2026-10-01 Loja A 10,00', None),
        ('Fatura Vencimento 20/11/2026', None),
        ('date title amount', None), ('2026-11-01 Loja B 20,00', None)]])
    result = pdf.parse_local(content)
    assert result['errors'] == []
    assert len(result['items']) == 2
    assert result['extracted_header']['due_on'] == '2026-10-20'
    assert result['extracted_header']['total_amount_cents'] == 3000


def test_AUD13_tabular_document_reports_statement_type_as_source_type(api):
    source = api.source('CREDIT_CARD')
    result, _, _ = upload_preview(api, source, pdf_bytes([[
        ('Fatura Vencimento 20/10/2026', None), ('date title amount', None),
        ('2026-10-01 Loja A 10,00', None)]]))
    assert result['detected_source_type'] == 'CARD_BILL'
    assert result['status'] == 'INVALID'
    errors = api.get('/previews/' + result['id'] + '/errors')
    assert any(e['code'] == 'PDF_SOURCE_TYPE_MISMATCH' for e in errors)


def test_AUD14_obligations_can_use_old_review_after_current_review_is_unbalanced(api):
    _, _, statement, items = setup_card_statement(api,
        b'date,title,amount\n2026-10-01,Loja,"100,00"\n', 10000, '2026-10-20')
    old = review(api, statement, items, ['PURCHASE_BUSINESS'])
    current = api.post(f"/statements/{statement['id']}/semantic-reviews", {
        'expected_revision': 1,
        'items': [{'item_id': items[0]['id'], 'semantic_category': 'CONTEXT_ONLY'}],
    })
    assert current['status'] == 'DRAFT'
    obligations = api.post(f"/statements/{statement['id']}/generate-obligations",
        {'review_id': old['id']})['obligations']
    assert len(obligations) == 1
