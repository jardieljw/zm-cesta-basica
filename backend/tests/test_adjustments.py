import uuid
import threading
import pytest
from fastapi import status

def test_adjustment_in_increases_stock(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Sardinha em Lata 125g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Ajuste positivo
    payload = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "IN",
        "quantity_delta": 25,
        "reason": "Sobra identificada na contagem semanal",
    }
    r = client.post("/api/v1/inventory/adjustments", json=payload, headers=headers)
    assert r.status_code == status.HTTP_201_CREATED
    data = r.json()
    assert data["previous_stock"] == 0
    assert data["quantity_delta"] == 25
    assert data["new_stock"] == 25
    assert data["movement_type"] == "ADJUSTMENT_IN"
    assert data["reason"] == "Sobra identificada na contagem semanal"

    # Saldo deve ser 25
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 25


def test_adjustment_out_decreases_stock_when_sufficient(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Milho Verde em Lata 170g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Entrada de 30
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 30, "unit_price_cents": 250}]
    }, headers=headers)

    # Saida de 10
    payload = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "OUT",
        "quantity_delta": 10,
        "reason": "Lata amassada imprópria para consumo",
    }
    r = client.post("/api/v1/inventory/adjustments", json=payload, headers=headers)
    assert r.status_code == status.HTTP_201_CREATED
    data = r.json()
    assert data["previous_stock"] == 30
    assert data["quantity_delta"] == -10
    assert data["new_stock"] == 20
    assert data["movement_type"] == "ADJUSTMENT_OUT"

    # Saldo final = 20
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 20


def test_adjustment_out_rejected_on_insufficient_stock(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Ervilha em Conserva 170g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Saldo inicial = 5
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 5, "unit_price_cents": 250}]
    }, headers=headers)

    # Tenta retirar 10
    payload = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "OUT",
        "quantity_delta": 10,
        "reason": "Tentativa de baixa maior que saldo",
    }
    r = client.post("/api/v1/inventory/adjustments", json=payload, headers=headers)
    assert r.status_code == status.HTTP_409_CONFLICT
    err = r.json()
    assert err["detail"]["error_code"] == "INSUFFICIENT_STOCK"
    assert err["detail"]["current_stock"] == 5
    assert err["detail"]["requested_decrease"] == 10

    # Saldo permanece inalterado em 5
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 5


def test_adjustment_count_physical_inventory(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Sal Grosso 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Saldo = 15
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 15, "unit_price_cents": 200}]
    }, headers=headers)

    # Contagem fisica encontrou 22 (sobra de 7)
    payload_up = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "COUNT",
        "physical_count": 22,
        "reason": "Inventario mensal de estoque",
    }
    r1 = client.post("/api/v1/inventory/adjustments", json=payload_up, headers=headers)
    assert r1.status_code == status.HTTP_201_CREATED
    assert r1.json()["previous_stock"] == 15
    assert r1.json()["quantity_delta"] == 7
    assert r1.json()["new_stock"] == 22
    assert r1.json()["movement_type"] == "ADJUSTMENT_IN"

    # Nova contagem fisica encontrou 18 (falta de 4)
    payload_down = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "COUNT",
        "physical_count": 18,
        "reason": "Recontagem de confirmacao",
    }
    r2 = client.post("/api/v1/inventory/adjustments", json=payload_down, headers=headers)
    assert r2.status_code == status.HTTP_201_CREATED
    assert r2.json()["previous_stock"] == 22
    assert r2.json()["quantity_delta"] == -4
    assert r2.json()["new_stock"] == 18
    assert r2.json()["movement_type"] == "ADJUSTMENT_OUT"


def test_adjustment_requires_valid_reason_for_audit(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Esponja de Aco",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers).json()

    # Justificativa vazia
    r_empty = client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": prod["id"],
        "adjustment_type": "IN",
        "quantity_delta": 5,
        "reason": "  ",
    }, headers=headers)
    assert r_empty.status_code in (status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY, 422)

    # Justificativa muito curta (< 3 caracteres)
    r_short = client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": prod["id"],
        "adjustment_type": "IN",
        "quantity_delta": 5,
        "reason": "ok",
    }, headers=headers)
    assert r_short.status_code in (status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY, 422)


def test_adjustment_idempotency_prevents_duplicate_adjustments(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Sabonete Liquido 250ml",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    idemp_key = str(uuid.uuid4())
    headers_with_key = {**headers, "X-Idempotency-Key": idemp_key}

    payload = {
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "IN",
        "quantity_delta": 10,
        "reason": "Ajuste com chave de idempotencia",
    }

    # 1. Primeira chamada
    r1 = client.post("/api/v1/inventory/adjustments", json=payload, headers=headers_with_key)
    assert r1.status_code == status.HTTP_201_CREATED
    assert r1.json()["new_stock"] == 10

    # 2. Segunda chamada com mesma chave e payload
    r2 = client.post("/api/v1/inventory/adjustments", json=payload, headers=headers_with_key)
    assert r2.status_code == status.HTTP_201_CREATED
    assert r2.json()["movement_id"] == r1.json()["movement_id"]

    # Saldo NAO PODE duplicar para 20
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 10


def test_concurrent_stock_deduction_prevents_negative_stock(client, authenticated_device):
    """
    Testa que chamadas concorrentes sob BEGIN IMMEDIATE concorrendo pelo ultimo lote
    impedem que o estoque se torne negativo (race condition / TOCTOU prevention).
    """
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Produto Concorrencia Estoque",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Saldo inicial = 10 unidades
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 10, "unit_price_cents": 100}]
    }, headers=headers)

    results = []
    errors = []

    def attempt_deduction():
        try:
            # Cada thread tenta deduzir 10 unidades
            resp = client.post(
                "/api/v1/inventory/adjustments",
                json={
                    "item_type": "PRODUCT",
                    "product_id": prod_id,
                    "adjustment_type": "OUT",
                    "quantity_delta": 10,
                    "reason": "Deducao concorrente de estoque",
                },
                headers=headers,
            )
            results.append(resp.status_code)
        except Exception as e:
            errors.append(e)

    # 4 threads tentam consumir simultaneamente as 10 unidades existentes
    threads = [threading.Thread(target=attempt_deduction) for _ in range(4)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(errors) == 0
    assert len(results) == 4

    # Exatamente UMA requisicao deve ser confirmada (201) e as outras tres devem ser rejeitadas (409)
    successes = results.count(status.HTTP_201_CREATED)
    conflicts = results.count(status.HTTP_409_CONFLICT)

    assert successes == 1
    assert conflicts == 3

    # Saldo final deve ser exatamente ZERO, jamais negativo!
    final_stock = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"]
    assert final_stock == 0


def test_adjustment_rejected_on_inactive_product_and_basket(client, authenticated_device):
    """Testa que ajustes manuais em produtos ou cestas inativas sao expressamente rejeitados com HTTP 400."""
    _, _, headers = authenticated_device

    # 1. Cria e inativa um produto
    p = client.post("/api/v1/products", json={
        "name": "Produto Inativado Teste",
        "category": "OUTROS",
        "base_unit": "UNIT",
    }, headers=headers).json()
    client.delete(f"/api/v1/products/{p['id']}", headers=headers)

    # Tenta ajuste
    r_prod = client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": p["id"],
        "adjustment_type": "IN",
        "quantity_delta": 10,
        "reason": "Tentativa indevida em produto inativo",
    }, headers=headers)
    assert r_prod.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativo" in r_prod.json()["detail"]

    # 2. Cria e inativa uma cesta
    b = client.post("/api/v1/basket-types", json={
        "code": "CESTA_INAT_TEST",
        "name": "Cesta Inativa",
    }, headers=headers).json()
    client.delete(f"/api/v1/basket-types/{b['id']}", headers=headers)

    # Tenta ajuste
    r_bt = client.post("/api/v1/inventory/adjustments", json={
        "item_type": "BASKET",
        "basket_type_id": b["id"],
        "adjustment_type": "IN",
        "quantity_delta": 5,
        "reason": "Tentativa indevida em cesta inativa",
    }, headers=headers)
    assert r_bt.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativ" in r_bt.json()["detail"]


def test_adjustment_sanitizes_conflicting_item_ids(client, authenticated_device, test_session):
    """Testa que o schema e o servico de ajuste limpam IDs conflitantes (ex: basket_type_id em item PRODUCT)."""
    _, _, headers = authenticated_device
    from sqlalchemy import select
    from app.models.movements import InventoryMovement

    p = client.post("/api/v1/products", json={"name": "Prod Sanit Test", "category": "OUTROS", "base_unit": "UNIT"}, headers=headers).json()
    b = client.post("/api/v1/basket-types", json={"code": "BASK_SANIT_TEST", "name": "Cesta Sanit Test"}, headers=headers).json()

    # Envia PRODUCT mas com basket_type_id preenchido maliciosamente
    r = client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": p["id"],
        "basket_type_id": b["id"],
        "adjustment_type": "IN",
        "quantity_delta": 8,
        "reason": "Teste de sanitizacao de IDs",
    }, headers=headers)
    assert r.status_code == status.HTTP_201_CREATED
    data = r.json()
    mov_id = data["movement_id"]

    # Verifica no banco que basket_type_id foi salvo como NULL
    db_mov = test_session.execute(select(InventoryMovement).where(InventoryMovement.id == mov_id)).scalar_one()
    assert db_mov.item_type == "PRODUCT"
    assert db_mov.product_id == p["id"]
    assert db_mov.basket_type_id is None


def test_massive_concurrency_20_threads_stock_deduction(client, authenticated_device):
    """Testa concorrência massiva de 20 threads disputando o último estoque de 10 unidades sob BEGIN IMMEDIATE."""
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Item Concorrencia 20 Threads",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Saldo inicial = 10 unidades
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod_id, "packages_count": 10, "unit_price_cents": 200}]
    }, headers=headers)

    results = []
    errors = []

    def worker():
        try:
            resp = client.post(
                "/api/v1/inventory/adjustments",
                json={
                    "item_type": "PRODUCT",
                    "product_id": prod_id,
                    "adjustment_type": "OUT",
                    "quantity_delta": 10,
                    "reason": "Disputa massiva de estoque",
                },
                headers=headers,
            )
            results.append(resp.status_code)
        except Exception as e:
            errors.append(e)

    threads = [threading.Thread(target=worker) for _ in range(20)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(errors) == 0
    assert len(results) == 20
    assert results.count(status.HTTP_201_CREATED) == 1
    assert results.count(status.HTTP_409_CONFLICT) == 19

    # Saldo final deve ser exatamente ZERO, jamais negativo
    final_stock = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"]
    assert final_stock == 0
