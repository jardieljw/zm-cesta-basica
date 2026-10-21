"""One exact payment, four immutable purpose components, shared by reports."""
from sqlalchemy import select
from app.models.financial_bill_cycles import FinancialBillCycle, FinancialBillCycleRevision
from app.services.financial_bill_cycles import PARTS, confirmed_parts
from app.services.financial_imports import fail


def snapshot_payment(db, payable, payment, expected_revision):
    cycle = db.scalar(select(FinancialBillCycle).where(FinancialBillCycle.payable_id == payable.id))
    if not cycle:
        return
    if expected_revision != cycle.revision:
        fail('FINANCIAL_BILL_REVISION_CONFLICT', 'A composicao da fatura mudou. Atualize e confira antes de pagar.')
    revision = db.scalar(select(FinancialBillCycleRevision).where(
        FinancialBillCycleRevision.cycle_id == cycle.id, FinancialBillCycleRevision.revision == cycle.revision))
    used = confirmed_parts(db, payable.id)
    remaining = {p: getattr(revision, p) - used[p] for p in PARTS}
    total = sum(remaining.values())
    if total != payable.balance_cents or any(v < 0 for v in remaining.values()) or total < payment.amount_cents:
        fail('FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT', 'Confira a composicao e o saldo desta cobranca.')
    quotient = {p: payment.amount_cents * remaining[p] // total for p in PARTS}
    order = sorted(PARTS, key=lambda p: (-(payment.amount_cents * remaining[p] % total), p))
    for p in order[:payment.amount_cents - sum(quotient.values())]:
        quotient[p] += 1
    payment.bill_revision_id = revision.id
    for p in PARTS:
        setattr(payment, p, quotient[p])


def entry_composition(entry, payment=None):
    sign = 1 if entry.entry_type == 'DEBIT' else -1
    if payment and payment.bill_revision_id:
        return {p: sign * getattr(payment, p) for p in PARTS}
    stock = entry.source_type == 'PURCHASE' or entry.category == 'COMPRA_INSUMOS' or bool(payment and payment.payable and payment.payable.purchase_id)
    part = ('personal_cents' if entry.nature == 'PERSONAL_WITHDRAWAL' else
            'stock_cents' if stock else 'business_cents' if entry.nature == 'BUSINESS' else 'unclassified_cents')
    return {p: sign * entry.amount_cents if p == part else 0 for p in PARTS}
