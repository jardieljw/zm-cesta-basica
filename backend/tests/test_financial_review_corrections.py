"""Audited decision changes; synthetic records only, no company DB access."""
import sqlite3
import uuid
from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.backup import create_backup, restore_backup
from test_financial_imports import FinancialAPI, PREFIX, books, line


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def correct(api, item, action, revision=0, *, expected=(200,), key=None, **fields):
    return api.post("/items/" + item["id"] + "/corrections", {
        "action": action, "reason": "Conferencia corrigida no original", "expected_revision": revision, **fields,
    }, expected=expected, key=key)


def merged_pair(api, source=None, **facts):
    source = source or api.source()
    _, items, _ = api.stage(source, [line(**facts), line(**facts)])
    first = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=first["id"])
    return source, items, first


@pytest.mark.parametrize("amount", [-5000, 5000])
def test_separate_mistaken_duplicate_preserves_original_and_all_books(api, test_db_path, test_engine, amount):
    source, items, original = merged_pair(api, amount=amount)
    before = books(test_db_path)
    with test_engine.connect() as db:
        raw_item = db.exec_driver_sql("SELECT * FROM financial_statement_items WHERE id=?", (items[1]["id"],)).one()
        raw_tx = db.exec_driver_sql("SELECT * FROM financial_transactions WHERE id=?", (original["id"],)).one()
    result = correct(api, items[1], "NEW")
    separate = result["transaction"]
    assert separate["id"] != original["id"] and result["item"]["review_revision"] == 1
    assert result["item"]["original_review_status"] == "LINKED"
    assert not result["affects_ledger"] and books(test_db_path) == before
    with test_engine.connect() as db:
        assert db.exec_driver_sql("SELECT * FROM financial_statement_items WHERE id=?", (items[1]["id"],)).one() == raw_item
        assert db.exec_driver_sql("SELECT * FROM financial_transactions WHERE id=?", (original["id"],)).one() == raw_tx
    assert len(api.get("/transactions")) == 2
    assert api.get("/transactions/" + original["id"] + "/evidence")[0]["id"] == items[0]["id"]
    assert api.get("/transactions/" + separate["id"] + "/evidence")[0]["id"] == items[1]["id"]
    assert len(api.get("/transactions/" + original["id"] + "/evidence?include_history=true")) == 2
    assert api.get("/items/" + items[1]["id"])["transaction_id"] == separate["id"]
    history = api.get("/items/" + items[1]["id"] + "/review-history")
    assert [h["revision"] for h in history] == [0, 1]
    assert [h["transaction_id"] for h in history] == [original["id"], separate["id"]]
    assert all(h["reason"] and h["created_by"] and h["created_at"] for h in history)


def test_correct_link_ignore_and_restore_are_versioned_and_inactive_facts_not_suggested(api):
    source = api.source()
    statement, items, _ = api.stage(source, [line(), line(), line()])
    first = api.review(items[0])["transaction"]
    second = api.review(items[1])["transaction"]
    api.review(items[2], action="LINK", transaction_id=first["id"])
    moved = correct(api, items[2], "LINK", transaction_id=second["id"])
    assert moved["item"]["transaction_id"] == second["id"]
    assert correct(api, items[2], "IGNORE", revision=1)["item"]["transaction_id"] is None
    restored = correct(api, items[2], "LINK", revision=2, transaction_id=first["id"])
    assert restored["item"]["review_revision"] == 3
    correct(api, items[1], "IGNORE")
    active = api.get("/transactions")
    assert [t["id"] for t in active] == [first["id"]]
    all_rows = {t["id"]: t for t in api.get("/transactions?include_inactive=true")}
    assert all_rows[second["id"]]["evidence_status"] == "WITHDRAWN"
    assert all_rows[second["id"]]["reconciliation_status"] == "INACTIVE"
    assert all_rows[first["id"]]["active_evidence_count"] == 2
    _, pending, _ = api.stage(source, [line()])
    assert [r["transaction"]["id"] for r in api.get("/items/" + pending[0]["id"] + "/candidates")] == [first["id"]]
    header = api.get("/statements/" + statement["id"])
    assert header["pending_count"] == 0 and header["items_count"] == 3
    assert api.get("/items/" + items[2]["id"] + "/review-history?limit=1&offset=1")[0]["revision"] == 1
    assert api.get("/items/" + items[2]["id"] + "/review-history?limit=2&offset=2")[-1]["revision"] == 3


def test_ignored_original_can_be_confirmed_later(api):
    _, items, _ = api.stage(api.source(), [line()])
    api.review(items[0], action="IGNORE")
    result = correct(api, items[0], "NEW")
    assert result["item"]["review_status"] == "NEW" and result["transaction"]
    assert api.get("/items/" + items[0]["id"] + "/review-history")[0]["review_status"] == "IGNORED"


def test_active_reconciliations_require_explicit_void_and_never_reverse_real_payment(api, test_db_path):
    source, items, transaction = merged_pair(api)
    entry = api.entry(source["financial_account_id"])
    allocation = api.post("/reconciliations", {"transaction_id": transaction["id"], "cash_flow_entry_id": entry["id"],
        "amount_cents": 5000, "reason": "Conferido no extrato"})["reconciliation"]
    before = books(test_db_path)
    assert correct(api, items[1], "NEW", expected=(409,))["detail"]["error_code"] == "FINANCIAL_CORRECTION_REQUIRES_UNRECONCILE"
    assert len(api.get("/transactions?include_inactive=true")) == 1
    assert api.get("/items/" + items[1]["id"])["review_revision"] == 0
    assert api.get("/reconciliations")[0]["voided_at"] is None
    api.post("/reconciliations/" + allocation["id"] + "/void", {"reason": "Associacao incorreta"})
    corrected = correct(api, items[1], "NEW")
    assert corrected["item"]["review_revision"] == 1
    assert books(test_db_path) == before
    assert api.get("/reconciliations")[0]["void_reason"] == "Associacao incorreta"


def test_destination_reconciliation_also_blocks_link_correction(api):
    source, items, first = merged_pair(api)
    _, destination, _ = api.stage(source, [line()])
    second = api.review(destination[0])["transaction"]
    entry = api.entry(source["financial_account_id"])
    api.post("/reconciliations", {"transaction_id": second["id"], "cash_flow_entry_id": entry["id"],
        "amount_cents": 5000, "reason": "Conferido"})
    assert correct(api, items[1], "LINK", transaction_id=second["id"], expected=(409,))["detail"]["error_code"] == "FINANCIAL_CORRECTION_REQUIRES_UNRECONCILE"
    assert api.get("/items/" + items[1]["id"])["transaction_id"] == first["id"]


def test_inactive_transaction_cannot_be_conciliated(api):
    source = api.source()
    _, items, _ = api.stage(source, [line()])
    transaction = api.review(items[0])["transaction"]
    correct(api, items[0], "IGNORE")
    entry = api.entry(source["financial_account_id"])
    result = api.post("/reconciliations", {"transaction_id": transaction["id"], "cash_flow_entry_id": entry["id"],
        "amount_cents": 5000, "reason": "Sem evidencia ativa"}, expected=(409,))
    assert result["detail"]["error_code"] == "FINANCIAL_TRANSACTION_INACTIVE"
    _, fresh, _ = api.stage(source, [line(), line()])
    assert api.post("/items/" + fresh[0]["id"] + "/review", {
        "action": "LINK", "transaction_id": transaction["id"], "reason": "Destino retirado",
    }, expected=(409,))["detail"]["error_code"] == "FINANCIAL_TRANSACTION_INACTIVE"
    api.review(fresh[1], action="IGNORE")
    assert correct(api, fresh[1], "LINK", transaction_id=transaction["id"], expected=(409,))["detail"]["error_code"] == "FINANCIAL_TRANSACTION_INACTIVE"


def test_alias_added_by_wrong_link_moves_without_rewriting_historical_identity(api, test_engine):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(external_id_namespace="bank:csv", external_id="alias-id")])
    original = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=original["id"])
    separate = correct(api, items[1], "NEW")["transaction"]
    assert separate["id"] != original["id"]
    with test_engine.connect() as db:
        assert db.exec_driver_sql("SELECT transaction_id FROM financial_transaction_identities WHERE external_id='alias-id'").scalar() == original["id"]
        assert db.exec_driver_sql("SELECT transaction_id FROM financial_identity_changes WHERE external_id='alias-id'").scalar() == separate["id"]
    _, repeat, _ = api.stage(source, [line(external_id_namespace="bank:csv", external_id="alias-id")])
    assert api.get("/items/" + repeat[0]["id"] + "/candidates")[0]["transaction"]["id"] == separate["id"]
    assert api.review(repeat[0])["transaction"]["id"] == separate["id"]
    assert len(api.get("/transactions")) == 2
    summaries = {t["id"]: t for t in api.get("/transactions")}
    assert summaries[separate["id"]]["external_identities"] == [{"namespace": "bank:csv", "external_id": "alias-id"}]
    assert summaries[original["id"]]["external_identities"] == []


def test_ignore_releases_id_and_reimport_reactivates_compatible_canonical(api):
    source = api.source()
    fact = line(external_id_namespace="bank:id", external_id="x" * 255)
    _, items, _ = api.stage(source, [fact])
    original = api.review(items[0])["transaction"]
    correct(api, items[0], "IGNORE")
    _, repeat, _ = api.stage(source, [fact])
    assert api.get("/items/" + repeat[0]["id"] + "/candidates") == []
    assert api.review(repeat[0])["transaction"]["id"] == original["id"]
    assert len(api.get("/transactions")) == 1


def test_same_strong_identity_cannot_be_forced_into_two_events(api):
    source = api.source()
    fact = line(external_id_namespace="bank:id", external_id="same-id")
    _, items, _ = api.stage(source, [fact, fact])
    original = api.review(items[0])["transaction"]
    api.review(items[1])
    result = correct(api, items[1], "NEW", expected=(409,))
    assert result["detail"]["error_code"] == "FINANCIAL_IDENTITY_STILL_SUPPORTED"
    assert len(api.get("/transactions")) == 1
    assert api.get("/items/" + items[1]["id"])["transaction_id"] == original["id"]


def test_alias_with_other_support_requires_review_of_other_evidence_before_transfer(api):
    source = api.source()
    fact = line(external_id_namespace="bank:csv", external_id="supported-id")
    _, items, _ = api.stage(source, [line(), fact, fact])
    original = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=original["id"])
    api.review(items[2])
    assert correct(api, items[1], "NEW", expected=(409,))["detail"]["error_code"] == "FINANCIAL_IDENTITY_STILL_SUPPORTED"
    correct(api, items[2], "IGNORE")
    separate = correct(api, items[1], "NEW")["transaction"]
    corrected = correct(api, items[2], "LINK", revision=1, transaction_id=separate["id"])
    assert corrected["transaction"]["id"] == separate["id"]


def test_correcting_created_event_to_existing_event_moves_identity_and_withdraws_old(api):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(external_id_namespace="bank:csv", external_id="moved-id")])
    destination = api.review(items[0])["transaction"]
    historical = api.review(items[1])["transaction"]
    corrected = correct(api, items[1], "LINK", transaction_id=destination["id"])
    assert corrected["transaction"]["id"] == destination["id"]
    assert len(api.get("/transactions")) == 1
    assert len(api.get("/transactions/" + historical["id"] + "/evidence?include_history=true")) == 1
    _, repeat, _ = api.stage(source, [line(external_id_namespace="bank:csv", external_id="moved-id")])
    assert api.review(repeat[0])["transaction"]["id"] == destination["id"]


def test_corrections_revalidate_source_known_facts_and_reliable_ids(api):
    source, other = api.source(), api.source()
    _, items, _ = api.stage(source, [line(external_id_namespace="bank:id", external_id="one")])
    api.review(items[0])
    for target_source, fact in [(other, line()), (source, line(amount=-5001)),
                                (source, line(transaction_date="2025-07-11")),
                                (source, line(external_id_namespace="bank:id", external_id="two"))]:
        _, targets, _ = api.stage(target_source, [fact])
        target = api.review(targets[0])["transaction"]
        assert correct(api, items[0], "LINK", transaction_id=target["id"], expected=(409,))
    assert api.get("/items/" + items[0]["id"])["review_revision"] == 0


def test_replay_stale_version_and_concurrent_corrections_are_safe(api):
    _, items, _ = merged_pair(api)
    first = correct(api, items[1], "NEW", key="same-correction")
    assert correct(api, items[1], "NEW", key="same-correction") == first
    assert correct(api, items[1], "IGNORE", revision=0, expected=(409,))["detail"]["error_code"] == "FINANCIAL_REVIEW_CHANGED"
    assert correct(api, items[1], "IGNORE", key="same-correction", expected=(409,))["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"
    def concurrent(_):
        return api.client.post(PREFIX + "/items/" + items[1]["id"] + "/corrections", json={
            "action": "IGNORE", "expected_revision": 1, "reason": "Correcao concorrente",
        }, headers={**api.headers, "X-Idempotency-Key": str(uuid.uuid4())})
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(concurrent, range(2)))
    assert sorted(r.status_code for r in responses) == [200, 409]
    assert len(api.get("/items/" + items[1]["id"] + "/review-history")) == 3


def test_pending_noop_auth_and_input_validation(api):
    _, pending, _ = api.stage(api.source(), [line()])
    assert correct(api, pending[0], "IGNORE", expected=(409,))["detail"]["error_code"] == "FINANCIAL_REVIEW_NOT_COMPLETED"
    api.review(pending[0], action="IGNORE")
    assert correct(api, pending[0], "IGNORE", expected=(409,))["detail"]["error_code"] == "FINANCIAL_CORRECTION_NO_CHANGE"
    path = PREFIX + "/items/" + pending[0]["id"] + "/corrections"
    assert api.client.post(path, json={}, headers={"X-Idempotency-Key": "no-auth"}).status_code == 401
    for payload in ({"action": "NEW", "reason": "x", "expected_revision": 0},
                    {"action": "NEW", "reason": "Correcao", "expected_revision": True},
                    {"action": "NEW", "reason": "Correcao"}):
        assert api.client.post(path, json=payload, headers={**api.headers, "X-Idempotency-Key": str(uuid.uuid4())}).status_code == 422


def test_sql_keeps_corrections_identity_changes_and_originals_immutable(api, test_engine):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(external_id_namespace="bank:id", external_id="sql-protected")])
    tx = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=tx["id"])
    correct(api, items[1], "NEW")
    for table in ("financial_review_corrections", "financial_identity_changes", "financial_statement_items"):
        for statement in (f"UPDATE {table} SET id='changed'", f"DELETE FROM {table}"):
            with pytest.raises(IntegrityError), test_engine.begin() as db:
                db.execute(text(statement))
    with pytest.raises(IntegrityError), test_engine.begin() as db:
        db.exec_driver_sql("""INSERT INTO financial_review_corrections
            SELECT 'invalid-revision',item_id,3,review_status,transaction_id,reason,created_by,created_at
            FROM financial_review_corrections LIMIT 1""")


def test_backups_preserve_decision_history_and_id_ownership(api, test_db_path, tmp_path):
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(external_id_namespace="bank:id", external_id="backup-id")])
    original = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=original["id"])
    correction = correct(api, items[1], "NEW")
    backup, restored = tmp_path / "decisions.db", tmp_path / "restored-decisions.db"
    assert create_backup(source_path=test_db_path, destination_path=backup)["integrity_ok"]
    restore_backup(backup, target_path=restored)
    with sqlite3.connect(restored) as db:
        assert db.execute("SELECT transaction_id FROM financial_statement_items WHERE id=?", (items[1]["id"],)).fetchone()[0] == original["id"]
        assert db.execute("SELECT transaction_id FROM financial_review_corrections WHERE item_id=?", (items[1]["id"],)).fetchone()[0] == correction["transaction"]["id"]
        assert db.execute("SELECT transaction_id FROM financial_identity_changes").fetchone()[0] == correction["transaction"]["id"]
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []


def test_failure_after_correction_insert_rolls_back_decision_identity_and_request(api, test_engine, monkeypatch):
    import app.services.financial_review_corrections as service
    source = api.source()
    _, items, _ = api.stage(source, [line(), line(external_id_namespace="bank:id", external_id="rollback-id")])
    original = api.review(items[0])["transaction"]
    api.review(items[1], action="LINK", transaction_id=original["id"])
    real = service.assign_identity
    def interrupted(*args, **kwargs):
        real(*args, **kwargs)
        raise RuntimeError("Simulated correction interruption")
    monkeypatch.setattr(service, "assign_identity", interrupted)
    with pytest.raises(RuntimeError, match="Simulated"):
        correct(api, items[1], "NEW", key="interrupted-correction")
    with test_engine.connect() as db:
        assert db.exec_driver_sql("SELECT COUNT(*) FROM financial_review_corrections").scalar() == 0
        assert db.exec_driver_sql("SELECT COUNT(*) FROM financial_identity_changes").scalar() == 0
        assert db.exec_driver_sql("SELECT COUNT(*) FROM idempotency_records WHERE idempotency_key='interrupted-correction'").scalar() == 0
    assert len(api.get("/transactions?include_inactive=true")) == 1
    monkeypatch.setattr(service, "assign_identity", real)
    assert correct(api, items[1], "NEW", key="interrupted-correction")["item"]["review_revision"] == 1


def test_sql_cannot_bypass_active_reconciliation_guard(api, test_engine, authenticated_device):
    source, items, transaction = merged_pair(api)
    entry = api.entry(source["financial_account_id"])
    api.post("/reconciliations", {"transaction_id": transaction["id"], "cash_flow_entry_id": entry["id"],
        "amount_cents": 5000, "reason": "Conferido"})
    with pytest.raises(IntegrityError), test_engine.begin() as db:
        db.exec_driver_sql("""INSERT INTO financial_review_corrections
            (id,item_id,revision,review_status,transaction_id,reason,created_by,created_at)
            VALUES ('invalid-sql',?,1,'IGNORED',NULL,'Tentativa SQL',?,'2025-07-10')""",
            (items[1]["id"], authenticated_device[0].id))
