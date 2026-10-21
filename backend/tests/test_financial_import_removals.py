"""Import withdrawal, truthful UI contracts, replay, dependencies and reimport."""
import uuid
import sqlite3
import pytest
from test_financial_bill_cycles import api, bill, integrate, payment
from test_financial_imports import books
from test_financial_installments import agenda, next_bill, resolve
from test_financial_e3 import summary, command


def removal_plan(api, p):
    return api.get('/documents/'+p['document_id']+'/removal?import_id='+p['import_id']+
        '&expected_generation='+str(p['generation']))


def remove(api, p, plan=None, **kw):
    plan = plan or removal_plan(api,p)
    return api.post('/documents/'+p['document_id']+'/remove', {'import_id':p['import_id'],
        'expected_generation':p['generation'],'expected_snapshot':plan['snapshot']}, **kw)


def test_remove_unpaid_import_hides_its_title_forecasts_and_document_without_cash_changes(api,test_db_path):
    p,c = bill(api)
    cycle = integrate(api,p,c)
    before = books(test_db_path)
    plan = removal_plan(api,p)
    assert plan['can_remove'] and len(plan['payables'])==1 and plan['series_count']==1
    key=str(uuid.uuid4())
    first=remove(api,p,plan,key=key)
    assert remove(api,p,plan,key=key)==first
    assert remove(api,p,plan,expected=(409,))['detail']['error_code']=='FINANCIAL_IMPORT_GENERATION_CONFLICT'
    assert api.get('/previews')==[] and api.get('/statements')==[]
    assert api.client.get('/api/v1/payables',headers=api.headers).json()==[]
    assert api.client.get('/api/v1/payables/summary',headers=api.headers).json()['open_cents']==0
    assert agenda(api)['items']==[] and agenda(api)['pending_links']==[]
    after=books(test_db_path)
    for table in ['cash_flow_entries','inventory_movements','payable_payments']:
        assert before[table]==after[table]
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('select count(*) from financial_documents').fetchone()[0]==1
        assert db.execute('select count(*) from financial_bill_cycle_revisions').fetchone()[0]==1
        assert db.execute('select status,balance_cents from accounts_payable').fetchone()==('CANCELED',0)
    denied=integrate(api,p,{**c,'expected_revision':1},expected=(409,))
    assert denied['detail']['error_code']=='FINANCIAL_IMPORT_GENERATION_CONFLICT'


def test_replayed_upload_keeps_removed_until_new_read_and_explicit_confirmation(api,test_db_path):
    source=api.source('CREDIT_CARD')
    content=b'date,title,amount\n2026-10-01,Loja A - 3/10,"100,00"\n'
    upload_key=str(uuid.uuid4())
    doc=api.document(content,key=upload_key)['document']
    p=api.post('/documents/'+doc['id']+'/previews',{'source_id':source['id'],'currency':'BRL','reader_id':'csv_auto','expected_generation':0})['preview']
    c=command(p);c['total_amount_cents']=10000
    first=integrate(api,p,c)
    remove(api,p)
    assert api.document(content,key=upload_key)['document']['id']==doc['id']
    assert api.document(content,key=upload_key)['document']['id']==doc['id']
    assert api.get('/previews')==[]
    from test_financial_import_lifecycle import read
    p=read(api,source,content)
    draft=api.get('/previews/'+p['id']+'/bill-integration?import_id='+p['import_id']+'&expected_generation='+str(p['generation']))
    assert draft['cycle']['import_withdrawn']
    assert api.client.get('/api/v1/payables',headers=api.headers).json()==[]
    restored=integrate(api,p,{**c,'expected_revision':1})
    assert restored['payable_id']==first['payable_id'] and restored['revision']==2
    assert not restored['import_withdrawn'] and restored['balance_cents']==10000
    assert len(api.client.get('/api/v1/payables',headers=api.headers).json())==1
    assert agenda(api)['estimated_cents']==70000
    assert remove(api,p)['removed']
    assert api.document(content,key=upload_key)['document']['id']==doc['id']
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('select count(*) from financial_documents').fetchone()[0]==1
        assert db.execute('select max(generation) from financial_import_entries').fetchone()[0]==2
        assert db.execute('select count(*) from financial_import_removals').fetchone()[0]==0


def test_payment_blocks_removal_stale_plan_cannot_discard_a_new_payment_and_reversal_allows_it(api):
    p,c=bill(api);result=integrate(api,p,c);stale=removal_plan(api,p)
    paid=payment(api,result['payable_id'],1000)
    current=removal_plan(api,p)
    assert not current['can_remove']
    assert current['blocked'][0]['code']=='PAYMENT_EXISTS'
    assert current['blocked'][0]['payable_id']==result['payable_id']
    assert remove(api,p,stale,expected=(409,))['detail']['error_code']=='FINANCIAL_IMPORT_REMOVAL_CHANGED'
    assert remove(api,p,current,expected=(409,))['detail']['error_code']=='FINANCIAL_IMPORT_REMOVAL_BLOCKED'
    assert api.get('/previews')
    response=api.client.post('/api/v1/payables/payments/'+paid['id']+'/cancel',json={'reason':'Pagamento sintético lançado por engano'},headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert response.status_code==200
    assert remove(api,p)['removed']


@pytest.mark.parametrize('destination',['PENDING','HISTORY'])
def test_evidence_only_import_removal_does_not_create_or_cancel_other_titles(api,destination):
    p,c=bill(api,destination=destination);integrate(api,p,c)
    assert removal_plan(api,p)['payables']==[]
    assert remove(api,p)['removed']
    assert agenda(api)['items']==[]


def test_enrichment_dependency_is_identified_and_both_documents_can_be_removed_in_order(api):
    source=api.source('CREDIT_CARD');p,c=bill(api,source=source);integrate(api,p,c)
    parent,s=summary(api,source)
    integrate(api,s,{**command(s),'expected_revision':1})
    plan=removal_plan(api,p)
    assert not plan['can_remove']
    assert any(b.get('document_id')==s['document_id'] for b in plan['blocked'])
    # Removing a later summary withdraws the shared cycle, retaining its evidence.
    assert remove(api,s)['removed']
    assert remove(api,p)['removed']
    assert agenda(api)['items']==[]


def test_later_installment_document_must_be_removed_first_and_previous_estimates_return(api):
    p,c=bill(api);integrate(api,p,c)
    second=next_bill(api,{'id':c['expected_source_id'],'currency':'BRL'},amount=10000)
    state=agenda(api);pending=state['pending_links'][0]
    resolve(api,pending,series=pending['candidates'][0]['series_id'])
    assert agenda(api)['estimated_cents']==60000
    assert not removal_plan(api,p)['can_remove']
    second_preview=api.get('/previews/'+second['preview_id'])
    assert remove(api,second_preview)['removed']
    assert agenda(api)['estimated_cents']==70000
    assert remove(api,p)['removed'] and agenda(api)['items']==[]


def test_atomic_failure_rolls_back_cancellation_and_visibility(api,monkeypatch):
    from app.services import financial_imports
    p,c=bill(api);result=integrate(api,p,c)
    original=financial_imports.audit
    def rejected(db,actor,event,obj,details=None):
        if event=='IMPORT_REMOVED':
            raise RuntimeError('synthetic audit failure')
        return original(db,actor,event,obj,details)
    monkeypatch.setattr(financial_imports,'audit',rejected)
    with pytest.raises(RuntimeError,match='synthetic audit failure'):
        remove(api,p)
    assert api.get('/previews')
    title=api.client.get('/api/v1/payables/'+result['payable_id'],headers=api.headers).json()
    assert title['status']=='OPEN' and title['balance_cents']==13000
    assert removal_plan(api,p)['can_remove']


def test_bank_statement_removal_hides_only_its_evidence_preserving_money_and_other_imports(api,test_db_path):
    source=api.source('BANK_ACCOUNT')
    from test_financial_readers import preview,confirm
    p,_,_=preview(api,source,b'Data;Valor;Descricao\n01/10/2026;-10,00;Movimento de teste\n')
    statement=confirm(api,p,period_start='2026-10-01',period_end='2026-10-01')['statement']
    items=api.get('/statements/'+statement['id']+'/items')
    transaction=api.review(items[0])['transaction']
    assert len(api.get('/transactions'))==1
    before=books(test_db_path)
    assert remove(api,p)['removed']
    assert api.get('/transactions')==[]
    assert api.get('/transactions?include_inactive=true')[0]['id']==transaction['id']
    after=books(test_db_path)
    assert before['cash_flow_entries']==after['cash_flow_entries']
    assert before['accounts_payable']==after['accounts_payable']


def test_removed_enrichment_does_not_prevent_reimporting_original_details(api):
    source=api.source('CREDIT_CARD');p,c=bill(api,source=source);first=integrate(api,p,c)
    parent,s=summary(api,source)
    integrate(api,s,{**command(s),'expected_revision':1})
    remove(api,s);remove(api,p)
    content=b'date,title,amount\n2026-10-01,Loja A - 3/10,"100,00"\n2026-10-01,Loja B,"50,00"\n2026-10-01,Estorno exemplo,"-20,00"\n'
    assert api.document(content)['document']['id']==p['document_id']
    from test_financial_import_lifecycle import read
    p=read(api,source,content)
    restored=integrate(api,p,{**c,'expected_revision':2})
    assert restored['payable_id']==first['payable_id'] and restored['balance_cents']==13000


def test_reimport_can_stay_saved_then_be_added_without_duplicate_bill(api):
    p,c=bill(api);first=integrate(api,p,c);remove(api,p)
    content=b'date,title,amount\n2026-10-01,Loja A - 3/10,"100,00"\n2026-10-01,Loja B,"50,00"\n2026-10-01,Estorno exemplo,"-20,00"\n'
    api.document(content)
    from test_financial_import_lifecycle import read
    p=read(api,{'id':p['source_id']},content)
    saved=integrate(api,p,{**c,'expected_revision':1,'destination':'HISTORY'})
    assert saved['payable_id'] is None and saved['destination']=='HISTORY'
    assert api.client.get('/api/v1/payables',headers=api.headers).json()==[]
    restored=integrate(api,p,{**c,'expected_revision':2})
    assert restored['payable_id']==first['payable_id'] and restored['balance_cents']==13000


def test_removing_carry_bill_restores_prior_balance_and_preserves_its_payment(api,test_db_path):
    p,c=bill(api,[('Compra anterior',5000)],total=5000,items=[{'position':1,'purpose':'BUSINESS'}])
    first=integrate(api,p,c);payment(api,first['payable_id'],2000)
    source={'id':c['expected_source_id'],'currency':'BRL'}
    p2,c2=bill(api,[('Saldo anterior',3000),('Compra nova',1000)],source=source,total=4000,
        reference='2026-11',due_on='2026-11-24',items=[{'position':2,'purpose':'BUSINESS'}],
        replacements=[{'payable_id':first['payable_id'],'kind':'PREVIOUS_BALANCE','expected_balance_cents':3000,'reason':'Saldo anterior conferido'}])
    second=integrate(api,p2,c2)
    assert any(b.get('document_id')==p2['document_id'] for b in removal_plan(api,p)['blocked'])
    plan=removal_plan(api,p2)
    assert plan['can_remove'] and plan['restored_payables'][0]['id']==first['payable_id']
    before=books(test_db_path)
    remove(api,p2,plan)
    prior=api.client.get('/api/v1/payables/'+first['payable_id'],headers=api.headers).json()
    assert prior['status']=='PARTIAL' and prior['paid_amount_cents']==2000 and prior['balance_cents']==3000
    assert prior['superseded_by_id'] is None
    after=books(test_db_path)
    assert after['cash_flow_entries']==before['cash_flow_entries'] and after['payable_payments']==before['payable_payments']
    content=b'date,title,amount\n2026-10-01,Saldo anterior,"30,00"\n2026-10-01,Compra nova,"10,00"\n'
    assert api.document(content)['document']['id']==p2['document_id']
    from test_financial_import_lifecycle import read
    p2=read(api,source,content)
    restored=integrate(api,p2,{**c2,'expected_revision':1})
    assert restored['payable_id']==second['payable_id'] and restored['balance_cents']==4000
    assert remove(api,p2)['removed']
    assert api.client.get('/api/v1/payables/'+first['payable_id'],headers=api.headers).json()['balance_cents']==3000


def test_removing_bill_restores_independent_purchase_without_touching_stock_or_payments(api,test_session,test_db_path):
    from app.models.purchases import Purchase
    purchase=Purchase(id=str(uuid.uuid4()),purchase_number=1,total_amount_cents=10000,payment_mode='CREDIT_TERM')
    test_session.add(purchase);test_session.commit()
    response=api.client.post('/api/v1/payables',json={'description':'Compra existente','beneficiary':'Fornecedor','category':'FORNECEDOR','purchase_id':purchase.id,'original_amount_cents':10000,'due_date':'2026-10-01T00:00:00'},headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert response.status_code==201
    title=response.json()[0];payment(api,title['id'],2000)
    p,c=bill(api,[('Compra no cartão',8000)],total=8000,replacements=[{'payable_id':title['id'],'kind':'PURCHASE','position':1,'expected_balance_cents':8000,'reason':'Compra já cadastrada'}])
    integrated=integrate(api,p,c)
    before=books(test_db_path)
    with sqlite3.connect(test_db_path) as db: purchase_before=db.execute('SELECT * FROM purchases ORDER BY id').fetchall()
    # A direct unrecorded reopen still violates the database guard.
    with sqlite3.connect(test_db_path) as db:
        with pytest.raises(sqlite3.IntegrityError):
            db.execute("UPDATE accounts_payable SET status='PARTIAL',superseded_by_id=NULL WHERE id=?",(title['id'],))
    assert remove(api,p)['removed']
    prior=api.client.get('/api/v1/payables/'+title['id'],headers=api.headers).json()
    assert prior['purchase_id']==purchase.id and prior['status']=='PARTIAL' and prior['balance_cents']==8000 and prior['paid_amount_cents']==2000
    after=books(test_db_path)
    for table in ['cash_flow_entries','payable_payments','inventory_movements']:
        assert after[table]==before[table]

    with sqlite3.connect(test_db_path) as db: assert db.execute('SELECT * FROM purchases ORDER BY id').fetchall()==purchase_before
