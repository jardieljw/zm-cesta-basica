"""E5 original-file matrix in disposable migrated databases; sanitized output only.

Requires a private audit inventory and independent-reference file. Never accepts
a company database as destination. No native-window/device certification.
"""
import csv, datetime, hashlib, io, json, logging, re, sqlite3, sys, uuid
from collections import Counter
from contextlib import closing
from decimal import Decimal
from pathlib import Path
import tempfile

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'backend'),str(ROOT/'scripts')]
import argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--manifest',type=Path,required=True)
parser.add_argument('--reference',type=Path,required=True)
parser.add_argument('--output-dir',type=Path,required=True)
args=parser.parse_args()
OUT=args.output_dir.resolve()
OUT.mkdir(parents=True,exist_ok=True)
logging.disable(logging.CRITICAL)
from verify_financial_csv import migrate, book_snapshot
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.api.v1.router import api_v1_router
from app.core.database import create_db_engine,get_db
from app.core.security import hash_token
from app.models.auth import PairedDevice
from app.services.financial_readers import normalized

manifest=json.loads(args.manifest.read_text(encoding='utf-8-sig'))
samples={s['alias']:s for s in manifest['samples']}
oracle=json.loads(args.reference.read_text(encoding='utf-8-sig'))
assert set(samples)=={f'pdf_{i:02d}' for i in range(1,10)}|{f'csv_{i:02d}' for i in range(1,11)}
raws={a:Path(s['path']).read_bytes() for a,s in samples.items()}
assert all(hashlib.sha256(raws[a]).hexdigest()==s['sha256'] for a,s in samples.items())
def norm(v):return re.sub(r'\s+','',str(v)).casefold()
def cents(v):return int(Decimal(v.replace('−','-').replace(' ','').replace('.','').replace(',','.'))*100)
def fields(rows):return Counter((r['transaction_date'],norm(r['description']),r['amount_cents'],r.get('installment_number'),r.get('total_installments')) for r in rows)
def expected_details(alias):
    if alias in ('csv_05','csv_06'):
        rows=[dict(transaction_date=r['date'],description=r['title'],amount_cents=cents(r['amount'])) for r in csv.DictReader(io.StringIO(raws[alias].decode('utf-8-sig')))]
    elif alias in ('pdf_07','pdf_08','pdf_09'):
        key='pdf_08' if alias=='pdf_09' else alias
        rows=[dict(transaction_date=dates[0],description=r['description'],amount_cents=r['amount_cents']) for r,dates in zip(oracle[key]['reference'],oracle[key]['date_fields'])]
    else:return None
    for r in rows:
        match=re.search(r'(?<!\d)(\d{1,3})/(\d{1,3})\s*$',r['description'])
        r.update(installment_number=int(match[1]) if match else None,total_installments=int(match[2]) if match else None)
    return fields(rows)

class Run:
    def __init__(self,directory):
        self.path=directory/'matrix.db';migrate(self.path)
        self.engine=create_db_engine('sqlite:///'+self.path.as_posix())
        app=FastAPI();app.include_router(api_v1_router,prefix='/api/v1')
        def session():
            with Session(self.engine) as db:yield db
        app.dependency_overrides[get_db]=session
        token=uuid.uuid4().hex
        with Session(self.engine) as db:
            db.add(PairedDevice(id=str(uuid.uuid4()),device_name='E5 isolated',device_public_id=uuid.uuid4().hex,token_hash=hash_token(token)));db.commit()
        self.client=TestClient(app);self.headers={'Authorization':'Bearer '+token}
        self.cards={}
        for institution in ('NUBANK','ITAU','SANTANDER','INTER','PICPAY','MERCADO PAGO'):
            self.cards[institution]=self.req('POST','/sources',dict(source_type='CREDIT_CARD',holder_type='PF',name='E5 '+institution,institution=institution,currency='BRL'))
        bank=self.req('POST','/api/v1/treasury/accounts',dict(name='E5 bank',account_type='BANK',initial_balance_cents=0))
        self.bank=self.req('POST','/sources',dict(source_type='BANK_ACCOUNT',holder_type='PJ',name='E5 statement source',institution='NUBANK',currency='BRL',financial_account_id=bank['id']))
        self.before=book_snapshot(self.path);self.parents={};self.children={};self.records=[]
    def req(self,method,path,data=None,raw=None,media=None,key=None,expected=(200,201)):
        route=path if path.startswith('/api/') else '/api/v1/financial-imports'+path
        h={**self.headers,'X-Idempotency-Key':key or str(uuid.uuid4())}
        if media:h['Content-Type']=media
        r=self.client.request(method,route,json=data,content=raw,headers=h)
        if r.status_code not in expected:
            detail=r.json().get('detail',{})
            raise ValueError('HTTP_'+str(r.status_code)+'_'+(detail.get('error_code','UNKNOWN') if isinstance(detail,dict) else 'UNKNOWN'))
        return r.json()
    def source(self,segment):
        if segment.get('document_kind')=='BANK_STATEMENT_INDEX':return self.bank
        name=normalized(segment.get('institution','')).replace('MERCADOPAGO','MERCADO PAGO')
        return next((s for k,s in self.cards.items() if k in name),self.cards['NUBANK'])
    def stage(self,alias):
        sample=samples[alias];media=sample['media_type'];raw=raws[alias]
        doc=self.req('POST','/documents?filename='+alias,raw=raw,media=media)['document']
        replay=self.req('POST','/documents?filename=renamed-original',raw=raw,media=media)
        assert replay['duplicate'] and replay['document']['id']==doc['id']
        reader='pdf_auto' if alias.startswith('pdf') else 'csv_auto'
        source=self.bank if alias=='pdf_06' else self.cards['NUBANK']
        command=dict(source_id=source['id'],currency='BRL',reader_id=reader,expected_reader_version='4' if reader=='pdf_auto' else '2')
        p=self.req('POST','/documents/'+doc['id']+'/previews',command)['preview']
        assert self.req('POST','/documents/'+doc['id']+'/previews',command)['preview']['id']==p['id']
        self.parents[alias]=p
        rows=self.req('GET','/previews/'+p['id']+'/items?limit=500')
        expected=expected_details(alias)
        if expected is not None:assert fields([r['data'] for r in rows])==expected,alias+'_FIELDS'
        if alias=='pdf_06':assert [[r['data']['transaction_date'],r['data']['amount_cents']] for r in rows]==oracle['pdf_06']['reference']
        for s in p.get('segments',[]):
            source=self.source(s)
            command=dict(expected_result_sha256=p['result_sha256'],segment_key=s['key'],source_id=source['id'])
            # A failed/stale selection must not reserve or duplicate a segment.
            denied=self.req('POST','/previews/'+p['id']+'/select-segment',{**command,'expected_result_sha256':'0'*64},expected=(409,))
            assert denied['detail']['error_code']=='FINANCIAL_PREVIEW_CHANGED'
            child=self.req('POST','/previews/'+p['id']+'/select-segment',command)['preview']
            assert self.req('POST','/previews/'+p['id']+'/select-segment',command)['preview']['id']==child['id']
            self.children[alias,s['key']]=child
        report=dict(alias=alias,document_id=doc['id'],preview_id=p['id'],segments=len(p.get('segments',[])),rows=p.get('rows_read'),items=p['items_count'],renamed_bytes_and_preview_reused=True,failed_segment_retry_verified=bool(p.get('segments')),independent_fields_checked=expected is not None or alias=='pdf_06',destinations=[])
        self.records.append(report)
        return p
    def integrate(self,p,controls=None,due=None,resolved=False,destination='HISTORY',expected=(200,201)):
        h=p.get('extracted_header',{}).copy()
        if controls:h.update({k:controls['extracted_header'][k] for k in ('due_on','total_amount_cents')})
        due=due or h['due_on'];draft=self.req('GET','/previews/'+p['id']+'/bill-integration?reference='+due[:7])
        data=dict(expected_source_id=p['source_id'],expected_result_sha256=p['result_sha256'],expected_revision=draft['expected_revision'],reference=due[:7],due_on=due,total_amount_cents=h['total_amount_cents'],destination=destination,controls_confirmed=True,accept_details_pending=True,due_conflict_resolved=resolved,reason='E5 disposable scenario; no assertion about actual debt')
        if controls:data['control_preview_id']=controls['id']
        result=self.req('POST','/previews/'+p['id']+'/integrate-bill',data,expected=expected)
        if 'detail' not in result:
            again=self.req('POST','/previews/'+p['id']+'/integrate-bill',data)
            assert again['duplicate'] and again['cycle_id']==result['cycle_id']
        return result
    def destinations(self,aliases):
        # Stage all before integration: controls can be selected regardless of file order.
        for alias in aliases:
            parent=self.parents[alias];record=next(r for r in self.records if r['alias']==alias)
            previews=[p for (a,k),p in self.children.items() if a==alias] or [parent]
            for p in previews:
                h=p.get('extracted_header',{});kind=p.get('content_type');missing=[k for k in ('due_on','total_amount_cents') if h.get(k) is None]
                entry=dict(preview_id=p['id'],segment_key=p.get('segment_provenance',{}).get('segment_key'),items=p['items_count'])
                if kind=='BANK_STATEMENT' or alias=='pdf_06':
                    confirm=dict(expected_source_id=p['source_id'],expected_result_sha256=p['result_sha256'],statement_type='BANK_STATEMENT')
                    staged=self.req('POST','/previews/'+p['id']+'/confirm',confirm)['statement']
                    assert staged['pending_count']==28
                    entry.update(destination='STATEMENT_EVIDENCE',statement_id=staged['id'])
                elif kind in ('BANK_STATEMENT_INDEX','RENEGOTIATION','UNKNOWN_INDEX') or p.get('document_kind') in ('BANK_STATEMENT_INDEX','RENEGOTIATION','UNKNOWN_INDEX'):
                    entry.update(destination='INDEX_OR_RENEGOTIATION_EVIDENCE',pending=['NO_CARD_DEBT'])
                elif alias in ('pdf_08','pdf_09'):
                    blocked=self.integrate(p,due='2026-10-26',expected=(409,))
                    assert blocked['detail']['error_code']=='FINANCIAL_DUE_DATE_CONFLICT'
                    entry.update(destination='PENDING',pending=['DUE_DATE_24_OR_26','DETAIL_DIFFERENCE_2_CENTS','CONTROL_COMPARISON_1_CENT'])
                else:
                    complement=None
                    if missing:
                        hint=p.get('reference_hint')
                        if alias in ('csv_05','csv_06'):
                            hint='2024-04' if alias=='csv_05' else '2026-03'
                        candidates=[c for c in self.children.values() if c['source_id']==p['source_id'] and c.get('extracted_header',{}).get('due_on','').startswith(hint or '__none__') and c.get('extracted_header',{}).get('total_amount_cents') is not None]
                        complement=next(iter(candidates),None)
                    if missing and complement is None:entry.update(destination='PENDING',pending=['MISSING_'+k.upper() for k in missing])
                    else:
                        result=self.integrate(p,controls=complement,expected=(200,201,409))
                        if 'detail' in result:
                            entry.update(destination='PENDING',pending=[result['detail']['error_code']])
                        else:
                            assert result['payable_id'] is None and result['balance_cents']==0
                            entry.update(destination=result['destination'],cycle_id=result['cycle_id'],revision=result['revision'],details_status=result['details_status'],difference_cents=result['difference_cents'],control_complement=bool(complement))
                            if alias=='pdf_07':assert len(result['items'])==39 and result['difference_cents']==-6
                record['destinations'].append(entry)
        after=book_snapshot(self.path)
        assert after==self.before,'BOOKS_CHANGED'
        with closing(sqlite3.connect(self.path)) as db:
            assert db.execute('pragma integrity_check').fetchone()==('ok',)
            assert db.execute('pragma foreign_key_check').fetchall()==[]
            assert db.execute('select count(*) from accounts_payable').fetchone()==(0,)
        return self.records
    def close(self):self.client.close();self.engine.dispose()
    def logical_snapshot(self):
        agenda=self.req('GET','/installments?limit=500')
        with closing(sqlite3.connect(self.path)) as db:
            cycles=db.execute('SELECT s.institution,c.reference,r.total_cents,r.due_on,r.destination,r.details_status,r.difference_cents,r.statement_id FROM financial_bill_cycles c JOIN financial_sources s ON s.id=c.source_id JOIN financial_bill_cycle_revisions r ON r.cycle_id=c.id AND r.revision=c.revision ORDER BY s.institution,c.reference').fetchall()
            logical=[]
            for *header,statement in cycles:
                rows=db.execute('SELECT normalized_data FROM financial_statement_items WHERE statement_id=? ORDER BY position',(statement,)).fetchall()
                logical.append([header,sorted(json.dumps(json.loads(row[0]),sort_keys=True) for row in rows)])
            self.logical_private=logical
            return dict(cycles=len(cycles),series=db.execute('SELECT COUNT(*) FROM financial_installment_series').fetchone()[0],forecasts=db.execute('SELECT COUNT(*) FROM financial_installment_forecasts').fetchone()[0],free_forecasts=sum(r['state']=='ESTIMATED' for r in agenda['items']),estimated_total_sha256=hashlib.sha256(str(agenda['estimated_cents']).encode()).hexdigest(),logical_sha256=hashlib.sha256(json.dumps(logical,sort_keys=True).encode()).hexdigest())
    def resolve_proved_scenarios(self):
        resolved=0
        while True:
            agenda=self.req('GET','/installments?limit=500')
            pending=agenda['pending_links']
            # Test scenario attestation only: equal purchase date and amount,
            # one available candidate; ambiguous candidates stay pending.
            match=None
            for p in pending:
                with closing(sqlite3.connect(self.path)) as db:
                    row=db.execute('SELECT i.normalized_data FROM financial_installment_occurrences o JOIN financial_statement_items i ON i.id=o.item_id WHERE o.id=?',(p['occurrence_id'],)).fetchone()
                purchase_date=json.loads(row[0])['transaction_date']
                if len(p['candidates'])==1 and p['candidates'][0]['amount_cents']==p['amount_cents'] and p['candidates'][0]['purchase_date']==purchase_date:
                    match=p;break
            if match is None:break
            self.req('POST','/installments/decisions',dict(action='LINK',occurrence_id=match['occurrence_id'],series_id=match['candidates'][0]['series_id'],expected_revision=match['expected_revision'],expected_snapshot=agenda['snapshot'],reason='E5 isolated explicit scenario: installment correspondence checked against originals'))
            resolved+=1
        return dict(explicit_scenario_links=resolved,remaining_ambiguous_links=len(pending),pending=[dict(occurrence_id=p['occurrence_id'],cycle_id=p['cycle_id'],candidates=len(p['candidates'])) for p in pending],estimated_cents_kept_private=True)

def compare_compilations(run):
    def segs(alias):return run.parents[alias]['segments']
    def meta(alias):return [s['raw_metadata'] for s in segs(alias) if 'raw_metadata' in s]
    def key(r):return tuple(sorted((normalized(k),norm(v)) for k,v in r.items()))
    # Compare PDF table geometry to raw CSV records, without app tokenization.
    for pdf,csv_alias,subset in [('pdf_01','csv_02',False),('pdf_04','csv_02',True),('pdf_05','csv_08',False)]:
        actual=Counter(key(r) for r in meta(pdf))
        expected=Counter(key(r) for r in csv.DictReader(io.StringIO(raws[csv_alias].decode('utf-8-sig'))))
        assert not(actual-expected) if subset else actual==expected,pdf+'_METADATA'
    for alias in ('csv_01','csv_02','csv_03','csv_04','csv_08','csv_09','csv_10'):
        expected=Counter(key(r) for r in csv.DictReader(io.StringIO(raws[alias].decode('utf-8-sig'))))
        assert Counter(key(r) for r in meta(alias))==expected,alias+'_METADATA'
    for a in ('pdf_02','pdf_03','csv_07'):
        segments=segs(a)
        if a=='pdf_02':
            for alias,count in [('csv_05',21),('csv_06',13)]:
                s=next(s for s in segments if len(s['items'])==count)
                expected=oracle[alias]['reference_compiled_pdf']
                assert Counter((i['data']['transaction_date'],norm(i['data']['description']),i['data']['amount_cents']) for i in s['items'])==Counter((r['date'],norm(r['description']),r['amount_cents']) for r in expected)
        else:
            rows=list(csv.DictReader(io.StringIO(raws['csv_07'].decode('utf-8-sig'))))
            actual=Counter((r['data']['transaction_date'],norm(r['data']['description']),r['data']['amount_cents'],norm(r.get('observation',''))) for s in segments for r in s['items'])
            # Explicit audited control labels; independently keep these out of purchases.
            details=[r for r in rows if not normalized(r['descricao']).startswith(('FATURA ANTERIOR','TOTAL','OUTROS LANCAMENTOS','PAGAMENTO RECEBIDO'))]
            expected=Counter((r['data_lancamento'],norm(r['descricao']),cents(r['valor_rs']),norm(r['observacao'])) for r in details)
            assert actual==expected,a+'_DETAIL_FIELDS'
    return True

def main():
    report=dict(status='PASS_WITH_DOCUMENT_PENDENCIES',scope='E5 isolated scenarios; principal untouched',reader_versions={'pdf_auto':'4','csv_auto':'2'},individual=[],combined={},reverse={})
    individual_aliases=samples
    for alias in individual_aliases:
        with tempfile.TemporaryDirectory(prefix='e5-one-',dir=ROOT/'tmp') as temp:
            run=Run(Path(temp))
            try:run.stage(alias);report['individual']+=run.destinations([alias])
            finally:run.close()
        print(json.dumps(dict(progress='individual',alias=alias)),flush=True)
    for name,aliases in [('combined',list(samples)),('reverse',list(reversed(samples)))]:
        with tempfile.TemporaryDirectory(prefix='e5-'+name+'-',dir=ROOT/'tmp') as temp:
            run=Run(Path(temp))
            try:
                for alias in aliases:run.stage(alias)
                compare_compilations(run)
                report[name]=run.destinations(aliases)
                report[name+'_link_decisions']=run.resolve_proved_scenarios()
                report[name+'_logical_snapshot']=run.logical_snapshot()
                assert run.parents['pdf_08']['id']==run.parents['pdf_09']['id']
                report[name+'_checks']=dict(independent_compilation_fields_and_multiplicity=True,duplicate_pdf_reused=True,no_principal_writes=True,books_unchanged=True,integrity_and_foreign_keys=True)
            finally:run.close()
        print(json.dumps(dict(progress=name,status='checked')),flush=True)
    (OUT/'matriz-sanitizada.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    # Unresolved identity intentionally holds candidate forecasts. The inventory
    # before an explicit link can depend on which observed installment came first;
    # neither order may change cycle facts or the amount freely estimated.
    for k in ('cycles','series','logical_sha256','free_forecasts','estimated_total_sha256'):
        assert report['combined_logical_snapshot'][k]==report['reverse_logical_snapshot'][k],'ORDER_CHANGED_'+k
    report['order_independent_cycle_facts_and_free_estimates']=True
    report['unresolved_forecast_inventory_requires_link_decision']=bool(report['combined_link_decisions']['remaining_ambiguous_links'])
    (OUT/'matriz-sanitizada.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(dict(status=report['status'],individual=len(report['individual']),combined=len(report['combined']),reverse=len(report['reverse']))))

if __name__=='__main__':
    try:main()
    except Exception as e:
        import traceback
        print(json.dumps(dict(status='FAIL',code=str(e) if isinstance(e,ValueError) else type(e).__name__,lines=[f.lineno for f in traceback.extract_tb(e.__traceback__) if Path(f.filename).name==Path(__file__).name])),flush=True)
        raise SystemExit(1)
