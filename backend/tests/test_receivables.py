import pytest
import datetime
from fastapi.testclient import TestClient
from tests.test_sales import _setup_inventory_and_basket


def test_receivables_and_partial_payments(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # 1. Create Customer
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Restaurante Central", "credit_limit_cents": 100000}, # R$ 1.000,00 limit
        headers=headers,
    ).json()

    # 2. Make credit sale of 2 baskets @ 10,000 cents = 20,000 cents (R$ 200,00)
    due_date = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=15)).isoformat()
    sale = client.post(
        "/api/v1/sales",
        json={
            "customer_id": customer["id"],
            "payment_mode": "CREDIT_TERM",
            "due_date": due_date,
            "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    ).json()
    receivable_id = sale["receivable_id"]
    assert receivable_id is not None

    # 3. List receivables
    rec_list = client.get("/api/v1/receivables?status=OPEN", headers=headers).json()
    assert len(rec_list) >= 1
    found = next(r for r in rec_list if r["id"] == receivable_id)
    assert found["original_amount_cents"] == 20000
    assert found["balance_cents"] == 20000
    assert found["paid_amount_cents"] == 0
    assert found["status"] == "OPEN"

    # 4. Partial Payment 1: R$ 50,00 (5,000 cents)
    pay1_resp = client.post(
        f"/api/v1/receivables/{receivable_id}/payments",
        json={"amount_cents": 5000, "payment_method": "PIX", "notes": "Primeira parcela"},
        headers=headers,
    )
    assert pay1_resp.status_code == 201, pay1_resp.text
    pay1 = pay1_resp.json()
    assert pay1["amount_cents"] == 5000
    assert pay1["status"] == "CONFIRMED"

    # Verify updated receivable details
    rec_detail = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec_detail["paid_amount_cents"] == 5000
    assert rec_detail["balance_cents"] == 15000
    assert rec_detail["status"] == "PARTIAL"
    assert len(rec_detail["payments"]) == 1

    # Verify sale payment_status updated to PARTIAL
    sale_chk = client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()
    assert sale_chk["payment_status"] == "PARTIAL"

    # 5. Overpaying must fail (attempting to pay 16,000 cents when balance is 15,000 cents)
    overpay = client.post(
        f"/api/v1/receivables/{receivable_id}/payments",
        json={"amount_cents": 16000, "payment_method": "CASH"},
        headers=headers,
    )
    assert overpay.status_code == 400

    # 6. Attempting to cancel sale with payments must fail with 400
    fail_cancel = client.post(
        f"/api/v1/sales/{sale['id']}/cancel",
        json={"reason": "Cancelamento indevido com pagamento existente"},
        headers=headers,
    )
    assert fail_cancel.status_code == 400

    # 7. Final Payment: remaining 15,000 cents
    pay2_resp = client.post(
        f"/api/v1/receivables/{receivable_id}/payments",
        json={"amount_cents": 15000, "payment_method": "CASH", "notes": "Quitacao final"},
        headers=headers,
    )
    assert pay2_resp.status_code == 201

    rec_paid = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec_paid["paid_amount_cents"] == 20000
    assert rec_paid["balance_cents"] == 0
    assert rec_paid["status"] == "PAID"

    # Verify sale payment_status updated to PAID
    sale_paid = client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()
    assert sale_paid["payment_status"] == "PAID"

    # 8. Customer statement reflects both payments and 0 debt
    cust_stmt = client.get(f"/api/v1/customers/{customer['id']}/statement", headers=headers).json()
    assert cust_stmt["current_debt_cents"] == 0
    assert len(cust_stmt["entries"]) == 3 # 1 sale + 2 payments

    # 9. Test payment reversal
    cancel_pay_resp = client.post(
        f"/api/v1/receivables/payments/{pay2_resp.json()['id']}/cancel",
        json={"reason": "Pagamento lancado em duplicidade por engano"},
        headers=headers,
    )
    assert cancel_pay_resp.status_code == 200
    rec_reopened = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec_reopened["status"] == "PARTIAL"
    assert rec_reopened["balance_cents"] == 15000

    # 10. Reverse the remaining payment (pay1)
    cancel_pay1_resp = client.post(
        f"/api/v1/receivables/payments/{pay1['id']}/cancel",
        json={"reason": "Estorno completo da primeira parcela"},
        headers=headers,
    )
    assert cancel_pay1_resp.status_code == 200
    rec_fully_open = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec_fully_open["status"] == "OPEN"
    assert rec_fully_open["balance_cents"] == 20000
    assert rec_fully_open["paid_amount_cents"] == 0

    # Verify sale payment_status reverted to PENDING
    sale_chk2 = client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()
    assert sale_chk2["payment_status"] == "PENDING"

    # 11. Now that all payments are reversed, cancelling the sale succeeds
    cancel_sale_ok = client.post(
        f"/api/v1/sales/{sale['id']}/cancel",
        json={"reason": "Cancelamento final apos estorno de todas as parcelas"},
        headers=headers,
    )
    assert cancel_sale_ok.status_code == 200
    sale_canceled = cancel_sale_ok.json()
    assert sale_canceled["status"] == "CANCELED"
    assert sale_canceled["payment_status"] == "CANCELED"

    # Receivable must be canceled and have balance_cents = 0
    rec_canceled = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec_canceled["status"] == "CANCELED"
    assert rec_canceled["balance_cents"] == 0

    # Customer debt must be 0
    cust_debt = client.get(f"/api/v1/customers/{customer['id']}", headers=headers).json()
    assert cust_debt["current_debt_cents"] == 0


def test_receivable_payment_idempotency(client: TestClient, authenticated_device):
    import uuid
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # 1. Create Customer
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Cliente Idempotencia", "credit_limit_cents": 50000},
        headers=headers,
    ).json()

    # 2. Make credit sale of 1 basket @ 10,000 cents
    sale = client.post(
        "/api/v1/sales",
        json={
            "customer_id": customer["id"],
            "payment_mode": "CREDIT_TERM",
            "items": [{"basket_type_id": basket["id"], "quantity": 1, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    ).json()
    receivable_id = sale["receivable_id"]

    # 3. Pay with X-Idempotency-Key
    idem_key = str(uuid.uuid4())
    headers_idem = {**headers, "X-Idempotency-Key": idem_key}
    pay_payload = {"amount_cents": 3000, "payment_method": "PIX", "notes": "Pagamento Idempotente"}

    resp1 = client.post(f"/api/v1/receivables/{receivable_id}/payments", json=pay_payload, headers=headers_idem)
    assert resp1.status_code == 201
    pay_id = resp1.json()["id"]

    # Replay identical payment request
    resp2 = client.post(f"/api/v1/receivables/{receivable_id}/payments", json=pay_payload, headers=headers_idem)
    assert resp2.status_code == 201
    assert resp2.json()["id"] == pay_id

    # Verify receivable only received ONE payment of 3000 (balance is 7000, not 4000)
    rec = client.get(f"/api/v1/receivables/{receivable_id}", headers=headers).json()
    assert rec["paid_amount_cents"] == 3000
    assert rec["balance_cents"] == 7000
    assert len(rec["payments"]) == 1
