import sqlite3, json, sys, os
sys.path.insert(0, os.path.abspath("backend"))

from app.core.database import SessionLocal
from app.services import financial_previews, financial_bill_semantics
from app.models.financial_imports import FinancialImportPreview, FinancialStatementItem, FinancialStatement
from app.schemas.financial_readers import FinancialPreviewConfirm
from app.schemas.financial_bill_semantics import BillGenerateObligationsRequest, BillSemanticReviewCreate, BillSemanticItemInput
from app.models.financial import AccountPayable

db = SessionLocal()
pids = [
    "104fafd2-e371-410a-9a3a-315687be17d5",
    "36711fcc-7a09-4f98-a7d7-90562f1cf58d",
    "da45408d-7363-4b36-baff-a7946fa4ce8f",
    "cbaa36a7-3a27-4979-bcc3-d6ee15edebe0",
]

total_obligations = 0

for pid in pids:
    preview = db.get(FinancialImportPreview, pid)
    if not preview:
        print(f"Preview {pid} not found")
        continue

    # Check if already confirmed
    existing_stmt = db.query(FinancialStatement).filter(FinancialStatement.preview_id == pid).first()
    if existing_stmt:
        stmt_id = existing_stmt.id
        print(f"Preview {pid} already confirmed as statement {stmt_id}")
    else:
        hdr = preview.result.get('extracted_header', {})
        confirm_data = FinancialPreviewConfirm(
            expected_source_id=preview.source_id,
            expected_result_sha256=preview.result_sha256,
            statement_type=hdr.get('statement_type', 'CARD_BILL'),
            due_on=hdr.get('due_on'),
            total_amount_cents=hdr.get('total_amount_cents'),
            minimum_payment_cents=hdr.get('minimum_payment_cents'),
            period_start=hdr.get('period_start'),
            period_end=hdr.get('period_end'),
        )
        result = financial_previews.confirm_preview(db, preview.id, confirm_data, "windows-local-master-id")
        stmt_id = result["statement"]["id"]
        print(f"Confirmed preview {pid} -> statement {stmt_id}")

    items = db.query(FinancialStatementItem).filter(FinancialStatementItem.statement_id == stmt_id).all()

    def classify(it):
        d = it.normalized_data
        desc = (d.get("description") or "").lower()
        amt = d.get("amount_cents", 0)
        
        if "pagamento" in desc or "pgto" in desc:
            return "BILL_PAYMENT"
        if amt < 0:
            return "REFUND_CREDIT"
        if any(w in desc for w in ["juros", "multa", "iof", "anuidade", "saldo em atraso", "encerramento", "tarifa"]):
            return "FINANCIAL_CHARGES"
        if any(w in desc for w in ["retirada", "particular", "socio"]):
            return "PURCHASE_PERSONAL"
        return "PURCHASE_BUSINESS"

    semantic_items = [
        BillSemanticItemInput(
            item_id=it.id,
            semantic_category=classify(it)
        )
        for it in items
    ]

    review_data = BillSemanticReviewCreate(
        expected_revision=0,
        notes="Classificação automática e lançamento em Contas a Pagar",
        items=semantic_items
    )

    current_review = financial_bill_semantics.latest_review(db, stmt_id)
    if not current_review:
        res = financial_bill_semantics.create_semantic_review(db, stmt_id, review_data, "windows-local-master-id")
    else:
        res = financial_bill_semantics.serialize_review(db, current_review)

    print(f"Review for statement {stmt_id}: status={res['status']}, is_balanced={res['is_balanced']}, diff={res['equation_difference_cents']}")

    from app.models.financial_bill_semantics import FinancialBillObligation
    obs_count = db.query(FinancialBillObligation).filter(FinancialBillObligation.statement_id == stmt_id).count()
    if obs_count == 0 and res["is_balanced"]:
        gen_req = BillGenerateObligationsRequest(review_id=res["id"])
        obs = financial_bill_semantics.generate_bill_obligations(db, stmt_id, gen_req, "windows-local-master-id")
        print(f"Generated {len(obs)} obligations for statement {stmt_id}")
        total_obligations += len(obs)
    else:
        print(f"Obligations already exist or not balanced: {obs_count}")

# Audit evidence is strictly immutable in SQLite trigger: preserve all previews
db.commit()
db.close()
print(f"DONE! Processed bills, generated {total_obligations} obligations total.")
