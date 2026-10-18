import datetime
import uuid

from sqlalchemy import select
from app.core.idempotency import compute_payload_hash
from app.models.idempotency import IdempotencyRecord


def title(client, headers, amount=100000, due="2026-10-16T00:00:00Z"):
    response = client.post("/api/v1/payables", headers=headers, json={
        "description": "Compra para teste de revisão", "beneficiary": "Fornecedor de teste",
        "category": "FORNECEDOR", "original_amount_cents": amount, "due_date": due,
    })
    assert response.status_code == 201, response.text
    return response.json()[0]["id"]


def command(amount=100000, expected=100000):
    return {"amount_cents": amount, "expected_balance_cents": expected,
            "payment_business_date": "2026-10-16", "payment_method": "PIX"}


def test_reviewed_payment_replay_precedes_balance_precondition(client, authenticated_device):
    _, _, headers = authenticated_device
    pid = title(client, headers)
    assert client.get(f"/api/v1/payables/{pid}", headers=headers).json()["payment_review_version"] == 1
    request_headers = {**headers, "X-Idempotency-Key": str(uuid.uuid4())}
    first = client.post(f"/api/v1/payables/{pid}/payments", headers=request_headers, json=command())
    assert first.status_code == 201, first.text
    replay = client.post(f"/api/v1/payables/{pid}/payments", headers=request_headers, json=command())
    assert replay.json() == first.json()
    detail = client.get(f"/api/v1/payables/{pid}", headers=headers).json()
    assert (detail["balance_cents"], detail["status"], len(detail["payments"])) == (0, "PAID", 1)
    # A different command after another operator settled the title must re-review.
    refused = client.post(f"/api/v1/payables/{pid}/payments", headers={**headers, "X-Idempotency-Key": str(uuid.uuid4())}, json=command())
    assert refused.status_code == 409
    assert refused.json()["detail"]["error_code"] == "PAYABLE_BALANCE_CHANGED"
    assert len(client.get(f"/api/v1/payables/{pid}", headers=headers).json()["payments"]) == 1


def test_balance_increase_after_reversal_does_not_turn_integral_into_partial(client, authenticated_device):
    _, _, headers = authenticated_device
    pid = title(client, headers)
    first = client.post(f"/api/v1/payables/{pid}/payments", headers=headers, json=command(20000)).json()
    # User has reviewed the remaining 80000; another operation reverses 20000.
    reversal = client.post(f"/api/v1/payables/payments/{first['id']}/cancel", headers=headers, json={"reason": "Estorno de teste"})
    assert reversal.status_code == 200, reversal.text
    result = client.post(f"/api/v1/payables/{pid}/payments", headers=headers, json=command(80000, 80000))
    assert result.status_code == 409
    detail = client.get(f"/api/v1/payables/{pid}", headers=headers).json()
    assert detail["balance_cents"] == 100000
    assert len(detail["payments"]) == 1


def test_civil_day_maps_to_business_midnight_utc_and_rejects_ambiguous_input(client, authenticated_device):
    _, _, headers = authenticated_device
    pid = title(client, headers)
    invalid = command(20000)
    invalid["payment_date"] = "2026-10-16T17:00:00Z"
    assert client.post(f"/api/v1/payables/{pid}/payments", headers=headers, json=invalid).status_code == 422
    response = client.post(f"/api/v1/payables/{pid}/payments", headers=headers, json=command(20000))
    assert response.status_code == 201, response.text
    instant = datetime.datetime.fromisoformat(response.json()["payment_date"].replace("Z", "+00:00"))
    assert instant == datetime.datetime(2026, 10, 16, 3, tzinfo=datetime.timezone.utc)
    assert instant.utcoffset() == datetime.timedelta(0)
    detail = client.get(f"/api/v1/payables/{pid}", headers=headers).json()
    assert detail["payments"][0]["payment_date"].endswith("Z")
    assert detail["balance_cents"] == 80000


def test_legacy_idempotency_payload_hash_is_preserved(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    pid = title(client, headers)
    key = str(uuid.uuid4())
    body = {"amount_cents": 20000, "payment_method": "PIX"}
    response = client.post(f"/api/v1/payables/{pid}/payments", headers={**headers, "X-Idempotency-Key": key}, json=body)
    assert response.status_code == 201, response.text
    record = test_session.execute(select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key)).scalar_one()
    legacy_payload = {"payable_id": pid, "amount_cents": 20000, "account_id": None, "payment_method": "PIX", "payment_date": None, "notes": None}
    assert record.request_payload_hash == compute_payload_hash(legacy_payload)


def test_due_today_is_not_overdue_in_list_or_detail_at_business_boundary(client, authenticated_device, monkeypatch):
    import app.services.financial as financial
    import app.api.v1.payables as api
    _, _, headers = authenticated_device
    now = datetime.datetime(2026, 10, 17, 1, tzinfo=datetime.timezone.utc)  # still 16/10 in business zone
    monkeypatch.setattr(financial, "utc_now", lambda: now)
    monkeypatch.setattr(api, "utc_now", lambda: now)
    today = title(client, headers)
    overdue = title(client, headers, due="2026-10-15T00:00:00Z")
    tomorrow = title(client, headers, due="2026-10-17T00:00:00Z")
    result = client.get("/api/v1/payables?overdue_only=true", headers=headers).json()
    assert [item["id"] for item in result] == [overdue]
    assert client.get(f"/api/v1/payables/{today}", headers=headers).json()["is_overdue"] is False
    assert client.get(f"/api/v1/payables/{tomorrow}", headers=headers).json()["is_overdue"] is False


def test_review_invalid_method_refuses_without_payment(client, authenticated_device):
    _, _, headers = authenticated_device
    pid = title(client, headers)
    body = command()
    body["payment_method"] = "UNKNOWN"
    result = client.post(f"/api/v1/payables/{pid}/payments", headers=headers, json=body)
    assert result.status_code == 400
    assert result.json()["detail"]["error_code"] == "PAYABLE_PAYMENT_METHOD_INVALID"
    assert client.get(f"/api/v1/payables/{pid}", headers=headers).json()["payments"] == []
