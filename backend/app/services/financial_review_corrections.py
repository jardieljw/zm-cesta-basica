"""Current review projections over immutable original evidence and corrections.

All decisions and identifier ownership changes are append-only. This module
never writes to cash, payable, receivable, payment or stock tables.
"""
import datetime
import uuid

from sqlalchemy import select, func, case, and_, union_all

from app.models.financial_imports import (
    FinancialStatementItem, FinancialStatement, FinancialTransaction,
    FinancialTransactionIdentity, FinancialReviewCorrection, FinancialIdentityChange,
    FinancialReconciliation, FinancialImportAudit,
)
from app.schemas.financial_imports import FinancialTransactionData


def effective_items():
    """SQL projection shared by lists, evidence, ownership checks and counts."""
    item = FinancialStatementItem.__table__
    correction = FinancialReviewCorrection.__table__
    latest = select(correction.c.item_id, func.max(correction.c.revision).label("revision")).group_by(correction.c.item_id).subquery()
    last = select(correction).join(latest, and_(
        correction.c.item_id == latest.c.item_id, correction.c.revision == latest.c.revision,
    )).subquery()
    overrides = {"review_status": last.c.review_status, "transaction_id": last.c.transaction_id,
                 "reviewed_by": last.c.created_by, "reviewed_at": last.c.created_at}
    columns = [case((last.c.id.is_not(None), overrides[c.name]), else_=c).label(c.name)
               if c.name in overrides else c for c in item.c]
    return select(*columns, func.coalesce(last.c.revision, 0).label("review_revision"),
                  item.c.review_status.label("original_review_status"), item.c.transaction_id.label("original_transaction_id")
                  ).select_from(item.outerjoin(last, last.c.item_id == item.c.id)).subquery("effective_financial_items")


def current_item(db, item_id):
    from app.services import financial_imports as service
    view = effective_items()
    row = db.execute(select(view).where(view.c.id == item_id)).mappings().first()
    if row is None:
        service.fail("FINANCIAL_RESOURCE_NOT_FOUND", "Registro financeiro nao encontrado.", 404)
    return dict(row)


def active_evidence(db, transaction_id):
    view = effective_items()
    return db.scalar(select(func.count()).select_from(view).where(view.c.transaction_id == transaction_id))


def identity_owner(db, source_id, namespace, external_id):
    change = db.scalar(select(FinancialIdentityChange).where(
        FinancialIdentityChange.source_id == source_id, FinancialIdentityChange.namespace == namespace,
        FinancialIdentityChange.external_id == external_id,
    ).order_by(FinancialIdentityChange.revision.desc()).limit(1))
    if change is not None:
        return change.transaction_id
    return db.scalar(select(FinancialTransactionIdentity.transaction_id).where(
        FinancialTransactionIdentity.source_id == source_id, FinancialTransactionIdentity.namespace == namespace,
        FinancialTransactionIdentity.external_id == external_id,
    ))


def effective_identities():
    alias = FinancialTransactionIdentity.__table__
    change = FinancialIdentityChange.__table__
    keys = (change.c.source_id, change.c.namespace, change.c.external_id)
    latest = select(*keys, func.max(change.c.revision).label("revision")).group_by(*keys).subquery()
    last = select(change).join(latest, and_(
        change.c.source_id == latest.c.source_id, change.c.namespace == latest.c.namespace,
        change.c.external_id == latest.c.external_id, change.c.revision == latest.c.revision,
    )).subquery()
    matching = and_(alias.c.source_id == last.c.source_id, alias.c.namespace == last.c.namespace, alias.c.external_id == last.c.external_id)
    original = select(alias.c.source_id, alias.c.namespace, alias.c.external_id,
        case((last.c.id.is_not(None), last.c.transaction_id), else_=alias.c.transaction_id).label("transaction_id")
    ).select_from(alias.outerjoin(last, matching))
    # Also support ownership entries without an original alias, e.g. a future
    # provider that writes the same versioned identity contract directly.
    added = select(last.c.source_id, last.c.namespace, last.c.external_id, last.c.transaction_id).where(
        ~select(alias.c.id).where(matching).exists())
    return union_all(original, added).subquery("effective_financial_identities")


def identity_support(db, source_id, data, *, exclude_item_id):
    view = effective_items()
    return set(db.scalars(select(view.c.transaction_id).join(
        FinancialStatement, FinancialStatement.id == view.c.statement_id,
    ).where(FinancialStatement.source_id == source_id, view.c.transaction_id.is_not(None), view.c.id != exclude_item_id,
            view.c.normalized_data["external_id_namespace"].as_string() == data.external_id_namespace,
            view.c.normalized_data["external_id"].as_string() == data.external_id)).all())


def assign_identity(db, source_id, data, transaction_id, actor_id, reason, *, correction_id=None, transfer=False):
    from app.services import financial_imports as service
    if data.external_id is None:
        return
    owner = identity_owner(db, source_id, data.external_id_namespace, data.external_id)
    if owner == transaction_id:
        return
    if owner is not None and not transfer:
        service.fail("FINANCIAL_EXTERNAL_ID_CONFLICT", "Identificador externo ja pertence a outra transacao.")
    alias = db.scalar(select(FinancialTransactionIdentity).where(
        FinancialTransactionIdentity.source_id == source_id, FinancialTransactionIdentity.namespace == data.external_id_namespace,
        FinancialTransactionIdentity.external_id == data.external_id,
    ))
    # The original alias is permanent historical evidence. A released or moved
    # identity receives a new ownership entry instead of UPDATE/DELETE.
    previous_change = db.scalar(select(FinancialIdentityChange.revision).where(
        FinancialIdentityChange.source_id == source_id, FinancialIdentityChange.namespace == data.external_id_namespace,
        FinancialIdentityChange.external_id == data.external_id,
    ).order_by(FinancialIdentityChange.revision.desc()).limit(1))
    if alias is None and previous_change is None and transaction_id is not None:
        db.add(FinancialTransactionIdentity(id=str(uuid.uuid4()), transaction_id=transaction_id, source_id=source_id,
            namespace=data.external_id_namespace, external_id=data.external_id))
        db.flush()
        return
    change = FinancialIdentityChange(
        id=str(uuid.uuid4()), source_id=source_id, namespace=data.external_id_namespace, external_id=data.external_id,
        revision=(previous_change or 0) + 1, previous_transaction_id=owner, transaction_id=transaction_id,
        correction_id=correction_id, created_by=actor_id, reason=reason,
    )
    db.add(change)
    db.flush()
    service.audit(db, actor_id, "IDENTITY_OWNERSHIP_CHANGED", change, {
        "previous_transaction_id": owner, "transaction_id": transaction_id, "correction_id": correction_id,
    })


def canonical_for_new(db, source_id, data, actor_id):
    """Reactivate compatible historical ID facts; never rewrite a canonical row."""
    from app.services import financial_imports as service
    if data.external_id:
        historical = db.scalar(select(FinancialTransaction).where(
            FinancialTransaction.source_id == source_id,
            FinancialTransaction.external_id_namespace == data.external_id_namespace,
            FinancialTransaction.external_id == data.external_id,
        ))
        if historical is not None:
            service._compatible(historical, source_id, data)
            return historical
    values = data.model_dump()
    raw_time = values.pop("transaction_time")
    transaction = FinancialTransaction(
        id=str(uuid.uuid4()), source_id=source_id, created_by=actor_id,
        transaction_time=datetime.time.fromisoformat(raw_time) if raw_time else None,
        time_precision=("MINUTE" if len(raw_time) == 5 else "SECOND") if raw_time else None, **values,
    )
    db.add(transaction)
    db.flush()
    return transaction


def assert_identity_compatible(db, source_id, data, transaction_id, *, exclude_item_id):
    """Different reliable IDs in one namespace cannot be collapsed into one event."""
    from app.services import financial_imports as service
    if data.external_id is None:
        return
    view = effective_items()
    conflicting = db.scalar(select(view.c.id).join(FinancialStatement, FinancialStatement.id == view.c.statement_id).where(
        FinancialStatement.source_id == source_id, view.c.transaction_id == transaction_id, view.c.id != exclude_item_id,
        view.c.normalized_data["external_id_namespace"].as_string() == data.external_id_namespace,
        view.c.normalized_data["external_id"].as_string().is_not(None),
        view.c.normalized_data["external_id"].as_string() != data.external_id,
    ).limit(1))
    if conflicting:
        service.fail("FINANCIAL_EXTERNAL_ID_CONFLICT", "Identificadores distintos representam operacoes distintas.")


def correct_review(db, item_id, request, actor_id):
    from app.services import financial_imports as service
    item = current_item(db, item_id)
    if item["review_status"] == "PENDING":
        service.fail("FINANCIAL_REVIEW_NOT_COMPLETED", "Conclua a primeira conferencia antes de corrigi-la.")
    if item["review_revision"] != request.expected_revision:
        service.fail("FINANCIAL_REVIEW_CHANGED", "Esta conferencia foi alterada. Atualize os dados antes de corrigir.")
    statement = service.require(db, FinancialStatement, item["statement_id"])
    data = FinancialTransactionData.model_validate(item["normalized_data"])
    previous_id = item["transaction_id"]
    owner = identity_owner(db, statement.source_id, data.external_id_namespace, data.external_id) if data.external_id else None
    target = None
    status = "IGNORED"
    if request.action == "LINK":
        target = service.require(db, FinancialTransaction, request.transaction_id)
        if not active_evidence(db, target.id):
            service.fail("FINANCIAL_TRANSACTION_INACTIVE", "Escolha uma operacao com evidencia confirmada ativa.")
        status = "LINKED"
    elif request.action == "NEW":
        if item["review_status"] == "NEW":
            service.fail("FINANCIAL_CORRECTION_NO_CHANGE", "A ocorrencia ja representa uma operacao separada.")
        if owner is not None and active_evidence(db, owner):
            # A split cannot manufacture another event bearing the same bank ID.
            # Transferring an alias added by a mistaken LINK is allowed only
            # when no other evidence claims that ID and it is not the original
            # canonical identity of the event being split.
            owner_tx = service.require(db, FinancialTransaction, owner)
            if (owner != previous_id or identity_support(db, statement.source_id, data, exclude_item_id=item_id)
                    or (owner_tx.external_id_namespace == data.external_id_namespace and owner_tx.external_id == data.external_id)):
                service.fail("FINANCIAL_IDENTITY_STILL_SUPPORTED", "O mesmo identificador bancario esta confirmado em outra evidencia; nao pode representar duas operacoes.")
        target = canonical_for_new(db, statement.source_id, data, actor_id)
        status = "NEW"
    target_id = target.id if target else None
    if target_id == previous_id and ((target_id is not None) or item["review_status"] == "IGNORED"):
        service.fail("FINANCIAL_CORRECTION_NO_CHANGE", "A correcao nao altera a associacao atual.")
    involved = {value for value in (previous_id, target_id) if value is not None}
    if involved and db.scalar(select(FinancialReconciliation.id).where(
        FinancialReconciliation.transaction_id.in_(involved), FinancialReconciliation.voided_at.is_(None),
    ).limit(1)):
        service.fail("FINANCIAL_CORRECTION_REQUIRES_UNRECONCILE", "Desfaca explicitamente as conciliacoes ativas das operacoes envolvidas antes de corrigir.")
    if target is not None:
        service._compatible(target, statement.source_id, data)
        assert_identity_compatible(db, statement.source_id, data, target.id, exclude_item_id=item_id)
    support = identity_support(db, statement.source_id, data, exclude_item_id=item_id) if data.external_id else set()
    if target is not None and (support - {target.id} or owner not in {None, previous_id, target.id}):
        service.fail("FINANCIAL_IDENTITY_STILL_SUPPORTED", "O identificador bancario possui outra evidencia confirmada; revise esses vinculos antes de transferi-lo.")
    correction = FinancialReviewCorrection(
        id=str(uuid.uuid4()), item_id=item_id, revision=item["review_revision"] + 1, review_status=status,
        transaction_id=target_id, reason=request.reason, created_by=actor_id,
    )
    db.add(correction)
    db.flush()
    if data.external_id:
        if target is not None:
            assign_identity(db, statement.source_id, data, target.id, actor_id, request.reason, correction_id=correction.id, transfer=True)
        elif owner == previous_id and not support:
            assign_identity(db, statement.source_id, data, None, actor_id, request.reason, correction_id=correction.id, transfer=True)
    service.audit(db, actor_id, "ITEM_REVIEW_CORRECTED", correction, {
        "item_id": item_id, "previous_revision": item["review_revision"], "previous_status": item["review_status"],
        "previous_transaction_id": previous_id, "review_status": status, "transaction_id": target_id, "reason": request.reason,
    })
    # Also index the event under the item for its existing audit endpoint.
    original = service.require(db, FinancialStatementItem, item_id)
    service.audit(db, actor_id, "ITEM_CORRECTION_RECORDED", original, {"correction_id": correction.id, "revision": correction.revision})
    db.flush()
    return {"item": current_item(db, item_id), "correction": service.as_dict(correction),
            "transaction": service.as_dict(target) if target else None, "affects_ledger": False}


def review_history(db, item_id, limit, offset):
    from app.services import financial_imports as service
    original = service.require(db, FinancialStatementItem, item_id)
    rows = []
    if offset == 0:
        if original.review_status == "PENDING":
            return []
        event = db.scalar(select(FinancialImportAudit).where(
            FinancialImportAudit.entity_id == item_id,
            FinancialImportAudit.event_type == "ITEM_" + original.review_status,
        ).order_by(FinancialImportAudit.created_at, FinancialImportAudit.id).limit(1))
        rows.append({"revision": 0, "review_status": original.review_status, "transaction_id": original.transaction_id,
                     "created_by": original.reviewed_by, "created_at": original.reviewed_at,
                     "reason": event.details.get("reason") if event else None})
    corrections = db.scalars(select(FinancialReviewCorrection).where(FinancialReviewCorrection.item_id == item_id).order_by(
        FinancialReviewCorrection.revision).limit(limit - len(rows)).offset(max(0, offset - 1))).all()
    return rows + [service.as_dict(c) for c in corrections]
