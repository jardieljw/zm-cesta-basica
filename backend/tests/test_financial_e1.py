"""E1/T01–T07: synthetic evidence, isolated API, exact cents and no posting."""
import pytest

from app.services.financial_normalization import installment_facts
from app.services.financial_readers import READERS, parse_csv, detect_csv
from app.services.financial_pdf_readers import parse_local
from app.services.financial_preview_contract import enrich_report
from test_financial_imports import FinancialAPI, books
from test_financial_readers import preview
from test_financial_pdf import pdf_bytes, card_pdf, upload_preview


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


@pytest.mark.parametrize('text,expected', [
    ('Loja - 1/1', (1, 1)), ('Loja - 3/10', (3, 10)), ('Loja Parcela 10/10', (10, 10)),
    ('Loja PARC01/02', (1, 2)), ('Compra 3/10', None), ('Loja 01/02/2026', None),
])
def test_t03_shared_installment_grammar(text, expected):
    result = installment_facts(text)
    assert tuple(result.values()) == expected if expected else not result


@pytest.mark.parametrize('text', ['Loja - 0/3', 'Loja - 4/3', 'Loja PARC01/00', 'Loja - 1/1001'])
def test_t03_invalid_installment_is_rejected(text):
    with pytest.raises(ValueError):
        installment_facts(text)


def test_t02_t03_t05_csv_preserves_sign_description_multiplicity_and_unknown_purpose():
    content = ('date,title,amount\n2026-01-02,Loja - 3/10,"10,01"\n'
               '2026-01-02,Loja - 3/10,"10,01"\n'
               '2026-01-03,Pagamento recebido,"- 5,00"\n'
               '2026-01-03,Estorno exemplo,"-1,00"\n'
               '2026-01-03,Juros de mora,"0,01"\n').encode()
    result = detect_csv(content, 'CREDIT_CARD')
    assert not result['errors']
    assert [i['data']['amount_cents'] for i in result['items']] == [1001, 1001, -500, -100, 1]
    assert [i['role'] for i in result['items']] == ['PURCHASE', 'PURCHASE', 'PAYMENT', 'CREDIT', 'CHARGE']
    assert all(i['purpose'] == 'UNSPECIFIED' for i in result['items'])
    assert result['items'][0]['data']['description'] == 'Loja - 3/10'
    assert result['items'][0]['data']['installment_number'] == 3
    assert '- 5,00' in result['items'][2]['raw_text']


def test_t03_column_installment_conflict_is_not_silently_overwritten():
    options = READERS['nubank_card_csv'].options.model_copy(deep=True)
    options.columns.installment_number = 'atual'
    options.columns.total_installments = 'total'
    result = parse_csv(b'date,title,amount,atual,total\n2026-01-02,Loja - 3/10,"10,00",2,10\n', options)
    assert result['errors'][0]['code'] == 'CSV_INVALID_ROW'
    assert not result['items']


@pytest.mark.parametrize('source_type', ['BANK_ACCOUNT', 'CREDIT_CARD'])
def test_t01_summary_content_precedes_bank_reader_and_never_becomes_transactions(source_type):
    result = detect_csv(b'Instituicao,Tipo_Documento,Referencia_Mes_Ano\nBanco,Fatura,2026-01\n', source_type)
    assert result['content_type'] == 'SUMMARY_INDEX'
    assert result['errors'] == [] and len(result['segments']) == 1
    assert result['segments'][0]['items'] == []
    assert not result['items']


def test_t01_account_reader_not_forced_on_card_and_unknown_has_no_nubank_fallback():
    content = 'Data;Descrição;Valor\n02/01/2026;Compra;10,00\n'.encode()
    result = detect_csv(content, 'CREDIT_CARD')
    assert not result['items'] and result['errors'][0]['code'] == 'FINANCIAL_READER_AMBIGUOUS'
    assert detect_csv(b'foo,bar\nx,y\n', 'CREDIT_CARD')['detected_reader'] is None


@pytest.mark.parametrize('holder,reader', [('PF', 'nubank_account_csv'), ('PJ', 'nu_empresas_account_csv')])
def test_t01_selected_bank_source_disambiguates_namespace_only_after_header_match(holder, reader):
    content = 'Data,Valor,Identificador,Descrição\n02/01/2026,10.01,synthetic-id,Transferencia\n'.encode()
    result = detect_csv(content, 'BANK_ACCOUNT', institution='NUBANK', holder_type=holder)
    assert not result['errors'] and result['detected_reader'] == reader
    assert result['items'][0]['data']['amount_cents'] == 1001
    ambiguous = detect_csv(content, 'BANK_ACCOUNT')
    assert ambiguous['errors'][0]['code'] == 'FINANCIAL_READER_AMBIGUOUS'


def contract(report):
    return enrich_report(report, document_id='synthetic', reader_id='pdf_auto', reader_version='3', source_type='CREDIT_CARD')


def test_t04_csv_no_due_no_declared_total_and_calculated_sum_stays_calculated(api, test_db_path):
    source = api.source('CREDIT_CARD')
    before = books(test_db_path)
    p, _, _ = preview(api, source, b'date,title,amount\n2026-01-02,Loja,"10,00"\n', reader='csv_auto')
    assert p['source_id'] == source['id']
    assert p.get('extracted_header', {}) == {}
    assert p['readiness']['total_basis'] == 'CALCULATED_ONLY'
    assert p['readiness']['header_status'] == 'MISSING'
    assert not p['readiness']['can_prepare_bill']
    assert not p['readiness']['can_generate_obligations']
    assert books(test_db_path) == before


def test_t02_controls_offers_and_subtotals_are_not_purchases():
    result = detect_csv(('date,title,amount\n2026-01-02,Loja,"10,00"\n'
                         ',Total da fatura,"10,00"\n,Pagamento mínimo,"1,00"\n'
                         ',Oferta,"3,00"\n,Subtotal,"10,00"\n').encode(), 'CREDIT_CARD')
    assert len(result['items']) == 1
    assert [c['kind'] for c in result['controls']] == ['TOTAL', 'MINIMUM', 'OFFER', 'SUBTOTAL']
    assert result['totals']['net_cents'] == 1000


def test_t06_complete_header_vs_detail_pending_one_cent_no_compensation():
    balanced = contract(parse_local(card_pdf()))
    assert balanced['readiness']['header_status'] == 'DOCUMENT_VALIDATED'
    assert balanced['readiness']['details_status'] == 'RECONCILED'
    assert balanced['readiness']['can_prepare_complete_details']
    different = contract(parse_local(card_pdf(mismatch=True)))
    assert different['readiness']['difference_cents'] == 1
    assert different['readiness']['can_prepare_bill']
    assert not different['readiness']['can_prepare_complete_details']
    assert len(different['items']) == 2
    assert different['items'][0]['data']['amount_cents'] == 1001
    assert all(c['document_id'] == 'synthetic' and c['reader_version'] == '3' for c in different['controls'])


def test_t07_all_due_candidates_preserved_and_no_operational_date_chosen():
    content = pdf_bytes([[('Nubank FATURA 24 OUT 2026', None),
        ('Data de vencimento: 26 OUT 2026', None), ('Resumo da fatura atual', None),
        ('Total a pagar', '10,00'), ('Transações', None), ('01 OUT Loja - 1/1', '10,00')]])
    result = contract(parse_local(content))
    assert {c['value'] for c in result['header_candidates']['due_on']} == {'2026-10-24', '2026-10-26'}
    assert 'due_on' not in result['extracted_header']
    assert result['readiness']['header_status'] == 'CONFLICTING'
    assert not result['readiness']['can_prepare_bill']
    assert 'FINANCIAL_DUE_DATE_CONFLICT' in {e['code'] for e in result['errors']}
    assert all(c['page_number'] == 1 and c['raw_text'] for c in result['header_candidates']['due_on'])


def test_t01_pdf_incompatible_institution_keeps_selected_source(api):
    source = api.post('/sources', {'name': 'Cartao sintético', 'institution': 'SANTANDER',
        'source_type': 'CREDIT_CARD', 'holder_type': 'PF', 'currency': 'BRL'})
    p, _, _ = upload_preview(api, source, card_pdf())
    assert p['source_id'] == source['id'] and p['status'] == 'INVALID'
    assert 'FINANCIAL_INSTITUTION_MISMATCH' in {e['code'] for e in api.get('/previews/' + p['id'] + '/errors')}


def test_t04_compatible_control_complement_is_bound_to_source_cycle_and_provenance(api, test_db_path):
    source = api.source('CREDIT_CARD')
    before = books(test_db_path)
    control, _, _ = upload_preview(api, source, card_pdf())
    csv = b'date,title,amount\n2025-07-10,Loja exemplo - 1/2,"10,00"\n2025-07-11,Credito exemplo,"-5,00"\n'
    p, doc, _ = preview(api, source, csv, reader='csv_auto', control_preview_id=control['id'], cycle_due_on='2025-08-10')
    assert p['readiness']['header_status'] == 'OPERATOR_DECLARED'
    assert p['extracted_header']['due_on'] == '2025-08-10'
    assert p['control_complement']['preview_id'] == control['id']
    assert any(c['document_id'] == control['document_id'] and c['field'] == 'total_amount_cents' for c in p['controls'])
    assert not p['readiness']['can_prepare_complete_details']
    conflict = api.post('/previews/' + p['id'] + '/confirm', {
        'expected_source_id': source['id'], 'expected_result_sha256': p['result_sha256'],
        'statement_type': 'CARD_BILL', 'total_amount_cents': 501,
    }, expected=(409,))
    assert conflict['detail']['error_code'] == 'FINANCIAL_PDF_HEADER_CONFLICT'
    for changes in ({}, {'cycle_due_on': '2025-09-10'}):
        bad = api.post('/documents/' + doc['id'] + '/previews', {'source_id': source['id'], 'currency': 'BRL',
            'reader_id': 'csv_auto', 'control_preview_id': control['id'], **changes}, expected=(409,))
        assert bad['detail']['error_code'] == 'FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE'
    assert books(test_db_path) == before


def test_complement_rejects_another_card_even_same_institution(api):
    first, second = api.source('CREDIT_CARD'), api.source('CREDIT_CARD')
    control, _, _ = upload_preview(api, first, card_pdf())
    doc = api.document(b'date,title,amount\n2025-07-10,Loja,"10,00"\n')['document']
    result = api.post('/documents/' + doc['id'] + '/previews', {'source_id': second['id'], 'currency': 'BRL',
        'reader_id': 'csv_auto', 'control_preview_id': control['id'], 'cycle_due_on': '2025-08-10'}, expected=(409,))
    assert result['detail']['error_code'] == 'FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE'
