"""Multibank CSV evidence; all records and identifiers here are synthetic."""
import copy
import json
import sqlite3
from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.backup import create_backup, restore_backup
from app.schemas.financial_readers import CSVOptions
from app.services.financial_readers import CSVReader, READERS, money_cents
from test_financial_imports import FinancialAPI, PREFIX, books


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def options(**changes):
    return {"columns": {"transaction_date": "Data", "amount": "Valor", "description": "Descricao"},
            "date_format": "DD/MM/YYYY", "decimal_separator": ",", "delimiter": ";",
            "amount_convention": "CREDITS_POSITIVE", **changes}


def preview(api, source, content, *, opts=None, reader="generic_csv", **fields):
    document = api.document(content)["document"]
    request = {"source_id": source["id"], "currency": source["currency"], "reader_id": reader, **fields}
    if reader == "generic_csv":
        request["options"] = opts or options()
    return api.post("/documents/" + document["id"] + "/previews", request)["preview"], document, request


def confirm(api, result, **fields):
    expected = fields.pop("expected", (200, 201))
    return api.post("/previews/" + result["id"] + "/confirm", {
        "expected_source_id": result["source_id"], "expected_result_sha256": result["result_sha256"],
        "statement_type": "BANK_STATEMENT", **fields,
    }, expected=expected)


def test_known_layout_is_only_one_adapter_and_import_never_changes_books(api, test_db_path):
    source = api.source()
    before = books(test_db_path)
    content = ('\ufeffData,Valor,Identificador,Descrição\r\n'
               '10/07/2025,-50.00,synthetic-a,"Fornecedor, exemplo"\r\n'
               '10/07/2025,-50.00,synthetic-b,"Fornecedor, exemplo"\r\n').encode()
    p, doc, request = preview(api, source, content, reader="nubank_account_csv")
    assert p["status"] == "READY" and p["reader_version"] == "1" and p["items_count"] == 2
    assert p["totals"] == {"positive_cents": 0, "negative_cents": 10000, "net_cents": -10000}
    assert p["observed_dates"] == {"first": "2025-07-10", "last": "2025-07-10"}
    assert "items" not in p and "result" not in p
    assert {"generic_csv", "nubank_account_csv", "pdf_auto"}.issubset({r["id"] for r in api.get("/readers")})
    replay = api.post("/documents/" + doc["id"] + "/previews", request)
    assert replay["duplicate"] and replay["preview"]["id"] == p["id"]
    staged = confirm(api, p)["statement"]
    assert staged["preview_id"] == p["id"] and staged["pending_count"] == 2
    assert not api.get("/transactions")
    assert confirm(api, p)["duplicate"]
    items = api.get("/statements/" + staged["id"] + "/items")
    txs = [api.review(i)["transaction"] for i in items]
    assert txs[0]["id"] != txs[1]["id"]
    assert all(t["transaction_time"] is None for t in txs)
    assert books(test_db_path) == before
    current = api.get("/previews/" + p["id"] + "/items")
    assert all(i["candidates"][0]["basis"] == "EXTERNAL_ID" for i in current)
    assert api.get("/previews/" + p["id"] + "/items?limit=1&offset=1")[0]["position"] == 2


def test_other_bank_mapping_preserves_dates_time_full_id_and_raw_multiline_text(api):
    source = api.source()
    external_id = "s" * 255
    content = ('Dia;Quantia;Historico;Referencia;Compra;Efetivacao;Hora;Outra\r\n'
               f'11/07/2025;-1.234,56;"Fornecedor\r\n  exemplo";{external_id};10/07/2025;11/07/2025;14:23;Original\r\n').encode("cp1252")
    opts = options(encoding="cp1252", thousands_separator=".", date_kind="BOOKING", external_id_namespace="bank:reference",
                   columns={"transaction_date": "Dia", "amount": "Quantia", "description": "Historico", "external_id": "Referencia",
                            "purchase_date": "Compra", "booking_date": "Efetivacao", "transaction_time": "Hora"})
    p, _, _ = preview(api, source, content, opts=opts)
    assert p["status"] == "READY"
    assert p["warnings"] == [{"code": "UNMAPPED_COLUMNS_PRESERVED_IN_ORIGINAL", "count": 1}]
    row = api.get("/previews/" + p["id"] + "/items")[0]
    assert (row["line_start"], row["line_end"]) == (2, 3)
    assert '"Fornecedor\r\n  exemplo"' in row["raw_text"]
    statement = confirm(api, p)["statement"]
    item = api.get("/statements/" + statement["id"] + "/items")[0]
    tx = api.review(item)["transaction"]
    assert (tx["amount_cents"], tx["purchase_date"], tx["booking_date"]) == (-123456, "2025-07-10", "2025-07-11")
    assert tx["transaction_time"] == "14:23" and tx["utc_offset_minutes"] is None
    assert tx["external_id"] == external_id


def test_generic_card_requires_explicit_sign_and_reported_bill_header(api, test_db_path):
    source = api.source("CREDIT_CARD")
    before = books(test_db_path)
    p, _, _ = preview(api, source, b"Data;Valor;Descricao\n10/07/2025;-200,00;Compra\n11/07/2025;50,00;Credito\n",
                      opts=options(amount_convention="CHARGES_NEGATIVE", date_kind="PURCHASE"))
    rows = api.get("/previews/" + p["id"] + "/items")
    assert [r["data"]["amount_cents"] for r in rows] == [20000, -5000]
    assert confirm(api, p, statement_type="CARD_BILL", expected=(422,))["detail"]["error_code"] == "FINANCIAL_IMPORT_HEADER_INVALID"
    statement = confirm(api, p, statement_type="CARD_BILL", due_on="2025-08-10", total_amount_cents=16000)["statement"]
    # The bank's reported bill amount is not fabricated from the imported lines.
    assert statement["total_amount_cents"] == 16000
    for item in api.get("/statements/" + statement["id"] + "/items"):
        api.review(item)
    assert books(test_db_path) == before


@pytest.mark.parametrize("content,code", [
    (b"Data;Valor;Descricao\n10/07/2025;-1.001;Documento privado\n", "CSV_INVALID_ROW"),
    (b"Data;Valor;Descricao\n10/07/2025;-1,001;Documento privado\n", "CSV_INVALID_ROW"),
    (b"Data;Valor;Descricao\n31/02/2025;-1,00;Documento privado\n", "CSV_INVALID_ROW"),
    (b"Data;Valor;Descricao\n7/10/2025;-1,00;Documento privado\n", "CSV_INVALID_ROW"),
    (b"Data;Valor;Descricao\n10/07/2025;0,00;Documento privado\n", "CSV_INVALID_ROW"),
    (b"Data;Valor;Descricao\n10/07/2025;1,00\n", "CSV_ROW_SHAPE"),
    (b"Data;Valor;Descricao\n10/07/2025;1,00;\xff\n", "CSV_ENCODING"),
    (b"Data;Valor;Descricao\n10/07/2025;1,00;\x00\n", "CSV_CONTROL_CHARACTER"),
    (b"Data;Valor;Descricao\n10/07/2025;1,00;\"broken\n", "CSV_SYNTAX"),
    (b"Data;Valor;Descricao;Data\n10/07/2025;1,00;x;x\n", "CSV_HEADER"),
    (b"Outra;Valor;Descricao\n10/07/2025;1,00;x\n", "CSV_LAYOUT_MISMATCH"),
    (b"Data;Valor;Descricao\n", "CSV_NO_TRANSACTIONS"),
])
def test_invalid_files_block_whole_confirmation_without_echoing_values(api, content, code):
    p, _, _ = preview(api, api.source(), content)
    assert p["status"] == "INVALID"
    errors = api.get("/previews/" + p["id"] + "/errors")
    assert errors[0]["code"] == code
    assert "Documento privado" not in json.dumps(errors)
    assert confirm(api, p, expected=(409,))["detail"]["error_code"] == "FINANCIAL_PREVIEW_INVALID"
    assert api.get("/statements") == []


def test_reprocessing_corrects_interpretation_in_new_preview_and_keeps_invalid_one(api, test_engine):
    source = api.source()
    content = b"Data;Valor;Descricao\n10/07/2025;-12.34;Fornecedor\n"
    invalid, doc, _ = preview(api, source, content)
    fixed, _, _ = preview(api, source, content, opts=options(decimal_separator="."))
    assert invalid["status"] == "INVALID" and fixed["status"] == "READY"
    assert invalid["id"] != fixed["id"] and invalid["document_id"] == fixed["document_id"] == doc["id"]
    assert len(api.get("/previews?document_id=" + doc["id"] + "&source_id=" + source["id"])) == 2
    assert api.get("/previews/" + invalid["id"])["status"] == "INVALID"
    assert api.get("/audit?entity_id=" + fixed["id"])[0]["event_type"] == "IMPORT_PREVIEW_CREATED"
    for sql in ("UPDATE financial_import_previews SET status='READY'", "DELETE FROM financial_import_previews"):
        with pytest.raises(IntegrityError), test_engine.begin() as connection:
            connection.execute(text(sql))


def test_repeated_ids_missing_columns_and_changed_known_layout_stay_invalid(api):
    source = api.source()
    opts = options(columns={"transaction_date": "Data", "amount": "Valor", "description": "Descricao", "external_id": "Id"},
                   external_id_namespace="bank:transaction")
    p, _, _ = preview(api, source, b"Data;Valor;Descricao;Id\n10/07/2025;1,00;x;a\n10/07/2025;1,00;x;a\n", opts=opts)
    assert api.get("/previews/" + p["id"] + "/errors")[0]["code"] == "CSV_REPEATED_EXTERNAL_ID"
    p, _, _ = preview(api, source, "Data,Valor,Identificador,Descrição,Saldo\n10/07/2025,1.00,a,x,10.00\n".encode(), reader="nubank_account_csv")
    assert p["status"] == "INVALID"


def test_overlapping_imports_reuse_same_bank_id_but_other_sources_do_not(api):
    source, other = api.source(), api.source()
    opts = options(columns={"transaction_date": "Data", "amount": "Valor", "description": "Descricao", "external_id": "Id"},
                   external_id_namespace="bank:transaction")
    transaction_ids = []
    for target, content in [(source, b"Data;Valor;Descricao;Id\n10/07/2025;-1,00;x;a\n"),
                            (source, b"Data;Valor;Descricao;Id\n10/07/2025;-1,00;x;a\n\n"),
                            (other, b"Data;Valor;Descricao;Id\n10/07/2025;-1,00;x;a\n")]:
        p, _, _ = preview(api, target, content, opts=opts)
        s = confirm(api, p)["statement"]
        item = api.get("/statements/" + s["id"] + "/items")[0]
        transaction_ids.append(api.review(item)["transaction"]["id"])
    assert transaction_ids[0] == transaction_ids[1] != transaction_ids[2]
    conflict, _, _ = preview(api, source, b"Data;Valor;Descricao;Id\n10/07/2025;-2,00;x;a\n", opts=opts)
    assert api.get("/previews/" + conflict["id"] + "/items")[0]["candidates"][0]["basis"] == "EXTERNAL_ID_CONFLICT"
    s = confirm(api, conflict)["statement"]
    item = api.get("/statements/" + s["id"] + "/items")[0]
    assert api.post("/items/" + item["id"] + "/review", {"action": "NEW", "reason": "Conferido"}, expected=(409,))
    assert len(api.get("/transactions")) == 2


def test_confirmation_binds_source_hash_and_header_and_idempotency(api):
    p, doc, request = preview(api, api.source(), b"Data;Valor;Descricao\n10/07/2025;1,00;x\n")
    assert confirm(api, p, expected_source_id="another-source", expected=(409,))["detail"]["error_code"] == "FINANCIAL_IMPORT_SOURCE_MISMATCH"
    assert confirm(api, p, expected_result_sha256="0" * 64, expected=(409,))["detail"]["error_code"] == "FINANCIAL_PREVIEW_CHANGED"
    assert confirm(api, p, period_start="2025-07-31", period_end="2025-07-01", expected=(422,))
    path = "/documents/" + doc["id"] + "/previews"
    api.post(path, request, key="preview-key")
    changed = copy.deepcopy(request)
    changed["options"]["date_kind"] = "BOOKING"
    assert api.post(path, changed, key="preview-key", expected=(409,))["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"


def test_limits_and_valid_rows_do_not_hide_failed_rows(api):
    source = api.source()
    p, _, _ = preview(api, source, b"Data;Valor;Descricao\n10/07/2025;1,00;x\n10/07/2025;invalid;secret\n")
    assert p["items_count"] == 1 and p["errors_count"] == 1 and p["rows_read"] == 2
    assert confirm(api, p, expected=(409,))
    p, _, _ = preview(api, source, b"Data;Valor;Descricao\n" + b"10/07/2025;1,00;x\n" * 2001)
    assert p["items_count"] == 2000 and not p["complete"] and p["status"] == "INVALID"
    assert api.client.get(PREFIX + "/previews/" + p["id"] + "/items?limit=501", headers=api.headers).status_code == 422
    p, _, _ = preview(api, source, b"Data;Valor;Descricao\n" + b"x" * 8001)
    assert p["status"] == "INVALID" and not p["complete"]


def test_unknown_time_and_formula_looking_description_are_plain_evidence(api):
    p, _, _ = preview(api, api.source(), 'Data;Valor;Descricao\n10/07/2025;0,01;=1+1\n\n10/07/2025;0,10;Texto\u2028original\n'.encode())
    rows = api.get("/previews/" + p["id"] + "/items")
    assert p["status"] == "READY" and p["blank_records"] == 1
    assert p["totals"]["net_cents"] == 11
    assert rows[0]["data"]["description"] == "=1+1" and rows[0]["data"]["transaction_time"] is None
    assert "Texto\u2028original" in rows[1]["raw_text"]


def test_parallel_preview_and_confirmation_have_one_result(api):
    source = api.source()
    doc = api.document(b"Data;Valor;Descricao\n10/07/2025;1,00;x\n")["document"]
    request = {"source_id": source["id"], "currency": "BRL", "reader_id": "generic_csv", "options": options()}
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: api.post("/documents/" + doc["id"] + "/previews", request), range(2)))
    assert results[0]["preview"]["id"] == results[1]["preview"]["id"]
    with ThreadPoolExecutor(max_workers=2) as pool:
        statements = list(pool.map(lambda _: confirm(api, results[0]["preview"]), range(2)))
    assert statements[0]["statement"]["id"] == statements[1]["statement"]["id"]


def test_backups_restore_reader_provenance_original_and_statement_link(api, test_db_path, tmp_path):
    content = b"Data;Valor;Descricao\n10/07/2025;-10,00;x\n"
    p, doc, _ = preview(api, api.source(), content)
    statement = confirm(api, p)["statement"]
    backup = tmp_path / "with-preview.db"
    restored = tmp_path / "restored-preview.db"
    assert create_backup(source_path=test_db_path, destination_path=backup)["integrity_ok"]
    restore_backup(backup, target_path=restored)
    with sqlite3.connect(restored) as db:
        assert db.execute("SELECT content FROM financial_documents WHERE id=?", (doc["id"],)).fetchone()[0] == content
        assert db.execute("SELECT preview_id FROM financial_statements WHERE id=?", (statement["id"],)).fetchone()[0] == p["id"]
        version, stored = db.execute("SELECT reader_version,result FROM financial_import_previews WHERE id=?", (p["id"],)).fetchone()
        assert version == "2" and json.loads(stored)["items"][0]["data"]["amount_cents"] == -1000
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []


def test_bank_currency_and_sign_must_match_selected_source_and_reader(api):
    bank, card = api.source(), api.source("CREDIT_CARD")
    document = api.document(b"Data;Valor;Descricao\n10/07/2025;1,00;x\n")["document"]
    path = "/documents/" + document["id"] + "/previews"
    for source, currency, opts, code in [
        (bank, "USD", options(), "FINANCIAL_IMPORT_CURRENCY_MISMATCH"),
        (bank, "BRL", options(amount_convention="CHARGES_POSITIVE"), "FINANCIAL_IMPORT_SIGN_MISMATCH"),
        (card, "BRL", options(), "FINANCIAL_IMPORT_SIGN_MISMATCH"),
    ]:
        result = api.post(path, {"source_id": source["id"], "currency": currency, "reader_id": "generic_csv", "options": opts}, expected=(409,))
        assert result["detail"]["error_code"] == code
    assert api.post(path, {"source_id": bank["id"], "currency": "BRL", "reader_id": "unknown"}, expected=(422,))
    response = api.client.get(PREFIX + "/readers", headers={"Authorization": "Bearer invalid"})
    assert response.status_code == 401


def test_two_date_roles_match_without_overwriting_first_event_and_conflicts_block(api):
    source = api.source()
    base = {"amount_cents": -1000, "description": "Operacao", "external_id_namespace": "bank:id", "external_id": "two-dates"}
    _, first, _ = api.stage(source, [{**base, "transaction_date": "2025-07-10", "date_kind": "PURCHASE", "booking_date": "2025-07-11"}])
    canonical = api.review(first[0])["transaction"]
    _, second, _ = api.stage(source, [{**base, "transaction_date": "2025-07-11", "date_kind": "BOOKING", "purchase_date": "2025-07-10"}])
    assert api.review(second[0])["transaction"]["id"] == canonical["id"]
    _, third, _ = api.stage(source, [{**base, "transaction_date": "2025-07-11", "date_kind": "BOOKING", "purchase_date": "2025-07-09"}])
    assert api.post("/items/" + third[0]["id"] + "/review", {"action": "NEW", "reason": "Conferido"}, expected=(409,))
    assert len(api.get("/transactions")) == 1


def test_crash_during_reader_does_not_leave_partial_preview_or_lock(api, test_engine, monkeypatch):
    import app.services.financial_previews as module
    source = api.source()
    doc = api.document(b"Data;Valor;Descricao\n10/07/2025;1,00;x\n")["document"]
    data = {"source_id": source["id"], "currency": "BRL", "reader_id": "generic_csv", "options": options()}
    real = module.parse_csv
    def crash(*args, **kwargs):
        raise RuntimeError("Simulated reader interruption")
    monkeypatch.setattr(module, "parse_csv", crash)
    with pytest.raises(RuntimeError, match="Simulated"):
        api.post("/documents/" + doc["id"] + "/previews", data, key="interrupted-preview")
    with test_engine.connect() as db:
        assert db.exec_driver_sql("SELECT COUNT(*) FROM financial_import_previews").scalar() == 0
        assert db.exec_driver_sql("SELECT COUNT(*) FROM idempotency_records WHERE idempotency_key='interrupted-preview'").scalar() == 0
    monkeypatch.setattr(module, "parse_csv", real)
    assert api.post("/documents/" + doc["id"] + "/previews", data, key="interrupted-preview")["preview"]["status"] == "READY"


def test_import_checks_report_divergences_without_fabricating_balances_or_payments(api):
    p, _, _ = preview(api, api.source(), b"Data;Valor;Descricao\n10/07/2025;-10,00;x\n")
    statement = confirm(api, p, opening_balance_cents=2000, closing_balance_cents=1000,
        total_inflows_cents=0, total_outflows_cents=999, period_start="2025-07-11", period_end="2025-07-31")["statement"]
    checks = {c["code"]: c for c in statement["checks"]}
    assert checks["IMPORTED_INFLOWS_TOTAL"]["matches"]
    assert checks["IMPORTED_OUTFLOWS_TOTAL"]["difference_cents"] == -1
    assert not checks["REPORTED_BALANCE_EQUATION"]["matches"]
    assert not checks["OBSERVED_DATES_WITHIN_PERIOD"]["matches"]
    assert not statement["affects_ledger"] and not api.get("/transactions")


@pytest.mark.parametrize("value,expected", [
    ("- 12,34", -1234), ("+ 12,34", 1234), ("-12,34", -1234),
    ("12,34", 1234), ("- 1.234,56", -123456), ("+ 0,01", 1),
])
def test_explicit_single_sign_space_preserves_exact_cents_and_card_convention(value, expected):
    opts = CSVOptions.model_validate(options(amount_sign_spacing="OPTIONAL_SINGLE_SPACE", thousands_separator="."))
    assert money_cents(value, opts) == expected
    assert money_cents(value, opts.model_copy(update={"amount_convention": "CHARGES_NEGATIVE"})) == -expected


@pytest.mark.parametrize("value", [
    "-  12,34", "-\t12,34", "-\n12,34", "-\u00a012,34", "− 12,34",
    "-- 12,34", "+- 12,34", "12,34-", "- 1 2,34", "- 12.34,56",
    "- 12,345", "- 1e2", "- NaN", "- Infinity", "- R$ 12,34", "- ",
])
def test_single_sign_space_never_repairs_ambiguous_or_invalid_money(value):
    opts = CSVOptions.model_validate(options(amount_sign_spacing="OPTIONAL_SINGLE_SPACE", thousands_separator="."))
    with pytest.raises(ValueError):
        money_cents(value, opts)


def test_sign_spacing_requires_opt_in_and_reprocessing_keeps_original_and_invalid_preview(api, test_db_path):
    source = api.source("CREDIT_CARD")
    before = books(test_db_path)
    content = b"Data;Valor;Descricao\r\n10/07/2025;100,00;Compra\r\n11/07/2025;- 20,00;Credito\r\n"
    opts = options(amount_convention="CHARGES_POSITIVE")
    invalid, doc, _ = preview(api, source, content, opts=opts)
    assert invalid["status"] == "INVALID" and invalid["items_count"] == 1
    assert confirm(api, invalid, statement_type="CARD_BILL", expected=(409,))
    fixed, _, request = preview(api, source, content, opts={**opts, "amount_sign_spacing": "OPTIONAL_SINGLE_SPACE"})
    assert fixed["status"] == "READY" and fixed["reader_version"] == "2"
    assert fixed["id"] != invalid["id"] and fixed["document_id"] == doc["id"]
    rows = api.get("/previews/" + fixed["id"] + "/items")
    assert [r["data"]["amount_cents"] for r in rows] == [10000, -2000]
    assert "- 20,00" in rows[1]["raw_text"]
    original = api.client.get(PREFIX + "/documents/" + doc["id"] + "/content", headers=api.headers)
    assert original.content == content
    assert api.get("/previews/" + invalid["id"])["status"] == "INVALID"
    assert api.post("/documents/" + doc["id"] + "/previews", request)["preview"]["id"] == fixed["id"]
    assert confirm(api, fixed, statement_type="CARD_BILL", expected=(422,))
    staged = confirm(api, fixed, statement_type="CARD_BILL", due_on="2025-08-10", total_amount_cents=9000)["statement"]
    assert staged["total_amount_cents"] == 9000 and staged["pending_count"] == 2
    assert not api.get("/transactions") and books(test_db_path) == before


def test_spacing_option_still_blocks_whole_document_with_one_malformed_row(api):
    content = b"Data;Valor;Descricao\n10/07/2025;- 12,34;Credito\n11/07/2025;-  2,00;Privado\n"
    p, _, _ = preview(api, api.source("CREDIT_CARD"), content,
        opts=options(amount_convention="CHARGES_POSITIVE", amount_sign_spacing="OPTIONAL_SINGLE_SPACE"))
    assert p["status"] == "INVALID" and p["items_count"] == 1 and p["errors_count"] == 1
    assert confirm(api, p, statement_type="CARD_BILL", expected=(409,))
    assert not api.get("/statements")


def test_reader_version_change_creates_new_preview_without_rewriting_v1(api, monkeypatch):
    source = api.source()
    content = b"Data;Valor;Descricao\n10/07/2025;1,00;Exemplo\n"
    with monkeypatch.context() as patch:
        patch.setitem(READERS, "generic_csv", CSVReader("generic_csv", "1"))
        old, doc, _ = preview(api, source, content)
    new, _, _ = preview(api, source, content)
    assert new["id"] != old["id"] and new["reader_version"] == "2"
    assert api.get("/previews/" + old["id"])["reader_version"] == "1"
    assert new["document_id"] == old["document_id"] == doc["id"]
