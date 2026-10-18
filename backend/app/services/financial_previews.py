"""Versioned import previews; confirmation only creates pending evidence."""
import uuid

from pydantic import ValidationError
from sqlalchemy import select

from app.core.idempotency import compute_payload_hash
from app.models.financial_imports import FinancialImportPreview, FinancialDocument, FinancialSource
from app.schemas.financial_imports import FinancialStatementCreate, FinancialTransactionData
from app.services import financial_imports as evidence
from app.services.financial_readers import READERS, parse_csv
from app.services.financial_pdf_runtime import extract_pdf


def preview_summary(preview):
    result = evidence.as_dict(preview)
    report = preview.result
    result.update({k: v for k, v in report.items() if k not in {"items", "errors", "pages"}})
    result.update(items_count=len(report["items"]), errors_count=len(report["errors"]), affects_ledger=False)
    return result


def interpretation(data):
    reader = READERS[data.reader_id]
    options = reader.options or data.options
    values = options.model_dump(mode="json") if options else {}
    return reader, options, compute_payload_hash({
        "reader_id": reader.id,
        "reader_version": reader.version,
        "options": values,
        "currency": data.currency,
        "has_password": bool(getattr(data, "password", None)),
    })


def existing_preview(db, document_id, source_id, request_hash):
    return db.scalar(select(FinancialImportPreview).where(
        FinancialImportPreview.document_id == document_id, FinancialImportPreview.source_id == source_id,
        FinancialImportPreview.request_sha256 == request_hash,
    ))


def prepare_pdf_preview(db, document_id, data):
    """Read immutable bytes, release the read transaction, then run the worker.

    Never perform untrusted PDF parsing while holding SQLite's write lock.
    The mutation subsequently revalidates document identity and selected source.
    """
    if data.reader_id != "pdf_auto":
        return None
    document = evidence.require(db, FinancialDocument, document_id)
    source = evidence.require(db, FinancialSource, data.source_id)
    if document.media_type != "application/pdf":
        evidence.fail("FINANCIAL_READER_DOCUMENT_TYPE", "Este leitor exige documento PDF.", 415)
    if source.currency != data.currency or data.currency != "BRL":
        evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "Estes layouts PDF exigem origem em reais.")
    _, _, request_hash = interpretation(data)
    if existing_preview(db, document_id, source.id, request_hash):
        db.rollback()
        return None
    content, digest = document.content, document.sha256
    db.rollback()
    pwd = getattr(data, "password", None)
    report = extract_pdf(content, password=pwd) if pwd else extract_pdf(content)
    transient = {"PDF_PROCESSING_FAILED", "PDF_PROCESSING_TIMEOUT", "PDF_RUNTIME_UNAVAILABLE", "PDF_PROCESSING_BUSY"}
    if any(e["code"] in transient for e in report["errors"]):
        evidence.fail(report["errors"][0]["code"], "Nao foi possivel processar o PDF agora. Tente novamente.", 503)
    return digest, report


def create_preview(db, document_id, data, actor_id, prepared=None):
    document = evidence.require(db, FinancialDocument, document_id)
    source = evidence.require(db, FinancialSource, data.source_id)
    reader, options, request_hash = interpretation(data)
    if document.media_type != reader.media_type:
        evidence.fail("FINANCIAL_READER_DOCUMENT_TYPE", "O documento nao corresponde ao leitor selecionado.", 415)
    if source.currency != data.currency or (reader.options is not None and reader.id != "generic_csv" and data.currency != "BRL"):
        evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "A moeda confirmada deve corresponder a origem e ao leitor.")
    if options and (source.source_type == "BANK_ACCOUNT") != (options.amount_convention == "CREDITS_POSITIVE"):
        evidence.fail("FINANCIAL_IMPORT_SIGN_MISMATCH", "Confirme a convencao dos valores para conta bancaria ou cartao.")
    old = existing_preview(db, document_id, source.id, request_hash)
    if old:
        return {"preview": preview_summary(old), "duplicate": True}
    if reader.id == "pdf_auto":
        from app.models.auth import PairedDevice
        device = db.get(PairedDevice, actor_id)
        if device is None or not device.is_active:
            evidence.fail("FINANCIAL_AUTH_REQUIRED", "Autenticacao valida de dispositivo necessaria.", 401)
        if prepared is None or prepared[0] != document.sha256:
            evidence.fail("FINANCIAL_PREVIEW_CHANGED", "Gere outra previa do documento original.")
        report = prepared[1]
        if data.currency != "BRL":
            evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "Estes layouts PDF exigem origem em reais.")
        if report.get("detected_source_type") and report["detected_source_type"] != source.source_type:
            report["errors"].append({"code": "PDF_SOURCE_TYPE_MISMATCH", "fields": []})
    else:
        report = parse_csv(document.content, options, exact_headers=reader.id == "nubank_account_csv")
    preview = FinancialImportPreview(
        id=str(uuid.uuid4()), document_id=document.id, source_id=source.id,
        reader_id=reader.id, reader_version=reader.version, options=options.model_dump(mode="json") if options else {},
        request_sha256=request_hash, result_sha256=compute_payload_hash(report),
        status="INVALID" if report["errors"] else "READY", result=report, created_by=actor_id,
    )
    db.add(preview)
    db.flush()
    evidence.audit(db, actor_id, "IMPORT_PREVIEW_CREATED", preview, {
        "reader_id": reader.id, "reader_version": reader.version, "status": preview.status,
        "items_count": len(report["items"]), "errors_count": len(report["errors"]),
    })
    return {"preview": preview_summary(preview), "duplicate": False}


def preview_items(db, preview, offset, limit):
    return [{**item, "candidates": evidence.data_candidates(
        db, preview.source_id, FinancialTransactionData.model_validate(item["data"]),
    )} for item in preview.result["items"][offset:offset + limit]]


def confirm_preview(db, preview_id, data, actor_id):
    preview = evidence.require(db, FinancialImportPreview, preview_id)
    if data.expected_source_id != preview.source_id:
        evidence.fail("FINANCIAL_IMPORT_SOURCE_MISMATCH", "Confirme a conta ou o cartao selecionado na previa.")
    if data.expected_result_sha256 != preview.result_sha256:
        evidence.fail("FINANCIAL_PREVIEW_CHANGED", "Confira o resultado da previa antes de confirmar.")
    if preview.status != "READY":
        evidence.fail("FINANCIAL_PREVIEW_INVALID", "A previa possui erros. Corrija o mapeamento e gere outra previa.")
    header = data.model_dump(mode="json", exclude={"expected_source_id", "expected_result_sha256", "assessment_id"})
    if preview.reader_id == "pdf_auto":
        for field, value in preview.result.get("extracted_header", {}).items():
            if header.get(field) is not None and header[field] != value:
                evidence.fail("FINANCIAL_PDF_HEADER_CONFLICT", "Os dados confirmados divergem dos dados extraidos do PDF.")
            header[field] = value
    assessment = None
    if data.assessment_id:
        from app.services import financial_bill_assessments as bills
        effective = type(data).model_validate({**data.model_dump(mode="json"), **header}) if preview.reader_id == "pdf_auto" else data
        assessment = bills.validate_confirmation(db, preview, effective)
    try:
        statement = FinancialStatementCreate(
            document_id=preview.document_id, source_id=preview.source_id, **header,
            items=[{k: v for k, v in item.items() if k in {"position", "page_number", "raw_text", "data"}}
                   for item in preview.result["items"]],
        )
    except ValidationError:
        evidence.fail("FINANCIAL_IMPORT_HEADER_INVALID", "Confira periodo, tipo e totais informados no documento.", 422)
    result = evidence.create_statement(db, statement, actor_id, preview_id=preview.id)
    if assessment:
        bills.link_confirmation(db, result["statement"]["id"], assessment, actor_id)
        result["assessment_id"] = assessment.id
    if not result["duplicate"]:
        evidence.audit(db, actor_id, "IMPORT_PREVIEW_CONFIRMED", preview, {"statement_id": result["statement"]["id"]})
    return result
