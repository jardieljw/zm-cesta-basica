import datetime
import uuid

import pytest
from sqlalchemy import func, select

from app.core.idempotency import compute_payload_hash
from app.models.customers import Customer
from app.models.financial import CashFlowEntry, FinancialAccount
from app.models.idempotency import IdempotencyRecord
from app.models.movements import InventoryMovement
from app.models.sales import ReceivablePayment, Sale, SalesReceivable
from tests.test_sales import _setup_inventory_and_basket


def title(db, amount=100000, due="2026-10-17T00:00:00Z", status="OPEN"):
    """Seed only the isolated test session; no production session factory."""
    customer_id, sale_id, receivable_id = [str(uuid.uuid4()) for _ in range(3)]
    sale_number = db.scalar(select(func.coalesce(func.max(Sale.sale_number), 0))) + 1
    db.add(Customer(id=customer_id, name="Cliente de teste"))
    db.flush()
    db.add(Sale(id=sale_id, sale_number=sale_number, customer_id=customer_id,
                payment_mode="CREDIT_TERM", payment_status="PENDING", total_amount_cents=amount))
    db.flush()
    db.add(SalesReceivable(
        id=receivable_id, sale_id=sale_id, customer_id=customer_id,
        due_date=datetime.datetime.fromisoformat(due.replace("Z", "+00:00")),
        original_amount_cents=amount, balance_cents=0 if status == "CANCELED" else amount,
        status=status,
    ))
    db.commit()
    return receivable_id, sale_id, customer_id


def command(amount=100000, expected=100000, method="PIX"):
    return {"amount_cents": amount, "expected_balance_cents": expected,
            "payment_business_date": "2026-10-17", "payment_method": method}


def post_payment(client, headers, rid, body, key=None):
    return client.post(f"/api/v1/receivables/{rid}/payments", json=body,
                       headers={**headers, "X-Idempotency-Key": key or str(uuid.uuid4())})


def test_reviewed_receipt_replay_precedes_balance_precondition(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    rid, sale_id, _ = title(test_session)
    assert client.get(f"/api/v1/receivables/{rid}", headers=headers).json()["payment_review_version"] == 1
    key = str(uuid.uuid4())
    first = post_payment(client, headers, rid, command(), key)
    assert first.status_code == 201, first.text
    assert first.json()["repass_status"] == "DIRECT_COMPANY"
    replay = post_payment(client, headers, rid, command(), key)
    assert replay.status_code == 201
    assert replay.json() == first.json()
    detail = client.get(f"/api/v1/receivables/{rid}", headers=headers).json()
    assert (detail["balance_cents"], detail["status"], len(detail["payments"])) == (0, "PAID", 1)
    assert client.get(f"/api/v1/sales/{sale_id}", headers=headers).json()["payment_status"] == "PAID"

    refused = post_payment(client, headers, rid, command())
    assert refused.status_code == 409
    assert refused.json()["detail"]["error_code"] == "RECEIVABLE_BALANCE_CHANGED"
    entries = test_session.scalars(select(CashFlowEntry).where(
        CashFlowEntry.source_type == "RECEIVABLE_PAYMENT")).all()
    assert len(entries) == 1
    assert (entries[0].entry_type, entries[0].amount_cents) == ("CREDIT", 100000)


def test_balance_increase_after_reversal_requires_new_review(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session)
    first = post_payment(client, headers, rid, command(20000))
    assert first.status_code == 201, first.text
    reversal = client.post(f"/api/v1/receivables/payments/{first.json()['id']}/cancel",
                          headers=headers, json={"reason": "Estorno de teste"})
    assert reversal.status_code == 200, reversal.text
    refused = post_payment(client, headers, rid, command(80000, 80000))
    assert refused.status_code == 409
    assert refused.json()["detail"]["error_code"] == "RECEIVABLE_BALANCE_CHANGED"
    detail = client.get(f"/api/v1/receivables/{rid}", headers=headers).json()
    assert (detail["balance_cents"], len(detail["payments"])) == (100000, 1)
    assert detail["payments"][0]["status"] == "REVERSED"
    entries = test_session.scalars(select(CashFlowEntry).where(
        CashFlowEntry.source_type == "RECEIVABLE_PAYMENT")).all()
    assert len(entries) == 2
    assert sum(e.amount_cents * (1 if e.entry_type == "CREDIT" else -1) for e in entries) == 0


def test_civil_receipt_day_is_utc_and_ambiguous_dates_are_rejected(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session)
    ambiguous = {**command(20000), "payment_date": "2026-10-17T15:00:00Z"}
    assert post_payment(client, headers, rid, ambiguous).status_code == 422
    response = post_payment(client, headers, rid, command(20000))
    assert response.status_code == 201, response.text
    payment = response.json()
    assert payment["payment_date"] == "2026-10-17T03:00:00Z"
    assert payment["created_at"].endswith("Z")
    detail = client.get(f"/api/v1/receivables/{rid}", headers=headers).json()
    assert detail["payments"][0]["payment_date"] == payment["payment_date"]
    entry = test_session.scalars(select(CashFlowEntry).where(
        CashFlowEntry.source_type == "RECEIVABLE_PAYMENT")).one()
    assert entry.occurred_at == datetime.datetime(2026, 10, 17, 3)


def test_legacy_payload_hash_and_completed_replay_are_preserved(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session)
    key = str(uuid.uuid4())
    body = {"amount_cents": 100000, "payment_method": "PIX"}
    response = post_payment(client, headers, rid, body, key)
    assert response.status_code == 201, response.text
    replay = post_payment(client, headers, rid, {**body, "expected_balance_cents": None,
                                               "payment_business_date": None}, key)
    assert replay.json() == response.json()
    record = test_session.scalars(select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key)).one()
    legacy_payload = {"receivable_id": rid, "amount_cents": 100000, "payment_method": "PIX",
                      "account_id": None, "dispatch_id": None, "payment_date": None, "notes": None}
    assert record.request_payload_hash == compute_payload_hash(legacy_payload)


def test_due_today_matches_active_business_summary_at_business_boundary(
    client, authenticated_device, test_session, monkeypatch,
):
    import app.api.v1.receivables as api
    import app.services.receivables as service
    import app.services.business_dashboard as dashboard
    _, _, headers = authenticated_device
    now = datetime.datetime(2026, 10, 18, 1, tzinfo=datetime.timezone.utc)  # still 17/10 UTC-03
    for module in (api, service, dashboard):
        monkeypatch.setattr(module, "utc_now", lambda: now)
    today, _, _ = title(test_session)
    overdue, _, _ = title(test_session, due="2026-10-16T00:00:00Z")
    tomorrow, _, _ = title(test_session, due="2026-10-18T00:00:00Z")
    result = client.get("/api/v1/receivables?overdue_only=true", headers=headers).json()
    assert [item["id"] for item in result] == [overdue]
    for rid in (today, tomorrow):
        assert client.get(f"/api/v1/receivables/{rid}", headers=headers).json()["is_overdue"] is False
    summary = client.get("/api/v1/dashboard/business-summary?filter_type=all", headers=headers).json()["financial"]
    assert summary["receivables_overdue_cents"] == sum(item["balance_cents"] for item in result)
    assert [item["id"] for item in summary["receivables_records"] if item["is_overdue"]] == [overdue]


@pytest.mark.parametrize(("method", "account_type"), [("CASH", "CASH"), ("PIX", "BANK"),
                                                     ("CARD", "BANK"), ("OTHER", "CASH")])
def test_reviewed_receipt_uses_own_methods_and_existing_account_resolution(
    client, authenticated_device, test_session, method, account_type,
):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session)
    test_session.add(FinancialAccount(id="test-bank", name="Banco de teste", account_type="BANK",
                                      is_active=True, is_default=True))
    test_session.commit()
    response = post_payment(client, headers, rid, command(20000, method=method))
    assert response.status_code == 201, response.text
    payment = response.json()
    assert payment["payment_method"] == method
    assert payment["dispatch_id"] is None
    assert payment["is_route_collection"] is False
    assert payment["repass_status"] == "DIRECT_COMPANY"
    assert test_session.get(FinancialAccount, payment["account_id"]).account_type == account_type


@pytest.mark.parametrize(("case", "code", "http_status"), [
    ("missing", "RECEIVABLE_NOT_FOUND", 404),
    ("closed", "RECEIVABLE_NOT_OPEN", 400),
    ("excess", "RECEIVABLE_AMOUNT_EXCEEDS_BALANCE", 400),
    ("method", "RECEIVABLE_PAYMENT_METHOD_INVALID", 400),
])
def test_definitive_callback_refusals_leave_no_receipt_or_ledger(
    client, authenticated_device, test_session, case, code, http_status,
):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session, status="CANCELED" if case == "closed" else "OPEN")
    body = command()
    if case == "missing":
        rid = "missing-receivable"
    elif case == "closed":
        body = command(1, 0)
    elif case == "excess":
        body = command(100001)
    else:
        body["payment_method"] = "UNKNOWN"
    key = str(uuid.uuid4())
    refused = post_payment(client, headers, rid, body, key)
    assert refused.status_code == http_status, refused.text
    assert refused.json()["detail"]["error_code"] == code
    assert test_session.scalar(select(func.count()).select_from(ReceivablePayment)) == 0
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)) == 0
    assert test_session.scalar(select(func.count()).select_from(IdempotencyRecord).where(
        IdempotencyRecord.idempotency_key == key)) == 0


def test_legacy_transfer_method_remains_supported(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    rid, _, _ = title(test_session)
    response = post_payment(client, headers, rid, {"amount_cents": 20000, "payment_method": "TRANSFER"})
    assert response.status_code == 201, response.text
    assert response.json()["payment_method"] == "TRANSFER"


def test_open_only_includes_partial_and_paginates_without_changing_legacy_status(
    client, authenticated_device, test_session,
):
    _, _, headers = authenticated_device
    opened, _, _ = title(test_session)
    partial, _, _ = title(test_session)
    paid, _, _ = title(test_session)
    assert post_payment(client, headers, partial, command(20000)).status_code == 201
    assert post_payment(client, headers, paid, command()).status_code == 201
    exact_open = client.get("/api/v1/receivables?status=OPEN", headers=headers).json()
    assert [item["id"] for item in exact_open] == [opened]
    all_items = client.get("/api/v1/receivables", headers=headers).json()
    assert {item["id"] for item in all_items} == {opened, partial, paid}
    active = client.get("/api/v1/receivables?open_only=true", headers=headers).json()
    assert {item["id"] for item in active} == {opened, partial}
    pages = [client.get(f"/api/v1/receivables?open_only=true&limit=1&offset={offset}",
                        headers=headers).json() for offset in (0, 1, 2)]
    assert [len(page) for page in pages] == [1, 1, 0]
    assert [item["id"] for page in pages for item in page] == [item["id"] for item in active]


def test_receipt_and_reversal_preserve_sale_value_items_and_inventory(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    _, _, basket = _setup_inventory_and_basket(client, headers)
    customer = client.post("/api/v1/customers", headers=headers,
                           json={"name": "Cliente da conferência", "credit_limit_cents": 100000}).json()
    created = client.post("/api/v1/sales", headers=headers, json={
        "customer_id": customer["id"], "payment_mode": "CREDIT_TERM",
        "items": [{"basket_type_id": basket["id"], "quantity": 2,
                   "unit_price_cents": 20000, "assemble_on_demand": True}],
    })
    assert created.status_code == 201, created.text
    sale = created.json()
    original_sale = client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()
    original_stock = [dict(row) for row in test_session.execute(
        select(InventoryMovement.__table__).order_by(InventoryMovement.id)).mappings()]
    test_session.commit()
    response = post_payment(client, headers, sale["receivable_id"], command(10000, 40000, "CARD"))
    assert response.status_code == 201, response.text

    for expected_payment_status in ("PARTIAL", "PENDING"):
        current = client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()
        assert current["payment_status"] == expected_payment_status
        assert current["receivable_status"] == ("PARTIAL" if expected_payment_status == "PARTIAL" else "OPEN")
        assert current["receivable_balance_cents"] == (30000 if expected_payment_status == "PARTIAL" else 40000)
        financial_state = {"payment_status", "receivable_status", "receivable_balance_cents"}
        assert {k: v for k, v in current.items() if k not in financial_state} == {
            k: v for k, v in original_sale.items() if k not in financial_state}
        stock = [dict(row) for row in test_session.execute(
            select(InventoryMovement.__table__).order_by(InventoryMovement.id)).mappings()]
        assert stock == original_stock
        test_session.commit()
        if expected_payment_status == "PARTIAL":
            reversal = client.post(f"/api/v1/receivables/payments/{response.json()['id']}/cancel",
                                  headers=headers, json={"reason": "Correção preservando a venda"})
            assert reversal.status_code == 200, reversal.text

    detail = client.get(f"/api/v1/receivables/{sale['receivable_id']}", headers=headers).json()
    assert (detail["original_amount_cents"], detail["paid_amount_cents"], detail["balance_cents"]) == (40000, 0, 40000)
    assert detail["payments"][0]["status"] == "REVERSED"
    summary = client.get("/api/v1/dashboard/business-summary?filter_type=all", headers=headers).json()
    assert summary["sales"]["total_sold_cents"] == 40000
    assert summary["financial"]["effective_received_cents"] == 0
