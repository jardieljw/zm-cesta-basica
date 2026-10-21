"""Atomic single-cycle integration. Reading, debt and economic purpose are distinct."""
import datetime
import calendar
import uuid
from sqlalchemy import select
from app.core.idempotency import compute_payload_hash
from app.models.financial import AccountPayable, PayablePayment
from app.models.financial_imports import FinancialImportPreview, FinancialSource, FinancialStatement, FinancialStatementItem
from app.models.financial_bill_semantics import FinancialBillObligation
from app.models.financial_bill_cycles import FinancialBillCycle as Cycle, FinancialBillCycleRevision as Revision, FinancialBillCycleItem as Item, FinancialBillPayableLink as Link
from app.models.purchases import Purchase
from app.schemas.financial_imports import FinancialStatementCreate
from app.services import financial_imports as evidence
from app.services.financial_normalization import card_role
from app.services import financial_bill_enrichment as enrichment

PARTS = ('stock_cents', 'business_cents', 'personal_cents', 'unclassified_cents')
PURPOSE_PART = {'STOCK': 'stock_cents', 'BUSINESS': 'business_cents', 'PERSONAL_WITHDRAWAL': 'personal_cents', 'UNSPECIFIED': 'unclassified_cents'}


def find_cycle(db, source_id, reference):
    return db.scalar(select(Cycle).where(Cycle.source_id == source_id, Cycle.reference == reference))


def current(db, cycle):
    return db.scalar(select(Revision).where(Revision.cycle_id == cycle.id, Revision.revision == cycle.revision))


def describe(db, cycle):
    from app.services.financial_import_removals import withdrawn_cycles, hidden_payables
    revision = current(db, cycle)
    source = evidence.require(db, FinancialSource, cycle.source_id)
    payable = db.get(AccountPayable, cycle.payable_id) if cycle.payable_id else None
    rows = db.scalars(select(FinancialStatementItem).where(FinancialStatementItem.statement_id == revision.statement_id).order_by(FinancialStatementItem.position)).all()
    meanings = {i.item_id: i for i in db.scalars(select(Item).where(Item.revision_id == revision.id))}
    from app.models.financial_installments import InstallmentOccurrence, InstallmentForecast
    from app.services.financial_installments import assigned
    occurrences = list(db.scalars(select(InstallmentOccurrence).where(InstallmentOccurrence.revision_id == revision.id)))
    series_ids = {assigned(db, o) for o in occurrences} - {None}
    return {'version': 1, 'cycle_id': cycle.id, 'reference': cycle.reference, 'revision': cycle.revision,
        'revision_id': revision.id, 'statement_id': revision.statement_id, 'preview_id': revision.preview_id,
        'payable_id': cycle.payable_id if cycle.payable_id not in hidden_payables(db) else None, 'destination': revision.destination,
        'details_status': revision.details_status, 'difference_cents': revision.difference_cents,
        'total_amount_cents': revision.total_cents, 'due_on': revision.due_on.isoformat(),
        'balance_cents': payable.balance_cents if payable else 0, 'payable_status': payable.status if payable else None,
        'financial_source': {'id': source.id, 'name': source.name, 'institution': source.institution},
        'composition': {p: getattr(revision, p) for p in PARTS},
        'control_origin': revision.control_origin,
        'control_provenance': revision.provenance,
        'items': [{'item_id': row.id, 'position': row.position, **row.normalized_data,
            'observation': revision.provenance.get('item_observations', {}).get(str(row.position)),
            'provenance': revision.provenance.get('item_provenance', {}).get(str(row.position), {'statement_id': revision.statement_id}),
            'role': meanings[row.id].role, 'purpose': meanings[row.id].purpose} for row in rows],
        'installments': {'version': 1, 'series_ids': sorted(series_ids),
            'forecast_ids': list(db.scalars(select(InstallmentForecast.id).where(InstallmentForecast.series_id.in_(series_ids)))),
            'pending_occurrence_ids': [o.id for o in occurrences if assigned(db, o) is None]},
        'import_withdrawn': cycle.id in withdrawn_cycles(db),
        'affects_ledger': False}


def draft(db, preview_id, reference=None):
    preview = evidence.require(db, FinancialImportPreview, preview_id)
    source = evidence.require(db, FinancialSource, preview.source_id)
    report = preview.result
    header = report.get('extracted_header', {})
    reference = reference or header.get('due_on', '')[:7] or None
    reference = reference or report.get('reference_hint')
    # A resolved conflict may leave the immutable reading without a due date.
    # Recover its recorded cycle by identity, never by another document's date.
    if not reference:
        bound = list(db.scalars(select(Cycle).join(Revision, Revision.cycle_id == Cycle.id).where(
            Revision.preview_id == preview.id, Cycle.source_id == source.id).distinct().limit(2)))
        if len(bound) == 1:
            reference = bound[0].reference
    cycle = find_cycle(db, source.id, reference) if reference else None
    from app.services.financial_import_removals import withdrawn_cycles
    comparison = enrichment.comparison(db, current(db, cycle) if cycle and cycle.id not in withdrawn_cycles(db) else None, report,
        header.get('total_amount_cents'), header.get('due_on'))
    controls = []
    from app.services.financial_import_lifecycle import active_preview_ids
    for p in db.scalars(select(FinancialImportPreview).where(FinancialImportPreview.source_id == source.id,
            FinancialImportPreview.id.in_(active_preview_ids())).order_by(FinancialImportPreview.created_at.desc())):
        other = p.result
        h = other.get('extracted_header', {})
        if p.id != preview.id and other.get('content_type') in {'DETAILED_CARD_BILL','SUMMARY_ONLY'} and h.get('due_on') and h.get('total_amount_cents') is not None and (not reference or h['due_on'][:7] == reference) and not any(len({c['value'] for c in v}) > 1 for v in other.get('header_candidates', {}).values()):
            controls.append(dict(preview_id=p.id, due_on=h['due_on'], total_amount_cents=h['total_amount_cents'], compiled=other.get('compiled', False)))
    replacement_candidates = []
    positions = {i['position']: i['data'] for i in report['items']}
    for payable in db.scalars(select(AccountPayable).where(AccountPayable.status.in_(['OPEN','PARTIAL']), AccountPayable.superseded_by_id.is_(None))):
        if cycle and payable.id == cycle.payable_id:
            continue
        base = dict(payable_id=payable.id, payable_number=payable.payable_number, description=payable.description,
                    expected_balance_cents=payable.balance_cents, due_on=payable.due_date.date().isoformat())
        prior_cycle = db.scalar(select(Cycle).where(Cycle.payable_id == payable.id, Cycle.source_id == source.id))
        if prior_cycle and reference and prior_cycle.reference < reference:
            replacement_candidates.append({**base, 'kind':'PREVIOUS_BALANCE'})
        if payable.purchase_id:
            for position, row in positions.items():
                if row['amount_cents'] == payable.balance_cents:
                    replacement_candidates.append({**base, 'kind':'PURCHASE', 'position':position})
        legacy = db.scalar(select(FinancialBillObligation.id).join(FinancialStatement, FinancialStatement.id == FinancialBillObligation.statement_id).where(
            FinancialBillObligation.account_payable_id == payable.id, FinancialStatement.source_id == source.id))
        if legacy and payable.due_date.strftime('%Y-%m') == reference:
            replacement_candidates.append({**base, 'kind':'LEGACY'})
    return {'version': 1, 'expected_revision': cycle.revision if cycle else 0,
        'reference': reference, 'header': header, 'readiness': report.get('readiness'),
        'comparison': comparison, 'control_candidates': controls, 'header_candidates': report.get('header_candidates', {}),
        'replacement_candidates': replacement_candidates,
        'read_errors': [{'code':e['code'],'page_number':e.get('page_number')} for e in report.get('errors',[]) if e['code'] not in {'PDF_SUMMARY_DETAIL_MISMATCH','PDF_SUMMARY_CONTROLS_REQUIRED','PDF_NO_TRANSACTIONS','PDF_CONFLICTING_HEADER','FINANCIAL_DUE_DATE_CONFLICT'}],
        'financial_source': evidence.as_dict(source), 'cycle': describe(db, cycle) if cycle else None,
        'items': [{'position': i['position'], **i['data'], 'observation': i.get('observation'), 'role': i.get('role', 'UNKNOWN'), 'purpose': 'UNSPECIFIED'} for i in report['items']],
        'can_integrate': source.source_type == 'CREDIT_CARD' and report.get('contract_version') == 1,
        'affects_ledger': False}


def confirmed_parts(db, payable_id):
    values = dict.fromkeys(PARTS, 0)
    for payment in db.scalars(select(PayablePayment).where(PayablePayment.payable_id == payable_id, PayablePayment.status == 'CONFIRMED')):
        if payment.bill_revision_id is None:
            evidence.fail('FINANCIAL_BILL_LEGACY_PAYMENT_REVIEW', 'Pagamentos anteriores exigem conferencia antes de alterar esta cobranca.')
        for part in PARTS:
            values[part] += getattr(payment, part)
    return values


def integrate(db, preview_id, data, actor):
    from app.services import financial_import_lifecycle as lifecycle
    entry, preview = lifecycle.require_preview(db, preview_id, data.import_id, data.expected_generation)
    source = evidence.require(db, FinancialSource, preview.source_id)
    report = enrichment.prepare(db, preview.result, data, source.id)
    if source.source_type != 'CREDIT_CARD' or data.expected_source_id != source.id:
        evidence.fail('FINANCIAL_IMPORT_SOURCE_MISMATCH', 'Confira a origem selecionada.')
    if source.currency != 'BRL':
        evidence.fail('FINANCIAL_IMPORT_CURRENCY_MISMATCH', 'A cobranca do aplicativo exige valores em reais, sem conversao presumida.')
    if data.expected_result_sha256 != preview.result_sha256:
        evidence.fail('FINANCIAL_PREVIEW_CHANGED', 'A leitura mudou; atualize a conferencia.')
    if report.get('contract_version') != 1:
        evidence.fail('FINANCIAL_REIMPORT_REQUIRED', 'Reprocesse o documento com o leitor atual.')
    if not data.controls_confirmed:
        evidence.fail('FINANCIAL_BILL_CONTROLS_REQUIRED', 'Confira total, vencimento e situacao da divida.')
    if report.get('content_type') in {'MULTI_CYCLE_COMPILATION', 'SUMMARY_INDEX', 'UNKNOWN', 'BANK_STATEMENT_INDEX', 'RENEGOTIATION', 'UNKNOWN_INDEX'}:
        evidence.fail('FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED', 'Selecione uma fatura de ciclo unico.')
    if report.get('segment_provenance'):
        for other in db.scalars(select(FinancialImportPreview).join(Revision, Revision.preview_id == FinancialImportPreview.id).where(
            FinancialImportPreview.document_id == preview.document_id, FinancialImportPreview.source_id != source.id)):
            if other.result.get('segment_provenance', {}).get('segment_key') == report['segment_provenance']['segment_key']:
                evidence.fail('FINANCIAL_BILL_CYCLE_CONFLICT', 'Este segmento ja foi vinculado a outra origem. Confira o vinculo existente.')
    allowed = {'PDF_SUMMARY_DETAIL_MISMATCH', 'PDF_SUMMARY_CONTROLS_REQUIRED', 'PDF_NO_TRANSACTIONS'}
    if any(e['code'] not in allowed for e in report['errors']):
        evidence.fail('FINANCIAL_PREVIEW_INVALID', 'Resolva os erros de leitura ou controles antes de confirmar.')
    extracted = report.get('extracted_header', {})
    for field in ('due_on', 'total_amount_cents'):
        value = getattr(data, field)
        value = value.isoformat() if field == 'due_on' else value
        if extracted.get(field) is not None and extracted[field] != value:
            evidence.fail('FINANCIAL_PDF_HEADER_CONFLICT', 'O controle confirmado diverge do documento.')
    cycle = find_cycle(db, source.id, data.reference)
    command_hash = compute_payload_hash(data.model_dump(mode='json', exclude={'expected_revision'}))
    previous = current(db, cycle) if cycle else None
    from app.services.financial_import_removals import withdrawn_cycles, reinstate_cycle, hidden_payables
    reinstating = bool(cycle and cycle.id in withdrawn_cycles(db))
    if previous and not reinstating and previous.preview_id == preview.id and previous.command_sha256 == command_hash:
        return {**describe(db, cycle), 'import_id': entry.id,
                'generation': entry.generation, 'duplicate': True}
    if data.expected_revision != (cycle.revision if cycle else 0):
        evidence.fail('FINANCIAL_BILL_REVISION_CONFLICT', 'Outra conferencia alterou este ciclo. Atualize antes de confirmar.')
    comparison = enrichment.comparison(db, None if reinstating else previous, report, data.total_amount_cents, data.due_on.isoformat())
    if comparison['requires_decision'] and not data.accept_content_change:
        evidence.fail('FINANCIAL_BILL_CONTENT_CONFLICT', 'A redacao, multiplicidade ou controles divergem da conferencia anterior. Compare e confirme a revisao.')
    inherited = enrichment.old_items(db, previous) if comparison['details'] in {'KEEP_EXISTING','SAME'} else []
    if inherited:
        report['items'] = inherited if comparison['details'] == 'KEEP_EXISTING' else enrichment.preserve_meanings(inherited, report['items'])
        report['totals']['net_cents'] = sum(i['data']['amount_cents'] for i in inherited)
    if previous and not reinstating:
        prior_report = evidence.require(db, FinancialImportPreview, previous.preview_id).result
        known_summary = previous.provenance.get('reported_summary') or prior_report.get('reported_summary', {})
        # Missing components in a summary do not retract previously proved controls.
        # Conflicting supplied components have already required an explicit revision.
        report['reported_summary'] = {**known_summary, **report.get('reported_summary', {})}
    # A document already bound to a cycle cannot be reused under another identity.
    old_bind = db.scalar(select(Revision).where(Revision.preview_id == preview.id))
    if old_bind and (not cycle or old_bind.cycle_id != cycle.id):
        evidence.fail('FINANCIAL_BILL_CYCLE_CONFLICT', 'Este documento ja pertence a outro ciclo.')

    decisions = {i.position: i for i in data.items}
    rows = {i['position']: i for i in report['items']}
    if set(decisions) - set(rows):
        evidence.fail('FINANCIAL_ITEM_NOT_FOUND', 'Uma decisao nao pertence ao documento.')
    meanings = {}
    for position, row in rows.items():
        decision = decisions.get(position)
        role = row.get('role') or card_role(row['data']['description'], row['data']['amount_cents'])
        if decision and decision.role is not None:
            if role != 'UNKNOWN' and role != decision.role:
                evidence.fail('FINANCIAL_BILL_ROLE_CONFLICT', 'O papel declarado diverge da leitura comprovada.')
            role = decision.role
        amount = row['data']['amount_cents']
        if role in {'PURCHASE','CHARGE','PREVIOUS_BALANCE'} and amount <= 0 or role in {'PAYMENT','CREDIT'} and amount >= 0:
            evidence.fail('FINANCIAL_BILL_ROLE_CONFLICT', 'Confira o sinal do papel informado.')
        meanings[position] = (role, decision.purpose if decision else row.get('purpose', 'UNSPECIFIED'))

    summary = report.get('reported_summary', {})
    previous_amount = summary.get('previous', sum(r['data']['amount_cents'] for p,r in rows.items() if meanings[p][0] == 'PREVIOUS_BALANCE'))
    payments = summary.get('payments', sum(r['data']['amount_cents'] for p,r in rows.items() if meanings[p][0] == 'PAYMENT'))
    carry = max(0, previous_amount + payments)
    expected = data.total_amount_cents - previous_amount
    explicit_previous = sum(r['data']['amount_cents'] for p,r in rows.items() if meanings[p][0] == 'PREVIOUS_BALANCE')
    difference = report.get('totals', {}).get('net_cents', 0) - explicit_previous - expected if rows else None
    details_status = 'SUMMARY_ONLY' if not rows else 'RECONCILED' if difference == 0 and not report['errors'] and all(r != 'UNKNOWN' for r,p in meanings.values()) else 'AVAILABLE_UNRECONCILED'
    if comparison['details'] == 'KEEP_EXISTING' and previous.total_cents == data.total_amount_cents:
        details_status, difference = previous.details_status, previous.difference_cents
    if details_status != 'RECONCILED' and not data.accept_details_pending:
        evidence.fail('FINANCIAL_BILL_DETAILS_PENDING', 'Confira a diferenca e confirme que os detalhes permanecem pendentes.')

    target = db.get(AccountPayable, cycle.payable_id) if cycle and cycle.payable_id else None
    if reinstating and data.destination == 'OPEN':
        from app.services.financial_import_removals import validate_reinstatement
        validate_reinstatement(db, cycle)
    if target and data.destination != 'OPEN' and target.id not in hidden_payables(db):
        evidence.fail('FINANCIAL_BILL_ACTIVE_DESTINATION', 'Uma cobranca existente exige revisao propria para sair do aberto.')
    legacy = list(db.scalars(select(AccountPayable).join(FinancialBillObligation, FinancialBillObligation.account_payable_id == AccountPayable.id)
        .join(FinancialStatement, FinancialStatement.id == FinancialBillObligation.statement_id)
        .where(FinancialStatement.source_id == source.id,
               FinancialStatement.due_on >= datetime.date(data.due_on.year, data.due_on.month, 1),
               FinancialStatement.due_on <= data.due_on.replace(day=calendar.monthrange(data.due_on.year, data.due_on.month)[1]))).unique())
    # Filter by actual civil month, including the last days of short months.
    # A removed import keeps its statement and obligation history for audit, but
    # those withdrawn payables no longer represent an active legacy bill to link.
    withdrawn_payable_ids = hidden_payables(db)
    legacy = [p for p in legacy if p.id not in withdrawn_payable_ids
              and p.due_date.strftime('%Y-%m') == data.reference
              and (p.superseded_by_id is None or target and p.superseded_by_id == target.id)]
    replacement_decisions = list(data.replacements)
    if cycle and target:
        from app.schemas.financial_bill_cycles import BillReplacement
        for link in db.scalars(select(Link).where(Link.cycle_id == cycle.id, Link.kind != 'PRIMARY')):
            old = db.get(AccountPayable, link.payable_id)
            if not old or old.superseded_by_id != target.id or any(r.payable_id == old.id for r in replacement_decisions):
                continue
            position = None
            if link.kind == 'PURCHASE':
                original = db.get(FinancialStatementItem, link.item_id)
                matches = [p for p,row in rows.items() if enrichment.fingerprint(row['data']) == enrichment.fingerprint(original.normalized_data)]
                if len(matches) != 1:
                    continue
                position = matches[0]
            replacement_decisions.append(BillReplacement(payable_id=old.id, expected_balance_cents=old.balance_cents,
                kind=link.kind, position=position, reason=link.reason))
    replacements = []
    for replacement in replacement_decisions:
        old = evidence.require(db, AccountPayable, replacement.payable_id)
        prior_link = db.scalar(select(Link).where(Link.payable_id == old.id, Link.kind != 'PRIMARY'))
        represented_here = bool(target and old.superseded_by_id == target.id and prior_link and prior_link.cycle_id == cycle.id)
        if data.destination != 'OPEN' or target and old.id == target.id or (not represented_here and (old.status not in {'OPEN','PARTIAL'} or old.superseded_by_id)) or old.balance_cents != replacement.expected_balance_cents:
            evidence.fail('FINANCIAL_BILL_REPLACEMENT_CONFLICT', 'Confira o saldo integral ainda aberto do titulo a substituir.')
        if replacement.kind == 'PURCHASE':
            row = rows.get(replacement.position)
            purchase = db.get(Purchase, old.purchase_id) if old.purchase_id else None
            if not row or not purchase or purchase.status != 'CONFIRMED' or row['data']['amount_cents'] != old.balance_cents or meanings[replacement.position][0] != 'PURCHASE':
                evidence.fail('FINANCIAL_PURCHASE_ALLOCATION_REQUIRED', 'A compra deve representar exatamente o saldo integral informado.')
            meanings[replacement.position] = ('PURCHASE', 'STOCK')
        elif replacement.kind == 'LEGACY':
            if old.id not in {p.id for p in legacy}:
                evidence.fail('FINANCIAL_BILL_LEGACY_REVIEW', 'O titulo legado nao pertence a este ciclo.')
        else:
            old_cycle = db.scalar(select(Cycle).where(Cycle.payable_id == old.id))
            if not old_cycle or old_cycle.source_id != source.id or old_cycle.reference >= data.reference:
                evidence.fail('FINANCIAL_BILL_PREVIOUS_BALANCE_LINK', 'O saldo anterior exige vinculo comprovado ao mesmo cartao e ciclo anterior.')
        replacements.append((replacement, old))
    if data.destination == 'OPEN':
        represented_legacy = {r.payable_id for r in replacement_decisions if r.kind == 'LEGACY'}
        if {p.id for p in legacy} != represented_legacy or legacy and sum(p.balance_cents for p in legacy) != max(data.total_amount_cents, 0):
            evidence.fail('FINANCIAL_BILL_LEGACY_REVIEW', 'Confira os titulos e pagamentos legados deste ciclo antes de substituir a divida.')
        if sum(r.expected_balance_cents for r in replacement_decisions if r.kind == 'PREVIOUS_BALANCE') != carry:
            evidence.fail('FINANCIAL_BILL_PREVIOUS_BALANCE_LINK', 'Identifique o saldo anterior representado antes de ativar a cobranca.')
        if previous_amount > 0 and payments < 0 and carry == 0:
            prior_open = db.scalar(select(Cycle.id).join(AccountPayable, AccountPayable.id == Cycle.payable_id).where(
                Cycle.source_id == source.id, Cycle.reference < data.reference, AccountPayable.status.in_(['OPEN','PARTIAL'])))
            if prior_open:
                evidence.fail('FINANCIAL_BILL_PREVIOUS_BALANCE_LINK', 'O pagamento impresso nao baixa uma cobranca anterior aberta. Confira seu pagamento existente antes de seguir.')
    purchase_positions = [r.position for r in replacement_decisions if r.kind == 'PURCHASE']
    if len(set(purchase_positions)) != len(purchase_positions) or any(purpose == 'STOCK' and p not in purchase_positions for p,(role,purpose) in meanings.items()):
        evidence.fail('FINANCIAL_PURCHASE_ALLOCATION_REQUIRED', 'Estoque exige vinculo unico com compra existente.')

    parts = dict.fromkeys(PARTS, 0)
    for position, row in rows.items():
        role, purpose = meanings[position]
        if role in {'PURCHASE','CHARGE','CREDIT'}:
            parts[PURPOSE_PART[purpose]] += row['data']['amount_cents']
    for replacement, old in replacements:
        if replacement.kind == 'PREVIOUS_BALANCE':
            old_cycle = db.scalar(select(Cycle).where(Cycle.payable_id == old.id))
            old_revision, used = current(db, old_cycle), confirmed_parts(db, old.id)
            for part in PARTS:
                parts[part] += getattr(old_revision, part) - used[part]
    ambiguous_credit = any(role == 'CREDIT' and purpose == 'UNSPECIFIED' for role,purpose in meanings.values()) and any(
        role in {'PURCHASE','CHARGE'} and purpose != 'UNSPECIFIED' for role,purpose in meanings.values())
    if ambiguous_credit or any(v < 0 for v in parts.values()) or sum(parts.values()) != max(data.total_amount_cents, 0) or details_status != 'RECONCILED':
        # Unknown credit/carry/difference never becomes a fictitious business allocation.
        parts = dict.fromkeys(PARTS, 0)
        parts['unclassified_cents'] = max(data.total_amount_cents, 0)
    if target:
        if target.superseded_by_id or target.status == 'CANCELED' and previous.total_cents > 0 and target.id not in hidden_payables(db):
            evidence.fail('FINANCIAL_BILL_REPLACEMENT_CONFLICT', 'Esta cobranca exige revisao do vinculo financeiro.')
        paid_parts = confirmed_parts(db, target.id)
        if data.total_amount_cents < target.paid_amount_cents or any(parts[p] < paid_parts[p] for p in PARTS):
            evidence.fail('FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT', 'O novo total ou composicao nao pode apagar pagamentos anteriores.')
    # All validation precedes the first new domain row; transaction covers staging too.
    header = {k:v for k,v in extracted.items() if k in {'period_start','period_end','issued_on','closing_on','minimum_payment_cents'}}
    staged = evidence.create_statement(db, FinancialStatementCreate(document_id=preview.document_id, source_id=source.id,
        statement_type='CARD_BILL', due_on=data.due_on, total_amount_cents=data.total_amount_cents, **header,
        items=[{k:v for k,v in {**row, **({'page_number':None} if comparison['details'] == 'KEEP_EXISTING' else {})}.items()
                if k in {'position','page_number','raw_text','data'}} for row in report['items']]), actor, preview_id=preview.id)['statement']
    statement = staged
    if cycle is None:
        cycle = Cycle(id=str(uuid.uuid4()), source_id=source.id, reference=data.reference, revision=0)
        db.add(cycle)
        db.flush()
    destination = 'CREDIT' if data.destination == 'OPEN' and data.total_amount_cents <= 0 else data.destination
    revision = Revision(id=str(uuid.uuid4()), cycle_id=cycle.id, revision=cycle.revision+1,
        statement_id=statement['id'], preview_id=preview.id, command_sha256=command_hash,
        total_cents=data.total_amount_cents, due_on=data.due_on, destination=destination,
        details_status=details_status, difference_cents=difference, control_origin='DOCUMENT' if all(extracted.get(f) is not None for f in ('due_on','total_amount_cents')) else 'OPERATOR_DECLARATION',
        provenance={'version':1,'preview_result_sha256':preview.result_sha256,'controls':report.get('controls', []), 'controls_confirmed':True,
            'comparison':comparison, 'inherited_revision_id':previous.id if inherited else None,
            'control_statement_id':staged['id'], 'reported_summary':report.get('reported_summary', {}),
            'item_provenance':{str(i['position']): previous.provenance.get('item_provenance', {}).get(str(i['position']),
                {'statement_id':previous.statement_id, 'document_id':db.get(FinancialStatement,previous.statement_id).document_id,
                 'page_number':i.get('page_number')}) for i in inherited} if comparison['details'] == 'KEEP_EXISTING' else {},
            'due_resolution':report.get('due_resolution'), 'control_complement':report.get('control_complement'),
            'segment':report.get('segment_provenance'), 'compiled':report.get('compiled', False),
            'item_observations':{str(i['position']):i['observation'] for i in report['items'] if i.get('observation')},
            'content_change_confirmed':data.accept_content_change,
            'replacement_snapshots':[r.model_dump(mode='json') for r in replacement_decisions]},
        reason=data.reason, created_by=actor, **parts)
    db.add(revision)
    db.flush()
    statement_rows = {r.position:r for r in db.scalars(select(FinancialStatementItem).where(FinancialStatementItem.statement_id == statement['id']))}
    for position,(role,purpose) in meanings.items():
        db.add(Item(id=str(uuid.uuid4()), revision_id=revision.id, item_id=statement_rows[position].id, role=role, purpose=purpose))
    if destination == 'OPEN':
        if target is None:
            from app.services.financial import generate_next_payable_number
            target = AccountPayable(id=str(uuid.uuid4()), payable_number=generate_next_payable_number(db),
                description=f'Fatura {source.name} · {data.reference}', beneficiary=source.institution,
                category='CARTAO_CREDITO', nature='UNCLASSIFIED', original_amount_cents=data.total_amount_cents,
                paid_amount_cents=0, balance_cents=data.total_amount_cents,
                due_date=datetime.datetime.combine(data.due_on, datetime.time.min), payment_method='BOLETO', status='OPEN')
            db.add(target)
            db.flush()
            db.add(Link(id=str(uuid.uuid4()), cycle_id=cycle.id, revision_id=revision.id, payable_id=target.id,
                kind='PRIMARY', amount_cents=data.total_amount_cents, reason=data.reason, created_by=actor))
        else:
            target.original_amount_cents = data.total_amount_cents
            target.balance_cents = data.total_amount_cents - target.paid_amount_cents
            target.due_date = datetime.datetime.combine(data.due_on, datetime.time.min)
            target.status = 'PAID' if target.balance_cents == 0 else 'PARTIAL' if target.paid_amount_cents else 'OPEN'
        for replacement, old in replacements:
            if old.superseded_by_id == target.id:
                continue
            old.status = 'SUBSTITUTED'
            old.superseded_by_id = target.id
            if not db.scalar(select(Link.id).where(Link.cycle_id == cycle.id, Link.payable_id == old.id, Link.kind == replacement.kind)):
                db.add(Link(id=str(uuid.uuid4()), cycle_id=cycle.id, revision_id=revision.id, payable_id=old.id,
                    kind=replacement.kind, item_id=statement_rows[replacement.position].id if replacement.position else None,
                    amount_cents=old.balance_cents, reason=replacement.reason, created_by=actor))
    elif target and destination == 'CREDIT':
        target.status, target.balance_cents = 'CANCELED', 0
    cycle.revision, cycle.payable_id = revision.revision, target.id if target else None
    db.flush()
    if destination == 'OPEN':
        reinstate_cycle(db, cycle, entry, actor)
    from app.services.financial_installments import sync_cycle
    sync_cycle(db, cycle, revision, statement_rows, meanings, estimate_day=data.estimate_installment_day)
    from app.models.financial_installments import InstallmentSeries
    series_ids = [s.id for s in db.scalars(select(InstallmentSeries).where(
        InstallmentSeries.source_id == source.id))
        if (db.get(Revision, s.provenance.get('revision_id')) and
            db.get(Revision, s.provenance.get('revision_id')).cycle_id == cycle.id)]
    represented_ids = [old.id for replacement, old in replacements if old.superseded_by_id == target.id] if target else []
    lifecycle.record_cycle(db, entry, preview, cycle, revision, series_ids=series_ids,
                           represented_ids=represented_ids, actor=actor)
    evidence.audit(db, actor, 'BILL_CYCLE_INTEGRATED', revision, {'cycle_id':cycle.id,'revision':revision.revision,'destination':destination})
    return {**describe(db, cycle), 'import_id': entry.id,
            'generation': entry.generation, 'duplicate': False}
