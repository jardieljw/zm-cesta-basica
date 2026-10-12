import uuid
import datetime
import pytest
from fastapi.testclient import TestClient


def test_financial_accounts_management_and_defaults(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. List pre-seeded accounts
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    assert len(accounts) >= 1
    assert any(a["name"] == "Caixa Físico da Loja" and a["is_default"] is True for a in accounts)

    # 2. Create a Bank Account (Banco do Brasil)
    bank_resp = client.post(
        "/api/v1/treasury/accounts",
        json={
            "name": "Banco do Brasil PJ",
            "account_type": "BANK",
            "bank_name": "Banco do Brasil",
            "account_number": "Ag 1234 CC 56789-0",
            "initial_balance_cents": 100000,  # R$ 1.000,00
            "is_default": True,
            "notes": "Conta principal da empresa",
        },
        headers=headers,
    )
    assert bank_resp.status_code == 201, bank_resp.text
    bb_acc = bank_resp.json()
    assert bb_acc["name"] == "Banco do Brasil PJ"
    assert bb_acc["account_type"] == "BANK"
    assert bb_acc["initial_balance_cents"] == 100000
    assert bb_acc["current_balance_cents"] == 100000
    assert bb_acc["is_default"] is True

    # 3. Create a second Bank Account (Bradesco) marked as default -> should unset BB as default BANK
    bradesco_resp = client.post(
        "/api/v1/treasury/accounts",
        json={
            "name": "Bradesco PJ",
            "account_type": "BANK",
            "bank_name": "Bradesco",
            "account_number": "Ag 4321 CC 98765-4",
            "initial_balance_cents": 50000,
            "is_default": True,
        },
        headers=headers,
    )
    assert bradesco_resp.status_code == 201
    brad_acc = bradesco_resp.json()
    assert brad_acc["is_default"] is True

    # Verify BB is no longer default BANK
    bb_refreshed = client.get(f"/api/v1/treasury/accounts/{bb_acc['id']}", headers=headers).json()
    assert bb_refreshed["is_default"] is False

    # 4. Patch account details
    patch_resp = client.patch(
        f"/api/v1/treasury/accounts/{brad_acc['id']}",
        json={"notes": "Atualizado com sucesso", "is_active": True},
        headers=headers,
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["notes"] == "Atualizado com sucesso"


def test_inter_account_transfers(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Create two accounts: Caixa and Banco
    acc1 = client.post(
        "/api/v1/treasury/accounts",
        json={"name": "Caixa Loja 2", "account_type": "CASH", "initial_balance_cents": 50000},
        headers=headers,
    ).json()

    acc2 = client.post(
        "/api/v1/treasury/accounts",
        json={"name": "Conta Sicredi", "account_type": "BANK", "initial_balance_cents": 10000},
        headers=headers,
    ).json()

    # 2. Transfer R$ 200,00 (20000 cents) from acc1 to acc2
    transfer_resp = client.post(
        "/api/v1/treasury/transfers",
        json={
            "source_account_id": acc1["id"],
            "destination_account_id": acc2["id"],
            "amount_cents": 20000,
            "description": "Deposito em cheque/dinheiro na boca do caixa",
        },
        headers=headers,
    )
    assert transfer_resp.status_code == 201, transfer_resp.text
    t_data = transfer_resp.json()
    assert t_data["amount_cents"] == 20000
    assert t_data["source_account_id"] == acc1["id"]
    assert t_data["destination_account_id"] == acc2["id"]
    assert t_data["transfer_id"] is not None

    # 3. Check updated balances
    acc1_updated = client.get(f"/api/v1/treasury/accounts/{acc1['id']}", headers=headers).json()
    acc2_updated = client.get(f"/api/v1/treasury/accounts/{acc2['id']}", headers=headers).json()
    assert acc1_updated["current_balance_cents"] == 30000  # 50000 - 20000
    assert acc2_updated["current_balance_cents"] == 30000  # 10000 + 20000

    # 4. Same source and destination must fail
    fail_resp = client.post(
        "/api/v1/treasury/transfers",
        json={
            "source_account_id": acc1["id"],
            "destination_account_id": acc1["id"],
            "amount_cents": 5000,
        },
        headers=headers,
    )
    assert fail_resp.status_code == 400


def test_manual_entries_and_append_only_ledger(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]
    initial_bal = accounts[0]["current_balance_cents"]

    # 1. Credit entry: Aporte dos socios
    credit_entry = client.post(
        "/api/v1/treasury/entries",
        json={
            "account_id": acc_id,
            "entry_type": "CREDIT",
            "amount_cents": 80000,
            "category": "APORTE",
            "nature": "BUSINESS",
            "description": "Aporte de capital dos socios",
            "payment_method": "PIX",
        },
        headers=headers,
    ).json()
    assert credit_entry["entry_type"] == "CREDIT"
    assert credit_entry["amount_cents"] == 80000

    # 2. Debit entry: Retirada particular de socio
    debit_entry = client.post(
        "/api/v1/treasury/entries",
        json={
            "account_id": acc_id,
            "entry_type": "DEBIT",
            "amount_cents": 15000,
            "category": "RETIRADA_SOCIO",
            "nature": "PERSONAL_WITHDRAWAL",
            "description": "Retirada pro-labore socio A",
            "payment_method": "PIX",
        },
        headers=headers,
    ).json()
    assert debit_entry["entry_type"] == "DEBIT"
    assert debit_entry["nature"] == "PERSONAL_WITHDRAWAL"

    # Verify account balance adjusted
    acc_check = client.get(f"/api/v1/treasury/accounts/{acc_id}", headers=headers).json()
    assert acc_check["current_balance_cents"] == initial_bal + 80000 - 15000

    # 3. Query entries with filters
    entries_credit = client.get("/api/v1/treasury/entries?entry_type=CREDIT&category=APORTE", headers=headers).json()
    assert any(e["id"] == credit_entry["id"] for e in entries_credit)

    entries_personal = client.get("/api/v1/treasury/entries?nature=PERSONAL_WITHDRAWAL", headers=headers).json()
    assert any(e["id"] == debit_entry["id"] for e in entries_personal)


def test_treasury_summary_metrics(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    summary = client.get("/api/v1/treasury/summary", headers=headers).json()
    assert "total_available_cents" in summary
    assert "cash_balance_cents" in summary
    assert "bank_balance_cents" in summary
    assert "open_receivables_cents" in summary
    assert "overdue_receivables_cents" in summary
    assert "open_payables_cents" in summary
    assert "overdue_payables_cents" in summary
    assert "route_cash_pending_cents" in summary
    assert "projected_net_cents" in summary
    assert "period_business_expenses_cents" in summary
    assert "period_personal_withdrawals_cents" in summary
    assert isinstance(summary["accounts"], list)

    # Projected net formula check: total_available + open_receivables - open_payables
    expected_net = summary["total_available_cents"] + summary["open_receivables_cents"] - summary["open_payables_cents"]
    assert summary["projected_net_cents"] == expected_net


def test_treasury_idempotency(client: TestClient, authenticated_device):
    import uuid
    _, _, headers = authenticated_device

    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]

    # 1. Idempotent Account Creation
    idem_acc_key = str(uuid.uuid4())
    acc_payload = {
        "name": "Conta Idempotente",
        "account_type": "BANK",
        "initial_balance_cents": 5000,
    }
    resp1 = client.post("/api/v1/treasury/accounts", json=acc_payload, headers={**headers, "X-Idempotency-Key": idem_acc_key})
    assert resp1.status_code == 201
    created_id = resp1.json()["id"]

    resp2 = client.post("/api/v1/treasury/accounts", json=acc_payload, headers={**headers, "X-Idempotency-Key": idem_acc_key})
    assert resp2.status_code == 201
    assert resp2.json()["id"] == created_id

    # 2. Idempotent Transfer
    idem_trans_key = str(uuid.uuid4())
    trans_payload = {
        "source_account_id": acc_id,
        "destination_account_id": created_id,
        "amount_cents": 1000,
        "description": "Transferencia idempotente",
    }
    t_resp1 = client.post("/api/v1/treasury/transfers", json=trans_payload, headers={**headers, "X-Idempotency-Key": idem_trans_key})
    assert t_resp1.status_code == 201
    t_id = t_resp1.json()["transfer_id"]

    t_resp2 = client.post("/api/v1/treasury/transfers", json=trans_payload, headers={**headers, "X-Idempotency-Key": idem_trans_key})
    assert t_resp2.status_code == 201
    assert t_resp2.json()["transfer_id"] == t_id


def test_route_cash_repayment_treasury_integration(client: TestClient, authenticated_device):
    """
    Verifies that route collections and repayments:
    1. Pending cash with driver appears in route_cash_pending_cents.
    2. When repayment is registered, cash lands in cash_flow_entries under REPASSE_ROTA.
    3. Target financial account balance is incremented.
    4. route_cash_pending_cents decreases accordingly.
    """
    _, _, headers = authenticated_device
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]
    initial_acc_bal = accounts[0]["current_balance_cents"]

    # 1. Create a basket type
    bt_res = client.post(
        "/api/v1/basket-types",
        json={
            "code": "CESTA_ROTA_REP",
            "name": "Cesta Rota Repasse",
            "default_price_cents": 10000,
            "is_active": True,
        },
        headers=headers,
    )
    assert bt_res.status_code == 201, bt_res.text
    bt_id = bt_res.json()["id"]

    # 2. Inject stock via inventory adjustment
    adj_res = client.post(
        "/api/v1/inventory/adjustments",
        json={
            "item_type": "BASKET",
            "basket_type_id": bt_id,
            "adjustment_type": "IN",
            "quantity_delta": 10,
            "reason": "Estoque para teste repasse rota",
        },
        headers=headers,
    )
    assert adj_res.status_code == 201

    # 3. Create responsible person
    rp_res = client.post(
        "/api/v1/dispatches/responsible-persons",
        json={"name": "Motorista Carlos Repasse", "phone": "11999998888"},
        headers=headers,
    )
    assert rp_res.status_code == 201
    rp_id = rp_res.json()["id"]

    # 4. Dispatch 5 baskets to route
    disp_res = client.post(
        "/api/v1/dispatches",
        json={
            "responsible_person_id": rp_id,
            "items": [{"basket_type_id": bt_id, "quantity": 5}],
        },
        headers=headers,
    )
    assert disp_res.status_code == 201, disp_res.text
    disp_id = disp_res.json()["id"]

    # 5. Route driver sells 2 baskets in CASH (R$ 200,00 = 20000 cents)
    sale_res = client.post(
        "/api/v1/sales",
        json={
            "sale_mode": "COMMERCIAL_ROUTE",
            "payment_mode": "CASH_IMMEDIATE",
            "dispatch_id": disp_id,
            "items": [{"basket_type_id": bt_id, "quantity": 2, "unit_price_cents": 10000}],
        },
        headers=headers,
    )
    assert sale_res.status_code == 201

    # 6. Check TreasurySummary has route_cash_pending_cents >= 20000
    sum1 = client.get("/api/v1/treasury/summary", headers=headers).json()
    assert sum1["route_cash_pending_cents"] >= 20000

    # 7. Driver hands over R$ 150,00 (15000 cents) to company treasury
    rep_res = client.post(
        f"/api/v1/dispatches/{disp_id}/repayments",
        json={
            "amount_cents": 15000,
            "payment_method": "CASH",
            "account_id": acc_id,
            "notes": "Entrega parcial do dinheiro da rota",
        },
        headers=headers,
    )
    assert rep_res.status_code == 201

    # 8. Verify ledger received credit under REPASSE_ROTA
    entries = client.get(f"/api/v1/treasury/entries?account_id={acc_id}&category=REPASSE_ROTA", headers=headers).json()
    assert len(entries) >= 1
    rep_entry = next(e for e in entries if e["source_type"] == "DISPATCH_REPAYMENT" and e["amount_cents"] == 15000)
    assert rep_entry["entry_type"] == "CREDIT"

    # 9. Verify financial account balance increased by 15000 cents
    acc_check = client.get(f"/api/v1/treasury/accounts/{acc_id}", headers=headers).json()
    assert acc_check["current_balance_cents"] == initial_acc_bal + 15000

    # 10. Check TreasurySummary pending cash reduced
    sum2 = client.get("/api/v1/treasury/summary", headers=headers).json()
    assert sum2["route_cash_pending_cents"] == sum1["route_cash_pending_cents"] - 15000


def test_duplicate_cash_flow_entry_prevention(client: TestClient, authenticated_device):
    """
    Verifies that calling record_cash_flow_entry for the same source_id and source_type
    is rejected with 409 Conflict when allow_duplicate_source is False.
    """
    from app.core.database import SessionLocal
    from app.services.financial import record_cash_flow_entry
    from fastapi import HTTPException
    import pytest
    import uuid

    _, _, headers = authenticated_device
    accounts = client.get("/api/v1/treasury/accounts", headers=headers).json()
    acc_id = accounts[0]["id"]

    db = SessionLocal()
    fake_source_id = str(uuid.uuid4())
    try:
        # First entry succeeds
        record_cash_flow_entry(
            db=db,
            account_id=acc_id,
            entry_type="CREDIT",
            amount_cents=5000,
            category="OUTROS",
            description="Lancamento primario",
            source_type="TEST_SOURCE",
            source_id=fake_source_id,
        )
        db.commit()

        # Second entry with identical source_type and source_id must raise 409 Conflict
        with pytest.raises(HTTPException) as exc_info:
            record_cash_flow_entry(
                db=db,
                account_id=acc_id,
                entry_type="CREDIT",
                amount_cents=5000,
                category="OUTROS",
                description="Lancamento duplicado indevido",
                source_type="TEST_SOURCE",
                source_id=fake_source_id,
            )
        assert exc_info.value.status_code == 409
        assert "ja existente" in exc_info.value.detail
    finally:
        db.close()

