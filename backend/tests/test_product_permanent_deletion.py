import pytest
from app.models.products import BasketType, RecipeVersion, RecipeItem
from app.models.purchases import Purchase, PurchaseItem
from app.models.production import ProductionBatch, ProductionBatchItem
from app.models.movements import InventoryMovement


def create_product(client, headers):
    response = client.post('/api/v1/products', headers=headers,
        json={'name': 'Produto de teste', 'category': 'ALIMENTACAO', 'base_unit': 'UNIT'})
    assert response.status_code == 201
    return response.json()['id']


def test_delete_unused_product_and_packagings_with_idempotent_replay(client, authenticated_device):
    _, _, headers = authenticated_device
    product_id = create_product(client, headers)
    response = client.post(f'/api/v1/products/{product_id}/packagings', headers=headers,
        json={'name': 'Caixa com 12', 'quantity_in_base_units': 12, 'is_default': True})
    packaging_id = response.json()['id']
    assert client.get(f'/api/v1/products/{product_id}/deletion-check', headers=headers).json()['can_delete']
    deletion_headers = {**headers, 'X-Idempotency-Key': 'unused-product-delete'}
    endpoint = f'/api/v1/products/{product_id}/permanent'
    first = client.delete(endpoint, headers=deletion_headers)
    assert first.status_code == 200, first.text
    assert first.json()['deleted'] is True
    assert first.json()['removed_packagings_count'] == 1
    replay = client.delete(endpoint, headers=deletion_headers)
    assert replay.status_code == 200 and replay.json() == first.json()
    assert client.get(f'/api/v1/products/{product_id}', headers=headers).status_code == 404
    assert client.put(f'/api/v1/packagings/{packaging_id}', json={'name': 'Novo'}, headers=headers).status_code == 404


def test_soft_delete_remains_compatible_and_unused_inactive_product_can_be_deleted(client, authenticated_device):
    _, _, headers = authenticated_device
    product_id = create_product(client, headers)
    inactive = client.delete(f'/api/v1/products/{product_id}', headers=headers)
    assert inactive.status_code == 200 and inactive.json()['is_active'] is False
    assert client.get(f'/api/v1/products/{product_id}', headers=headers).status_code == 200
    deleted = client.delete(f'/api/v1/products/{product_id}/permanent', headers=headers)
    assert deleted.status_code == 200


@pytest.mark.parametrize('reference,reason', [
    ('recipe', 'RECIPES'), ('purchase', 'PURCHASES'),
    ('production', 'PRODUCTION'), ('zero_stock', 'MOVEMENTS'),
])
def test_any_history_blocks_deletion_even_after_a_prior_unused_check(
    client, authenticated_device, test_session, reference, reason
):
    _, _, headers = authenticated_device
    product_id = create_product(client, headers)
    check_endpoint = f'/api/v1/products/{product_id}/deletion-check'
    assert client.get(check_endpoint, headers=headers).json()['can_delete'] is True
    if reference in ['recipe', 'production']:
        test_session.add(BasketType(id='basket-delete-test', code='DELETE_TEST', name='Cesta antiga'))
        test_session.flush()
    if reference == 'recipe':
        test_session.add(RecipeVersion(id='recipe-delete-test', basket_type_id='basket-delete-test',
                                      version_number=1, status='INACTIVE'))
        test_session.flush()
        test_session.add(RecipeItem(id='recipe-item-delete-test', recipe_version_id='recipe-delete-test',
            product_id=product_id, quantity_in_base_units=1, section='ALIMENTACAO'))
    elif reference == 'purchase':
        test_session.add(Purchase(id='purchase-delete-test', purchase_number=1, status='DRAFT'))
        test_session.flush()
        test_session.add(PurchaseItem(id='purchase-item-delete-test', purchase_id='purchase-delete-test',
            product_id=product_id, packages_count=1, quantity_in_base_units=1,
            unit_price_cents=100, total_price_cents=100))
    elif reference == 'production':
        test_session.add(ProductionBatch(id='batch-delete-test', batch_number=1,
            basket_type_id='basket-delete-test', quantity_produced=1, status='CANCELED'))
        test_session.flush()
        test_session.add(ProductionBatchItem(id='batch-item-delete-test', batch_id='batch-delete-test',
            product_id=product_id, quantity_consumed_base_units=1, section='ALIMENTACAO'))
    else:
        for index, quantity in enumerate([1, -1]):
            test_session.add(InventoryMovement(id=f'movement-delete-{index}', item_type='PRODUCT',
                product_id=product_id, quantity_delta=quantity, movement_type='ADJUSTMENT',
                source_type='ADJUSTMENT', source_id=f'adjustment-{index}'))
    test_session.commit()
    check = client.get(check_endpoint, headers=headers).json()
    if reference in ('production', 'zero_stock'):
        assert check['can_delete'] is True
        response = client.delete(f'/api/v1/products/{product_id}/permanent', headers=headers)
        assert response.status_code == 200 and response.json()['deletion_mode'] == 'CATALOG_ONLY'
        return
    assert check['can_delete'] is False and reason in check['reasons']
    response = client.delete(f'/api/v1/products/{product_id}/permanent', headers=headers)
    assert response.status_code == 409, response.text
    assert response.json()['detail']['error_code'] == 'PRODUCT_HAS_HISTORY'
    # Failed deletion cannot inactivate the product or remove any of its history.
    retained = client.get(f'/api/v1/products/{product_id}', headers=headers)
    assert retained.status_code == 200 and retained.json()['is_active'] is True


def test_deleting_missing_product_returns_not_found(client, authenticated_device):
    _, _, headers = authenticated_device
    assert client.delete('/api/v1/products/missing/permanent', headers=headers).status_code == 404
