"""Semantic classification of credit card bill items and safe obligations integration.

Follows FAT-005 to FAT-009 invariants:
- Zero duplication of expenses and CMPM.
- Clear segregation of BUSINESS vs PERSONAL_WITHDRAWAL.
- Mathematical component equation validation.
- Append-only reviews and obligations.
"""
import datetime
import uuid
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.models.base import utc_now
from app.models.financial import AccountPayable
from app.models.purchases import Purchase
from app.models.financial_imports import (
    FinancialStatement, FinancialStatementItem, FinancialSource,
    FinancialImportAudit, FinancialImportPreview,
)
from app.models.financial_bill_semantics import (
    FinancialBillSemanticReview, FinancialBillSemanticItem, FinancialBillObligation,
)
from app.schemas.financial_bill_semantics import (
    BillSemanticReviewCreate, BillGenerateObligationsRequest,
)
from app.services import financial_imports as base_import
from app.services.financial import generate_next_payable_number


def fail(code: str, message: str, status: int = 409):
    raise HTTPException(status, detail={"error_code": code, "message": message})


def latest_review(db: Session, statement_id: str) -> Optional[FinancialBillSemanticReview]:
    return db.scalar(
        select(FinancialBillSemanticReview)
        .where(FinancialBillSemanticReview.statement_id == statement_id)
        .order_by(FinancialBillSemanticReview.revision.desc())
        .limit(1)
    )


def review_items_with_details(db: Session, review_id: str):
    items = db.scalars(
        select(FinancialBillSemanticItem)
        .where(FinancialBillSemanticItem.review_id == review_id)
    ).all()
    if not items:
        return []
    statement_items = {
        i.id: i for i in db.scalars(
            select(FinancialStatementItem).where(
                FinancialStatementItem.id.in_([it.item_id for it in items])
            )
        ).all()
    }
    result = []
    for it in items:
        si = statement_items.get(it.item_id)
        data = si.normalized_data if si else {}
        result.append({
            "id": it.id,
            "item_id": it.item_id,
            "position": si.position if si else None,
            "description": data.get("description", ""),
            "transaction_date": data.get("transaction_date"),
            "amount_cents": it.amount_cents,
            "semantic_category": it.semantic_category,
            "purchase_id": it.purchase_id,
            "notes": it.notes,
        })
    result.sort(key=lambda x: (x["position"] or 0, x["id"]))
    return result


def format_review_summary(db: Session, review: FinancialBillSemanticReview) -> dict:
    return {
        "id": review.id,
        "statement_id": review.statement_id,
        "revision": review.revision,
        "declared_total_cents": review.declared_total_cents,
        "previous_balance_cents": review.previous_balance_cents,
        "purchases_business_cents": review.purchases_business_cents,
        "purchases_personal_cents": review.purchases_personal_cents,
        "financial_charges_cents": review.financial_charges_cents,
        "payments_cents": review.payments_cents,
        "refunds_cents": review.refunds_cents,
        "equation_difference_cents": review.equation_difference_cents,
        "is_balanced": review.is_balanced,
        "status": review.status,
        "notes": review.notes,
        "created_by": review.created_by,
        "created_at": review.created_at,
        "items": review_items_with_details(db, review.id),
    }


def create_semantic_review(
    db: Session, statement_id: str, data: BillSemanticReviewCreate, actor_id: str,
) -> dict:
    statement = base_import.require(db, FinancialStatement, statement_id)
    if statement.statement_type != "CARD_BILL":
        fail("FINANCIAL_BILL_SOURCE_REQUIRED", "Revisao semantica de fatura exige documento do tipo CARD_BILL.")

    current = latest_review(db, statement_id)
    current_rev = current.revision if current else 0
    if data.expected_revision != current_rev:
        fail("FINANCIAL_BILL_REVISION_CONFLICT", "A revisao semantica foi alterada por outro terminal. Atualize e confira.")

    # Retrieve all confirmed statement items for this card bill
    st_items = db.scalars(
        select(FinancialStatementItem).where(FinancialStatementItem.statement_id == statement_id)
    ).all()
    st_items_by_id = {i.id: i for i in st_items}

    # Validate that all incoming review items belong to this statement
    input_item_ids = {it.item_id for it in data.items}
    unknown_ids = input_item_ids - set(st_items_by_id.keys())
    if unknown_ids:
        fail("FINANCIAL_ITEM_NOT_FOUND", "Ha itens informados que nao pertencem a esta fatura.")

    if len(input_item_ids) != len(st_items_by_id):
        fail("FINANCIAL_BILL_ITEMS_UNCOVERED", f"Todas as {len(st_items_by_id)} linhas da fatura devem ser classificadas.")

    # Verify any linked purchase exists
    purchase_ids = {it.purchase_id for it in data.items if it.purchase_id}
    if purchase_ids:
        existing_purchases = set(db.scalars(select(Purchase.id).where(Purchase.id.in_(purchase_ids))).all())
        missing_purchases = purchase_ids - existing_purchases
        if missing_purchases:
            fail("FINANCIAL_PURCHASE_NOT_FOUND", "Uma ou mais compras vinculadas nao foram encontradas.")

    # Calculate component sums
    # Amounts in statement items: charges are positive, credits may be negative
    previous_balance = 0
    purchases_business = 0
    purchases_personal = 0
    financial_charges = 0
    payments = 0
    refunds = 0

    review_id = str(uuid.uuid4())
    next_revision = current_rev + 1
    now = utc_now()

    new_review_items: List[FinancialBillSemanticItem] = []

    for item_input in data.items:
        st_item = st_items_by_id[item_input.item_id]
        item_amount = st_item.normalized_data.get("amount_cents", 0)
        cat = item_input.semantic_category

        if cat == "PREVIOUS_BALANCE":
            previous_balance += item_amount
        elif cat == "PURCHASE_BUSINESS":
            purchases_business += item_amount
        elif cat == "PURCHASE_PERSONAL":
            purchases_personal += item_amount
        elif cat == "FINANCIAL_CHARGES":
            financial_charges += item_amount
        elif cat == "BILL_PAYMENT":
            payments += abs(item_amount)
        elif cat == "REFUND_CREDIT":
            refunds += abs(item_amount)
        elif cat == "CONTEXT_ONLY":
            pass

        new_review_items.append(FinancialBillSemanticItem(
            id=str(uuid.uuid4()),
            review_id=review_id,
            item_id=st_item.id,
            semantic_category=cat,
            amount_cents=item_amount,
            purchase_id=item_input.purchase_id,
            notes=item_input.notes.strip() if item_input.notes else None,
        ))

    # Check preview reported_summary for previous_balance
    preview = db.get(FinancialImportPreview, statement.preview_id) if statement.preview_id else None
    if not preview:
        preview = db.scalar(
            select(FinancialImportPreview)
            .where(
                FinancialImportPreview.document_id == statement.document_id,
                FinancialImportPreview.source_id == statement.source_id,
            )
            .order_by(FinancialImportPreview.created_at.desc())
        )
    reported_prev = 0
    if preview and preview.result and "reported_summary" in preview.result:
        reported_prev = abs(preview.result["reported_summary"].get("previous", 0) or 0)

    if previous_balance == 0 and reported_prev > 0:
        previous_balance = reported_prev
    elif reported_prev > 0 and previous_balance != reported_prev:
        # Check if substituting reported_prev for previous_balance balances the equation
        declared_total = statement.total_amount_cents or 0
        test_calc = reported_prev + purchases_business + purchases_personal + financial_charges - payments - refunds
        if abs(declared_total - test_calc) <= 10:
            previous_balance = reported_prev

    # Equation: Declared Total = Previous Balance + Purchases Business + Purchases Personal + Charges - Payments - Refunds
    declared_total = statement.total_amount_cents or 0
    calculated_total = (
        previous_balance
        + purchases_business
        + purchases_personal
        + financial_charges
        - payments
        - refunds
    )
    difference = declared_total - calculated_total
    if abs(difference) <= 10:
        financial_charges += difference
        difference = 0
        is_balanced = True
        status = "APPROVED"
    else:
        is_balanced = False
        status = "DRAFT"

    review = FinancialBillSemanticReview(
        id=review_id,
        statement_id=statement_id,
        revision=next_revision,
        declared_total_cents=declared_total,
        previous_balance_cents=previous_balance,
        purchases_business_cents=purchases_business,
        purchases_personal_cents=purchases_personal,
        financial_charges_cents=financial_charges,
        payments_cents=payments,
        refunds_cents=refunds,
        equation_difference_cents=difference,
        is_balanced=is_balanced,
        status=status,
        notes=data.notes.strip() if data.notes else None,
        created_by=actor_id,
        created_at=now,
    )
    db.add(review)
    db.flush()

    for r_item in new_review_items:
        db.add(r_item)
    db.flush()

    base_import.audit(db, actor_id, "BILL_SEMANTIC_REVIEW_SAVED", review, {
        "revision": next_revision,
        "is_balanced": is_balanced,
        "status": status,
        "difference_cents": difference,
    })

    return format_review_summary(db, review)


def get_current_semantic_review(db: Session, statement_id: str) -> Optional[dict]:
    statement = base_import.require(db, FinancialStatement, statement_id)
    review = latest_review(db, statement_id)
    if not review:
        return None
    return format_review_summary(db, review)


def generate_bill_obligations(
    db: Session, statement_id: str, data: BillGenerateObligationsRequest, actor_id: str,
) -> List[dict]:
    statement = base_import.require(db, FinancialStatement, statement_id)
    if statement.statement_type != "CARD_BILL":
        fail("FINANCIAL_BILL_SOURCE_REQUIRED", "Apenas faturas de cartao geram obrigacoes consolidadas.")

    source = base_import.require(db, FinancialSource, statement.source_id)

    # Check for existing obligations
    existing_obligations = db.scalars(
        select(FinancialBillObligation).where(FinancialBillObligation.statement_id == statement_id)
    ).all()
    if existing_obligations:
        return list_bill_obligations(db, statement_id)

    # Resolve review
    if data.review_id:
        review = db.get(FinancialBillSemanticReview, data.review_id)
        if not review or review.statement_id != statement_id:
            fail("FINANCIAL_REVIEW_NOT_FOUND", "Revisao semantica nao encontrada para esta fatura.", 404)
    else:
        review = latest_review(db, statement_id)
        if not review:
            fail("FINANCIAL_REVIEW_REQUIRED", "Revisao semantica obrigatoria antes de gerar obrigacoes.")

    if not review.is_balanced or review.status != "APPROVED":
        fail(
            "BILL_REVIEW_NOT_BALANCED",
            f"A revisao semantica precisa estar balanceada e aprovada. Diferenca atual: {review.equation_difference_cents} centavos.",
        )

    # Collect review items with details
    semantic_items = db.scalars(
        select(FinancialBillSemanticItem).where(FinancialBillSemanticItem.review_id == review.id)
    ).all()
    statement_items = {
        i.id: i for i in db.scalars(
            select(FinancialStatementItem).where(
                FinancialStatementItem.id.in_([it.item_id for it in semantic_items])
            )
        ).all()
    }

    due_dt = (
        datetime.datetime.combine(statement.due_on, datetime.time(12, 0))
        if statement.due_on else utc_now()
    )
    now = utc_now()
    created_obligations: List[FinancialBillObligation] = []

    for s_item in semantic_items:
        st_item = statement_items.get(s_item.item_id)
        item_data = st_item.normalized_data if st_item else {}
        desc = item_data.get("description", "Operacao Cartao")
        cat = s_item.semantic_category
        amount = s_item.amount_cents

        if cat == "PURCHASE_BUSINESS":
            if s_item.purchase_id:
                # Linked to an existing Purchase! Check for existing AccountPayable
                existing_payable = db.scalar(
                    select(AccountPayable).where(AccountPayable.purchase_id == s_item.purchase_id).limit(1)
                )
                if existing_payable:
                    obligation = FinancialBillObligation(
                        id=str(uuid.uuid4()),
                        statement_id=statement_id,
                        review_id=review.id,
                        account_payable_id=existing_payable.id,
                        component_type="PURCHASE_LINKED",
                        amount_cents=abs(amount),
                        purchase_id=s_item.purchase_id,
                        created_by=actor_id,
                        created_at=now,
                    )
                    db.add(obligation)
                    created_obligations.append(obligation)
                    continue
                else:
                    # Create AccountPayable linked to purchase
                    num = generate_next_payable_number(db)
                    payable = AccountPayable(
                        id=str(uuid.uuid4()),
                        payable_number=num,
                        description=f"Fatura {source.name}: Compra estoque #{s_item.purchase_id[:8]}",
                        beneficiary=source.name,
                        category="FORNECEDOR",
                        nature="BUSINESS",
                        original_amount_cents=abs(amount),
                        paid_amount_cents=0,
                        balance_cents=abs(amount),
                        due_date=due_dt,
                        payment_method="CARTAO_CREDITO",
                        status="OPEN",
                        purchase_id=s_item.purchase_id,
                        created_at=now,
                        updated_at=now,
                    )
                    db.add(payable)
                    db.flush()
                    obligation = FinancialBillObligation(
                        id=str(uuid.uuid4()),
                        statement_id=statement_id,
                        review_id=review.id,
                        account_payable_id=payable.id,
                        component_type="PURCHASE_LINKED",
                        amount_cents=abs(amount),
                        purchase_id=s_item.purchase_id,
                        created_by=actor_id,
                        created_at=now,
                    )
                    db.add(obligation)
                    created_obligations.append(obligation)
                    continue

            # Unlinked operational business purchase
            num = generate_next_payable_number(db)
            payable = AccountPayable(
                id=str(uuid.uuid4()),
                payable_number=num,
                description=f"Fatura {source.name}: {desc}",
                beneficiary=source.name,
                category="CARTAO_CREDITO",
                nature="BUSINESS",
                original_amount_cents=abs(amount),
                paid_amount_cents=0,
                balance_cents=abs(amount),
                due_date=due_dt,
                payment_method="CARTAO_CREDITO",
                status="OPEN",
                installment_number=item_data.get("installment_number") or 1,
                total_installments=item_data.get("total_installments") or 1,
                created_at=now,
                updated_at=now,
            )
            db.add(payable)
            db.flush()
            obligation = FinancialBillObligation(
                id=str(uuid.uuid4()),
                statement_id=statement_id,
                review_id=review.id,
                account_payable_id=payable.id,
                component_type="PURCHASE_BUSINESS",
                amount_cents=abs(amount),
                created_by=actor_id,
                created_at=now,
            )
            db.add(obligation)
            created_obligations.append(obligation)

        elif cat == "PURCHASE_PERSONAL":
            num = generate_next_payable_number(db)
            beneficiary_name = source.holder_name or source.name
            payable = AccountPayable(
                id=str(uuid.uuid4()),
                payable_number=num,
                description=f"Fatura {source.name} (Retirada Socio): {desc}",
                beneficiary=beneficiary_name,
                category="RETIRADA_SOCIO",
                nature="PERSONAL_WITHDRAWAL",
                original_amount_cents=abs(amount),
                paid_amount_cents=0,
                balance_cents=abs(amount),
                due_date=due_dt,
                payment_method="CARTAO_CREDITO",
                status="OPEN",
                installment_number=item_data.get("installment_number") or 1,
                total_installments=item_data.get("total_installments") or 1,
                created_at=now,
                updated_at=now,
            )
            db.add(payable)
            db.flush()
            obligation = FinancialBillObligation(
                id=str(uuid.uuid4()),
                statement_id=statement_id,
                review_id=review.id,
                account_payable_id=payable.id,
                component_type="PURCHASE_PERSONAL",
                amount_cents=abs(amount),
                created_by=actor_id,
                created_at=now,
            )
            db.add(obligation)
            created_obligations.append(obligation)

        elif cat == "FINANCIAL_CHARGES":
            num = generate_next_payable_number(db)
            payable = AccountPayable(
                id=str(uuid.uuid4()),
                payable_number=num,
                description=f"Fatura {source.name} (Encargo/Juros): {desc}",
                beneficiary=source.institution,
                category="CARTAO_CREDITO",
                nature="BUSINESS",
                original_amount_cents=abs(amount),
                paid_amount_cents=0,
                balance_cents=abs(amount),
                due_date=due_dt,
                payment_method="CARTAO_CREDITO",
                status="OPEN",
                created_at=now,
                updated_at=now,
            )
            db.add(payable)
            db.flush()
            obligation = FinancialBillObligation(
                id=str(uuid.uuid4()),
                statement_id=statement_id,
                review_id=review.id,
                account_payable_id=payable.id,
                component_type="FINANCIAL_CHARGES",
                amount_cents=abs(amount),
                created_by=actor_id,
                created_at=now,
            )
            db.add(obligation)
            created_obligations.append(obligation)

        # BILL_PAYMENT, PREVIOUS_BALANCE, REFUND_CREDIT, CONTEXT_ONLY generate 0 AccountPayable records

    db.flush()

    base_import.audit(db, actor_id, "BILL_OBLIGATIONS_GENERATED", statement, {
        "review_id": review.id,
        "obligations_count": len(created_obligations),
    })

    return list_bill_obligations(db, statement_id)


def list_bill_obligations(db: Session, statement_id: str) -> List[dict]:
    statement = base_import.require(db, FinancialStatement, statement_id)
    obligations = db.scalars(
        select(FinancialBillObligation)
        .where(FinancialBillObligation.statement_id == statement_id)
        .order_by(FinancialBillObligation.created_at)
    ).all()
    if not obligations:
        return []
    payable_ids = [o.account_payable_id for o in obligations]
    payables = {
        p.id: p for p in db.scalars(
            select(AccountPayable).where(AccountPayable.id.in_(payable_ids))
        ).all()
    }
    result = []
    for ob in obligations:
        p = payables.get(ob.account_payable_id)
        result.append({
            "id": ob.id,
            "statement_id": ob.statement_id,
            "review_id": ob.review_id,
            "account_payable_id": ob.account_payable_id,
            "payable_number": p.payable_number if p else None,
            "component_type": ob.component_type,
            "amount_cents": ob.amount_cents,
            "purchase_id": ob.purchase_id,
            "status": p.status if p else None,
            "due_date": p.due_date if p else None,
            "description": p.description if p else None,
            "category": p.category if p else None,
            "nature": p.nature if p else None,
            "created_at": ob.created_at,
        })
    return result
