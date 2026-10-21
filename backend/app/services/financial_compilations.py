"""Audited compilation layouts: independent segments, controls kept out of items.

Compiled summaries are evidence supplied by the operator, not bank originals.
No balance is assumed open, and missing dates/amounts remain absent.
"""
import csv
import datetime
import io
import re
from collections import defaultdict

from app.services.financial_normalization import normalize_card_data, normalized, control_kind
from app.schemas.financial_imports import FinancialTransactionData


def blank():
    return dict(items=[], errors=[], warnings=[], controls=[], checks=[], extracted_header={},
                header_candidates={}, complete=True, rows_read=0, blank_records=0,
                totals=dict(positive_cents=0, negative_cents=0, net_cents=0), observed_dates=None)


def money(value):
    from app.services.financial_pdf_readers import cents
    value = value.strip()
    value = re.sub(r'\s*\((?:M[IÍ]NIMO|[ÀA] VISTA|SALDO CREDOR)\)\s*$', '', value, flags=re.I)
    return None if value in {'', '-', '—', 'N/A'} else cents(value)


def date(value):
    value = value.strip()
    if value in {'', '-', '—', 'N/A'}:
        return None
    return datetime.datetime.strptime(value, '%d/%m/%Y' if '/' in value else '%Y-%m-%d').date().isoformat()


def finish(report):
    amounts = [i['data']['amount_cents'] for i in report['items']]
    report['totals'] = dict(positive_cents=sum(a for a in amounts if a > 0),
        negative_cents=-sum(a for a in amounts if a < 0), net_cents=sum(amounts))
    dates = [i['data']['transaction_date'] for i in report['items']]
    report['observed_dates'] = {'first': min(dates), 'last': max(dates)} if dates else None
    return report


def control(report, field, value, raw, page=None, kind='HEADER'):
    if value is None:
        return
    entry = dict(field=field, value=value, raw_text=raw, page_number=page,
                 kind=kind, origin='DOCUMENT')
    report['controls'].append(entry)
    if kind in {'HEADER', 'TOTAL'}:
        candidates = report['header_candidates'].setdefault(field, [])
        candidates.append(entry.copy())
        if len({c['value'] for c in candidates}) == 1:
            report['extracted_header'][field] = value
        else:
            report['extracted_header'].pop(field, None)


def item(report, txdate, description, amount, raw, page=None, observation=None):
    data = dict(transaction_date=date(txdate), description=description.strip(), amount_cents=money(amount),
                date_kind='AS_REPORTED')
    role = normalize_card_data(data)
    data = FinancialTransactionData.model_validate(data).model_dump(mode='json')
    report['items'].append(dict(position=len(report['items']) + 1, data=data, role=role,
                               raw_text=raw, page_number=page, observation=observation))


def metadata(rows):
    result = blank()
    segments = []
    result['document_notes'] = []
    combined, pending = [], None
    for row, raw, page in rows:
        if not row.get('INSTITUICAO'):
            pending = (row, raw, page)
            continue
        if pending and not row.get('TIPO_DOCUMENTO'):
            prior, prior_raw, prior_page = pending
            row = {k: (row.get(k) or prior.get(k, '')) for k in set(prior) | set(row)}
            raw, page = prior_raw + '\n' + raw, prior_page
        elif pending:
            result['document_notes'].append(pending[1])
        pending = None
        kind = normalized(row.get('TIPO_DOCUMENTO', ''))
        if not any(token in kind for token in ('FATURA','EXTRATO','RENEGOC')) and not row.get('REFERENCIA_MES_ANO'):
            result['document_notes'].append(raw)
            continue
        combined.append((row, raw, page))
    if pending:
        result['errors'].append({'code':'FINANCIAL_COMPILED_ROW_INVALID','fields':[]})
    rows = combined
    for n, (row, raw, page) in enumerate(rows, 1):
        segment = blank()
        kind = normalized(row.get('TIPO_DOCUMENTO', ''))
        segment.update(key=str(n), institution=row.get('INSTITUICAO', '').strip(),
            reference_label=row.get('REFERENCIA_MES_ANO', '').strip(),
            document_kind='BANK_STATEMENT_INDEX' if 'EXTRATO' in kind else 'RENEGOTIATION' if 'RENEGOC' in kind else 'CARD_SUMMARY' if 'FATURA' in kind else 'UNKNOWN_INDEX',
            content_type='SUMMARY_ONLY', compiled=True, raw_metadata=row)
        if segment['document_kind'] in {'CARD_SUMMARY', 'BANK_STATEMENT_INDEX'}:
            segment['extracted_header']['statement_type'] = 'BANK_STATEMENT' if segment['document_kind'] == 'BANK_STATEMENT_INDEX' else 'CARD_BILL'
        try:
            control(segment, 'due_on', date(row.get('DATA_VENCIMENTO', '')), raw, page)
            control(segment, 'total_amount_cents', money(row.get('VALOR_TOTAL_RS', '')), raw, page, 'TOTAL')
            # A combined minimum/settlement column is not proof of minimum payment.
            value = money(row.get('VALOR_MINIMO_OU_QUITACAO_RS', ''))
            control(segment, 'minimum_or_settlement_cents', value, raw, page, 'OFFER')
        except ValueError:
            segment['errors'].append({'code': 'FINANCIAL_SUMMARY_FIELD_INVALID', 'fields': []})
        segments.append(segment)
    result.update(content_type='SUMMARY_INDEX', compiled=True, segments=segments, rows_read=len(rows),
                  detected_reader='compiled_metadata_v1')
    return result


def referenced(rows, institution=''):
    grouped = defaultdict(list)
    for row, raw, page in rows:
        grouped[row['FATURA_REFERENCIA']].append((row, raw, page))
    result = blank()
    segments = []
    for reference, records in grouped.items():
        segment = blank()
        segment.update(key=str(len(segments)+1), institution=institution, reference_label=reference,
                       content_type='DETAILED_CARD_BILL', compiled=True, document_kind='CARD_DETAIL')
        segment['extracted_header']['statement_type'] = 'CARD_BILL'
        # This export explicitly calls the column fatura_referencia, not due date.
        # Keep it as a cycle hint; the actual due date must be supplied/confirmed.
        segment['reference_hint'] = date(reference)[:7]
        for row, raw, page in records:
            desc = row['DESCRICAO']
            text = normalized(desc)
            try:
                if control_kind(desc) or text.startswith(('FATURA ANTERIOR', 'OUTROS LANCAMENTOS')):
                    kind = control_kind(desc) or 'SUMMARY_COMPONENT'
                    field = 'total_amount_cents' if kind == 'TOTAL' else 'summary_component_cents'
                    control(segment, field, money(row['VALOR_RS']), raw, page, kind)
                    component = 'previous' if text.startswith('FATURA ANTERIOR') else 'purchases' if text.startswith('TOTAL DE COMPRAS') else 'other' if text.startswith('OUTROS LANCAMENTOS') else None
                    if component:
                        segment.setdefault('reported_summary', {})[component] = money(row['VALOR_RS'])
                else:
                    item(segment, row['DATA_LANCAMENTO'], desc, row['VALOR_RS'], raw, page, row.get('OBSERVACAO'))
            except ValueError:
                segment['errors'].append({'code': 'FINANCIAL_COMPILED_ROW_INVALID', 'fields': []})
            segment['rows_read'] += 1
        finish(segment)
        if not segment['items']:
            segment['content_type'] = 'SUMMARY_ONLY'
        segments.append(segment)
    result.update(content_type='MULTI_CYCLE_COMPILATION', compiled=True, segments=segments,
                  rows_read=sum(s['rows_read'] for s in segments), detected_reader='compiled_references_v1')
    return result


def csv_compilation(text, delimiter):
    reader = csv.DictReader(io.StringIO(text), delimiter=delimiter, strict=True)
    columns = [normalized(h) for h in reader.fieldnames or []]
    rows = []
    try:
        for row in reader:
            if len(rows) >= 2000 or None in row or any(v is None or len(v) > 8000 for v in row.values()):
                raise ValueError('bounded compilation')
            rows.append(({normalized(k): v for k,v in row.items()},
                         str(row), None))
        return metadata(rows) if 'INSTITUICAO' in columns else referenced(rows)
    except (ValueError, KeyError, csv.Error):
        result = blank()
        result['errors'].append({'code': 'FINANCIAL_COMPILED_ROW_INVALID', 'fields': []})
        return result


def table_cells(page, names):
    """Recompose wrapped cells around date/institution row anchors, by coordinates."""
    lines = page['lines']
    if names[0] == 'FATURA_REFERENCIA' and not page.get('horizontal_edges') and 'OBSERVACAO' not in names:
        rows = []
        for line in lines:
            match = re.fullmatch(r'(\d{4}-\d{2}-\d{2})\s+(\d{4}-\d{2}-\d{2})\s+(.+?)\s+(-?\s*\d+(?:\.\d{3})*,\d{2})', line['text'].strip())
            if match:
                rows.append((dict(zip(names, match.groups())), line['text'], page['page_number']))
        return rows
    rows = []
    for h, line in enumerate(lines):
        words = line['words']
        headers = {normalized(w['text']): w['x0'] for w in words}
        if not all(name in headers for name in names):
            continue
        starts = [headers[n] for n in names]
        end = next((j for j in range(h+1, len(lines)) if any(normalized(w['text']) == names[0] for w in lines[j]['words'])), len(lines))
        body = [w for l in lines[h+1:end] for w in l['words']]
        end_top = lines[end]['bbox'][1] if end < len(lines) else page['height']
        boundaries = sorted({round(e['top'], 2) for e in page.get('horizontal_edges', [])
            if e['x0'] <= starts[0] < e['x1'] and line['bbox'][3] <= e['top'] < end_top})
        if len(boundaries) >= 2:
            bands = list(zip(boundaries, boundaries[1:]))
        else:
            anchors = sorted({w['top'] for w in body if starts[0]-1 <= w['x0'] < starts[1]-2})
            bands = [((anchors[i-1]+top)/2 if i else line['bbox'][3],
                      (top+anchors[i+1])/2 if i+1<len(anchors) else end_top) for i,top in enumerate(anchors)]
        for low, high in bands:
            cells = {}
            for col, name in enumerate(names):
                right = starts[col+1]-2 if col+1 < len(starts) else max((w['x1'] for w in body), default=page['width'])+1
                selected = [w for w in body if low <= w['top'] < high and starts[col]-1 <= w['x0'] < right]
                selected.sort(key=lambda w: (round(w['top'], 1), w['x0']))
                cells[name] = ' '.join(w['text'] for w in selected)
            partial = names[0] == 'INSTITUICAO' and any(t in normalized(cells.get('TIPO_DOCUMENTO','')) for t in ('FATURA','EXTRATO','RENEGOC'))
            if (cells[names[0]] or partial) and not normalized(cells[names[0]]).startswith('NOTA TECNICA'):
                rows.append((cells, ' | '.join(cells.values()), page['page_number']))
    return rows


META_COLUMNS = ['INSTITUICAO','TIPO_DOCUMENTO','REFERENCIA_MES_ANO','DATA_EMAIL_EMISSAO',
                'DATA_VENCIMENTO','VALOR_TOTAL_RS','VALOR_MINIMO_OU_QUITACAO_RS',
                'ARQUIVO_ORIGINAL_NO_GMAIL','STATUS_PROTECAO_ANEXO']
REF_COLUMNS = ['FATURA_REFERENCIA','DATA_LANCAMENTO','DESCRICAO','VALOR_RS','OBSERVACAO']


def pdf_compilation(pages):
    whole = normalized('\n'.join(p['text'] for p in pages))
    if 'INSTITUICAO' in whole and 'REFERENCIA_MES_ANO' in whole:
        rows = [row for p in pages for row in table_cells(p, META_COLUMNS)]
        return metadata(rows)
    if 'FATURA_REFERENCIA' in whole:
        columns = REF_COLUMNS if 'OBSERVACAO' in whole else REF_COLUMNS[:-1]
        result = referenced([row for p in pages for row in table_cells(p, columns)], institution='NUBANK' if 'NUBANK' in whole else '')
        for page in pages:
            for line in page['lines']:
                match = re.fullmatch(r'RESUMO\s+(.+?)\s+\(VENC\.\s*(\d{2}/\d{2}/\d{4})\):\s*(R\$\s*[\d.]+,\d{2})', normalized(line['text']))
                if match:
                    row = dict(INSTITUICAO='NUBANK', TIPO_DOCUMENTO='Fatura', REFERENCIA_MES_ANO=match[1],
                        DATA_VENCIMENTO=match[2], VALOR_TOTAL_RS=match[3])
                    segment = metadata([(row,line['text'],page['page_number'])])['segments'][0]
                    segment['key'] = str(len(result['segments'])+1)
                    result['segments'].append(segment)
        return result
    # The supplied two-cycle detail PDF prints a separate heading for each cycle.
    dues = re.findall(r'VENCIMENTO\s+(\d{2}/\d{2}/\d{4})', whole)
    if len(set(dues)) > 1 and any('DATE TITLE AMOUNT' in normalized(p['text']) or 'DATA TITULO VALOR' in normalized(p['text']) for p in pages):
        result, segments, segment = blank(), [], None
        for page in pages:
            for line in page['lines']:
                due = re.search(r'VENCIMENTO\s+(\d{2}/\d{2}/\d{4})', normalized(line['text']))
                if due:
                    segment = blank()
                    segment.update(key=str(len(segments)+1), institution='NUBANK' if 'NUBANK' in whole else '', compiled=True,
                        reference_label=due[1], document_kind='CARD_DETAIL', content_type='DETAILED_CARD_BILL')
                    segment['extracted_header']['statement_type'] = 'CARD_BILL'
                    control(segment, 'due_on', date(due[1]), line['text'], page['page_number'])
                    segments.append(segment)
                match = re.fullmatch(r'(\d{4}-\d{2}-\d{2})\s+(.+?)\s+(-?\s*\d+(?:\.\d{3})*,\d{2})', line['text'].strip())
                if match and segment is not None:
                    item(segment, match[1], match[2], match[3], line['text'], page['page_number'])
                    segment['rows_read'] += 1
                elif re.match(r'^\d{4}-\d{2}-\d{2}', line['text'].strip()):
                    target = segment if segment is not None else result
                    target['errors'].append({'code':'PDF_UNPARSED_DATED_ROW','page_number':page['page_number'],'fields':[]})
        result.update(content_type='MULTI_CYCLE_COMPILATION', compiled=True,
                      segments=[finish(s) for s in segments], rows_read=sum(len(s['items']) for s in segments),
                      detected_reader='compiled_cycles_v1')
        return result
    return None
