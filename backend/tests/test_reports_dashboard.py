import datetime
import io
import openpyxl
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.products import Product, BasketType, RecipeVersion, RecipeItem
from app.models.production import ProductionBatch
from app.models.customers import Customer
from app.models.sales import Sale, SaleItem, SalesReceivable, ReceivablePayment
from app.models.dispatches import ResponsiblePerson, StockDispatch, DispatchItem, DispatchSettlement
from app.models.financial import FinancialAccount, CashFlowEntry, AccountPayable, PayablePayment
from app.models.movements import InventoryMovement


def test_empty_database_dashboard_and_reports(client: TestClient, authenticated_device):
    """Verifies dashboard and reports function seamlessly even on a completely empty database."""
    _, _, auth_headers = authenticated_device
    # Dashboard summary
    resp = client.get("/api/v1/dashboard/summary?filter_type=today", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["production"]["assembled_count"] == 0
    assert data["sales"]["sold_count"] == 0
    assert data["sales"]["total_sold_cents"] == 0
    assert data["dispatches"]["dispatched_count"] == 0
    assert data["inventory"]["total_products_count"] == 0
    assert data["financial"]["current_treasury_balance_cents"] == 0
    assert data["financial"]["projected_treasury_balance_cents"] == 0

    # All 8 reports return 200 with 0 rows
    report_endpoints = [
        "sales-dispatches",
        "assembly",
        "purchases-movements",
        "receivables",
        "payables",
        "dispatch-settlements",
        "physical-inventory",
        "financial-summary",
    ]
    for rep in report_endpoints:
        r = client.get(f"/api/v1/reports/{rep}", headers=auth_headers)
        assert r.status_code == 200
        r_data = r.json()
        assert "metadata" in r_data
        assert "headers" in r_data
        assert "rows" in r_data


def test_dashboard_with_populated_data_and_filters(client: TestClient, authenticated_device, test_session):
    """Verifies that all operational and financial indicators calculate correctly across filters."""
    _, _, auth_headers = authenticated_device
    db_session = test_session
    # 1. Create a product with low stock
    p1 = Product(
        id="prod-arroz-1",
        name="Arroz 5kg",
        sku="ARR5",
        category="ALIMENTACAO",
        base_unit="G",
        cost_price_microcents=25000000, # R$ 25,00
        minimum_stock=10000,
        is_active=True,
    )
    db_session.add(p1)

    # Stock movement: 5000g (below 10000 min stock)
    m1 = InventoryMovement(
        id="mov-1",
        item_type="PRODUCT",
        product_id=p1.id,
        movement_type="PURCHASE",
        quantity_delta=5000,
        source_type="PURCHASE",
        source_id="purch-1",
        location_type="STORE",
    )
    db_session.add(m1)

    # 2. Create BasketType & Production
    bt = BasketType(
        id="bt-completa-1",
        code="BASICA_PADRAO",
        name="Cesta Básica Completa",
        is_active=True,
    )
    db_session.add(bt)
    db_session.commit()

    now = datetime.datetime.now(datetime.timezone.utc)
    batch = ProductionBatch(
        id="batch-1",
        batch_number=101,
        basket_type_id=bt.id,
        quantity_produced=10,
        status="CONFIRMED",
        unit_cost_cents=8500,
        total_cost_cents=85000,
        occurred_at=now,
    )
    db_session.add(batch)

    # 3. Create Customer and Sale
    cust = Customer(
        id="cust-silva-1",
        name="Mercadinho Silva",
        document_cpf_cnpj="12.345.678/0001-90",
        phone="11988887777",
        is_active=True,
    )
    db_session.add(cust)

    sale = Sale(
        id="sale-1",
        sale_number=201,
        customer_id=cust.id,
        customer_name="Mercadinho Silva",
        status="CONFIRMED",
        sale_mode="DIRECT_STORE",
        payment_mode="CREDIT_TERM",
        payment_status="PENDING",
        total_amount_cents=12000,
        sale_date=now,
    )
    db_session.add(sale)

    sale_item = SaleItem(
        id="si-1",
        sale_id=sale.id,
        basket_type_id=bt.id,
        quantity=1,
        unit_price_cents=12000,
        total_cents=12000,
        unit_cost_cents=8500,
        total_cost_cents=8500,
    )
    db_session.add(sale_item)

    rec = SalesReceivable(
        id="rec-1",
        sale_id=sale.id,
        customer_id=cust.id,
        due_date=now,
        original_amount_cents=12000,
        paid_amount_cents=0,
        balance_cents=12000,
        status="OPEN",
    )
    db_session.add(rec)

    # 4. Create Dispatch & Responsible Person
    resp = ResponsiblePerson(
        id="resp-1",
        name="Carlos Entregador",
        phone="11999998888",
        is_active=True,
    )
    db_session.add(resp)

    disp = StockDispatch(
        id="disp-1",
        dispatch_number=501,
        responsible_person_id=resp.id,
        dispatch_date=now,
        status="OPEN",
    )
    db_session.add(disp)

    d_item = DispatchItem(
        id="di-1",
        dispatch_id=disp.id,
        basket_type_id=bt.id,
        quantity=5,
        unit_price_cents=12000,
    )
    db_session.add(d_item)

    # 5. Financial Account and Cash Entries
    acc = FinancialAccount(
        id="acc-caixa-1",
        name="Caixa Loja",
        account_type="CASH",
        initial_balance_cents=50000,
        current_balance_cents=50000,
        is_active=True,
    )
    db_session.add(acc)

    cfe = CashFlowEntry(
        id="cfe-1",
        account_id=acc.id,
        entry_type="CREDIT",
        amount_cents=15000,
        category="VENDAS",
        nature="BUSINESS",
        description="Venda a vista balcao",
        source_type="SALE",
        payment_method="CASH",
        occurred_at=now,
    )
    db_session.add(cfe)

    # Payable
    payable = AccountPayable(
        id="pay-1",
        payable_number=301,
        description="Fatura Energia",
        beneficiary="Enel Distribuidora",
        category="ENERGIA",
        nature="BUSINESS",
        original_amount_cents=25000,
        paid_amount_cents=0,
        balance_cents=25000,
        due_date=now,
        status="OPEN",
    )
    db_session.add(payable)

    db_session.commit()
    db_session.close()

    # Query Dashboard Summary
    resp = client.get("/api/v1/dashboard/summary?filter_type=today", headers=auth_headers)
    assert resp.status_code == 200
    d = resp.json()

    # Production check
    assert d["production"]["assembled_count"] == 10
    assert len(d["production"]["by_basket_type"]) == 1
    assert d["production"]["by_basket_type"][0]["count"] == 10
    assert len(d["production"]["batches"]) >= 1

    # Sales check
    assert d["sales"]["sold_count"] == 1
    assert d["sales"]["total_sold_cents"] == 12000
    assert len(d["sales"]["sales"]) >= 1

    # Dispatches check
    assert d["dispatches"]["dispatched_count"] == 5
    assert len(d["dispatches"]["dispatches"]) >= 1

    # Inventory check
    assert d["inventory"]["total_products_count"] >= 1
    assert d["inventory"]["low_stock_products_count"] == 1
    assert d["inventory"]["low_stock_items"][0]["name"] == "Arroz 5kg"
    assert d["inventory"]["low_stock_items"][0]["difference"] == 5000

    # Financial check
    fin = d["financial"]
    assert fin["receivables_open_cents"] == 12000
    assert fin["payables_open_cents"] == 25000
    assert fin["cash_inflow_cents"] == 15000
    assert fin["current_treasury_balance_cents"] == 50000
    # Projected: 50000 (current) + 12000 (open receivables in period) - 25000 (open payables in period) = 37000
    # Make sure projection is NOT treated as realized received money!
    assert fin["effective_received_cents"] == 0
    assert fin["projected_inflow_cents"] == 12000
    assert fin["projected_outflow_cents"] == 25000
    assert fin["projected_treasury_balance_cents"] == 37000


def test_export_reports_csv_and_xlsx(client: TestClient, authenticated_device):
    """Verifies that all 8 reports can be exported to valid CSV and XLSX without errors."""
    _, _, auth_headers = authenticated_device
    report_types = [
        "sales-dispatches",
        "assembly",
        "purchases-movements",
        "receivables",
        "payables",
        "dispatch-settlements",
        "physical-inventory",
        "financial-summary",
    ]

    for rt in report_types:
        # Test CSV export
        csv_resp = client.get(f"/api/v1/reports/{rt}/export?format=csv&filter_type=all", headers=auth_headers)
        assert csv_resp.status_code == 200
        assert "text/csv" in csv_resp.headers["content-type"]
        assert len(csv_resp.content) > 0
        # UTF-8 BOM check
        assert csv_resp.content.startswith(b"\xef\xbb\xbf")

        # Test XLSX export
        xlsx_resp = client.get(f"/api/v1/reports/{rt}/export?format=xlsx&filter_type=all", headers=auth_headers)
        assert xlsx_resp.status_code == 200
        assert "openxmlformats" in xlsx_resp.headers["content-type"]
        # Verify valid openpyxl workbook
        wb = openpyxl.load_workbook(io.BytesIO(xlsx_resp.content))
        assert len(wb.sheetnames) >= 1
        ws = wb.active
        assert ws.cell(row=2, column=1).value is not None


def test_blank_forms_endpoints_and_xlsx(client: TestClient, authenticated_device):
    """Verifies the 4 canonical blank forms generate with spacious rows and can be exported as empty templates."""
    _, _, auth_headers = authenticated_device
    form_types = ["payments", "payables", "dispatch_conference", "physical_inventory"]

    for ft in form_types:
        # JSON blank form
        resp = client.get(f"/api/v1/reports/blank-templates/{ft}", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["headers"]) >= 5
        assert len(data["rows"]) == 15
        assert all(val == "" for val in data["rows"][0].values())

        # XLSX blank template
        xlsx_resp = client.get(f"/api/v1/reports/blank-templates/{ft}/export", headers=auth_headers)
        assert xlsx_resp.status_code == 200
        wb = openpyxl.load_workbook(io.BytesIO(xlsx_resp.content))
        ws = wb.active
        # Check that row dimensions for blank rows have generous height for pen writing
        assert ws.row_dimensions[6].height == 28
        assert ws.row_dimensions[10].height == 28


def test_reports_and_dashboard_are_strictly_read_only(client: TestClient, authenticated_device, test_engine):
    """Verifies that calling reports, dashboard and exporters does NOT alter or create any database records."""
    _, _, auth_headers = authenticated_device
    with Session(test_engine) as session:
        count_movements_before = session.query(InventoryMovement).count()
        count_sales_before = session.query(Sale).count()
        count_cash_before = session.query(CashFlowEntry).count()

    # Invoke dashboard and various exports
    client.get("/api/v1/dashboard/summary?filter_type=today", headers=auth_headers)
    client.get("/api/v1/reports/financial-summary", headers=auth_headers)
    client.get("/api/v1/reports/sales-dispatches/export?format=xlsx", headers=auth_headers)
    client.get("/api/v1/reports/blank-templates/payments/export", headers=auth_headers)

    with Session(test_engine) as session:
        count_movements_after = session.query(InventoryMovement).count()
        count_sales_after = session.query(Sale).count()
        count_cash_after = session.query(CashFlowEntry).count()

    assert count_movements_before == count_movements_after
    assert count_sales_before == count_sales_after
    assert count_cash_before == count_cash_after


def test_dashboard_unremitted_responsible_drilldown(client: TestClient, authenticated_device, test_session):
    """Verifies that unremitted cash by responsible persons generates complete drilldown items."""
    _, _, auth_headers = authenticated_device
    db_session = test_session

    now = datetime.datetime.now(datetime.timezone.utc)
    resp = ResponsiblePerson(
        id="resp-unrem-1",
        name="Joao Motorista",
        phone="11977776666",
        is_active=True,
    )
    db_session.add(resp)

    disp = StockDispatch(
        id="disp-unrem-1",
        dispatch_number=888,
        responsible_person_id=resp.id,
        dispatch_date=now,
        status="OPEN",
    )
    db_session.add(disp)

    # Cash sale on route: R$ 200,00
    sale = Sale(
        id="sale-unrem-1",
        sale_number=8881,
        dispatch_id=disp.id,
        customer_name="Cliente Rota 1",
        status="CONFIRMED",
        sale_mode="ROUTE_DELIVERY",
        payment_mode="CASH_IMMEDIATE",
        payment_status="PAID",
        total_amount_cents=20000,
        sale_date=now,
    )
    db_session.add(sale)

    db_session.commit()
    db_session.close()

    r = client.get("/api/v1/dashboard/summary?filter_type=all", headers=auth_headers)
    assert r.status_code == 200
    data = r.json()
    disp_summary = data["dispatches"]
    assert disp_summary["responsible_unremitted_cents"] >= 20000
    assert len(disp_summary["responsible_unremitted_items"]) >= 1

    item = next(it for it in disp_summary["responsible_unremitted_items"] if it["dispatch_id"] == "disp-unrem-1")
    assert item["responsible_person_name"] == "Joao Motorista"
    assert item["phone"] == "11977776666"
    assert item["dispatch_number"] == 888
    assert item["cash_sales_cents"] == 20000
    assert item["unremitted_cash_cents"] == 20000
    assert item["status"] == "OPEN"


def test_audit_prefilled_forms_and_xlsx_export(client: TestClient, authenticated_device, test_session):
    """Verifies that all 4 canonical models can be pre-filled with real application data and exported to XLSX."""
    _, _, auth_headers = authenticated_device
    form_types = ["payments", "payables", "dispatch_conference", "physical_inventory"]

    for ft in form_types:
        # 1. JSON prefilled endpoint
        resp = client.get(f"/api/v1/reports/blank-templates/{ft}?filled=true", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "metadata" in data
        assert data["metadata"]["report_type"] == f"audit-{ft}"
        assert len(data["headers"]) >= 5
        assert len(data["columns"]) == len(data["headers"])
        assert len(data["rows"]) >= 1

        # 2. XLSX prefilled export
        xlsx_resp = client.get(f"/api/v1/reports/blank-templates/{ft}/export?filled=true", headers=auth_headers)
        assert xlsx_resp.status_code == 200
        assert "openxmlformats" in xlsx_resp.headers["content-type"]
        wb = openpyxl.load_workbook(io.BytesIO(xlsx_resp.content))
        ws = wb.active
        assert ws.cell(row=2, column=1).value is not None
        # Check spacious row height (comfortable 26-28pt for handwriting / audit)
        assert ws.row_dimensions[6].height in (26, 28)


def test_date_filters_invalid_format_returns_400(client: TestClient, authenticated_device):
    """Verifies that invalid date formats in query filters return HTTP 400 Bad Request instead of crashing with 500."""
    _, _, auth_headers = authenticated_device
    resp = client.get("/api/v1/dashboard/summary?filter_type=date&date=data-invalida", headers=auth_headers)
    assert resp.status_code == 400
    assert "Formato de data inválido" in resp.json()["detail"]

    resp2 = client.get("/api/v1/reports/sales-dispatches?filter_type=range&start_date=2026-99-99&end_date=2026-10-12", headers=auth_headers)
    assert resp2.status_code == 400

