import pytest
from fastapi import status
from sqlalchemy import select
from app.models.movements import InventoryMovement

def test_create_purchase_without_packaging(client, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Cria produto sem embalagem inicial
    prod = client.post("/api/v1/products", json={
        "name": "Acucar Cristal 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
        "cost_price_cents": 350,
        "sale_price_cents": 490,
    }, headers=headers).json()
    prod_id = prod["id"]

    # 2. Registra compra direta na unidade base
    payload = {
        "supplier_name": "Usina Boa Esperança",
        "notes": "NF 9876",
        "status": "CONFIRMED",
        "items": [
            {
                "product_id": prod_id,
                "packaging_id": None,
                "packages_count": 50,
                "unit_price_cents": 380,
            }
        ]
    }
    r = client.post("/api/v1/purchases", json=payload, headers=headers)
    assert r.status_code == status.HTTP_201_CREATED
    data = r.json()
    assert data["purchase_number"] >= 1
    assert data["status"] == "CONFIRMED"
    assert data["total_amount_cents"] == 50 * 380
    assert len(data["items"]) == 1
    assert data["items"][0]["quantity_in_base_units"] == 50
    assert data["items"][0]["unit_price_cents"] == 380
    assert data["items"][0]["total_price_cents"] == 19000

    # 3. Verifica se o saldo aumentou em 50
    r_stk = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers)
    assert r_stk.json()["current_stock"] == 50

    # 4. Verifica se o preco de custo do produto foi atualizado para 380
    r_prod = client.get(f"/api/v1/products/{prod_id}", headers=headers)
    assert r_prod.json()["cost_price_cents"] == 380


def test_create_purchase_with_packaging_conversion(client, authenticated_device):
    _, _, headers = authenticated_device

    # 1. Cria produto (Sal refinado 1kg, base_unit = G)
    prod = client.post("/api/v1/products", json={
        "name": "Sal Refinado 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    prod_id = prod["id"]

    # 2. Cria embalagem comercial: Fardo com 30 pacotes de 1kg (30.000g)
    pack = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Fardo c/ 30 un (30kg)",
        "quantity_in_base_units": 30000,
        "is_default": True,
    }, headers=headers).json()
    pack_id = pack["id"]

    # 3. Compra 4 fardos a R$ 60,00 cada (6000 centavos)
    payload = {
        "supplier_name": "Salinas do Nordeste",
        "items": [
            {
                "product_id": prod_id,
                "packaging_id": pack_id,
                "packages_count": 4.0,
                "unit_price_cents": 6000,
            }
        ]
    }
    r = client.post("/api/v1/purchases", json=payload, headers=headers)
    assert r.status_code == status.HTTP_201_CREATED
    data = r.json()
    assert data["total_amount_cents"] == 4 * 6000 # 24000 centavos
    item = data["items"][0]
    # 4 fardos * 30.000g = 120.000g
    assert item["quantity_in_base_units"] == 120000
    assert item["packaging_name"] == "Fardo c/ 30 un (30kg)"

    # 4. Saldo no estoque deve ser 120000g
    r_stk = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers)
    assert r_stk.json()["current_stock"] == 120000


def test_create_purchase_as_draft_and_confirm(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Farinha de Trigo 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # 1. Cria compra como DRAFT
    payload = {
        "status": "DRAFT",
        "supplier_name": "Moinho Central",
        "items": [
            {
                "product_id": prod_id,
                "packages_count": 30,
                "unit_price_cents": 420,
            }
        ]
    }
    r_draft = client.post("/api/v1/purchases", json=payload, headers=headers)
    assert r_draft.status_code == status.HTTP_201_CREATED
    draft_data = r_draft.json()
    assert draft_data["status"] == "DRAFT"
    purch_id = draft_data["id"]

    # 2. Saldo de estoque AINDA DEVE SER ZERO
    r_stk1 = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers)
    assert r_stk1.json()["current_stock"] == 0

    # 3. Confirma a compra
    r_conf = client.post(f"/api/v1/purchases/{purch_id}/confirm", headers=headers)
    assert r_conf.status_code == status.HTTP_200_OK
    assert r_conf.json()["status"] == "CONFIRMED"

    # 4. Saldo agora deve ser 30
    r_stk2 = client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers)
    assert r_stk2.json()["current_stock"] == 30


def test_cancel_purchase_with_sufficient_stock(client, authenticated_device, test_session):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Cafe Torrado e Moido 500g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Cria compra confirmada de 40 unidades
    r_purch = client.post("/api/v1/purchases", json={
        "status": "CONFIRMED",
        "items": [{"product_id": prod_id, "packages_count": 40, "unit_price_cents": 1500}]
    }, headers=headers)
    purch_id = r_purch.json()["id"]

    # Saldo e 40
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 40

    # Cancela compra com saldo suficiente
    r_cancel = client.post(f"/api/v1/purchases/{purch_id}/cancel", json={
        "reason": "Fornecedor enviou lote com data de validade curta"
    }, headers=headers)
    assert r_cancel.status_code == status.HTTP_200_OK
    cancel_data = r_cancel.json()
    assert cancel_data["purchase"]["status"] == "CANCELED"
    assert cancel_data["reversal_movements_count"] == 1

    # Saldo agora deve estar zerado (40 - 40 = 0)
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 0

    # Nenhuma linha de movimento foi excluida do banco
    movs = test_session.execute(
        select(InventoryMovement).where(InventoryMovement.source_id == purch_id)
    ).scalars().all()
    assert len(movs) == 2
    types = [m.movement_type for m in movs]
    assert "PURCHASE" in types
    assert "PURCHASE_CANCEL" in types


def test_cancel_purchase_rejected_when_stock_insufficient(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Biscoito Cream Cracker 400g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    # 1. Compra 50 pacotes
    r_purch = client.post("/api/v1/purchases", json={
        "status": "CONFIRMED",
        "items": [{"product_id": prod_id, "packages_count": 50, "unit_price_cents": 450}]
    }, headers=headers)
    purch_id = r_purch.json()["id"]

    # 2. Consome/baixa 30 pacotes (via perda ou ajuste)
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "PRODUCT",
        "product_id": prod_id,
        "adjustment_type": "LOSS",
        "quantity_delta": 30,
        "reason": "Avaria de estoque",
    }, headers=headers)

    # Saldo atual restante = 20
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 20

    # 3. Tenta estornar a compra de 50 pacotes (quando so restam 20 em estoque)
    r_cancel = client.post(f"/api/v1/purchases/{purch_id}/cancel", json={
        "reason": "Tentativa de cancelamento indevido"
    }, headers=headers)

    # DEVE SER REJEITADO com HTTP 409 Conflict e INSUFFICIENT_STOCK
    assert r_cancel.status_code == status.HTTP_409_CONFLICT
    err = r_cancel.json()
    assert err["detail"]["error_code"] == "INSUFFICIENT_STOCK"
    assert err["detail"]["current_stock"] == 20
    assert err["detail"]["required_for_reversal"] == 50

    # Saldo DEVE CONTINUAR 20 (sem gerar estoque negativo)
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 20

    # Compra DEVE PERMANECER CONFIRMED
    r_check = client.get(f"/api/v1/purchases/{purch_id}", headers=headers)
    assert r_check.json()["status"] == "CONFIRMED"


def test_purchase_idempotency_prevents_duplicate_stock(client, authenticated_device):
    _, _, headers = authenticated_device
    import uuid

    prod = client.post("/api/v1/products", json={
        "name": "Extrato de Tomate 340g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()
    prod_id = prod["id"]

    idempotency_key = str(uuid.uuid4())
    headers_with_key = {**headers, "X-Idempotency-Key": idempotency_key}

    payload = {
        "supplier_name": "Conservas do Vale",
        "items": [{"product_id": prod_id, "packages_count": 100, "unit_price_cents": 280}]
    }

    # 1. Envio da primeira requisicao
    r1 = client.post("/api/v1/purchases", json=payload, headers=headers_with_key)
    assert r1.status_code == status.HTTP_201_CREATED
    purch_id_1 = r1.json()["id"]

    # Saldo = 100
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 100

    # 2. Reenvio identico (ex: retry por timeout ou duplo clique)
    r2 = client.post("/api/v1/purchases", json=payload, headers=headers_with_key)
    assert r2.status_code == status.HTTP_201_CREATED
    assert r2.json()["id"] == purch_id_1

    # Saldo CONTINUA 100, NAO PODE VIRAR 200!
    assert client.get(f"/api/v1/inventory/products/{prod_id}/stock", headers=headers).json()["current_stock"] == 100

    # 3. Reenvio com a MESMA chave porem payload adulterado -> HTTP 409
    payload_modified = {
        "supplier_name": "Outro Fornecedor",
        "items": [{"product_id": prod_id, "packages_count": 200, "unit_price_cents": 280}]
    }
    r3 = client.post("/api/v1/purchases", json=payload_modified, headers=headers_with_key)
    assert r3.status_code == status.HTTP_409_CONFLICT
    assert r3.json()["detail"]["error_code"] == "IDEMPOTENCY_PAYLOAD_MISMATCH"


def test_purchase_validation_inactive_product_and_invalid_packaging(client, authenticated_device):
    _, _, headers = authenticated_device

    # Cria dois produtos
    p1 = client.post("/api/v1/products", json={"name": "Prod A", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    p2 = client.post("/api/v1/products", json={"name": "Prod B", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()

    # Cria embalagem no produto B
    pack_b = client.post(f"/api/v1/products/{p2['id']}/packagings", json={"name": "Caixa B", "quantity_in_base_units": 10}, headers=headers).json()

    # Tenta usar embalagem de B no produto A -> deve falhar com 400
    r_bad_pkg = client.post("/api/v1/purchases", json={
        "items": [{"product_id": p1["id"], "packaging_id": pack_b["id"], "packages_count": 5, "unit_price_cents": 100}]
    }, headers=headers)
    assert r_bad_pkg.status_code == status.HTTP_400_BAD_REQUEST

    # Inativa produto A
    client.delete(f"/api/v1/products/{p1['id']}", headers=headers)

    # Tenta comprar produto inativo -> deve falhar com 400
    r_inact = client.post("/api/v1/purchases", json={
        "items": [{"product_id": p1["id"], "packages_count": 5, "unit_price_cents": 100}]
    }, headers=headers)
    assert r_inact.status_code == status.HTTP_400_BAD_REQUEST


def test_purchase_listing_and_detail(client, authenticated_device):
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={"name": "Prod List Test", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()

    # Cria 2 compras
    p1 = client.post("/api/v1/purchases", json={
        "supplier_name": "Fornecedor Alfa",
        "notes": "Lote Alfa",
        "items": [{"product_id": prod["id"], "packages_count": 10, "unit_price_cents": 200}]
    }, headers=headers).json()

    p2 = client.post("/api/v1/purchases", json={
        "supplier_name": "Fornecedor Beta",
        "notes": "Lote Beta",
        "items": [{"product_id": prod["id"], "packages_count": 20, "unit_price_cents": 300}]
    }, headers=headers).json()

    # Buscar por ID
    r_det = client.get(f"/api/v1/purchases/{p1['id']}", headers=headers)
    assert r_det.status_code == status.HTTP_200_OK
    assert r_det.json()["supplier_name"] == "Fornecedor Alfa"

    # Filtrar por busca
    r_search = client.get("/api/v1/purchases?search=Beta", headers=headers)
    assert r_search.status_code == status.HTTP_200_OK
    assert len(r_search.json()["items"]) == 1
    assert r_search.json()["items"][0]["supplier_name"] == "Fornecedor Beta"


def test_draft_purchase_does_not_update_product_cost_price_until_confirmed(client, authenticated_device):
    """Testa que salvar rascunho de compra nao altera o preco de custo de referencia do produto ate ser confirmada."""
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Fubá Mimoso 500g",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
        "cost_price_cents": 250,
    }, headers=headers).json()
    prod_id = prod["id"]

    # 1. Cria compra em rascunho (DRAFT) com preco unitario de 450 centavos
    r_draft = client.post("/api/v1/purchases", json={
        "status": "DRAFT",
        "supplier_name": "Moinho Sul",
        "items": [{"product_id": prod_id, "packages_count": 20, "unit_price_cents": 450}],
    }, headers=headers)
    assert r_draft.status_code == status.HTTP_201_CREATED
    purch_id = r_draft.json()["id"]

    # 2. Preco de custo do produto DEVE CONTINUAR 250
    p_check1 = client.get(f"/api/v1/products/{prod_id}", headers=headers).json()
    assert p_check1["cost_price_cents"] == 250

    # 3. Confirma a compra
    r_conf = client.post(f"/api/v1/purchases/{purch_id}/confirm", headers=headers)
    assert r_conf.status_code == status.HTTP_200_OK

    # 4. Agora sim o preco de custo do produto deve estar atualizado para 450
    p_check2 = client.get(f"/api/v1/products/{prod_id}", headers=headers).json()
    assert p_check2["cost_price_cents"] == 450


def test_purchase_search_by_purchase_number(client, authenticated_device):
    """Testa que a busca de compras localiza compras pelo seu numero sequencial (#numero)."""
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Item Busca Numero",
        "category": "ALIMENTACAO",
        "base_unit": "UNIT",
    }, headers=headers).json()

    p1 = client.post("/api/v1/purchases", json={
        "supplier_name": "Fornecedor X",
        "items": [{"product_id": prod["id"], "packages_count": 5, "unit_price_cents": 100}],
    }, headers=headers).json()
    num1 = p1["purchase_number"]

    # Busca por numero exato
    r_search_num = client.get(f"/api/v1/purchases?search={num1}", headers=headers)
    assert r_search_num.status_code == status.HTTP_200_OK
    found = [it for it in r_search_num.json()["items"] if it["id"] == p1["id"]]
    assert len(found) == 1

    # Busca por prefixo com hash (#1)
    r_search_hash = client.get(f"/api/v1/purchases?search=%23{num1}", headers=headers)
    assert r_search_hash.status_code == status.HTTP_200_OK
    found_hash = [it for it in r_search_hash.json()["items"] if it["id"] == p1["id"]]
    assert len(found_hash) == 1


def test_create_purchase_rejects_fractional_units_without_packaging(client, authenticated_device):
    """Testa rejeicao de compra com quantidade fracionada em produto com unidade contavel UNIT sem embalagem."""
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Vassoura de Piaçava",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers).json()

    # Tenta comprar 2.5 vassouras avulsas
    r = client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod["id"], "packages_count": 2.5, "unit_price_cents": 1200}],
    }, headers=headers)
    assert r.status_code == status.HTTP_400_BAD_REQUEST
    assert "numero inteiro" in r.json()["detail"]


def test_cancel_purchase_idempotency(client, authenticated_device):
    """Testa que o cancelamento de compra suporta X-Idempotency-Key com replay seguro."""
    _, _, headers = authenticated_device
    import uuid

    prod = client.post("/api/v1/products", json={
        "name": "Sabao em Po 1kg",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers).json()

    purch = client.post("/api/v1/purchases", json={
        "items": [{"product_id": prod["id"], "packages_count": 30, "unit_price_cents": 800}],
    }, headers=headers).json()
    purch_id = purch["id"]

    idemp_key = str(uuid.uuid4())
    headers_key = {**headers, "X-Idempotency-Key": idemp_key}

    # 1. Primeira solicitacao de cancelamento
    r1 = client.post(
        f"/api/v1/purchases/{purch_id}/cancel",
        json={"reason": "Cancelamento inicial idempotente"},
        headers=headers_key,
    )
    assert r1.status_code == status.HTTP_200_OK
    assert r1.json()["purchase"]["status"] == "CANCELED"

    # 2. Reenvio identico com a mesma chave de idempotencia
    r2 = client.post(
        f"/api/v1/purchases/{purch_id}/cancel",
        json={"reason": "Cancelamento inicial idempotente"},
        headers=headers_key,
    )
    assert r2.status_code == status.HTTP_200_OK
    assert r2.json()["purchase"]["id"] == purch_id
    assert r2.json()["purchase"]["status"] == "CANCELED"

    # Saldo deve ser 0 (nao pode duplicar estorno para -30)
    stk = client.get(f"/api/v1/inventory/products/{prod['id']}/stock", headers=headers).json()
    assert stk["current_stock"] == 0

