import pytest


@pytest.mark.parametrize("endpoint", ["preview", "batches"])
@pytest.mark.parametrize("direct_sale", [False, True])
def test_disabled_customization_rejects_preview_and_creation(client, authenticated_device, endpoint, direct_sale):
    _, _, headers = authenticated_device
    basket = client.post('/api/v1/basket-types', headers=headers, json={
        'code': 'CUSTOM_OFF', 'name': 'Cesta sem personalizacao',
        'allows_customization': False,
    }).json()
    response = client.post(f'/api/v1/production/{endpoint}', headers=headers, json={
        'basket_type_id': basket['id'], 'quantity_produced': 1,
        'is_custom': True, 'is_direct_sale': direct_sale,
        'custom_description': 'Teste',
        'custom_items': [{'product_id': 'unused', 'quantity_in_base_units': 1}],
    })
    assert response.status_code == 409
    assert response.json()['detail']['error_code'] == 'CUSTOMIZATION_DISABLED'
    history = client.get(f"/api/v1/production/batches?basket_type_id={basket['id']}", headers=headers).json()
    assert history['total'] == 0


def test_customization_disabled_after_review_preserves_stock_and_recipe(client, authenticated_device):
    _, _, headers = authenticated_device
    product = client.post('/api/v1/products', headers=headers, json={
        'name': 'Sabonete', 'category': 'LIMPEZA', 'base_unit': 'UN',
    }).json()
    client.post('/api/v1/purchases', headers=headers, json={
        'items': [{'product_id': product['id'], 'packages_count': 10, 'unit_price_cents': 100}],
    })
    basket = client.post('/api/v1/basket-types', headers=headers, json={
        'code': 'CUSTOM_RACE', 'name': 'Cesta editavel', 'allows_customization': True,
    }).json()
    recipe_url = f"/api/v1/basket-types/{basket['id']}/recipes"
    recipe = client.post(recipe_url, headers=headers, json={
        'items': [{'product_id': product['id'], 'quantity_in_base_units': 1, 'section': 'LIMPEZA'}],
    }).json()
    payload = {'basket_type_id': basket['id'], 'quantity_produced': 2,
               'is_custom': True, 'custom_description': 'Dois sabonetes por cesta',
               'custom_items': [{'product_id': product['id'], 'quantity_in_base_units': 2, 'section': 'LIMPEZA'}]}
    preview = client.post('/api/v1/production/preview', headers=headers, json=payload)
    assert preview.status_code == 200
    assert preview.json()['can_produce'] is True
    assert preview.json()['items'][0]['quantity_required'] == 4
    disabled = client.put(f"/api/v1/basket-types/{basket['id']}", headers=headers, json={'allows_customization': False})
    assert disabled.status_code == 200
    rejected = client.post('/api/v1/production/batches', headers=headers, json=payload)
    assert rejected.status_code == 409
    assert rejected.json()['detail']['error_code'] == 'CUSTOMIZATION_DISABLED'
    stock = client.get(f"/api/v1/inventory/products/{product['id']}/stock", headers=headers).json()
    assert stock['current_stock'] == 10
    assert client.get(recipe_url, headers=headers).json()[0]['items'] == recipe['items']
