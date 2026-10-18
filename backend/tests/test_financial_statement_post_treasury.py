import uuid
import pytest
from app.models.financial import FinancialAccount, CashFlowEntry
from app.models.financial_imports import FinancialSource, FinancialDocument, FinancialStatement, FinancialStatementItem, FinancialReconciliation
from test_financial_imports import FinancialAPI, PREFIX


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def test_post_statement_to_treasury_full_flow(api, test_session):
    # 1. Create a bank source linked to a real treasury account
    source = api.source(kind="BANK_ACCOUNT", holder="PJ")
    account_id = source["financial_account_id"]
    assert account_id is not None

    # Ensure no open transactions on test_session before making client requests
    test_session.rollback()

    # 2. Stage a bank statement with a credit and a debit
    lines = [
        {"transaction_date": "2026-08-18", "amount_cents": 324000, "description": "Pix Recebido Ifood Pago"},
        {"transaction_date": "2026-08-19", "amount_cents": -100000, "description": "Pix Enviado Fornecedor Embalagens"},
    ]
    statement, items, _ = api.stage(source, lines)

    # 3. Call endpoint to post to treasury
    headers = {**api.headers, "X-Idempotency-Key": str(uuid.uuid4())}
    resp = api.client.post(f"{PREFIX}/statements/{statement['id']}/post-to-treasury", headers=headers)
    assert resp.status_code == 200, resp.text
    data = resp.json()

    # Initial balance from api.source was 50000 cents (R$ 500,00)
    assert data["statement_id"] == statement["id"]
    assert data["account_id"] == account_id
    assert data["entries_posted"] == 2
    assert data["total_credits_cents"] == 324000
    assert data["total_debits_cents"] == 100000
    assert data["new_balance_cents"] == 50000 + 224000  # 50000 + 324000 - 100000 = 274000

    # Verify treasury account updated in DB
    treasury_account = test_session.query(FinancialAccount).filter_by(id=account_id).first()
    assert treasury_account.current_balance_cents == 274000

    # Verify CashFlowEntry records
    entries = test_session.query(CashFlowEntry).filter_by(account_id=treasury_account.id).all()
    assert len(entries) == 2
    credit_entry = next(e for e in entries if e.entry_type == "CREDIT")
    debit_entry = next(e for e in entries if e.entry_type == "DEBIT")

    assert credit_entry.amount_cents == 324000
    assert credit_entry.category == "RECEITA"
    assert credit_entry.payment_method == "PIX"
    assert debit_entry.amount_cents == 100000
    assert debit_entry.category == "DESPESA"

    # Verify reconciliations created
    recons = test_session.query(FinancialReconciliation).all()
    assert len(recons) == 2

    # Verify items marked LINKED
    item_ids = [it["id"] for it in items]
    db_items = test_session.query(FinancialStatementItem).filter(FinancialStatementItem.id.in_(item_ids)).all()
    assert len(db_items) == 2
    assert all(it.review_status == "LINKED" for it in db_items)

    # 4. Idempotency test: calling again must not duplicate cash flow entries
    test_session.rollback()
    headers2 = {**api.headers, "X-Idempotency-Key": str(uuid.uuid4())}
    resp2 = api.client.post(f"{PREFIX}/statements/{statement['id']}/post-to-treasury", headers=headers2)
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert data2["entries_posted"] == 0
    assert data2["new_balance_cents"] == 274000

    entries_after = test_session.query(CashFlowEntry).filter_by(account_id=treasury_account.id).all()
    assert len(entries_after) == 2  # Still 2, no duplicates!
    test_session.rollback()

    # Verify that the posted bank import entries reflect in business-summary dashboard
    dash_resp = api.client.get("/api/v1/dashboard/business-summary?filter_type=all", headers=api.headers)
    assert dash_resp.status_code == 200
    dash_data = dash_resp.json()
    f = dash_data["financial"]
    assert f["effective_received_cents"] == 324000
    assert f["effective_paid_cents"] == 100000
    assert f["payment_difference_cents"] == 224000
    assert any("Pix Recebido Ifood" in r["description"] for r in f["received_records"])
    assert any("Pix Enviado Fornecedor" in r["description"] for r in f["paid_records"])

