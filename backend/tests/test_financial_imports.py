"""Synthetic bank/card cases inspired by document shapes, never customer data."""
import uuid
import sqlite3
from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError

from app.core.backup import create_backup, restore_backup
from app.models.auth import PairedDevice

PREFIX = "/api/v1/financial-imports"


class FinancialAPI:
    def __init__(self, client, headers):
        self.client, self.headers = client, headers

    def post(self, path, data, key=None, expected=(200, 201)):
        response = self.client.post(PREFIX + path, json=data, headers={
            **self.headers, "X-Idempotency-Key": key or str(uuid.uuid4()),
        })
        assert response.status_code in expected, response.text
        return response.json()

    def get(self, path):
        response = self.client.get(PREFIX + path, headers=self.headers)
        assert response.status_code == 200, response.text
        return response.json()

    def source(self, kind="BANK_ACCOUNT", holder="PJ"):
        data = {"source_type": kind, "holder_type": holder, "name": "Conta de teste",
                "institution": "Banco exemplo", "holder_name": "Empresa exemplo"}
        if kind == "BANK_ACCOUNT":
            response = self.client.post("/api/v1/treasury/accounts", json={
                "name": "Banco " + uuid.uuid4().hex[:6], "account_type": "BANK", "initial_balance_cents": 50000,
            }, headers=self.headers)
            assert response.status_code == 201, response.text
            data["financial_account_id"] = response.json()["id"]
        return self.post("/sources", data)

    def document(self, content=None, key=None, filename="example.csv"):
        content = content or ("date,amount\n" + uuid.uuid4().hex).encode()
        response = self.client.post(PREFIX + "/documents", params={"filename": filename}, content=content, headers={
            **self.headers, "Content-Type": "text/csv", "X-Idempotency-Key": key or str(uuid.uuid4()),
        })
        assert response.status_code in (200, 201), response.text
        return response.json()

    def stage(self, source, lines, **header):
        data = {"document_id": self.document()["document"]["id"], "source_id": source["id"],
                "statement_type": "BANK_STATEMENT", "items": [
                    {"position": i + 1, "page_number": 1, "data": line} for i, line in enumerate(lines)
                ], **header}
        result = self.post("/statements", data)
        return result["statement"], self.get("/statements/" + result["statement"]["id"] + "/items"), data

    def review(self, item, action="NEW", **fields):
        return self.post("/items/" + item["id"] + "/review", {"action": action, "reason": "Conferido no documento", **fields})

    def entry(self, account_id, amount=5000, direction="DEBIT"):
        response = self.client.post("/api/v1/treasury/entries", json={
            "account_id": account_id, "entry_type": direction, "amount_cents": amount,
            "category": "OUTROS", "description": "Movimento existente", "source_type": "MANUAL",
        }, headers=self.headers)
        assert response.status_code == 201, response.text
        return response.json()


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def line(amount=-5000, **fields):
    return {"transaction_date": "2025-07-10", "amount_cents": amount,
            "description": "Pagamento a fornecedor", **fields}


def books(db_path):
    with sqlite3.connect(db_path) as connection:
        return {table: connection.execute(f"SELECT * FROM {table} ORDER BY id").fetchall() for table in (
            "financial_accounts", "cash_flow_entries", "accounts_payable", "payable_payments", "inventory_movements",
        )}


def test_sources_keep_bank_identity_and_card_facility_separate(api):
    bank = api.source(holder="PJ")
    card = api.source("CREDIT_CARD", holder="PF")
    assert bank["financial_account_id"] and card["financial_account_id"] is None
    duplicate = {k: bank[k] for k in ("source_type", "financial_account_id", "holder_type", "name", "institution")}
    assert api.post("/sources", duplicate, expected=(409,))["detail"]["error_code"] == "FINANCIAL_SOURCE_EXISTS"
    assert len(api.get("/sources")) == 2


def test_document_exact_duplicate_and_replay_retain_one_blob_and_audit(api):
    content = b"Data,Valor,Identificador\n2025-07-10,-50.00,synthetic-id"
    first = api.document(content, key="same-document")
    replay = api.document(content, key="same-document")
    second_name = api.document(content, filename="another-name.csv")
    assert first == replay
    assert second_name["duplicate"]
    assert second_name["document"]["id"] == first["document"]["id"]
    document_id = first["document"]["id"]
    info = api.get("/documents/" + document_id)
    assert "content" not in info
    response = api.client.get(PREFIX + "/documents/" + document_id + "/content", headers=api.headers)
    assert response.content == content
    assert response.headers["cache-control"] == "no-store"
    assert response.headers["x-content-type-options"] == "nosniff"
    assert {e["event_type"] for e in api.get("/audit?entity_id=" + document_id)} == {
        "DOCUMENT_STORED", "DOCUMENT_REUSED", "DOCUMENT_ACCESSED",
    }


def test_staging_review_and_duplicate_statements_never_change_books(api, test_db_path):
    source = api.source()
    before = books(test_db_path)
    statement, items, payload = api.stage(source, [line()], opening_balance_cents=0,
                                        total_inflows_cents=10000, total_outflows_cents=5000, closing_balance_cents=5001)
    assert statement["checks"] == [{"code": "REPORTED_BALANCE_EQUATION", "matches": False, "difference_cents": 1}]
    assert statement["pending_count"] == 1
    duplicate = api.post("/statements", payload)
    assert duplicate["duplicate"] and duplicate["statement"]["id"] == statement["id"]
    result = api.review(items[0])
    assert result["item"]["review_status"] == "NEW"
    assert result["transaction"]["transaction_time"] is None
    assert result["transaction"]["utc_offset_minutes"] is None
    assert not result["affects_ledger"]
    assert api.get("/statements/" + statement["id"])["pending_count"] == 0
    assert books(test_db_path) == before


def test_raw_occurrence_text_keeps_original_whitespace(api):
    source = api.source()
    raw = "  10/07  Pagamento\n    50,00  \n"
    statement = api.post("/statements", {
        "document_id": api.document()["document"]["id"], "source_id": source["id"], "statement_type": "BANK_STATEMENT",
        "items": [{"position": 1, "raw_text": raw, "data": line()}],
    })["statement"]
    assert api.get("/statements/" + statement["id"] + "/items")[0]["raw_text"] == raw


def test_same_date_value_description_preserves_distinct_legitimate_operations(api):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line()])
    first = api.review(items[0])["transaction"]
    assert api.get("/items/" + items[1]["id"] + "/candidates")[0]["basis"] == "SAME_DATE_AMOUNT_REQUIRES_REVIEW"
    second = api.review(items[1])["transaction"]
    assert first["id"] != second["id"]
    assert len(api.get("/transactions")) == 2


def test_overlapping_documents_link_reliable_id_but_keep_every_occurrence(api):
    source = api.source()
    fact = line(external_id_namespace="bank_csv_id", external_id="example-id-001")
    _, first_items, _ = api.stage(source, [fact])
    _, next_items, _ = api.stage(source, [fact])
    first = api.review(first_items[0])["transaction"]
    assert api.get("/items/" + next_items[0]["id"] + "/candidates")[0]["basis"] == "EXTERNAL_ID"
    reviewed = api.review(next_items[0])
    assert reviewed["item"]["review_status"] == "LINKED"
    assert reviewed["transaction"]["id"] == first["id"]
    assert len(api.get("/transactions/" + first["id"] + "/evidence")) == 2


def test_different_bank_ids_are_not_merged_and_scope_is_per_source(api):
    source, other = api.source(), api.source()
    _, items, _ = api.stage(source, [line(external_id_namespace="bank", external_id="id-1"),
                                        line(external_id_namespace="bank", external_id="id-2")])
    first = api.review(items[0])["transaction"]
    assert api.get("/items/" + items[1]["id"] + "/candidates") == []
    assert api.post("/items/" + items[1]["id"] + "/review", {
        "action": "LINK", "transaction_id": first["id"], "reason": "Nao deve ser permitido",
    }, expected=(409,))["detail"]["error_code"] == "FINANCIAL_EXTERNAL_ID_CONFLICT"
    second = api.review(items[1])["transaction"]
    _, other_items, _ = api.stage(other, [line(external_id_namespace="bank", external_id="id-1")])
    third = api.review(other_items[0])["transaction"]
    assert len({first["id"], second["id"], third["id"]}) == 3


def test_conflicting_external_id_rolls_back_and_leaves_item_pending(api):
    source = api.source()
    _, first_items, _ = api.stage(source, [line(external_id_namespace="bank", external_id="fixed")])
    api.review(first_items[0])
    statement, other_items, _ = api.stage(source, [line(-5100, external_id_namespace="bank", external_id="fixed")])
    api.post("/items/" + other_items[0]["id"] + "/review", {"action": "NEW", "reason": "Dados divergentes"}, expected=(409,))
    assert api.get("/statements/" + statement["id"])["pending_count"] == 1
    assert len(api.get("/transactions")) == 1


def test_later_evidence_can_add_external_identity_without_rewriting_original_fact(api):
    source = api.source()
    _, initial, _ = api.stage(source, [line()])
    original = api.review(initial[0])["transaction"]
    identified = line(external_id_namespace="bank_csv", external_id="new-known-id", transaction_time="09:15:33", utc_offset_minutes=-180)
    _, better, _ = api.stage(source, [identified])
    api.review(better[0], "LINK", transaction_id=original["id"])
    _, overlap, _ = api.stage(source, [identified])
    assert api.review(overlap[0])["transaction"]["id"] == original["id"]
    evidence = api.get("/transactions/" + original["id"] + "/evidence")
    assert any(e["normalized_data"]["transaction_time"] == "09:15:33" for e in evidence)
    assert original["transaction_time"] is None
    _, conflicting, _ = api.stage(source, [line(external_id_namespace="bank_csv", external_id="different-bank-id")])
    api.post("/items/" + conflicting[0]["id"] + "/review", {
        "action": "LINK", "transaction_id": original["id"], "reason": "Nao deve mesclar ids distintos",
    }, expected=(409,))


def test_review_replay_conflict_and_ignore_are_audited(api):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(-3000)])
    path = "/items/" + items[0]["id"] + "/review"
    payload = {"action": "NEW", "reason": "Conferido manualmente"}
    first = api.post(path, payload, key="review-once")
    assert api.post(path, payload, key="review-once") == first
    api.post(path, {**payload, "reason": "Outra decisao"}, key="review-once", expected=(409,))
    api.post(path, payload, expected=(409,))
    ignored = api.review(items[1], "IGNORE")
    assert ignored["transaction"] is None and ignored["item"]["review_status"] == "IGNORED"
    assert len(api.get("/audit?entity_id=" + items[0]["id"])) == 1


def test_card_bill_keeps_old_purchase_dates_payment_credits_and_multiple_card_finals(api, test_db_path):
    card = api.source("CREDIT_CARD", "PF")
    before = books(test_db_path)
    statement, items, _ = api.stage(card, [
        line(15000, transaction_date="2025-02-10", date_kind="PURCHASE", card_last_four="1234", installment_number=4, total_installments=6),
        line(20000, card_last_four="5678"),
        line(-10000, transaction_kind="BILL_PAYMENT"),
    ], statement_type="CARD_BILL", period_start="2025-07-01", period_end="2025-07-31",
        closing_on="2025-07-31", due_on="2025-08-07", total_amount_cents=35000, minimum_payment_cents=3500)
    assert statement["total_amount_cents"] == 35000  # not the sum 25000 of all historical lines
    for item in items:
        api.review(item)
    assert len(api.get("/transactions")) == 3
    assert books(test_db_path) == before


@pytest.mark.parametrize("reported,precision", [(None, None), ("08:05", "MINUTE"), ("08:05:35", "SECOND")])
def test_real_time_precision_is_preserved_without_inventing_timezone(api, reported, precision):
    source = api.source()
    _, items, _ = api.stage(source, [line(transaction_time=reported)])
    transaction = api.review(items[0])["transaction"]
    assert transaction["transaction_time"] == reported
    assert transaction["time_precision"] == precision
    assert transaction["utc_offset_minutes"] is None


def test_many_to_many_reconciliation_and_void_only_link_evidence(api, test_db_path):
    source = api.source()
    entry1 = api.entry(source["financial_account_id"], 3000)
    entry2 = api.entry(source["financial_account_id"], 2000)
    before = books(test_db_path)
    _, items, _ = api.stage(source, [line(-5000), line(-1000)])
    tx1, tx2 = (api.review(i)["transaction"] for i in items)
    data = {"transaction_id": tx1["id"], "cash_flow_entry_id": entry1["id"], "amount_cents": 3000, "reason": "Comprovante conferido"}
    rec = api.post("/reconciliations", data, key="allocation-once")
    assert api.post("/reconciliations", data, key="allocation-once") == rec
    api.post("/reconciliations", data, expected=(409,))
    api.post("/reconciliations", {**data, "cash_flow_entry_id": entry2["id"], "amount_cents": 2000})
    summaries = {t["id"]: t for t in api.get("/transactions")}
    assert summaries[tx1["id"]]["reconciliation_status"] == "RECONCILED"
    assert summaries[tx1["id"]]["unreconciled_amount_cents"] == 0
    api.post("/reconciliations", {**data, "transaction_id": tx2["id"], "amount_cents": 1}, expected=(409,))
    void_id = rec["reconciliation"]["id"]
    api.post("/reconciliations/" + void_id + "/void", {"reason": "Correspondencia incorreta"})
    api.post("/reconciliations", {**data, "transaction_id": tx2["id"], "amount_cents": 1000})
    assert books(test_db_path) == before
    assert len(api.get("/reconciliations")) == 3
    summaries = {t["id"]: t for t in api.get("/transactions")}
    assert summaries[tx1["id"]]["reconciliation_status"] == "PARTIAL"
    assert summaries[tx1["id"]]["unreconciled_amount_cents"] == 3000


def test_wrong_account_direction_currency_and_card_cannot_be_cash_reconciled(api):
    bank, other, card = api.source(), api.source(), api.source("CREDIT_CARD")
    entry = api.entry(bank["financial_account_id"])
    for source, amount, header in [(other, -5000, {}), (bank, 5000, {}), (card, -5000, {
        "statement_type": "CARD_BILL", "due_on": "2025-08-07", "total_amount_cents": 5000,
    })]:
        _, items, _ = api.stage(source, [line(amount)], **header)
        tx = api.review(items[0])["transaction"]
        api.post("/reconciliations", {"transaction_id": tx["id"], "cash_flow_entry_id": entry["id"],
                                     "amount_cents": 5000, "reason": "Correspondencia invalida"}, expected=(409,))


def test_strict_auth_ignores_legacy_master_fallback_and_rejects_revoked_tokens(api, authenticated_device, test_session):
    test_session.add(PairedDevice(id=str(uuid.uuid4()), device_name="Mestre", device_public_id="windows-local-master", token_hash="example-not-token", is_active=True))
    test_session.commit()
    for headers in ({}, {"Authorization": "Bearer invalid-token"}):
        response = api.client.get(PREFIX + "/sources", headers=headers)
        assert response.status_code == 401
    device = test_session.get(PairedDevice, authenticated_device[0].id)
    device.is_active = False
    test_session.commit()
    assert api.client.get(PREFIX + "/sources", headers=api.headers).status_code == 401


@pytest.mark.parametrize("fields", [
    {"amount_cents": True}, {"amount_cents": 1.5}, {"amount_cents": 0},
    {"amount_cents": 9000000000000001}, {"transaction_time": "29:33"},
    {"transaction_date": 0},
    {"utc_offset_minutes": -180}, {"external_id": "without-namespace"},
    {"installment_number": 4}, {"installment_number": 5, "total_installments": 4},
    {"card_last_four": "1234567890123456"}, {"cvv": "123"},
])
def test_invalid_or_unneeded_fields_are_rejected_without_echoing_sensitive_input(api, fields):
    source = api.source()
    document_id = api.document()["document"]["id"]
    result = api.post("/statements", {"source_id": source["id"], "document_id": document_id,
        "statement_type": "BANK_STATEMENT", "items": [{"position": 1, "data": line(**fields)}]}, expected=(422,))
    assert result["detail"]["error_code"] == "INVALID_FINANCIAL_DATA"
    assert all("input" not in e for e in result["detail"]["fields"])


def test_required_keys_file_limits_formats_and_json_limit(api):
    assert api.client.post(PREFIX + "/sources", json={}, headers=api.headers).status_code == 400
    for mime, content, filename, expected in [
        ("application/pdf", b"not-a-pdf", "example.pdf", 422),
        ("text/csv", b"", "example.csv", 413),
        ("application/x-msdownload", b"x", "example.exe", 415),
        ("text/csv", b"x", "../bad.csv", 422),
        ("text/csv", b"x" * (10 * 1024 * 1024 + 1), "large.csv", 413),
    ]:
        response = api.client.post(PREFIX + "/documents", params={"filename": filename}, content=content,
                                   headers={**api.headers, "Content-Type": mime, "X-Idempotency-Key": str(uuid.uuid4())})
        assert response.status_code == expected, response.text
    oversized = api.client.post(PREFIX + "/statements", content=b" " * (2 * 1024 * 1024 + 1), headers={
        **api.headers, "Content-Type": "application/json", "X-Idempotency-Key": str(uuid.uuid4()),
    })
    assert oversized.status_code == 413


def test_sql_protects_original_document_items_transactions_and_audit(api, test_engine):
    source = api.source()
    statement, items, _ = api.stage(source, [line()])
    tx = api.review(items[0])["transaction"]
    for table, change in [
        ("financial_documents", "filename = 'changed.csv'"),
        ("financial_statements", "total_amount_cents = 100"),
        ("financial_statement_items", "review_status = 'PENDING'"),
        ("financial_transactions", "amount_cents = 123"),
        ("financial_import_audit", "event_type = 'CHANGED'"),
    ]:
        with pytest.raises(IntegrityError), test_engine.begin() as connection:
            connection.execute(text(f"UPDATE {table} SET {change}"))
        with pytest.raises(IntegrityError), test_engine.begin() as connection:
            connection.execute(text(f"DELETE FROM {table}"))
    assert len(api.get("/transactions/" + tx["id"] + "/evidence")) == 1


def test_concurrent_reviews_with_same_bank_identity_resolve_one_transaction(api):
    source = api.source()
    fact = line(external_id_namespace="bank_csv", external_id="concurrent-example")
    _, items1, _ = api.stage(source, [fact])
    _, items2, _ = api.stage(source, [fact])
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(api.review, [items1[0], items2[0]]))
    assert results[0]["transaction"]["id"] == results[1]["transaction"]["id"]
    assert len(api.get("/transactions")) == 1


def test_concurrent_allocations_cannot_exceed_external_transaction(api):
    source = api.source()
    entries = [api.entry(source["financial_account_id"], 3000) for _ in range(2)]
    _, items, _ = api.stage(source, [line(-3000)])
    tx = api.review(items[0])["transaction"]

    def allocate(entry):
        return api.client.post(PREFIX + "/reconciliations", json={
            "transaction_id": tx["id"], "cash_flow_entry_id": entry["id"],
            "amount_cents": 2000, "reason": "Conciliacao concorrente",
        }, headers={**api.headers, "X-Idempotency-Key": str(uuid.uuid4())})

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(allocate, entries))
    assert sorted(r.status_code for r in results) == [201, 409]
    assert sum(r["amount_cents"] for r in api.get("/reconciliations")) == 2000


def test_missing_schema_returns_clear_error_without_disabling_legacy_api(api, test_engine):
    with test_engine.begin() as connection:
        connection.exec_driver_sql("DROP TABLE financial_import_audit")
    response = api.client.get(PREFIX + "/sources", headers=api.headers)
    assert response.status_code == 503
    assert response.json()["detail"]["error_code"] == "FINANCIAL_SCHEMA_NOT_READY"
    assert api.client.get("/api/v1/payables", headers=api.headers).status_code == 200


def test_backup_and_restore_include_exact_original_document(api, test_db_path, tmp_path):
    content = b"date,amount\n2025-07-10,-50.00"
    document = api.document(content)["document"]
    backup = create_backup(source_path=test_db_path, destination_path=tmp_path / "backup.db")
    restored = tmp_path / "restored.db"
    restore_backup(tmp_path / "backup.db", target_path=restored)
    assert backup["integrity_ok"]
    with sqlite3.connect(restored) as connection:
        assert connection.execute("SELECT content FROM financial_documents WHERE id=?", (document["id"],)).fetchone()[0] == content
        assert connection.execute("PRAGMA foreign_key_check").fetchall() == []
