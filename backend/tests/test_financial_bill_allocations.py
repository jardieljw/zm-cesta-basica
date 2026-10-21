"""Allocation inspection is exact, current and read-only in an isolated DB."""
import pytest

from test_financial_imports import FinancialAPI, PREFIX, line, books
from test_financial_import_safety import classify


@pytest.fixture
def api(client, authenticated_device):
    return FinancialAPI(client, authenticated_device[2])


def bill(api, lines, total):
    source = api.source("CREDIT_CARD")
    statement, items, _ = api.stage(source, lines, statement_type="CARD_BILL",
                                    due_on="2026-10-20", total_amount_cents=total)
    return statement, items


def inspect(api, statement, review=None):
    path = f'/statements/{statement["id"]}/allocation-requirements'
    if review:
        path += '?expected_review_id=' + review['id']
    return api.get(path)


def test_numerically_cancelled_prior_balance_and_payment_keep_separate_requirements(api, test_db_path):
    st, items = bill(api, [line(10000), line(5000), line(-5000)], 10000)
    review = classify(api, st, items, ['PURCHASE_BUSINESS', 'PREVIOUS_BALANCE', 'BILL_PAYMENT'])
    assert review['is_balanced']
    before = books(test_db_path)
    result = inspect(api, st, review)
    assert {r['code'] for r in result['requirements']} == {'PRIOR_DEBT_LINK_REQUIRED', 'HISTORICAL_PAYMENT_LINK_REQUIRED'}
    assert not result['authorizes_generation'] and not result['affects_ledger']
    assert next(r for r in result['requirements'] if r['code'] == 'HISTORICAL_PAYMENT_LINK_REQUIRED')['settles_current_bill'] is False
    api.post(f'/statements/{st["id"]}/generate-obligations', {}, expected=(409,))
    assert books(test_db_path) == before


def test_refund_requires_original_target_and_attribution_without_income(api):
    st, items = bill(api, [line(10000), line(-2500)], 7500)
    review = classify(api, st, items, ['PURCHASE_PERSONAL', 'REFUND_CREDIT'])
    result = inspect(api, st, review)
    credit, = result['requirements']
    assert credit['code'] == 'CREDIT_TARGET_REQUIRED'
    assert credit['amount_cents'] == -2500 and credit['item_id'] == items[1]['id']
    assert 'business_or_personal_attribution' in credit['needs']
    assert credit['creates_cash_income'] is False


def test_installment_preserves_purchase_date_current_due_and_no_future_debt(api):
    st, items = bill(api, [line(10000, purchase_date='2025-04-01',
        installment_number=3, total_installments=10)], 10000)
    review = classify(api, st, items, ['PURCHASE_BUSINESS'])
    result = inspect(api, st, review)
    current, = result['installment_observations']
    assert current['installment_number'] == 3 and current['total_installments'] == 10
    assert current['purchase_date'] == '2025-04-01' and current['bill_due_on'] == '2026-10-20'
    assert not current['creates_future_installments']
    assert result['requirements'] == [] and not result['authorizes_generation']


def test_new_review_invalidates_inspection_reference(api):
    st, items = bill(api, [line(10000)], 10000)
    first = classify(api, st, items, ['PURCHASE_BUSINESS'])
    second = classify(api, st, items, ['PURCHASE_PERSONAL'], revision=1)
    response = api.client.get(PREFIX + f'/statements/{st["id"]}/allocation-requirements?expected_review_id={first["id"]}', headers=api.headers)
    assert response.status_code == 409
    assert response.json()['detail']['error_code'] == 'FINANCIAL_BILL_REVISION_CONFLICT'
    assert inspect(api, st, second)['review_id'] == second['id']


def test_missing_or_unbalanced_review_never_looks_allocation_ready(api):
    st, items = bill(api, [line(10000)], 10000)
    assert inspect(api, st)['requirements'][0]['code'] == 'SEMANTIC_REVIEW_REQUIRED'
    review = classify(api, st, items, ['CONTEXT_ONLY'])
    pending = inspect(api, st, review)['requirements'][0]
    assert pending['code'] == 'EXACT_COMPONENT_REVIEW_REQUIRED' and pending['difference_cents'] == 10000


def test_inspection_does_not_add_audit_or_business_rows(api, test_session, test_db_path):
    from sqlalchemy import text
    st, items = bill(api, [line(10000), line(-1000)], 9000)
    classify(api, st, items, ['PURCHASE_BUSINESS', 'REFUND_CREDIT'])
    before = books(test_db_path)
    count = test_session.execute(text('select count(*) from financial_import_audit')).scalar()
    test_session.rollback()
    for _ in range(2):
        inspect(api, st)
    assert test_session.execute(text('select count(*) from financial_import_audit')).scalar() == count
    assert books(test_db_path) == before


def test_inspection_rejects_account_and_unauthenticated_access(api):
    source = api.source()
    st, _, _ = api.stage(source, [line(-1000)])
    route = PREFIX + f'/statements/{st["id"]}/allocation-requirements'
    assert api.client.get(route).status_code == 401
    response = api.client.get(route, headers=api.headers)
    assert response.status_code == 409
    assert response.json()['detail']['error_code'] == 'FINANCIAL_BILL_SOURCE_REQUIRED'


def test_linked_purchase_exposes_all_installments_without_selecting_one(api, test_session):
    import datetime
    import uuid
    from app.models.purchases import Purchase
    from app.models.financial import AccountPayable
    purchase = Purchase(id=str(uuid.uuid4()), purchase_number=800, total_amount_cents=20000,
                        status='CONFIRMED', payment_method='CARTAO_CREDITO')
    test_session.add(purchase)
    test_session.flush()
    for number, status in [(1, 'PAID'), (2, 'OPEN')]:
        test_session.add(AccountPayable(id=str(uuid.uuid4()), payable_number=800+number,
            description='Synthetic installment', beneficiary='Synthetic supplier', category='FORNECEDOR',
            original_amount_cents=10000, paid_amount_cents=10000 if status == 'PAID' else 0,
            balance_cents=0 if status == 'PAID' else 10000, status=status,
            due_date=datetime.datetime(2026, 9+number, 20), installment_number=number,
            total_installments=2, purchase_id=purchase.id))
    test_session.commit()
    st, items = bill(api, [line(10000)], 10000)
    review = api.post(f'/statements/{st["id"]}/semantic-reviews', {'expected_revision': 0,
        'items': [{'item_id': items[0]['id'], 'semantic_category': 'PURCHASE_BUSINESS', 'purchase_id': purchase.id}]})
    result = inspect(api, st, review)
    target, = result['requirements']
    assert target['code'] == 'PURCHASE_PAYABLE_LINK_REVIEW' and target['automatic_selection'] is False
    assert [(p['installment_number'], p['status'], p['balance_cents']) for p in target['candidates']] == [
        (1, 'PAID', 0), (2, 'OPEN', 10000)]
    # Seeing an open candidate must not lift the existing ambiguity guard.
    response = api.post(f'/statements/{st["id"]}/generate-obligations', {}, expected=(409,))
    assert response['detail']['error_code'] == 'FINANCIAL_PURCHASE_ALLOCATION_REQUIRED'
