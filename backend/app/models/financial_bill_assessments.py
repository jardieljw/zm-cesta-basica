"""Append-only assessment snapshots bound to one immutable preview."""
import datetime

from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, JSON, UniqueConstraint, CheckConstraint, event, DDL
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, utc_now


class FinancialBillAssessment(Base):
    __tablename__ = "financial_bill_assessments"
    __table_args__ = (
        UniqueConstraint("preview_id", "revision", name="uq_fin_bill_assessment_revision"),
        CheckConstraint("revision > 0", name="ck_fin_bill_assessment_revision"),
        CheckConstraint("status IN ('REVIEW_REQUIRED','VERIFIED')", name="ck_fin_bill_assessment_status"),
        CheckConstraint("evidence_count BETWEEN 0 AND 20", name="ck_fin_bill_evidence_count"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    preview_id: Mapped[str] = mapped_column(ForeignKey("financial_import_previews.id"), nullable=False)
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    evidence_count: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    header: Mapped[dict | None] = mapped_column(JSON, nullable=False)
    resolutions: Mapped[list] = mapped_column(JSON, nullable=False)
    report: Mapped[dict] = mapped_column(JSON, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("paired_devices.id"), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)


class FinancialBillEvidence(Base):
    __tablename__ = "financial_bill_evidence"
    __table_args__ = (
        UniqueConstraint("assessment_id", "position", name="uq_fin_bill_evidence_position"),
        CheckConstraint("position > 0", name="ck_fin_bill_evidence_position"),
        CheckConstraint("role IN ('HEADER','DETAILS')", name="ck_fin_bill_evidence_role"),
    )
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    assessment_id: Mapped[str] = mapped_column(ForeignKey("financial_bill_assessments.id"), nullable=False)
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    document_id: Mapped[str] = mapped_column(ForeignKey("financial_documents.id"), nullable=False)
    role: Mapped[str] = mapped_column(String(10), nullable=False)
    document_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    claims: Mapped[dict] = mapped_column(JSON, nullable=False)


class FinancialBillAssessmentLink(Base):
    __tablename__ = "financial_bill_assessment_links"
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    statement_id: Mapped[str] = mapped_column(ForeignKey("financial_statements.id"), nullable=False, index=True)
    assessment_id: Mapped[str] = mapped_column(ForeignKey("financial_bill_assessments.id"), nullable=False, unique=True)


BILL_TRIGGERS = []
for table in (FinancialBillAssessment.__table__, FinancialBillEvidence.__table__, FinancialBillAssessmentLink.__table__):
    for operation in ("UPDATE", "DELETE"):
        sql = (f"CREATE TRIGGER IF NOT EXISTS trg_{table.name}_no_{operation.lower()} BEFORE {operation} ON {table.name} "
               "BEGIN SELECT RAISE(ABORT, 'financial evidence is immutable'); END;")
        BILL_TRIGGERS.append(sql)
        event.listen(table, "after_create", DDL(sql).execute_if(dialect="sqlite"))

BILL_INSERT_TRIGGERS = [
    (FinancialBillAssessment.__table__, """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_revision_insert BEFORE INSERT ON financial_bill_assessments
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_bill_assessments WHERE preview_id = NEW.preview_id), 0) + 1
 OR (SELECT s.source_type FROM financial_import_previews p JOIN financial_sources s ON s.id = p.source_id WHERE p.id = NEW.preview_id) != 'CREDIT_CARD'
BEGIN SELECT RAISE(ABORT, 'invalid financial bill assessment'); END;"""),
    (FinancialBillEvidence.__table__, """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_evidence_insert BEFORE INSERT ON financial_bill_evidence
WHEN NEW.document_sha256 != (SELECT sha256 FROM financial_documents WHERE id = NEW.document_id)
 OR NEW.position > (SELECT evidence_count FROM financial_bill_assessments WHERE id = NEW.assessment_id)
 OR NEW.assessment_id IS NOT (SELECT a.id FROM financial_bill_assessments a WHERE a.id = NEW.assessment_id
 AND a.revision = (SELECT MAX(b.revision) FROM financial_bill_assessments b WHERE b.preview_id = a.preview_id))
BEGIN SELECT RAISE(ABORT, 'invalid financial bill evidence'); END;"""),
    (FinancialBillAssessmentLink.__table__, """CREATE TRIGGER IF NOT EXISTS trg_financial_bill_link_insert BEFORE INSERT ON financial_bill_assessment_links
WHEN NOT EXISTS (SELECT 1 FROM financial_bill_assessments a JOIN financial_statements s ON s.preview_id = a.preview_id
 WHERE a.id = NEW.assessment_id AND s.id = NEW.statement_id AND s.statement_type = 'CARD_BILL' AND a.status = 'VERIFIED'
 AND a.revision = (SELECT MAX(b.revision) FROM financial_bill_assessments b WHERE b.preview_id = a.preview_id)
 AND s.due_on = json_extract(a.header, '$.due_on') AND s.total_amount_cents = json_extract(a.header, '$.total_amount_cents')
 AND s.period_start IS json_extract(a.header, '$.period_start') AND s.period_end IS json_extract(a.header, '$.period_end'))
BEGIN SELECT RAISE(ABORT, 'invalid financial bill assessment link'); END;"""),
]
for table, sql in BILL_INSERT_TRIGGERS:
    BILL_TRIGGERS.append(sql)
    event.listen(table, "after_create", DDL(sql).execute_if(dialect="sqlite"))
