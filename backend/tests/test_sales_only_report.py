import io

import openpyxl
import pytest

from app.models.dispatches import DispatchItem, ResponsiblePerson, StockDispatch
from app.models.products import BasketType
from app.models.sales import Sale, SaleItem


@pytest.mark.parametrize("format", ["json", "csv", "xlsx"])
@pytest.mark.parametrize("include_dispatches", [True, False])
def test_sales_report_preserves_historical_sales_and_filters_physical_dispatches(
    client, authenticated_device, test_session, format, include_dispatches
):
    """The active sales report and its exports exclude transfers, never old sales."""
    _, _, headers = authenticated_device
    basket = BasketType(id="report-basket", code="REPORT", name="Cesta Teste")
    person = ResponsiblePerson(id="report-person", name="Responsável Histórico")
    test_session.add_all([basket, person])
    test_session.flush()
    dispatch = StockDispatch(
        id="report-dispatch", dispatch_number=7,
        responsible_person_id=person.id, status="OPEN",
    )
    test_session.add(dispatch)
    test_session.flush()
    test_session.add(DispatchItem(
        id="report-dispatch-item", dispatch_id=dispatch.id,
        basket_type_id=basket.id, quantity=5, unit_price_cents=10000,
    ))
    for index, mode in enumerate(["DIRECT_STORE", "COMMERCIAL_ROUTE"], 1):
        sale = Sale(
            id=f"report-sale-{index}", sale_number=index, status="CONFIRMED",
            sale_mode=mode, payment_mode="CASH_IMMEDIATE", payment_status="PAID",
            total_amount_cents=index * 10000,
            dispatch_id=dispatch.id if index == 2 else None,
            responsible_person_id=person.id if index == 2 else None,
        )
        test_session.add(sale)
        test_session.flush()
        test_session.add(SaleItem(
            id=f"report-sale-item-{index}", sale_id=sale.id,
            basket_type_id=basket.id, quantity=index, unit_price_cents=10000,
            total_cents=index * 10000, unit_cost_cents=5000,
            total_cost_cents=index * 5000,
        ))
    test_session.commit()

    endpoint = "/api/v1/reports/sales-dispatches"
    params = {"filter_type": "all"}
    # Omitting the parameter verifies the original API default remains compatible.
    if not include_dispatches:
        params["include_dispatches"] = "false"
    if format != "json":
        endpoint += "/export"
        params["format"] = format
    response = client.get(endpoint, params=params, headers=headers)
    assert response.status_code == 200
    if format == "json":
        data = response.json()
        references = [row["reference"] for row in data["rows"]]
        assert "Venda #1" in references and "Venda #2" in references
        assert ("Saída #7" in references) is include_dispatches
        assert data["totals"]["quantity"] == (8 if include_dispatches else 3)
        assert data["totals"]["total_price_cents"] == 30000
        if not include_dispatches:
            assert data["metadata"]["title"] == "Relatório de Vendas de Cestas"
    else:
        if format == "csv":
            exported = response.content.decode("utf-8-sig")
        else:
            workbook = openpyxl.load_workbook(io.BytesIO(response.content))
            exported = str(list(workbook.active.values))
        assert "Venda #1" in exported and "Venda #2" in exported
        assert ("Saída #7" in exported) is include_dispatches

    # Reporting cannot mutate or discard archived operational records.
    assert test_session.get(StockDispatch, dispatch.id).status == "OPEN"
