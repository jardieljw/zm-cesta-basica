"""E4: remaining installments, exact monthly calendar, conservative continuity and UI contracts."""
import datetime as dt
import sqlite3
import pytest
from sqlalchemy import select
from test_financial_bill_cycles import api, bill, integrate, payment
from app.models.financial_installments import InstallmentSeries as Series, InstallmentForecast as Forecast
from app.services.financial_installments import monthly_date, month_offset


def agenda(api, query=''):
    return api.get('/installments'+query)


def resolve(api, pending, action='LINK', series=None, **changes):
    state=agenda(api)
    return api.post('/installments/decisions',dict(action=action,occurrence_id=pending['occurrence_id'],
        import_id=pending['import_id'],expected_generation=pending['generation'],
        expected_revision=pending['expected_revision'],expected_snapshot=state['snapshot'],series_id=series,
        reason='Serie e divergencias conferidas no documento',**changes))


def next_bill(api, source, number=4, reference='2026-11', day=24, amount=10001, total=10, rows=None, **changes):
    p,c=bill(api,rows or [(f'Loja A - {number}/{total}',amount)],total=sum(v for _,v in rows) if rows else amount,
        source=source,reference=reference,due_on=f'{reference}-{day:02}',**changes)
    return integrate(api,p,c)


@pytest.mark.parametrize('number,remaining',[(3,7),(10,0),(1,9)])
def test_t12_only_remaining_no_division_or_payable(api,test_db_path,number,remaining):
    p,c=bill(api,[(f'Loja A - {number}/10',10001)],total=10001)
    first=integrate(api,p,c)
    state=agenda(api)
    assert state['count']==remaining and state['estimated_cents']==remaining*10001
    assert all(i['amount_cents']==10001 and not i['payable'] for i in state['items'])
    assert integrate(api,p,c)['duplicate'] and agenda(api)['count']==remaining
    with sqlite3.connect(test_db_path) as db:
        assert db.execute('select count(*) from accounts_payable').fetchone()[0]==1
        assert db.execute('select count(*) from cash_flow_entries').fetchone()[0]==0
    if remaining:
        denied=api.client.post('/api/v1/payables/'+state['items'][0]['id']+'/payments',json={'amount_cents':1,'payment_method':'PIX'},headers={**api.headers,'X-Idempotency-Key':'forecast-not-payable'})
        assert denied.status_code==404


def test_t12_months_clamp_without_drift_leap_and_year_limit():
    assert [monthly_date(month_offset('2024-01',n),31).isoformat() for n in (1,2,3)]==['2024-02-29','2024-03-31','2024-04-30']
    assert monthly_date('2025-02',31)==dt.date(2025,2,28)
    assert month_offset('2026-12',1)=='2027-01'
    assert monthly_date('2026-11',None) is None
    with pytest.raises(Exception):month_offset('9999-12',1)


def test_t13_candidate_not_automatic_value_and_day_divergence_explicit(api):
    p,c=bill(api,[('Loja A - 3/10',10001)],total=10001)
    first=integrate(api,p,c);source={'id':c['expected_source_id'],'currency':'BRL'}
    second=next_bill(api,source,amount=10002,day=26)
    state=agenda(api)
    assert state['estimated_cents']==0 and state['pending_cents']==70007
    pending=state['pending_links'][0]
    # The actual November bill remains reachable while resolving December's held forecasts.
    assert agenda(api,'?month=12&year=2026')['pending_links'][0]['occurrence_id']==pending['occurrence_id']
    assert pending['amount_cents']==10002 and pending['due_on']=='2026-11-26'
    assert pending['candidates'][0]['amount_cents']==10001
    assert pending['candidates'][0]['estimated_due_on']=='2026-11-24'
    resolve(api,pending,series=pending['candidates'][0]['series_id'])
    state=agenda(api)
    assert state['estimated_cents']==60006 and not state['pending_links']
    assert state['items'][0]['state']=='REPLACED'
    assert api.client.get('/api/v1/payables/summary',headers=api.headers).json()['open_cents']==20003
    # A summary or equivalent evidence after payment does not recreate estimates or debt.
    payment(api,second['payable_id'],10002)
    next_bill(api,source,amount=10002,day=26,expected_revision=1)
    assert agenda(api)['estimated_cents']==60006


def test_t13_equal_purchases_preserve_multiplicity_and_resolve_one_each(api):
    p,c=bill(api,[('Loja A - 3/10',10001)]*2,total=20002)
    integrate(api,p,c)
    state=agenda(api);assert state['count']==14
    source={'id':c['expected_source_id'],'currency':'BRL'}
    next_bill(api,source,rows=[('Loja A - 4/10',10001)]*2)
    state=agenda(api);assert len(state['pending_links'])==2 and state['estimated_cents']==0
    one,two=state['pending_links'];assert len(one['candidates'])==2
    resolve(api,one,series=one['candidates'][0]['series_id'])
    state=agenda(api)
    two=state['pending_links'][0]
    wrong={**two,'expected_revision':two['expected_revision']}
    response=api.post('/installments/decisions',dict(action='LINK',occurrence_id=wrong['occurrence_id'],expected_revision=wrong['expected_revision'],
        expected_snapshot=state['snapshot'],series_id=one['candidates'][0]['series_id'],reason='Tentativa de colapsar compras'),expected=(409,))
    assert response['detail']['error_code']=='FINANCIAL_INSTALLMENT_LINK_CONFLICT'
    resolve(api,two,series=one['candidates'][1]['series_id'])
    assert agenda(api)['estimated_cents']==120012


def test_t13_out_of_order_distinct_and_absence_never_cancels(api):
    p,c=bill(api,[('Loja A - 4/10',10001)],total=10001,reference='2026-11',due_on='2026-11-24')
    integrate(api,p,c);source={'id':c['expected_source_id'],'currency':'BRL'}
    next_bill(api,source,number=3,reference='2026-10')
    state=agenda(api);assert len(state['pending_links'])==1
    pending=state['pending_links'][0];resolve(api,pending,series=pending['candidates'][0]['series_id'])
    state=agenda(api);assert state['count']==7 and state['estimated_cents']==60006
    next_bill(api,source,reference='2026-12',rows=[('Outra compra',500)])
    assert agenda(api)['estimated_cents']==60006
    next_bill(api,source,number=5,reference='2026-12',expected_revision=1,accept_content_change=True)
    pending=agenda(api)['pending_links'][0];resolve(api,pending,action='DISTINCT')
    assert agenda(api)['estimated_cents']==110011


def test_t12_unknown_day_month_filter_and_complete_totals(api):
    p,c=bill(api,[('Loja A - 3/10',10001)],total=10001,estimate_installment_day=False);integrate(api,p,c)
    all_rows=agenda(api,'?limit=1')
    assert len(all_rows['items'])==1 and all_rows['count']==7 and all_rows['estimated_cents']==70007
    assert all_rows['items'][0]['estimated_due_on'] is None
    assert agenda(api,'?due_date_from=2026-11-15&due_date_to=2026-11-16')['estimated_cents']==10001
    assert agenda(api,'?month=11&year=2026')['estimated_cents']==10001
    assert agenda(api,'?status=PAID')['estimated_cents']==0
    assert agenda(api,'?merchant=outra')['count']==0


def test_t13_explicit_cancel_requires_credit_and_does_not_touch_paid(api):
    p,c=bill(api,[('Loja A - 3/10',10001)],total=10001);first=integrate(api,p,c)
    source={'id':c['expected_source_id'],'currency':'BRL'}
    payment(api,first['payable_id'],10001)
    next_bill(api,source,rows=[('Estorno Loja A',-10001),('Outra compra',20002)])
    state=agenda(api);credit=state['cancellation_evidence'][0];series=state['items'][0]['series_id']
    api.post('/installments/decisions',dict(action='CANCEL',series_id=series,evidence_item_id=credit['item_id'],from_number=4,
        expected_revision=0,expected_snapshot=state['snapshot'],reason='Documento confirma cancelamento das parcelas 4 a 10'))
    state=agenda(api)
    assert state['estimated_cents']==0 and all(i['state']=='CANCELED' for i in state['items'])
    assert api.client.get('/api/v1/payables/'+first['payable_id'],headers=api.headers).json()['balance_cents']==0


def test_t13_equivalent_revision_reordered_rows_preserves_series_and_no_reactivation(api):
    rows=[('Loja A - 3/10',10001),('Loja A - 3/10',10002)]
    p,c=bill(api,rows,total=20003);first=integrate(api,p,c)
    state=agenda(api);assert state['count']==14
    source={'id':c['expected_source_id'],'currency':'BRL'}
    next_bill(api,source,rows=rows[::-1],reference='2026-10',expected_revision=1,accept_content_change=True)
    assert agenda(api)['count']==14 and not agenda(api)['pending_links']
    assert agenda(api)['estimated_cents']==140021
    # Changed wording in an accepted revision is a candidate, never a second silent series.
    next_bill(api,source,rows=[('Loja A nova redacao - 3/10',10001),rows[1]],reference='2026-10',expected_revision=2,accept_content_change=True)
    state=agenda(api);assert state['count']==14 and len(state['pending_links'])==1
    pending=state['pending_links'][0];resolve(api,pending,series=pending['candidates'][0]['series_id'])
    assert agenda(api)['count']==14


def test_t15_stale_snapshot_two_clients_and_decision_replay(api):
    p,c=bill(api,[('Loja A - 3/10',10001)],total=10001);integrate(api,p,c)
    source={'id':c['expected_source_id'],'currency':'BRL'};next_bill(api,source)
    state=agenda(api);pending=state['pending_links'][0]
    command=dict(action='LINK',occurrence_id=pending['occurrence_id'],expected_revision=pending['expected_revision'],
        expected_snapshot=state['snapshot'],series_id=pending['candidates'][0]['series_id'],reason='Vinculo conferido pelo primeiro cliente')
    import uuid
    key=str(uuid.uuid4());first=api.post('/installments/decisions',command,key=key)
    assert api.post('/installments/decisions',command,key=key)['id']==first['id']
    assert api.post('/installments/decisions',command,expected=(409,))['detail']['error_code']=='FINANCIAL_INSTALLMENT_REVISION_CONFLICT'


def test_t15_calendar_overflow_rolls_back_entire_cycle(api,test_db_path):
    from test_financial_imports import books
    p,c=bill(api,[('Loja A - 3/10',10001)],total=10001,reference='9999-12',due_on='9999-12-31')
    before=books(test_db_path)
    denied=integrate(api,p,c,expected=(409,))
    assert denied['detail']['error_code']=='FINANCIAL_INSTALLMENT_DATE_LIMIT'
    assert books(test_db_path)==before and agenda(api)['count']==0


@pytest.mark.parametrize('pdf_first',[True,False])
def test_t13_pdf_csv_both_orders_and_renamed_pdf_keep_one_agenda(api,pdf_first):
    from test_financial_pdf import card_pdf, upload_preview
    from test_financial_readers import preview
    source=api.source('CREDIT_CARD')
    content=card_pdf()
    pdf,document,options=upload_preview(api,source,content)
    csv,_,_=preview(api,source,b'date,title,amount\n2025-07-10,Loja exemplo - 1/2,"10,00"\n2025-07-11,Cr\xc3\xa9dito exemplo,"-5,00"\n',reader='csv_auto')
    ordered=[pdf,csv] if pdf_first else [csv,pdf]
    for revision,p in enumerate(ordered):
        data=dict(expected_source_id=source['id'],expected_result_sha256=p['result_sha256'],expected_revision=revision,
            reference='2025-08',due_on='2025-08-10',total_amount_cents=500,destination='HISTORY',controls_confirmed=True,
            accept_details_pending=True,accept_content_change=True,reason='Conferencia sintetica dos formatos equivalentes')
        integrate(api,p,data)
        assert agenda(api)['count']==1 and agenda(api)['estimated_cents']==1000
    import uuid
    r=api.client.post('/api/v1/financial-imports/documents?filename=renamed.pdf',content=content,
        headers={**api.headers,'Content-Type':'application/pdf','X-Idempotency-Key':str(uuid.uuid4())})
    assert r.status_code in (200,201) and r.json()['document']['id']==document['id']
    again=api.post('/documents/'+document['id']+'/previews',options)['preview']
    assert again['id']==pdf['id']
    data.update(expected_result_sha256=again['result_sha256'],expected_revision=2)
    integrate(api,again,data)
    assert agenda(api)['count']==1 and agenda(api)['estimated_cents']==1000
