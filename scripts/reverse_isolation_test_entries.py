"""Reverse only the two test credits identified during the catalog change audit."""
import json
import sys
from pathlib import Path
from sqlalchemy import select
from sqlalchemy.orm import Session

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'backend'))
from app.core.backup import create_backup
from app.core.database import engine
from app.models.financial import CashFlowEntry
from app.services.financial import record_cash_flow_entry


def main():
    assert Path(engine.url.database).resolve() == (ROOT / 'backend' / 'data' / 'estoque.db').resolve()
    backup = create_backup(tag='before_test_isolation_correction')
    expected_times = {'2026-10-14 19:51:33.474417', '2026-10-14 20:04:56.444870'}
    corrected = 0
    with Session(engine) as db:
        entries = db.scalars(select(CashFlowEntry).where(CashFlowEntry.source_type == 'TEST_SOURCE')).all()
        selected = [entry for entry in entries if str(entry.occurred_at) in expected_times]
        assert len(selected) == 2
        for entry in selected:
            assert entry.entry_type == 'CREDIT' and entry.amount_cents == 5000
            assert entry.description == 'Lancamento primario' and not entry.is_reversal
            if db.scalar(select(CashFlowEntry.id).where(CashFlowEntry.reversal_of_id == entry.id)):
                continue
            record_cash_flow_entry(db=db, account_id=entry.account_id, entry_type='DEBIT',
                amount_cents=entry.amount_cents, category=entry.category, nature=entry.nature,
                description='Estorno de lancamento indevido do teste de isolamento de banco',
                source_type='TEST_ISOLATION_CORRECTION', source_id=entry.id,
                payment_method=entry.payment_method, reversal_of_id=entry.id, is_reversal=True,
                notes='Falha identificada em test_duplicate_cash_flow_entry_prevention; teste agora usa banco temporario.')
            corrected += 1
        db.commit()
    print(json.dumps({'backup': backup['backup_path'], 'test_entries_reversed': corrected,
                      'original_entries_preserved': True}))


if __name__ == '__main__':
    main()
