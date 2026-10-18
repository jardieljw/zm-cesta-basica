import pytest
import datetime
from fastapi.testclient import TestClient


def _setup_inventory_and_basket(client: TestClient, headers: dict):
    """Helper that creates 2 products, a basket type, an active recipe, and purchases stock."""
    # 1. Product 1 (Arroz)
    p1 = client.post(
        "/api/v1/products",
        json={"name": "Arroz Branco Tipo 1", "category": "ALIMENTACAO", "base_unit": "G", "cost_price_cents": 550},
        headers=headers,
    ).json()

    # 2. Product 2 (Feijao)
    p2 = client.post(
        "/api/v1/products",
        json={"name": "Feijao Carioca", "category": "ALIMENTACAO", "base_unit": "G", "cost_price_cents": 800},
        headers=headers,
    ).json()

    # 3. Inbound Purchase to populate stock: 100,000g Arroz (100kg) and 50,000g Feijao (50kg)
    client.post(
        "/api/v1/purchases",
        json={
            "supplier_name": "Distribuidora Cereais",
            "status": "CONFIRMED",
            "items": [
                {"product_id": p1["id"], "packaging_id": None, "packages_count": 100000, "unit_price_cents": 550},
                {"product_id": p2["id"], "packaging_id": None, "packages_count": 50000, "unit_price_cents": 800},
            ],
        },
        headers=headers,
    )

    # 4. Basket Type
    import uuid
    b_code = f"CB_{uuid.uuid4().hex[:6]}"
    basket = client.post(
        "/api/v1/basket-types",
        json={"code": b_code, "name": "Cesta Familia Padrao", "category": "PADRAO", "default_price_cents": 12000},
        headers=headers,
    ).json()

    # 5. Recipe: 5,000g Arroz + 2,000g Feijao per basket
    client.post(
        f"/api/v1/basket-types/{basket['id']}/recipes",
        json={
            "items": [
                {"product_id": p1["id"], "quantity_in_base_units": 5000, "section": "ALIMENTACAO"},
                {"product_id": p2["id"], "quantity_in_base_units": 2000, "section": "ALIMENTACAO"},
            ]
        },
        headers=headers,
    )

    return p1, p2, basket


def test_sale_from_finished_stock(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # 1. Attempting to sell 2 baskets from stock before assembling must fail with INSUFFICIENT_STOCK
    fail_sale = client.post(
        "/api/v1/sales",
        json={
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 12000, "assemble_on_demand": False}
            ],
        },
        headers=headers,
    )
    assert fail_sale.status_code == 409
    assert fail_sale.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"

    # 2. Assemble 5 baskets into stock via production
    prod_resp = client.post(
        "/api/v1/production/batches",
        json={"basket_type_id": basket["id"], "quantity_produced": 5},
        headers=headers,
    )
    assert prod_resp.status_code == 201

    # 3. Now sell 2 baskets from stock
    sale_resp = client.post(
        "/api/v1/sales",
        json={
            "customer_name": "Consumidor Balcao",
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 2,
                    "unit_price_cents": 12000,
                    "discount_cents": 500, # R$ 5,00 discount
                    "assemble_on_demand": False,
                }
            ],
        },
        headers=headers,
    )
    assert sale_resp.status_code == 201, sale_resp.text
    sale_data = sale_resp.json()
    assert sale_data["status"] == "CONFIRMED"
    assert sale_data["payment_status"] == "PAID"
    assert sale_data["total_amount_cents"] == (2 * 12000) - 500 # 23500 cents
    assert sale_data["customer_name"] == "Consumidor Balcao"
    assert len(sale_data["items"]) == 1
    assert sale_data["items"][0]["quantity"] == 2
    assert sale_data["items"][0]["unit_cost_cents"] > 0
    assert sale_data["total_cost_cents"] > 0
    assert sale_data["gross_margin_cents"] == sale_data["total_amount_cents"] - sale_data["total_cost_cents"]

    # 4. Check remaining finished stock (5 produced - 2 sold = 3 remaining)
    stock_resp = client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers)
    assert stock_resp.json()["current_stock"] == 3


def test_simultaneous_assembly_on_demand(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # Inbound had 100,000g Arroz and 50,000g Feijao. Basket requires 5,000g Arroz + 2,000g Feijao.
    # We sell 4 baskets with assemble_on_demand=True:
    # Ingredients needed: 4 * 5,000 = 20,000g Arroz; 4 * 2,000 = 8,000g Feijao.
    sale_resp = client.post(
        "/api/v1/sales",
        json={
            "customer_name": "Maria Oliveira",
            "payment_mode": "PIX",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 4,
                    "unit_price_cents": 11500, # Negotiated special price
                    "discount_cents": 0,
                    "assemble_on_demand": True,
                }
            ],
        },
        headers=headers,
    )
    assert sale_resp.status_code == 201, sale_resp.text
    sale_data = sale_resp.json()
    assert sale_data["status"] == "CONFIRMED"
    assert sale_data["items"][0]["quantity"] == 4
    assert sale_data["items"][0]["production_batch_id"] is not None
    assert sale_data["items"][0]["unit_cost_cents"] > 0

    # Finished stock should be 0 (produced 4, sold 4 on demand)
    stock_resp = client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers)
    assert stock_resp.json()["current_stock"] == 0

    # Check remaining raw ingredients:
    # Arroz: 100,000 - 20,000 = 80,000g
    # Feijao: 50,000 - 8,000 = 42,000g
    stk_arroz = client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()
    assert stk_arroz["current_stock"] == 80000

    stk_feijao = client.get(f"/api/v1/inventory/products/{p2['id']}/stock", headers=headers).json()
    assert stk_feijao["current_stock"] == 42000


def test_custom_basket_assembly_on_demand(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    client.put(f"/api/v1/basket-types/{basket['id']}", json={"allows_customization": True}, headers=headers)

    # Sell 2 custom baskets on demand with extra feijao (3,000g each) and less arroz (2,000g each)
    custom_items = [
        {"product_id": p1["id"], "quantity_in_base_units": 2000, "section": "ALIMENTACAO"},
        {"product_id": p2["id"], "quantity_in_base_units": 3000, "section": "ALIMENTACAO"},
    ]
    sale_resp = client.post(
        "/api/v1/sales",
        json={
            "customer_name": "Empresa Parceira",
            "payment_mode": "CARD",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 2,
                    "unit_price_cents": 13000,
                    "discount_cents": 0,
                    "assemble_on_demand": True,
                    "is_custom": True,
                    "custom_description": "Cesta Especial com Feijao Reforcado",
                    "custom_items": custom_items,
                }
            ],
        },
        headers=headers,
    )
    assert sale_resp.status_code == 201, sale_resp.text
    sale_data = sale_resp.json()
    batch_id = sale_data["items"][0]["production_batch_id"]
    assert batch_id is not None

    # Verify custom production batch was created and flagged as direct sale
    batch_resp = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers)
    assert batch_resp.status_code == 200
    b_data = batch_resp.json()
    assert b_data["is_custom"] is True
    assert b_data["is_direct_sale"] is True
    assert b_data["custom_description"] == "Cesta Especial com Feijao Reforcado"


def test_credit_term_sale_and_credit_limit(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # 1. Create Customer with credit limit of R$ 300,00 (30,000 cents)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Joao da Mercearia", "credit_limit_cents": 30000},
        headers=headers,
    ).json()

    # 2. CREDIT_TERM without customer must fail with 400
    fail_no_cust = client.post(
        "/api/v1/sales",
        json={
            "payment_mode": "CREDIT_TERM",
            "items": [{"basket_type_id": basket["id"], "quantity": 1, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    )
    assert fail_no_cust.status_code == 400

    # 3. Successful credit sale under limit: 2 baskets @ 10,000 cents = 20,000 cents (<= 30,000)
    sale1 = client.post(
        "/api/v1/sales",
        json={
            "customer_id": customer["id"],
            "payment_mode": "CREDIT_TERM",
            "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    ).json()
    assert sale1["status"] == "CONFIRMED"
    assert sale1["payment_status"] == "PENDING"
    assert sale1["receivable_id"] is not None
    assert sale1["receivable_balance_cents"] == 20000

    # Customer statement and debt check
    stmt = client.get(f"/api/v1/customers/{customer['id']}/statement", headers=headers).json()
    assert stmt["current_debt_cents"] == 20000
    assert stmt["available_credit_cents"] == 10000

    # 4. Attempting another credit sale of 2 baskets @ 10,000 cents (20,000 + 20,000 = 40,000 > 30,000 limit)
    # Must fail with CREDIT_LIMIT_EXCEEDED when allow_credit_override=False
    fail_limit = client.post(
        "/api/v1/sales",
        json={
            "customer_id": customer["id"],
            "payment_mode": "CREDIT_TERM",
            "allow_credit_override": False,
            "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    )
    assert fail_limit.status_code == 409
    assert fail_limit.json()["detail"]["error_code"] == "CREDIT_LIMIT_EXCEEDED"
    assert fail_limit.json()["detail"]["exceeded_by_cents"] == 10000

    # 5. Same sale with allow_credit_override=True succeeds
    override_sale = client.post(
        "/api/v1/sales",
        json={
            "customer_id": customer["id"],
            "payment_mode": "CREDIT_TERM",
            "allow_credit_override": True,
            "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 10000, "assemble_on_demand": True}],
        },
        headers=headers,
    )
    assert override_sale.status_code == 201


def test_sale_idempotency(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    idem_key = "sale-idem-key-999"
    headers_idem = {**headers, "X-Idempotency-Key": idem_key}

    payload = {
        "customer_name": "Cliente Idempotente",
        "payment_mode": "CASH_IMMEDIATE",
        "items": [{"basket_type_id": basket["id"], "quantity": 1, "unit_price_cents": 10000, "assemble_on_demand": True}],
    }

    # First request
    resp1 = client.post("/api/v1/sales", json=payload, headers=headers_idem)
    assert resp1.status_code == 201
    sale_id = resp1.json()["id"]

    # Replay identical request
    resp2 = client.post("/api/v1/sales", json=payload, headers=headers_idem)
    assert resp2.status_code == 201
    assert resp2.json()["id"] == sale_id

    # Same key with different payload must reject with 409
    payload_mismatch = {**payload, "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 10000, "assemble_on_demand": True}]}
    resp3 = client.post("/api/v1/sales", json=payload_mismatch, headers=headers_idem)
    assert resp3.status_code == 409


def test_sale_cancellation_and_inventory_reversal(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # 1. Produce 5 baskets
    client.post("/api/v1/production/batches", json={"basket_type_id": basket["id"], "quantity_produced": 5}, headers=headers)
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 5

    # 2. Sell 2 baskets
    sale = client.post(
        "/api/v1/sales",
        json={
            "customer_name": "Comprador Cancelamento",
            "payment_mode": "CASH_IMMEDIATE",
            "items": [{"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 12000, "assemble_on_demand": False}],
        },
        headers=headers,
    ).json()
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 3

    # 3. Cancel sale
    cancel_resp = client.post(
        f"/api/v1/sales/{sale['id']}/cancel",
        json={"reason": "Desistencia do cliente antes da entrega"},
        headers=headers,
    )
    assert cancel_resp.status_code == 200, cancel_resp.text
    canceled_data = cancel_resp.json()
    assert canceled_data["status"] == "CANCELED"
    assert canceled_data["cancellation_reason"] == "Desistencia do cliente antes da entrega"

    # 4. Finished baskets stock must be restored to 5
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 5


def test_simultaneous_assembly_insufficient_stock_fails(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # In setup, we have 100,000g Arroz and 50,000g Feijao.
    # Recipe needs 5,000g Arroz and 2,000g Feijao per basket.
    # Max possible baskets is min(100000/5000, 50000/2000) = min(20, 25) = 20 baskets.
    # Trying to sell 25 baskets on demand must fail with INSUFFICIENT_STOCK.
    resp = client.post(
        "/api/v1/sales",
        json={
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 25,
                    "unit_price_cents": 12000,
                    "assemble_on_demand": True,
                }
            ],
        },
        headers=headers,
    )
    assert resp.status_code == 409
    assert resp.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"


def test_sale_cancellation_of_assemble_on_demand_restores_finished_stock(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)

    # Initial basket stock is 0
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 0

    # Sell 3 baskets with simultaneous assembly on demand
    sale = client.post(
        "/api/v1/sales",
        json={
            "customer_name": "Cliente Montagem Sob Demanda",
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 3,
                    "unit_price_cents": 12000,
                    "assemble_on_demand": True,
                }
            ],
        },
        headers=headers,
    ).json()

    # After on-demand sale: 3 produced and 3 sold -> stock is 0
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 0

    # Cancel the sale
    cancel_resp = client.post(
        f"/api/v1/sales/{sale['id']}/cancel",
        json={"reason": "Cancelamento de venda montada sob demanda"},
        headers=headers,
    )
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "CANCELED"
    assert cancel_resp.json()["payment_status"] == "CANCELED"

    # The baskets that were physically produced now remain in stock ready to be sold (+3)
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 3
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 85000


@pytest.mark.parametrize("custom", [False, True])
def test_cancel_unassembled_sale_restores_original_products(client, authenticated_device, custom):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    item = {"basket_type_id": basket["id"], "quantity": 3,
            "unit_price_cents": 12000, "assemble_on_demand": True}
    if custom:
        client.put(f"/api/v1/basket-types/{basket['id']}", json={"allows_customization": True}, headers=headers)
        item.update(is_custom=True, custom_description="Composicao especial", custom_items=[
            {"product_id": p1["id"], "quantity_in_base_units": 1000}])
    response = client.post("/api/v1/sales", json={"items": [item]}, headers=headers)
    assert response.status_code == 201, response.text
    sale = response.json()
    assert sale["items"][0]["assembled_on_demand"] is True
    # A subsequent recipe change must not affect the returned composition.
    client.post(f"/api/v1/basket-types/{basket['id']}/recipes", json={"items": [
        {"product_id": p2["id"], "quantity_in_base_units": 9000, "section": "ALIMENTACAO"}]}, headers=headers)
    payload = {"reason": "Venda registrada por engano, montagem nao aconteceu",
               "unassembled_item_ids": [sale["items"][0]["id"]]}
    if custom:
        payload["reason"] += " detalhe" * 80
    import uuid
    retry_headers = {**headers, "X-Idempotency-Key": str(uuid.uuid4())}
    for _ in range(2):
        cancel = client.post(f"/api/v1/sales/{sale['id']}/cancel", json=payload, headers=retry_headers)
        assert cancel.status_code == 200, cancel.text
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 0
    for product, stock in [(p1, 100000), (p2, 50000)]:
        assert client.get(f"/api/v1/inventory/products/{product['id']}/stock", headers=headers).json()["current_stock"] == stock
    batch = client.get(f"/api/v1/production/batches/{sale['items'][0]['production_batch_id']}", headers=headers).json()
    assert batch["status"] == "DISASSEMBLED"


def test_cancel_finished_stock_cannot_return_ingredients(client, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    client.post("/api/v1/production/batches", json={"basket_type_id": basket["id"], "quantity_produced": 2}, headers=headers)
    sale = client.post("/api/v1/sales", json={"items": [{"basket_type_id": basket["id"], "quantity": 1, "unit_price_cents": 12000}]}, headers=headers).json()
    assert sale["items"][0]["assembled_on_demand"] is False
    cancel = client.post(f"/api/v1/sales/{sale['id']}/cancel", json={
        "reason": "Tentativa indevida", "unassembled_item_ids": [sale["items"][0]["id"]]}, headers=headers)
    assert cancel.status_code == 422
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 1
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 90000


def test_cancel_mixed_sale_and_invalid_item_is_atomic(client, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    items = [{"basket_type_id": basket["id"], "quantity": 1,
              "unit_price_cents": 12000, "assemble_on_demand": True} for _ in range(2)]
    sale = client.post("/api/v1/sales", json={"items": items}, headers=headers).json()
    bad = client.post(f"/api/v1/sales/{sale['id']}/cancel", json={
        "reason": "Registro incorreto", "unassembled_item_ids": ["outro-item"]}, headers=headers)
    assert bad.status_code == 422
    assert client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()["status"] == "CONFIRMED"
    cancel = client.post(f"/api/v1/sales/{sale['id']}/cancel", json={
        "reason": "Uma cesta montada, outra nao", "unassembled_item_ids": [sale["items"][0]["id"]]}, headers=headers)
    assert cancel.status_code == 200, cancel.text
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 1
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 95000


def test_basket_without_ready_stock_requires_on_demand_assembly(client, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    update = client.put(f"/api/v1/basket-types/{basket['id']}", json={"tracks_finished_stock": False}, headers=headers)
    assert update.status_code == 200
    item = {"basket_type_id": basket["id"], "quantity": 2, "unit_price_cents": 12000}
    response = client.post("/api/v1/sales", json={"items": [item]}, headers=headers)
    assert response.status_code == 409
    assert response.json()["detail"]["error_code"] == "BASKET_STOCK_DISABLED"
    standalone = client.post("/api/v1/production/batches", json={"basket_type_id": basket["id"], "quantity_produced": 2}, headers=headers)
    assert standalone.status_code == 409
    response = client.post("/api/v1/sales", json={"items": [{**item, "assemble_on_demand": True}]}, headers=headers)
    assert response.status_code == 201, response.text
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()["current_stock"] == 0
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 90000


def test_cannot_disable_ready_stock_with_existing_baskets(client, authenticated_device):
    _, _, headers = authenticated_device
    _, _, basket = _setup_inventory_and_basket(client, headers)
    client.post("/api/v1/production/batches", json={"basket_type_id": basket["id"], "quantity_produced": 2}, headers=headers)
    response = client.put(f"/api/v1/basket-types/{basket['id']}", json={"tracks_finished_stock": False}, headers=headers)
    assert response.status_code == 409
    assert response.json()["detail"]["error_code"] == "BASKET_STOCK_REMAINS"
    assert client.get(f"/api/v1/basket-types/{basket['id']}", headers=headers).json()["tracks_finished_stock"] is True


def test_standard_assembly_history_includes_advance_and_sale_with_utc_time(client, authenticated_device):
    _, _, headers = authenticated_device
    p1, _, basket = _setup_inventory_and_basket(client, headers)
    preview = client.post('/api/v1/production/preview', json={
        'basket_type_id': basket['id'], 'quantity_produced': 5}, headers=headers).json()
    payload = {'basket_type_id': basket['id'], 'quantity_produced': 5,
               'occurred_at': '2026-10-14T09:30:00-03:00',
               'expected_recipe_version_number': preview['recipe_version_number']}
    import uuid
    retry_headers = {**headers, 'X-Idempotency-Key': str(uuid.uuid4())}
    for _ in range(2):
        batch = client.post('/api/v1/production/batches', json=payload, headers=retry_headers)
        assert batch.status_code == 201, batch.text
    when = datetime.datetime.fromisoformat(batch.json()['occurred_at'].replace('Z', '+00:00'))
    assert when == datetime.datetime(2026, 10, 14, 12, 30, tzinfo=datetime.timezone.utc)
    sale = client.post('/api/v1/sales', json={'items': [{
        'basket_type_id': basket['id'], 'quantity': 2, 'unit_price_cents': 12000,
        'assemble_on_demand': True}]}, headers=headers)
    assert sale.status_code == 201
    history = client.get(f"/api/v1/production/batches?basket_type_id={basket['id']}", headers=headers).json()
    assert history['total'] == 2
    assert sorted((b['quantity_produced'], b['is_direct_sale']) for b in history['items']) == [(2, True), (5, False)]
    assert client.get(f"/api/v1/inventory/baskets/{basket['id']}/stock", headers=headers).json()['current_stock'] == 5
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()['current_stock'] == 65000


def test_assembly_rejects_recipe_changed_since_preview(client, authenticated_device):
    _, _, headers = authenticated_device
    p1, _, basket = _setup_inventory_and_basket(client, headers)
    preview = client.post('/api/v1/production/preview', json={
        'basket_type_id': basket['id'], 'quantity_produced': 1}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{basket['id']}/recipes", json={'items': [
        {'product_id': p1['id'], 'quantity_in_base_units': 1000, 'section': 'ALIMENTACAO'}]}, headers=headers)
    result = client.post('/api/v1/production/batches', json={
        'basket_type_id': basket['id'], 'quantity_produced': 1,
        'expected_recipe_version_number': preview['recipe_version_number']}, headers=headers)
    assert result.status_code == 409
    assert result.json()['detail']['error_code'] == 'RECIPE_CHANGED'
    assert client.get(f"/api/v1/production/batches?basket_type_id={basket['id']}", headers=headers).json()['total'] == 0
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()['current_stock'] == 100000


def test_production_legacy_request_keeps_its_idempotency_hash(client, authenticated_device, test_session):
    from sqlalchemy import select
    from app.core.idempotency import compute_payload_hash
    from app.models.idempotency import IdempotencyRecord
    from app.schemas.production import ProductionBatchCreate
    import uuid
    _, _, headers = authenticated_device
    _, _, basket = _setup_inventory_and_basket(client, headers)
    payload = {'basket_type_id': basket['id'], 'quantity_produced': 1}
    key = str(uuid.uuid4())
    retry_headers = {**headers, 'X-Idempotency-Key': key}
    result = client.post('/api/v1/production/batches', json=payload, headers=retry_headers)
    assert result.status_code == 201, result.text
    legacy = ProductionBatchCreate(**payload).model_dump(mode='json')
    legacy.pop('expected_recipe_version_number')
    record = test_session.scalar(select(IdempotencyRecord).where(IdempotencyRecord.idempotency_key == key))
    assert record.request_payload_hash == compute_payload_hash(legacy)
    test_session.rollback()  # Release BEGIN IMMEDIATE before the HTTP replay.
    replay = client.post('/api/v1/production/batches', json=payload, headers=retry_headers)
    assert replay.status_code == 201
    assert replay.json()['id'] == result.json()['id']


def test_custom_batch_sale_rejects_non_confirmed_batch(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device
    p1, p2, basket = _setup_inventory_and_basket(client, headers)
    client.put(f"/api/v1/basket-types/{basket['id']}", json={"allows_customization": True}, headers=headers)

    # 1. Produce a custom batch of 2 baskets
    custom_batch = client.post(
        "/api/v1/production/batches",
        json={
            "basket_type_id": basket["id"],
            "quantity_produced": 2,
            "is_custom": True,
            "custom_description": "Cesta Especial Canceled",
            "custom_items": [
                {"product_id": p1["id"], "quantity_in_base_units": 4000, "section": "ALIMENTACAO"},
            ],
        },
        headers=headers,
    ).json()

    # 2. Cancel the custom batch
    cancel_batch = client.post(
        f"/api/v1/production/batches/{custom_batch['id']}/cancel",
        json={"reason": "Lote montado com avaria de embalagem"},
        headers=headers,
    )
    assert cancel_batch.status_code == 200

    # 3. Attempt to sell the canceled custom batch from stock must fail
    sale_resp = client.post(
        "/api/v1/sales",
        json={
            "payment_mode": "CASH_IMMEDIATE",
            "items": [
                {
                    "basket_type_id": basket["id"],
                    "quantity": 1,
                    "unit_price_cents": 15000,
                    "production_batch_id": custom_batch["id"],
                    "assemble_on_demand": False,
                }
            ],
        },
        headers=headers,
    )
    assert sale_resp.status_code == 400
    assert "nao esta confirmado" in sale_resp.json()["detail"]
