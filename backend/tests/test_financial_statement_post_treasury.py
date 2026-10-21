"""Bank evidence can only validate/reconcile cash already recorded."""
import uuid
import pytest
from sqlalchemy import func, select
from app.models.financial import CashFlowEntry
from app.models.financial_imports import FinancialReconciliation
from test_financial_imports import FinancialAPI, PREFIX

@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def test_bulk_posting_requires_review_and_does_not_change_cash(api, test_session):
    source = api.source()
    statement, _, _ = api.stage(source, [
        {"transaction_date": "2026-08-18", "amount_cents": 324000, "description": "Entrada a conferir"},
        {"transaction_date": "2026-08-19", "amount_cents": -100000, "description": "Saida a conferir"},
    ])
    result = api.post(f"/statements/{statement['id']}/post-to-treasury", {}, expected=(409,))
    assert result['detail']['error_code'] == 'FINANCIAL_CASH_REVIEW_REQUIRED'
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)) == 0


def test_explicit_reconciliation_and_replay_never_duplicate_existing_money(api, test_session):
    source = api.source()
    statement, items, _ = api.stage(source, [
        {"transaction_date": "2026-08-18", "amount_cents": 5000, "description": "Entrada conferida"},
    ])
    reviewed = api.review(items[0], action='NEW')
    entry = api.entry(source['financial_account_id'], amount=5000, direction='CREDIT')
    api.post('/reconciliations', {
        'transaction_id': reviewed['transaction']['id'], 'cash_flow_entry_id': entry['id'],
        'amount_cents': 5000, 'reason': 'Correspondencia conferida no extrato',
    })
    for _ in range(2):
        result = api.post(f"/statements/{statement['id']}/post-to-treasury", {})
        assert result['entries_posted'] == 0
    test_session.rollback()
    assert test_session.scalar(select(func.count()).select_from(CashFlowEntry)) == 1
    assert test_session.scalar(select(func.count()).select_from(FinancialReconciliation)) == 1
