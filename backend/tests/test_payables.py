import uuid
import datetime
import pytest
from fastapi.testclient import TestClient


def test_single_payable_lifecycle_and_payments(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Get default cash account
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    assert len(accounts) >= 1
    acc_id = accounts[0]["id"]
    initial_acc_bal = accounts[0]["current_balance_cents"]

    # 2. Create single account payable (e.g. Aluguel de R$ 1.500,00 = 150000 cents)
    due_date = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=10)).isoformat()
    create_payload = {
        "description": "Aluguel Galpao",
        "beneficiary": "Imobiliaria Progresso",
        "category": "ALUGUEL",
        "nature": "BUSINESS",
        "original_amount_cents": 150000,
        "due_date": due_date,
        "payment_method": "BOLETO",
        "total_installments": 1,
        "notes": "Referente ao mes corrente",
    }
    resp = client.post("/api/v1/payables", json=create_payload, headers=headers)
    assert resp.status_code == 201, resp.text
    payables = resp.json()
    assert len(payables) == 1
    p = payables[0]
    p_id = p["id"]
    assert p["payable_number"] >= 1
    assert p["original_amount_cents"] == 150000
    assert p["balance_cents"] == 150000
    assert p["paid_amount_cents"] == 0
    assert p["status"] == "OPEN"
    assert p["category"] == "ALUGUEL"
    assert p["installment_number"] == 1
    assert p["total_installments"] == 1

    # 3. Partial payment 1: R$ 500,00 (50000 cents)
    pay1_resp = client.post(
        f"/api/v1/payables/{p_id}/payments",
        json={
            "amount_cents": 50000,
            "account_id": acc_id,
            "payment_method": "BOLETO",
            "notes": "Adiantamento",
        },
        headers=headers,
    )
    assert pay1_resp.status_code == 201, pay1_resp.text
    pay1 = pay1_resp.json()
    assert pay1["amount_cents"] == 50000
    assert pay1["status"] == "CONFIRMED"

    # Verify updated payable status
    detail = client.get(f"/api/v1/payables/{p_id}", headers=headers).json()
    assert detail["paid_amount_cents"] == 50000
    assert detail["balance_cents"] == 100000
    assert detail["status"] == "PARTIAL"
    assert len(detail["payments"]) == 1

    # Verify treasury was debited
    acc_after = client.get(f"/api/v1/treasury/accounts/{acc_id}", headers=headers).json()
    assert acc_after["current_balance_cents"] == initial_acc_bal - 50000

    # 4. Attempt to pay more than balance (100001 cents) -> 400
    overpay = client.post(
        f"/api/v1/payables/{p_id}/payments",
        json={
            "amount_cents": 100001,
            "account_id": acc_id,
            "payment_method": "BOLETO",
        },
        headers=headers,
    )
    assert overpay.status_code == 400

    # 5. Cannot cancel payable with payments -> 400
    cancel_fail = client.post(
        f"/api/v1/payables/{p_id}/cancel",
        json={"reason": "Tentativa indevida de cancelar titulo com pagamento"},
        headers=headers,
    )
    assert cancel_fail.status_code == 400

    # 6. Final payment: settle remaining 100000 cents
    pay2_resp = client.post(
        f"/api/v1/payables/{p_id}/payments",
        json={
            "amount_cents": 100000,
            "account_id": acc_id,
            "payment_method": "BOLETO",
            "notes": "Quitacao total",
        },
        headers=headers,
    )
    assert pay2_resp.status_code == 201
    detail_settled = client.get(f"/api/v1/payables/{p_id}", headers=headers).json()
    assert detail_settled["paid_amount_cents"] == 150000
    assert detail_settled["balance_cents"] == 0
    assert detail_settled["status"] == "PAID"

    # Cannot pay settled payable -> 400
    pay3_fail = client.post(
        f"/api/v1/payables/{p_id}/payments",
        json={"amount_cents": 100, "account_id": acc_id, "payment_method": "BOLETO"},
        headers=headers,
    )
    assert pay3_fail.status_code == 400

    # 7. Reverse pay2
    rev_resp = client.post(
        f"/api/v1/payables/payments/{pay2_resp.json()['id']}/cancel",
        json={"reason": "Estorno da quitacao por erro operacional"},
        headers=headers,
    )
    assert rev_resp.status_code == 200
    assert rev_resp.json()["status"] == "REVERSED"

    detail_rev = client.get(f"/api/v1/payables/{p_id}", headers=headers).json()
    assert detail_rev["status"] == "PARTIAL"
    assert detail_rev["balance_cents"] == 100000
    assert detail_rev["paid_amount_cents"] == 50000

    # Account balance reimbursed in treasury
    acc_after_rev = client.get(f"/api/v1/treasury/accounts/{acc_id}", headers=headers).json()
    assert acc_after_rev["current_balance_cents"] == initial_acc_bal - 50000


def test_multi_installment_payables_and_cent_splitting(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # Split 10000 cents (R$ 100,00) into 3 installments
    # 10000 // 3 = 3333 with remainder 1. First installment must be 3334, then 3333, 3333
    base_due = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30)).isoformat()
    resp = client.post(
        "/api/v1/payables",
        json={
            "description": "Equipamento Seladora",
            "beneficiary": "Maquinas Industriais SA",
            "category": "MANUTENCAO",
            "nature": "BUSINESS",
            "original_amount_cents": 10000,
            "due_date": base_due,
            "payment_method": "BOLETO",
            "total_installments": 3,
        },
        headers=headers,
    )
    assert resp.status_code == 201, resp.text
    installments = resp.json()
    assert len(installments) == 3

    inst1, inst2, inst3 = installments
    assert inst1["installment_number"] == 1
    assert inst1["total_installments"] == 3
    assert inst1["original_amount_cents"] == 3334
    assert inst1["balance_cents"] == 3334

    assert inst2["installment_number"] == 2
    assert inst2["total_installments"] == 3
    assert inst2["original_amount_cents"] == 3333

    assert inst3["installment_number"] == 3
    assert inst3["total_installments"] == 3
    assert inst3["original_amount_cents"] == 3333

    # Total must sum to exact 10000 cents
    assert inst1["original_amount_cents"] + inst2["original_amount_cents"] + inst3["original_amount_cents"] == 10000

    # Group ID must match across installments
    assert inst1["installment_group_id"] is not None
    assert inst1["installment_group_id"] == inst2["installment_group_id"] == inst3["installment_group_id"]

    # Cancel one open installment
    can_resp = client.post(
        f"/api/v1/payables/{inst3['id']}/cancel",
        json={"reason": "Cancelamento amigavel da ultima parcela"},
        headers=headers,
    )
    assert can_resp.status_code == 200
    assert can_resp.json()["status"] == "CANCELED"
    assert can_resp.json()["balance_cents"] == 0


def test_payables_filters(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # Create distinct payables
    due_future = datetime.datetime(2027, 5, 20, 12, 0, 0, tzinfo=datetime.timezone.utc).isoformat()
    client.post(
        "/api/v1/payables",
        json={
            "description": "Energia Eletrica Maio 2027",
            "beneficiary": "Companhia Energetica",
            "category": "ENERGIA",
            "nature": "BUSINESS",
            "original_amount_cents": 45000,
            "due_date": due_future,
            "payment_method": "BOLETO",
        },
        headers=headers,
    )

    client.post(
        "/api/v1/payables",
        json={
            "description": "Retirada Particular Socio",
            "beneficiary": "Socio Majoritario",
            "category": "RETIRADA_SOCIO",
            "nature": "PERSONAL_WITHDRAWAL",
            "original_amount_cents": 80000,
            "due_date": due_future,
            "payment_method": "PIX",
        },
        headers=headers,
    )

    # Filter by category
    res_energy = client.get("/api/v1/payables?category=ENERGIA", headers=headers).json()
    assert any(p["category"] == "ENERGIA" and p["beneficiary"] == "Companhia Energetica" for p in res_energy)
    assert not any(p["category"] == "RETIRADA_SOCIO" for p in res_energy)

    # Filter by nature
    res_personal = client.get("/api/v1/payables?nature=PERSONAL_WITHDRAWAL", headers=headers).json()
    assert any(p["nature"] == "PERSONAL_WITHDRAWAL" for p in res_personal)
    assert not any(p["category"] == "ENERGIA" for p in res_personal)

    # Filter by beneficiary
    res_ben = client.get("/api/v1/payables?beneficiary=Energetica", headers=headers).json()
    assert len(res_ben) >= 1
    assert all("Energetica" in p["beneficiary"] for p in res_ben)

    # Filter by year and month
    res_ym = client.get("/api/v1/payables?year=2027&month=5", headers=headers).json()
    assert len(res_ym) >= 2


def test_payable_idempotency(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]

    idem_key_create = str(uuid.uuid4())
    headers_idem_create = {**headers, "X-Idempotency-Key": idem_key_create}

    due_date = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=15)).isoformat()
    payload = {
        "description": "Telefonia e Internet",
        "beneficiary": "Operadora Telecom",
        "category": "OUTROS",
        "nature": "BUSINESS",
        "original_amount_cents": 25000,
        "due_date": due_date,
        "payment_method": "BOLETO",
    }

    # 1. First create
    resp1 = client.post("/api/v1/payables", json=payload, headers=headers_idem_create)
    assert resp1.status_code == 201
    p1 = resp1.json()
    p_id = p1[0]["id"]

    # 2. Replay create with same key
    resp2 = client.post("/api/v1/payables", json=payload, headers=headers_idem_create)
    assert resp2.status_code == 201
    assert resp2.json()[0]["id"] == p_id

    # 3. Pay idempotency
    idem_key_pay = str(uuid.uuid4())
    headers_idem_pay = {**headers, "X-Idempotency-Key": idem_key_pay}
    pay_payload = {
        "amount_cents": 10000,
        "account_id": acc_id,
        "payment_method": "BOLETO",
        "notes": "Pagamento parcial 1",
    }

    pay1 = client.post(f"/api/v1/payables/{p_id}/payments", json=pay_payload, headers=headers_idem_pay)
    assert pay1.status_code == 201
    pay1_id = pay1.json()["id"]

    pay2 = client.post(f"/api/v1/payables/{p_id}/payments", json=pay_payload, headers=headers_idem_pay)
    assert pay2.status_code == 201
    assert pay2.json()["id"] == pay1_id

    # Verify payable was only debited once (paid 10000, balance 15000)
    detail = client.get(f"/api/v1/payables/{p_id}", headers=headers).json()
    assert detail["paid_amount_cents"] == 10000
    assert detail["balance_cents"] == 15000
    assert len(detail["payments"]) == 1


def test_purchases_on_credit_integration(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # Setup a product
    p_resp = client.post(
        "/api/v1/products",
        json={
            "name": "Feijao Preto Insumo",
            "category": "ALIMENTACAO",
            "base_unit": "UNIT",
            "cost_price_cents": 500,
            "sale_price_cents": 750,
        },
        headers=headers,
    )
    assert p_resp.status_code == 201, p_resp.text
    product_id = p_resp.json()["id"]

    due = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=28)).isoformat()
    # Purchase ON_CREDIT (a prazo)
    purchase_resp = client.post(
        "/api/v1/purchases",
        json={
            "supplier_name": "Distribuidora de Graos Silva",
            "notes": "NF-9988",
            "payment_mode": "CREDIT_TERM",
            "due_date": due,
            "status": "CONFIRMED",
            "items": [
                {
                    "product_id": product_id,
                    "packaging_id": None,
                    "packages_count": 100,
                    "unit_price_cents": 500,
                }
            ],
        },
        headers=headers,
    )
    assert purchase_resp.status_code == 201, purchase_resp.text
    purchase = purchase_resp.json()
    purchase_id = purchase["id"]
    total_cost = purchase["total_amount_cents"]
    assert total_cost == 50000  # 100 * 500 = 50.000 cents

    # Verify AccountPayable was automatically created
    payables = client.get(f"/api/v1/payables?beneficiary=Distribuidora de Graos Silva", headers=headers).json()
    matching = [p for p in payables if p.get("purchase_id") == purchase_id]
    assert len(matching) == 1
    payable = matching[0]
    assert payable["status"] == "OPEN"
    assert payable["balance_cents"] == 50000
    assert payable["original_amount_cents"] == 50000

    # Pay the linked payable
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]
    pay_resp = client.post(
        f"/api/v1/payables/{payable['id']}/payments",
        json={"amount_cents": 50000, "account_id": acc_id, "payment_method": "BOLETO"},
        headers=headers,
    )
    assert pay_resp.status_code == 201

    pay_chk = client.get(f"/api/v1/payables/{payable['id']}", headers=headers).json()
    assert pay_chk["status"] == "PAID"
    assert pay_chk["balance_cents"] == 0


def test_recurrent_payable_next_recurrence_generation(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    due = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=10)).isoformat()

    # 1. Create a recurrent payable (Aluguel mensal)
    create_resp = client.post(
        "/api/v1/payables",
        json={
            "description": "Aluguel Predio Sede",
            "beneficiary": "Locadora Santana",
            "category": "ALUGUEL",
            "nature": "BUSINESS",
            "original_amount_cents": 120000,
            "due_date": due,
            "payment_method": "BOLETO",
            "is_recurrent": True,
            "recurrence_period": "MONTHLY",
        },
        headers=headers,
    )
    assert create_resp.status_code == 201
    p1 = create_resp.json()[0]
    p1_id = p1["id"]
    assert p1["is_recurrent"] is True
    assert p1["recurrence_period"] == "MONTHLY"

    # 2. Generate next recurrence cycle
    next_resp = client.post(f"/api/v1/payables/{p1_id}/next-recurrence", headers=headers)
    assert next_resp.status_code == 201, next_resp.text
    p2 = next_resp.json()
    assert p2["id"] != p1_id
    assert p2["payable_number"] > p1["payable_number"]
    assert p2["original_amount_cents"] == 120000
    assert p2["balance_cents"] == 120000
    assert p2["status"] == "OPEN"
    assert p2["installment_number"] == p1["installment_number"] + 1

    # Check due date is approx 30 days ahead
    p1_due = datetime.datetime.fromisoformat(p1["due_date"])
    p2_due = datetime.datetime.fromisoformat(p2["due_date"])
    if p1_due.tzinfo is None:
        p1_due = p1_due.replace(tzinfo=datetime.timezone.utc)
    if p2_due.tzinfo is None:
        p2_due = p2_due.replace(tzinfo=datetime.timezone.utc)
    diff_days = (p2_due - p1_due).total_seconds() / 86400
    assert 29 <= diff_days <= 31

    # 3. Generating recurrence on non-recurrent payable must fail with 400
    non_rec_resp = client.post(
        "/api/v1/payables",
        json={
            "description": "Despesa Avulsa",
            "beneficiary": "Grafica Express",
            "category": "OUTROS",
            "nature": "BUSINESS",
            "original_amount_cents": 5000,
            "due_date": due,
            "is_recurrent": False,
        },
        headers=headers,
    )
    p_non = non_rec_resp.json()[0]
    fail_rec = client.post(f"/api/v1/payables/{p_non['id']}/next-recurrence", headers=headers)
    assert fail_rec.status_code == 400


def test_cancel_purchase_with_multiple_payables(client: TestClient, authenticated_device, test_session):
    """
    Verifies that cancel_purchase_entity safely handles purchases with multiple linked payables
    without raising MultipleResultsFound, cancelling them all and restoring audit integrity.
    """
    from app.models.financial import AccountPayable
    from app.services.purchases import cancel_purchase_entity
    import uuid

    _, _, headers = authenticated_device

    # 1. Create a product
    p_resp = client.post(
        "/api/v1/products",
        json={
            "name": "Arroz Teste Multi",
            "category": "ALIMENTACAO",
            "base_unit": "UNIT",
            "cost_price_cents": 1000,
            "sale_price_cents": 1500,
        },
        headers=headers,
    )
    prod_id = p_resp.json()["id"]

    # 2. Create purchase
    due = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30)).isoformat()
    purch_resp = client.post(
        "/api/v1/purchases",
        json={
            "supplier_name": "Cerealista Ramos",
            "payment_mode": "CREDIT_TERM",
            "due_date": due,
            "status": "CONFIRMED",
            "items": [{"product_id": prod_id, "packages_count": 50, "unit_price_cents": 1000}],
        },
        headers=headers,
    )
    purch_id = purch_resp.json()["id"]

    # 3. Add a second installment payable linked to the same purchase in test DB
    p2 = AccountPayable(
        id=str(uuid.uuid4()),
        payable_number=999888,
        description="Parcela 2 da compra",
        beneficiary="Cerealista Ramos",
        category="FORNECEDOR",
        nature="BUSINESS",
        original_amount_cents=25000,
        paid_amount_cents=0,
        balance_cents=25000,
        due_date=datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=60),
        payment_method="BOLETO",
        status="OPEN",
        purchase_id=purch_id,
        installment_number=2,
        total_installments=2,
    )
    test_session.add(p2)
    test_session.commit()

    # 4. Cancel purchase - should cancel both without MultipleResultsFound
    cancel_purchase_entity(test_session, purch_id, reason="Cancelamento de pedido com multiplas parcelas")
    test_session.commit()

    # Verify all linked payables are canceled
    linked = test_session.query(AccountPayable).filter(AccountPayable.purchase_id == purch_id).all()
    assert len(linked) >= 2
    assert all(p.status == "CANCELED" and p.balance_cents == 0 for p in linked)


def test_payment_reversal_ledger_link(client: TestClient, authenticated_device):
    """
    Verifies that when a payment is reversed, the resulting reversal entry in cash_flow_entries
    has reversal_of_id pointing directly to the original entry's ID and is_reversal=True.
    """
    _, _, headers = authenticated_device
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]
    due = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=5)).isoformat()

    # 1. Create payable
    p_resp = client.post(
        "/api/v1/payables",
        json={
            "description": "Seguro Patrimonial",
            "beneficiary": "Seguradora Allianz",
            "category": "OUTROS",
            "nature": "BUSINESS",
            "original_amount_cents": 60000,
            "due_date": due,
        },
        headers=headers,
    )
    payable_id = p_resp.json()[0]["id"]

    # 2. Pay it
    pay_resp = client.post(
        f"/api/v1/payables/{payable_id}/payments",
        json={"amount_cents": 60000, "account_id": acc_id, "payment_method": "BOLETO"},
        headers=headers,
    )
    pay_id = pay_resp.json()["id"]

    # 3. Find debit entry in ledger
    entries_before = client.get(f"/api/v1/treasury/entries?account_id={acc_id}", headers=headers).json()
    orig_entry = next(e for e in entries_before if e["source_id"] == pay_id and not e["is_reversal"])
    assert orig_entry["entry_type"] == "DEBIT"
    assert orig_entry["amount_cents"] == 60000

    # 4. Reverse the payment
    rev_resp = client.post(
        f"/api/v1/payables/payments/{pay_id}/cancel",
        json={"reason": "Pagamento em duplicidade estornado"},
        headers=headers,
    )
    assert rev_resp.status_code == 200

    # 5. Verify reversal entry in ledger has reversal_of_id == orig_entry['id']
    entries_after = client.get(f"/api/v1/treasury/entries?account_id={acc_id}", headers=headers).json()
    rev_entry = next(e for e in entries_after if e["source_id"] == pay_id and e["is_reversal"])
    assert rev_entry["entry_type"] == "CREDIT"
    assert rev_entry["amount_cents"] == 60000
    assert rev_entry["reversal_of_id"] == orig_entry["id"]

