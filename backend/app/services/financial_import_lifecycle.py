"""Operational import generations over immutable document and preview evidence."""
import uuid

from sqlalchemy import select, func, or_

from app.models.base import utc_now
from app.models.financial_imports import (
    FinancialDocument, FinancialImportEntry as Entry,
    FinancialImportEntrySegment as Segment, FinancialImportPreview as Preview,
    FinancialStatement, FinancialStatementItem,
)


def _fail(code, message, status=409, **details):
    from app.services.financial_imports import fail
    if details:
        from fastapi import HTTPException
        raise HTTPException(status, detail={"error_code": code, "message": message, **details})
    fail(code, message, status)


def latest(db, document_id):
    return db.scalar(select(Entry).where(Entry.document_id == document_id)
                     .order_by(Entry.generation.desc()).limit(1))


def active(db, document_id):
    return db.scalar(select(Entry).where(Entry.document_id == document_id,
                                         Entry.state == 'ACTIVE'))


def state(db, document_id):
    if db.get(FinancialDocument, document_id) is None:
        _fail('FINANCIAL_RESOURCE_NOT_FOUND', 'Arquivo financeiro não encontrado.', 404)
    current = latest(db, document_id)
    selected = current if current and current.state == 'ACTIVE' else None
    return {'lifecycle_version': 1, 'document_id': document_id,
            'current_generation': current.generation if current else 0,
            'active_import': ({'id': selected.id, 'generation': selected.generation,
                               'state': selected.state} if selected else None),
            'root_preview_id': selected.root_preview_id if selected else None}


def require_generation(db, document_id, expected_generation, *, import_id=None):
    if expected_generation is None or import_id is None:
        _fail('FINANCIAL_CLIENT_UPDATE_REQUIRED',
              'Atualize o aplicativo para conferir esta importação com segurança.')
    current = latest(db, document_id)
    generation = current.generation if current else 0
    if generation != expected_generation:
        _fail('FINANCIAL_IMPORT_GENERATION_CONFLICT',
              'Esta importação mudou. Atualize a lista antes de continuar.',
              current_generation=generation)
    if current is None or current.id != import_id or current.state != 'ACTIVE':
        _fail('FINANCIAL_IMPORT_GENERATION_CONFLICT',
              'Esta importação não está ativa. Atualize a lista antes de continuar.',
              current_generation=generation)
    return current


def require_preview(db, preview_id, import_id, expected_generation):
    preview = db.get(Preview, preview_id)
    if preview is None:
        _fail('FINANCIAL_RESOURCE_NOT_FOUND', 'Leitura financeira não encontrada.', 404)
    entry = require_generation(db, preview.document_id, expected_generation,
                               import_id=import_id)
    if preview.id != entry.root_preview_id:
        segment = db.get(Segment, (entry.id, _segment_key(preview)))
        if not segment or segment.preview_id != preview.id:
            _fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY',
                  'Esta leitura pertence ao histórico. Abra a importação atual pela lista.')
    return entry, preview


def _segment_key(preview):
    return (preview.result.get('segment_provenance') or {}).get('segment_key') or ''


def entry_for_preview(db, preview_id):
    entry = db.scalar(select(Entry).where(Entry.state == 'ACTIVE',
                                          Entry.root_preview_id == preview_id))
    if entry:
        return entry
    return db.scalar(select(Entry).join(Segment, Segment.import_id == Entry.id).where(
        Entry.state == 'ACTIVE', Segment.preview_id == preview_id))


def entry_for_statement(db, statement_id):
    entry = db.scalar(select(Entry).where(Entry.state == 'ACTIVE',
                                          Entry.statement_id == statement_id))
    if entry:
        return entry
    return db.scalar(select(Entry).join(Segment, Segment.import_id == Entry.id).where(
        Entry.state == 'ACTIVE', Segment.statement_id == statement_id))


def statement_context(db, statement_id):
    owner = entry_for_statement(db, statement_id)
    return {'import_id': owner.id, 'generation': owner.generation} if owner else {}


def active_statement_ids():
    root_ids = select(Entry.statement_id).where(Entry.state == 'ACTIVE', Entry.statement_id.is_not(None))
    child_ids = select(Segment.statement_id).join(Entry, Entry.id == Segment.import_id).where(
        Entry.state == 'ACTIVE', Segment.statement_id.is_not(None))
    return select(FinancialStatement.id).where(or_(
        FinancialStatement.preview_id.is_(None),
        FinancialStatement.id.in_(root_ids), FinancialStatement.id.in_(child_ids)))


def active_preview_ids():
    root_ids = select(Entry.root_preview_id).where(Entry.state == 'ACTIVE')
    child_ids = select(Segment.preview_id).join(Entry, Entry.id == Segment.import_id).where(Entry.state == 'ACTIVE')
    return select(Preview.id).where(or_(Preview.id.in_(root_ids), Preview.id.in_(child_ids)))


def inactive_statement_ids():
    return select(FinancialStatement.id).where(FinancialStatement.preview_id.is_not(None),
                                                FinancialStatement.id.not_in(active_statement_ids()))


def current_statement(db, statement_id):
    statement = db.get(FinancialStatement, statement_id)
    if statement is None:
        _fail('FINANCIAL_RESOURCE_NOT_FOUND', 'Registro financeiro não encontrado.', 404)
    if statement.preview_id and entry_for_statement(db, statement_id) is None:
        _fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY',
              'Este registro pertence ao histórico. Abra a importação atual pela lista.')
    return statement


def guard_statement(db, statement_id, command):
    statement = current_statement(db, statement_id)
    if statement.preview_id is None:
        return None
    entry = require_generation(db, statement.document_id,
        getattr(command, 'expected_generation', None), import_id=getattr(command, 'import_id', None))
    owner = entry_for_statement(db, statement_id)
    if owner is None or owner.id != entry.id:
        _fail('FINANCIAL_IMPORT_GENERATION_CONFLICT', 'Atualize a importação antes de continuar.')
    return entry


def guard_item(db, item_id, command):
    item = db.get(FinancialStatementItem, item_id)
    if item is None:
        _fail('FINANCIAL_RESOURCE_NOT_FOUND', 'Linha financeira não encontrada.', 404)
    return guard_statement(db, item.statement_id, command)


def guard_transaction(db, transaction_id, command):
    from app.services.financial_review_corrections import effective_items
    view = effective_items()
    statements = list(db.scalars(select(FinancialStatement).where(
        FinancialStatement.id.in_(select(view.c.statement_id).where(view.c.transaction_id == transaction_id)))))
    if not statements:
        _fail('FINANCIAL_TRANSACTION_INACTIVE', 'Esta operação não tem evidência ativa para conferir.')
    if not getattr(command, 'import_id', None) and any(s.preview_id is None for s in statements):
        return None
    for statement in statements:
        owner = entry_for_statement(db, statement.id) if statement.preview_id else None
        if owner and owner.id == getattr(command, 'import_id', None):
            return guard_statement(db, statement.id, command)
    _fail('FINANCIAL_IMPORT_GENERATION_CONFLICT' if getattr(command, 'import_id', None)
          else 'FINANCIAL_CLIENT_UPDATE_REQUIRED',
          'Abra a importação atual e confira novamente esta operação.')


def record_ids(db, entry, key, ids):
    if entry is None:
        return
    entry.effects = {**entry.effects, key: sorted(set(entry.effects.get(key, [])) | set(ids))}
    entry.updated_at = utc_now()
    db.flush()


def preview_summary(db, entry, preview):
    from app.services.financial_previews import preview_summary as base_summary
    from app.models.financial_bill_cycles import FinancialBillCycle as Cycle, FinancialBillCycleRevision as Revision
    from app.models.financial import AccountPayable
    from app.services.financial_import_removals import hidden_payables, withdrawn_cycles
    document = db.get(FinancialDocument, entry.document_id)
    summary = base_summary(preview)
    segment = db.get(Segment, (entry.id, _segment_key(preview))) if preview.id != entry.root_preview_id else None
    statement_id = segment.statement_id if segment else entry.statement_id
    revision_ids = ([segment.bill_revision_id] if segment and segment.bill_revision_id else
                    entry.effects.get('bill_revision_ids', []) if segment is None else [])
    current = list(db.execute(select(Revision, Cycle).join(Cycle, Cycle.id == Revision.cycle_id).where(
        Revision.id.in_(revision_ids), Revision.revision == Cycle.revision,
        Cycle.id.not_in(withdrawn_cycles(db)))))
    hidden = hidden_payables(db)
    payable_ids = {c.payable_id for r, c in current if r.destination == 'OPEN' and c.payable_id not in hidden}
    cycle_payables = select(Cycle.payable_id).where(Cycle.payable_id.is_not(None))
    if segment is None:
        payable_ids.update(db.scalars(select(AccountPayable.id).where(
            AccountPayable.id.in_(entry.effects.get('payable_ids', [])),
            AccountPayable.id.not_in(cycle_payables), AccountPayable.id.not_in(hidden),
            AccountPayable.status != 'CANCELED')))
    payable_ids.discard(None)
    destinations = {r.destination for r, c in current}
    summary.update(import_id=entry.id, generation=entry.generation,
                   filename=document.filename, import_state=entry.state,
                   statement_id=statement_id,
                   financial_status='CONFIRMED' if entry.effects.get('statement_ids') else 'PENDING',
                   recorded_payable_ids=sorted(payable_ids), recorded_payables_count=len(payable_ids),
                   recorded_payable_id=next(iter(payable_ids)) if len(payable_ids) == 1 else None,
                   recorded_destination=(next(iter(destinations)) if len(destinations) == 1 else
                                         'MIXED' if destinations else None))
    return summary


def activate_root(db, document_id, preview, actor, expected_generation,
                  *, explicit_reprocess=False, expected_root_preview_id=None):
    from app.services.financial_imports import audit
    current = latest(db, document_id)
    generation = current.generation if current else 0
    if expected_generation is None:
        _fail('FINANCIAL_CLIENT_UPDATE_REQUIRED',
              'Atualize o aplicativo para importar com segurança.')
    if expected_generation != generation:
        _fail('FINANCIAL_IMPORT_GENERATION_CONFLICT',
              'Esta importação mudou. Atualize a lista antes de continuar.',
              current_generation=generation)
    if preview.document_id != document_id or preview.result.get('segment_provenance'):
        _fail('FINANCIAL_IMPORT_ROOT_INVALID', 'Esta leitura não é a raiz do arquivo.')
    if current and current.state == 'ACTIVE':
        if current.root_preview_id == preview.id:
            return current, False
        if not explicit_reprocess or expected_root_preview_id != current.root_preview_id:
            _fail('FINANCIAL_IMPORT_ACTIVE',
                  'Este arquivo já está em conferência. Abra o cadastro existente para continuar.',
                  import_id=current.id, generation=current.generation,
                  root_preview_id=current.root_preview_id)
        if any(isinstance(value, list) and value for value in current.effects.values()) or current.statement_id or current.bill_revision_id or db.scalar(
                select(Segment.segment_key).where(Segment.import_id == current.id).limit(1)):
            _fail('FINANCIAL_IMPORT_CONFIRMED',
                  'Este arquivo já tem dados confirmados. Confira o cadastro antes de alterar a leitura.')
        previous_root = current.root_preview_id
        current.root_preview_id = preview.id
        current.updated_at = utc_now()
        audit(db, actor, 'IMPORT_REPROCESSED', current,
              {'generation': current.generation, 'previous_root_preview_id': previous_root,
               'root_preview_id': preview.id})
        db.flush()
        return current, False
    entry = Entry(id=str(uuid.uuid4()), document_id=document_id,
                  generation=generation + 1, state='ACTIVE',
                  root_preview_id=preview.id, effects={}, retained_effects={},
                  released_effects={}, created_by=actor)
    db.add(entry)
    db.flush()
    audit(db, actor, 'IMPORT_GENERATION_CREATED', entry,
          {'document_id': document_id, 'generation': entry.generation,
           'root_preview_id': preview.id})
    return entry, True


def attach_segment(db, entry, parent, child, segment_key, actor):
    from app.services.financial_imports import audit
    if parent.id != entry.root_preview_id and not db.scalar(select(Segment.preview_id).where(
            Segment.import_id == entry.id, Segment.preview_id == parent.id)):
        _fail('FINANCIAL_IMPORT_SEGMENT_PARENT', 'Esta fatura não pertence à importação aberta.')
    provenance = child.result.get('segment_provenance') or {}
    if (parent.document_id != entry.document_id or child.document_id != entry.document_id or
            provenance.get('parent_preview_id') != parent.id or
            provenance.get('segment_key') != segment_key):
        _fail('FINANCIAL_IMPORT_SEGMENT_PARENT', 'Esta fatura não pertence à importação aberta.')
    existing = db.get(Segment, (entry.id, segment_key))
    if existing:
        if existing.preview_id != child.id or existing.parent_preview_id != parent.id:
            _fail('FINANCIAL_IMPORT_SEGMENT_CONFLICT',
                  'Esta fatura já foi selecionada de outra forma. Atualize a conferência.')
        return existing
    segment = Segment(import_id=entry.id, segment_key=segment_key,
                      preview_id=child.id, parent_preview_id=parent.id)
    db.add(segment)
    db.flush()
    audit(db, actor, 'IMPORT_SEGMENT_ATTACHED', entry,
          {'generation': entry.generation, 'segment_key': segment_key,
           'preview_id': child.id, 'parent_preview_id': parent.id})
    return segment


def attach_statement(db, entry, preview, statement, actor):
    from app.services.financial_imports import audit
    if statement.preview_id != preview.id or statement.document_id != entry.document_id:
        _fail('FINANCIAL_IMPORT_STATEMENT_CONFLICT',
              'A fatura confirmada não pertence a esta importação.')
    if preview.id == entry.root_preview_id:
        if entry.statement_id != statement.id:
            entry.bill_revision_id = None
        entry.statement_id = statement.id
    else:
        segment = db.get(Segment, (entry.id, _segment_key(preview)))
        if not segment or segment.preview_id != preview.id:
            _fail('FINANCIAL_IMPORT_SEGMENT_PARENT', 'Esta fatura não pertence à importação aberta.')
        if segment.statement_id != statement.id:
            segment.bill_revision_id = None
        segment.statement_id = statement.id
    effects = dict(entry.effects)
    effects['statement_ids'] = sorted(set(effects.get('statement_ids', [])) | {statement.id})
    entry.effects, entry.updated_at = effects, utc_now()
    audit(db, actor, 'IMPORT_STATEMENT_ATTACHED', entry,
          {'generation': entry.generation, 'statement_id': statement.id,
           'preview_id': preview.id})
    db.flush()


def record_cycle(db, entry, preview, cycle, revision, *, series_ids, represented_ids, actor):
    from app.services.financial_imports import audit
    statement = db.get(FinancialStatement, revision.statement_id)
    attach_statement(db, entry, preview, statement, actor)
    if preview.id == entry.root_preview_id:
        entry.bill_revision_id = revision.id
    else:
        segment = db.get(Segment, (entry.id, _segment_key(preview)))
        segment.bill_revision_id = revision.id
    effects = dict(entry.effects)
    from app.models.financial_bill_cycles import FinancialBillPayableLink
    for key, values in {
        'cycle_ids': [cycle.id], 'bill_revision_ids': [revision.id],
        'payable_ids': [cycle.payable_id] if cycle.payable_id and revision.destination == 'OPEN' else [],
        'series_ids': series_ids,
        'represented_payables_to_restore': represented_ids,
        'link_ids': list(db.scalars(select(FinancialBillPayableLink.id).where(
            FinancialBillPayableLink.cycle_id == cycle.id))),
    }.items():
        effects[key] = sorted(set(effects.get(key, [])) | set(values))
    effects['recorded_destination'] = revision.destination
    effects['recorded_payable_id'] = cycle.payable_id if revision.destination == 'OPEN' else None
    entry.effects, entry.updated_at = effects, utc_now()
    audit(db, actor, 'IMPORT_FINANCIAL_EFFECTS_ATTACHED', entry,
          {'generation': entry.generation, 'cycle_id': cycle.id,
           'revision_id': revision.id, 'payable_id': cycle.payable_id,
           'series_ids': series_ids, 'represented_payable_ids': represented_ids})
    db.flush()
