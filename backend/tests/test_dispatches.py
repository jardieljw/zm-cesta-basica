import uuid
import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.products import BasketType
from app.models.customers import Customer
from app.services.inventory import record_inventory_movement, get_basket_stock
from app.services.receivables import record_receivable_payment
from app.schemas.receivables import ReceivablePaymentCreate


def _setup_test_basket_and_stock(client: TestClient, headers: dict, initial_stock: int = 20) -> str:
    """Helper to create a basket type and inject initial finished stock into STORE."""
    bt_res = client.post(
        "/api/v1/basket-types",
        json={
            "code": f"CESTA-{uuid.uuid4().hex[:6]}",
            "name": "Cesta Teste Expedicao",
            "description": "Cesta para teste de custodia",
            "default_price_cents": 10000, # R$ 100,00
            "allows_custom": False,
        },
        headers=headers,
    )
    assert bt_res.status_code == 201
    basket_id = bt_res.json()["id"]

    # Inject finished baskets into STORE via manual adjustment
    adj_res = client.post(
        "/api/v1/inventory/adjustments",
        json={
            "item_type": "BASKET",
            "basket_type_id": basket_id,
            "adjustment_type": "IN",
            "quantity_delta": initial_stock,
            "reason": "Estoque inicial para teste de expedicao",
        },
        headers=headers,
    )
    assert adj_res.status_code == 201
    return basket_id


def test_responsible_person_crud_and_custody(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Create responsible person
    create_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={
            "name": "Carlos Entregador",
            "phone": "(11) 99999-1111",
            "notes": "Entregador de rotas zona norte",
            "is_active": True,
        },
        headers=headers,
    )
    assert create_res.status_code == 201
    person = create_res.json()
    person_id = person["id"]
    assert person["name"] == "Carlos Entregador"
    assert person["is_active"] is True

    # 2. Get details
    get_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["name"] == "Carlos Entregador"

    # 3. Update details
    put_res = client.put(
        f"/api/v1/dispatches/responsible-persons/{person_id}",
        json={"phone": "(11) 98888-2222", "notes": "Atualizado"},
        headers=headers,
    )
    assert put_res.status_code == 200
    assert put_res.json()["phone"] == "(11) 98888-2222"

    # 4. List responsible persons
    list_res = client.get("/api/v1/dispatches/responsible-persons?search=Carlos", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1

    # 5. Custody balance is initially 0
    custody_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert custody_res.status_code == 200
    assert custody_res.json()["total_custody_baskets"] == 0


def test_dispatch_physical_stock_transfer_and_balances(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=20)

    # Create responsible person
    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Marcos Rota", "phone": "(11) 97777-3333"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    # Dispatch 15 baskets to Marcos
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "notes": "Saida Rota Manha",
            "items": [
                {
                    "basket_type_id": basket_id,
                    "quantity": 15,
                    "unit_price_cents": 10000,
                    "notes": "Padrao",
                }
            ],
        },
        headers=headers,
    )
    assert disp_res.status_code == 201
    dispatch = disp_res.json()
    assert dispatch["total_items_quantity"] == 15
    assert dispatch["status"] == "OPEN"
    assert dispatch["dispatch_number"] >= 1

    # Verify live balances:
    # 1. Custody for Marcos in TRANSIT must be exactly 15
    custody_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert custody_res.status_code == 200
    assert custody_res.json()["total_custody_baskets"] == 15

    # 2. Store inventory balance must be exactly 20 - 15 = 5
    summary_res = client.get("/api/v1/inventory/summary", headers=headers)
    assert summary_res.status_code == 200
    # Or test by attempting to dispatch 6 baskets (only 5 left in STORE)
    over_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 6}],
        },
        headers=headers,
    )
    assert over_res.status_code == 409
    assert over_res.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"


def test_cancel_open_dispatch(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=10)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Entregador Cancelamento"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    # Dispatch 6 baskets
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 6}],
        },
        headers=headers,
    )
    assert disp_res.status_code == 201
    disp_id = disp_res.json()["id"]

    # Verify custody is 6
    c_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert c_res.json()["total_custody_baskets"] == 6

    # Cancel dispatch
    cancel_res = client.post(
        f"/api/v1/dispatches/{disp_id}/cancel",
        json={"reason": "Veiculo quebrou antes de sair"},
        headers=headers,
    )
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "CANCELED"

    # Verify custody is back to 0
    c_res_after = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert c_res_after.json()["total_custody_baskets"] == 0

    # Store balance is back to 10: dispatching 10 should now succeed!
    re_disp = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 10}],
        },
        headers=headers,
    )
    assert re_disp.status_code == 201


def test_route_sale_from_custody_prevention_of_double_deduction(client: TestClient, authenticated_device):
    """
    CRITICAL ARCHITECTURAL TEST:
    A sale performed in COMMERCIAL_ROUTE under custody of a responsible person:
    1. Debits TRANSIT stock.
    2. Does NOT debit STORE stock again.
    3. Direct store sales do not touch TRANSIT stock.
    """
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=20)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Joao Rota"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    # Dispatch 12 baskets: STORE has 8, TRANSIT has 12
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 12}],
        },
        headers=headers,
    )
    assert disp_res.status_code == 201
    dispatch_id = disp_res.json()["id"]

    # 1. Sell 5 baskets on route linked to this dispatch
    route_sale_res = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "responsible_person_id": person_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 5, "unit_price_cents": 12000}],
        },
        headers=headers,
    )
    assert route_sale_res.status_code == 201
    sale_data = route_sale_res.json()
    assert sale_data["dispatch_id"] == dispatch_id
    assert sale_data["responsible_person_id"] == person_id

    # VERIFICATION:
    # Custody in TRANSIT must be 12 - 5 = 7
    custody_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert custody_res.json()["total_custody_baskets"] == 7

    # STORE stock must still be exactly 8 (not 8 - 5 = 3!).
    # We prove this by performing a direct store sale of 8 baskets:
    store_sale_res = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "DIRECT_STORE",
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 8, "unit_price_cents": 12000}],
        },
        headers=headers,
    )
    assert store_sale_res.status_code == 201 # Proves STORE had all 8 intact!

    # Now STORE stock is 0. Attempting direct store sale of 1 basket fails:
    store_fail_res = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "DIRECT_STORE",
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 1, "unit_price_cents": 12000}],
        },
        headers=headers,
    )
    assert store_fail_res.status_code == 409
    assert store_fail_res.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"

    # But TRANSIT still has 7! Attempting to sell 7 on route succeeds even though STORE is 0:
    route_sale_res2 = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 7, "unit_price_cents": 12000}],
        },
        headers=headers,
    )
    assert route_sale_res2.status_code == 201

    # Now TRANSIT has 0. Attempting to sell 1 on route fails:
    route_fail_res = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 1, "unit_price_cents": 12000}],
        },
        headers=headers,
    )
    assert route_fail_res.status_code == 409
    assert route_fail_res.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"


def test_dispatch_returns_and_losses(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=10)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Lucia Entregadora"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    # Dispatch 10 baskets
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 10}],
        },
        headers=headers,
    )
    assert disp_res.status_code == 201
    dispatch_id = disp_res.json()["id"]

    # 1. Return 3 intact baskets
    ret_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/returns",
        json={
            "basket_type_id": basket_id,
            "quantity": 3,
            "notes": "Cliente cancelou pedido antes da entrega",
        },
        headers=headers,
    )
    assert ret_res.status_code == 201
    assert ret_res.json()["quantity"] == 3

    # Custody is now 10 - 3 = 7
    c_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert c_res.json()["total_custody_baskets"] == 7

    # 2. Record 2 damaged baskets as loss
    loss_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/losses",
        json={
            "basket_type_id": basket_id,
            "quantity": 2,
            "reason": "Embalagem rasgou e pacote de acucar furou",
        },
        headers=headers,
    )
    assert loss_res.status_code == 201
    assert loss_res.json()["quantity"] == 2

    # Custody is now 7 - 2 = 5
    c_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert c_res.json()["total_custody_baskets"] == 5

    # 3. Attempting loss without reason is rejected
    loss_fail = client.post(
        f"/api/v1/dispatches/{dispatch_id}/losses",
        json={
            "basket_type_id": basket_id,
            "quantity": 1,
            "reason": " ",
        },
        headers=headers,
    )
    assert loss_fail.status_code == 422 or loss_fail.status_code == 400

    # 4. Attempting to return 6 baskets (only 5 left in custody) fails 409
    over_ret = client.post(
        f"/api/v1/dispatches/{dispatch_id}/returns",
        json={"basket_type_id": basket_id, "quantity": 6},
        headers=headers,
    )
    assert over_ret.status_code == 409
    assert over_ret.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"


def test_segregated_payments_debt_collection_and_repayments(client: TestClient, authenticated_device):
    """
    Tests financial reconciliation:
    - Cash sales: driver owes cash in hand.
    - Pix/Card sales direct to company: company already received, driver DOES NOT owe cash.
    - Credit sales: receivable created, driver does not owe cash.
    - Route debt collection: customer amortizes existing receivable in cash.
    - Route expense: deducted from cash in hand.
    - Partial cash repayments by driver.
    """
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=20)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Roberto Financeiro"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    cust_res = client.post(
        "/api/v1/customers",
        json={"name": "Cliente Rota Teste", "credit_limit_cents": 50000},
        headers=headers,
    )
    customer_id = cust_res.json()["id"]

    # Dispatch 10 baskets
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 10}],
        },
        headers=headers,
    )
    dispatch_id = disp_res.json()["id"]

    # 1. Sale 1: 2 baskets in CASH @ R$ 100,00 each = R$ 200,00 (20000 cents)
    s1 = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 2, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    assert s1.status_code == 201

    # 2. Sale 2: 2 baskets via PIX direct to company account = R$ 200,00 (20000 cents)
    s2 = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "payment_mode": "PIX",
            "items": [{"basket_type_id": basket_id, "quantity": 2, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    assert s2.status_code == 201

    # 3. Sale 3: 2 baskets on CREDIT_TERM (fiado) = R$ 200,00 (20000 cents)
    s3 = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "customer_id": customer_id,
            "payment_mode": "CREDIT_TERM",
            "items": [{"basket_type_id": basket_id, "quantity": 2, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    assert s3.status_code == 201
    receivable_id = s3.json()["receivable_id"]

    # 4. Route debt collection: Customer amortizes R$ 50,00 (5000 cents) in cash for this receivable
    rec_pay_res = client.post(
        f"/api/v1/receivables/{receivable_id}/payments",
        json={
            "amount_cents": 5000,
            "payment_method": "CASH",
            "dispatch_id": dispatch_id,
            "notes": "Cobrado na rota",
        },
        headers=headers,
    )
    assert rec_pay_res.status_code == 201

    # 5. Route authorized expense: Fuel R$ 40,00 (4000 cents)
    exp_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/expenses",
        json={
            "amount_cents": 4000,
            "description": "Combustivel posto Shell",
            "authorized_by": "Gerente Paulo",
        },
        headers=headers,
    )
    assert exp_res.status_code == 201

    # Check Reconciliation numbers:
    # Expected Cash = Cash Sales (20000) + Cash Debt (5000) - Expense (4000) = 21000 cents (R$ 210,00)
    # Direct Company Received = PIX (20000 cents)
    recon_res = client.get(f"/api/v1/dispatches/{dispatch_id}/reconciliation", headers=headers)
    assert recon_res.status_code == 200
    recon = recon_res.json()
    assert recon["cash_sales_cents"] == 20000
    assert recon["direct_company_received_cents"] == 20000
    assert recon["credit_sales_cents"] == 20000
    assert recon["cash_debt_collected_cents"] == 5000
    assert recon["expenses_cents"] == 4000
    assert recon["expected_cash_cents"] == 21000
    assert recon["actual_repaid_cash_cents"] == 0
    assert recon["pending_cash_cents"] == 21000

    # 6. Driver makes partial repayment of R$ 150,00 (15000 cents)
    rep1_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/repayments",
        json={"amount_cents": 15000, "notes": "Repasse parcial 1"},
        headers=headers,
    )
    assert rep1_res.status_code == 201

    recon_res2 = client.get(f"/api/v1/dispatches/{dispatch_id}/reconciliation", headers=headers)
    recon2 = recon_res2.json()
    assert recon2["actual_repaid_cash_cents"] == 15000
    assert recon2["pending_cash_cents"] == 6000

    # 7. Driver hands over remaining R$ 60,00 (6000 cents)
    rep2_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/repayments",
        json={"amount_cents": 6000, "notes": "Repasse final"},
        headers=headers,
    )
    assert rep2_res.status_code == 201

    recon_res3 = client.get(f"/api/v1/dispatches/{dispatch_id}/reconciliation", headers=headers)
    recon3 = recon_res3.json()
    assert recon3["actual_repaid_cash_cents"] == 21000
    assert recon3["pending_cash_cents"] == 0
    assert recon3["cash_discrepancy_cents"] == 0
    assert recon3["has_cash_discrepancy"] is False


def test_reconciliation_4_terms_and_settlement_with_discrepancy(client: TestClient, authenticated_device):
    """
    Tests:
    1. Canonical 4-term physical equation: Dispatched = Sold + Returned + Lost + In Custody.
    2. Detection of discrepancy -> marks PENDING_INVESTIGATION.
    3. Documenting investigation notes and resolving it.
    """
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=20)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Sandra Auditoria"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    # Dispatch 10 baskets
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 10, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    dispatch_id = disp_res.json()["id"]

    # Sell 4 baskets in cash (40000 cents)
    client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": dispatch_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 4, "unit_price_cents": 10000}],
        },
        headers=headers,
    )

    # Return 3 intact baskets
    client.post(
        f"/api/v1/dispatches/{dispatch_id}/returns",
        json={"basket_type_id": basket_id, "quantity": 3},
        headers=headers,
    )

    # 1 basket lost
    client.post(
        f"/api/v1/dispatches/{dispatch_id}/losses",
        json={"basket_type_id": basket_id, "quantity": 1, "reason": "Avaria na viagem"},
        headers=headers,
    )

    # Current transit custody: 10 - 4 - 3 - 1 = 2 baskets remaining!
    # Repay full cash (40000 cents)
    client.post(
        f"/api/v1/dispatches/{dispatch_id}/repayments",
        json={"amount_cents": 40000},
        headers=headers,
    )

    # First settlement check:
    # 4 terms: Dispatched (10) = Sold (4) + Returned (3) + Lost (1) + Remaining (2) = 10 -> Discrepancy is 0!
    recon = client.get(f"/api/v1/dispatches/{dispatch_id}/reconciliation", headers=headers).json()
    assert recon["total_dispatched_qty"] == 10
    assert recon["total_sold_qty"] == 4
    assert recon["total_returned_qty"] == 3
    assert recon["total_lost_qty"] == 1
    assert recon["total_remaining_custody_qty"] == 2
    assert recon["basket_discrepancy_qty"] == 0

    # Settle: Because 2 remain in custody, status will be IN_CUSTODY_RESOLVED
    settle_res = client.post(
        f"/api/v1/dispatches/{dispatch_id}/settlement",
        json={"audited_by": "Auditor Marcelo"},
        headers=headers,
    )
    assert settle_res.status_code == 201
    assert settle_res.json()["status"] == "IN_CUSTODY_RESOLVED"

    # Now let's create another dispatch to simulate a missing basket discrepancy:
    disp2_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": person_id,
            "items": [{"basket_type_id": basket_id, "quantity": 5, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    disp2_id = disp2_res.json()["id"]

    # Sell 2 baskets in cash (20000 cents)
    client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "dispatch_id": disp2_id,
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket_id, "quantity": 2, "unit_price_cents": 10000}],
        },
        headers=headers,
    )

    # Driver only repays R$ 150,00 (15000 cents) instead of R$ 200,00 -> cash discrepancy!
    client.post(
        f"/api/v1/dispatches/{disp2_id}/repayments",
        json={"amount_cents": 15000},
        headers=headers,
    )

    # Settle disp2 with cash shortfall:
    settle_disc = client.post(
        f"/api/v1/dispatches/{disp2_id}/settlement",
        json={"audited_by": "Auditor Marcelo", "notes": "Faltou R$ 50,00 no repasse"},
        headers=headers,
    )
    assert settle_disc.status_code == 201
    assert settle_disc.json()["status"] == "PENDING_INVESTIGATION"

    # Dispatch remains OPEN
    disp2_check = client.get(f"/api/v1/dispatches/{disp2_id}", headers=headers).json()
    assert disp2_check["status"] == "OPEN"

    # Document investigation and resolve
    invest_res = client.put(
        f"/api/v1/dispatches/{disp2_id}/settlement/investigation",
        json={
            "investigation_notes": "Entregador transferiu os R$ 50,00 faltantes via Pix comprovante #12345",
            "mark_as_resolved": True,
        },
        headers=headers,
    )
    assert invest_res.status_code == 200
    assert invest_res.json()["status"] == "RESOLVED"
    assert "comprovante #12345" in invest_res.json()["investigation_notes"]


def test_idempotency_dispatch_creation(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    basket_id = _setup_test_basket_and_stock(client, headers, initial_stock=10)

    p_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Idempotencia Teste"},
        headers=headers,
    )
    person_id = p_res.json()["id"]

    idempotency_headers = {**headers, "X-Idempotency-Key": f"disp-key-{uuid.uuid4().hex}"}
    payload = {
        "responsible_person_id": person_id,
        "items": [{"basket_type_id": basket_id, "quantity": 4}],
    }

    res1 = client.post("/api/v1/dispatches", json=payload, headers=idempotency_headers)
    assert res1.status_code == 201
    d1 = res1.json()

    # Replay identical request with same idempotency key
    res2 = client.post("/api/v1/dispatches", json=payload, headers=idempotency_headers)
    assert res2.status_code == 201
    d2 = res2.json()

    assert d1["id"] == d2["id"]
    assert d1["dispatch_number"] == d2["dispatch_number"]

    # Custody should be exactly 4, NOT 8!
    custody_res = client.get(f"/api/v1/dispatches/responsible-persons/{person_id}/custody", headers=headers)
    assert custody_res.json()["total_custody_baskets"] == 4
