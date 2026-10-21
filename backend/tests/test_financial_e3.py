"""E3: segments, explicit decisions, multiset enrichment and complete filters."""
import csv
import io
import uuid
import pytest
from test_financial_bill_cycles import api, bill, integrate, payment
from test_financial_readers import preview
from app.services.financial_readers import detect_csv
from test_financial_pdf import pdf_bytes, upload_preview

HEADERS = 'Instituicao,Tipo_Documento,Referencia_Mes_Ano,Data_Email_Emissao,Data_Vencimento,Valor_Total_RS,Valor_Minimo_ou_Quitacao_RS,Arquivo_Original_No_Gmail,Status_Protecao_Anexo\n'


def summary(api, source, total='130,00', due='24/10/2026', kind='Fatura Cartão de Crédito'):
    content=HEADERS+f'''{source['institution']},{kind},Outubro/2026,,{due},"{total}",,,\n'''
    p,_,_=preview(api,source,content.encode(),reader='csv_auto')
    child=api.post('/previews/'+p['id']+'/select-segment',dict(import_id=p['import_id'],
        expected_generation=p['generation'],expected_result_sha256=p['result_sha256'], segment_key='1',source_id=source['id']))['preview']
    return p, child


def command(p, **kw):
    return dict(expected_source_id=p['source_id'],expected_result_sha256=p['result_sha256'],expected_revision=0,
        reference='2026-10',due_on='2026-10-24',total_amount_cents=13000,controls_confirmed=True,
        accept_details_pending=True,destination='OPEN',reason='Conferido o saldo ainda aberto',**kw)


def test_summary_segments_keep_missing_credit_and_renegotiation_separate():
    content=HEADERS+'Nubank,Fatura Cartão de Crédito,Outubro/2026,,24/10/2026,"-25,00 (Saldo Credor)",,,\nNubank,Renegociação de Contrato,Outubro/2026,,,,,,\n'
    r=detect_csv(content.encode(),'CREDIT_CARD')
    assert len(r['segments'])==2 and r['items']==[]
    assert r['segments'][0]['extracted_header']['total_amount_cents']==-2500
    assert r['segments'][1]['document_kind']=='RENEGOTIATION'
    assert 'total_amount_cents' not in r['segments'][1]['extracted_header']


def test_t08_selection_replay_and_no_implicit_history_debt(api):
    source=api.source('CREDIT_CARD')
    parent,p=summary(api,source)
    selected=api.post('/previews/'+parent['id']+'/select-segment',dict(expected_result_sha256=parent['result_sha256'],segment_key='1',source_id=source['id']))
    assert selected['duplicate'] and selected['preview']['id']==p['id']
    data=command(p); data['destination']='HISTORY'
    result=integrate(api,p,data)
    assert result['payable_id'] is None and not result['items']
    assert api.client.get('/api/v1/payables',headers=api.headers).json()==[]


@pytest.mark.parametrize('summary_first',[False,True])
def test_t13_summary_and_details_both_orders_keep_items_and_paid_balance(api,summary_first):
    source=api.source('CREDIT_CARD')
    _,s=summary(api,source)
    p,data=bill(api,source=source)
    first=integrate(api,s,command(s)) if summary_first else integrate(api,p,data)
    payment(api,first['payable_id'],13000)
    if summary_first:
        result=integrate(api,p,{**data,'expected_revision':1})
    else:
        result=integrate(api,s,{**command(s),'expected_revision':1})
    assert result['balance_cents']==0 and result['payable_status']=='PAID'
    assert len(result['items'])==3 and result['details_status']=='RECONCILED'
    assert result['payable_id']==first['payable_id']


def test_t13_multiset_divergence_requires_explicit_revision(api):
    source=api.source('CREDIT_CARD')
    p,data=bill(api,source=source); integrate(api,p,data)
    p2,d2=bill(api,source=source,rows=[('Loja A - 3/10',10000),('Loja B diferente',5000),('Estorno exemplo',-2000)],expected_revision=1)
    assert integrate(api,p2,d2,expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_CONTENT_CONFLICT'
    changed=integrate(api,p2,{**d2,'accept_content_change':True})
    assert changed['revision']==2 and len(changed['items'])==3


def test_t04_guided_control_complement_binds_immutable_summary(api):
    source=api.source('CREDIT_CARD'); _,s=summary(api,source)
    p,data=bill(api,source=source)
    draft=api.get('/previews/'+p['id']+'/bill-integration')
    assert any(c['preview_id']==s['id'] and c['compiled'] for c in draft['control_candidates'])
    result=integrate(api,p,{**data,'control_preview_id':s['id']})
    assert result['balance_cents']==13000


def test_t10_filters_total_all_pages_and_ordinary_titles(api):
    source=api.source('CREDIT_CARD'); p,data=bill(api,source=source)
    integrated=integrate(api,p,data)
    for n in range(3):
        api.client.post('/api/v1/payables',json=dict(description='Conta comum',beneficiary='Fornecedor',category='OUTROS',nature='BUSINESS',original_amount_cents=1000,due_date=f'2026-10-{24+n}T15:00:00',payment_method='PIX'),headers={**api.headers,'X-Idempotency-Key':str(uuid.uuid4())}).raise_for_status()
    def get(q):
        response=api.client.get('/api/v1/payables'+q,headers=api.headers); assert response.status_code==200,response.text; return response.json()
    assert len(get('?merchant=Loja'))==1
    assert len(get('?source_id='+source['id']))==1
    assert len(get('?due_date_from=2026-10-24&due_date_to=2026-10-24'))==2
    assert len(get('?limit=1'))==1
    totals=get('/summary?limit=1')
    assert totals['count']==4 and totals['open_cents']==16000
    filtered=get('/summary?merchant=Loja&source_id='+source['id'])
    assert filtered['count']==1 and filtered['open_cents']==13000
    assert len(get(''))==4


def test_t07_due_conflict_requires_recorded_candidate_and_preserves_difference(api):
    source=api.source('CREDIT_CARD')
    content=pdf_bytes([[('Nubank FATURA 24 OUT 2026',None),('Data de vencimento: 26 OUT 2026',None),
        ('Resumo da fatura atual',None),('Total a pagar','10,00'),('Transações',None),('01 OUT Loja - 1/1','10,02')]])
    p,_,_=upload_preview(api,source,content)
    data=command(p); data['total_amount_cents']=1000
    for changes in ({},{'due_conflict_resolved':True,'due_on':'2026-10-25'}):
        denied=integrate(api,p,{**data,**changes},expected=(409,))
        assert denied['detail']['error_code']=='FINANCIAL_DUE_DATE_CONFLICT'
    result=integrate(api,p,{**data,'due_conflict_resolved':True,'due_on':'2026-10-26'})
    assert result['due_on']=='2026-10-26' and result['difference_cents']==2
    decision=result['control_provenance']['due_resolution']
    assert {c['value'] for c in decision['candidates']}=={'2026-10-24','2026-10-26'}
    assert decision['reason'] and result['details_status']=='AVAILABLE_UNRECONCILED'
    # Reopening an immutable reading must recover the operator's saved choice.
    before = api.client.get('/api/v1/payables', headers=api.headers).json()
    reopened = api.get('/previews/'+p['id']+'/bill-integration')
    assert reopened['reference'] == '2026-10'
    assert reopened['cycle']['preview_id'] == p['id']
    assert reopened['cycle']['due_on'] == '2026-10-26'
    assert reopened['cycle']['difference_cents'] == 2
    assert reopened['expected_revision'] == 1
    assert api.get('/previews/'+p['id'])['extracted_header'].get('due_on') is None
    unrelated = api.get('/previews/'+p['id']+'/bill-integration?reference=2026-11')
    assert unrelated['cycle'] is None and unrelated['expected_revision'] == 0
    assert api.client.get('/api/v1/payables', headers=api.headers).json() == before


def test_t08_wrong_institution_and_unselected_compilation_cannot_generate(api):
    source=api.source('CREDIT_CARD'); parent,p=summary(api,source)
    assert integrate(api,parent,command(parent),expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED'
    other=api.post('/sources',dict(source_type='CREDIT_CARD',holder_type='PF',name='Outro cartão',institution='Santander'))
    denied=api.post('/previews/'+parent['id']+'/select-segment',dict(expected_result_sha256=parent['result_sha256'],segment_key='1',source_id=other['id']),expected=(409,))
    assert denied['detail']['error_code']=='FINANCIAL_INSTITUTION_MISMATCH'


def test_reopening_keeps_saved_cycle_when_another_reference_is_rejected(api):
    p, data = bill(api)
    integrate(api, p, data)
    denied = integrate(api, p, {**data, 'reference': '2026-11', 'due_on': '2026-11-24'}, expected=(409,))
    assert denied['detail']['error_code'] == 'FINANCIAL_BILL_CYCLE_CONFLICT'
    reopened = api.get('/previews/'+p['id']+'/bill-integration')
    assert reopened['cycle']['reference'] == '2026-10'
    assert reopened['expected_revision'] == 1
    explicit = api.get('/previews/'+p['id']+'/bill-integration?reference=2026-10')
    assert explicit['cycle']['reference'] == '2026-10'


def test_t13_same_repeated_items_are_not_collapsed_or_silently_replaced(api):
    source=api.source('CREDIT_CARD')
    p,data=bill(api,source=source,rows=[('Loja repetida',1000),('Loja repetida',1000)],total=2000)
    result=integrate(api,p,data); assert len(result['items'])==2
    p2,d2=bill(api,source=source,rows=[('Loja repetida',2000)],total=2000,expected_revision=1)
    assert integrate(api,p2,d2,expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_CONTENT_CONFLICT'


def test_t09_renegotiation_never_activates_positive_debt(api):
    source=api.source('CREDIT_CARD'); _,p=summary(api,source,kind='Renegociação de Contrato')
    assert integrate(api,p,command(p),expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED'


def test_t08_compiled_row_split_between_pages_keeps_all_fields_and_notes():
    from app.services.financial_compilations import metadata
    report=metadata([
        ({'INSTITUICAO':'','TIPO_DOCUMENTO':'Extrato Conta PJ','DATA_EMAIL_EMISSAO':'01/10/2026'},'primeira parte',1),
        ({'INSTITUICAO':'Nu Empresas','TIPO_DOCUMENTO':'','REFERENCIA_MES_ANO':'Setembro/2026'},'segunda parte',2),
        ({'INSTITUICAO':'Banco Inter','TIPO_DOCUMENTO':'','REFERENCIA_MES_ANO':''},'título de seção',2),
    ])
    assert len(report['segments'])==1 and report['rows_read']==1
    assert report['segments'][0]['document_kind']=='BANK_STATEMENT_INDEX'
    assert report['segments'][0]['raw_metadata']['DATA_EMAIL_EMISSAO']=='01/10/2026'
    assert report['document_notes']==['título de seção']


def test_t08_wrapped_reference_cells_keep_description_observation_and_controls():
    from app.services.financial_compilations import REF_COLUMNS, table_cells, referenced
    def word(text,x,y): return dict(text=text,x0=x,x1=x+len(text)*3,top=y,bottom=y+8)
    headers=[word(name,x,10) for name,x in zip(REF_COLUMNS,(10,110,210,410,510))]
    data=[word('2026-10-24',10,40),word('2026-10-01',110,40),word('Juros de',210,34),word('atraso',210,46),word('10,00',410,40),word('Referência de',510,34),word('teste',510,46)]
    lines=[dict(words=headers,text=' '.join(REF_COLUMNS),bbox=[10,10,600,18])]+[dict(words=[w],text=w['text'],bbox=[w['x0'],w['top'],w['x1'],w['bottom']]) for w in data]
    page=dict(page_number=1,height=100,width=600,lines=lines,horizontal_edges=[dict(x0=0,x1=100,top=y) for y in (25,60)])
    result=referenced(table_cells(page,REF_COLUMNS))
    item=result['segments'][0]['items'][0]
    assert item['data']['description']=='Juros de atraso' and item['observation']=='Referência de teste'
    assert item['role']=='CHARGE' and item['data']['amount_cents']==1000


def test_t09_previous_balance_in_summary_is_control_and_requires_existing_link(api):
    source=api.source('CREDIT_CARD')
    content=b'fatura_referencia,data_lancamento,descricao,valor_rs,observacao\n2026-10-24,2026-10-01,Fatura anterior,"100,00",resumo\n2026-10-24,2026-10-01,Total a pagar,"130,00",resumo\n'
    parent,_,_=preview(api,source,content,reader='csv_auto')
    p=api.post('/previews/'+parent['id']+'/select-segment',dict(expected_result_sha256=parent['result_sha256'],segment_key='1',source_id=source['id']))['preview']
    assert p['items_count']==0 and p['reported_summary']['previous']==10000
    assert integrate(api,p,command(p),expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_PREVIOUS_BALANCE_LINK'


def test_t13_equal_totals_do_not_hide_different_summary_components(api):
    source=api.source('CREDIT_CARD')
    def compiled(previous,purchases):
        content=('fatura_referencia,data_lancamento,descricao,valor_rs,observacao\n'+
          f'2026-10-24,2026-10-01,Fatura anterior,"{previous},00",resumo\n'+
          f'2026-10-24,2026-10-01,Total de compras,"{purchases},00",resumo\n'+
          '2026-10-24,2026-10-01,Total a pagar,"130,00",resumo\n').encode()
        parent,_,_=preview(api,source,content,reader='csv_auto')
        return api.post('/previews/'+parent['id']+'/select-segment',dict(expected_result_sha256=parent['result_sha256'],segment_key='1',source_id=source['id']))['preview']
    first=compiled(100,30); data=command(first);data['destination']='HISTORY'
    integrate(api,first,data)
    second=compiled(90,40); data=command(second); data.update(destination='HISTORY',expected_revision=1)
    assert integrate(api,second,data,expected=(409,))['detail']['error_code']=='FINANCIAL_BILL_CONTENT_CONFLICT'
    result=integrate(api,second,{**data,'accept_content_change':True})
    assert result['control_provenance']['reported_summary']['previous']==9000


@pytest.mark.parametrize('metadata_first', [False, True])
def test_e5_summary_enrichment_retains_known_components_without_false_detail_difference(api, metadata_first):
    source=api.source('CREDIT_CARD')
    content=b'fatura_referencia,data_lancamento,descricao,valor_rs,observacao\n2026-10-24,2026-10-01,Fatura anterior,"100,00",resumo\n2026-10-24,2026-10-01,Total de compras,"30,00",resumo\n2026-10-24,2026-10-01,Total a pagar,"130,00",resumo\n'
    parent,_,_=preview(api,source,content,reader='csv_auto')
    rich=api.post('/previews/'+parent['id']+'/select-segment',dict(expected_result_sha256=parent['result_sha256'],segment_key='1',source_id=source['id']))['preview']
    _,metadata=summary(api,source)
    ordered=[metadata,rich] if metadata_first else [rich,metadata]
    first=integrate(api,ordered[0],{**command(ordered[0]),'destination':'HISTORY'})
    result=integrate(api,ordered[1],{**command(ordered[1]),'destination':'HISTORY','expected_revision':1})
    assert result['cycle_id']==first['cycle_id'] and result['payable_id'] is None
    assert result['details_status']=='SUMMARY_ONLY' and result['difference_cents'] is None
    assert result['control_provenance']['reported_summary']=={'previous':10000,'purchases':3000}
