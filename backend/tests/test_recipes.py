import pytest
from fastapi import status

def test_create_basket_type_success(client, authenticated_device):
    _, _, headers = authenticated_device
    payload = {
        "code": "CESTA_FAMILIA_T1",
        "name": "Cesta Familia Tipo 1",
        "description": "Cesta completa contendo alimentos e produtos de higiene",
        "category": "PADRAO",
        "default_price_cents": 16990,
        "allows_customization": False,
        "tracks_finished_stock": True,
        "is_active": True,
    }
    resp = client.post("/api/v1/basket-types", json=payload, headers=headers)
    assert resp.status_code == status.HTTP_201_CREATED
    data = resp.json()
    assert data["id"] is not None
    assert data["code"] == "CESTA_FAMILIA_T1"
    assert data["name"] == "Cesta Familia Tipo 1"
    assert data["default_price_cents"] == 16990
    assert data["allows_customization"] is False
    assert data["active_recipe"] is None


def test_duplicate_basket_type_code_rejected(client, authenticated_device):
    _, _, headers = authenticated_device
    p1 = {
        "code": "CESTA_NATAL_2026",
        "name": "Cesta Natalina Prata",
    }
    client.post("/api/v1/basket-types", json=p1, headers=headers)

    p2 = {
        "code": "CESTA_NATAL_2026",
        "name": "Cesta Natalina Ouro",
    }
    r2 = client.post("/api/v1/basket-types", json=p2, headers=headers)
    assert r2.status_code == status.HTTP_409_CONFLICT
    assert "codigo" in r2.json()["detail"].lower()


def test_create_initial_recipe_version(client, authenticated_device):
    _, _, headers = authenticated_device
    # Cria cesta
    bt = client.post("/api/v1/basket-types", json={
        "code": "BASICA_POPULAR",
        "name": "Cesta Basica Popular",
    }, headers=headers).json()
    bt_id = bt["id"]

    # Cria dois produtos ativos
    prod1 = client.post("/api/v1/products", json={
        "name": "Arroz 5kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    prod2 = client.post("/api/v1/products", json={
        "name": "Detergente 500ml",
        "category": "LIMPEZA",
        "base_unit": "ML",
    }, headers=headers).json()

    # Cria a primeira versao da receita
    recipe_payload = {
        "notes": "Composicao inicial da cesta popular 2026",
        "items": [
            {
                "product_id": prod1["id"],
                "quantity_in_base_units": 5000,
                "section": "ALIMENTACAO",
                "is_required": True,
            },
            {
                "product_id": prod2["id"],
                "quantity_in_base_units": 500,
                "section": "LIMPEZA",
                "is_required": True,
            },
        ],
    }
    resp = client.post(f"/api/v1/basket-types/{bt_id}/recipes", json=recipe_payload, headers=headers)
    assert resp.status_code == status.HTTP_201_CREATED
    data = resp.json()
    assert data["version_number"] == 1
    assert data["status"] == "ACTIVE"
    assert len(data["items"]) == 2

    # Verifica se os dados do produto vieram preenchidos no response
    item_arroz = next(it for it in data["items"] if it["product_id"] == prod1["id"])
    assert item_arroz["product_name"] == "Arroz 5kg"
    assert item_arroz["quantity_in_base_units"] == 5000
    assert item_arroz["section"] == "ALIMENTACAO"


def test_versioning_and_immutability_on_composition_change(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_CARNE_PREMIUM",
        "name": "Cesta de Carnes Premium",
    }, headers=headers).json()
    bt_id = bt["id"]

    p_frango = client.post("/api/v1/products", json={
        "name": "Frango Congelado 1kg",
        "category": "CARNE",
        "base_unit": "G",
    }, headers=headers).json()
    p_bovina = client.post("/api/v1/products", json={
        "name": "Carne Bovina Acem 1kg",
        "category": "CARNE",
        "base_unit": "G",
    }, headers=headers).json()
    p_linguica = client.post("/api/v1/products", json={
        "name": "Linguica Toscana 1kg",
        "category": "CARNE",
        "base_unit": "G",
    }, headers=headers).json()

    # Versao 1: 1kg frango + 1kg bovina
    r1 = client.post(f"/api/v1/basket-types/{bt_id}/recipes", json={
        "notes": "Versao 1",
        "items": [
            {"product_id": p_frango["id"], "quantity_in_base_units": 1000, "section": "CARNE"},
            {"product_id": p_bovina["id"], "quantity_in_base_units": 1000, "section": "CARNE"},
        ],
    }, headers=headers).json()
    assert r1["version_number"] == 1
    assert r1["status"] == "ACTIVE"
    assert len(r1["items"]) == 2

    # Versao 2: Alteracao da composicao (troca bovina por linguica e adiciona 2kg frango)
    r2 = client.post(f"/api/v1/basket-types/{bt_id}/recipes", json={
        "notes": "Versao 2 com substituicao de corte",
        "items": [
            {"product_id": p_frango["id"], "quantity_in_base_units": 2000, "section": "CARNE"},
            {"product_id": p_linguica["id"], "quantity_in_base_units": 1000, "section": "CARNE"},
        ],
    }, headers=headers).json()
    assert r2["version_number"] == 2
    assert r2["status"] == "ACTIVE"
    assert len(r2["items"]) == 2

    # Consulta a versao 1 historica: deve permanecer intacta com status ARCHIVED
    v1_check = client.get(f"/api/v1/basket-types/{bt_id}/recipes/1", headers=headers)
    assert v1_check.status_code == status.HTTP_200_OK
    v1_data = v1_check.json()
    assert v1_data["version_number"] == 1
    assert v1_data["status"] == "ARCHIVED"
    assert len(v1_data["items"]) == 2
    v1_pids = {it["product_id"] for it in v1_data["items"]}
    assert p_frango["id"] in v1_pids
    assert p_bovina["id"] in v1_pids

    # Consulta a versao ativa da cesta: deve ser a versao 2
    active_check = client.get(f"/api/v1/basket-types/{bt_id}/recipes/active", headers=headers)
    assert active_check.status_code == status.HTTP_200_OK
    assert active_check.json()["version_number"] == 2

    # Missing body remains invalid. An unused recipe may now be removed.
    bad_put = client.put(f"/api/v1/basket-types/{bt_id}/recipes/1", headers=headers)
    assert bad_put.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    # No sale or assembly depends on this recipe.
    bad_del = client.delete(f"/api/v1/basket-types/{bt_id}/recipes/1", headers=headers)
    assert bad_del.status_code == status.HTTP_200_OK


def test_reject_recipe_with_inactive_product(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_TESTE_INATIVO",
        "name": "Cesta Teste Inativo",
    }, headers=headers).json()

    prod = client.post("/api/v1/products", json={
        "name": "Produto Inativado",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    prod_id = prod["id"]

    # Inativar o produto
    client.delete(f"/api/v1/products/{prod_id}", headers=headers)

    # Tentar criar receita com insumo inativo
    bad_recipe = client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": prod_id, "quantity_in_base_units": 1000, "section": "ALIMENTACAO"}
        ]
    }, headers=headers)
    assert bad_recipe.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativo" in bad_recipe.json()["detail"].lower()


def test_reject_recipe_with_duplicate_products(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_DUP",
        "name": "Cesta Duplicidade",
    }, headers=headers).json()

    prod = client.post("/api/v1/products", json={
        "name": "Sal 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()

    # Adiciona o mesmo produto duas vezes na mesma receita
    bad_recipe = client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": prod["id"], "quantity_in_base_units": 1000, "section": "ALIMENTACAO"},
            {"product_id": prod["id"], "quantity_in_base_units": 2000, "section": "ALIMENTACAO"},
        ]
    }, headers=headers)
    assert bad_recipe.status_code == status.HTTP_400_BAD_REQUEST
    assert "mais de uma vez" in bad_recipe.json()["detail"].lower()


def test_reject_recipe_with_nonexistent_product(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_NONEXIST",
        "name": "Cesta Produto Inexistente",
    }, headers=headers).json()

    bad_recipe = client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": "uuid-fantasma-123", "quantity_in_base_units": 1000, "section": "ALIMENTACAO"}
        ]
    }, headers=headers)
    assert bad_recipe.status_code == status.HTTP_404_NOT_FOUND


def test_soft_delete_basket_type(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_INATIVAR",
        "name": "Cesta Descontinuada",
    }, headers=headers).json()
    bt_id = bt["id"]

    # Inativa a cesta
    del_resp = client.delete(f"/api/v1/basket-types/{bt_id}", headers=headers)
    assert del_resp.status_code == status.HTTP_200_OK
    assert del_resp.json()["is_active"] is False

    # Tentar criar receita para cesta inativa deve falhar
    p = client.post("/api/v1/products", json={
        "name": "Item Cesta Inativa",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()

    bad_rec = client.post(f"/api/v1/basket-types/{bt_id}/recipes", json={
        "items": [{"product_id": p["id"], "quantity_in_base_units": 100, "section": "ALIMENTACAO"}]
    }, headers=headers)
    assert bad_rec.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativo" in bad_rec.json()["detail"].lower()


def test_unauthenticated_recipe_requests_rejected(client):
    resp = client.get("/api/v1/basket-types")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_case_insensitive_basket_category_filter(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_NATAL_CASE",
        "name": "Cesta Natalina Case Filter",
        "category": "NATALINA",
    }, headers=headers).json()

    # Filtro em minusculo
    resp = client.get("/api/v1/basket-types?category=natalina", headers=headers)
    assert resp.status_code == status.HTTP_200_OK
    items = resp.json()
    assert any(b["code"] == "CESTA_NATAL_CASE" for b in items)


def test_recipe_with_large_item_count_50_plus(client, authenticated_device):
    """
    Testa a composicao de receita com volumetria alta (55 itens distintos)
    em uma unica transacao atomica do SQLite.
    """
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_MEGA_55",
        "name": "Cesta Mega 55 Itens",
    }, headers=headers).json()
    bt_id = bt["id"]

    # Cria 55 produtos distintos
    recipe_items = []
    for i in range(55):
        p = client.post("/api/v1/products", json={
            "name": f"Insumo Bulk {i+1}",
            "category": "ALIMENTACAO" if i % 2 == 0 else "LIMPEZA",
            "base_unit": "UNIT",
        }, headers=headers).json()
        recipe_items.append({
            "product_id": p["id"],
            "quantity_in_base_units": (i + 1) * 2,
            "section": "ALIMENTACAO" if i % 2 == 0 else "LIMPEZA",
            "is_required": True,
        })

    # Submete receita com 55 itens
    rec_resp = client.post(f"/api/v1/basket-types/{bt_id}/recipes", json={
        "notes": "Receita grande com 55 componentes",
        "items": recipe_items,
    }, headers=headers)
    assert rec_resp.status_code == status.HTTP_201_CREATED
    data = rec_resp.json()
    assert data["version_number"] == 1
    assert data["status"] == "ACTIVE"
    assert len(data["items"]) == 55

    # Valida consulta da receita ativa
    active_resp = client.get(f"/api/v1/basket-types/{bt_id}/recipes/active", headers=headers)
    assert active_resp.status_code == status.HTTP_200_OK
    assert len(active_resp.json()["items"]) == 55


def test_recipe_items_ordered_stably(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_ORDER_TEST",
        "name": "Cesta Order Test",
    }, headers=headers).json()

    p_limp = client.post("/api/v1/products", json={"name": "Alcool 70", "category": "LIMPEZA", "base_unit": "ML"}, headers=headers).json()
    p_alim = client.post("/api/v1/products", json={"name": "Biscoito", "category": "ALIMENTACAO", "base_unit": "G"}, headers=headers).json()

    rec_resp = client.post(f"/api/v1/basket-types/{bt['id']}/recipes", json={
        "items": [
            {"product_id": p_limp["id"], "quantity_in_base_units": 1000, "section": "LIMPEZA"},
            {"product_id": p_alim["id"], "quantity_in_base_units": 500, "section": "ALIMENTACAO"},
        ],
    }, headers=headers)
    assert rec_resp.status_code == status.HTTP_201_CREATED
    items = rec_resp.json()["items"]
    # Section ALIMENTACAO vem antes de LIMPEZA
    assert items[0]["section"] == "ALIMENTACAO"
    assert items[1]["section"] == "LIMPEZA"


def test_update_basket_type_clear_description_with_null(client, authenticated_device):
    _, _, headers = authenticated_device
    bt = client.post("/api/v1/basket-types", json={
        "code": "CESTA_CLEAR_DESC",
        "name": "Cesta Desc Limpar",
        "description": "Descricao para ser removida",
    }, headers=headers).json()
    bt_id = bt["id"]

    upd = client.put(f"/api/v1/basket-types/{bt_id}", json={"description": None}, headers=headers)
    assert upd.status_code == status.HTTP_200_OK
    assert upd.json()["description"] is None


def test_whitespace_basket_name_or_code_rejected_with_422(client, authenticated_device):
    _, _, headers = authenticated_device
    r_bad_code = client.post("/api/v1/basket-types", json={
        "code": "    ",
        "name": "Cesta Sem Codigo",
    }, headers=headers)
    assert r_bad_code.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    r_bad_name = client.post("/api/v1/basket-types", json={
        "code": "CESTA_VALIDA",
        "name": "    ",
    }, headers=headers)
    assert r_bad_name.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
