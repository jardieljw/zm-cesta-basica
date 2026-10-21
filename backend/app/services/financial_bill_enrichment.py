"""Compare complete multisets, retaining every revision and its provenance."""
import copy
from collections import Counter, defaultdict, deque
from sqlalchemy import select
from app.models.financial_imports import FinancialStatementItem, FinancialImportPreview
from app.models.financial_bill_cycles import FinancialBillCycleItem
from app.services import financial_imports as evidence


def fingerprint(data):
    return tuple(data.get(k) for k in ('transaction_date', 'description', 'amount_cents',
        'installment_number', 'total_installments', 'card_last_four', 'external_id_namespace', 'external_id'))


def old_items(db, revision):
    if revision is None:
        return []
    meanings = {i.item_id:i for i in db.scalars(select(FinancialBillCycleItem).where(FinancialBillCycleItem.revision_id == revision.id))}
    observations = revision.provenance.get('item_observations', {})
    return [dict(position=i.position, data=i.normalized_data, raw_text=i.raw_text, page_number=i.page_number,
                 observation=observations.get(str(i.position)),
                 role=meanings[i.id].role, purpose=meanings[i.id].purpose)
            for i in db.scalars(select(FinancialStatementItem).where(FinancialStatementItem.statement_id == revision.statement_id).order_by(FinancialStatementItem.position))]


def preserve_meanings(previous, incoming):
    buckets = defaultdict(deque)
    for row in previous:
        buckets[fingerprint(row['data'])].append(row)
    for row in incoming:
        known = buckets[fingerprint(row['data'])].popleft()
        row['purpose'] = known['purpose']
        row['role'] = known['role']
        if not row.get('observation') and known.get('observation'):
            row['observation'] = known['observation']
    return incoming


def comparison(db, revision, report, total=None, due=None):
    old, new = old_items(db, revision), report['items']
    same = Counter(fingerprint(i['data']) for i in old) == Counter(fingerprint(i['data']) for i in new)
    changed = bool(old and new and not same)
    notes_changed = False
    if same:
        notes = defaultdict(deque)
        for row in old:
            notes[fingerprint(row['data'])].append(row.get('observation'))
        for row in new:
            known = notes[fingerprint(row['data'])].popleft()
            if known and row.get('observation') and known != row['observation']:
                notes_changed = True
    controls = bool(revision and ((total is not None and total != revision.total_cents) or
                                  (due is not None and due != revision.due_on.isoformat())))
    if revision:
        prior = revision.provenance.get('reported_summary') or evidence.require(db, FinancialImportPreview, revision.preview_id).result.get('reported_summary', {})
        incoming = report.get('reported_summary', {})
        controls = controls or any(prior[k] != incoming[k] for k in prior.keys() & incoming.keys())
    return dict(details='SAME' if same else 'KEEP_EXISTING' if old and not new else 'ENRICH' if not old and new else 'DIVERGENT',
                previous_count=len(old), incoming_count=len(new), requires_decision=changed or controls or notes_changed,
                controls_changed=controls, observations_changed=notes_changed)


def prepare(db, report, data, source_id):
    report = copy.deepcopy(report)
    report.setdefault('extracted_header', {})
    candidates = report.get('header_candidates', {})
    conflicts = {f for f, values in candidates.items() if len({c['value'] for c in values}) > 1}
    if conflicts:
        if conflicts != {'due_on'} or not data.due_conflict_resolved or data.due_on.isoformat() not in {c['value'] for c in candidates['due_on']}:
            evidence.fail('FINANCIAL_DUE_DATE_CONFLICT', 'Escolha um dos vencimentos comprovados e registre a decisao.')
        report['extracted_header']['due_on'] = data.due_on.isoformat()
        report['due_resolution'] = dict(due_on=data.due_on.isoformat(), reason=data.reason, candidates=candidates['due_on'])
        report['errors'] = [e for e in report['errors'] if e['code'] not in {'FINANCIAL_DUE_DATE_CONFLICT', 'PDF_CONFLICTING_HEADER', 'PDF_BILL_HEADER_REQUIRED'}]
    if data.control_preview_id:
        complement = evidence.require(db, FinancialImportPreview, data.control_preview_id)
        from app.services.financial_import_lifecycle import entry_for_preview
        if entry_for_preview(db, complement.id) is None:
            evidence.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY', 'O documento complementar não está ativo.')
        other = complement.result
        if complement.source_id != source_id or other.get('content_type') not in {'DETAILED_CARD_BILL', 'SUMMARY_ONLY'}:
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Escolha controles do mesmo cartao e ciclo.')
        header = other.get('extracted_header', {})
        if any(len({c['value'] for c in v}) > 1 for v in other.get('header_candidates', {}).values()) or (
            header.get('due_on') != data.due_on.isoformat() or header.get('total_amount_cents') != data.total_amount_cents):
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Os controles do complemento divergem do ciclo conferido.')
        hint = report.get('reference_hint')
        if hint and hint != data.reference:
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'A referencia do documento diverge do complemento.')
        if report.get('observed_dates') and report['observed_dates']['last'] > data.due_on.isoformat():
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'As linhas ultrapassam o vencimento complementar.')
        report['control_complement'] = dict(preview_id=complement.id, result_sha256=complement.result_sha256,
            document_id=complement.document_id, compiled=other.get('compiled', False))
        report.setdefault('controls', []).extend(other.get('controls', []))
        for field in ('due_on', 'total_amount_cents'):
            if report['extracted_header'].get(field) not in (None, header[field]):
                evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Os controles dos documentos divergem.')
            report['extracted_header'][field] = header[field]
    if report.get('reference_hint') and report['reference_hint'] != data.reference:
        evidence.fail('FINANCIAL_BILL_CYCLE_CONFLICT', 'Confira o mes de referencia indicado pelo documento.')
    return report
