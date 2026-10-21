"""Conservative monthly projections. Similarity proposes; an explicit link proves a series."""
import calendar
import datetime as dt
import re
import uuid
from collections import Counter
from sqlalchemy import select
from app.models.financial_installments import InstallmentSeries as Series, InstallmentOccurrence as Occurrence, InstallmentForecast as Forecast, InstallmentDecision as Decision
from app.models.financial_bill_cycles import FinancialBillCycle as Cycle, FinancialBillCycleRevision as Revision, FinancialBillCycleItem as Meaning
from app.models.financial_imports import FinancialSource, FinancialStatementItem as Item
from app.services.financial_normalization import normalized
from app.services.financial_imports import require, fail, audit
from app.core.idempotency import compute_payload_hash


def month_offset(reference, offset):
    year, month = map(int, reference.split('-'))
    year, month = divmod(year * 12 + month - 1 + offset, 12)
    if not 1 <= year <= 9999:
        fail('FINANCIAL_INSTALLMENT_DATE_LIMIT', 'A agenda ultrapassa o calendario suportado.')
    return f'{year:04d}-{month + 1:02d}'


def monthly_date(reference, day):
    if day is None:
        return None
    year, month = map(int, reference.split('-'))
    return dt.date(year, month, min(day, calendar.monthrange(year, month)[1]))


def match_key(description):
    return re.sub(r'(?:\bPARCELA\s*|\bPARC\.?\s*|\s-\s*)\d+\s*/\s*\d+\s*$', '', normalized(description)).strip()


def assigned(db, occurrence):
    decision = db.scalar(select(Decision).where(Decision.occurrence_id == occurrence.id))
    return decision.series_id if decision else occurrence.series_id


def visible_series(db):
    from app.services.financial_import_removals import withdrawn_cycles, hidden_series
    from app.models.financial_imports import FinancialStatement
    hidden_cycles = withdrawn_cycles(db)
    inactive_items = select(Item.id).join(Revision, Revision.statement_id == Item.statement_id).where(Revision.cycle_id.in_(hidden_cycles))
    return select(Series).where(Series.id.not_in(hidden_series(db)), Series.origin_item_id.not_in(inactive_items))


def candidates(db, source_id, reference, data):
    return [s for s in db.scalars(visible_series(db).where(Series.source_id == source_id, Series.total == data['total_installments']))
        if (s.match_key == match_key(data['description']) or
            (db.get(Item, s.origin_item_id).normalized_data['transaction_date'] == data['transaction_date'] and s.amount_cents == data['amount_cents'])) and
        month_offset(s.base_reference, data['installment_number'] - s.base_number) == reference]


def create_series(db, source_id, reference, row, day, revision):
    data = row.normalized_data
    series = Series(id=str(uuid.uuid4()), source_id=source_id, origin_item_id=row.id,
        description=data['description'], match_key=match_key(data['description']),
        base_reference=reference, base_number=data['installment_number'], total=data['total_installments'],
        amount_cents=data['amount_cents'], base_day=day,
        provenance={'version': 1, 'revision_id': revision.id, 'item_id': row.id,
            'kind': 'MONTHLY_ESTIMATE', 'day_origin': revision.control_origin,
            'document_schedule': False})
    db.add(series)
    db.flush()
    extend(db, series, series.base_number)
    return series


def extend(db, series, number):
    existing = set(db.scalars(select(Forecast.number).where(Forecast.series_id == series.id)))
    for n in range(number + 1, series.total + 1):
        if n in existing:
            continue
        reference = month_offset(series.base_reference, n - series.base_number)
        db.add(Forecast(id=str(uuid.uuid4()), series_id=series.id, number=n, reference=reference,
            estimated_due_on=monthly_date(reference, series.base_day), amount_cents=series.amount_cents))
    db.flush()


def sync_cycle(db, cycle, revision, rows, meanings, *, estimate_day=True):
    """Called inside the bill's transaction, including summary enrichment and historical imports."""
    counts = Counter()
    for position, row in sorted(rows.items()):
        data = row.normalized_data
        if meanings[position][0] not in {'PURCHASE', 'CHARGE'} or not data.get('installment_number') or data['amount_cents'] <= 0:
            continue
        key = (match_key(data['description']), data['transaction_date'], data['installment_number'], data['total_installments'], data['amount_cents'])
        counts[key] += 1
        slot = compute_payload_hash([*key, counts[key]])
        old = db.scalars(select(Occurrence).join(Revision, Revision.id == Occurrence.revision_id).where(
            Revision.cycle_id == cycle.id, Occurrence.slot_key == slot).order_by(Revision.revision.desc())).first()
        series_id = assigned(db, old) if old else None
        if not old and not [s for s in candidates(db, cycle.source_id, cycle.reference, data) if s.provenance.get('revision_id') != revision.id]:
            series_id = create_series(db, cycle.source_id, cycle.reference, row, revision.due_on.day if estimate_day else None, revision).id
        db.add(Occurrence(id=str(uuid.uuid4()), revision_id=revision.id, item_id=row.id,
            series_id=series_id, slot_key=slot, number=data['installment_number'], total=data['total_installments'], amount_cents=data['amount_cents']))
    db.flush()


def active_occurrences(db):
    from app.services.financial_import_removals import withdrawn_cycles
    return list(db.scalars(select(Occurrence).join(Revision, Revision.id == Occurrence.revision_id)
        .join(Cycle, Cycle.id == Revision.cycle_id).where(Cycle.revision == Revision.revision, Cycle.id.not_in(withdrawn_cycles(db)))))


def guard_decision(db, data):
    from app.services.financial_import_lifecycle import guard_item, guard_statement
    if data.action == 'CANCEL':
        return guard_item(db, data.evidence_item_id, data)
    occurrence = require(db, Occurrence, data.occurrence_id)
    revision = require(db, Revision, occurrence.revision_id)
    return guard_statement(db, revision.statement_id, data)


def decide(db, data, actor):
    entry = guard_decision(db, data)
    if agenda(db)['snapshot'] != data.expected_snapshot:
        fail('FINANCIAL_INSTALLMENT_REVISION_CONFLICT', 'A agenda mudou. Atualize antes de confirmar o vinculo.')
    if data.action == 'CANCEL':
        series = require(db, Series, data.series_id)
        row = require(db, Item, data.evidence_item_id)
        meaning = db.scalar(select(Meaning).join(Revision, Revision.id == Meaning.revision_id)
            .join(Cycle, Cycle.id == Revision.cycle_id).where(Meaning.item_id == row.id,
                Cycle.source_id == series.source_id, Meaning.role == 'CREDIT'))
        if not meaning or row.normalized_data['amount_cents'] >= 0 or not 1 <= data.from_number <= series.total:
            fail('FINANCIAL_INSTALLMENT_CANCELLATION_EVIDENCE', 'Selecione o estorno comprovado da mesma origem e quais parcelas ele cancela.')
        decision = Decision(id=str(uuid.uuid4()), series_id=series.id, action='CANCEL', evidence_item_id=row.id,
            from_number=data.from_number, reason=data.reason, created_by=actor)
    else:
        occurrence = require(db, Occurrence, data.occurrence_id)
        revision = require(db, Revision, occurrence.revision_id)
        cycle = require(db, Cycle, revision.cycle_id)
        if cycle.revision != data.expected_revision or revision.revision != cycle.revision or assigned(db, occurrence):
            fail('FINANCIAL_INSTALLMENT_REVISION_CONFLICT', 'A parcela ja mudou ou foi vinculada. Atualize a agenda.')
        row = require(db, Item, occurrence.item_id)
        options = candidates(db, cycle.source_id, cycle.reference, row.normalized_data)
        if data.action == 'LINK':
            series = require(db, Series, data.series_id)
            if series.id not in {s.id for s in options}:
                fail('FINANCIAL_INSTALLMENT_LINK_CONFLICT', 'A serie nao e compativel com esta origem, mes e sequencia.')
            # A series can have only one actual installment per cycle, even if there are two identical purchases.
            if any(o.id != occurrence.id and o.number == occurrence.number and assigned(db, o) == series.id for o in active_occurrences(db)):
                fail('FINANCIAL_INSTALLMENT_LINK_CONFLICT', 'Esta parcela da serie ja possui uma ocorrencia real.')
        else:
            series = create_series(db, cycle.source_id, cycle.reference, row, revision.due_on.day, revision)
        extend(db, series, occurrence.number)
        decision = Decision(id=str(uuid.uuid4()), occurrence_id=occurrence.id, series_id=series.id,
            action=data.action, reason=data.reason, created_by=actor)
    db.add(decision)
    db.flush()
    from app.services.financial_import_lifecycle import record_ids
    record_ids(db, entry, 'installment_decision_ids', [decision.id])
    if data.action == 'DISTINCT':
        record_ids(db, entry, 'series_ids', [series.id])
    audit(db, actor, 'INSTALLMENT_DECISION', decision, {'series_id': series.id, 'action': data.action})
    return {'id': decision.id, 'series_id': series.id, 'action': data.action, 'affects_ledger': False}


def agenda(db, *, source_id=None, source_query=None, merchant=None, due_date_from=None, due_date_to=None,
           month=None, year=None, status=None, category=None, beneficiary=None, nature=None, overdue_only=False,
           limit=100, offset=0):
    from app.services.financial_import_removals import withdrawn_cycles
    inactive = withdrawn_cycles(db)
    from app.services.financial_import_lifecycle import statement_context
    series_map = {s.id: s for s in db.scalars(visible_series(db))}
    sources = {s.id: s for s in db.scalars(select(FinancialSource))}
    occurrences = active_occurrences(db)
    pending, held, actual = [], set(), set()
    occupied = {(assigned(db, o), o.number) for o in occurrences if assigned(db, o)}
    # Keep past proven links even after enrichment: replacement must never reactivate an estimate.
    for occurrence in db.scalars(select(Occurrence).join(Revision, Revision.id == Occurrence.revision_id).where(Revision.cycle_id.not_in(inactive))):
        sid = assigned(db, occurrence)
        if sid:
            actual.add((sid, occurrence.number))
    for o in occurrences:
        if assigned(db, o):
            continue
        revision = db.get(Revision, o.revision_id)
        cycle = db.get(Cycle, revision.cycle_id)
        row = db.get(Item, o.item_id)
        options = [s for s in candidates(db, cycle.source_id, cycle.reference, row.normalized_data) if (s.id, o.number) not in occupied]
        for s in options:
            # The whole competing series remains held until identity is resolved.
            held.add(s.id)
        pending.append({**statement_context(db, revision.statement_id), 'occurrence_id': o.id, 'expected_revision': cycle.revision, 'cycle_id': cycle.id,
            'payable_id': cycle.payable_id, 'source_id': cycle.source_id, 'reference': cycle.reference,
            'description': row.normalized_data['description'], 'number': o.number, 'total': o.total,
            'amount_cents': o.amount_cents, 'due_on': revision.due_on.isoformat(),
            'candidates': [{'series_id': s.id, 'description': s.description, 'amount_cents': s.amount_cents,
                'estimated_due_on': (monthly_date(cycle.reference, s.base_day).isoformat() if s.base_day else None),
                'origin_item_id': s.origin_item_id, 'origin_reference': s.base_reference,
                'origin_number': s.base_number, 'origin_position': db.get(Item, s.origin_item_id).position,
                'purchase_date': db.get(Item, s.origin_item_id).normalized_data['transaction_date']} for s in options]})
    from app.models.financial_imports import FinancialStatement
    from app.services.financial_import_lifecycle import inactive_statement_ids
    hidden_credit_items = select(Item.id).where(Item.statement_id.in_(inactive_statement_ids()))
    cancellations = list(db.scalars(select(Decision).where(Decision.action == 'CANCEL', Decision.evidence_item_id.not_in(hidden_credit_items))))
    def included(source, description, reference, due):
        if source_id and source.id != source_id or source_query and normalized(source_query) not in normalized(source.name + ' ' + source.institution):
            return False
        if merchant and normalized(merchant) not in normalized(description) or beneficiary and normalized(beneficiary) not in normalized(source.institution):
            return False
        if month and int(reference[5:]) != month or year and int(reference[:4]) != year:
            return False
        # Unknown day: include overlapping month, never fabricate a date to show the user.
        lo = due or monthly_date(reference, 1)
        hi = due or monthly_date(reference, 31)
        if due_date_from and hi < due_date_from.date() or due_date_to and lo > due_date_to.date():
            return False
        return not (status or nature or overdue_only or category and category != 'CARTAO_CREDITO')
    rows = []
    for f in db.scalars(select(Forecast).order_by(Forecast.reference, Forecast.series_id, Forecast.number)):
        if f.series_id not in series_map:
            continue
        s = series_map[f.series_id]
        source = sources[s.source_id]
        if not included(source, s.description, f.reference, f.estimated_due_on):
            continue
        state = ('REPLACED' if (s.id, f.number) in actual else 'CANCELED' if any(d.series_id == s.id and f.number >= d.from_number for d in cancellations)
            else 'PENDING_LINK' if s.id in held else 'ESTIMATED')
        rows.append({**statement_context(db, db.get(Item, s.origin_item_id).statement_id),
            'id': f.id, 'series_id': s.id, 'number': f.number, 'total': s.total, 'reference': f.reference,
            'estimated_due_on': f.estimated_due_on.isoformat() if f.estimated_due_on else None,
            'amount_cents': f.amount_cents, 'description': s.description, 'state': state,
            'financial_source': {'id': source.id, 'name': source.name, 'institution': source.institution},
            'provenance': s.provenance, 'payable': False})
    held_in_filter = {r['series_id'] for r in rows if r['state'] == 'PENDING_LINK'}
    visible_pending = [p for p in pending if
        any(s['series_id'] in held_in_filter for s in p['candidates']) or
        included(sources[p['source_id']], p['description'], p['reference'], dt.date.fromisoformat(p['due_on']))]
    credits = []
    for row, cycle in db.execute(select(Item, Cycle).join(Revision, Revision.statement_id == Item.statement_id)
            .join(Cycle, Cycle.id == Revision.cycle_id).join(Meaning, (Meaning.item_id == Item.id) & (Meaning.revision_id == Revision.id))
            .where(Cycle.revision == Revision.revision, Cycle.id.not_in(inactive), Meaning.role == 'CREDIT')):
        credits.append({**statement_context(db, row.statement_id), 'item_id': row.id, 'source_id': cycle.source_id, 'description': row.normalized_data['description'], 'amount_cents': row.normalized_data['amount_cents']})
    version = compute_payload_hash([sorted((o.id, assigned(db, o)) for o in occurrences), sorted(d.id for d in cancellations), sorted(inactive)])
    return {'version': 1, 'snapshot': version, 'items': rows[offset:offset + limit], 'count': len(rows), 'limit': limit, 'offset': offset,
        'estimated_cents': sum(r['amount_cents'] for r in rows if r['state'] == 'ESTIMATED'),
        'pending_cents': sum(r['amount_cents'] for r in rows if r['state'] == 'PENDING_LINK'),
        'pending_links': visible_pending, 'cancellation_evidence': credits, 'affects_ledger': False}
