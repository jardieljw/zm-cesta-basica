import datetime
import io
import openpyxl
import pytest
from app.models.base import utc_now
from app.models.customers import Customer
from app.models.products import BasketType
from app.models.purchases import Purchase
from app.models.sales import Sale, SaleItem, SalesReceivable
from app.models.financial import FinancialAccount, AccountPayable, CashFlowEntry
from app.services.financial import record_cash_flow_entry
from app.services.business_dashboard import BUSINESS_TZ


def seed_business(db):
    now = utc_now()
    today = now.astimezone(BUSINESS_TZ).date()
    due = datetime.datetime.combine(today, datetime.time.min)
    db.add_all([
        Customer(id="company-customer", name="Cliente da entrega"),
        BasketType(id="company-basket", code="COMPANY", name="Cesta Completa"),
        Purchase(id="company-purchase", purchase_number=1, total_amount_cents=20000),
    ])
    db.flush()
    db.add(Sale(id="company-sale", sale_number=1, customer_id="company-customer",
                payment_mode="CREDIT_TERM", payment_status="PENDING", total_amount_cents=30000))
    db.flush()
    db.add_all([
        SaleItem(id="company-item", sale_id="company-sale", basket_type_id="company-basket",
                 quantity=1, unit_price_cents=30000, total_cents=30000,
                 unit_cost_cents=20000, total_cost_cents=20000),
        SalesReceivable(id="company-receivable", sale_id="company-sale", customer_id="company-customer",
                        due_date=due, original_amount_cents=30000, balance_cents=30000),
        AccountPayable(id="company-rent", payable_number=1, description="Aluguel",
                       beneficiary="Proprietário", category="ALUGUEL", due_date=due,
                       original_amount_cents=3000, balance_cents=3000),
        AccountPayable(id="company-stock", payable_number=2, description="Insumos",
                       beneficiary="Fornecedor", category="FORNECEDOR", due_date=due,
                       purchase_id="company-purchase", original_amount_cents=20000, balance_cents=20000),
    ])
    db.commit()


def test_confirmations_partial_receipts_and_reversals_without_account_selection(
    client, test_session, authenticated_device
):
    seed_business(test_session)
    _, _, headers = authenticated_device
    endpoint = "/api/v1/dashboard/business-summary?filter_type=all"
    initial = client.get(endpoint, headers=headers).json()
    assert initial["financial"]["sales_revenue_cents"] == 30000
    assert initial["financial"]["effective_received_cents"] == 0
    assert initial["financial"]["gross_profit_cents"] == 10000
    # Due today is not overdue before the calendar day ends.
    assert initial["financial"]["receivables_overdue_cents"] == 0

    receipt_ids = []
    for amount in [10000, 5000]:
        response = client.post("/api/v1/receivables/company-receivable/payments",
                               json={"amount_cents": amount, "payment_method": "PIX"}, headers=headers)
        assert response.status_code == 201, response.text
        receipt_ids.append(response.json()["id"])
    payment_ids = []
    for payable, amount in [("company-rent", 3000), ("company-stock", 20000)]:
        response = client.post(f"/api/v1/payables/{payable}/payments",
                               json={"amount_cents": amount, "payment_method": "PIX"}, headers=headers)
        assert response.status_code == 201, response.text
        payment_ids.append(response.json()["id"])
    account = test_session.query(FinancialAccount).first()
    for source in ["MANUAL", "TRANSFER", "DISPATCH_REPAYMENT"]:
        record_cash_flow_entry(test_session, account.id, "CREDIT", 50000, "OUTROS",
                               "Informação arquivada", source_type=source)
    test_session.commit()
    before_count = test_session.query(CashFlowEntry).count()
    test_session.commit()
    data = client.get(endpoint, headers=headers).json()
    f = data["financial"]
    assert set(data) == {"filter_info", "sales", "purchases", "inventory", "financial"}
    assert data["purchases"] == {"purchase_count": 1, "total_amount_cents": 20000}
    assert f["effective_received_cents"] == 15000
    assert f["effective_paid_cents"] == 23000
    assert f["payment_difference_cents"] == -8000
    assert f["receivables_open_cents"] == 15000
    assert f["sold_baskets_cost_cents"] == 20000
    assert f["stock_purchases_paid_cents"] == 20000
    assert f["operating_expenses_paid_cents"] == 3000
    assert f["operating_result_cents"] == 7000  # Not -13000: no second stock deduction.
    assert all("arquivada" not in r["description"] for r in f["received_records"])
    assert not any("treasury" in key or "cash" in key for key in f)
    assert test_session.query(CashFlowEntry).count() == before_count
    test_session.commit()

    for endpoint_cancel in [
        f"/api/v1/receivables/payments/{receipt_ids[1]}/cancel",
        f"/api/v1/payables/payments/{payment_ids[0]}/cancel",
    ]:
        response = client.post(endpoint_cancel, json={"reason": "Correção de registro"}, headers=headers)
        assert response.status_code == 200, response.text
    f = client.get(endpoint, headers=headers).json()["financial"]
    assert f["effective_received_cents"] == 10000
    assert f["effective_paid_cents"] == 20000
    assert f["receivables_open_cents"] == 20000
    assert f["payables_open_cents"] == 3000
    assert f["operating_result_cents"] == 10000
    assert any(r["amount_cents"] == -5000 for r in f["received_records"])
    assert any(r["amount_cents"] == -3000 for r in f["paid_records"])


@pytest.mark.parametrize("format", ["json", "csv", "xlsx"])
def test_financial_report_counts_immediate_sale_and_never_reports_deposited_balance(
    client, test_session, authenticated_device, format
):
    seed_business(test_session)
    account = test_session.query(FinancialAccount).first()
    sale = Sale(id="company-immediate", sale_number=2, payment_mode="PIX",
                payment_status="PAID", total_amount_cents=10000)
    test_session.add(sale)
    test_session.flush()
    test_session.add(SaleItem(id="company-immediate-item", sale_id=sale.id,
        basket_type_id="company-basket", quantity=1, unit_price_cents=10000,
        total_cents=10000, unit_cost_cents=6000, total_cost_cents=6000))
    record_cash_flow_entry(test_session, account.id, "CREDIT", 10000, "VENDAS",
                           "Venda à vista #2", source_type="SALE", source_id=sale.id)
    test_session.commit()
    _, _, headers = authenticated_device
    dashboard = client.get("/api/v1/dashboard/business-summary?filter_type=all", headers=headers).json()
    assert dashboard["financial"]["effective_received_cents"] == 10000
    assert dashboard["financial"]["gross_profit_cents"] == 14000
    endpoint = "/api/v1/reports/business-financial-summary"
    if format != "json":
        endpoint += "/export"
    response = client.get(endpoint, params={"filter_type": "all", "format": format}, headers=headers)
    assert response.status_code == 200, response.text
    if format == "json":
        rows = response.json()["rows"]
        amounts = {r["indicator"]: r["amount_cents"] for r in rows}
        assert amounts["Recebimentos confirmados"] == 10000
        assert amounts["Lucro bruto das vendas"] == 14000
        exported = str(rows)
    elif format == "csv":
        exported = response.content.decode("utf-8-sig")
    else:
        exported = str(list(openpyxl.load_workbook(io.BytesIO(response.content)).active.values))
    assert "Saldo Disponível" not in exported
    assert "Saldo de Caixa" not in exported


def test_payment_period_uses_local_calendar_and_reversal_date(client, test_session, authenticated_device):
    account = test_session.query(FinancialAccount).first()
    for time, entry_type, amount in [
        ("2026-10-13T02:59:59+00:00", "CREDIT", 10000),  # Previous business day.
        ("2026-10-13T03:00:00+00:00", "CREDIT", 15000),
        ("2026-10-14T02:59:59+00:00", "DEBIT", 5000),
        ("2026-10-14T03:00:00+00:00", "CREDIT", 20000),  # Following business day.
    ]:
        record_cash_flow_entry(test_session, account.id, entry_type, amount, "VENDAS", "Teste de data",
            source_type="SALE", occurred_at=datetime.datetime.fromisoformat(time))
    test_session.commit()
    _, _, headers = authenticated_device
    response = client.get("/api/v1/dashboard/business-summary",
        params={"filter_type": "date", "date": "2026-10-13"}, headers=headers)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["financial"]["effective_received_cents"] == 10000
    assert len(data["financial"]["received_records"]) == 2
    assert data["filter_info"]["start_date"] == "2026-10-13T03:00:00Z"
