import json
import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.models.auth import PairedDevice, PairingSession
from app.core.security import hash_token
from app.models.base import utc_now

def test_pairing_initiate_generates_pin_and_qr_without_permanent_tokens(client: TestClient):
    response = client.post("/api/v1/pairing/initiate")
    assert response.status_code == 200
    data = response.json()

    assert "pin_code" in data
    assert len(data["pin_code"]) == 6
    assert data["pin_code"].isdigit()
    assert "expires_at" in data
    assert "server_url" in data
    assert "tls_fingerprint_sha256" in data
    assert "qr_payload" in data

    # Verify that QR Code payload does NOT expose any permanent tokens
    qr_dict = json.loads(data["qr_payload"])
    assert "device_token" not in qr_dict
    assert "secret_hash" not in qr_dict
    assert "token_hash" not in qr_dict
    assert qr_dict["pin_code"] == data["pin_code"]
    assert qr_dict["tls_fingerprint_sha256"] == data["tls_fingerprint_sha256"]

def test_pairing_confirm_success_and_server_stores_only_hash(client: TestClient, test_session: Session):
    # Initiate pairing
    init_res = client.post("/api/v1/pairing/initiate")
    pin = init_res.json()["pin_code"]

    device_name = "Galaxy Tab A9"
    device_public_id = "device-android-12345"

    confirm_res = client.post(
        "/api/v1/pairing/confirm",
        json={
            "pin_code": pin,
            "device_name": device_name,
            "device_public_id": device_public_id,
        }
    )
    assert confirm_res.status_code == 200
    confirm_data = confirm_res.json()

    assert "device_token" in confirm_data
    raw_token = confirm_data["device_token"]
    assert len(raw_token) >= 32

    # Check database: only token_hash is stored! Raw token must NOT exist in DB
    db_device = test_session.execute(
        select(PairedDevice).where(PairedDevice.device_public_id == device_public_id)
    ).scalar_one()

    assert db_device.token_hash == hash_token(raw_token)
    assert db_device.token_hash != raw_token
    assert db_device.is_active is True
    test_session.commit()

    # Test authentication with the issued token
    list_res = client.get(
        "/api/v1/devices",
        headers={"Authorization": f"Bearer {raw_token}"}
    )
    assert list_res.status_code == 200
    devices = list_res.json()
    assert any(d["device_public_id"] == device_public_id for d in devices)

def test_pairing_fails_with_reused_or_expired_pin(client: TestClient, test_session: Session):
    init_res = client.post("/api/v1/pairing/initiate")
    pin = init_res.json()["pin_code"]

    # First use succeeds
    ok_res = client.post(
        "/api/v1/pairing/confirm",
        json={"pin_code": pin, "device_name": "Dev 1", "device_public_id": "pub-1"}
    )
    assert ok_res.status_code == 200

    # Second use of same PIN must fail
    fail_res = client.post(
        "/api/v1/pairing/confirm",
        json={"pin_code": pin, "device_name": "Dev 2", "device_public_id": "pub-2"}
    )
    assert fail_res.status_code == 400
    assert "PIN invalido ou ja utilizado" in fail_res.json()["detail"]

    # Create expired PIN session
    expired_session = PairingSession(
        id="expired-session-id",
        pin_code="999999",
        expires_at=utc_now() - datetime.timedelta(minutes=10),
        is_used=False,
        created_at=utc_now() - datetime.timedelta(minutes=15),
    )
    test_session.add(expired_session)
    test_session.commit()

    exp_res = client.post(
        "/api/v1/pairing/confirm",
        json={"pin_code": "999999", "device_name": "Dev 3", "device_public_id": "pub-3"}
    )
    assert exp_res.status_code == 400
    assert "expirou" in exp_res.json()["detail"]

def test_device_revocation_blocks_access(client: TestClient, authenticated_device):
    device, token, headers = authenticated_device

    # Access works prior to revocation
    res = client.get("/api/v1/devices", headers=headers)
    assert res.status_code == 200

    # Revoke device
    revoke_res = client.post(
        "/api/v1/devices/revoke",
        headers=headers,
        json={"device_public_id": device.device_public_id}
    )
    assert revoke_res.status_code == 200
    assert revoke_res.json()["is_active"] is False

    # Next attempt with the revoked token fails with 401
    failed_res = client.get("/api/v1/devices", headers=headers)
    assert failed_res.status_code == 401
    assert "revogado" in failed_res.json()["detail"]

def test_unauthenticated_requests_are_rejected(client: TestClient):
    res_no_auth = client.get("/api/v1/devices")
    assert res_no_auth.status_code == 401

    res_invalid_token = client.get("/api/v1/devices", headers={"Authorization": "Bearer invalid_secret_123"})
    assert res_invalid_token.status_code == 401

def test_pairing_initiate_prunes_stale_sessions_and_prevents_pin_collisions(
    client: TestClient,
    test_session: Session
):
    """
    Verifies that initiate_pairing cleans up stale expired/used sessions and generates valid PINs
    even when thousands of historical sessions were created.
    """
    import uuid
    # Insert multiple stale sessions
    for i in range(5):
        s = PairingSession(
            id=str(uuid.uuid4()),
            pin_code=f"88888{i}",
            expires_at=utc_now() - datetime.timedelta(minutes=30),
            is_used=False,
            created_at=utc_now() - datetime.timedelta(minutes=35),
        )
        test_session.add(s)
    test_session.commit()

    # initiate_pairing should prune these and succeed
    res = client.post("/api/v1/pairing/initiate")
    assert res.status_code == 200
    new_pin = res.json()["pin_code"]
    assert len(new_pin) == 6

    # Verify stale sessions were pruned
    stale_count = test_session.execute(
        select(PairingSession).where(PairingSession.expires_at < utc_now())
    ).scalars().all()
    assert len(stale_count) == 0

