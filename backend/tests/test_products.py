import pytest
from fastapi import status

def test_create_product_success(client, authenticated_device):
    _, _, headers = authenticated_device
    payload = {
        "name": "Arroz Agulhinha Tipo 1 5kg",
        "sku": "ARR-AGU-5KG",
        "barcode": "7891000100011",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "minimum_stock": 50000,
        "cost_price_cents": 2350,
        "sale_price_cents": 2890,
        "notes": "Armazenar em local seco",
        "is_active": True,
    }
    resp = client.post("/api/v1/products", json=payload, headers=headers)
    assert resp.status_code == status.HTTP_201_CREATED
    data = resp.json()
    assert data["id"] is not None
    assert data["name"] == "Arroz Agulhinha Tipo 1 5kg"
    assert data["sku"] == "ARR-AGU-5KG"
    assert data["barcode"] == "7891000100011"
    assert data["category"] == "ALIMENTACAO"
    assert data["base_unit"] == "G"
    assert data["minimum_stock"] == 50000
    assert data["cost_price_cents"] == 2350
    assert data["sale_price_cents"] == 2890
    assert data["is_active"] is True
    assert data["packagings"] == []


def test_list_products_and_search_filters(client, authenticated_device):
    _, _, headers = authenticated_device

    # Cria dois produtos de categorias distintas
    p1 = {
        "name": "Feijao Carioca 1kg",
        "sku": "FEI-CAR-1KG",
        "barcode": "7891000200022",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "minimum_stock": 20000,
    }
    p2 = {
        "name": "Detergente Neutro 500ml",
        "sku": "DET-NEU-500",
        "barcode": "7891000300033",
        "category": "LIMPEZA",
        "base_unit": "ML",
        "minimum_stock": 10000,
    }
    client.post("/api/v1/products", json=p1, headers=headers)
    client.post("/api/v1/products", json=p2, headers=headers)

    # Listar todos
    r_all = client.get("/api/v1/products", headers=headers)
    assert r_all.status_code == status.HTTP_200_OK
    assert len(r_all.json()) >= 2

    # Filtrar por categoria ALIMENTACAO
    r_cat = client.get("/api/v1/products?category=ALIMENTACAO", headers=headers)
    assert r_cat.status_code == status.HTTP_200_OK
    items_cat = r_cat.json()
    assert all(it["category"] == "ALIMENTACAO" for it in items_cat)
    assert any(it["name"] == "Feijao Carioca 1kg" for it in items_cat)

    # Filtrar por busca (nome)
    r_search = client.get("/api/v1/products?search=detergente", headers=headers)
    assert r_search.status_code == status.HTTP_200_OK
    items_search = r_search.json()
    assert len(items_search) == 1
    assert items_search[0]["name"] == "Detergente Neutro 500ml"

    # Filtrar por busca (barcode)
    r_bc = client.get("/api/v1/products?search=7891000200022", headers=headers)
    assert r_bc.status_code == status.HTTP_200_OK
    assert len(r_bc.json()) == 1
    assert r_bc.json()[0]["name"] == "Feijao Carioca 1kg"


def test_get_product_by_id(client, authenticated_device):
    _, _, headers = authenticated_device
    p = {
        "name": "Oleo de Soja 900ml",
        "category": "ALIMENTACAO",
        "base_unit": "ML",
    }
    create_resp = client.post("/api/v1/products", json=p, headers=headers)
    prod_id = create_resp.json()["id"]

    get_resp = client.get(f"/api/v1/products/{prod_id}", headers=headers)
    assert get_resp.status_code == status.HTTP_200_OK
    assert get_resp.json()["id"] == prod_id
    assert get_resp.json()["name"] == "Oleo de Soja 900ml"


def test_get_nonexistent_product_returns_404(client, authenticated_device):
    _, _, headers = authenticated_device
    resp = client.get("/api/v1/products/inexistente-123", headers=headers)
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_update_product(client, authenticated_device):
    _, _, headers = authenticated_device
    p = {
        "name": "Sabao em Po 1kg",
        "category": "LIMPEZA",
        "base_unit": "G",
        "minimum_stock": 5000,
        "cost_price_cents": 800,
        "sale_price_cents": 1150,
    }
    create_resp = client.post("/api/v1/products", json=p, headers=headers)
    prod_id = create_resp.json()["id"]

    update_payload = {
        "name": "Sabao em Po Lavagem Especial 1kg",
        "cost_price_cents": 900,
        "sale_price_cents": 1290,
        "notes": "Formula concentrada",
    }
    update_resp = client.put(f"/api/v1/products/{prod_id}", json=update_payload, headers=headers)
    assert update_resp.status_code == status.HTTP_200_OK
    updated = update_resp.json()
    assert updated["name"] == "Sabao em Po Lavagem Especial 1kg"
    assert updated["cost_price_cents"] == 900
    assert updated["sale_price_cents"] == 1290
    assert updated["notes"] == "Formula concentrada"


def test_duplicate_sku_rejection(client, authenticated_device):
    _, _, headers = authenticated_device
    p1 = {
        "name": "Acucar Cristal 1kg",
        "sku": "ACU-CRI-1KG",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }
    r1 = client.post("/api/v1/products", json=p1, headers=headers)
    assert r1.status_code == status.HTTP_201_CREATED

    p2 = {
        "name": "Acucar Refinado 1kg",
        "sku": "ACU-CRI-1KG",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }
    r2 = client.post("/api/v1/products", json=p2, headers=headers)
    assert r2.status_code == status.HTTP_409_CONFLICT
    assert "SKU" in r2.json()["detail"]


def test_duplicate_barcode_rejection(client, authenticated_device):
    _, _, headers = authenticated_device
    p1 = {
        "name": "Cafe Torrado 500g",
        "barcode": "7894445556667",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }
    r1 = client.post("/api/v1/products", json=p1, headers=headers)
    assert r1.status_code == status.HTTP_201_CREATED

    p2 = {
        "name": "Cafe Especial 500g",
        "barcode": "7894445556667",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }
    r2 = client.post("/api/v1/products", json=p2, headers=headers)
    assert r2.status_code == status.HTTP_409_CONFLICT
    assert "codigo de barras" in r2.json()["detail"]


def test_validation_errors(client, authenticated_device):
    _, _, headers = authenticated_device

    # Nome vazio
    r_empty_name = client.post("/api/v1/products", json={
        "name": "",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers)
    assert r_empty_name.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Estoque minimo negativo
    r_neg_stock = client.post("/api/v1/products", json={
        "name": "Macarrao 500g",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "minimum_stock": -10,
    }, headers=headers)
    assert r_neg_stock.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # Preco negativo
    r_neg_price = client.post("/api/v1/products", json={
        "name": "Macarrao 500g",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "cost_price_cents": -500,
    }, headers=headers)
    assert r_neg_price.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_soft_delete_preserves_product_and_sets_inactive(client, authenticated_device):
    _, _, headers = authenticated_device
    p = {
        "name": "Sal Refinado 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "is_active": True,
    }
    create_resp = client.post("/api/v1/products", json=p, headers=headers)
    prod_id = create_resp.json()["id"]

    # Chamada de exclusao (soft delete)
    del_resp = client.delete(f"/api/v1/products/{prod_id}", headers=headers)
    assert del_resp.status_code == status.HTTP_200_OK
    data = del_resp.json()
    assert data["id"] == prod_id
    assert data["is_active"] is False
    assert "proibida" in data["message"].lower()

    # Confirmar que produto continua existindo no banco de dados porem inativo
    get_resp = client.get(f"/api/v1/products/{prod_id}", headers=headers)
    assert get_resp.status_code == status.HTTP_200_OK
    assert get_resp.json()["is_active"] is False


def test_unauthenticated_request_rejected(client):
    # Sem cabecalho Authorization
    resp = client.get("/api/v1/products")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_case_insensitive_category_filter(client, authenticated_device):
    _, _, headers = authenticated_device
    p = {
        "name": "Arroz Agulhinha Case Test",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }
    client.post("/api/v1/products", json=p, headers=headers)

    # Filtrar com lowercase
    resp = client.get("/api/v1/products?category=alimentacao", headers=headers)
    assert resp.status_code == status.HTTP_200_OK
    items = resp.json()
    assert any(it["name"] == "Arroz Agulhinha Case Test" for it in items)


def test_whitespace_name_rejected_with_422(client, authenticated_device):
    _, _, headers = authenticated_device
    resp = client.post("/api/v1/products", json={
        "name": "    ",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers)
    assert resp.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_whitespace_sku_and_barcode_normalized_to_none(client, authenticated_device):
    _, _, headers = authenticated_device
    r1 = client.post("/api/v1/products", json={
        "name": "Prod WS 1",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "sku": "   ",
        "barcode": "   ",
    }, headers=headers)
    assert r1.status_code == status.HTTP_201_CREATED
    assert r1.json()["sku"] is None
    assert r1.json()["barcode"] is None

    # Segundo produto com whitespace em SKU e Barcode nao deve colidir
    r2 = client.post("/api/v1/products", json={
        "name": "Prod WS 2",
        "category": "ALIMENTACAO",
        "base_unit": "G",
        "sku": "   ",
        "barcode": "   ",
    }, headers=headers)
    assert r2.status_code == status.HTTP_201_CREATED
    assert r2.json()["sku"] is None
    assert r2.json()["barcode"] is None


def test_update_product_clear_sku_barcode_notes_with_null(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod Para Limpar",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
        "sku": "SKU-TEMP-01",
        "barcode": "7899999999991",
        "notes": "Nota inicial",
    }, headers=headers).json()
    pid = p["id"]

    # Envia null explicitamente para limpar os campos
    upd = client.put(f"/api/v1/products/{pid}", json={
        "sku": None,
        "barcode": None,
        "notes": None,
    }, headers=headers)
    assert upd.status_code == status.HTTP_200_OK
    data = upd.json()
    assert data["sku"] is None
    assert data["barcode"] is None
    assert data["notes"] is None


def test_update_product_rejects_base_unit_mutation_when_packagings_exist(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Feijao Base Unit Test",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    # Cadastra embalagem
    client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Saco 5kg",
        "quantity_in_base_units": 5000,
    }, headers=headers)

    # Tenta alterar unidade base de G para KG
    bad_upd = client.put(f"/api/v1/products/{pid}", json={"base_unit": "KG"}, headers=headers)
    assert bad_upd.status_code == status.HTTP_400_BAD_REQUEST
    assert "embalagens" in bad_upd.json()["detail"].lower()


def test_update_product_rejects_base_unit_mutation_when_recipes_exist(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Item Receita Base Unit",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_UNIT_TEST",
        "name": "Cesta Unit Test",
    }, headers=headers).json()

    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": pid, "quantity_in_base_units": 1000}],
    }, headers=headers)

    bad_upd = client.put(f"/api/v1/products/{pid}", json={"base_unit": "KG"}, headers=headers)
    assert bad_upd.status_code == status.HTTP_400_BAD_REQUEST
    assert "receitas" in bad_upd.json()["detail"].lower()


def test_inactivate_product_rejected_when_in_active_recipe_of_active_basket(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Insumo Vital da Cesta",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_COM_INSUMO_VITAL",
        "name": "Cesta com Insumo Vital",
    }, headers=headers).json()

    client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [{"product_id": pid, "quantity_in_base_units": 2000}],
    }, headers=headers)

    # Tentar inativar via DELETE deve falhar com 409
    del_resp = client.delete(f"/api/v1/products/{pid}", headers=headers)
    assert del_resp.status_code == status.HTTP_409_CONFLICT
    assert "em uso na receita ativa" in del_resp.json()["detail"].lower()

    # Tentar inativar via PUT deve falhar com 409
    put_resp = client.put(f"/api/v1/products/{pid}", json={"is_active": False}, headers=headers)
    assert put_resp.status_code == status.HTTP_409_CONFLICT
    assert "em uso na receita ativa" in put_resp.json()["detail"].lower()


def test_inactivate_product_cascades_inactivation_to_its_packagings(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Produto Sem Cesta",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers).json()
    pid = p["id"]

    pkg = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Caixa 24",
        "quantity_in_base_units": 24,
        "is_default": True,
    }, headers=headers).json()

    # Inativa o produto
    del_resp = client.delete(f"/api/v1/products/{pid}", headers=headers)
    assert del_resp.status_code == status.HTTP_200_OK

    # Embalagem deve ter sido inativada e perdido default
    pkgs = client.get(f"/api/v1/products/{pid}/packagings", headers=headers).json()
    assert len(pkgs) == 1
    assert pkgs[0]["is_active"] is False
    assert pkgs[0]["is_default"] is False
