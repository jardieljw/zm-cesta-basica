import uuid
import datetime
import threading
import pytest
from fastapi.testclient import TestClient
from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from app.models.movements import InventoryMovement
from app.models.idempotency import IdempotencyRecord
from app.models.base import utc_now
from app.core.idempotency import compute_payload_hash, process_transactional_idempotency

def test_idempotency_same_key_same_payload_replays_without_duplicating_stock(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    _, _, headers = authenticated_device
    key = str(uuid.uuid4())
    payload = {
        "product_id": "prod-feijao",
        "quantity_delta": 10,
        "reason": "Entrada teste idempotencia"
    }

    # Request 1: Fresh execution
    req_headers = {**headers, "X-Idempotency-Key": key}
    res1 = client.post("/api/v1/test-ops/stock-simulation", headers=req_headers, json=payload)
    assert res1.status_code == 201
    data1 = res1.json()
    assert data1["current_calculated_balance"] == 10
    movement_id_1 = data1["movement_id"]

    # Verify database movements: exactly 1 movement recorded
    mov_count_1 = test_session.execute(
        select(func.count(InventoryMovement.id)).where(InventoryMovement.product_id == "prod-feijao")
    ).scalar()
    assert mov_count_1 == 1
    test_session.commit()

    # Request 2: Replay of same key with identical payload
    res2 = client.post("/api/v1/test-ops/stock-simulation", headers=req_headers, json=payload)
    assert res2.status_code == 201
    data2 = res2.json()
    assert data2["movement_id"] == movement_id_1
    assert data2["current_calculated_balance"] == 10 # MUST NOT BE 20!

    # Verify database movements: STILL exactly 1 movement, NO duplication!
    mov_count_2 = test_session.execute(
        select(func.count(InventoryMovement.id)).where(InventoryMovement.product_id == "prod-feijao")
    ).scalar()
    assert mov_count_2 == 1
    test_session.commit()

def test_idempotency_same_key_different_payload_returns_409(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    _, _, headers = authenticated_device
    key = str(uuid.uuid4())
    payload_original = {
        "product_id": "prod-arroz",
        "quantity_delta": 50,
        "reason": "Compra lote A"
    }
    payload_divergent = {
        "product_id": "prod-arroz",
        "quantity_delta": 999, # Changed quantity!
        "reason": "Tentativa divergente com mesma chave"
    }

    # Original request
    req_headers = {**headers, "X-Idempotency-Key": key}
    res1 = client.post("/api/v1/test-ops/stock-simulation", headers=req_headers, json=payload_original)
    assert res1.status_code == 201

    # Divergent request with reused key
    res2 = client.post("/api/v1/test-ops/stock-simulation", headers=req_headers, json=payload_divergent)
    assert res2.status_code == 409
    data2 = res2.json()
    assert data2["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"

    # Verify that divergent operation did not touch ledger balance
    balance = test_session.execute(
        select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0))
        .where(InventoryMovement.product_id == "prod-arroz")
    ).scalar()
    assert balance == 50
    test_session.commit()

def test_idempotency_different_keys_execute_independently(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    _, _, headers = authenticated_device
    key1 = str(uuid.uuid4())
    key2 = str(uuid.uuid4())

    payload = {"product_id": "prod-oleo", "quantity_delta": 15}

    res1 = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": key1},
        json=payload
    )
    assert res1.status_code == 201
    assert res1.json()["current_calculated_balance"] == 15

    res2 = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": key2},
        json=payload
    )
    assert res2.status_code == 201
    assert res2.json()["current_calculated_balance"] == 30

def test_idempotency_expired_lock_recovers_without_unique_constraint_violation(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    """
    Simulates an in-flight operation that timed out or whose server crashed before completion.
    A retry of the same key and payload must re-acquire the lock and succeed without crashing.
    """
    _, _, headers = authenticated_device
    key = str(uuid.uuid4())
    payload = {"product_id": "prod-sal", "quantity_delta": 25, "reason": "Entrada apos crash"}
    h = compute_payload_hash(payload)

    # Insert simulated expired in-flight record
    stale_record = IdempotencyRecord(
        id=str(uuid.uuid4()),
        idempotency_key=key,
        operation_type="TEST_STOCK_SIMULATION",
        request_payload_hash=h,
        response_status_code=0,
        response_body="",
        locked_until=utc_now() - datetime.timedelta(seconds=15), # Expired!
        created_at=utc_now() - datetime.timedelta(seconds=45),
    )
    test_session.add(stale_record)
    test_session.commit()

    # Client retries request with same key
    res = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": key},
        json=payload
    )
    assert res.status_code == 201
    data = res.json()
    assert data["is_replay"] is False
    assert data["current_calculated_balance"] == 25

    # Verify that record was updated in place with status code 201
    test_session.expire_all()
    record_in_db = test_session.execute(
        select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key)
    ).scalar_one()
    assert record_in_db.response_status_code == 201
    assert record_in_db.locked_until is None
    test_session.commit()

def test_idempotency_in_flight_lock_returns_409_request_in_progress(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    """
    Verifies that an in-flight key currently locked rejects concurrent attempts with HTTP 409 REQUEST_IN_PROGRESS.
    """
    _, _, headers = authenticated_device
    key = str(uuid.uuid4())
    payload = {"product_id": "prod-cafe", "quantity_delta": 5, "reason": "Em voo"}
    h = compute_payload_hash(payload)

    active_lock = IdempotencyRecord(
        id=str(uuid.uuid4()),
        idempotency_key=key,
        operation_type="TEST_STOCK_SIMULATION",
        request_payload_hash=h,
        response_status_code=0,
        response_body="",
        locked_until=utc_now() + datetime.timedelta(seconds=20), # Active lock!
        created_at=utc_now(),
    )
    test_session.add(active_lock)
    test_session.commit()

    res = client.post(
        "/api/v1/test-ops/stock-simulation",
        headers={**headers, "X-Idempotency-Key": key},
        json=payload
    )
    assert res.status_code == 409
    data = res.json()
    assert data["detail"]["error_code"] == "REQUEST_IN_PROGRESS"

def test_idempotency_operation_type_mismatch_returns_409(test_session: Session):
    """
    Verifies that reusing the same key for a different operation type returns HTTP 409 IDEMPOTENCY_PAYLOAD_MISMATCH.
    """
    key = str(uuid.uuid4())
    payload = {"amount": 100}

    # Step 1: Execute with operation PURCHASES
    process_transactional_idempotency(
        db=test_session,
        idempotency_key=key,
        operation_type="PURCHASES",
        payload=payload,
        business_callback=lambda s: (201, {"created": True})
    )

    # Step 2: Attempt to reuse same key for SALES
    with pytest.raises(HTTPException) as exc_info:
        process_transactional_idempotency(
            db=test_session,
            idempotency_key=key,
            operation_type="SALES",
            payload=payload,
            business_callback=lambda s: (201, {"created": True})
        )
    assert exc_info.value.status_code == 409
    assert exc_info.value.detail["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"

def test_idempotency_business_exception_rolls_back_completely(test_session: Session):
    """
    Verifies that if business callback raises an exception, the database session is rolled back,
    no partial records are persisted, and the key can be retried subsequently.
    """
    key = str(uuid.uuid4())
    payload = {"data": "test"}

    def failing_callback(s):
        s.add(IdempotencyRecord(
            id=str(uuid.uuid4()),
            idempotency_key="internal-test-throwaway",
            operation_type="TEMP",
            request_payload_hash="dummy",
            response_status_code=0,
            response_body="",
            created_at=utc_now(),
        ))
        raise RuntimeError("Simulated commercial validation failure")

    with pytest.raises(RuntimeError):
        process_transactional_idempotency(
            db=test_session,
            idempotency_key=key,
            operation_type="TEST",
            payload=payload,
            business_callback=failing_callback
        )

    # Verify no record remains for key
    persisted = test_session.execute(
        select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key)
    ).scalar_one_or_none()
    assert persisted is None

    # Verify key can now be retried and succeed
    res = process_transactional_idempotency(
        db=test_session,
        idempotency_key=key,
        operation_type="TEST",
        payload=payload,
        business_callback=lambda s: (200, {"success": True})
    )
    assert res.status_code == 200
    assert res.is_replay is False

def test_concurrent_api_requests_with_same_key_serialize_cleanly(
    client: TestClient,
    authenticated_device,
    test_session: Session
):
    """
    Simulates 8 concurrent threads sending the exact same idempotency key at the same instant.
    Exactly one must execute (is_replay=False) and the other 7 must replay (is_replay=True),
    with the ledger balance incremented exactly once.
    """
    _, _, headers = authenticated_device
    key = str(uuid.uuid4())
    prod_id = "prod-leite"
    payload = {"product_id": prod_id, "quantity_delta": 7, "reason": "Teste concorrente mesma chave"}

    responses = []
    errors = []

    def send_worker(idx: int):
        try:
            r = client.post(
                "/api/v1/test-ops/stock-simulation",
                headers={**headers, "X-Idempotency-Key": key},
                json=payload
            )
            responses.append((idx, r.status_code, r.json()))
        except Exception as e:
            errors.append((idx, e))

    threads = [threading.Thread(target=send_worker, args=(i,)) for i in range(8)]
    for t in threads: t.start()
    for t in threads: t.join()

    assert len(errors) == 0, f"Concurrent thread errors: {errors}"
    assert len(responses) == 8

    # All responses must be HTTP 201
    for _, status_code, body in responses:
        assert status_code == 201

    replays = [body["is_replay"] for _, _, body in responses]
    assert replays.count(False) == 1, f"Expected exactly 1 execution, got: {replays}"
    assert replays.count(True) == 7, f"Expected 7 replays, got: {replays}"

    # Balance must be exactly 7, not 56 (7 * 8)
    balance = test_session.execute(
        select(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0))
        .where(InventoryMovement.product_id == prod_id)
    ).scalar()
    assert balance == 7

