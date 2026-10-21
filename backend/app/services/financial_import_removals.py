"""Atomic withdrawal of effects owned by one import generation."""
from sqlalchemy import select
from app.core.idempotency import compute_payload_hash
from app.models.base import utc_now
from app.models.financial_imports import FinancialDocument, FinancialImportEntry as Entry, FinancialImportEntrySegment as Segment, FinancialImportPreview as Preview, FinancialStatement as Statement, FinancialStatementItem as Item
from app.models.financial_bill_cycles import FinancialBillCycle as Cycle, FinancialBillCycleRevision as Revision, FinancialBillPayableLink as Link
from app.models.financial import AccountPayable, PayablePayment
from app.models.financial_bill_semantics import FinancialBillObligation


def state(db, document_id):
    from app.services.financial_import_lifecycle import latest
    return latest(db, document_id)


def removed_documents(db):
    return select(Entry.document_id).where(Entry.state == 'REMOVED',
        Entry.document_id.not_in(select(Entry.document_id).where(Entry.state == 'ACTIVE')))


def withdrawn_cycles(db):
    return {cid for row in db.scalars(select(Entry))
            for cid in row.retained_effects.get('cycle_ids', [])
            if cid not in row.retained_effects.get('reinstated_cycle_ids', [])
            and cid not in row.released_effects.get('cycle_ids', [])}


def hidden_payables(db):
    return {pid for row in db.scalars(select(Entry))
            for pid in row.retained_effects.get('payable_ids', [])
            if pid not in row.retained_effects.get('reinstated_payable_ids', [])
            and pid not in row.released_effects.get('payable_ids', [])}


def hidden_series(db):
    return {sid for row in db.scalars(select(Entry))
            for sid in row.retained_effects.get('series_ids', [])
            if sid not in row.released_effects.get('series_ids', [])}


def _title_snapshot(title):
    values = {key: getattr(title, key) for key in (
        'status', 'balance_cents', 'paid_amount_cents', 'original_amount_cents',
        'superseded_by_id', 'nature', 'category', 'description', 'beneficiary')}
    values['due_date'] = title.due_date.replace(tzinfo=None).isoformat()
    return values


def validate_reinstatement(db, cycle):
    from app.services.financial_imports import fail
    if not cycle.payable_id:
        return
    title = db.get(AccountPayable, cycle.payable_id)
    for row in db.scalars(select(Entry)):
        if (cycle.id not in row.retained_effects.get('cycle_ids', []) or
                cycle.id in row.retained_effects.get('reinstated_cycle_ids', []) or
                cycle.id in row.released_effects.get('cycle_ids', []) or
                title.id not in row.retained_effects.get('payable_ids', [])):
            continue
        snapshot = row.retained_effects.get('payable_snapshots', {}).get(title.id)
        if not snapshot:
            fail('FINANCIAL_IMPORT_LEGACY_REVIEW_REQUIRED',
                 'A retirada antiga desta conta precisa de conferência antes de restabelecer a cobrança.')
        current = _title_snapshot(title)
        actual = {key: current.get(key) for key in snapshot}
        paid = db.scalar(select(PayablePayment.id).where(
            PayablePayment.payable_id == title.id, PayablePayment.status == 'CONFIRMED').limit(1))
        if actual != snapshot or paid:
            fail('FINANCIAL_IMPORT_REINSTATEMENT_CONFLICT',
                 'A conta mudou depois da exclusão. Confira a conta e os pagamentos antes de restabelecer a cobrança.')


def assert_active(db, document_id):
    from app.services.financial_import_lifecycle import active
    if not active(db, document_id):
        from app.services.financial_imports import fail
        fail('FINANCIAL_IMPORT_REMOVED', 'Esta importação não está ativa. Selecione o arquivo e leia novamente para criar uma nova importação.')


def reinstate_cycle(db, cycle, entry, actor):
    """Release a retained effect only after an explicit confirmed integration."""
    from app.services.financial_imports import audit, fail
    if entry.state != 'ACTIVE':
        fail('FINANCIAL_IMPORT_GENERATION_CONFLICT', 'Atualize a importação antes de confirmar.')
    for row in db.scalars(select(Entry)):
        if cycle.id not in row.retained_effects.get('cycle_ids', []):
            continue
        if cycle.id in row.retained_effects.get('reinstated_cycle_ids', []) or cycle.id in row.released_effects.get('cycle_ids', []):
            continue
        payable = db.get(AccountPayable, cycle.payable_id) if cycle.payable_id else None
        if payable and (payable.paid_amount_cents or payable.status == 'CANCELED'):
            fail('FINANCIAL_IMPORT_REINSTATEMENT_CONFLICT',
                 'A conta mudou durante a conferência. Atualize os dados antes de continuar.')
        released = dict(row.released_effects)
        released['cycle_ids'] = sorted(set(released.get('cycle_ids', [])) | {cycle.id})
        if payable:
            released['payable_ids'] = sorted(set(released.get('payable_ids', [])) | {payable.id})
        from app.models.financial_installments import InstallmentSeries
        series_ids = []
        for sid in row.retained_effects.get('series_ids', []):
            series = db.get(InstallmentSeries, sid)
            revision = db.get(Revision, series.provenance.get('revision_id')) if series else None
            if revision and revision.cycle_id == cycle.id:
                series_ids.append(sid)
        released['series_ids'] = sorted(set(released.get('series_ids', [])) | set(series_ids))
        row.released_effects, row.updated_at = released, utc_now()
        audit(db, actor, 'IMPORT_EFFECT_REINSTATED', row,
              {'by_import_id': entry.id, 'by_generation': entry.generation,
               'cycle_id': cycle.id, 'payable_id': payable.id if payable else None})
    db.flush()
    if cycle.id in withdrawn_cycles(db) or cycle.payable_id and cycle.payable_id in hidden_payables(db):
        fail('FINANCIAL_IMPORT_REINSTATEMENT_CONFLICT', 'Outra retirada ainda protege esta conta.')


def _strings(value):
    if isinstance(value, dict):
        return set().union(*(_strings(v) for v in value.values())) if value else set()
    if isinstance(value, list):
        return set().union(*(_strings(v) for v in value)) if value else set()
    return {value} if isinstance(value, str) else set()


def plan(db, document_id, import_id=None, expected_generation=None):
    from app.services.financial_import_lifecycle import require_generation
    entry = require_generation(db, document_id, expected_generation, import_id=import_id)
    document = db.get(FinancialDocument, document_id)
    segments = list(db.scalars(select(Segment).where(Segment.import_id == entry.id)))
    preview_ids = {entry.root_preview_id} | {s.preview_id for s in segments}
    previews = list(db.scalars(select(Preview).where(Preview.id.in_(preview_ids))))
    statement_ids = set(entry.effects.get('statement_ids', []))
    statement_ids |= {s.statement_id for s in segments if s.statement_id}
    if entry.statement_id:
        statement_ids.add(entry.statement_id)
    items = list(db.scalars(select(Item).where(Item.statement_id.in_(statement_ids))))
    refs = {document_id} | preview_ids | statement_ids | {i.id for i in items}
    cycle_ids = set(entry.effects.get('cycle_ids', []))
    cycles = list(db.scalars(select(Cycle).where(Cycle.id.in_(cycle_ids))))
    blocked = []
    def block(code, message, **target):
        entry = {'code':code, 'message':message, **target}
        if entry not in blocked:
            blocked.append(entry)
    inactive = withdrawn_cycles(db)
    # A summary/enrichment or later cycle may depend on another document's facts.
    from app.services.financial_import_lifecycle import entry_for_preview
    for revision in db.scalars(select(Revision).join(Cycle, Cycle.id == Revision.cycle_id).where(Cycle.revision == Revision.revision)):
        if revision.cycle_id in inactive:
            continue
        other = db.get(Preview, revision.preview_id)
        owner = entry_for_preview(db, other.id)
        if owner and owner.id != entry.id and (revision.cycle_id in cycle_ids or _strings(revision.provenance) & refs):
            block('DEPENDENT_DOCUMENT', 'Outro documento usa informações desta importação. Exclua primeiro a importação indicada abaixo.',
                  document_id=other.document_id, filename=db.get(FinancialDocument, other.document_id).filename,
                  import_id=owner.id, generation=owner.generation)
    from app.models.financial_installments import InstallmentOccurrence as Occurrence
    origin_series_ids = set(entry.effects.get('series_ids', []))
    from app.services.financial_installments import assigned
    for occurrence in db.scalars(select(Occurrence).join(Revision, Revision.id == Occurrence.revision_id).join(Cycle, Cycle.id == Revision.cycle_id).where(Cycle.revision == Revision.revision)):
        rev = db.get(Revision, occurrence.revision_id)
        if rev.cycle_id not in cycle_ids | inactive and assigned(db, occurrence) in origin_series_ids:
            other = db.get(Preview, rev.preview_id)
            owner = entry_for_preview(db, other.id)
            if owner and owner.id != entry.id:
                block('DEPENDENT_DOCUMENT', 'Uma fatura posterior usa estas parcelas. Exclua primeiro a importação indicada abaixo.',
                      document_id=other.document_id, filename=db.get(FinancialDocument, other.document_id).filename,
                      import_id=owner.id, generation=owner.generation)
    payables = set(entry.effects.get('payable_ids', []))
    payables.discard(None)
    titles = list(db.scalars(select(AccountPayable).where(AccountPayable.id.in_(payables))))
    payments = list(db.scalars(select(PayablePayment).where(PayablePayment.payable_id.in_(payables))))
    represented_ids = set(entry.effects.get('represented_payables_to_restore', []))
    represented = list(db.scalars(select(AccountPayable).where(AccountPayable.id.in_(represented_ids))))
    for title in represented:
        if title.superseded_by_id not in payables:
            block('OTHER_ACCOUNT_LINK',
                  'Uma conta vinculada a esta fatura mudou. Confira a conta antes de excluir a importação.',
                  payable_id=title.id, payable_number=title.payable_number)
    for title in titles:
        if title.paid_amount_cents or any(p.payable_id == title.id and p.status == 'CONFIRMED' for p in payments):
            block('PAYMENT_EXISTS', 'Esta conta tem pagamento registrado. Abra a conta e confira esse pagamento antes de excluir.', payable_id=title.id, payable_number=title.payable_number)
        if title.superseded_by_id:
            successor = db.scalar(select(Cycle).where(Cycle.payable_id == title.superseded_by_id))
            if successor:
                successor_revision = db.scalar(select(Revision).where(Revision.cycle_id == successor.id, Revision.revision == successor.revision))
                successor_document = db.get(Preview, successor_revision.preview_id).document_id
                block('DEPENDENT_DOCUMENT', 'Uma fatura posterior reuniu esta conta. Exclua primeiro a importação indicada para devolver as contas anteriores.', document_id=successor_document, filename=db.get(FinancialDocument, successor_document).filename)
            else:
                block('OTHER_ACCOUNT_LINK', 'Esta conta faz parte de outro registro financeiro que precisa ser conferido antes da exclusão.', payable_id=title.id, payable_number=title.payable_number)
        if title.purchase_id:
            block('OTHER_ACCOUNT_LINK', 'Esta conta pertence a uma compra cadastrada separadamente. A exclusão não pode apagar a compra.', payable_id=title.id, payable_number=title.payable_number)
    effects = {key: sorted(set(entry.effects.get(key, []))) for key in (
        'statement_ids', 'cycle_ids', 'bill_revision_ids', 'payable_ids', 'series_ids',
        'represented_payables_to_restore', 'semantic_review_ids', 'assessment_ids', 'link_ids')}
    snapshot = compute_payload_hash({'document':document_id, 'import_id':entry.id,
        'generation':entry.generation, 'state':entry.state, 'root_preview_id':entry.root_preview_id,
        'previews':sorted((p.id,p.result_sha256) for p in previews),
        'revisions':sorted((c.id,c.revision) for c in cycles),
        'titles':sorted((p.id,p.status,p.balance_cents,p.paid_amount_cents,p.superseded_by_id) for p in titles+represented),
        'payments':sorted((p.id,p.status,p.amount_cents) for p in payments), 'effects':effects,'blocked':blocked})
    return {'version':2,'document_id':document_id,'import_id':entry.id,'generation':entry.generation,
        'filename':document.filename,'snapshot':snapshot,'already_removed':False,
        'can_remove':not blocked, 'blocked':blocked,
        'payables':[{'id':p.id,'number':p.payable_number,'balance_cents':p.balance_cents} for p in titles],
        'restored_payables':[{'id':p.id,'number':p.payable_number,'balance_cents':p.balance_cents} for p in represented],
        'preview_count':len(previews),'series_count':len(origin_series_ids),'effects':effects,
        'original_records_preserved':True,'payments_automatically_reversed':False}


def remove(db, document_id, import_id, expected_generation, expected_snapshot, actor):
    from app.services.financial_imports import fail, audit
    value = plan(db, document_id, import_id, expected_generation)
    if value['snapshot'] != expected_snapshot:
        fail('FINANCIAL_IMPORT_REMOVAL_CHANGED', 'Esta importação mudou. Confira novamente o que será excluído.')
    if not value['can_remove']:
        fail('FINANCIAL_IMPORT_REMOVAL_BLOCKED', value['blocked'][0]['message'])
    row = db.get(Entry, import_id)
    retained = dict(row.retained_effects)
    for name, ids in value['effects'].items():
        retained[name] = sorted(set(retained.get(name, [])) | set(ids))
    row.retained_effects = retained
    row.state, row.removed_by, row.removed_at, row.updated_at = 'REMOVED', actor, utc_now(), utc_now()
    db.flush()
    for pid in value['effects']['payable_ids']:
        title = db.get(AccountPayable, pid)
        title.status, title.balance_cents, title.updated_at = 'CANCELED', 0, utc_now()
    snapshots = {pid: _title_snapshot(db.get(AccountPayable, pid)) for pid in value['effects']['payable_ids']}
    row.retained_effects = {**row.retained_effects, 'payable_snapshots': snapshots}
    for pid in value['effects']['represented_payables_to_restore']:
        title = db.get(AccountPayable, pid)
        title.superseded_by_id = None
        title.status = 'PAID' if title.balance_cents == 0 else 'PARTIAL' if title.paid_amount_cents else 'OPEN'
        title.updated_at = utc_now()
    db.flush()
    audit(db, actor, 'IMPORT_REMOVED', row, {'generation':row.generation,
        'snapshot':expected_snapshot, **value['effects']})
    return {**value,'removed':True,'duplicate':False}
