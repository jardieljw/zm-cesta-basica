"""Manual provenance and exact comparison, without posting payments or debts."""
import uuid

from sqlalchemy import select

from app.models.financial_imports import FinancialImportPreview, FinancialSource, FinancialDocument
from app.models.financial_bill_assessments import FinancialBillAssessment, FinancialBillEvidence, FinancialBillAssessmentLink
from app.services import financial_imports as base


def latest(db, preview_id):
    return db.scalar(select(FinancialBillAssessment).where(FinancialBillAssessment.preview_id == preview_id)
                     .order_by(FinancialBillAssessment.revision.desc()).limit(1))


def summary(assessment):
    return {**base.as_dict(assessment), "affects_ledger": False, "can_generate_obligations": False,
            "semantic_status": "NOT_REVIEWED", "verification_method": "MANUAL_TRANSCRIPTION_EXACT_COMPARISON"}


def evaluate(preview, data):
    findings = []

    def finding(code, suffix="", **fields):
        findings.append({"id": code + (":" + suffix if suffix else ""), "code": code, **fields})

    if preview.status != "READY":
        finding("READING_INVALID")
    header = data.header.model_dump(mode="json") if data.header else None
    if header is None:
        finding("DECLARED_HEADER_REQUIRED")
    header_verified, header_seen = True, False
    reference_positions = set()
    # These comparisons refer to the exact stored preview, never current dedup decisions.
    rows = {i["position"]: i["data"] for i in preview.result["items"]}
    detail_seen = False
    for position, evidence in enumerate(data.evidence, 1):
        suffix = str(position)
        if evidence.header.model_dump(mode="json") != header:
            finding("DECLARED_HEADER_MISMATCH", suffix, evidence_position=position)
            header_verified = False
        if evidence.role == "HEADER":
            header_seen = True
        else:
            if evidence.document_id == preview.document_id:
                finding("INDEPENDENT_DETAILS_REQUIRED", suffix, evidence_position=position)
            else:
                detail_seen = True
            for index, item in enumerate(evidence.items, 1):
                ref = f"{position}:{index}"
                target = rows.get(item.preview_position)
                if item.preview_position is None or target is None:
                    finding("UNMATCHED_REFERENCE_ITEM", ref, evidence_position=position, reference_position=index)
                    continue
                if item.preview_position in reference_positions:
                    finding("REPEATED_REFERENCE_POSITION", ref, preview_position=item.preview_position)
                reference_positions.add(item.preview_position)
                expected = item.model_dump(mode="json", exclude={"preview_position"})
                for field, value in expected.items():
                    if target[field] != value:
                        finding("REFERENCE_" + field.upper() + "_MISMATCH", ref, preview_position=item.preview_position)
    header_verified = header is not None and header_seen and header_verified
    if not header_seen:
        finding("HEADER_EVIDENCE_REQUIRED")
    if not detail_seen:
        finding("DETAILS_EVIDENCE_REQUIRED")
    missing = set(rows) - reference_positions
    if missing:
        finding("PREVIEW_ITEMS_UNCOVERED", count=len(missing))
    for observation in data.observations:
        findings.append({"id": "MANUAL:" + observation.key, "code": "MANUAL_OBSERVATION", "reason": observation.reason})
    coverage_codes = {f["code"] for f in findings} - {"HEADER_EVIDENCE_REQUIRED", "DECLARED_HEADER_MISMATCH"}
    coverage_verified = detail_seen and not coverage_codes
    status = "VERIFIED" if header_verified and coverage_verified and not findings else "REVIEW_REQUIRED"
    return {"reading_status": preview.status, "header_verified": header_verified,
            "coverage_verified": coverage_verified, "findings": findings, "status": status,
            "preview_result_sha256": preview.result_sha256, "reader_id": preview.reader_id,
            "reader_version": preview.reader_version, "items_compared": len(reference_positions)}


def create(db, preview_id, data, actor_id):
    preview = base.require(db, FinancialImportPreview, preview_id)
    source = base.require(db, FinancialSource, preview.source_id)
    if source.source_type != "CREDIT_CARD":
        base.fail("FINANCIAL_BILL_SOURCE_REQUIRED", "A conferencia exige uma origem de cartao.")
    if data.expected_source_id != source.id or data.expected_result_sha256 != preview.result_sha256:
        base.fail("FINANCIAL_BILL_PREVIEW_MISMATCH", "Confira a origem e a versao exata da previa.")
    previous = latest(db, preview_id)
    revision = previous.revision if previous else 0
    if data.expected_revision != revision:
        base.fail("FINANCIAL_BILL_REVISION_CONFLICT", "A conferencia mudou. Atualize e confira novamente.")
    documents = {}
    for evidence in data.evidence:
        document = base.require(db, FinancialDocument, evidence.document_id)
        if evidence.source_id != source.id or evidence.currency != source.currency:
            base.fail("FINANCIAL_BILL_EVIDENCE_SOURCE_MISMATCH", "O documento informado pertence a outra origem ou moeda.")
        if document.media_type == "application/pdf" and evidence.page_number is None:
            base.fail("FINANCIAL_BILL_PAGE_REQUIRED", "Indique a pagina conferida no PDF.", 422)
        documents[document.id] = document
    report = evaluate(preview, data)
    old_findings = {f["id"] for f in previous.report["findings"]} if previous else set()
    new_findings = {f["id"] for f in report["findings"]}
    resolutions = {r.finding_id: r for r in data.resolutions}
    if set(resolutions) != old_findings - new_findings:
        base.fail("FINANCIAL_BILL_RESOLUTION_REQUIRED", "Justifique cada divergencia anterior resolvida, sem dispensar as que continuam presentes.")
    for resolution in resolutions.values():
        if resolution.document_id not in documents:
            base.fail("FINANCIAL_BILL_RESOLUTION_EVIDENCE_REQUIRED", "A resolucao deve indicar documento da nova conferencia.")
        if documents[resolution.document_id].media_type == "application/pdf" and resolution.page_number is None:
            base.fail("FINANCIAL_BILL_PAGE_REQUIRED", "Indique a pagina conferida no PDF.", 422)
    assessment = FinancialBillAssessment(id=str(uuid.uuid4()), preview_id=preview_id, revision=revision + 1,
        reason=data.reason, header=data.header.model_dump(mode="json") if data.header else None, report=report, status=report["status"],
        resolutions=[r.model_dump(mode="json") for r in data.resolutions], evidence_count=len(data.evidence), created_by=actor_id)
    db.add(assessment)
    db.flush()
    for position, evidence in enumerate(data.evidence, 1):
        db.add(FinancialBillEvidence(id=str(uuid.uuid4()), assessment_id=assessment.id, position=position,
            document_id=evidence.document_id, role=evidence.role, document_sha256=documents[evidence.document_id].sha256,
            claims=evidence.model_dump(mode="json")))
    db.flush()
    base.audit(db, actor_id, "BILL_ASSESSMENT_CREATED", assessment,
               {"revision": assessment.revision, "status": assessment.status, "findings_count": len(report["findings"])})
    return {"assessment": summary(assessment)}


def evidence_rows(db, assessment_id, limit, offset):
    base.require(db, FinancialBillAssessment, assessment_id)
    return [base.as_dict(r) for r in db.scalars(select(FinancialBillEvidence).where(
        FinancialBillEvidence.assessment_id == assessment_id).order_by(FinancialBillEvidence.position).limit(limit).offset(offset))]


def validate_confirmation(db, preview, data):
    assessment = base.require(db, FinancialBillAssessment, data.assessment_id)
    current = latest(db, preview.id)
    if assessment.preview_id != preview.id or current.id != assessment.id:
        base.fail("FINANCIAL_BILL_ASSESSMENT_STALE", "Selecione a conferencia atual desta previa.")
    if assessment.status != "VERIFIED":
        base.fail("FINANCIAL_BILL_ASSESSMENT_UNRESOLVED", "A conferencia ainda possui pendencias.")
    header = data.model_dump(mode="json")
    if data.statement_type != "CARD_BILL" or any(header[key] != value for key, value in assessment.header.items()):
        base.fail("FINANCIAL_BILL_HEADER_MISMATCH", "O cabecalho difere da conferencia selecionada.")
    return assessment


def link_confirmation(db, statement_id, assessment, actor_id):
    existing = db.scalar(select(FinancialBillAssessmentLink).where(FinancialBillAssessmentLink.assessment_id == assessment.id))
    if existing is None:
        db.add(FinancialBillAssessmentLink(id=str(uuid.uuid4()), statement_id=statement_id, assessment_id=assessment.id))
        db.flush()
        base.audit(db, actor_id, "BILL_ASSESSMENT_LINKED", assessment, {"statement_id": statement_id})
    elif existing.statement_id != statement_id:
        base.fail("FINANCIAL_BILL_CONFIRMATION_CONFLICT", "A conferencia ja esta associada a outro documento confirmado.")
