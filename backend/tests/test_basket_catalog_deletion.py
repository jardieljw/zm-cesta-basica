import uuid
import pytest
from sqlalchemy import select, text
from app.models.products import RecipeVersion, RecipeItem, BasketType
from app.models.movements import InventoryMovement


def setup_basket(client, headers):
    product = client.post('/api/v1/products', headers=headers, json={
        'name': 'Sabonete catalogo', 'base_unit': 'UN', 'category': 'LIMPEZA',
    }).json()
    basket = client.post('/api/v1/basket-types', headers=headers, json={
        'code': 'BASKET_DELETE', 'name': 'Cesta para testes',
    }).json()
    recipe = client.post(f"/api/v1/basket-types/{basket['id']}/recipes", headers=headers, json={
        'items': [{'product_id': product['id'], 'quantity_in_base_units': 1, 'section': 'LIMPEZA'}],
    }).json()
    return product, basket, recipe


def make_sale(client, headers, product, basket):
    purchase = client.post('/api/v1/purchases', headers=headers, json={
        'items': [{'product_id': product['id'], 'packages_count': 10, 'unit_price_cents': 100}],
    })
    assert purchase.status_code == 201
    response = client.post('/api/v1/sales', headers=headers, json={
        'payment_mode': 'CASH_IMMEDIATE', 'items': [{'basket_type_id': basket['id'],
        'quantity': 2, 'unit_price_cents': 500, 'assemble_on_demand': True}],
    })
    assert response.status_code == 201, response.text
    return response.json()


def test_unused_basket_and_recipes_delete_permanently_with_replay(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    product, basket, recipe = setup_basket(client, headers)
    check = client.get(f"/api/v1/basket-types/{basket['id']}/deletion-check", headers=headers).json()
    assert check['can_delete'] and check['deletion_mode'] == 'PERMANENT'
    endpoint = f"/api/v1/basket-types/{basket['id']}/catalog"
    deletion_headers = {**headers, 'X-Idempotency-Key': str(uuid.uuid4())}
    deleted = client.delete(endpoint, headers=deletion_headers)
    assert deleted.status_code == 200, deleted.text
    assert deleted.json()['removed_recipes_count'] == 1
    assert client.delete(endpoint, headers=deletion_headers).json() == deleted.json()
    assert client.get(f"/api/v1/basket-types/{basket['id']}", headers=headers).status_code == 404
    assert test_session.get(RecipeVersion, recipe['id']) is None
    assert test_session.scalar(select(RecipeItem.id).where(RecipeItem.recipe_version_id == recipe['id'])) is None
    assert test_session.execute(text('PRAGMA foreign_key_check')).all() == []
    test_session.rollback()
    assert client.get(f"/api/v1/products/{product['id']}", headers=headers).status_code == 200
    assert client.post('/api/v1/basket-types', headers=headers, json={'code': basket['code'], 'name': 'Nova cesta'}).status_code == 201


def test_canceled_unassembled_sale_can_remove_catalog_without_deleting_history(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    product, basket, recipe = setup_basket(client, headers)
    sale = make_sale(client, headers, product, basket)
    canceled = client.post(f"/api/v1/sales/{sale['id']}/cancel", headers=headers, json={
        'reason': 'Teste registrado por engano', 'unassembled_item_ids': [sale['items'][0]['id']],
    })
    assert canceled.status_code == 200, canceled.text
    movements_before = test_session.execute(select(InventoryMovement.id, InventoryMovement.quantity_delta)).all()
    test_session.rollback()
    check = client.get(f"/api/v1/basket-types/{basket['id']}/deletion-check", headers=headers).json()
    assert check['can_delete'] and check['deletion_mode'] == 'CATALOG_ONLY'
    endpoint = f"/api/v1/basket-types/{basket['id']}/catalog"
    removal_headers = {**headers, 'X-Idempotency-Key': str(uuid.uuid4())}
    removed = client.delete(endpoint, headers=removal_headers)
    assert removed.status_code == 200, removed.text
    assert removed.json()['deletion_mode'] == 'CATALOG_ONLY'
    assert client.delete(endpoint, headers=removal_headers).json() == removed.json()
    assert not client.get('/api/v1/basket-types', headers=headers).json()
    assert not client.get('/api/v1/basket-types?is_active=false', headers=headers).json()
    retained = client.get(f"/api/v1/basket-types/{basket['id']}", headers=headers).json()
    assert retained['removed_at'] is not None and retained['is_active'] is False
    assert retained['active_recipe']['id'] == recipe['id']
    assert client.get(f"/api/v1/sales/{sale['id']}", headers=headers).json()['status'] == 'CANCELED'
    assert test_session.execute(select(InventoryMovement.id, InventoryMovement.quantity_delta)).all() == movements_before
    assert test_session.execute(text('PRAGMA foreign_key_check')).all() == []
    test_session.rollback()
    edit = client.put(f"/api/v1/basket-types/{basket['id']}", headers=headers, json={'is_active': True})
    assert edit.status_code == 409 and edit.json()['detail']['error_code'] == 'BASKET_REMOVED'


@pytest.mark.parametrize('canceled', [False, True])
def test_sale_or_returned_ready_stock_blocks_catalog_removal(client, authenticated_device, canceled):
    _, _, headers = authenticated_device
    product, basket, _ = setup_basket(client, headers)
    # A previous advisory check cannot authorize deletion after new operations.
    assert client.get(f"/api/v1/basket-types/{basket['id']}/deletion-check", headers=headers).json()['can_delete']
    sale = make_sale(client, headers, product, basket)
    if canceled:
        response = client.post(f"/api/v1/sales/{sale['id']}/cancel", headers=headers, json={'reason': 'Cestas continuam montadas'})
        assert response.status_code == 200
    check = client.get(f"/api/v1/basket-types/{basket['id']}/deletion-check", headers=headers).json()
    assert check['can_delete'] is False
    assert ('STOCK_REMAINS' if canceled else 'ACTIVE_SALES') in check['reasons']
    deleted = client.delete(f"/api/v1/basket-types/{basket['id']}/catalog", headers=headers)
    assert deleted.status_code == 409
    assert deleted.json()['detail']['error_code'] == 'BASKET_DELETE_BLOCKED'
    assert client.get('/api/v1/basket-types', headers=headers).json()[0]['id'] == basket['id']


def test_zero_total_does_not_hide_custom_stock_in_another_location(client, authenticated_device, test_session):
    _, _, headers = authenticated_device
    _, basket, _ = setup_basket(client, headers)
    for index, (location, quantity) in enumerate([('STORE', 1), ('TRANSIT', -1)]):
        test_session.add(InventoryMovement(id=f'isolated-stock-{index}', item_type='BASKET',
            basket_type_id=basket['id'], quantity_delta=quantity, location_type=location,
            movement_type='ADJUSTMENT', source_type='ADJUSTMENT', source_id=f'adjust-{index}'))
    test_session.commit()
    check = client.get(f"/api/v1/basket-types/{basket['id']}/deletion-check", headers=headers).json()
    assert check['can_delete'] is False and 'STOCK_REMAINS' in check['reasons']
