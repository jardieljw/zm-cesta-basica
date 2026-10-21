"""E2 acceptance: exact net debt, neutral purpose, one cash event and safe replay."""
import datetime
import sqlite3
import uuid
import pytest
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
from app.models.financial import PayablePayment, AccountPayable, CashFlowEntry
from app.models.purchases import Purchase
from test_financial_imports import FinancialAPI, books
from test_financial_readers import preview
from test_financial_pdf import card_pdf, upload_preview


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def bill(api, rows=None, total=13000, source=None, **changes):
    source = source or api.source('CREDIT_CARD')
    rows = rows or [('Loja A - 3/10',10000), ('Loja B',5000), ('Estorno exemplo',-2000)]
    content = 'date,title,amount\n' + ''.join('2026-10-01,'+d+',"'+('-' if a<0 else '')+str(abs(a)//100)+','+str(abs(a)%100).zfill(2)+'"\n' for d,a in rows)
    p,doc,_ = preview(api,source,content.encode(),reader='csv_auto')
    command = {'expected_source_id':source['id'], 'expected_result_sha256':p['result_sha256'],
        'expected_revision':0, 'reference':'2026-10','due_on':'2026-10-24','total_amount_cents':total,
        'controls_confirmed':True,'destination':'OPEN','reason':'Conferido documento e saldo ainda aberto', **changes}
    return p,command


def integrate(api,p,data,**kwargs):
    return api.post('/previews/'+p['id']+'/integrate-bill',
        {'import_id':p['import_id'],'expected_generation':p['generation'],**data},**kwargs)


def payment(api,payable,amount,key=None):
    title=api.client.get('/api/v1/payables/'+payable,headers=api.headers).json()
    revision={'expected_bill_revision':title['financial_bill']['revision']} if title.get('financial_bill') else {}
    r=api.client.post('/api/v1/payables/'+payable+'/payments',json={'amount_cents':amount,'payment_method':'PIX',**revision},
        headers={**api.headers,'X-Idempotency-Key':key or str(uuid.uuid4())})
    assert r.status_code == 201,r.text
    return r.json()


def test_t05_t10_one_net_bill_all_items_exact_source_and_no_cash(api,test_db_path):
    before=books(test_db_path)
    p,data=bill(api)
    result=integrate(api,p,data)
    assert result['total_amount_cents']==13000 and result['balance_cents']==13000
    assert result['details_status']=='RECONCILED' and len(result['items'])==3
    assert result['items'][0]['installment_number']==3
    assert result['composition']['unclassified_cents']==13000
    assert result['financial_source']['id']==data['expected_source_id']
    prepared=api.get('/previews/'+p['id']+'/bill-integration?reference=2026-10')
    assert prepared['expected_revision']==1 and prepared['cycle']['payable_id']==result['payable_id']
    assert integrate(api,p,data)['duplicate']
    detail=api.client.get('/api/v1/payables/'+result['payable_id'],headers=api.headers).json()
    assert detail['nature']=='UNCLASSIFIED' and len(detail['financial_bill']['items'])==3
    after=books(test_db_path)
    assert after['cash_flow_entries']==before['cash_flow_entries']
    assert after['inventory_movements']==before['inventory_movements']
    assert len(after['accounts_payable'])==len(before['accounts_payable'])+1


@pytest.mark.parametrize('destination', ['PENDING','HISTORY'])
def test_t09_history_and_pending_do_not_create_debt(api,destination):
    p,data=bill(api,destination=destination)
    result=integrate(api,p,data)
    assert result['destination']==destination and result['payable_id'] is None
    if destination=='HISTORY':
        active=integrate(api,p,{**data,'destination':'OPEN','expected_revision':1})
        assert active['payable_id'] and active['balance_cents']==13000


@pytest.mark.parametrize('total', [0,-1000])
def test_t09_zero_credit_does_not_create_positive_debt_or_payment(api,total):
    rows=[('Loja A',1000),('Estorno exemplo',total-1000)]
    p,data=bill(api,rows,total=total)
    result=integrate(api,p,data)
    assert result['destination']=='CREDIT' and result['payable_id'] is None


def test_t06_one_cent_difference_requires_explicit_detail_pending(api):
    p,data=bill(api,[('Loja A',10001)],total=10000)
    assert integrate(api,p,data,expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_DETAILS_PENDING'
    result=integrate(api,p,{**data,'accept_details_pending':True})
    assert result['details_status']=='AVAILABLE_UNRECONCILED' and result['difference_cents']==1
    assert result['balance_cents']==10000 and len(result['items'])==1


def test_t06_pdf_declared_total_and_real_detail_difference_are_independent(api):
    p,_,_=upload_preview(api,api.source('CREDIT_CARD'),card_pdf(mismatch=True))
    data={'expected_source_id':p['source_id'],'expected_result_sha256':p['result_sha256'],'expected_revision':0,
        'reference':'2025-08','due_on':'2025-08-10','total_amount_cents':500,'controls_confirmed':True,
        'accept_details_pending':True,'destination':'OPEN','reason':'Total e saldo em aberto conferidos'}
    result=integrate(api,p,data)
    assert result['difference_cents']==1 and result['balance_cents']==500
    assert len(result['items'])==2


def test_t14_mixed_ambiguous_credit_is_unknown_and_reversal_exact(api,test_session):
    p,data=bill(api,items=[{'position':1,'purpose':'BUSINESS'},{'position':2,'purpose':'PERSONAL_WITHDRAWAL'}])
    result=integrate(api,p,data)
    key=str(uuid.uuid4())
    paid=payment(api,result['payable_id'],3001,key)
    assert paid['unclassified_cents']==3001 and paid['business_cents']==0
    assert payment(api,result['payable_id'],3001,key)['id']==paid['id']
    dashboard=api.client.get('/api/v1/dashboard/business-summary?filter_type=all',headers=api.headers).json()['financial']
    assert dashboard['operating_expenses_paid_cents']==0 and dashboard['unclassified_paid_cents']==3001
    response=api.client.post('/api/v1/payables/payments/'+paid['id']+'/cancel',json={'reason':'Estorno conferido'},
        headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert response.status_code==200,response.text
    fresh=api.client.get('/api/v1/payables/'+result['payable_id'],headers=api.headers).json()
    assert fresh['balance_cents']==13000
    dashboard=api.client.get('/api/v1/dashboard/business-summary?filter_type=all',headers=api.headers).json()['financial']
    assert dashboard['unclassified_paid_cents']==0


def test_t14_known_credit_largest_remainder_and_paid_enrichment_no_debt_restore(api):
    decisions=[{'position':1,'purpose':'BUSINESS'},{'position':2,'purpose':'PERSONAL_WITHDRAWAL'},{'position':3,'purpose':'BUSINESS'}]
    p,data=bill(api,items=decisions)
    first=integrate(api,p,data)
    paid=payment(api,first['payable_id'],1)
    assert paid['business_cents']==1 and paid['personal_cents']==0
    second=payment(api,first['payable_id'],12999)
    assert second['business_cents']==7999 and second['personal_cents']==5000
    # Different bytes/description enrich the same identity and preserve all payments.
    source={'id':data['expected_source_id'],'currency':'BRL'}
    p2,c2=bill(api,[('Loja A - 3/10',10000),('Loja B detalhe',5000),('Estorno exemplo',-2000)],source=source,items=decisions,expected_revision=1)
    enriched=integrate(api,p2,{**c2,'accept_content_change':True})
    assert enriched['payable_id']==first['payable_id'] and enriched['balance_cents']==0
    assert integrate(api,p2,{**c2,'expected_revision':0,'accept_content_change':True})['duplicate']
    denied=integrate(api,p2,{**c2,'expected_revision':2,'items':[{'position':i,'purpose':'UNSPECIFIED'} for i in (1,2,3)]},expected=(409,))
    assert denied['detail']['error_code']=='FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT'


def test_t15_revision_conflict_is_atomic_and_legacy_generator_cannot_duplicate(api,test_db_path):
    p,data=bill(api)
    result=integrate(api,p,data)
    before=books(test_db_path)
    denied=integrate(api,p,{**data,'reason':'Outra decisao no mesmo ciclo'},expected=(409,))
    assert denied['detail']['error_code']=='FINANCIAL_BILL_REVISION_CONFLICT'
    assert books(test_db_path)==before
    old=api.post('/statements/'+result['statement_id']+'/generate-obligations',{'expected_review_id':'none'},expected=(409,422))
    assert old['detail']


def test_t11_existing_purchase_remaining_balance_substituted_without_stock_or_cash(api,test_session,test_db_path):
    purchase=Purchase(id=str(uuid.uuid4()),purchase_number=1,total_amount_cents=10000,payment_mode='CREDIT_TERM')
    test_session.add(purchase);test_session.commit()
    r=api.client.post('/api/v1/payables',json={'description':'Compra existente','beneficiary':'Fornecedor',
        'category':'FORNECEDOR','purchase_id':purchase.id,'original_amount_cents':10000,'due_date':'2026-10-01T00:00:00'},
        headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert r.status_code==201,r.text
    old=r.json()[0]
    paid=payment(api,old['id'],2000)
    before=books(test_db_path)
    p,data=bill(api,[('Compra no cartao',8000)],total=8000,replacements=[{'payable_id':old['id'],
        'expected_balance_cents':8000,'kind':'PURCHASE','position':1,'reason':'Saldo integral desta compra conferido'}])
    result=integrate(api,p,data)
    replaced=api.client.get('/api/v1/payables/'+old['id'],headers=api.headers).json()
    assert replaced['status']=='SUBSTITUTED' and replaced['paid_amount_cents']==2000
    assert result['composition']['stock_cents']==8000
    after=books(test_db_path)
    assert after['cash_flow_entries']==before['cash_flow_entries'] and after['inventory_movements']==before['inventory_movements']
    rejected=api.client.post('/api/v1/payables/payments/'+paid['id']+'/cancel',json={'reason':'Nao pode reabrir saldo'},
        headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert rejected.status_code==409
    actual=payment(api,result['payable_id'],8000)
    assert actual['stock_cents']==8000 and actual['business_cents']==0


def test_t15_database_protects_item_revision_and_payment_snapshots(api,test_session):
    p,data=bill(api)
    result=integrate(api,p,data)
    paid=payment(api,result['payable_id'],100)
    for sql in ("UPDATE financial_bill_cycle_revisions SET total_cents=1", "DELETE FROM financial_bill_cycle_items", "UPDATE payable_payments SET unclassified_cents=0"):
        with pytest.raises(IntegrityError):
            test_session.execute(text(sql));test_session.flush()
        test_session.rollback()
    columns = [c.name for c in PayablePayment.__table__.columns]
    snapshot = {'bill_revision_id', 'stock_cents', 'business_cents', 'personal_cents', 'unclassified_cents'}
    values = [':new_id' if c == 'id' else 'NULL' if c in snapshot else c for c in columns]
    with pytest.raises(IntegrityError, match='invalid payment bill revision'):
        test_session.execute(text('INSERT INTO payable_payments ('+','.join(columns)+') SELECT '+','.join(values)
                                  +' FROM payable_payments WHERE id=:payment_id'),
                             {'new_id':str(uuid.uuid4()), 'payment_id':paid['id']})
    test_session.rollback()


def test_t11_previous_cycle_remaining_debt_is_transferred_once(api):
    p,data=bill(api,[('Loja A',5000)],total=5000,items=[{'position':1,'purpose':'BUSINESS'}])
    first=integrate(api,p,data)
    payment(api,first['payable_id'],2000)
    source={'id':data['expected_source_id'],'currency':'BRL'}
    p2,c2=bill(api,[('Saldo anterior',3000),('Loja nova',1000)],total=4000,source=source,
        reference='2026-11',due_on='2026-11-24',items=[{'position':2,'purpose':'BUSINESS'}],
        replacements=[{'payable_id':first['payable_id'],'expected_balance_cents':3000,'kind':'PREVIOUS_BALANCE','reason':'Saldo anterior integral conferido'}])
    second=integrate(api,p2,c2)
    assert second['composition']['business_cents']==4000
    previous=api.client.get('/api/v1/payables/'+first['payable_id'],headers=api.headers).json()
    assert previous['status']=='SUBSTITUTED' and previous['paid_amount_cents']==2000
    assert integrate(api,p2,c2)['duplicate']
    summary=api.client.get('/api/v1/dashboard/business-summary?filter_type=all',headers=api.headers).json()['financial']
    assert summary['payables_open_cents']==4000


def test_t15_concurrent_different_decisions_have_one_winner(api,test_db_path):
    from concurrent.futures import ThreadPoolExecutor
    p,data=bill(api)
    def send(reason):
        return integrate(api,p,{**data,'reason':reason},expected=(200,201,409))
    with ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(send,['Conferencia terminal um','Conferencia terminal dois']))
    assert sum('payable_id' in r for r in results)==1
    assert sum('detail' in r for r in results)==1
    assert len(books(test_db_path)['accounts_payable'])==1


def test_t15_payment_requires_current_bill_revision_even_when_balance_is_unchanged(api):
    p,data=bill(api,[('Loja A',1000)],total=1000)
    result=integrate(api,p,data)
    integrate(api,p,{**data,'expected_revision':1,'items':[{'position':1,'purpose':'BUSINESS'}]})
    response=api.client.post('/api/v1/payables/'+result['payable_id']+'/payments',
        json={'amount_cents':1000,'payment_method':'PIX','expected_bill_revision':1},
        headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())})
    assert response.status_code==409 and response.json()['detail']['error_code']=='FINANCIAL_BILL_REVISION_CONFLICT'


def test_t14_generic_credit_cannot_be_assigned_silently_to_unknown_positive_purchase(api):
    p,data=bill(api,items=[{'position':1,'purpose':'BUSINESS'}])
    result=integrate(api,p,data)
    assert result['composition']['unclassified_cents']==13000 and result['composition']['business_cents']==0


def test_t15_populated_cycle_downgrade_refuses_to_erase_history(api,test_db_path):
    from alembic import command
    from test_financial_imports_migration import config
    p,data=bill(api)
    result=integrate(api,p,data)
    command.stamp(config(test_db_path),'head')
    with pytest.raises(RuntimeError,match='preserve history'):
        command.downgrade(config(test_db_path),'fe4b5c6d8714')
    # Empty additive tables may already be downgraded before an older history guard refuses.
    command.upgrade(config(test_db_path),'head')
    assert api.get('/bill-cycles/'+result['cycle_id'])['payable_id']==result['payable_id']


def test_t11_legacy_titles_require_full_explicit_replacement_and_keep_history(api):
    from test_financial_semantic_obligations import setup_card_statement
    source,p,statement,items = setup_card_statement(api,
        b'date,title,amount\n2026-10-01,Loja A,"100,00"\n2026-10-02,Loja B,"50,00"\n',15000,'2026-10-24')
    api.post('/statements/'+statement['id']+'/semantic-reviews', {
        'expected_revision':0,'notes':'Classificacao legada de exemplo',
        'items':[{'item_id':i['id'],'semantic_category':'PURCHASE_BUSINESS'} for i in items]})
    legacy = api.post('/statements/'+statement['id']+'/generate-obligations',{})['obligations']
    p2,data = bill(api,[('Loja A',10000),('Loja B',5000)],total=15000,source=source)
    assert integrate(api,p2,data,expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_LEGACY_REVIEW'
    replacements=[{'payable_id':i['account_payable_id'],'kind':'LEGACY','expected_balance_cents':i['amount_cents'],
                   'reason':'Titulo integral deste mesmo ciclo conferido'} for i in legacy]
    result=integrate(api,p2,{**data,'replacements':replacements})
    for old in legacy:
        title=api.client.get('/api/v1/payables/'+old['account_payable_id'],headers=api.headers).json()
        assert title['status']=='SUBSTITUTED' and title['superseded_by_id']==result['payable_id']
    enriched=integrate(api,p2,{**data,'replacements':replacements,'expected_revision':1,'reason':'Mesmos vinculos reconferidos'})
    assert enriched['payable_id']==result['payable_id'] and enriched['revision']==2


def test_t15_failure_after_staging_rolls_back_all_bill_rows(api,test_db_path,monkeypatch):
    from app.services import financial_imports
    p,data=bill(api)
    before=books(test_db_path)
    original=financial_imports.audit
    def reject(db,actor,event,*args,**kwargs):
        if event=='BILL_CYCLE_INTEGRATED':
            raise RuntimeError('synthetic failure after staging')
        return original(db,actor,event,*args,**kwargs)
    monkeypatch.setattr(financial_imports,'audit',reject)
    with pytest.raises(RuntimeError,match='synthetic failure'):
        integrate(api,p,data)
    assert books(test_db_path)==before
    with sqlite3.connect(test_db_path) as connection:
        for table in ('financial_bill_cycles','financial_bill_cycle_revisions','financial_bill_cycle_items',
                      'financial_bill_payable_links','financial_statements','financial_statement_items'):
            assert connection.execute('SELECT COUNT(*) FROM '+table).fetchone()[0]==0
        assert connection.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
        assert connection.execute('PRAGMA foreign_key_check').fetchall()==[]
