import pytest
from fastapi.testclient import TestClient

def test_health_check(client: TestClient):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["database_status"] == "ok"
    assert "version" in data
    assert "tls_fingerprint_sha256" in data
    # Fingerprint must have hex pairs separated by colons (32 bytes = 64 hex chars + 31 colons = 95 chars)
    fp = data["tls_fingerprint_sha256"]
    assert len(fp.split(":")) == 32

def test_ping_endpoint(client: TestClient):
    response = client.get("/api/v1/ping")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_root_endpoint(client: TestClient):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "online"
