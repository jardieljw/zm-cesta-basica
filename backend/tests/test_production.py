import uuid
import threading
import datetime
import pytest
from fastapi import status, HTTPException

from app.models.movements import InventoryMovement
from app.schemas.production import DisassemblyRequest, DisassemblyTriageItem
from app.services.production import disassemble_production_batch


def test_standard_basket_assembly_success(client, authenticated_device):
    """
    Testa a montagem completa de cestas padrao a partir da receita ativa:
    - Consumo correto e proporcional de todos os ingredientes na unidade base
    - Entrada atômica de cestas acabadas no livro-razao
    - Apuracao do CMPM e congelamento imutavel do custo unitario do lote em centavos
    """
    _, _, headers = authenticated_device

    # 1. Cadastra dois produtos (Arroz 5kg e Feijao 1kg)
    p_arroz = client.post("/api/v1/products", json={
        "name": "Arroz Cristal 5kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "cost_price_cents": 2500, # R$ 25,00 por 5000g -> 0,50 centavos/g = 5000 microcentavos/g
    }, headers=headers).json()

    p_feijao = client.post("/api/v1/products", json={
        "name": "Feijao Carioca 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "cost_price_cents": 800,  # R$ 8,00 por 1000g -> 0,80 centavos/g = 8000 microcentavos/g
    }, headers=headers).json()

    # 2. Compra estoque de insumos
    client.post("/api/v1/purchases", json={
        "items": [
            {"product_id": p_arroz["id"], "packages_count": 50000, "unit_price_cents": 250}, # 50.000g
            {"product_id": p_feijao["id"], "packages_count": 20000, "unit_price_cents": 160}, # 20.000g
        ]
    }, headers=headers)

    # 3. Cria tipo de cesta e receita ativa (5000g de arroz e 2000g de feijao por cesta)
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_PADRAO_TEST",
        "name": "Cesta Familia Padrao",
        "default_price_cents": 15000,
    }, headers=headers).json()
    bt_id = bt["id"]

    client.post(f"/api/v1/basket-types/{bt_id}/recipes", json={
        "notes": "Receita V1",
        "items": [
            {"product_id": p_arroz["id"], "quantity_in_base_units": 5000, "section": "ALIMENTACAO", "is_required": True},
            {"product_id": p_feijao["id"], "quantity_in_base_units": 2000, "section": "ALIMENTACAO", "is_required": True},
        ]
    }, headers=headers)

    # 4. Executa montagem de 4 cestas
    r_batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt_id,
        "quantity_produced": 4,
        "notes": "Producao turno da manha",
    }, headers=headers)
    assert r_batch.status_code == status.HTTP_201_CREATED
    batch_data = r_batch.json()

    assert batch_data["batch_number"] >= 1
    assert batch_data["quantity_produced"] == 4
    assert batch_data["status"] == "CONFIRMED"
    assert batch_data["is_custom"] is False
    assert batch_data["basket_type_name"] == "Cesta Familia Padrao"
    assert len(batch_data["items"]) == 2

    # Verifica custos calculados:
    # Arroz consumido: 4 * 5000g = 20000g
    # Feijao consumido: 4 * 2000g = 8000g
    item_arroz = next(it for it in batch_data["items"] if it["product_id"] == p_arroz["id"])
    item_feijao = next(it for it in batch_data["items"] if it["product_id"] == p_feijao["id"])
    assert item_arroz["quantity_consumed_base_units"] == 20000
    assert item_feijao["quantity_consumed_base_units"] == 8000
    assert batch_data["unit_cost_cents"] > 0
    assert batch_data["total_cost_cents"] == batch_data["unit_cost_cents"] * 4

    # 5. Verifica saldos de estoque apos a montagem
    stk_arroz = client.get(f"/api/v1/inventory/products/{p_arroz['id']}/stock", headers=headers).json()["current_stock"]
    stk_feijao = client.get(f"/api/v1/inventory/products/{p_feijao['id']}/stock", headers=headers).json()["current_stock"]
    assert stk_arroz == 50000 - 20000 # 30.000g
    assert stk_feijao == 20000 - 8000 # 12.000g

    # Saldo de cestas acabadas deve ser 4
    stk_cesta = client.get(f"/api/v1/inventory/baskets/{bt_id}/stock", headers=headers).json()["current_stock"]
    assert stk_cesta == 4


def test_standard_basket_assembly_rejects_on_insufficient_stock(client, authenticated_device):
    """
    Testa que a montagem de cestas e rejeitada atomicamente com HTTP 409 Conflict
    quando qualquer ingrediente nao possui saldo suficiente em estoque,
    apresentando os itens em falta e sem gerar movimentacoes orfas no livro-razao.
    """
    _, _, headers = authenticated_device

    p1 = client.post("/api/v1/products", json={"name": "Farinha 1kg", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()
    p2 = client.post("/api/v1/products", json={"name": "Acucar 1kg", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()

    # Compra apenas 1500g de farinha e 10000g de acucar
    client.post("/api/v1/purchases", json={
        "items": [
            {"product_id": p1["id"], "packages_count": 1500, "unit_price_cents": 100},
            {"product_id": p2["id"], "packages_count": 10000, "unit_price_cents": 100},
        ]
    }, headers=headers)

    # Cria cesta que precisa de 1000g de cada por unidade
    bt = client.post("/api/v1/basket-types", json={"code": "BT_FALTA_TEST", "name": "Cesta Falta Teste"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": p1["id"], "quantity_in_base_units": 1000, "section": "ALIMENTACAO"},
            {"product_id": p2["id"], "quantity_in_base_units": 1000, "section": "ALIMENTACAO"},
        ]
    }, headers=headers)

    # Tenta montar 2 cestas (precisaria de 2000g de farinha, mas so tem 1500g)
    r = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
    }, headers=headers)

    assert r.status_code == status.HTTP_409_CONFLICT
    err = r.json()
    assert err["detail"]["error_code"] == "INSUFFICIENT_STOCK"
    missing = err["detail"]["missing_items"]
    assert len(missing) == 1
    assert missing[0]["product_id"] == p1["id"]
    assert missing[0]["current_stock"] == 1500
    assert missing[0]["required_quantity"] == 2000
    assert missing[0]["missing_quantity"] == 500

    # Garante que nenhum saldo foi alterado
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 1500
    assert client.get(f"/api/v1/inventory/products/{p2['id']}/stock", headers=headers).json()["current_stock"] == 10000
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 0


def test_standard_basket_assembly_rejects_inactive_basket_or_missing_recipe(client, authenticated_device):
    """Testa validacoes de tipo de cesta inativo ou sem receita ativa cadastrada."""
    _, _, headers = authenticated_device

    # Cesta sem receita
    bt = client.post("/api/v1/basket-types", json={"code": "BT_NO_RECIPE", "name": "Cesta Sem Receita"}, headers=headers).json()
    r1 = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 1}, headers=headers)
    assert r1.status_code == status.HTTP_400_BAD_REQUEST

    # Cesta inativa
    client.delete(f"/api/v1/basket-types/{bt['id']}", headers=headers)
    r2 = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 1}, headers=headers)
    assert r2.status_code == status.HTTP_400_BAD_REQUEST


def test_custom_basket_assembly_with_snapshot_immutability(client, authenticated_device):
    """
    Testa a montagem de cestas personalizadas:
    - Gravacao de snapshot imutavel da composicao real em production_batch_items
    - Nao contamina a receita padrao nem o estoque de cestas padrao
    - Rastreamento unívoco via production_batch_id no livro-razao
    """
    _, _, headers = authenticated_device

    p_arroz = client.post("/api/v1/products", json={"name": "Arroz Custom", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()
    p_leite = client.post("/api/v1/products", json={"name": "Leite em Po", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()
    p_chocolate = client.post("/api/v1/products", json={"name": "Achocolatado", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()

    # Compra insumos
    client.post("/api/v1/purchases", json={
        "items": [
            {"product_id": p_arroz["id"], "packages_count": 20000, "unit_price_cents": 100},
            {"product_id": p_leite["id"], "packages_count": 5000, "unit_price_cents": 150},
            {"product_id": p_chocolate["id"], "packages_count": 5000, "unit_price_cents": 120},
        ]
    }, headers=headers)

    bt = client.post("/api/v1/basket-types", json={
        "code": "BT_BASE_CUSTOM",
        "name": "Cesta Base para Personalizacao",
        "allows_customization": True,
    }, headers=headers).json()

    # Monta lote personalizado de 2 cestas com leite e chocolate (sem arroz)
    custom_desc = "Montagem sob encomenda para Dona Maria - Especial Criancas"
    r_custom = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
        "is_custom": True,
        "custom_description": custom_desc,
        "custom_items": [
            {"product_id": p_leite["id"], "quantity_in_base_units": 800, "section": "ALIMENTACAO"},
            {"product_id": p_chocolate["id"], "quantity_in_base_units": 400, "section": "ALIMENTACAO"},
        ],
        "notes": "Sem arroz por solicitacao do cliente",
    }, headers=headers)

    assert r_custom.status_code == status.HTTP_201_CREATED
    batch = r_custom.json()
    assert batch["is_custom"] is True
    assert batch["custom_description"] == custom_desc
    assert batch["quantity_produced"] == 2
    assert batch["recipe_version_id"] is None
    assert len(batch["items"]) == 2

    # Verifica consumo no estoque de insumos
    assert client.get(f"/api/v1/inventory/products/{p_leite['id']}/stock", headers=headers).json()["current_stock"] == 5000 - 1600 # 3400g
    assert client.get(f"/api/v1/inventory/products/{p_chocolate['id']}/stock", headers=headers).json()["current_stock"] == 5000 - 800  # 4200g
    assert client.get(f"/api/v1/inventory/products/{p_arroz['id']}/stock", headers=headers).json()["current_stock"] == 20000        # Intacto

    # Saldo de cestas PADRAO nao pode ter sido alterado
    stk_padrao = client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"]
    assert stk_padrao == 0

    # Saldo do LOTE PERSONALIZADO deve ser 2
    b_det = client.get(f"/api/v1/production/batches/{batch['id']}", headers=headers).json()
    assert b_det["current_batch_stock"] == 2


def test_microcents_cmpm_fractional_precision_and_cost_freezing(client, authenticated_device):
    """
    Testa a precisao em microcentavos do CMPM para insumos fracionarios (gramas),
    o arredondamento bancario half-even e o congelamento imutavel do custo unitario
    historico do lote de producao.
    """
    _, _, headers = authenticated_device

    prod = client.post("/api/v1/products", json={
        "name": "Arroz Agulhinha a Granel",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    p_id = prod["id"]

    # Cria embalagem comercial: Saco de 5kg (5000g)
    pkg = client.post(f"/api/v1/products/{p_id}/packagings", json={
        "name": "Saco 5kg",
        "quantity_in_base_units": 5000,
        "is_default": True,
    }, headers=headers).json()
    pkg_id = pkg["id"]

    # Compra 1: 1 saco de 5.000g por R$ 27,50 (2750 centavos) -> R$ 0,0055/g = 5500 microcentavos/g
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": p_id, "packaging_id": pkg_id, "packages_count": 1, "unit_price_cents": 2750}]
    }, headers=headers)

    p_check1 = client.get(f"/api/v1/products/{p_id}", headers=headers).json()
    assert p_check1["cost_price_microcents"] == 5500

    # Compra 2: 2 sacos (10.000g) a R$ 30,00 cada (total 6000 centavos) -> R$ 0,0060/g = 6000 microcentavos/g
    # CMPM esperado = (5000 * 5500 + 10000 * 6000) / 15000 = (27500000 + 60000000) / 15000 = 87500000 / 15000 = 5833 microcentavos
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": p_id, "packaging_id": pkg_id, "packages_count": 2, "unit_price_cents": 3000}]
    }, headers=headers)

    p_check2 = client.get(f"/api/v1/products/{p_id}", headers=headers).json()
    assert p_check2["cost_price_microcents"] == 5833

    # Monta lote consumindo 3.000g de arroz por cesta
    # Custo do arroz por cesta = round(3000 * 5833 / 10000) = round(1749.9) = 1750 centavos (R$ 17,50)
    bt = client.post("/api/v1/basket-types", json={"code": "BT_CMPM_TEST", "name": "Cesta Teste CMPM"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p_id, "quantity_in_base_units": 3000, "section": "ALIMENTACAO"}]
    }, headers=headers)

    r_batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
    }, headers=headers)
    batch = r_batch.json()
    assert batch["unit_cost_cents"] == 1750
    assert batch["total_cost_cents"] == 3500

    # Compra subsequente com preco muito elevado nao pode alterar o custo do lote historico ja gravado
    client.post("/api/v1/purchases", json={
        "items": [{"product_id": p_id, "packages_count": 5000, "unit_price_cents": 25000}]
    }, headers=headers)

    batch_recheck = client.get(f"/api/v1/production/batches/{batch['id']}", headers=headers).json()
    assert batch_recheck["unit_cost_cents"] == 1750
    assert batch_recheck["total_cost_cents"] == 3500


def test_disassembly_with_triage_intact_and_loss(client, authenticated_device):
    """
    Testa a desmontagem de lote com triagem física de insumos:
    - Insumos intactos retornam ao armazém (STORE)
    - Insumos avariados/violados são lançados como perda contábil (ASSEMBLY_LOSS) sem retorno fictício ao estoque
    - Cestas acabadas sofrem baixa de estoque na mesma transação
    """
    _, _, headers = authenticated_device

    p_oleo = client.post("/api/v1/products", json={"name": "Oleo Triagem", "category": "ALIMENTACAO", "base_unit": "ML"}, headers=headers).json()
    p_sal = client.post("/api/v1/products", json={"name": "Sal Triagem", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()

    # Compra inicial
    client.post("/api/v1/purchases", json={
        "items": [
            {"product_id": p_oleo["id"], "packages_count": 9000, "unit_price_cents": 500},
            {"product_id": p_sal["id"], "packages_count": 5000, "unit_price_cents": 200},
        ]
    }, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_TRIAGEM", "name": "Cesta Triagem"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": p_oleo["id"], "quantity_in_base_units": 900, "section": "ALIMENTACAO"},
            {"product_id": p_sal["id"], "quantity_in_base_units": 1000, "section": "ALIMENTACAO"},
        ]
    }, headers=headers)

    # Produz 4 cestas
    r_batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 4,
    }, headers=headers)
    batch_id = r_batch.json()["id"]

    # Saldo pos-producao:
    # Oleo restante = 9000 - 3600 = 5400ml
    # Sal restante = 5000 - 4000 = 1000g
    # Cestas prontas = 4

    # Desmonta 2 cestas com triagem:
    # Consumo correspondente a 2 cestas: 1800ml de oleo e 2000g de sal
    # Triagem:
    # Oleo: 900ml intacto, 900ml avariado (garrafa furada)
    # Sal: 2000g 100% intacto
    r_dis = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmontagem com avaria identificada na carga",
        "triage_items": [
            {"product_id": p_oleo["id"], "intact_quantity": 900, "loss_quantity": 900, "loss_reason": "Garrafa furada no transporte"},
            {"product_id": p_sal["id"], "intact_quantity": 2000, "loss_quantity": 0},
        ]
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK

    # Verificacao de estoque:
    # Oleo deve ter retornado apenas os 900ml intactos: 5400 + 900 = 6300ml (os 900ml avariados NAO retornaram)
    assert client.get(f"/api/v1/inventory/products/{p_oleo['id']}/stock", headers=headers).json()["current_stock"] == 6300
    # Sal deve ter retornado 2000g intactos: 1000 + 2000 = 3000g
    assert client.get(f"/api/v1/inventory/products/{p_sal['id']}/stock", headers=headers).json()["current_stock"] == 3000

    # Cestas acabadas restantes em estoque: 4 - 2 = 2
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 2


def test_disassembly_rejected_when_finished_baskets_already_consumed_or_sold(client, authenticated_device):
    """
    Testa que nao e permitido desmontar mais cestas do que o saldo atual existente
    de produtos acabados em estoque (evita desmontar cestas ja vendidas ou expedidas).
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Vendido", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 10, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_VENDIDO", "name": "Cesta Vendida"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Monta 5 cestas
    batch = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 5}, headers=headers).json()

    # Simula saida/baixa de 4 cestas (resta apenas 1 em estoque)
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "BASKET",
        "basket_type_id": bt["id"],
        "adjustment_type": "OUT",
        "quantity_delta": 4,
        "reason": "Expedicao de teste",
    }, headers=headers)
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 1

    # Tenta desmontar 3 cestas do lote quando so existe 1 em estoque
    r_dis = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 3,
        "reason": "Tentativa indevida de desmontar cestas inexistentes",
    }, headers=headers)

    assert r_dis.status_code == status.HTTP_409_CONFLICT
    err = r_dis.json()
    assert err["detail"]["error_code"] == "INSUFFICIENT_STOCK"
    assert err["detail"]["current_stock"] == 1
    assert err["detail"]["requested_disassembly"] == 3


def test_cancel_batch_estorno_full_return(client, authenticated_device):
    """
    Testa o estorno completo de lote de producao:
    - Retorno de 100% dos insumos ao estoque
    - Atualizacao do status do lote para DISASSEMBLED
    - Rejeicao de estorno duplicado
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Estorno", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_ESTORNO", "name": "Cesta Estorno"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Monta lote de 3 cestas (consome 6 unidades)
    batch = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 3}, headers=headers).json()
    batch_id = batch["id"]

    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 14
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 3

    # Cancela / estorna o lote
    r_cancel = client.post(f"/api/v1/production/batches/{batch_id}/cancel", json={
        "reason": "Montagem realizada com lote errado",
    }, headers=headers)
    assert r_cancel.status_code == status.HTTP_200_OK

    # Saldo de insumos voltou integralmente para 20
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 20
    # Saldo de cestas voltou para 0
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 0

    # Lote deve estar com status DISASSEMBLED
    b_check = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_check["status"] == "DISASSEMBLED"
    assert b_check["cancellation_reason"] == "Montagem realizada com lote errado"

    # Segunda tentativa de estorno deve falhar com 400
    r_cancel2 = client.post(f"/api/v1/production/batches/{batch_id}/cancel", json={
        "reason": "Tentativa repetida",
    }, headers=headers)
    assert r_cancel2.status_code == status.HTTP_400_BAD_REQUEST


def test_production_idempotency_prevents_duplicate_batches(client, authenticated_device):
    """Testa que a chave X-Idempotency-Key impede execucao duplicada de montagem."""
    _, _, headers = authenticated_device
    idemp_key = str(uuid.uuid4())
    headers_with_key = {**headers, "X-Idempotency-Key": idemp_key}

    p = client.post("/api/v1/products", json={"name": "Prod Idemp", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_IDEMP", "name": "Cesta Idemp"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    payload = {"basket_type_id": bt["id"], "quantity_produced": 2}

    # 1. Primeira requisicao
    r1 = client.post("/api/v1/production/batches", json=payload, headers=headers_with_key)
    assert r1.status_code == status.HTTP_201_CREATED
    b1_id = r1.json()["id"]

    # 2. Segunda requisicao com mesma chave
    r2 = client.post("/api/v1/production/batches", json=payload, headers=headers_with_key)
    assert r2.status_code == status.HTTP_201_CREATED
    assert r2.json()["id"] == b1_id

    # Saldo de insumo deve ter sido consumido APENAS UMA VEZ (20 - 4 = 16)
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 16
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 2


def test_production_preview_endpoint(client, authenticated_device):
    """Testa o endpoint de simulacao pre-flight /production/preview sem efeitos colaterais no banco."""
    _, _, headers = authenticated_device

    p1 = client.post("/api/v1/products", json={"name": "Prev Arroz", "category": "ALIMENTACAO", "base_unit": "UNIT", "cost_price_cents": 500}, headers=headers).json()
    p2 = client.post("/api/v1/products", json={"name": "Prev Feijao", "category": "ALIMENTACAO", "base_unit": "UNIT", "cost_price_cents": 800}, headers=headers).json()

    # Compra 2 unidades de arroz e 2 unidades de feijao
    client.post("/api/v1/purchases", json={
        "items": [
            {"product_id": p1["id"], "packages_count": 2, "unit_price_cents": 500},
            {"product_id": p2["id"], "packages_count": 2, "unit_price_cents": 800},
        ]
    }, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_PREV", "name": "Cesta Preview"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": p1["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"},
            {"product_id": p2["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"},
        ]
    }, headers=headers)

    # Preview de 2 cestas (suficiente)
    r_prev_ok = client.post("/api/v1/production/preview", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
    }, headers=headers)
    assert r_prev_ok.status_code == status.HTTP_200_OK
    data_ok = r_prev_ok.json()
    assert data_ok["can_produce"] is True
    assert len(data_ok["missing_items"]) == 0
    assert data_ok["estimated_unit_cost_cents"] == 1300 # 500 + 800

    # Preview de 3 cestas (insuficiente)
    r_prev_fail = client.post("/api/v1/production/preview", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 3,
    }, headers=headers)
    assert r_prev_fail.status_code == status.HTTP_200_OK
    data_fail = r_prev_fail.json()
    assert data_fail["can_produce"] is False
    assert len(data_fail["missing_items"]) == 2

    # Verifica que nenhum saldo de estoque foi alterado
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 2
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 0


def test_concurrent_production_prevents_negative_ingredient_stock(client, authenticated_device):
    """
    Testa que chamadas concorrentes sob BEGIN IMMEDIATE concorrendo pelos ultimos insumos
    impedem que o estoque fique negativo e serializam atomicamente as mutacoes.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Concorrencia Montagem", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    p_id = p["id"]

    # Compra inicial de apenas 10 unidades
    client.post("/api/v1/purchases", json={"items": [{"product_id": p_id, "packages_count": 10, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CONC", "name": "Cesta Concorrencia"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p_id, "quantity_in_base_units": 10, "section": "ALIMENTACAO"}]
    }, headers=headers)

    results = []
    errors = []

    def attempt_assembly():
        try:
            # Cada thread tenta montar 1 cesta (que consome todas as 10 unidades)
            resp = client.post(
                "/api/v1/production/batches",
                json={"basket_type_id": bt["id"], "quantity_produced": 1},
                headers=headers,
            )
            results.append(resp.status_code)
        except Exception as e:
            errors.append(e)

    # 4 threads disputam simultaneamente os insumos de 1 lote
    threads = [threading.Thread(target=attempt_assembly) for _ in range(4)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(errors) == 0
    assert len(results) == 4

    # Exatamente UMA requisicao deve ser confirmada (201) e as outras tres devem ser rejeitadas com 409
    successes = results.count(status.HTTP_201_CREATED)
    conflicts = results.count(status.HTTP_409_CONFLICT)
    assert successes == 1
    assert conflicts == 3

    # Saldo de insumo deve ser exatamente ZERO, jamais negativo
    final_stk = client.get(f"/api/v1/inventory/products/{p_id}/stock", headers=headers).json()["current_stock"]
    assert final_stk == 0

    # Saldo de cestas deve ser exatamente 1
    final_basket_stk = client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"]
    assert final_basket_stk == 1


def test_production_list_and_filters(client, authenticated_device):
    """Testa listagem paginada e filtros de ordens de montagem."""
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Filtro", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 50, "unit_price_cents": 100}]}, headers=headers)

    bt1 = client.post("/api/v1/basket-types", json={"code": "BT_F1", "name": "Cesta Alfa"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt1['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"}]
    }, headers=headers)

    bt2 = client.post("/api/v1/basket-types", json={"code": "BT_F2", "name": "Cesta Beta", "allows_customization": True}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt2['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Cria 1 lote padrao para bt1
    client.post("/api/v1/production/batches", json={"basket_type_id": bt1["id"], "quantity_produced": 2, "notes": "Ordem Alfa"}, headers=headers)

    # Cria 1 lote personalizado para bt2
    client.post("/api/v1/production/batches", json={
        "basket_type_id": bt2["id"],
        "quantity_produced": 1,
        "is_custom": True,
        "custom_description": "Personalizada Especial",
        "custom_items": [{"product_id": p["id"], "quantity_in_base_units": 3, "section": "ALIMENTACAO"}],
    }, headers=headers)

    # 1. Listar todos
    r_all = client.get("/api/v1/production/batches", headers=headers)
    assert r_all.status_code == status.HTTP_200_OK
    assert r_all.json()["total"] == 2

    # 2. Filtrar apenas personalizadas
    r_custom = client.get("/api/v1/production/batches?is_custom=true", headers=headers)
    assert r_custom.status_code == status.HTTP_200_OK
    assert len(r_custom.json()["items"]) == 1
    assert r_custom.json()["items"][0]["custom_description"] == "Personalizada Especial"

    # 3. Filtrar por busca
    r_search = client.get("/api/v1/production/batches?search=Alfa", headers=headers)
    assert r_search.status_code == status.HTTP_200_OK
    assert len(r_search.json()["items"]) == 1
    assert r_search.json()["items"][0]["basket_type_name"] == "Cesta Alfa"


def test_consecutive_partial_disassembly_and_cumulative_limit(client, authenticated_device):
    """
    Testa desmontagens parciais consecutivas e cumulativas:
    - Rastreamento exato de quantity_disassembled e current_batch_stock
    - Bloqueio imediato (400) de desmontagem que exceda o saldo restante cumulativo do lote
    - Transicao do status para DISASSEMBLED ao zerar o saldo cumulativo
    - Bloqueio de novas desmontagens apos o lote estar integralmente desmontado
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Desmontagem Cumulativa", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 50, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CUMULATIVE", "name": "Cesta Cumulativa"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Produz lote de 10 cestas (consome 20 unidades de p)
    r_create = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 10,
    }, headers=headers)
    assert r_create.status_code == status.HTTP_201_CREATED
    batch_id = r_create.json()["id"]

    # Estado inicial do lote
    b_init = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_init["quantity_produced"] == 10
    assert b_init["quantity_disassembled"] == 0
    assert b_init["current_batch_stock"] == 10
    assert b_init["status"] == "CONFIRMED"

    # 1. Primeira desmontagem parcial: 3 cestas
    r_d1 = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 3,
        "reason": "Desmontagem parcial 1",
    }, headers=headers)
    assert r_d1.status_code == status.HTTP_200_OK
    assert r_d1.json()["quantity_disassembled"] == 3
    assert r_d1.json()["status"] == "CONFIRMED"

    b_after_1 = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_after_1["quantity_disassembled"] == 3
    assert b_after_1["current_batch_stock"] == 7
    assert b_after_1["status"] == "CONFIRMED"

    # 2. Segunda desmontagem parcial: 4 cestas (acumulando 7 desmontadas)
    r_d2 = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 4,
        "reason": "Desmontagem parcial 2",
    }, headers=headers)
    assert r_d2.status_code == status.HTTP_200_OK
    assert r_d2.json()["quantity_disassembled"] == 4
    assert r_d2.json()["status"] == "CONFIRMED"

    b_after_2 = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_after_2["quantity_disassembled"] == 7
    assert b_after_2["current_batch_stock"] == 3
    assert b_after_2["status"] == "CONFIRMED"

    # 3. Tentativa de sobredesmontagem: tentar desmontar 4 cestas quando restam apenas 3 no lote
    r_overflow = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 4,
        "reason": "Tentativa excedente",
    }, headers=headers)
    assert r_overflow.status_code == status.HTTP_400_BAD_REQUEST
    assert "Saldo restante" in r_overflow.json()["detail"] or "invalida" in r_overflow.json()["detail"]

    # 4. Terceira desmontagem: desmonta exatamente as 3 restantes -> zera o lote
    r_d3 = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 3,
        "reason": "Desmontagem final",
    }, headers=headers)
    assert r_d3.status_code == status.HTTP_200_OK
    assert r_d3.json()["quantity_disassembled"] == 3
    assert r_d3.json()["status"] == "DISASSEMBLED"

    b_final = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_final["quantity_disassembled"] == 10
    assert b_final["current_batch_stock"] == 0
    assert b_final["status"] == "DISASSEMBLED"
    assert b_final["cancellation_reason"] == "Desmontagem final"

    # 5. Tentativa subsequente deve ser rejeitada porque status ja e DISASSEMBLED
    r_after_final = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Tentativa em lote ja desmontado",
    }, headers=headers)
    assert r_after_final.status_code == status.HTTP_400_BAD_REQUEST


def test_cancel_after_partial_disassembly(client, authenticated_device):
    """
    Testa que o endpoint /cancel desmonta apenas o saldo restante do lote quando
    houve desmontagem parcial previa, evitando erro 409 de estoque insuficiente
    e retornando a quantidade real desmontada.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Cancel Parcial", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 30, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CANCEL_PARCIAL", "name": "Cesta Cancel Parcial"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Produz lote de 6 cestas (consome 12 unidades)
    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 6,
    }, headers=headers).json()
    batch_id = batch["id"]

    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 18
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 6

    # 1. Desmonta parcialmente 2 cestas
    r_dis = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmontagem inicial parcial",
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK

    # Estoque de insumo deve ter voltado 4 unidades (18 + 4 = 22)
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 22
    # Estoque de cestas prontas deve ser 4
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 4

    # 2. Executa /cancel: deve estornar as 4 cestas restantes sem conflito 409
    r_cancel = client.post(f"/api/v1/production/batches/{batch_id}/cancel", json={
        "reason": "Estorno do saldo restante",
    }, headers=headers)
    assert r_cancel.status_code == status.HTTP_200_OK
    cancel_data = r_cancel.json()
    assert cancel_data["quantity_disassembled"] == 4
    assert cancel_data["status"] == "DISASSEMBLED"

    # Saldo de insumo deve ter voltado integralmente para 30 (22 + 8)
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 30
    # Saldo de cestas acabadas deve ser 0
    assert client.get(f"/api/v1/inventory/baskets/{bt['id']}/stock", headers=headers).json()["current_stock"] == 0

    # Lote no backend deve estar DISASSEMBLED com 6 desmontadas cumulativamente
    b_check = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_check["status"] == "DISASSEMBLED"
    assert b_check["quantity_disassembled"] == 6
    assert b_check["current_batch_stock"] == 0


def test_assembly_and_disassembly_with_flutter_payload_aliases(client, authenticated_device):
    """
    Testa compatibilidade com os aliases enviados pelo Flutter:
    - Montagem personalizada aceita 'quantity_base_units' via AliasChoices
    - Triagem de desmontagem aceita 'quantity_intact_base_units' e 'quantity_loss_base_units' via AliasChoices
    - Campo is_direct_sale e recebido e persistido corretamente
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Aliases Flutter", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_ALIASES", "name": "Cesta Aliases", "allows_customization": True}, headers=headers).json()

    # 1. Preview com quantity_base_units e is_direct_sale
    r_prev = client.post("/api/v1/production/preview", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
        "is_custom": True,
        "is_direct_sale": True,
        "custom_description": "Preview Aliases",
        "custom_items": [
            {"product_id": p["id"], "quantity_base_units": 3, "section": "ALIMENTACAO"}
        ],
    }, headers=headers)
    assert r_prev.status_code == status.HTTP_200_OK
    assert r_prev.json()["can_produce"] is True

    # 2. Montagem de cesta personalizada enviando 'quantity_base_units' e 'is_direct_sale': True
    r_batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
        "is_custom": True,
        "is_direct_sale": True,
        "custom_description": "Personalizada Aliases",
        "custom_items": [
            {"product_id": p["id"], "quantity_base_units": 3, "section": "ALIMENTACAO"}
        ],
    }, headers=headers)
    assert r_batch.status_code == status.HTTP_201_CREATED
    batch_data = r_batch.json()
    assert batch_data["is_direct_sale"] is True
    assert batch_data["items"][0]["quantity_consumed_base_units"] == 6

    # 3. Desmontagem enviando 'quantity_intact_base_units' e 'quantity_loss_base_units'
    r_dis = client.post(f"/api/v1/production/batches/{batch_data['id']}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Teste aliases desmontagem",
        "triage_items": [
            {
                "product_id": p["id"],
                "quantity_intact_base_units": 2,
                "quantity_loss_base_units": 1,
                "loss_reason": "Quebra de teste",
            }
        ],
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK
    dis_data = r_dis.json()
    assert dis_data["quantity_disassembled"] == 1
    assert dis_data["intact_items_returned"] == 1
    assert dis_data["loss_items_recorded"] == 1


def test_serialize_batch_stock_capped_at_remaining_in_batch(client, authenticated_device):
    """
    Testa que em serialize_batch para cestas padrao, current_batch_stock
    e estritamente min(remaining_in_batch, warehouse_stock).
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Estoque Min", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 100, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_STOCK_MIN", "name": "Cesta Stock Min"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Cria lote 1 de 5 cestas
    b1 = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 5}, headers=headers).json()
    # Cria lote 2 de 10 cestas (armazem passa a ter 15 cestas)
    b2 = client.post("/api/v1/production/batches", json={"basket_type_id": bt["id"], "quantity_produced": 10}, headers=headers).json()

    # O lote 1 deve reportar current_batch_stock = 5 (e nao 15!)
    b1_check = client.get(f"/api/v1/production/batches/{b1['id']}", headers=headers).json()
    assert b1_check["current_batch_stock"] == 5
    assert b1_check["quantity_disassembled"] == 0

    # Desmonta 2 cestas do lote 1 (restam 3 no lote, armazem fica com 13)
    client.post(f"/api/v1/production/batches/{b1['id']}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmontagem 2 de 5",
    }, headers=headers)

    b1_check2 = client.get(f"/api/v1/production/batches/{b1['id']}", headers=headers).json()
    assert b1_check2["quantity_disassembled"] == 2
    assert b1_check2["current_batch_stock"] == 3 # min(3, 13) = 3

    # Simula venda/baixa de quase todo o estoque do armazem, deixando apenas 1 cesta no total
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "BASKET",
        "basket_type_id": bt["id"],
        "adjustment_type": "OUT",
        "quantity_delta": 12, # 13 - 12 = 1 cesta restante no armazem
        "reason": "Venda em massa",
    }, headers=headers)

    # Agora o lote 1 tem remaining_in_batch = 3, mas warehouse_stock = 1. current_batch_stock deve ser min(3, 1) = 1!
    b1_check3 = client.get(f"/api/v1/production/batches/{b1['id']}", headers=headers).json()
    assert b1_check3["current_batch_stock"] == 1


def test_cancel_custom_batch_after_partial_disassembly(client, authenticated_device):
    """
    Testa que o endpoint /cancel funciona perfeitamente para lotes personalizados
    que sofreram desmontagem parcial previa, retornando o saldo restante e marcando DISASSEMBLED.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Cancel Custom", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CANCEL_CUST", "name": "Cesta Cancel Cust", "allows_customization": True}, headers=headers).json()

    # Cria lote personalizado de 4 cestas (consome 12 unidades)
    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 4,
        "is_custom": True,
        "custom_description": "Custom para estorno parcial",
        "custom_items": [{"product_id": p["id"], "quantity_in_base_units": 3, "section": "ALIMENTACAO"}],
    }, headers=headers).json()
    batch_id = batch["id"]

    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 8

    # 1. Desmonta 1 cesta
    r_dis = client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Desmonta 1 de 4",
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 11

    # 2. Executa /cancel: deve estornar as 3 restantes
    r_cancel = client.post(f"/api/v1/production/batches/{batch_id}/cancel", json={
        "reason": "Estorno das 3 restantes",
    }, headers=headers)
    assert r_cancel.status_code == status.HTTP_200_OK
    assert r_cancel.json()["quantity_disassembled"] == 3
    assert r_cancel.json()["status"] == "DISASSEMBLED"

    # Saldo de insumo deve ter voltado para 20
    assert client.get(f"/api/v1/inventory/products/{p['id']}/stock", headers=headers).json()["current_stock"] == 20

    b_check = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_check["status"] == "DISASSEMBLED"
    assert b_check["quantity_disassembled"] == 4
    assert b_check["current_batch_stock"] == 0


def test_cancel_fails_when_finished_baskets_insufficient_stock(client, authenticated_device):
    """
    Testa que /cancel falha com 409 Conflict se o saldo restante do lote nao estiver
    mais disponivel fisicamente no armazem (ex: cestas ja vendidas ou baixadas).
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Cancel Insuff", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CANCEL_INSUFF", "name": "Cesta Cancel Insuff"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"}]
    }, headers=headers)

    # Cria lote de 5 cestas
    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 5,
    }, headers=headers).json()
    batch_id = batch["id"]

    # Desmonta 1 cesta (restam 4 no lote e 4 no armazem)
    client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Desmonta 1",
    }, headers=headers)

    # Simula baixa/venda de todas as 4 cestas restantes do armazem
    client.post("/api/v1/inventory/adjustments", json={
        "item_type": "BASKET",
        "basket_type_id": bt["id"],
        "adjustment_type": "OUT",
        "quantity_delta": 4,
        "reason": "Venda de todas as cestas",
    }, headers=headers)

    # Agora o lote tem remaining_in_batch = 4, mas estoque do armazem = 0.
    # O /cancel deve falhar com 409 Conflict!
    r_cancel = client.post(f"/api/v1/production/batches/{batch_id}/cancel", json={
        "reason": "Tentativa de cancelar sem saldo",
    }, headers=headers)
    assert r_cancel.status_code == status.HTTP_409_CONFLICT
    assert r_cancel.json()["detail"]["error_code"] == "INSUFFICIENT_STOCK"


def test_disassembly_triage_rejects_unknown_product_or_duplicate(client, authenticated_device):
    """
    Testa que a triagem rejeita produtos nao pertencentes ao lote ou informados em duplicidade.
    """
    _, _, headers = authenticated_device

    p1 = client.post("/api/v1/products", json={"name": "Prod Triage 1", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    p2 = client.post("/api/v1/products", json={"name": "Prod Triage 2 (Alheio)", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p1["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_TRIAGE_VAL", "name": "Cesta Triage Val"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p1["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
    }, headers=headers).json()

    # 1. Enviar triagem com produto p2 que nao pertence a cesta
    r_bad_prod = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Triagem com produto alheio",
        "triage_items": [
            {"product_id": p2["id"], "intact_quantity": 2, "loss_quantity": 0}
        ],
    }, headers=headers)
    assert r_bad_prod.status_code == status.HTTP_400_BAD_REQUEST
    assert "nao pertence a composicao" in r_bad_prod.json()["detail"]

    # 2. Enviar triagem com o mesmo produto p1 em duplicidade
    r_dup = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "Triagem duplicada",
        "triage_items": [
            {"product_id": p1["id"], "intact_quantity": 1, "loss_quantity": 0},
            {"product_id": p1["id"], "intact_quantity": 1, "loss_quantity": 0},
        ],
    }, headers=headers)
    assert r_dup.status_code == status.HTTP_400_BAD_REQUEST
    assert "duplicidade" in r_dup.json()["detail"]


def test_disassembly_with_omitted_quantity_defaults_to_remaining_in_batch(client, authenticated_device):
    """
    Testa que ao omitir quantity_to_disassemble (None), o service desmonta exatamente
    o saldo restante do lote e transiciona para DISASSEMBLED.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Omit Qty", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_OMIT_QTY", "name": "Cesta Omit Qty"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"}]
    }, headers=headers)

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 5,
    }, headers=headers).json()

    # Desmonta 2 cestas
    client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmonta 2 de 5",
    }, headers=headers)

    # Desmonta com quantity_to_disassemble omitido: deve desmontar as 3 restantes!
    r_dis = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "reason": "Desmonta restante sem especificar quantidade",
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK
    assert r_dis.json()["quantity_disassembled"] == 3
    assert r_dis.json()["status"] == "DISASSEMBLED"

    b_check = client.get(f"/api/v1/production/batches/{batch['id']}", headers=headers).json()
    assert b_check["status"] == "DISASSEMBLED"
    assert b_check["quantity_disassembled"] == 5
    assert b_check["current_batch_stock"] == 0


def test_serialize_batch_stock_capped_for_custom_batch_as_well(client, authenticated_device):
    """
    Testa que para cestas personalizadas, current_batch_stock tambem e estritamente
    limitado por remaining_in_batch.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Custom Min", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 20, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CUST_CAP", "name": "Cesta Cust Cap", "allows_customization": True}, headers=headers).json()

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 4,
        "is_custom": True,
        "custom_description": "Custom Cap Test",
        "custom_items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}],
    }, headers=headers).json()
    batch_id = batch["id"]

    # Desmonta 2 cestas (restam 2 no lote)
    client.post(f"/api/v1/production/batches/{batch_id}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmonta 2",
    }, headers=headers)

    b_check = client.get(f"/api/v1/production/batches/{batch_id}", headers=headers).json()
    assert b_check["quantity_disassembled"] == 2
    assert b_check["current_batch_stock"] == 2


def test_disassembly_triage_validates_quantity_sum_consistency(client, authenticated_device):
    """
    Testa que a triagem rejeita divergencia na soma das quantidades intactas e avariadas:
    a soma (intact_quantity + loss_quantity) deve ser exatamente igual ao total consumido
    para a quantidade de cestas desmontadas (qty_to_disassemble * quantity_per_basket).
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Consist Triage", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 30, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_CONSIST", "name": "Cesta Consist"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 3, "section": "ALIMENTACAO"}]
    }, headers=headers)

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 4,
    }, headers=headers).json()

    # Desmontar 2 cestas exige 2 * 3 = 6 unidades de insumo.
    # Se informar intact=4 e loss=1 (total 5 != 6), deve ser rejeitado com 400.
    r_div_under = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Triagem com soma insuficiente",
        "triage_items": [
            {"product_id": p["id"], "intact_quantity": 4, "loss_quantity": 1}
        ],
    }, headers=headers)
    assert r_div_under.status_code == status.HTTP_400_BAD_REQUEST
    assert "Divergencia na triagem" in r_div_under.json()["detail"]

    # Se informar intact=5 e loss=2 (total 7 != 6), deve ser rejeitado com 400.
    r_div_over = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Triagem com soma excedente",
        "triage_items": [
            {"product_id": p["id"], "intact_quantity": 5, "loss_quantity": 2}
        ],
    }, headers=headers)
    assert r_div_over.status_code == status.HTTP_400_BAD_REQUEST
    assert "Divergencia na triagem" in r_div_over.json()["detail"]


def test_disassembly_triage_loss_reason_and_aliases_support(client, authenticated_device):
    """
    Testa o suporte a aliases de entrada na triagem (quantity_intact_base_units, quantity_loss_base_units),
    a preservacao da justificativa especifica do item e a correta contabilizacao de estoques.
    """
    _, _, headers = authenticated_device

    p1 = client.post("/api/v1/products", json={"name": "Prod Alias Triage 1", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    p2 = client.post("/api/v1/products", json={"name": "Prod Alias Triage 2", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [
        {"product_id": p1["id"], "packages_count": 20, "unit_price_cents": 100},
        {"product_id": p2["id"], "packages_count": 20, "unit_price_cents": 200},
    ]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_ALIAS_TRI", "name": "Cesta Alias Tri"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": p1["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"},
            {"product_id": p2["id"], "quantity_in_base_units": 1, "section": "ALIMENTACAO"},
        ]
    }, headers=headers)

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 3,
    }, headers=headers).json()

    # Desmonta 2 cestas:
    # p1 total necessario = 4. Usar aliases: quantity_intact_base_units=3, quantity_loss_base_units=1, loss_reason="Embalagem rasgada"
    # p2 total necessario = 2. Usar aliases: quantity_intact_base_units=2, quantity_loss_base_units=0
    r_dis = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 2,
        "reason": "Desmontagem com aliases e motivo de perda de insumo",
        "triage_items": [
            {
                "product_id": p1["id"],
                "quantity_intact_base_units": 3,
                "quantity_loss_base_units": 1,
                "loss_reason": "Embalagem rasgada no manuseio",
            },
            {
                "product_id": p2["id"],
                "quantity_intact_base_units": 2,
                "quantity_loss_base_units": 0,
            },
        ],
    }, headers=headers)
    assert r_dis.status_code == status.HTTP_200_OK
    data = r_dis.json()
    assert data["intact_items_returned"] == 2
    assert data["loss_items_recorded"] == 1

    # Insumo p1: 20 comprados - 6 consumidos na montagem + 3 retornados intactos = 17 em estoque
    assert client.get(f"/api/v1/inventory/products/{p1['id']}/stock", headers=headers).json()["current_stock"] == 17
    # Insumo p2: 20 comprados - 3 consumidos na montagem + 2 retornados intactos = 19 em estoque
    assert client.get(f"/api/v1/inventory/products/{p2['id']}/stock", headers=headers).json()["current_stock"] == 19


def test_disassembly_triage_loss_requires_justification(client, authenticated_device, test_session):
    """
    Testa que qualquer perda fisica (loss_quantity > 0) na desmontagem exige justificativa
    obrigatoria (motivo nao vazio no item ou motivo valido da desmontagem), sendo rejeitada
    se nenhuma justificativa for informada.
    """
    _, _, headers = authenticated_device

    p = client.post("/api/v1/products", json={"name": "Prod Loss Just", "category": "ALIMENTACAO", "base_unit": "UNIT"}, headers=headers).json()
    client.post("/api/v1/purchases", json={"items": [{"product_id": p["id"], "packages_count": 10, "unit_price_cents": 100}]}, headers=headers)

    bt = client.post("/api/v1/basket-types", json={"code": "BT_LOSS_JUST", "name": "Cesta Loss Just"}, headers=headers).json()
    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 2, "section": "ALIMENTACAO"}]
    }, headers=headers)

    batch = client.post("/api/v1/production/batches", json={
        "basket_type_id": bt["id"],
        "quantity_produced": 2,
    }, headers=headers).json()

    # 1. API: Envio de motivo em branco ou menor que 3 caracteres e rejeitado com 422
    r_empty_reason = client.post(f"/api/v1/production/batches/{batch['id']}/disassemble", json={
        "quantity_to_disassemble": 1,
        "reason": "  ",
        "triage_items": [
            {"product_id": p["id"], "intact_quantity": 1, "loss_quantity": 1, "loss_reason": None}
        ],
    }, headers=headers)
    assert r_empty_reason.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # 2. Servico direto: Se effective_reason for None/vazio quando houver loss_quantity > 0, lanca HTTP 400
    direct_req = DisassemblyRequest.model_construct(
        quantity_to_disassemble=1,
        reason="",
        triage_items=[
            DisassemblyTriageItem(
                product_id=p["id"],
                intact_quantity=1,
                loss_quantity=1,
                loss_reason=None,
            )
        ],
    )
    with pytest.raises(HTTPException) as exc_info:
        disassemble_production_batch(test_session, batch["id"], direct_req)
    assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
    assert "exige justificativa obrigatoria" in exc_info.value.detail





