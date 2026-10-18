"""Comprehensive multibank reader test suite.

Validates:
1. CSV adapters for Nubank Card, Nu Empresas, Itaú, Santander, Inter, Mercado Pago, BB, Bradesco, Caixa.
2. Real user-provided samples: Nubank Card CSVs (2024-04 and 2026-03) and Nu Empresas PJ PDF (5 pages, 28 items).
3. Synthetic PDF card bill layouts for Itaú, Santander, and Banco Inter.
4. In-memory password decryption for protected PDFs.
5. End-to-end API preview and confirmation for multibank statements.
"""
import copy
import json
import os
import uuid
import pytest

from app.schemas.financial_readers import FinancialPreviewCreate
from app.services.financial_readers import READERS, parse_csv
from app.services import financial_pdf_readers as reader
from app.services import financial_previews
from test_financial_imports import FinancialAPI, PREFIX, books
from test_financial_pdf import pdf_bytes


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def test_multibank_csv_registered_readers_syntax_and_import():
    # 1. Nubank Card CSV
    nubank_card_data = (
        "date,title,amount\n"
        '2026-03-10,Posto Shell,"150,00"\n'
        '2026-03-12,Estorno Uber,"- 25,50"\n'
    ).encode("utf-8")
    res_nu_card = parse_csv(nubank_card_data, READERS["nubank_card_csv"].options)
    assert res_nu_card["errors"] == [] and len(res_nu_card["items"]) == 2
    assert res_nu_card["items"][0]["data"]["amount_cents"] == 15000
    assert res_nu_card["items"][1]["data"]["amount_cents"] == -2550

    # 2. Nu Empresas Account CSV
    nu_pj_data = (
        "Data,Valor,Identificador,Descrição\n"
        "10/08/2026,500.00,id-pj-1,Venda Cesta Basica\n"
        "11/08/2026,-120.50,id-pj-2,Pagamento Energia\n"
    ).encode("utf-8")
    res_nu_pj = parse_csv(nu_pj_data, READERS["nu_empresas_account_csv"].options)
    assert res_nu_pj["errors"] == [] and len(res_nu_pj["items"]) == 2
    assert res_nu_pj["items"][0]["data"]["amount_cents"] == 50000
    assert res_nu_pj["items"][1]["data"]["amount_cents"] == -12050
    assert res_nu_pj["items"][0]["data"]["external_id_namespace"] == "nubank:pj_account"

    # 3. Itaú Account CSV
    itau_acc_data = (
        "Data;Lançamento;Valor;Saldo\n"
        "15/07/2026;PIX RECEBIDO FORNECEDOR;1.250,50;1.250,50\n"
        "16/07/2026;PAGTO ELETRON COBRANCA;-350,00;900,50\n"
    ).encode("utf-8")
    res_itau_acc = parse_csv(itau_acc_data, READERS["itau_account_csv"].options)
    assert res_itau_acc["errors"] == [] and len(res_itau_acc["items"]) == 2
    assert res_itau_acc["items"][0]["data"]["amount_cents"] == 125050
    assert res_itau_acc["items"][1]["data"]["amount_cents"] == -35000

    # 4. Itaú Card CSV
    itau_card_data = (
        "Data;Lançamento;Valor\n"
        "20/07/2026;POSTO IPIRANGA;180,00\n"
        "21/07/2026;FARMACIA PRECO BAIXO;45,50\n"
    ).encode("utf-8")
    res_itau_card = parse_csv(itau_card_data, READERS["itau_card_csv"].options)
    assert res_itau_card["errors"] == [] and len(res_itau_card["items"]) == 2
    assert res_itau_card["items"][0]["data"]["amount_cents"] == 18000

    # 5. Santander Account CSV
    santander_acc_data = (
        "Data;Histórico;Documento;Valor;Saldo\n"
        "01/08/2026;TED RECEBIDA;DOC12345;2.000,00;2.000,00\n"
        "02/08/2026;TARIFA BANCARIA;DOC67890;-15,90;1.984,10\n"
    ).encode("utf-8")
    res_san_acc = parse_csv(santander_acc_data, READERS["santander_account_csv"].options)
    assert res_san_acc["errors"] == [] and len(res_san_acc["items"]) == 2
    assert res_san_acc["items"][0]["data"]["external_id"] == "DOC12345"

    # 6. Santander Card CSV
    santander_card_data = (
        "Data;Descricao;Valor\n"
        "05/08/2026;SUPERMERCADO ATACADO;450,00\n"
    ).encode("utf-8")
    res_san_card = parse_csv(santander_card_data, READERS["santander_card_csv"].options)
    assert res_san_card["errors"] == [] and len(res_san_card["items"]) == 1
    assert res_san_card["items"][0]["data"]["amount_cents"] == 45000

    # 7. Inter Account CSV
    inter_acc_data = (
        "Data Lançamento;Histórico;Valor\n"
        "10/08/2026;TRANSFERENCIA PIX;800,00\n"
        "11/08/2026;BOLETO PAGO;-200,00\n"
    ).encode("utf-8")
    res_inter_acc = parse_csv(inter_acc_data, READERS["inter_account_csv"].options)
    assert res_inter_acc["errors"] == [] and len(res_inter_acc["items"]) == 2

    # 8. Inter Card CSV
    inter_card_data = (
        "Data;Descricao;Valor\n"
        "15/08/2026;LOJA DE UTILIDADES;99,90\n"
    ).encode("utf-8")
    res_inter_card = parse_csv(inter_card_data, READERS["inter_card_csv"].options)
    assert res_inter_card["errors"] == [] and len(res_inter_card["items"]) == 1
    assert res_inter_card["items"][0]["data"]["amount_cents"] == 9990

    # 9. Mercado Pago CSV
    mp_data = (
        "Data;Descrição;Valor\n"
        "18/08/2026;Venda Mercado Livre;350,00\n"
        "19/08/2026;Tarifa Mercado Pago;-12,00\n"
    ).encode("utf-8")
    res_mp = parse_csv(mp_data, READERS["mercadopago_csv"].options)
    assert res_mp["errors"] == [] and len(res_mp["items"]) == 2

    # 10. Banco do Brasil CSV
    bb_data = (
        "Data;Historico;Numero do Documento;Valor;Saldo\n"
        "20/08/2026;CREDITO PIX;BB9988;1.500,00;1.500,00\n"
    ).encode("utf-8")
    res_bb = parse_csv(bb_data, READERS["bb_account_csv"].options)
    assert res_bb["errors"] == [] and len(res_bb["items"]) == 1

    # 11. Bradesco CSV
    bradesco_data = (
        "Data;Histórico;Docto.;Valor;Saldo\n"
        "22/08/2026;DEPOSITO DINHEIRO;BR1122;750,00;750,00\n"
    ).encode("utf-8")
    res_bra = parse_csv(bradesco_data, READERS["bradesco_account_csv"].options)
    assert res_bra["errors"] == [] and len(res_bra["items"]) == 1

    # 12. Caixa CSV
    caixa_data = (
        "Data Mov.;Nr. Doc.;Historico;Valor;Saldo\n"
        "25/08/2026;CX3344;RECEBIMENTO DIVERSOS;600,00;600,00\n"
    ).encode("utf-8")
    res_caixa = parse_csv(caixa_data, READERS["caixa_account_csv"].options)
    assert res_caixa["errors"] == [] and len(res_caixa["items"]) == 1


def test_real_user_uploaded_nubank_csv_card_samples():
    base_dir = r"C:\Users\jardi\.gemini\antigravity\brain\4485ce4a-3a32-4ccd-a304-69e667bbbc6f\scratch\financial_samples\CSV"
    sample_2024 = os.path.join(base_dir, "Nubank_2024-04-24.csv")
    sample_2026 = os.path.join(base_dir, "Nubank_2026-03-24.csv")

    if os.path.exists(sample_2024):
        with open(sample_2024, "rb") as f:
            content = f.read()
        res = parse_csv(content, READERS["nubank_card_csv"].options)
        assert res["errors"] == []
        assert len(res["items"]) == 21
        amounts = [i["data"]["amount_cents"] for i in res["items"]]
        assert any(a < 0 for a in amounts)
        assert any(a > 0 for a in amounts)

    if os.path.exists(sample_2026):
        with open(sample_2026, "rb") as f:
            content = f.read()
        res = parse_csv(content, READERS["nubank_card_csv"].options)
        assert res["errors"] == []
        assert len(res["items"]) == 13


def test_real_user_uploaded_nu_empresas_pdf_sample():
    sample_pdf = r"C:\Users\jardi\.gemini\antigravity\brain\4485ce4a-3a32-4ccd-a304-69e667bbbc6f\.user_uploaded\media_1792280384123_739df8ce.pdf"
    if not os.path.exists(sample_pdf):
        pytest.skip("Sample Nu Empresas PDF not available in local test environment")

    with open(sample_pdf, "rb") as f:
        content = f.read()

    report = reader.parse_local(content)
    assert report["errors"] == []
    assert report["detected_reader"] == "nubank_account_pdf_v1"
    assert report["detected_institution"] == "NUBANK"
    assert len(report["items"]) == 28

    header = report["extracted_header"]
    assert header["statement_type"] == "BANK_STATEMENT"
    assert header["period_start"] == "2026-08-18"
    assert header["period_end"] == "2026-10-16"
    assert header["opening_balance_cents"] == 403
    assert header["closing_balance_cents"] == 0
    assert header["total_inflows_cents"] == 1593551
    assert header["total_outflows_cents"] == 1593954

    checks = {c["code"]: c["matches"] for c in report["checks"]}
    assert checks["PDF_TOTAL_INFLOWS_CENTS"] is True
    assert checks["PDF_TOTAL_OUTFLOWS_CENTS"] is True
    assert checks["PDF_BALANCE_EQUATION"] is True


def test_multibank_pdf_card_bills_itau_santander_inter():
    # Itaú
    itau_pdf = pdf_bytes([[
        ("Itau Click MC Plat", None),
        ("Vencimento: 10/08/2026 Fechamento: 03/08/2026", None),
        ("Total da fatura", "150,00"),
        ("Pagamento minimo", "30,00"),
        ("Lancamentos", None),
        ("15/07 Posto Combustivel", "100,00"),
        ("16/07 Mercado Alimentos", "50,00"),
    ]])
    r_itau = reader.parse_local(itau_pdf)
    assert r_itau["errors"] == []
    assert r_itau["detected_reader"] == "itau_card_pdf_v1"
    assert r_itau["detected_institution"] == "ITAU"
    assert r_itau["extracted_header"]["total_amount_cents"] == 15000
    assert r_itau["extracted_header"]["due_on"] == "2026-08-10"
    assert len(r_itau["items"]) == 2
    assert all(c["matches"] for c in r_itau["checks"])

    # Santander
    santander_pdf = pdf_bytes([[
        ("Santander SX Visa", None),
        ("Vencimento: 30/01/2026 Fechamento: 24/01/2026", None),
        ("Total da fatura", "200,00"),
        ("Pagamento minimo", "40,00"),
        ("Demonstrativo", None),
        ("12/01 Fornecedor Exemplo", "120,00"),
        ("14/01 Farmacia", "80,00"),
    ]])
    r_santander = reader.parse_local(santander_pdf)
    assert r_santander["errors"] == []
    assert r_santander["detected_reader"] == "santander_card_pdf_v1"
    assert r_santander["detected_institution"] == "SANTANDER"
    assert r_santander["extracted_header"]["total_amount_cents"] == 20000
    assert r_santander["extracted_header"]["due_on"] == "2026-01-30"
    assert len(r_santander["items"]) == 2
    assert all(c["matches"] for c in r_santander["checks"])

    # Inter
    inter_pdf = pdf_bytes([[
        ("Banco Inter", None),
        ("Vencimento: 10/03/2026 Fechamento: 03/03/2026", None),
        ("Total da fatura", "300,00"),
        ("Pagamento minimo", "50,00"),
        ("Transacoes", None),
        ("20/02 Material Escritorio", "300,00"),
    ]])
    r_inter = reader.parse_local(inter_pdf)
    assert r_inter["errors"] == []
    assert r_inter["detected_reader"] == "inter_card_pdf_v1"
    assert r_inter["detected_institution"] == "INTER"
    assert r_inter["extracted_header"]["total_amount_cents"] == 30000
    assert r_inter["extracted_header"]["due_on"] == "2026-03-10"
    assert len(r_inter["items"]) == 1
    assert all(c["matches"] for c in r_inter["checks"])


def test_multibank_pdf_password_decryption_flow(monkeypatch):
    import pdfplumber
    from pdfminer.pdfdocument import PDFPasswordIncorrect

    real_open = pdfplumber.open

    def mock_open(*args, **kwargs):
        pwd = kwargs.get("password")
        if pwd == "secret123":
            return real_open(*args, **{k: v for k, v in kwargs.items() if k != "password"})
        raise PDFPasswordIncorrect("Password required or incorrect")

    monkeypatch.setattr(pdfplumber, "open", mock_open)

    dummy_pdf = pdf_bytes([[
        ("Banco Inter", None),
        ("Vencimento: 10/03/2026 Fechamento: 03/03/2026", None),
        ("Total da fatura", "100,00"),
        ("Transacoes", None),
        ("20/02 Loja", "100,00"),
    ]])

    # 1. No password provided: returns PDF_PASSWORD_REQUIRED
    res_no_pwd = reader.parse_local(dummy_pdf)
    assert res_no_pwd["errors"][0]["code"] == "PDF_PASSWORD_REQUIRED"

    # 2. Wrong password provided: returns PDF_PASSWORD_REQUIRED
    res_wrong_pwd = reader.parse_local(dummy_pdf, password="wrong")
    assert res_wrong_pwd["errors"][0]["code"] == "PDF_PASSWORD_REQUIRED"

    # 3. Correct password provided: successfully decrypts in memory and extracts
    res_ok = reader.parse_local(dummy_pdf, password="secret123")
    assert res_ok["errors"] == []
    assert res_ok["detected_reader"] == "inter_card_pdf_v1"
    assert len(res_ok["items"]) == 1


def test_multibank_preview_api_end_to_end(api, test_db_path):
    source = api.source("CREDIT_CARD")
    before = books(test_db_path)

    csv_content = (
        "Data;Lançamento;Valor\n"
        "05/09/2026;POSTO GASOLINA;150,00\n"
        "06/09/2026;MERCADO SUPER;250,00\n"
    ).encode("utf-8")

    doc = api.document(csv_content, filename="fatura_itau.csv")["document"]
    preview_res = api.post(f"/documents/{doc['id']}/previews", {
        "source_id": source["id"],
        "currency": "BRL",
        "reader_id": "itau_card_csv",
    })
    p = preview_res["preview"]
    assert p["status"] == "READY"
    assert p["items_count"] == 2
    assert p["totals"]["net_cents"] == 40000

    # Confirm statement
    statement_res = api.post(f"/previews/{p['id']}/confirm", {
        "expected_source_id": source["id"],
        "expected_result_sha256": p["result_sha256"],
        "statement_type": "CARD_BILL",
        "total_amount_cents": 40000,
        "due_on": "2026-09-20",
    })
    st = statement_res["statement"]
    assert st["preview_id"] == p["id"]
    assert st["total_amount_cents"] == 40000
    assert st["pending_count"] == 2

    # Ensure ledger is unchanged during staging
    assert books(test_db_path) == before
