import pytest
from fastapi.testclient import TestClient

def test_customer_crud_and_statement(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Create Customer
    payload = {
        "name": "Supermercado Progresso Ltda",
        "document_cpf_cnpj": "12.345.678/0001-99",
        "phone": "(11) 98765-4321",
        "address": "Av. Brasil, 1500, Galpao 4",
        "credit_limit_cents": 500000, # R$ 5.000,00
        "notes": "Cliente corporativo faturado quinzenal",
    }
    resp = client.post("/api/v1/customers", json=payload, headers=headers)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["name"] == payload["name"]
    assert data["document_cpf_cnpj"] == payload["document_cpf_cnpj"]
    assert data["credit_limit_cents"] == 500000
    assert data["current_debt_cents"] == 0
    assert data["is_active"] is True
    cust_id = data["id"]

    # 2. Duplicate document conflict
    dup_resp = client.post("/api/v1/customers", json=payload, headers=headers)
    assert dup_resp.status_code == 409
    assert dup_resp.json()["detail"]["error_code"] == "CUSTOMER_DOCUMENT_CONFLICT"

    # 3. Get Customer by ID
    get_resp = client.get(f"/api/v1/customers/{cust_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == cust_id

    # 4. Update Customer
    upd_payload = {
        "name": "Supermercado Progresso & Cia",
        "credit_limit_cents": 750000, # R$ 7.500,00
    }
    upd_resp = client.put(f"/api/v1/customers/{cust_id}", json=upd_payload, headers=headers)
    assert upd_resp.status_code == 200
    assert upd_resp.json()["name"] == "Supermercado Progresso & Cia"
    assert upd_resp.json()["credit_limit_cents"] == 750000

    # 5. List Customers with search
    list_resp = client.get("/api/v1/customers?search=Progresso", headers=headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["id"] == cust_id

    # 6. Customer statement initially empty
    stmt_resp = client.get(f"/api/v1/customers/{cust_id}/statement", headers=headers)
    assert stmt_resp.status_code == 200
    stmt_data = stmt_resp.json()
    assert stmt_data["current_debt_cents"] == 0
    assert stmt_data["available_credit_cents"] == 750000
    assert len(stmt_data["entries"]) == 0

    # 7. Soft Delete (inactivate)
    del_resp = client.delete(f"/api/v1/customers/{cust_id}", headers=headers)
    assert del_resp.status_code == 200
    assert del_resp.json()["is_active"] is False

    # Filter active only should return empty
    active_resp = client.get("/api/v1/customers?is_active=true", headers=headers)
    assert len(active_resp.json()) == 0

    # Reactivate customer
    reactivate_resp = client.put(f"/api/v1/customers/{cust_id}", json={"is_active": True}, headers=headers)
    assert reactivate_resp.status_code == 200
    assert reactivate_resp.json()["is_active"] is True


def test_customer_validation_and_normalization(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Whitespace-only name rejected with 422
    resp_empty = client.post("/api/v1/customers", json={"name": ""}, headers=headers)
    assert resp_empty.status_code == 422

    resp_ws = client.post("/api/v1/customers", json={"name": "    "}, headers=headers)
    assert resp_ws.status_code == 422

    # 2. Blank document, phone, address, notes normalized to None
    resp_norm = client.post(
        "/api/v1/customers",
        json={
            "name": "Cliente Sem Documento",
            "document_cpf_cnpj": "   ",
            "phone": "  ",
            "address": "",
            "notes": "   ",
        },
        headers=headers,
    )
    assert resp_norm.status_code == 201, resp_norm.text
    cust = resp_norm.json()
    assert cust["document_cpf_cnpj"] is None
    assert cust["phone"] is None
    assert cust["address"] is None
    assert cust["notes"] is None

    # Another customer with empty document should NOT conflict (both are None)
    resp_norm2 = client.post(
        "/api/v1/customers",
        json={
            "name": "Segundo Cliente Sem Documento",
            "document_cpf_cnpj": "",
        },
        headers=headers,
    )
    assert resp_norm2.status_code == 201

    # 3. Update customer document to empty string normalizes to None
    upd_resp = client.put(
        f"/api/v1/customers/{cust['id']}",
        json={"document_cpf_cnpj": "   "},
        headers=headers,
    )
    assert upd_resp.status_code == 200
    assert upd_resp.json()["document_cpf_cnpj"] is None
