"""Separate visible import generations from immutable bytes and reader cache."""
import json
import uuid

from alembic import op
import sqlalchemy as sa

revision = 'f39a012b2159'
down_revision = 'f28f901a1048'
branch_labels = depends_on = None


ROOT_GUARD = """CREATE TRIGGER IF NOT EXISTS trg_fin_import_entry_root BEFORE INSERT ON financial_import_entries
WHEN NOT EXISTS (SELECT 1 FROM financial_import_previews p WHERE p.id=NEW.root_preview_id
 AND p.document_id=NEW.document_id AND json_extract(p.result, '$.segment_provenance') IS NULL)
BEGIN SELECT RAISE(ABORT, 'invalid import root'); END"""
SEGMENT_GUARD = """CREATE TRIGGER IF NOT EXISTS trg_fin_import_segment_parent BEFORE INSERT ON financial_import_entry_segments
WHEN NOT EXISTS (SELECT 1 FROM financial_import_entries e JOIN financial_import_previews p
 ON p.id=NEW.preview_id AND p.document_id=e.document_id WHERE e.id=NEW.import_id
 AND NEW.preview_id!=e.root_preview_id
 AND json_extract(p.result, '$.segment_provenance.segment_key')=NEW.segment_key
 AND json_extract(p.result, '$.segment_provenance.parent_preview_id')=NEW.parent_preview_id
 AND (NEW.parent_preview_id=e.root_preview_id OR EXISTS (
   SELECT 1 FROM financial_import_entry_segments s WHERE s.import_id=e.id AND s.preview_id=NEW.parent_preview_id)))
BEGIN SELECT RAISE(ABORT, 'segment belongs to another import'); END"""
PAYABLE_GUARD = """CREATE TRIGGER IF NOT EXISTS trg_substituted_payable_guard BEFORE UPDATE ON accounts_payable
WHEN OLD.superseded_by_id IS NOT NULL AND (NEW.superseded_by_id IS NOT OLD.superseded_by_id
 OR NEW.status != OLD.status OR NEW.balance_cents != OLD.balance_cents OR NEW.paid_amount_cents != OLD.paid_amount_cents
 OR NEW.original_amount_cents != OLD.original_amount_cents)
 AND NOT (NEW.superseded_by_id IS NULL AND NEW.balance_cents = OLD.balance_cents
 AND NEW.paid_amount_cents = OLD.paid_amount_cents AND NEW.original_amount_cents = OLD.original_amount_cents
 AND NEW.status = CASE WHEN OLD.balance_cents=0 THEN 'PAID' WHEN OLD.paid_amount_cents>0 THEN 'PARTIAL' ELSE 'OPEN' END
 AND EXISTS(SELECT 1 FROM financial_import_entries e
 WHERE EXISTS(SELECT 1 FROM json_each(e.retained_effects,'$.represented_payables_to_restore') a WHERE a.value=OLD.id)
 AND EXISTS(SELECT 1 FROM json_each(e.retained_effects,'$.payable_ids') b WHERE b.value=OLD.superseded_by_id)
 AND NOT EXISTS(SELECT 1 FROM json_each(e.released_effects,'$.represented_payables_to_restore') x WHERE x.value=OLD.id)))
BEGIN SELECT RAISE(ABORT, 'represented payable cannot be reopened'); END"""


def _value(raw):
    if raw is None:
        return {}
    return json.loads(raw) if isinstance(raw, str) else raw


def _alias(value):
    return value[:8] if value else '?'


def _backfill(bind):
    entry_rows, segment_rows = [], []
    previews = [dict(r) for r in bind.execute(sa.text(
        'SELECT id,document_id,created_by,created_at,result FROM financial_import_previews '
        'ORDER BY created_at,id')).mappings()]
    by_id = {p['id']: p for p in previews}
    for p in previews:
        p['result'] = _value(p['result'])
    by_document = {}
    for p in previews:
        by_document.setdefault(p['document_id'], []).append(p)
    removals = {r['document_id']: dict(r) for r in bind.execute(sa.text(
        'SELECT document_id,removed,effects FROM financial_import_removals')).mappings()}
    for document_id in removals:
        if document_id not in by_document:
            raise RuntimeError('Import lifecycle migration needs a documented root for legacy withdrawal '
                               + _alias(document_id))

    def root_of(preview_id, document_id):
        seen = set()
        while preview_id:
            if preview_id in seen or preview_id not in by_id or by_id[preview_id]['document_id'] != document_id:
                raise RuntimeError('Import lifecycle migration found broken segment provenance '
                                   + _alias(document_id) + ':' + _alias(preview_id))
            seen.add(preview_id)
            parent = (by_id[preview_id]['result'].get('segment_provenance') or {}).get('parent_preview_id')
            if not parent:
                return preview_id
            preview_id = parent
        raise RuntimeError('Import lifecycle migration found a missing root ' + _alias(document_id))

    statements = [dict(r) for r in bind.execute(sa.text(
        'SELECT id,document_id,preview_id,statement_type,created_at FROM financial_statements '
        'WHERE preview_id IS NOT NULL')).mappings()]
    statement_by_id = {s['id']: s for s in statements}
    hidden_cycles = set()
    hidden_payables = set()
    for row in removals.values():
        effects = _value(row['effects'])
        hidden_cycles.update(set(effects.get('cycle_ids', [])) - set(effects.get('reinstated_cycle_ids', [])))
        hidden_payables.update(set(effects.get('payable_ids', [])) - set(effects.get('reinstated_payable_ids', [])))
    current_cycles = [dict(r) for r in bind.execute(sa.text(
        'SELECT c.id AS cycle_id,c.payable_id,r.id AS revision_id,r.preview_id,r.statement_id,r.destination '
        'FROM financial_bill_cycles c JOIN financial_bill_cycle_revisions r '
        'ON r.cycle_id=c.id AND r.revision=c.revision')).mappings()
        if r['cycle_id'] not in hidden_cycles]
    cycle_statement_ids = set(bind.execute(sa.text('SELECT statement_id FROM financial_bill_cycle_revisions')).scalars())
    obligations = [dict(r) for r in bind.execute(sa.text(
        'SELECT o.account_payable_id,o.statement_id,s.document_id,s.preview_id '
        'FROM financial_bill_obligations o JOIN financial_statements s ON s.id=o.statement_id '
        'WHERE s.preview_id IS NOT NULL')).mappings()
        if r['account_payable_id'] not in hidden_payables]
    series = [dict(r) for r in bind.execute(sa.text(
        'SELECT id,provenance FROM financial_installment_series')).mappings()]
    links = [dict(r) for r in bind.execute(sa.text(
        'SELECT l.cycle_id,l.payable_id,l.kind,p.superseded_by_id '
        'FROM financial_bill_payable_links l JOIN accounts_payable p ON p.id=l.payable_id')).mappings()]
    semantic_reviews = [dict(r) for r in bind.execute(sa.text(
        'SELECT id,statement_id FROM financial_bill_semantic_reviews')).mappings()]

    for document_id, doc_previews in by_document.items():
        roots = [p for p in doc_previews if not p['result'].get('segment_provenance')]
        if not roots:
            raise RuntimeError('Import lifecycle migration cannot prove root for document ' + _alias(document_id))
        cycle_rows = [r for r in current_cycles if by_id.get(r['preview_id'], {}).get('document_id') == document_id]
        obligation_rows = [r for r in obligations if r['document_id'] == document_id]
        bank_statements = [s for s in statements if s['document_id'] == document_id and
                           s['statement_type'] == 'BANK_STATEMENT']
        removal = removals.get(document_id)
        if removal and not removal['removed'] and bank_statements:
            raise RuntimeError('Import lifecycle migration found ambiguous legacy bank confirmation '
                               + _alias(document_id))
        direct_card_statements = [s for s in statements if s['document_id'] == document_id and
                                  s['statement_type'] == 'CARD_BILL' and
                                  s['id'] not in cycle_statement_ids]
        confirmed = ([r['preview_id'] for r in cycle_rows] +
                     [r['preview_id'] for r in obligation_rows] +
                     [s['preview_id'] for s in bank_statements])
        if not confirmed and not cycle_rows:
            confirmed = [s['preview_id'] for s in direct_card_statements]
        if removal and removal['removed']:
            confirmed = []
        confirmed_roots = {root_of(pid, document_id) for pid in confirmed}
        if len(confirmed_roots) > 1:
            raise RuntimeError('Import lifecycle migration found ambiguous active roots for document '
                               + _alias(document_id) + ': ' + ','.join(sorted(_alias(x) for x in confirmed_roots)))
        root_id = next(iter(confirmed_roots)) if confirmed_roots else roots[-1]['id']
        root = by_id[root_id]
        state = 'REMOVED' if removal and removal['removed'] else 'ACTIVE'
        entry_id = str(uuid.uuid4())
        current_for_root = [r for r in cycle_rows if root_of(r['preview_id'], document_id) == root_id]
        obligations_for_root = [r for r in obligation_rows if root_of(r['preview_id'], document_id) == root_id]
        statements_for_root = [s for s in bank_statements + direct_card_statements
                               if root_of(s['preview_id'], document_id) == root_id]
        statement_ids = ({r['statement_id'] for r in current_for_root} |
                         {r['statement_id'] for r in obligations_for_root} |
                         {s['id'] for s in statements_for_root}) if state == 'ACTIVE' else set()
        preview_statements = {}
        for sid in statement_ids:
            statement = statement_by_id.get(sid)
            if statement is None:
                raise RuntimeError('Import lifecycle migration found missing statement ' + _alias(sid))
            previous = preview_statements.setdefault(statement['preview_id'], sid)
            if previous != sid:
                raise RuntimeError('Import lifecycle migration found conflicting statements for preview '
                                   + _alias(statement['preview_id']))
        cycle_ids = {r['cycle_id'] for r in current_for_root} if state == 'ACTIVE' else set()
        revision_ids = {r['revision_id'] for r in current_for_root} if state == 'ACTIVE' else set()
        payable_ids = ({r['payable_id'] for r in current_for_root if r['payable_id']} |
                       {r['account_payable_id'] for r in obligations_for_root}) if state == 'ACTIVE' else set()
        represented = {r['payable_id'] for r in links if r['cycle_id'] in cycle_ids and
                       r['kind'] != 'PRIMARY' and r['superseded_by_id'] in payable_ids}
        series_ids = {r['id'] for r in series if _value(r['provenance']).get('revision_id') in revision_ids}
        revision_by_preview = {r['preview_id']: r for r in current_for_root}
        direct_revision = revision_by_preview.get(root_id)
        effects = {'statement_ids': sorted(statement_ids), 'cycle_ids': sorted(cycle_ids),
                   'bill_revision_ids': sorted(revision_ids), 'payable_ids': sorted(payable_ids),
                   'series_ids': sorted(series_ids),
                   'represented_payables_to_restore': sorted(represented),
                   'semantic_review_ids': sorted(r['id'] for r in semantic_reviews if r['statement_id'] in statement_ids)}
        if direct_revision:
            effects['recorded_destination'] = direct_revision['destination']
            effects['recorded_payable_id'] = direct_revision['payable_id'] if direct_revision['destination'] == 'OPEN' else None
        entry_rows.append({
            'id': entry_id, 'document_id': document_id, 'state': state, 'root_preview_id': root_id,
            'statement_id': preview_statements.get(root_id),
            'bill_revision_id': direct_revision['revision_id'] if direct_revision else None,
            'effects': json.dumps(effects),
            'retained_effects': json.dumps(_value(removal['effects']) if removal else {}),
            'released_effects': '{}', 'legacy_removal_document_id': document_id if removal else None,
            'created_by': root['created_by'], 'created_at': root['created_at'], 'updated_at': root['created_at'],
        })
        pending_children = set(preview_statements) - {root_id}
        attached = {root_id}
        while pending_children:
            available = sorted(pid for pid in pending_children if
                (by_id[pid]['result'].get('segment_provenance') or {}).get('parent_preview_id') in attached)
            if not available:
                # Add provenance-only ancestors before their confirmed children.
                parents = {(by_id[pid]['result'].get('segment_provenance') or {}).get('parent_preview_id')
                           for pid in pending_children} - attached - pending_children
                if not parents or None in parents:
                    raise RuntimeError('Import lifecycle migration has unresolved segment parent ' + _alias(document_id))
                pending_children.update(parents)
                continue
            pid = available[0]
            sid = preview_statements.get(pid)
            pending_children.remove(pid)
            if pid == root_id:
                continue
            child = by_id[pid]
            provenance = child['result'].get('segment_provenance') or {}
            parent = provenance.get('parent_preview_id')
            key = provenance.get('segment_key')
            if not parent or not key or root_of(pid, document_id) != root_id:
                raise RuntimeError('Import lifecycle migration cannot prove confirmed segment ' + _alias(pid))
            rev = revision_by_preview.get(pid)
            if any(s['import_id'] == entry_id and s['segment_key'] == key for s in segment_rows):
                raise RuntimeError('Import lifecycle migration found ambiguous segment ' + _alias(pid))
            segment_rows.append({
                'import_id': entry_id, 'segment_key': key, 'preview_id': pid, 'parent_preview_id': parent,
                'statement_id': sid, 'bill_revision_id': rev['revision_id'] if rev else None,
            })
            attached.add(pid)
    return entry_rows, segment_rows


def upgrade():
    # Prove associations before SQLite executes any additive DDL, so a refused
    # ambiguous legacy database is still immediately retryable after review.
    entry_rows, segment_rows = _backfill(op.get_bind())
    op.create_table('financial_import_entries',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('document_id', sa.String(36), sa.ForeignKey('financial_documents.id'), nullable=False),
        sa.Column('generation', sa.Integer(), nullable=False),
        sa.Column('state', sa.String(10), nullable=False),
        sa.Column('root_preview_id', sa.String(36), sa.ForeignKey('financial_import_previews.id'), nullable=False),
        sa.Column('statement_id', sa.String(36), sa.ForeignKey('financial_statements.id')),
        sa.Column('bill_revision_id', sa.String(36), sa.ForeignKey('financial_bill_cycle_revisions.id')),
        sa.Column('effects', sa.JSON(), nullable=False),
        sa.Column('retained_effects', sa.JSON(), nullable=False),
        sa.Column('released_effects', sa.JSON(), nullable=False),
        sa.Column('legacy_removal_document_id', sa.String(36), sa.ForeignKey('financial_import_removals.document_id')),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('removed_by', sa.String(36), sa.ForeignKey('paired_devices.id')),
        sa.Column('removed_at', sa.DateTime()),
        sa.UniqueConstraint('document_id', 'generation', name='uq_fin_import_generation'),
        sa.CheckConstraint('generation > 0', name='ck_fin_import_generation'),
        sa.CheckConstraint("state IN ('ACTIVE','REMOVED')", name='ck_fin_import_entry_state'))
    op.create_index('ix_financial_import_entries_document_id', 'financial_import_entries', ['document_id'])
    op.create_index('uq_fin_import_active_document', 'financial_import_entries', ['document_id'],
                    unique=True, sqlite_where=sa.text("state = 'ACTIVE'"))
    op.create_table('financial_import_entry_segments',
        sa.Column('import_id', sa.String(36), sa.ForeignKey('financial_import_entries.id'), primary_key=True),
        sa.Column('segment_key', sa.String(20), primary_key=True),
        sa.Column('preview_id', sa.String(36), sa.ForeignKey('financial_import_previews.id'), nullable=False),
        sa.Column('parent_preview_id', sa.String(36), sa.ForeignKey('financial_import_previews.id'), nullable=False),
        sa.Column('statement_id', sa.String(36), sa.ForeignKey('financial_statements.id')),
        sa.Column('bill_revision_id', sa.String(36), sa.ForeignKey('financial_bill_cycle_revisions.id')),
        sa.UniqueConstraint('import_id', 'preview_id', name='uq_fin_import_segment_preview'),
        sa.CheckConstraint('length(segment_key) > 0', name='ck_fin_import_segment_key'))
    op.execute(ROOT_GUARD)
    op.execute(SEGMENT_GUARD)
    # These guards constrain metadata identity; original evidence tables stay intact.
    from app.models.financial_imports import IMPORT_METADATA_GUARDS
    for table, sql in IMPORT_METADATA_GUARDS:
        op.execute(sql)
    bind = op.get_bind()
    for row in entry_rows:
        bind.execute(sa.text('INSERT INTO financial_import_entries '
            '(id,document_id,generation,state,root_preview_id,statement_id,bill_revision_id,effects,'
            'retained_effects,released_effects,legacy_removal_document_id,created_by,created_at,updated_at) '
            'VALUES (:id,:document_id,1,:state,:root_preview_id,:statement_id,:bill_revision_id,:effects,'
            ':retained_effects,:released_effects,:legacy_removal_document_id,:created_by,:created_at,:updated_at)'), row)
    for row in segment_rows:
        bind.execute(sa.text('INSERT INTO financial_import_entry_segments '
            '(import_id,segment_key,preview_id,parent_preview_id,statement_id,bill_revision_id) '
            'VALUES (:import_id,:segment_key,:preview_id,:parent_preview_id,:statement_id,:bill_revision_id)'), row)
    op.execute('DROP TRIGGER IF EXISTS trg_substituted_payable_guard')
    op.execute(PAYABLE_GUARD)
    for action in ('INSERT', 'UPDATE', 'DELETE'):
        op.execute(f'CREATE TRIGGER IF NOT EXISTS trg_fin_import_legacy_no_{action.lower()} '
            f'BEFORE {action} ON financial_import_removals BEGIN '
            "SELECT RAISE(ABORT, 'legacy import withdrawals are read only'); END;")


def downgrade():
    bind = op.get_bind()
    if bind.scalar(sa.text('SELECT COUNT(*) FROM financial_import_entries')):
        raise RuntimeError('Cannot discard import generations or their withdrawal history')
    for action in ('INSERT', 'UPDATE', 'DELETE'):
        op.execute(f'DROP TRIGGER IF EXISTS trg_fin_import_legacy_no_{action.lower()}')
    op.execute('DROP TRIGGER IF EXISTS trg_fin_import_segment_parent')
    op.execute('DROP TRIGGER IF EXISTS trg_fin_import_entry_root')
    op.execute('DROP TRIGGER IF EXISTS trg_fin_import_entry_update')
    op.execute('DROP TRIGGER IF EXISTS trg_fin_import_segment_update')
    op.drop_table('financial_import_entry_segments')
    op.drop_index('uq_fin_import_active_document', table_name='financial_import_entries')
    op.drop_index('ix_financial_import_entries_document_id', table_name='financial_import_entries')
    op.drop_table('financial_import_entries')
    op.execute('DROP TRIGGER IF EXISTS trg_substituted_payable_guard')
    from importlib.util import spec_from_file_location, module_from_spec
    from pathlib import Path
    spec = spec_from_file_location('legacy_import_removal_migration',
        Path(__file__).with_name('f17e8f901037_import_removal_state.py'))
    legacy = module_from_spec(spec)
    spec.loader.exec_module(legacy)
    RESTORED_GUARD = legacy.RESTORED_GUARD
    op.execute(RESTORED_GUARD)
