"""Versioned reading readiness. Preparing a bill never means posting a debt."""
from app.schemas.financial_readers import PreviewControl, PreviewReadiness, PreviewItemMeaning


def enrich_report(report, *, document_id, reader_id, reader_version, source_type):
    report['contract_version'] = 1
    for segment in report.get('segments', []):
        enrich_report(segment, document_id=document_id, reader_id=reader_id,
                      reader_version=reader_version, source_type='CREDIT_CARD')
    for item in report['items']:
        item.update(PreviewItemMeaning(role=item.get('role', 'UNKNOWN')).model_dump())
    report.setdefault('content_type', 'BANK_STATEMENT' if source_type == 'BANK_ACCOUNT' else 'DETAILED_CARD_BILL')
    controls = []
    for control in report.get('controls', []):
        controls.append(PreviewControl.model_validate({
            'document_id': document_id, 'reader_id': reader_id, 'reader_version': reader_version,
            **control,
        }).model_dump(mode='json'))
    report['controls'] = controls
    for values in report.get('header_candidates', {}).values():
        for candidate in values:
            candidate.update(document_id=document_id, reader_id=reader_id, reader_version=reader_version)
    header = report.get('extracted_header', {})
    candidates = report.get('header_candidates', {})
    conflicting = any(len({c['value'] for c in values}) > 1 for values in candidates.values())
    required = ('due_on', 'total_amount_cents') if source_type == 'CREDIT_CARD' else (
        'period_start', 'period_end', 'opening_balance_cents', 'closing_balance_cents',
        'total_inflows_cents', 'total_outflows_cents')
    has_header = all(header.get(f) is not None for f in required)
    summary = report.get('reported_summary', {})
    expected = None
    if set(summary) == {'previous', 'payments', 'purchases', 'other'}:
        expected = summary['payments'] + summary['purchases'] + summary['other']
    elif has_header and source_type == 'CREDIT_CARD':
        expected = header['total_amount_cents']
    difference = report['totals']['net_cents'] - expected if expected is not None and report['items'] else None
    pending = []
    if source_type == 'CREDIT_CARD':
        for field in ('due_on', 'total_amount_cents'):
            if header.get(field) is None:
                pending.append({'code': 'HEADER_CONFLICT' if candidates.get(field) else 'HEADER_MISSING',
                                'fields': [field], 'blocks_header': True})
    for issue in report['errors']:
        pending.append({'code': issue['code'], 'fields': issue.get('fields', []),
                        'blocks_header': issue['code'] not in {'PDF_SUMMARY_DETAIL_MISMATCH'},
                        'blocks_details': True})
    if report.get('segments') is not None:
        pending.append({'code': 'SEGMENT_SELECTION_REQUIRED', 'blocks_header': True})
    if difference not in (None, 0):
        pending.append({'code': 'DETAIL_TOTAL_DIFFERENCE', 'blocks_details': True})
    unknown = source_type == 'CREDIT_CARD' and any(i.get('role') == 'UNKNOWN' for i in report['items'])
    if unknown and source_type == 'CREDIT_CARD':
        pending.append({'code': 'ITEM_ROLE_UNKNOWN', 'blocks_details': True})
    complete = bool(report['items']) and report.get('complete', True) and bool(report.get('checks')) and all(
        c['matches'] for c in report['checks']) and not report['errors'] and not unknown
    can_prepare = source_type == 'CREDIT_CARD' and has_header and not conflicting and not any(
        p.get('blocks_header') for p in pending)
    declared = any(c['origin'] == 'OPERATOR_DECLARATION' for c in controls)
    report['readiness'] = PreviewReadiness(
        header_status='CONFLICTING' if conflicting else ('OPERATOR_DECLARED' if declared else 'DOCUMENT_VALIDATED') if has_header else 'MISSING',
        details_status='SUMMARY_ONLY' if not report['items'] else 'RECONCILED' if complete else 'AVAILABLE_UNRECONCILED',
        total_basis='DOCUMENT' if header.get('total_amount_cents') is not None else 'CALCULATED_ONLY' if report['items'] else 'MISSING',
        difference_cents=difference, can_prepare_bill=can_prepare,
        can_prepare_complete_details=can_prepare and complete, pending=pending,
    ).model_dump(mode='json')
    return report
