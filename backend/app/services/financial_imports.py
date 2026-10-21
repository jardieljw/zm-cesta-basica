"""Financial evidence lifecycle. These services never write cash or debt books."""
import datetime
import hashlib
import uuid

from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import Session

from app.core.idempotency import compute_payload_hash
from app.models.base import utc_now
from app.models.financial import FinancialAccount, CashFlowEntry
from app.models.financial_imports import (
    FinancialSource, FinancialDocument, FinancialStatement, FinancialStatementItem,
    FinancialTransaction, FinancialTransactionIdentity, FinancialReconciliation, FinancialImportAudit,
    FinancialImportPreview,
)
from app.schemas.financial_imports import (
    FinancialSourceCreate, FinancialStatementCreate, FinancialItemReview,
    FinancialTransactionData, FinancialReconciliationCreate,
)
from app.services.financial_review_corrections import (
    effective_items, current_item, identity_owner, active_evidence,
    assign_identity, canonical_for_new, assert_identity_compatible,
    effective_identities,
)

MAX_DOCUMENT_BYTES = 10 * 1024 * 1024
MEDIA_TYPES = {"application/pdf", "text/csv", "application/x-ofx", "application/vnd.intu.qfx"}


def fail(code, message, status=409):
    raise HTTPException(status, detail={"error_code": code, "message": message})


def require(db, model, object_id):
    obj = db.get(model, object_id)
    if obj is None:
        fail("FINANCIAL_RESOURCE_NOT_FOUND", "Registro financeiro nao encontrado.", 404)
    if model is FinancialStatement:
        from app.services.financial_import_lifecycle import current_statement
        current_statement(db, obj.id)
    elif model is FinancialStatementItem:
        from app.services.financial_import_lifecycle import current_statement
        current_statement(db, obj.statement_id)
    return obj


def as_dict(obj):
    # The deferred binary column is deliberately excluded from all JSON output.
    result = {c.key: getattr(obj, c.key) for c in inspect(type(obj)).column_attrs if c.key not in {"content", "result"}}
    if isinstance(obj, FinancialTransaction) and obj.transaction_time is not None:
        result["transaction_time"] = obj.transaction_time.isoformat(timespec=(
            "minutes" if obj.time_precision == "MINUTE" else "seconds"
        ))
    return result


def audit(db, actor_id, event_type, obj, details=None):
    db.add(FinancialImportAudit(
        id=str(uuid.uuid4()), actor_id=actor_id, event_type=event_type,
        entity_type=obj.__tablename__, entity_id=obj.id, details=details or {},
    ))


def create_source(db: Session, data: FinancialSourceCreate, actor_id):
    if data.financial_account_id:
        account = require(db, FinancialAccount, data.financial_account_id)
        if account.account_type != "BANK" or not account.is_active:
            fail("FINANCIAL_BANK_ACCOUNT_REQUIRED", "A origem exige uma conta bancaria ativa.")
        if db.scalar(select(FinancialSource.id).where(FinancialSource.financial_account_id == account.id)):
            fail("FINANCIAL_SOURCE_EXISTS", "Esta conta bancaria ja possui uma origem financeira.")
    source = FinancialSource(id=str(uuid.uuid4()), created_by=actor_id, **data.model_dump())
    db.add(source)
    db.flush()
    audit(db, actor_id, "SOURCE_CREATED", source)
    return as_dict(source)


def store_document(db: Session, content: bytes, filename: str, media_type: str, actor_id):
    if not content or len(content) > MAX_DOCUMENT_BYTES:
        fail("FINANCIAL_DOCUMENT_SIZE", "Documento vazio ou acima do limite de 10 MiB.", 413)
    if media_type not in MEDIA_TYPES:
        fail("FINANCIAL_DOCUMENT_TYPE", "Tipo de documento nao suportado.", 415)
    if media_type == "application/pdf" and not content.startswith(b"%PDF-"):
        fail("FINANCIAL_DOCUMENT_FORMAT", "Conteudo nao corresponde a um PDF.", 422)
    digest = hashlib.sha256(content).hexdigest()
    old = db.scalar(select(FinancialDocument).where(FinancialDocument.sha256 == digest))
    if old:
        audit(db, actor_id, "DOCUMENT_REUSED", old, {"received_filename": filename})
        return {"document": as_dict(old), "duplicate": True}
    document = FinancialDocument(
        id=str(uuid.uuid4()), sha256=digest, filename=filename, media_type=media_type,
        size_bytes=len(content), content=content, created_by=actor_id,
    )
    db.add(document)
    db.flush()
    audit(db, actor_id, "DOCUMENT_STORED", document)
    return {"document": as_dict(document), "duplicate": False}


def statement_summary(db, statement):
    result = as_dict(statement)
    from app.services.financial_import_lifecycle import statement_context
    result.update(statement_context(db, statement.id))
    result["items_count"] = db.scalar(select(func.count()).select_from(FinancialStatementItem).where(
        FinancialStatementItem.statement_id == statement.id))
    result["pending_count"] = db.scalar(select(func.count()).select_from(FinancialStatementItem).where(
        FinancialStatementItem.statement_id == statement.id, FinancialStatementItem.review_status == "PENDING"))
    result["linked_count"] = db.scalar(select(func.count()).select_from(FinancialStatementItem).where(
        FinancialStatementItem.statement_id == statement.id, FinancialStatementItem.review_status == "LINKED"))
    result["checks"] = []
    fields = (statement.opening_balance_cents, statement.total_inflows_cents,
              statement.total_outflows_cents, statement.closing_balance_cents)
    if all(v is not None for v in fields):
        opening, credits, debits, closing = fields
        result["checks"].append({"code": "REPORTED_BALANCE_EQUATION", "matches": opening + credits - debits == closing,
                                  "difference_cents": closing - (opening + credits - debits)})
    if statement.preview_id:
        report = require(db, FinancialImportPreview, statement.preview_id).result
        if statement.statement_type == "BANK_STATEMENT":
            for field, total, code in (
                ("total_inflows_cents", "positive_cents", "IMPORTED_INFLOWS_TOTAL"),
                ("total_outflows_cents", "negative_cents", "IMPORTED_OUTFLOWS_TOTAL"),
            ):
                declared = getattr(statement, field)
                if declared is not None:
                    difference = declared - report["totals"][total]
                    result["checks"].append({"code": code, "matches": difference == 0, "difference_cents": difference})
        if statement.period_start and report["observed_dates"]:
            observed = report["observed_dates"]
            result["checks"].append({"code": "OBSERVED_DATES_WITHIN_PERIOD", "matches": (
                observed["first"] >= statement.period_start.isoformat() and observed["last"] <= statement.period_end.isoformat()
            )})
    # Card lines may include prior bill payments: their sum is not its new debt.
    result["affects_ledger"] = False
    return result


def create_statement(db: Session, data: FinancialStatementCreate, actor_id, *, preview_id=None):
    require(db, FinancialDocument, data.document_id)
    source = require(db, FinancialSource, data.source_id)
    if (data.statement_type == "CARD_BILL") != (source.source_type == "CREDIT_CARD"):
        fail("FINANCIAL_STATEMENT_SOURCE_MISMATCH", "Documento incompativel com a origem bancaria/cartao.")
    payload = data.model_dump(mode="json")
    if preview_id:
        payload["preview_id"] = preview_id
    payload_hash = compute_payload_hash(payload)
    old = db.scalar(select(FinancialStatement).where(
        FinancialStatement.document_id == data.document_id, FinancialStatement.source_id == data.source_id,
        FinancialStatement.payload_sha256 == payload_hash,
    ))
    if old:
        return {"statement": statement_summary(db, old), "duplicate": True}
    statement = FinancialStatement(
        id=str(uuid.uuid4()), payload_sha256=payload_hash, created_by=actor_id, preview_id=preview_id,
        **data.model_dump(exclude={"items"}),
    )
    db.add(statement)
    db.flush()
    for item in data.items:
        db.add(FinancialStatementItem(
            id=str(uuid.uuid4()), statement_id=statement.id, position=item.position,
            page_number=item.page_number, raw_text=item.raw_text,
            normalized_data=item.data.model_dump(mode="json"), review_status="PENDING",
        ))
    db.flush()
    audit(db, actor_id, "STATEMENT_STAGED", statement, {"items_count": len(data.items)})
    return {"statement": statement_summary(db, statement), "duplicate": False}


def external_match(db, source_id, data):
    if data.external_id is None:
        return None
    transaction_id = identity_owner(db, source_id, data.external_id_namespace, data.external_id)
    return require(db, FinancialTransaction, transaction_id) if transaction_id and active_evidence(db, transaction_id) else None


def candidate_transactions(db, item_id):
    item = require(db, FinancialStatementItem, item_id)
    statement = require(db, FinancialStatement, item.statement_id)
    data = FinancialTransactionData.model_validate(item.normalized_data)
    return data_candidates(db, statement.source_id, data)


def data_candidates(db, source_id, data):
    exact = external_match(db, source_id, data)
    if exact:
        matched_identity = {"namespace": data.external_id_namespace, "external_id": data.external_id}
        try:
            _compatible(exact, source_id, data)
        except HTTPException as exc:
            return [{"basis": "EXTERNAL_ID_CONFLICT", "error_code": exc.detail["error_code"], "transaction": as_dict(exact), "matched_identity": matched_identity}]
        return [{"basis": "EXTERNAL_ID", "transaction": as_dict(exact), "matched_identity": matched_identity}]
    # A distinct reliable ID is a distinct event, despite the same date/value.
    if data.external_id:
        return []
    view = effective_items()
    candidates = db.scalars(select(FinancialTransaction).where(
        FinancialTransaction.source_id == source_id,
        FinancialTransaction.transaction_date == data.transaction_date,
        FinancialTransaction.amount_cents == data.amount_cents,
        FinancialTransaction.id.in_(select(view.c.transaction_id).where(view.c.transaction_id.is_not(None))),
    ).order_by(FinancialTransaction.created_at.desc(), FinancialTransaction.id).limit(20)).all()
    return [{"basis": "SAME_DATE_AMOUNT_REQUIRES_REVIEW", "transaction": as_dict(t)} for t in candidates]


def _compatible(transaction, source_id, data):
    if transaction.source_id != source_id or transaction.amount_cents != data.amount_cents:
        fail("FINANCIAL_TRANSACTION_MISMATCH", "Origem ou valor divergente da transacao selecionada.")
    date_facts = []
    for kind, field in (("PURCHASE", "purchase_date"), ("BOOKING", "booking_date")):
        reported = getattr(data, field) or (data.transaction_date if data.date_kind == kind else None)
        existing = getattr(transaction, field) or (transaction.transaction_date if transaction.date_kind == kind else None)
        if reported is not None and existing is not None:
            date_facts.append(reported == existing)
    if False in date_facts or (transaction.transaction_date != data.transaction_date and not date_facts):
        fail("FINANCIAL_TRANSACTION_DATE_MISMATCH", "Data divergente; a correspondencia exige revisao dos dados.")
    for field in ("card_last_four", "installment_number", "total_installments", "counterparty_document"):
        reported, existing = getattr(data, field), getattr(transaction, field)
        if reported is not None and existing is not None and reported != existing:
            fail("FINANCIAL_TRANSACTION_MISMATCH", "Dados da operacao divergem da transacao selecionada.")
    if data.transaction_time and transaction.transaction_time:
        incoming = datetime.time.fromisoformat(data.transaction_time)
        if (incoming.hour, incoming.minute) != (transaction.transaction_time.hour, transaction.transaction_time.minute):
            fail("FINANCIAL_TRANSACTION_TIME_MISMATCH", "Horarios conhecidos divergentes.")
        if len(data.transaction_time) == 8 and transaction.time_precision == "SECOND" and incoming.second != transaction.transaction_time.second:
            fail("FINANCIAL_TRANSACTION_TIME_MISMATCH", "Horarios conhecidos divergentes.")
    if data.utc_offset_minutes is not None and transaction.utc_offset_minutes is not None and data.utc_offset_minutes != transaction.utc_offset_minutes:
        fail("FINANCIAL_TRANSACTION_TIME_MISMATCH", "Fusos informados divergentes.")


def review_item(db: Session, item_id, review: FinancialItemReview, actor_id):
    from app.services.financial_import_lifecycle import guard_item
    guard_item(db, item_id, review)
    item = require(db, FinancialStatementItem, item_id)
    if item.review_status != "PENDING":
        fail("FINANCIAL_ITEM_ALREADY_REVIEWED", "Esta linha ja foi conferida. Consulte o historico.")
    statement = require(db, FinancialStatement, item.statement_id)
    data = FinancialTransactionData.model_validate(item.normalized_data)
    transaction = None
    status = "IGNORED"
    if review.action != "IGNORE":
        exact = external_match(db, statement.source_id, data)
        if review.action == "LINK":
            transaction = require(db, FinancialTransaction, review.transaction_id)
            if not active_evidence(db, transaction.id):
                fail("FINANCIAL_TRANSACTION_INACTIVE", "Escolha uma operacao com evidencia confirmada ativa.")
            if exact is not None and transaction.id != exact.id:
                fail("FINANCIAL_EXTERNAL_ID_CONFLICT", "Identificador externo ja pertence a outra transacao.")
            status = "LINKED"
        elif exact:
            transaction, status = exact, "LINKED"
        else:
            transaction = canonical_for_new(db, statement.source_id, data, actor_id)
            status = "NEW"
        _compatible(transaction, statement.source_id, data)
        assert_identity_compatible(db, statement.source_id, data, transaction.id, exclude_item_id=item_id)
        assign_identity(db, statement.source_id, data, transaction.id, actor_id, review.reason)
        item.transaction_id = transaction.id
    item.review_status, item.reviewed_by, item.reviewed_at = status, actor_id, utc_now()
    audit(db, actor_id, "ITEM_" + status, item, {"reason": review.reason, "transaction_id": item.transaction_id})
    db.flush()
    return {"item": current_item(db, item.id), "transaction": as_dict(transaction) if transaction else None, "affects_ledger": False}


def _allocated(db, column, object_id):
    return db.scalar(select(func.coalesce(func.sum(FinancialReconciliation.amount_cents), 0)).where(
        column == object_id, FinancialReconciliation.voided_at.is_(None)))


def transaction_summaries(db, transactions):
    if not transactions:
        return []
    allocated = dict(db.execute(select(
        FinancialReconciliation.transaction_id, func.sum(FinancialReconciliation.amount_cents),
    ).where(FinancialReconciliation.transaction_id.in_([t.id for t in transactions]),
            FinancialReconciliation.voided_at.is_(None)).group_by(FinancialReconciliation.transaction_id)).all())
    sources = {s.id: s for s in db.scalars(select(FinancialSource).where(
        FinancialSource.id.in_({t.source_id for t in transactions}))).all()}
    result = []
    view = effective_items()
    evidence_counts = dict(db.execute(select(view.c.transaction_id, func.count()).where(
        view.c.transaction_id.in_([t.id for t in transactions])).group_by(view.c.transaction_id)).all())
    identities = effective_identities()
    owners = {}
    for row in db.execute(select(identities).where(identities.c.transaction_id.in_([t.id for t in transactions])).order_by(
            identities.c.namespace, identities.c.external_id)).mappings():
        owners.setdefault(row["transaction_id"], []).append({"namespace": row["namespace"], "external_id": row["external_id"]})
    for transaction in transactions:
        data, source = as_dict(transaction), sources[transaction.source_id]
        amount = allocated.get(transaction.id, 0)
        data.update(currency=source.currency, reconciled_amount_cents=amount)
        count = evidence_counts.get(transaction.id, 0)
        data.update(active_evidence_count=count, evidence_status="ACTIVE" if count else "WITHDRAWN")
        data["external_identities"] = owners.get(transaction.id, [])
        data["unreconciled_amount_cents"] = abs(transaction.amount_cents) - amount if count and source.source_type == "BANK_ACCOUNT" else None
        data["reconciliation_status"] = (
            "INACTIVE" if not count else "NOT_APPLICABLE" if source.source_type != "BANK_ACCOUNT" else
            "RECONCILED" if amount == abs(transaction.amount_cents) else "PARTIAL" if amount else "UNRECONCILED"
        )
        result.append(data)
    return result


def create_reconciliation(db: Session, data: FinancialReconciliationCreate, actor_id):
    from app.services.financial_import_lifecycle import guard_transaction
    owner = guard_transaction(db, data.transaction_id, data)
    transaction = require(db, FinancialTransaction, data.transaction_id)
    if not active_evidence(db, transaction.id):
        fail("FINANCIAL_TRANSACTION_INACTIVE", "Esta operacao nao possui evidencia confirmada ativa.")
    source = require(db, FinancialSource, transaction.source_id)
    entry = require(db, CashFlowEntry, data.cash_flow_entry_id)
    if source.source_type != "BANK_ACCOUNT" or source.financial_account_id != entry.account_id or source.currency != "BRL":
        fail("FINANCIAL_RECONCILIATION_ACCOUNT_MISMATCH", "O movimento deve pertencer a mesma conta bancaria em BRL.")
    expected_direction = "CREDIT" if transaction.amount_cents > 0 else "DEBIT"
    if entry.entry_type != expected_direction:
        fail("FINANCIAL_RECONCILIATION_DIRECTION", "Entrada e saida nao podem ser conciliadas entre si.")
    if db.scalar(select(FinancialReconciliation.id).where(
        FinancialReconciliation.transaction_id == transaction.id,
        FinancialReconciliation.cash_flow_entry_id == entry.id, FinancialReconciliation.voided_at.is_(None),
    )):
        fail("FINANCIAL_RECONCILIATION_EXISTS", "Esta correspondencia ja esta ativa.")
    tx_remaining = abs(transaction.amount_cents) - _allocated(db, FinancialReconciliation.transaction_id, transaction.id)
    entry_remaining = entry.amount_cents - _allocated(db, FinancialReconciliation.cash_flow_entry_id, entry.id)
    if data.amount_cents > min(tx_remaining, entry_remaining):
        fail("FINANCIAL_RECONCILIATION_EXCEEDS_BALANCE", "Valor excede o saldo ainda nao conciliado.")
    reconciliation = FinancialReconciliation(id=str(uuid.uuid4()), created_by=actor_id,
        **data.model_dump(exclude={'import_id', 'expected_generation'}))
    db.add(reconciliation)
    db.flush()
    audit(db, actor_id, "RECONCILIATION_CREATED", reconciliation)
    from app.services.financial_import_lifecycle import record_ids
    record_ids(db, owner, 'reconciliation_ids', [reconciliation.id])
    return {"reconciliation": as_dict(reconciliation), "affects_ledger": False}


def void_reconciliation(db, reconciliation_id, reason, actor_id, command=None):
    reconciliation = require(db, FinancialReconciliation, reconciliation_id)
    from app.services.financial_import_lifecycle import guard_transaction
    guard_transaction(db, reconciliation.transaction_id, command)
    if reconciliation.voided_at is not None:
        fail("FINANCIAL_RECONCILIATION_ALREADY_VOID", "Esta conciliacao ja foi desfeita.")
    reconciliation.voided_at, reconciliation.voided_by, reconciliation.void_reason = utc_now(), actor_id, reason
    audit(db, actor_id, "RECONCILIATION_VOIDED", reconciliation, {"reason": reason})
    db.flush()
    return {"reconciliation": as_dict(reconciliation), "affects_ledger": False}


def post_statement_to_treasury(db: Session, statement_id: str, actor_id: str):
    """Compatibility route: validate existing reconciliation, never post blindly.

    Cash creation requires classification and matching contracts this old bulk
    endpoint did not provide. Keep the endpoint and history; fail closed for
    outstanding evidence and direct clients to the explicit reconciliation API.
    """
    statement = require(db, FinancialStatement, statement_id)
    if statement.statement_type != "BANK_STATEMENT":
        fail("FINANCIAL_BANK_STATEMENT_REQUIRED", "Apenas extratos de conta bancaria podem ser conciliados.")
    source = require(db, FinancialSource, statement.source_id)
    account = require(db, FinancialAccount, source.financial_account_id) if source.financial_account_id else None
    if account is None or not account.is_active:
        fail("FINANCIAL_ACCOUNT_INACTIVE", "Confira a conta bancaria vinculada.")
    view = effective_items()
    items = db.execute(select(view).where(view.c.statement_id == statement_id)).mappings().all()
    if not items:
        fail("FINANCIAL_STATEMENT_EMPTY", "Este extrato nao possui lancamentos.")
    for item in items:
        if item['review_status'] == 'IGNORED':
            continue
        amount = abs(item['normalized_data']['amount_cents'])
        if amount == 0:
            continue
        transaction_id = item['transaction_id']
        allocated = _allocated(db, FinancialReconciliation.transaction_id, transaction_id) if transaction_id else 0
        if allocated != amount:
            fail("FINANCIAL_CASH_REVIEW_REQUIRED", "Revise e concilie cada ocorrencia com movimentos existentes antes de concluir o extrato.")
    return {"statement_id": statement_id, "account_id": account.id,
            "account_name": account.name, "entries_posted": 0,
            "total_credits_cents": 0, "total_debits_cents": 0,
            "new_balance_cents": account.current_balance_cents}
