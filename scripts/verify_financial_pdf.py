"""Exercise authorized PDF originals through the API in a disposable database.

Private manifest supplies independently checked expectations. No company DB
option, Gmail access, automatic item review or financial posting.
"""
import argparse
from collections import Counter
from contextlib import closing
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import tempfile
import uuid

from verify_financial_csv import (
    ROOT, CheckFailed, check, migrate, book_snapshot, create_db_engine, get_db,
    FastAPI, TestClient, Session, PairedDevice, FinancialAccount,
    generate_device_token, hash_token, router, FinancialPayloadLimitMiddleware, PREFIX,
    create_backup, restore_backup,
)


def run(manifest):
    samples = manifest['samples']
    check(isinstance(samples, list) and 0 < len(samples) <= 20, 'SAMPLE_COUNT')
    labels = [s['label'] for s in samples]
    check(all(re.fullmatch(r'[a-z][a-z0-9_]{0,39}', s) for s in labels) and len(set(labels)) == len(labels), 'SAMPLE_ALIASES')
    report = {'status': 'PASS', 'samples': [], 'checks': {}}
    with tempfile.TemporaryDirectory(prefix='zm-pdf-check-') as temporary:
        directory = Path(temporary).resolve()
        check(directory.parent == Path(tempfile.gettempdir()).resolve() and directory.name.startswith('zm-pdf-check-'), 'TEMP_DIRECTORY')
        path = directory / 'isolated.db'
        migrate(path)
        engine = create_db_engine('sqlite:///' + path.as_posix())
        app = FastAPI()
        app.include_router(router, prefix='/api/v1')
        app.add_middleware(FinancialPayloadLimitMiddleware, prefix=PREFIX)

        def session():
            with Session(engine) as db:
                yield db
        app.dependency_overrides[get_db] = session
        token = generate_device_token()
        device_id = str(uuid.uuid4())
        stored = []
        try:
            with Session(engine) as db:
                db.add(PairedDevice(id=device_id, device_name='PDF isolated test', device_public_id=str(uuid.uuid4()), token_hash=hash_token(token)))
                db.commit()
            with TestClient(app) as client:
                def request(method, route, payload=None, raw=None, expected=(200, 201)):
                    headers = {'Authorization': 'Bearer ' + token, 'X-Idempotency-Key': str(uuid.uuid4())}
                    if raw is not None:
                        headers['Content-Type'] = 'application/pdf'
                    response = client.request(method, PREFIX + route, json=payload, content=raw, headers=headers,
                                              params={'filename': 'sample.pdf'} if raw is not None else None)
                    check(response.status_code in expected, 'API_' + str(response.status_code))
                    return response.content if route.endswith('/content') else response.json()

                for sample in samples:
                    source_type = sample['source_type']
                    account_id = None
                    if source_type == 'BANK_ACCOUNT':
                        account_id = str(uuid.uuid4())
                        with Session(engine) as db:
                            db.add(FinancialAccount(id=account_id, name='Synthetic account', account_type='BANK', initial_balance_cents=0, current_balance_cents=0))
                            db.commit()
                    source = request('POST', '/sources', payload={'source_type': source_type, 'holder_type': sample['holder_type'],
                        'currency': 'BRL', 'financial_account_id': account_id, 'name': 'Isolated source', 'institution': 'Sample institution'})
                    before = book_snapshot(path)
                    sample_path = Path(sample['path'])
                    check(0 < sample_path.stat().st_size <= 10 * 1024 * 1024, 'SOURCE_SIZE')
                    with sample_path.open('rb') as stream:
                        raw = stream.read(10 * 1024 * 1024 + 1)
                    check(hashlib.sha256(raw).hexdigest() == sample['sha256'], 'SOURCE_CHECKSUM')
                    doc = request('POST', '/documents', raw=raw)['document']
                    check(request('GET', '/documents/' + doc['id'] + '/content') == raw, 'ORIGINAL_BYTES')
                    data = {'source_id': source['id'], 'currency': 'BRL', 'reader_id': 'pdf_auto'}
                    route = '/documents/' + doc['id'] + '/previews'
                    p = request('POST', route, payload=data)['preview']
                    check(p['status'] == sample['expected_status'], 'PREVIEW_STATUS')
                    check(p.get('detected_reader') == sample['expected_reader'], 'DETECTED_READER')
                    check(p['items_count'] == sample['items_count'] and p['pages_count'] == sample['pages_count'], 'READING_COUNTS')
                    check(request('POST', route, payload=data)['preview']['id'] == p['id'], 'PREVIEW_REPLAY')
                    items = request('GET', '/previews/' + p['id'] + '/items?limit=500')
                    if 'signed_values_cents' in sample:
                        check([i['data']['amount_cents'] for i in items] == sample['signed_values_cents'], 'INDEPENDENT_SIGNED_VALUES')
                    if 'date_amount_pairs' in sample:
                        # PDFs group credits/debits; CSV order can differ. Retain
                        # multiplicity: this is validation, never event identity.
                        check(Counter((i['data']['transaction_date'], i['data']['amount_cents']) for i in items)
                              == Counter(tuple(pair) for pair in sample['date_amount_pairs']), 'INDEPENDENT_DATE_AMOUNTS')
                    for field, value in sample.get('header', {}).items():
                        check(p['extracted_header'].get(field) == value, 'INDEPENDENT_HEADER')
                    errors = request('GET', '/previews/' + p['id'] + '/errors')
                    check({e['code'] for e in errors} == set(sample.get('errors', [])), 'EXPECTED_ERRORS')
                    pages = request('GET', '/previews/' + p['id'] + '/pages?limit=40')
                    check(len(pages) == sample['pages_count'] and all(page['text'] for page in pages), 'PAGE_EVIDENCE')
                    check(all(i['page_number'] and i['raw_text'] and i['data']['transaction_time'] is None for i in items), 'ITEM_EVIDENCE_UNKNOWN_TIME')
                    confirm = {'expected_source_id': source['id'], 'expected_result_sha256': p['result_sha256'],
                               'statement_type': 'BANK_STATEMENT' if source_type == 'BANK_ACCOUNT' else 'CARD_BILL'}
                    statement_id = None
                    if p['status'] == 'READY':
                        statement = request('POST', '/previews/' + p['id'] + '/confirm', payload=confirm)['statement']
                        statement_id = statement['id']
                        check(statement['pending_count'] == len(items), 'ALL_PENDING')
                        occurrences = request('GET', '/statements/' + statement_id + '/items?limit=500')
                        check([i['page_number'] for i in occurrences] == [i['page_number'] for i in items], 'STAGED_PAGES')
                        check(request('POST', '/previews/' + p['id'] + '/confirm', payload=confirm)['statement']['id'] == statement_id, 'CONFIRM_REPLAY')
                    else:
                        request('POST', '/previews/' + p['id'] + '/confirm', payload=confirm, expected=(409,))
                    check(request('GET', '/transactions') == [], 'NO_CANONICAL_EVENTS')
                    check(book_snapshot(path) == before, 'BOOKS_UNCHANGED')
                    stored.append((doc['id'], raw, p['id'], pages, statement_id))
                    report['samples'].append({'label': sample['label'], 'status': p['status'], 'pages': p['pages_count'],
                        'items': len(items), 'errors': [e['code'] for e in errors], 'checks': p['checks'],
                        'independent_values_checked': 'signed_values_cents' in sample or 'date_amount_pairs' in sample,
                        'independent_date_amount_pairs_checked': 'date_amount_pairs' in sample,
                        'independent_header_fields_checked': len(sample.get('header', {})),
                        'original_preserved': True, 'replay_preserved': True, 'pages_preserved': True,
                        'confirmation': 'PENDING_EVIDENCE_ONLY' if statement_id else 'BLOCKED', 'books_unchanged': True})
            backup, restored = directory / 'backup.db', directory / 'restored.db'
            create_backup(source_path=path, destination_path=backup)
            restore_backup(backup, target_path=restored)
            with closing(sqlite3.connect(restored)) as db:
                for doc_id, raw, preview_id, pages, statement_id in stored:
                    check(db.execute('SELECT content FROM financial_documents WHERE id=?', (doc_id,)).fetchone()[0] == raw, 'RESTORED_ORIGINAL')
                    result = json.loads(db.execute('SELECT result FROM financial_import_previews WHERE id=?', (preview_id,)).fetchone()[0])
                    check(result['pages'] == pages, 'RESTORED_PAGES')
                    if statement_id:
                        check(db.execute('SELECT preview_id FROM financial_statements WHERE id=?', (statement_id,)).fetchone()[0] == preview_id, 'RESTORED_LINK')
                check(db.execute('PRAGMA integrity_check').fetchone() == ('ok',), 'INTEGRITY')
                check(not db.execute('PRAGMA foreign_key_check').fetchall(), 'FOREIGN_KEYS')
            report['checks'] = {'backup_restore': True, 'integrity': True, 'foreign_keys': True, 'no_company_database': True}
        finally:
            app.dependency_overrides.clear()
            engine.dispose()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    try:
        manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
        inputs = {args.manifest.resolve(), *(Path(s['path']).resolve() for s in manifest['samples'])}
        check(args.report.resolve() not in inputs, 'REPORT_OVERWRITES_INPUT')
        report = run(manifest)
    except CheckFailed as exc:
        print(json.dumps({'status': 'FAIL', 'code': exc.code}))
        return 1
    except Exception:
        print(json.dumps({'status': 'FAIL', 'code': 'PDF_HOMOLOGATION_FAILED'}))
        return 1
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps(report))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
