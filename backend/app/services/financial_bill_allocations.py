"""Read-only requirements for explicit bill allocations; never authorize debt.

This inspection separates the economic links that a balanced equation cannot
prove. Persisted allocation decisions and their financial effects remain a
separate increment. Existing generation guards are intentionally unchanged.
"""
from sqlalchemy import select

from app.models.financial import AccountPayable
from app.models.financial_imports import FinancialStatement
from app.services import financial_imports as evidence
from app.services import financial_bill_semantics as semantics


def inspect_requirements(db, statement_id, expected_review_id=None):
    statement = evidence.require(db, FinancialStatement, statement_id)
    if statement.statement_type != "CARD_BILL":
        evidence.fail("FINANCIAL_BILL_SOURCE_REQUIRED", "Confira as alocacoes em uma fatura de cartao.")
    review = semantics.latest_review(db, statement_id)
    if expected_review_id is not None and (review is None or review.id != expected_review_id):
        evidence.fail("FINANCIAL_BILL_REVISION_CONFLICT", "A revisao mudou. Atualize antes de conferir os vinculos.")
    result = {"statement_id": statement_id, "review_id": review.id if review else None,
              "revision": review.revision if review else 0, "affects_ledger": False,
              "scope": "REQUIREMENTS_ONLY", "authorizes_generation": False,
              "requirements": [], "installment_observations": []}
    required = result["requirements"]
    if review is None:
        required.append({"code": "SEMANTIC_REVIEW_REQUIRED", "item_id": None})
        return result
    if not review.is_balanced or review.status != "APPROVED":
        required.append({"code": "EXACT_COMPONENT_REVIEW_REQUIRED", "item_id": None,
                         "difference_cents": review.equation_difference_cents})
    rows = semantics.review_items_with_details(db, review.id)
    semantic_ids = {row["item_id"] for row in rows}
    from app.models.financial_imports import FinancialStatementItem
    originals = {row.id: row for row in db.scalars(select(FinancialStatementItem).where(
        FinancialStatementItem.id.in_(semantic_ids)))}
    previous_items = []
    for row in rows:
        category = row["semantic_category"]
        common = {"item_id": row["item_id"], "amount_cents": row["amount_cents"]}
        if category == "REFUND_CREDIT":
            required.append({**common, "code": "CREDIT_TARGET_REQUIRED",
                             "needs": ["original_charge_or_prior_obligation", "allocated_amount", "business_or_personal_attribution"],
                             "creates_cash_income": False})
        elif category == "BILL_PAYMENT":
            required.append({**common, "code": "HISTORICAL_PAYMENT_LINK_REQUIRED",
                             "needs": ["paid_cycle", "existing_payment", "allocated_amount"],
                             "settles_current_bill": False})
        elif category == "PREVIOUS_BALANCE":
            previous_items.append(row)
            required.append({**common, "code": "PRIOR_DEBT_LINK_REQUIRED",
                             "needs": ["prior_obligations", "principal_and_charges", "remaining_balance"],
                             "creates_new_expense": False})
        original = originals.get(row["item_id"])
        data = original.normalized_data if original else {}
        if data.get("installment_number") is not None:
            result["installment_observations"].append({**common,
                "code": "CURRENT_INSTALLMENT_ONLY", "installment_number": data["installment_number"],
                "total_installments": data.get("total_installments"),
                "purchase_date": data.get("purchase_date"), "bill_due_on": statement.due_on,
                "creates_future_installments": False})
        if row["purchase_id"]:
            payables = db.scalars(select(AccountPayable).where(
                AccountPayable.purchase_id == row["purchase_id"]).order_by(
                AccountPayable.installment_number, AccountPayable.id)).all()
            required.append({**common, "code": "PURCHASE_PAYABLE_LINK_REVIEW",
                "purchase_id": row["purchase_id"], "automatic_selection": False,
                "candidates": [{"id": payable.id, "status": payable.status,
                                "balance_cents": payable.balance_cents,
                                "installment_number": payable.installment_number,
                                "total_installments": payable.total_installments,
                                "due_date": payable.due_date} for payable in payables]})
    # Some PDFs declare prior debt only in the bank summary, outside detail rows.
    if review.previous_balance_cents != 0 and not previous_items:
        required.append({"code": "PRIOR_DEBT_LINK_REQUIRED", "item_id": None,
                         "amount_cents": review.previous_balance_cents, "origin": "REPORTED_SUMMARY",
                         "needs": ["prior_obligations", "principal_and_charges", "remaining_balance"],
                         "creates_new_expense": False})
    return result
