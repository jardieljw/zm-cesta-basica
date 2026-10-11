import pytest
import datetime
from fastapi import status
from sqlalchemy import select
from app.models.movements import InventoryMovement
from app.services.inventory import record_inventory_movement

def test_inventory_summary_and_minimum_stock_alert(client, authenticated_device, test_session):
    _, _, headers = authenticated_device

    # 1. Cria produto A com estoque minimo 100
    p1 = client.post("/api/v1/products", json={
        "name": "Arroz Agulhinha 5kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "minimum_stock": 50000,
        "cost_price_cents": 2500,
        "sale_price_cents": 3200,
    }, headers=headers).json()

    # 2. Cria produto B com estoque minimo 0
    p2 = client.post("/api/v1/products", json={
        "name": "Sabao em Barra 200g",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
        "minimum_stock": 10,
        "cost_price_cents": 300,
        "sale_price_cents": 500,
    }, headers=headers).json()

    # Consulta resumo antes de compras
    r = client.get("/api/v1/inventory/summary", headers=headers)
    assert r.status_code == status.HTTP_200_OK
    items = r.json()
    assert len(items) >= 2

    arroz_summary = next(it for it in items if it["product_id"] == p1["id"])
    assert arroz_summary["current_stock"] == 0
    assert arroz_summary["minimum_stock"] == 50000
    assert arroz_summary["is_below_minimum"] is True

    # Realiza compra do Sabao acima do minimo
    client.post("/api/v1/purchases", json={
        "supplier_name": "Distribuidora Sul",
        "items": [
            {
                "product_id": p2["id"],
                "packaging_id": None,
                "packages_count": 25,
                "unit_price_cents": 300,
            }
        ]
    }, headers=headers)

    # Consulta resumo filtrando apenas itens abaixo do minimo
    r_below = client.get("/api/v1/inventory/summary?below_minimum_only=true", headers=headers)
    assert r_below.status_code == status.HTTP_200_OK
    below_items = r_below.json()
    assert any(it["product_id"] == p1["id"] for it in below_items)
    assert not any(it["product_id"] == p2["id"] for it in below_items)


def test_movements_ledger_pagination_and_filters(client, authenticated_device, test_session):
    _, _, headers = authenticated_device

    # Cria dois produtos
    p1 = client.post("/api/v1/products", json={
        "name": "Feijao Preto 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()

    p2 = client.post("/api/v1/products", json={
        "name": "Oleo de Soja 900ml",
        "category": "ALIMENTACAO",
        "base_unit": "ML",
    }, headers=headers).json()

    # Compra 1: Feijao
    client.post("/api/v1/purchases", json={
        "supplier_name": "Graos Brasil",
        "items": [{"product_id": p1["id"], "packages_count": 10000, "unit_price_cents": 700}]
    }, headers=headers)

    # Compra 2: Oleo
    client.post("/api/v1/purchases", json={
        "supplier_name": "Oleos do Campo",
        "items": [{"product_id": p2["id"], "packages_count": 5000, "unit_price_cents": 600}]
    }, headers=headers)

    # Ajuste manual positivo no feijao
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": p1["id"],
        "adjustment_type": "IN",
        "quantity_delta": 2000,
        "reason": "Sobra de conferencia de carga",
    }, headers=headers)

    # 1. Listar todas as movimentacoes paginadas
    r_all = client.get("/api/v1/inventory/movements?page=1&page_size=2", headers=headers)
    assert r_all.status_code == status.HTTP_200_OK
    data = r_all.json()
    assert data["total"] >= 3
    assert len(data["items"]) == 2
    assert data["page"] == 1
    assert data["page_size"] == 2
    assert data["total_pages"] >= 2

    # 2. Filtrar por produto (Feijao)
    r_p1 = client.get(f"/api/v1/inventory/movements?product_id={p1['id']}", headers=headers)
    assert r_p1.status_code == status.HTTP_200_OK
    items_p1 = r_p1.json()["items"]
    assert len(items_p1) == 2
    assert all(it["product_id"] == p1["id"] for it in items_p1)

    # 3. Filtrar por movement_type (ADJUSTMENT_IN)
    r_adj = client.get("/api/v1/inventory/movements?movement_type=ADJUSTMENT_IN", headers=headers)
    assert r_adj.status_code == status.HTTP_200_OK
    items_adj = r_adj.json()["items"]
    assert len(items_adj) >= 1
    assert all(it["movement_type"] == "ADJUSTMENT_IN" for it in items_adj)


def test_product_stock_and_running_balance_ledger(client, authenticated_device):
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={
        "name": "Macarrao Espaguete 500g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
        "minimum_stock": 20,
    }, headers=headers).json()
    p_id = p["id"]

    # Consulta saldo inicial
    r_stk = client.get(f"/api/v1/inventory/products/{p_id}/stock", headers=headers)
    assert r_stk.status_code == status.HTTP_200_OK
    assert r_stk.json()["current_stock"] == 0
    assert r_stk.json()["is_below_minimum"] is True

    # Entrada 1 (+50)
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": p_id, "packages_count": 50, "unit_price_cents": 350}]
    }, headers=headers)

    # Saida / Perda (-10)
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": p_id,
        "adjustment_type": "LOSS",
        "quantity_delta": 10,
        "reason": "Pacotes rasgados no transporte",
    }, headers=headers)

    # Entrada 2 (+20)
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": p_id, "packages_count": 20, "unit_price_cents": 350}]
    }, headers=headers)

    # Saldo atual deve ser 50 - 10 + 20 = 60
    r_stk2 = client.get(f"/api/v1/inventory/products/{p_id}/stock", headers=headers)
    assert r_stk2.json()["current_stock"] == 60
    assert r_stk2.json()["is_below_minimum"] is False

    # Extrato cronologico do produto com running balance
    r_ledger = client.get(f"/api/v1/inventory/products/{p_id}/movements", headers=headers)
    assert r_ledger.status_code == status.HTTP_200_OK
    ledger_items = r_ledger.json()
    assert len(ledger_items) == 3
    # Os itens sao retornados em ordem decrescente (mais recente primeiro)
    assert ledger_items[0]["quantity_delta"] == 20
    assert ledger_items[0]["running_balance"] == 60

    assert ledger_items[1]["quantity_delta"] == -10
    assert ledger_items[1]["running_balance"] == 40

    assert ledger_items[2]["quantity_delta"] == 50
    assert ledger_items[2]["running_balance"] == 50


def test_append_only_ledger_enforcement_prevents_update(test_session):
    """Testa que mutacao fisica (UPDATE) de linhas do livro-razao e estritamente proibida."""
    # Cria um movimento
    mov = record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="PURCHASE",
        quantity_delta=100,
        source_type="PURCHASE",
        source_id="purch-test-01",
        reason="Compra inicial",
    )
    test_session.commit()

    # Tenta alterar a quantidade do movimento existente
    mov.quantity_delta = 9999
    with pytest.raises(ValueError, match="estritamente append-only"):
        test_session.flush()

    test_session.rollback()


def test_append_only_ledger_enforcement_prevents_delete(test_session):
    """Testa que exclusao fisica (DELETE) de linhas do livro-razao e estritamente proibida."""
    mov = record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="PURCHASE",
        quantity_delta=50,
        source_type="PURCHASE",
        source_id="purch-test-02",
        reason="Compra teste",
    )
    test_session.commit()

    # Tenta excluir o movimento
    test_session.delete(mov)
    with pytest.raises(ValueError, match="estritamente append-only"):
        test_session.flush()

    test_session.rollback()


def test_sqlite_triggers_prevent_raw_sql_update_and_delete(test_session):
    """Testa que triggers SQLite nativos rejeitam mutacao direta via raw SQL."""
    from sqlalchemy import text
    from sqlalchemy.exc import OperationalError, DatabaseError

    mov = record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="PURCHASE",
        quantity_delta=100,
        source_type="PURCHASE",
        source_id="purch-raw-sql-01",
        reason="Compra raw SQL",
    )
    test_session.commit()

    # Tenta UPDATE via raw SQL direto
    with pytest.raises((OperationalError, DatabaseError), match="append-only"):
        test_session.execute(text(f"UPDATE inventory_movements SET quantity_delta = 999 WHERE id = '{mov.id}'"))
        test_session.commit()
    test_session.rollback()

    # Tenta DELETE via raw SQL direto
    with pytest.raises((OperationalError, DatabaseError), match="append-only"):
        test_session.execute(text(f"DELETE FROM inventory_movements WHERE id = '{mov.id}'"))
        test_session.commit()
    test_session.rollback()


def test_product_movements_ledger_preserves_running_balance_across_date_windows(client, authenticated_device, test_session):
    """Testa que o saldo progressivo respeita o saldo anterior quando filtrado por data de inicio."""
    _, _, headers = authenticated_device
    import datetime

    p = client.post("/api/v1/products", json={
        "name": "Farinha de Milho 500g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    p_id = p["id"]

    now = datetime.datetime.now(datetime.timezone.utc)
    d1 = now - datetime.timedelta(days=10)
    d2 = now - datetime.timedelta(days=5)
    d3 = now - datetime.timedelta(days=1)

    # Movimento 1: +100 unidades no dia 1
    record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="PURCHASE",
        quantity_delta=100,
        source_type="PURCHASE",
        source_id="purch-01",
        product_id=p_id,
        occurred_at=d1,
    )
    # Movimento 2: -20 unidades no dia 2
    record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="ADJUSTMENT_OUT",
        quantity_delta=-20,
        source_type="ADJUSTMENT",
        source_id="adj-01",
        product_id=p_id,
        occurred_at=d2,
    )
    # Movimento 3: +30 unidades no dia 3
    record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="PURCHASE",
        quantity_delta=30,
        source_type="PURCHASE",
        source_id="purch-02",
        product_id=p_id,
        occurred_at=d3,
    )
    test_session.commit()

    # Consulta com start_date no dia 2 (d2):
    # O saldo anterior (d1) era 100.
    # Movimento no dia 2 (-20) deve ter running_balance = 80.
    # Movimento no dia 3 (+30) deve ter running_balance = 110.
    start_dt = d2 - datetime.timedelta(hours=1)
    resp = client.get(
        f"/api/v1/inventory/products/{p_id}/movements",
        params={"start_date": start_dt.isoformat()},
        headers=headers,
    )
    assert resp.status_code == status.HTTP_200_OK
    items = resp.json()
    assert len(items) == 2
    # Mais recente primeiro
    assert items[0]["quantity_delta"] == 30
    assert items[0]["running_balance"] == 110

    assert items[1]["quantity_delta"] == -20
    assert items[1]["running_balance"] == 80


def test_product_stock_counts_production_batch_movements(client, authenticated_device, test_session):
    """Testa que baixas de insumo com production_batch_id populado sao contabilizadas no estoque do produto."""
    _, _, headers = authenticated_device
    import uuid
    from app.models.products import BasketType
    from app.models.production import ProductionBatch

    prod = client.post("/api/v1/products", json={
        "name": "Item Consumido em Lote",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Compra inicial de 50 unidades
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 50, "unit_price_cents": 100}]
    }, headers=headers)

    # Cria BasketType e ProductionBatch validos para satisfazer FK
    bt = BasketType(
        id=str(uuid.uuid4()),
        code="BT_LOTE_TEST",
        name="Cesta de Teste Lote",
    )
    test_session.add(bt)
    test_session.flush()

    batch = ProductionBatch(
        id=str(uuid.uuid4()),
        batch_number=999,
        basket_type_id=bt.id,
        quantity_produced=5,
        status="CONFIRMED",
    )
    test_session.add(batch)
    test_session.flush()

    # Registra consumo de 15 unidades pelo lote
    record_inventory_movement(
        db=test_session,
        item_type="PRODUCT",
        movement_type="ASSEMBLY_CONSUME",
        quantity_delta=-15,
        source_type="PRODUCTION",
        source_id=batch.id,
        product_id=prod_id,
        production_batch_id=batch.id,
        reason="Consumo montagem de cesta",
    )
    test_session.commit()

    # Saldo deve ser 50 - 15 = 35 (nao pode ignorar o movimento de lote!)
    stk_resp = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers)
    assert stk_resp.status_code == status.HTTP_200_OK
    assert stk_resp.json()["current_stock"] == 35

    # No resumo tambem deve ser 35
    summary_resp = client.get("/api/v1/inventory/summary", headers=headers)
    prod_sum = next(it for it in summary_resp.json() if it["product_id"] == prod_id)
    assert prod_sum["current_stock"] == 35


def test_basket_stock_endpoint(client, authenticated_device, test_session):
    """Testa o endpoint GET /inventory/baskets/{basket_type_id}/stock."""
    _, _, headers = authenticated_device

    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_STOCK_TEST",
        "name": "Cesta Teste de Estoque",
        "default_price_cents": 12000,
    }, headers=headers).json()
    bt_id = bt["id"]

    # Saldo inicial = 0
    r0 = client.get(f"/api/v1/inventory/baskets/{bt_id}/stock", headers=headers)
    assert r0.status_code == status.HTTP_200_OK
    assert r0.json()["current_stock"] == 0
    assert r0.json()["basket_name"] == "Cesta Teste de Estoque"

    # Entrada de 10 cestas acabadas
    record_inventory_movement(
        db=test_session,
        item_type="BASKET",
        movement_type="ASSEMBLY_PRODUCE",
        quantity_delta=10,
        source_type="PRODUCTION",
        source_id="prod-batch-001",
        basket_type_id=bt_id,
    )
    test_session.commit()

    r1 = client.get(f"/api/v1/inventory/baskets/{bt_id}/stock", headers=headers)
    assert r1.status_code == status.HTTP_200_OK
    assert r1.json()["current_stock"] == 10
