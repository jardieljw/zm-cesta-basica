"""Synthetic, independently attributed card references; no customer fixtures."""
import copy
import json
import sqlite3
from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import text, select
from sqlalchemy.exc import IntegrityError

from app.core.backup import create_backup, restore_backup
from app.core.idempotency import compute_payload_hash
from app.models.idempotency import IdempotencyRecord
from test_financial_imports import FinancialAPI, PREFIX, books
from test_financial_readers import preview, options, confirm


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def setup_bill(api):
    source = api.source("CREDIT_CARD")
    p, doc, _ = preview(api, source, b"Data;Valor;Descricao\n10/07/2025;100,00;Compra\n11/07/2025;-20,00;Credito\n",
                         opts=options(amount_convention="CHARGES_POSITIVE"))
    response = api.client.post(PREFIX + "/documents?filename=reference.pdf", content=b"%PDF-1.4 synthetic-reference",
        headers={**api.headers, "Content-Type": "application/pdf", "X-Idempotency-Key": "synthetic-reference"})
    assert response.status_code == 201
    pdf = response.json()["document"]
    header = {"due_on": "2025-08-10", "total_amount_cents": 9000}
    common = {"document_id": pdf["id"], "source_id": source["id"], "currency": "BRL",
        "identity_reason": "Titular, cartao e ciclo conferidos manualmente", "header": header}
    payload = {"expected_revision": 0, "expected_source_id": source["id"], "expected_result_sha256": p["result_sha256"],
        "reason": "Conferencia manual dos originais", "header": header, "evidence": [
        {**common, "role": "HEADER", "page_number": 1}, {**common, "role": "DETAILS", "page_number": 2, "items": [
        {"preview_position": 1, "transaction_date": "2025-07-10", "amount_cents": 10000, "description": "Compra"},
        {"preview_position": 2, "transaction_date": "2025-07-11", "amount_cents": -2000, "description": "Credito"}]}]}
    return p, doc, pdf, payload


def assess(api, p, data, **kwargs):
    return api.post("/previews/" + p["id"] + "/bill-assessments", data, **kwargs)


def test_verified_provenance_preserves_bytes_and_books_and_binds_confirmation(api, test_db_path):
    p, doc, pdf, data = setup_bill(api)
    before = books(test_db_path)
    assert api.get("/previews/" + p["id"] + "/bill-assessment")["revision"] == 0
    a = assess(api, p, data, key="assess-once")["assessment"]
    assert a["status"] == "VERIFIED" and a["report"]["coverage_verified"] and a["report"]["header_verified"]
    assert not a["can_generate_obligations"] and a["semantic_status"] == "NOT_REVIEWED"
    assert assess(api, p, data, key="assess-once")["assessment"]["id"] == a["id"]
    evidence = api.get("/bill-assessments/" + a["id"] + "/evidence")
    assert evidence[0]["document_sha256"] == pdf["sha256"] and evidence[1]["claims"]["page_number"] == 2
    # Net transaction amounts need not equal the bank's total bill.
    staged = confirm(api, p, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"])
    assert staged["assessment_id"] == a["id"] and staged["statement"]["total_amount_cents"] == 9000
    assert confirm(api, p, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"])["duplicate"]
    assert api.get("/statements/" + staged["statement"]["id"] + "/bill-assessments")[0]["id"] == a["id"]
    assert api.get("/previews/" + p["id"])["status"] == "READY"
    assert not api.get("/transactions") and books(test_db_path) == before
    audit = api.get("/audit?entity_id=" + a["id"])
    assert "Titular" not in json.dumps(audit) and "Compra" not in json.dumps(audit)


@pytest.mark.parametrize("change,code", [
    ("amount", "REFERENCE_AMOUNT_CENTS_MISMATCH"), ("date", "REFERENCE_TRANSACTION_DATE_MISMATCH"),
    ("description", "REFERENCE_DESCRIPTION_MISMATCH"), ("missing", "PREVIEW_ITEMS_UNCOVERED"),
    ("unmatched", "UNMATCHED_REFERENCE_ITEM"), ("repeated", "REPEATED_REFERENCE_POSITION"),
    ("cycle", "DECLARED_HEADER_MISMATCH"), ("self", "INDEPENDENT_DETAILS_REQUIRED"),
])
def test_readable_csv_is_not_approved_when_reference_is_inconsistent(api, change, code):
    p, doc, _, data = setup_bill(api)
    detail = data["evidence"][1]
    if change == "amount": detail["items"][0]["amount_cents"] += 1
    if change == "date": detail["items"][0]["transaction_date"] = "2025-07-12"
    if change == "description": detail["items"][0]["description"] = "Outra descricao"
    if change == "missing": detail["items"].pop()
    if change == "unmatched": detail["items"][0]["preview_position"] = None
    if change == "repeated": detail["items"][1]["preview_position"] = 1
    if change == "cycle": detail["header"] = {**data["header"], "due_on": "2025-09-10"}
    if change == "self": detail["document_id"] = doc["id"]
    a = assess(api, p, data)["assessment"]
    assert a["status"] == "REVIEW_REQUIRED" and code in {f["code"] for f in a["report"]["findings"]}
    assert api.get("/previews/" + p["id"])["status"] == "READY"
    assert confirm(api, p, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"], expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_ASSESSMENT_UNRESOLVED"
    assert not api.get("/statements")


def test_resolution_requires_explicit_reason_and_evidence_and_keeps_first_revision(api):
    p, _, pdf, original = setup_bill(api)
    data = copy.deepcopy(original)
    data["observations"] = [{"key": "summary", "reason": "Resumo diverge dos detalhes do proprio PDF"}]
    old = assess(api, p, data)["assessment"]
    fixed = {**original, "expected_revision": 1}
    assert assess(api, p, fixed, expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_RESOLUTION_REQUIRED"
    fixed["resolutions"] = [{"finding_id": "MANUAL:summary", "document_id": pdf["id"], "page_number": 3,
                             "reason": "Nova conferencia comprova a composicao declarada"}]
    new = assess(api, p, fixed)["assessment"]
    assert new["revision"] == 2 and new["status"] == "VERIFIED"
    history = api.get("/previews/" + p["id"] + "/bill-assessments")
    assert history[0]["id"] == old["id"] and history[0]["status"] == "REVIEW_REQUIRED"
    assert len(history) == 2
    assert assess(api, p, fixed, expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_REVISION_CONFLICT"


def test_resolution_never_waives_a_computed_difference(api):
    p, _, pdf, data = setup_bill(api)
    data["evidence"][1]["items"][0]["amount_cents"] += 1
    old = assess(api, p, data)["assessment"]
    finding = old["report"]["findings"][0]
    data.update(expected_revision=1, resolutions=[{"finding_id": finding["id"], "document_id": pdf["id"],
                "page_number": 2, "reason": "Tentativa de dispensar diferenca ainda existente"}])
    assert assess(api, p, data, expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_RESOLUTION_REQUIRED"


@pytest.mark.parametrize("change,code", [
    ("source", "FINANCIAL_BILL_EVIDENCE_SOURCE_MISMATCH"), ("currency", "FINANCIAL_BILL_EVIDENCE_SOURCE_MISMATCH"),
    ("hash", "FINANCIAL_BILL_PREVIEW_MISMATCH"), ("page", "FINANCIAL_BILL_PAGE_REQUIRED"),
])
def test_references_require_source_currency_preview_and_pdf_page(api, change, code):
    p, _, _, data = setup_bill(api)
    if change == "source": data["evidence"][0]["source_id"] = api.source("CREDIT_CARD")["id"]
    if change == "currency": data["evidence"][0]["currency"] = "USD"
    if change == "hash": data["expected_result_sha256"] = "0" * 64
    if change == "page": data["evidence"][0].pop("page_number"); data["evidence"][0]["line_start"] = 1
    assert assess(api, p, data, expected=(409, 422))["detail"]["error_code"] == code
    assert not api.get("/previews/" + p["id"] + "/bill-assessments")


def test_new_preview_or_revision_never_inherits_confirmation_approval(api):
    p, _, _, data = setup_bill(api)
    a = assess(api, p, data)["assessment"]
    other, _, _ = preview(api, api.get("/sources")[0], b"Data;Valor;Descricao\n10/07/2025;1,00;Outra\n",
                          opts=options(amount_convention="CHARGES_POSITIVE"))
    assert api.get("/previews/" + other["id"] + "/bill-assessment")["status"] == "NOT_ASSESSED"
    assert confirm(api, other, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"], expected=(409,))
    data["expected_revision"] = 1
    newer = assess(api, p, data)["assessment"]
    assert confirm(api, p, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"], expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_ASSESSMENT_STALE"
    assert confirm(api, p, assessment_id=newer["id"], statement_type="CARD_BILL", due_on="2025-08-10", total_amount_cents=1, expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_HEADER_MISMATCH"


def test_concurrent_assessments_one_revision_and_idempotent_replays(api):
    p, _, _, data = setup_bill(api)
    route = PREFIX + "/previews/" + p["id"] + "/bill-assessments"
    def post(_):
        return api.client.post(route, json=data, headers={**api.headers, "X-Idempotency-Key": "race-assessment"})
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(post, range(2)))
    assert all(r.status_code == 201 for r in results)
    assert results[0].json()["assessment"]["id"] == results[1].json()["assessment"]["id"]
    assert len(api.get("/previews/" + p["id"] + "/bill-assessments")) == 1
    assert assess(api, p, {**data, "reason": "Outro pedido"}, key="race-assessment", expected=(409,))["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"


def test_assessment_history_is_immutable_sealed_and_backup_preserves_it(api, test_engine, test_db_path, tmp_path):
    p, _, _, data = setup_bill(api)
    a = assess(api, p, data)["assessment"]
    statement = confirm(api, p, assessment_id=a["id"], statement_type="CARD_BILL", **data["header"])["statement"]
    for table in ("financial_bill_assessments", "financial_bill_evidence", "financial_bill_assessment_links"):
        for sql in (f"DELETE FROM {table}", f"UPDATE {table} SET id=id"):
            with pytest.raises(IntegrityError), test_engine.begin() as db:
                db.execute(text(sql))
    with pytest.raises(IntegrityError), test_engine.begin() as db:
        db.execute(text("INSERT INTO financial_bill_evidence SELECT 'extra',assessment_id,3,document_id,role,document_sha256,claims FROM financial_bill_evidence LIMIT 1"))
    backup, restored = tmp_path / "backup.db", tmp_path / "restored.db"
    assert create_backup(source_path=test_db_path, destination_path=backup)["integrity_ok"]
    restore_backup(backup, target_path=restored)
    with sqlite3.connect(restored) as db:
        assert db.execute("SELECT status FROM financial_bill_assessments WHERE id=?", (a["id"],)).fetchone() == ("VERIFIED",)
        assert db.execute("SELECT statement_id FROM financial_bill_assessment_links").fetchone() == (statement["id"],)
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []


def test_legacy_confirmation_retains_its_payload_hash(api, test_session):
    p, _, _, data = setup_bill(api)
    payload = {"expected_source_id": p["source_id"], "expected_result_sha256": p["result_sha256"],
               "statement_type": "CARD_BILL", **data["header"]}
    from app.schemas.financial_readers import FinancialPreviewConfirm
    normalized = FinancialPreviewConfirm.model_validate(payload).model_dump(mode="json", exclude={"assessment_id"})
    route = "/previews/" + p["id"] + "/confirm"
    api.post(route, payload, key="legacy-confirm")
    record = test_session.scalar(select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == "legacy-confirm"))
    assert record.request_payload_hash == compute_payload_hash({"preview_id": p["id"], **normalized})


def test_pending_assessment_can_be_saved_without_header_documents_or_a_staged_statement(api):
    p, _, _, data = setup_bill(api)
    data["evidence"] = []
    a = assess(api, p, data)["assessment"]
    assert a["status"] == "REVIEW_REQUIRED" and not a["report"]["header_verified"]
    assert not api.get("/statements")
    # A bank source cannot acquire a card assessment just by supplying a header.
    source = api.source()
    bank, _, _ = preview(api, source, b"Data;Valor;Descricao\n10/07/2025;1,00;Banco\n")
    data.update(expected_source_id=bank["source_id"], expected_result_sha256=bank["result_sha256"])
    assert assess(api, bank, data, expected=(409,))["detail"]["error_code"] == "FINANCIAL_BILL_SOURCE_REQUIRED"


def test_missing_header_is_saved_as_unknown_without_fabricating_total_or_due_date(api):
    p, _, _, data = setup_bill(api)
    data.pop("header")
    data["evidence"] = []
    a = assess(api, p, data)["assessment"]
    assert a["header"] is None and a["status"] == "REVIEW_REQUIRED"
    assert "DECLARED_HEADER_REQUIRED" in {f["code"] for f in a["report"]["findings"]}
    assert not api.get("/statements") and not api.get("/transactions")


def test_interrupted_assessment_rolls_back_parent_evidence_audit_and_idempotency(api, test_engine, monkeypatch):
    from app.services import financial_bill_assessments as module
    p, _, _, data = setup_bill(api)
    def crash(*args, **kwargs):
        raise RuntimeError("Synthetic interrupted evidence")
    with monkeypatch.context() as patch:
        patch.setattr(module, "FinancialBillEvidence", crash)
        with pytest.raises(RuntimeError, match="Synthetic interrupted"):
            assess(api, p, data, key="interrupted-assessment")
    with test_engine.connect() as db:
        assert db.exec_driver_sql("SELECT count(*) FROM financial_bill_assessments").scalar() == 0
        assert db.exec_driver_sql("SELECT count(*) FROM financial_bill_evidence").scalar() == 0
        assert db.exec_driver_sql("SELECT count(*) FROM financial_import_audit WHERE event_type='BILL_ASSESSMENT_CREATED'").scalar() == 0
    assert assess(api, p, data, key="interrupted-assessment")["assessment"]["revision"] == 1
