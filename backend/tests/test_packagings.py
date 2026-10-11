import pytest
from fastapi import status

def test_create_packaging_success(client, authenticated_device):
    _, _, headers = authenticated_device
    # Cria produto
    prod_resp = client.post("/api/v1/products", json={
        "name": "Sabonete 90g",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers)
    prod_id = prod_resp.json()["id"]

    # Cria embalagem comercial (Caixa com 12 unidades)
    pack_payload = {
        "name": "Caixa c/ 12 unidades",
        "quantity_in_base_units": 12,
        "is_default": True,
        "is_active": True,
    }
    pack_resp = client.post(f"/api/v1/products/{prod_id}/packagings", json=pack_payload, headers=headers)
    assert pack_resp.status_code == status.HTTP_201_CREATED
    data = pack_resp.json()
    assert data["id"] is not None
    assert data["product_id"] == prod_id
    assert data["name"] == "Caixa c/ 12 unidades"
    assert data["quantity_in_base_units"] == 12
    assert data["is_default"] is True
    assert data["is_active"] is True


def test_packaging_rejects_non_positive_conversion_factor(client, authenticated_device):
    _, _, headers = authenticated_device
    prod_resp = client.post("/api/v1/products", json={
        "name": "Feijao Preto 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers)
    prod_id = prod_resp.json()["id"]

    # Fator zero
    r_zero = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Fardo Zero",
        "quantity_in_base_units": 0,
    }, headers=headers)
    assert r_zero.status_code in (status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY, 422)

    # Fator negativo
    r_neg = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Fardo Negativo",
        "quantity_in_base_units": -5,
    }, headers=headers)
    assert r_neg.status_code in (status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY, 422)


def test_list_packagings_and_default_switch(client, authenticated_device):
    _, _, headers = authenticated_device
    prod_resp = client.post("/api/v1/products", json={
        "name": "Arroz Parboilizado 1kg",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers)
    prod_id = prod_resp.json()["id"]

    # Embalagem 1: Fardo com 10kg (10000g) como default
    p1 = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Fardo 10x1kg",
        "quantity_in_base_units": 10000,
        "is_default": True,
    }, headers=headers).json()

    # Embalagem 2: Fardo com 30kg (30000g) como novo default
    p2 = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Fardo 30x1kg",
        "quantity_in_base_units": 30000,
        "is_default": True,
    }, headers=headers).json()

    # Listar embalagens
    list_resp = client.get(f"/api/v1/products/{prod_id}/packagings", headers=headers)
    assert list_resp.status_code == status.HTTP_200_OK
    items = list_resp.json()
    assert len(items) == 2

    pack1 = next(it for it in items if it["id"] == p1["id"])
    pack2 = next(it for it in items if it["id"] == p2["id"])

    # A embalagem 1 deve ter perdido o is_default e a 2 deve ser o default atual
    assert pack1["is_default"] is False
    assert pack2["is_default"] is True


def test_update_packaging(client, authenticated_device):
    _, _, headers = authenticated_device
    prod_resp = client.post("/api/v1/products", json={
        "name": "Leite Integral 1L",
        "category": "ALIMENTACAO",
        "base_unit": "ML",
    }, headers=headers)
    prod_id = prod_resp.json()["id"]

    p = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Caixa c/ 10 un",
        "quantity_in_base_units": 10000,
    }, headers=headers).json()
    pack_id = p["id"]

    # Atualizar para 12 unidades (12000 ml)
    upd_resp = client.put(f"/api/v1/packagings/{pack_id}", json={
        "name": "Caixa c/ 12 unidades",
        "quantity_in_base_units": 12000,
    }, headers=headers)
    assert upd_resp.status_code == status.HTTP_200_OK
    updated = upd_resp.json()
    assert updated["name"] == "Caixa c/ 12 unidades"
    assert updated["quantity_in_base_units"] == 12000

    # Tentar atualizar fator para negativo deve falhar
    bad_upd = client.put(f"/api/v1/packagings/{pack_id}", json={
        "quantity_in_base_units": -100,
    }, headers=headers)
    assert bad_upd.status_code in (status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY, 422)


def test_soft_delete_packaging(client, authenticated_device):
    _, _, headers = authenticated_device
    prod_resp = client.post("/api/v1/products", json={
        "name": "Esponja Dupla Face",
        "category": "LIMPEZA",
        "base_unit": "UNIT",
    }, headers=headers)
    prod_id = prod_resp.json()["id"]

    p = client.post(f"/api/v1/products/{prod_id}/packagings", json={
        "name": "Pacote c/ 3 un",
        "quantity_in_base_units": 3,
    }, headers=headers).json()
    pack_id = p["id"]

    # Inativar embalagem (soft delete)
    del_resp = client.delete(f"/api/v1/packagings/{pack_id}", headers=headers)
    assert del_resp.status_code == status.HTTP_200_OK
    assert del_resp.json()["is_active"] is False

    # Verificar que persiste inativa
    list_resp = client.get(f"/api/v1/products/{prod_id}/packagings", headers=headers)
    pack_found = next(it for it in list_resp.json() if it["id"] == pack_id)
    assert pack_found["is_active"] is False


def test_packaging_for_nonexistent_product_returns_404(client, authenticated_device):
    _, _, headers = authenticated_device
    resp = client.post("/api/v1/products/inexistente/packagings", json={
        "name": "Caixa 10",
        "quantity_in_base_units": 10,
    }, headers=headers)
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_unauthenticated_packaging_rejected(client):
    resp = client.get("/api/v1/products/123/packagings")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_reject_packaging_creation_for_inactive_product(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod Inativo Packaging",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    # Inativa o produto
    client.delete(f"/api/v1/products/{pid}", headers=headers)

    # Tenta cadastrar embalagem para produto inativo
    bad_pack = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Fardo 10kg",
        "quantity_in_base_units": 10000,
    }, headers=headers)
    assert bad_pack.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativo" in bad_pack.json()["detail"].lower()


def test_reject_inactive_packaging_as_default(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod Inactive Default",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    # Tenta criar embalagem inativa como padrao
    bad_create = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Fardo Inativo Padrao",
        "quantity_in_base_units": 5000,
        "is_default": True,
        "is_active": False,
    }, headers=headers)
    assert bad_create.status_code == status.HTTP_400_BAD_REQUEST
    assert "inativa" in bad_create.json()["detail"].lower()


def test_inactivate_packaging_removes_default_flag(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod Pack Default Reset",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    pkg = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Fardo Padrao",
        "quantity_in_base_units": 10000,
        "is_default": True,
    }, headers=headers).json()
    pkg_id = pkg["id"]

    # Inativa a embalagem
    del_resp = client.delete(f"/api/v1/packagings/{pkg_id}", headers=headers)
    assert del_resp.status_code == status.HTTP_200_OK
    data = del_resp.json()
    assert data["is_active"] is False
    assert data["is_default"] is False


def test_list_packagings_filter_by_active(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod List Filter",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()
    pid = p["id"]

    p1 = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Ativa 1",
        "quantity_in_base_units": 1000,
        "is_active": True,
    }, headers=headers).json()

    p2 = client.post(f"/api/v1/products/{pid}/packagings", json={
        "name": "Inativa 1",
        "quantity_in_base_units": 2000,
        "is_active": False,
    }, headers=headers).json()

    # Listar apenas ativas
    r_act = client.get(f"/api/v1/products/{pid}/packagings?is_active=true", headers=headers)
    assert r_act.status_code == status.HTTP_200_OK
    items_act = r_act.json()
    assert len(items_act) == 1
    assert items_act[0]["id"] == p1["id"]

    # Listar apenas inativas
    r_inact = client.get(f"/api/v1/products/{pid}/packagings?is_active=false", headers=headers)
    assert r_inact.status_code == status.HTTP_200_OK
    items_inact = r_inact.json()
    assert len(items_inact) == 1
    assert items_inact[0]["id"] == p2["id"]


def test_packaging_whitespace_name_rejected_with_422(client, authenticated_device):
    _, _, headers = authenticated_device
    p = client.post("/api/v1/products", json={
        "name": "Prod Pack WS Name",
        "category": "ALIMENTACAO",
        "base_unit": "G",
    }, headers=headers).json()

    resp = client.post(f"/api/v1/products/{p['id']}/packagings", json={
        "name": "   ",
        "quantity_in_base_units": 1000,
    }, headers=headers)
    assert resp.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
