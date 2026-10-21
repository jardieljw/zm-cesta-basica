"""Real API journeys: undo operations, resolve dependencies, then remove catalog entries."""
import uuid
from sqlalchemy import select, func
from app.models.products import Product, RecipeVersion
from app.models.movements import InventoryMovement


def setup_catalog(client, headers):
    p = client.post('/api/v1/products', headers=headers, json=dict(
        name='Arroz', category='ALIMENTACAO', base_unit='UNIT')).json()
    b = client.post('/api/v1/basket-types', headers=headers, json=dict(
        code='PADRAO', name='Cesta padrão', default_price_cents=15000)).json()
    payload = dict(suggested_price_cents=16000,
        items=[dict(product_id=p['id'], quantity_in_base_units=1)])
    r = client.post(f"/api/v1/basket-types/{b['id']}/recipes", headers=headers, json=payload)
    assert r.status_code == 201, r.text
    return p, b, r.json(), payload


def stock(db, product_id, qty):
    db.add(InventoryMovement(id=str(uuid.uuid4()), item_type='PRODUCT', product_id=product_id,
        quantity_delta=qty, movement_type='ADJUSTMENT', source_type='ADJUSTMENT', source_id=str(uuid.uuid4())))
    db.commit()


def assemble(client, headers, basket_id, quantity=2):
    r = client.post('/api/v1/production/batches', headers=headers,
        json=dict(basket_type_id=basket_id, quantity_produced=quantity))
    assert r.status_code == 201, r.text
    return r.json()


def test_two_unsold_baskets_can_be_undone_then_catalog_removed(client, authenticated_device, test_session):
    _, _, h = authenticated_device
    p,b,r,_ = setup_catalog(client,h)
    stock(test_session,p['id'],2)
    batch = assemble(client,h,b['id'])
    check = client.get(f"/api/v1/basket-types/{b['id']}/deletion-check",headers=h).json()
    assert not check['can_delete']
    assert any(x['target'].get('batch_id') == batch['id'] for x in check['blockers'])
    rp = f"/api/v1/basket-types/{b['id']}/recipes/1"
    assert client.delete(rp,headers=h).status_code == 409
    endpoint = f"/api/v1/production/batches/{batch['id']}/disassemble"
    before = test_session.scalar(select(func.count()).select_from(InventoryMovement))
    test_session.rollback()
    preview = client.post(f"/api/v1/production/batches/{batch['id']}/disassembly-preview",headers=h,
        json=dict(quantity_to_disassemble=1, reason='Conferir antes de desmontar'))
    assert preview.status_code == 200, preview.text
    assert preview.json()['items'][0]['quantity_returned_base_units'] == 1
    assert test_session.scalar(select(func.count()).select_from(InventoryMovement)) == before
    test_session.rollback()
    assert client.get(f"/api/v1/production/batches/{batch['id']}",headers=h).json()['status'] == 'CONFIRMED'
    hkey = {**h,'X-Idempotency-Key':'undo-two'}
    first = client.post(endpoint,headers=hkey,json=dict(quantity_to_disassemble=2,reason='Montagem desfeita'))
    assert first.status_code == 200, first.text
    assert client.post(endpoint,headers=hkey,json=dict(quantity_to_disassemble=2,reason='Montagem desfeita')).json() == first.json()
    assert client.get(f"/api/v1/inventory/baskets/{b['id']}/stock",headers=h).json()['current_stock'] == 0
    test_session.expire_all()
    assert test_session.scalar(select(func.sum(InventoryMovement.quantity_delta)).where(
        InventoryMovement.product_id==p['id'])) == 2
    test_session.rollback()
    assert client.delete(rp,headers=h).status_code == 200
    assert client.get(f"/api/v1/basket-types/{b['id']}/recipes",headers=h).json() == []
    assert client.delete(f"/api/v1/basket-types/{b['id']}/catalog",headers=h).status_code == 200
    # Real remaining stock is a separate, explicit blocker, never silently discarded.
    check = client.get(f"/api/v1/products/{p['id']}/deletion-check",headers=h).json()
    assert check['reasons'] == ['STOCK_REMAINS']
    stock(test_session,p['id'],-2)
    removed = client.delete(f"/api/v1/products/{p['id']}/permanent",headers=h)
    assert removed.status_code == 200, removed.text
    assert removed.json()['deletion_mode'] == 'CATALOG_ONLY'
    assert client.get('/api/v1/products',headers=h).json() == []
    test_session.expire_all()
    assert test_session.get(Product,p['id']).removed_at is not None
    test_session.rollback()
    # The historical batch and its ingredients remain fully readable.
    detail=client.get(f"/api/v1/production/batches/{batch['id']}",headers=h)
    assert detail.status_code==200 and detail.json()['items'][0]['product_name']=='Arroz'


def test_active_sale_protects_recipe_until_canceled_and_assembly_undone(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,r,payload=setup_catalog(client,h)
    stock(test_session,p['id'],2)
    sale=client.post('/api/v1/sales',headers=h,json=dict(payment_mode='CASH_IMMEDIATE',
        customer_name='Maria',items=[dict(basket_type_id=b['id'],quantity=2,
            unit_price_cents=16000,assemble_on_demand=True)]))
    assert sale.status_code==201,sale.text
    sale=sale.json()
    rp=f"/api/v1/basket-types/{b['id']}/recipes/1"
    for method in ('delete','put'):
        response=getattr(client,method)(rp,headers=h,**({'json':payload} if method=='put' else {}))
        assert response.status_code==409,response.text
        assert any('Maria' in x['label'] and x['target'].get('sale_id')==sale['id']
            for x in response.json()['detail']['blockers'])
    # Same basket type, another composition/price; original sale stays unchanged.
    new=client.post(f"/api/v1/basket-types/{b['id']}/recipes",headers={**h,'X-Idempotency-Key':'new-recipe'},
        json={**payload,'suggested_price_cents':17500})
    assert new.status_code==201,new.text
    assert client.post(f"/api/v1/basket-types/{b['id']}/recipes",headers={**h,'X-Idempotency-Key':'new-recipe'},
        json={**payload,'suggested_price_cents':17500}).json()==new.json()
    # A sale tied to recipe 1 does not freeze an unused alternative recipe 2.
    assert client.put(f"/api/v1/basket-types/{b['id']}/recipes/2",headers=h,
        json={**payload,'suggested_price_cents':17700}).status_code==200
    assert client.get(f"/api/v1/sales/{sale['id']}",headers=h).json()['items'][0]['unit_price_cents']==16000
    canceled=client.post(f"/api/v1/sales/{sale['id']}/cancel",headers=h,
        json=dict(reason='Venda cancelada',unassembled_item_ids=[sale['items'][0]['id']]))
    assert canceled.status_code==200,canceled.text
    assert client.delete(rp,headers=h).status_code==200
    assert client.get(rp,headers=h).json()['status']=='REMOVED'
    assert client.get(f"/api/v1/sales/{sale['id']}",headers=h).json()['status']=='CANCELED'


def test_recipe_edit_and_switch_same_type_price_without_rewriting_batches(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,r,payload=setup_catalog(client,h)
    base=f"/api/v1/basket-types/{b['id']}/recipes"
    edited=client.put(base+'/1',headers=h,json={**payload,'suggested_price_cents':18000})
    assert edited.status_code==200,edited.text
    assert edited.json()['version_number']==1
    stock(test_session,p['id'],2)
    batch=assemble(client,h,b['id'])
    undone=client.post(f"/api/v1/production/batches/{batch['id']}/disassemble",headers=h,
        json=dict(reason='Teste de composição',quantity_to_disassemble=2))
    assert undone.status_code==200,undone.text
    edited=client.put(base+'/1',headers=h,json={**payload,'suggested_price_cents':19000,
        'items':[dict(product_id=p['id'],quantity_in_base_units=2)]})
    assert edited.status_code==200,edited.text
    assert edited.json()['version_number']==2
    assert client.get(base+'/1',headers=h).json()['items'][0]['quantity_in_base_units']==1
    new=client.post(base,headers=h,json=payload).json()
    activated=client.post(base+'/2/activate',headers=h)
    assert activated.status_code==200,activated.text
    assert client.get(base+'/active',headers=h).json()['version_number']==2
    assert client.post(base+'/2/deactivate',headers=h).status_code==200
    assert client.get(base+'/active',headers=h).status_code==404


def test_another_uncanceled_sale_keeps_recipe_protected(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,_,_=setup_catalog(client,h)
    stock(test_session,p['id'],2)
    sales=[]
    for _ in range(2):
        response=client.post('/api/v1/sales',headers=h,json=dict(items=[dict(
            basket_type_id=b['id'],quantity=1,unit_price_cents=100,assemble_on_demand=True)]))
        assert response.status_code==201,response.text
        sales.append(response.json())
    sale=sales[0]
    assert client.post(f"/api/v1/sales/{sale['id']}/cancel",headers=h,
        json=dict(reason='Cancelar uma venda',unassembled_item_ids=[sale['items'][0]['id']])).status_code==200
    response=client.delete(f"/api/v1/basket-types/{b['id']}/recipes/1",headers=h)
    assert response.status_code==409
    assert any(x['target'].get('sale_id')==sales[1]['id'] for x in response.json()['detail']['blockers'])


def test_cancel_block_formats_receipt_in_reais_and_points_to_exact_title(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,_,_=setup_catalog(client,h)
    stock(test_session,p['id'],1)
    customer=client.post('/api/v1/customers',headers=h,json=dict(name='Maria')).json()
    sale=client.post('/api/v1/sales',headers=h,json=dict(customer_id=customer['id'],
        payment_mode='CREDIT_TERM',items=[dict(basket_type_id=b['id'],quantity=1,
        unit_price_cents=15000,assemble_on_demand=True)]))
    assert sale.status_code==201,sale.text
    sale=sale.json()
    receivable_id=sale['receivable_id']
    paid=client.post(f'/api/v1/receivables/{receivable_id}/payments',headers=h,
        json=dict(amount_cents=15000,payment_method='PIX'))
    assert paid.status_code==201,paid.text
    cancel=client.post(f"/api/v1/sales/{sale['id']}/cancel",headers=h,json=dict(reason='Cancelar venda'))
    assert cancel.status_code==400,cancel.text
    detail=cancel.json()['detail']
    assert detail['error_code']=='SALE_HAS_RECEIPTS' and detail['receivable_id']==receivable_id
    assert 'R$ 150,00' in detail['message'] and 'centavos' not in detail['message']
    assert client.get(f"/api/v1/sales/{sale['id']}",headers=h).json()['status']=='CONFIRMED'


def test_ready_stock_sale_does_not_protect_a_recipe_created_after_it(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,_,payload=setup_catalog(client,h)
    stock(test_session,p['id'],2)
    assemble(client,h,b['id'])
    sale=client.post('/api/v1/sales',headers=h,json=dict(items=[dict(
        basket_type_id=b['id'],quantity=1,unit_price_cents=15000)]))
    assert sale.status_code==201,sale.text
    base=f"/api/v1/basket-types/{b['id']}/recipes"
    assert client.post(base,headers=h,json=payload).status_code==201
    assert client.get(base+'/2/deletion-check',headers=h).json()['can_modify'] is True
    assert client.delete(base+'/2',headers=h).status_code==200
    protected=client.get(base+'/1/deletion-check',headers=h).json()
    assert any(x['target'].get('sale_id')==sale.json()['id'] for x in protected['blockers'])


def test_another_recipe_ready_stock_cannot_return_ingredients_from_sold_composition(client, authenticated_device, test_session):
    _,_,h=authenticated_device
    p,b,_,payload=setup_catalog(client,h)
    stock(test_session,p['id'],4)
    first=assemble(client,h,b['id'])
    sale=client.post('/api/v1/sales',headers=h,json=dict(items=[dict(
        basket_type_id=b['id'],quantity=2,unit_price_cents=15000)]))
    assert sale.status_code==201,sale.text
    changed={**payload,'items':[dict(product_id=p['id'],quantity_in_base_units=2)]}
    assert client.post(f"/api/v1/basket-types/{b['id']}/recipes",headers=h,json=changed).status_code==201
    second=assemble(client,h,b['id'],quantity=1)
    data=dict(reason='Desmontar composição',quantity_to_disassemble=1)
    blocked=client.post(f"/api/v1/production/batches/{first['id']}/disassemble",headers=h,json=data)
    assert blocked.status_code==409,blocked.text
    assert blocked.json()['detail']['error_code']=='ASSEMBLY_RECIPE_STOCK_UNCERTAIN'
    assert any(x['target'].get('sale_id')==sale.json()['id'] for x in blocked.json()['detail']['blockers'])
    assert client.post(f"/api/v1/production/batches/{second['id']}/disassemble",headers=h,json=data).status_code==200
