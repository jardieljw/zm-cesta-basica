"""Protected backend-only foundation for bank/card evidence.

All writes require idempotency. File readers only stage evidence, never payments.
"""
import hashlib
from urllib.parse import quote

from fastapi import APIRouter, Depends, Header, Query, Request, Response, HTTPException
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.routing import APIRoute
from sqlalchemy import select, inspect, func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.idempotency import process_transactional_idempotency
from app.core.security import hash_token
from app.models.auth import PairedDevice
from app.models.financial_imports import (
    FinancialSource, FinancialDocument, FinancialStatement, FinancialStatementItem,
    FinancialTransaction, FinancialReconciliation, FinancialImportAudit,
    FinancialImportPreview,
    FinancialImportEntry,
    FINANCIAL_IMPORT_TABLE_NAMES,
)
from app.models.financial import FinancialAccount
from app.schemas.financial_imports import (
    FinancialSourceCreate, FinancialSourceResponse, FinancialDocumentResponse,
    FinancialStatementCreate, FinancialItemReview, FinancialReconciliationCreate,
    FinancialReconciliationVoid,
    FinancialReviewCorrectionCreate,
    FinancialImportContext,
)
from app.services import financial_imports as service
from app.services import financial_previews as previews
from app.services import financial_import_lifecycle as lifecycle
from app.services import financial_review_corrections as corrections
from app.services.financial_readers import READERS
from app.schemas.financial_readers import FinancialPreviewCreate, FinancialPreviewConfirm, FinancialSegmentSelect
from app.schemas.financial_bill_assessments import BillAssessmentCreate
from app.models.financial_bill_assessments import FinancialBillAssessment, FinancialBillAssessmentLink
from app.services import financial_bill_assessments as bills
from app.schemas.financial_bill_semantics import BillSemanticReviewCreate, BillGenerateObligationsRequest
from app.services import financial_bill_semantics as semantics


class FinancialRoute(APIRoute):
    def get_route_handler(self):
        original = super().get_route_handler()

        async def handler(request):
            try:
                response = await original(request)
            except RequestValidationError as error:
                # Standard errors echo input values, which may contain bank data.
                response = JSONResponse(status_code=422, content={"detail": {
                    "error_code": "INVALID_FINANCIAL_DATA",
                    "message": "Dados financeiros invalidos. Confira os campos informados.",
                    "fields": [{"loc": e["loc"], "type": e["type"]} for e in error.errors()],
                }})
            response.headers["Cache-Control"] = "no-store"
            response.headers["X-Content-Type-Options"] = "nosniff"
            return response

        return handler


router = APIRouter(prefix="/financial-imports", route_class=FinancialRoute)


def financial_actor(authorization: str | None = Header(None), db: Session = Depends(get_db)):
    # Explicit token verification: never accept the legacy master-device fallback.
    parts = authorization.split() if authorization and len(authorization) <= 4096 else []
    if len(parts) != 2 or parts[0].lower() != "bearer":
        service.fail("FINANCIAL_AUTH_REQUIRED", "Autenticacao valida de dispositivo necessaria.", 401)
    device = db.scalar(select(PairedDevice).where(
        PairedDevice.token_hash == hash_token(parts[1]), PairedDevice.is_active.is_(True),
    ))
    if device is None:
        service.fail("FINANCIAL_AUTH_REQUIRED", "Autenticacao valida de dispositivo necessaria.", 401)
    actor_id = device.id
    # Authentication must not hold SQLite's write transaction while a file streams.
    db.rollback()
    schema = inspect(db.get_bind())
    installed_tables = set(schema.get_table_names())
    if (not FINANCIAL_IMPORT_TABLE_NAMES.issubset(installed_tables)
            or not {"purchase_date", "booking_date"}.issubset({c["name"] for c in schema.get_columns("financial_transactions")})
            or "preview_id" not in {c["name"] for c in schema.get_columns("financial_statements")}
            or "superseded_by_id" not in {c["name"] for c in schema.get_columns("accounts_payable")}
            or not {"bill_revision_id", "stock_cents", "business_cents", "personal_cents", "unclassified_cents"}.issubset(
                {c["name"] for c in schema.get_columns("payable_payments")})):
        service.fail("FINANCIAL_SCHEMA_NOT_READY", "Base financeira aguardando migracao versionada do servidor.", 503)
    return actor_id


def required_key(key: str | None = Header(None, alias="X-Idempotency-Key")):
    if not key or not key.strip() or len(key) > 120:
        service.fail("FINANCIAL_IDEMPOTENCY_REQUIRED", "Informar X-Idempotency-Key com ate 120 caracteres.", 400)
    return key.strip()


def mutate(db, key, operation, payload, callback, status=201):
    _guard_import_command(db, operation, payload)
    def execute(session):
        result = callback(session)
        is_dup = result.get("duplicate") if isinstance(result, dict) else False
        return (200 if is_dup else status), jsonable_encoder(result)
    result = process_transactional_idempotency(db, key, operation, payload, execute)
    return JSONResponse(status_code=result.status_code, content=result.to_json_dict())


def _guard_import_command(db, operation, payload):
    """Also validate successful replays against the currently active generation."""
    from types import SimpleNamespace
    command = SimpleNamespace(**payload)
    if operation in {'FIN_SEGMENT_SELECT_V1', 'FIN_BILL_CYCLE_INTEGRATE_V1', 'FIN_IMPORT_CONFIRM', 'FIN_BILL_ASSESS'}:
        lifecycle.require_preview(db, payload['preview_id'], payload.get('import_id'), payload.get('expected_generation'))
    elif operation in {'FIN_ITEM_REVIEW', 'FIN_REVIEW_CORRECT'}:
        lifecycle.guard_item(db, payload['item_id'], command)
    elif operation in {'FIN_BILL_SEMANTIC_REVIEW', 'FIN_BILL_GENERATE_OBLIGATIONS', 'FIN_STATEMENT_POST_TREASURY'}:
        lifecycle.guard_statement(db, payload['statement_id'], command)
    elif operation == 'FIN_RECONCILE':
        lifecycle.guard_transaction(db, payload['transaction_id'], command)
    elif operation == 'FIN_RECONCILE_VOID':
        reconciliation = service.require(db, FinancialReconciliation, payload['reconciliation_id'])
        lifecycle.guard_transaction(db, reconciliation.transaction_id, command)
    elif operation == 'FIN_INSTALLMENT_DECISION_V1':
        from app.services.financial_installments import guard_decision
        guard_decision(db, command)


@router.post("/sources", response_model=FinancialSourceResponse, status_code=201)
def create_source(data: FinancialSourceCreate, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_SOURCE_CREATE", data.model_dump(mode="json"),
                  lambda session: service.create_source(session, data, actor))


@router.get("/sources", response_model=list[FinancialSourceResponse])
def list_sources(actor=Depends(financial_actor), db: Session = Depends(get_db),
                 limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    sources = db.scalars(select(FinancialSource).order_by(FinancialSource.created_at, FinancialSource.id).limit(limit).offset(offset)).all()
    account_ids = [s.financial_account_id for s in sources if s.financial_account_id]
    account_map = {}
    if account_ids:
        accounts = db.scalars(select(FinancialAccount).where(FinancialAccount.id.in_(account_ids))).all()
        account_map = {a.id: a.current_balance_cents for a in accounts}
    result = []
    for s in sources:
        item = FinancialSourceResponse.model_validate(s)
        if s.financial_account_id in account_map:
            item.current_balance_cents = account_map[s.financial_account_id]
        result.append(item)
    return result


@router.post("/documents")
async def store_document(request: Request, filename: str = Query(min_length=1, max_length=200),
                         actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    if not filename.strip() or any(ord(c) < 32 for c in filename) or "/" in filename or "\\" in filename or filename in (".", ".."):
        service.fail("FINANCIAL_DOCUMENT_NAME", "Informar apenas o nome do arquivo.", 422)
    media_type = request.headers.get("content-type", "").split(";", 1)[0].strip().lower()
    if media_type not in service.MEDIA_TYPES:
        service.fail("FINANCIAL_DOCUMENT_TYPE", "Tipo de documento nao suportado.", 415)
    chunks, size = [], 0
    async for chunk in request.stream():
        size += len(chunk)
        if size > service.MAX_DOCUMENT_BYTES:
            service.fail("FINANCIAL_DOCUMENT_SIZE", "Documento acima de 10 MiB.", 413)
        chunks.append(chunk)
    content = b"".join(chunks)
    payload = {"filename": filename, "media_type": media_type, "sha256": hashlib.sha256(content).hexdigest()}
    return mutate(db, key, "FIN_DOCUMENT_STORE", payload,
                  lambda session: service.store_document(session, content, filename, media_type, actor))


@router.get("/documents/{document_id}/import-state")
def document_import_state(document_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return lifecycle.state(db, document_id)


@router.get("/documents/{document_id}", response_model=FinancialDocumentResponse)
def get_document(document_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return service.require(db, FinancialDocument, document_id)


@router.get("/documents/{document_id}/content")
def document_content(document_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    document = service.require(db, FinancialDocument, document_id)
    service.audit(db, actor, "DOCUMENT_ACCESSED", document)
    content = document.content
    db.commit()
    return Response(content=content, media_type="application/octet-stream", headers={
        "Content-Disposition": "attachment; filename=document; filename*=UTF-8''" + quote(document.filename, safe=""),
        "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff",
    })


@router.post("/statements")
def create_statement(data: FinancialStatementCreate, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_STATEMENT_STAGE", data.model_dump(mode="json"),
                  lambda session: service.create_statement(session, data, actor))


@router.get("/readers")
def list_readers(actor=Depends(financial_actor)):
    return [{"id": r.id, "version": r.version, "media_type": r.media_type,
             "requires_mapping": r.id == "generic_csv",
             "source_types": ["BANK_ACCOUNT", "CREDIT_CARD"] if r.options is None else
                 ["BANK_ACCOUNT"] if r.options.amount_convention == "CREDITS_POSITIVE" else ["CREDIT_CARD"]}
            for r in READERS.values()]


@router.get('/capabilities')
def financial_capabilities(actor=Depends(financial_actor)):
    return {'bill_cycle_version': 1, 'bill_review_version': 2, 'segments_version': 1,
        'payable_filter_version': 1, 'installment_agenda_version': 1,
        'import_removal_version': 1, 'import_lifecycle_version': 1,
        'bill_requirements_version': 0}  # Versioned financial requirements are delivered in step 2.


@router.get('/installments')
def get_installment_agenda(source_id: str | None = Query(None, max_length=36), source_query: str | None = Query(None, max_length=200),
        merchant: str | None = Query(None, max_length=200), due_date_from: str | None = None, due_date_to: str | None = None,
        month: int | None = Query(None, ge=1, le=12), year: int | None = Query(None, ge=1, le=9999),
        status: str | None = None, category: str | None = None, beneficiary: str | None = None, nature: str | None = None,
        overdue_only: bool = False, limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0),
        actor=Depends(financial_actor), db: Session = Depends(get_db)):
    import datetime
    from app.services.financial_installments import agenda
    try:
        start = datetime.datetime.fromisoformat(due_date_from) if due_date_from else None
        end = datetime.datetime.fromisoformat(due_date_to) if due_date_to else None
    except ValueError:
        service.fail('INVALID_FINANCIAL_DATA', 'Confira o intervalo da agenda.', 422)
    return agenda(db, source_id=source_id, source_query=source_query, merchant=merchant, due_date_from=start,
        due_date_to=end, month=month, year=year, status=status, category=category, beneficiary=beneficiary,
        nature=nature, overdue_only=overdue_only, limit=limit, offset=offset)


from app.schemas.financial_installments import InstallmentResolve


@router.post('/installments/decisions')
def resolve_installment(data: InstallmentResolve, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    from app.services.financial_installments import decide
    return mutate(db, key, 'FIN_INSTALLMENT_DECISION_V1', data.model_dump(mode='json'), lambda session: decide(session, data, actor))


@router.post('/previews/{preview_id}/select-segment')
def select_segment(preview_id: str, data: FinancialSegmentSelect, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, 'FIN_SEGMENT_SELECT_V1', {'preview_id': preview_id, **data.model_dump(mode='json')},
        lambda session: previews.select_segment(session, preview_id, data, actor))


@router.get('/previews/{preview_id}/bill-integration')
def bill_integration_draft(preview_id: str, reference: str | None = Query(None, pattern=r'^\d{4}-(0[1-9]|1[0-2])$'),
                           import_id: str | None = Query(None), expected_generation: int | None = Query(None, ge=1),
                           actor=Depends(financial_actor), db: Session = Depends(get_db)):
    from app.services.financial_bill_cycles import draft
    entry, _ = lifecycle.require_preview(db, preview_id, import_id, expected_generation)
    return {**draft(db, preview_id, reference), 'import_id': entry.id,
            'generation': entry.generation}


from app.schemas.financial_bill_cycles import BillCycleIntegrate


@router.post('/previews/{preview_id}/integrate-bill')
def integrate_bill(preview_id: str, data: BillCycleIntegrate, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    from app.services.financial_bill_cycles import integrate
    return mutate(db, key, 'FIN_BILL_CYCLE_INTEGRATE_V1', {'preview_id': preview_id, **data.model_dump(mode='json')},
        lambda session: integrate(session, preview_id, data, actor))


@router.get('/bill-cycles/{cycle_id}')
def get_bill_cycle(cycle_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    from app.services.financial_bill_cycles import describe, current, Cycle
    from app.services.financial_import_removals import withdrawn_cycles
    cycle = service.require(db, Cycle, cycle_id)
    if cycle.id in withdrawn_cycles(db) or lifecycle.entry_for_preview(db, current(db, cycle).preview_id) is None:
        service.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY', 'Abra a importação atual pela lista.')
    return describe(db, cycle)


@router.post("/documents/{document_id}/previews")
def create_preview(document_id: str, data: FinancialPreviewCreate, actor=Depends(financial_actor),
                   key=Depends(required_key), db: Session = Depends(get_db)):
    prepared = previews.prepare_pdf_preview(db, document_id, data)
    payload = data.model_dump(mode="json", exclude={'expected_reader_version'} if data.expected_reader_version is None else set())
    return mutate(db, key, "FIN_IMPORT_PREVIEW", {"document_id": document_id, **payload},
                  lambda session: previews.create_preview(session, document_id, data, actor, prepared))


@router.get("/previews/{preview_id}")
def get_preview(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    preview = service.require(db, FinancialImportPreview, preview_id)
    entry = lifecycle.entry_for_preview(db, preview_id)
    if entry is None:
        service.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY',
            'Esta leitura pertence ao histórico. Abra a importação atual pela lista.')
    return lifecycle.preview_summary(db, entry, preview)


@router.get("/previews")
def list_previews(response: Response, document_id: str | None = None, source_id: str | None = None,
                  actor=Depends(financial_actor), db: Session = Depends(get_db),
                  limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    query = select(FinancialImportEntry, FinancialImportPreview).join(
        FinancialImportPreview, FinancialImportPreview.id == FinancialImportEntry.root_preview_id).where(
            FinancialImportEntry.state == 'ACTIVE')
    if document_id:
        query = query.where(FinancialImportEntry.document_id == document_id)
    if source_id:
        query = query.where(FinancialImportPreview.source_id == source_id)
    response.headers['X-Total-Count'] = str(db.scalar(select(func.count()).select_from(query.subquery())))
    page = db.execute(query.order_by(FinancialImportEntry.created_at,
                                     FinancialImportEntry.id).limit(limit).offset(offset)).all()
    return [lifecycle.preview_summary(db, entry, preview) for entry, preview in page]


@router.get("/previews/{preview_id}/items")
def preview_items(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                  limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    if lifecycle.entry_for_preview(db, preview_id) is None:
        service.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY', 'Abra a importação atual pela lista.')
    return previews.preview_items(db, service.require(db, FinancialImportPreview, preview_id), offset, limit)


@router.get("/previews/{preview_id}/errors")
def preview_errors(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                   limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    if lifecycle.entry_for_preview(db, preview_id) is None:
        service.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY', 'Abra a importação atual pela lista.')
    return service.require(db, FinancialImportPreview, preview_id).result["errors"][offset:offset + limit]


@router.get("/previews/{preview_id}/pages")
def preview_pages(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                  limit: int = Query(5, ge=1, le=40), offset: int = Query(0, ge=0)):
    if lifecycle.entry_for_preview(db, preview_id) is None:
        service.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY', 'Abra a importação atual pela lista.')
    return service.require(db, FinancialImportPreview, preview_id).result.get("pages", [])[offset:offset + limit]


@router.post("/previews/{preview_id}/bill-assessments")
def assess_bill(preview_id: str, data: BillAssessmentCreate, actor=Depends(financial_actor),
                key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_BILL_ASSESS", {"preview_id": preview_id, **data.model_dump(mode="json")},
                  lambda session: bills.create(session, preview_id, data, actor))


@router.get("/previews/{preview_id}/bill-assessments")
def assessment_history(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                       limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    get_preview(preview_id, actor, db)
    return [bills.summary(a) for a in db.scalars(select(FinancialBillAssessment).where(
        FinancialBillAssessment.preview_id == preview_id).order_by(FinancialBillAssessment.revision).limit(limit).offset(offset))]


@router.get("/previews/{preview_id}/bill-assessment")
def current_assessment(preview_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    get_preview(preview_id, actor, db)
    preview = service.require(db, FinancialImportPreview, preview_id)
    assessment = bills.latest(db, preview_id)
    if assessment is None:
        return {"preview_id": preview_id, "revision": 0, "status": "NOT_ASSESSED", "reading_status": preview.status,
                "can_generate_obligations": False, "affects_ledger": False}
    return bills.summary(assessment)


@router.get("/bill-assessments/{assessment_id}/evidence")
def assessment_evidence(assessment_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                        limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    assessment = service.require(db, FinancialBillAssessment, assessment_id)
    get_preview(assessment.preview_id, actor, db)
    return bills.evidence_rows(db, assessment_id, limit, offset)


@router.get("/statements/{statement_id}/bill-assessments")
def confirmed_assessments(statement_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                          limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    service.require(db, FinancialStatement, statement_id)
    return [{**bills.summary(a), "is_current": bills.latest(db, a.preview_id).id == a.id} for a in db.scalars(select(FinancialBillAssessment).join(
        FinancialBillAssessmentLink, FinancialBillAssessmentLink.assessment_id == FinancialBillAssessment.id).where(
        FinancialBillAssessmentLink.statement_id == statement_id).order_by(FinancialBillAssessment.revision).limit(limit).offset(offset))]


@router.post("/previews/{preview_id}/confirm")
def confirm_preview(preview_id: str, data: FinancialPreviewConfirm, actor=Depends(financial_actor),
                    key=Depends(required_key), db: Session = Depends(get_db)):
    # Preserve hashes for requests made before optional assessments existed.
    payload = data.model_dump(mode="json", exclude={"assessment_id"} if data.assessment_id is None else set())
    return mutate(db, key, "FIN_IMPORT_CONFIRM", {"preview_id": preview_id, **payload},
                  lambda session: previews.confirm_preview(session, preview_id, data, actor))


@router.get("/statements")
def list_statements(source_id: str | None = None, actor=Depends(financial_actor), db: Session = Depends(get_db),
                    limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    query = select(FinancialStatement).where(FinancialStatement.id.in_(lifecycle.active_statement_ids()))
    if source_id:
        query = query.where(FinancialStatement.source_id == source_id)
    return [service.statement_summary(db, s) for s in db.scalars(query.order_by(
        FinancialStatement.created_at, FinancialStatement.id).limit(limit).offset(offset))]


@router.get("/statements/{statement_id}")
def get_statement(statement_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return service.statement_summary(db, service.require(db, FinancialStatement, statement_id))


@router.get("/statements/{statement_id}/items")
def list_items(statement_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
               limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    service.require(db, FinancialStatement, statement_id)
    view = corrections.effective_items()
    context = lifecycle.statement_context(db, statement_id)
    return [{**dict(row), **context} for row in db.execute(select(view).where(
        view.c.statement_id == statement_id).order_by(view.c.position).limit(limit).offset(offset)).mappings()]


@router.get("/items/{item_id}/candidates")
def candidates(item_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return service.candidate_transactions(db, item_id)


@router.post("/items/{item_id}/review")
def review_item(item_id: str, data: FinancialItemReview, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_ITEM_REVIEW", {"item_id": item_id, **data.model_dump(mode="json")},
                  lambda session: service.review_item(session, item_id, data, actor), status=200)


@router.get("/items/{item_id}")
def get_item(item_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return corrections.current_item(db, item_id)


@router.get("/items/{item_id}/review-history")
def item_review_history(item_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db),
                        limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    return corrections.review_history(db, item_id, limit, offset)


@router.post("/items/{item_id}/corrections")
def correct_item(item_id: str, data: FinancialReviewCorrectionCreate, actor=Depends(financial_actor),
                 key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_REVIEW_CORRECT", {"item_id": item_id, **data.model_dump(mode="json")},
                  lambda session: corrections.correct_review(session, item_id, data, actor), status=200)


@router.get("/transactions")
def list_transactions(source_id: str | None = None, include_inactive: bool = False, actor=Depends(financial_actor), db: Session = Depends(get_db),
                      limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    query = select(FinancialTransaction)
    if source_id:
        query = query.where(FinancialTransaction.source_id == source_id)
    if not include_inactive:
        view = corrections.effective_items()
        query = query.where(FinancialTransaction.id.in_(select(view.c.transaction_id).where(view.c.transaction_id.is_not(None))))
    transactions = db.scalars(query.order_by(
        FinancialTransaction.transaction_date, FinancialTransaction.id).limit(limit).offset(offset)).all()
    return service.transaction_summaries(db, transactions)


@router.get("/transactions/{transaction_id}/evidence")
def transaction_evidence(transaction_id: str, include_history: bool = False, actor=Depends(financial_actor), db: Session = Depends(get_db),
                         limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    service.require(db, FinancialTransaction, transaction_id)
    view = corrections.effective_items()
    condition = view.c.transaction_id == transaction_id
    if include_history:
        from app.models.financial_imports import FinancialReviewCorrection
        condition = condition | (view.c.original_transaction_id == transaction_id) | view.c.id.in_(select(
            FinancialReviewCorrection.item_id).where(FinancialReviewCorrection.transaction_id == transaction_id))
    return [dict(row) for row in db.execute(select(view).where(condition).order_by(view.c.id).limit(limit).offset(offset)).mappings()]


@router.post("/reconciliations")
def reconcile(data: FinancialReconciliationCreate, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_RECONCILE", data.model_dump(mode="json"),
                  lambda session: service.create_reconciliation(session, data, actor))


@router.get("/reconciliations")
def reconciliations(transaction_id: str | None = None, actor=Depends(financial_actor), db: Session = Depends(get_db),
                    limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    query = select(FinancialReconciliation)
    if transaction_id:
        query = query.where(FinancialReconciliation.transaction_id == transaction_id)
    return [service.as_dict(r) for r in db.scalars(query.order_by(
        FinancialReconciliation.created_at, FinancialReconciliation.id).limit(limit).offset(offset))]


@router.post("/reconciliations/{reconciliation_id}/void")
def void(reconciliation_id: str, data: FinancialReconciliationVoid, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    return mutate(db, key, "FIN_RECONCILE_VOID", {"reconciliation_id": reconciliation_id, **data.model_dump(mode="json")},
                  lambda session: service.void_reconciliation(session, reconciliation_id, data.reason, actor, data), status=200)


@router.get("/audit")
def audit_history(entity_id: str = Query(min_length=1, max_length=36), actor=Depends(financial_actor), db: Session = Depends(get_db),
                  limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0)):
    return [service.as_dict(e) for e in db.scalars(select(FinancialImportAudit).where(
        FinancialImportAudit.entity_id == entity_id).order_by(FinancialImportAudit.created_at, FinancialImportAudit.id).limit(limit).offset(offset))]


@router.post("/statements/{statement_id}/semantic-reviews")
def create_semantic_review(
    statement_id: str, data: BillSemanticReviewCreate, actor=Depends(financial_actor),
    key=Depends(required_key), db: Session = Depends(get_db),
):
    return mutate(db, key, "FIN_BILL_SEMANTIC_REVIEW", {"statement_id": statement_id, **data.model_dump(mode="json")},
                  lambda session: semantics.create_semantic_review(session, statement_id, data, actor))


@router.get("/statements/{statement_id}/semantic-reviews/current")
def get_current_semantic_review(statement_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    result = semantics.get_current_semantic_review(db, statement_id)
    if result is None:
        raise HTTPException(404, detail={"error_code": "FINANCIAL_REVIEW_NOT_FOUND", "message": "Nenhuma revisao semantica encontrada para esta fatura."})
    return result


@router.post("/statements/{statement_id}/generate-obligations")
def generate_bill_obligations(
    statement_id: str, data: BillGenerateObligationsRequest, actor=Depends(financial_actor),
    key=Depends(required_key), db: Session = Depends(get_db),
):
    return mutate(db, key, "FIN_BILL_GENERATE_OBLIGATIONS", {"statement_id": statement_id, **data.model_dump(mode="json")},
                  lambda session: {"obligations": semantics.generate_bill_obligations(session, statement_id, data, actor)})


@router.get("/statements/{statement_id}/allocation-requirements")
def bill_allocation_requirements(
    statement_id: str, expected_review_id: str | None = Query(None, min_length=1, max_length=36),
    actor=Depends(financial_actor), db: Session = Depends(get_db),
):
    from app.services.financial_bill_allocations import inspect_requirements
    return inspect_requirements(db, statement_id, expected_review_id)


@router.get("/statements/{statement_id}/obligations")
def list_bill_obligations(statement_id: str, actor=Depends(financial_actor), db: Session = Depends(get_db)):
    return semantics.list_bill_obligations(db, statement_id)


@router.post("/statements/{statement_id}/post-to-treasury")
def post_statement_to_treasury(
    statement_id: str,
    data: FinancialImportContext,
    actor=Depends(financial_actor),
    key=Depends(required_key),
    db: Session = Depends(get_db),
):
    """Lança as transações de um extrato bancário confirmado na conta financeira de tesouraria vinculada."""
    return mutate(
        db, key, "FIN_STATEMENT_POST_TREASURY", {"statement_id": statement_id, **data.model_dump()},
        lambda session: _post_current_statement(session, statement_id, data, actor),
        status=200,
    )


def _post_current_statement(db, statement_id, data, actor):
    lifecycle.guard_statement(db, statement_id, data)
    return service.post_statement_to_treasury(db, statement_id, actor)



from pydantic import BaseModel, Field

class ImportRemovalRequest(BaseModel):
    import_id: str | None = None
    expected_generation: int | None = Field(None, ge=1)
    expected_snapshot: str = Field(min_length=64, max_length=64)

@router.get('/documents/{document_id}/removal')
def import_removal_plan(document_id: str, import_id: str | None = Query(None),
                        expected_generation: int | None = Query(None, ge=1),
                        actor=Depends(financial_actor), db: Session = Depends(get_db)):
    from app.services.financial_import_removals import plan
    return plan(db, document_id, import_id, expected_generation)

@router.post('/documents/{document_id}/remove')
def remove_import(document_id: str, data: ImportRemovalRequest, actor=Depends(financial_actor), key=Depends(required_key), db: Session = Depends(get_db)):
    from app.services.financial_import_removals import remove
    return mutate(db,key,'FIN_IMPORT_REMOVE_V1',{'document_id':document_id,**data.model_dump()},
        lambda session: remove(session,document_id,data.import_id,data.expected_generation,
                               data.expected_snapshot,actor))
