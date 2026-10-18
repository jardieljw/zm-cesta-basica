"""audited bill evidence assessments

Revision ID: fd3a4b5c7613
Revises: fc2f3a4b6512
Create Date: 2026-10-16 18:35:04.613517

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fd3a4b5c7613'
down_revision: Union[str, None] = 'fc2f3a4b6512'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('financial_bill_assessments',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('preview_id', sa.String(36), sa.ForeignKey('financial_import_previews.id'), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('evidence_count', sa.Integer(), nullable=False),
        sa.Column('reason', sa.Text(), nullable=False),
        sa.Column('header', sa.JSON(), nullable=False),
        sa.Column('resolutions', sa.JSON(), nullable=False),
        sa.Column('report', sa.JSON(), nullable=False),
        sa.Column('status', sa.String(20), nullable=False),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('paired_devices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.UniqueConstraint('preview_id', 'revision', name='uq_fin_bill_assessment_revision'),
        sa.CheckConstraint('revision > 0', name='ck_fin_bill_assessment_revision'),
        sa.CheckConstraint('evidence_count BETWEEN 0 AND 20', name='ck_fin_bill_evidence_count'),
        sa.CheckConstraint("status IN ('REVIEW_REQUIRED','VERIFIED')", name='ck_fin_bill_assessment_status'))
    op.create_table('financial_bill_evidence',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('assessment_id', sa.String(36), sa.ForeignKey('financial_bill_assessments.id'), nullable=False),
        sa.Column('position', sa.Integer(), nullable=False),
        sa.Column('document_id', sa.String(36), sa.ForeignKey('financial_documents.id'), nullable=False),
        sa.Column('role', sa.String(10), nullable=False),
        sa.Column('document_sha256', sa.String(64), nullable=False),
        sa.Column('claims', sa.JSON(), nullable=False),
        sa.UniqueConstraint('assessment_id', 'position', name='uq_fin_bill_evidence_position'),
        sa.CheckConstraint('position > 0', name='ck_fin_bill_evidence_position'),
        sa.CheckConstraint("role IN ('HEADER','DETAILS')", name='ck_fin_bill_evidence_role'))
    op.create_table('financial_bill_assessment_links',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('statement_id', sa.String(36), sa.ForeignKey('financial_statements.id'), nullable=False),
        sa.Column('assessment_id', sa.String(36), sa.ForeignKey('financial_bill_assessments.id'), nullable=False, unique=True))
    op.create_index('ix_financial_bill_assessment_links_statement_id', 'financial_bill_assessment_links', ['statement_id'])
    for table in ('financial_bill_assessments', 'financial_bill_evidence', 'financial_bill_assessment_links'):
        for operation in ('UPDATE', 'DELETE'):
            op.execute(f"CREATE TRIGGER IF NOT EXISTS trg_{table}_no_{operation.lower()} BEFORE {operation} ON {table} "
                       "BEGIN SELECT RAISE(ABORT, 'financial evidence is immutable'); END;")
    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_financial_bill_revision_insert BEFORE INSERT ON financial_bill_assessments
WHEN NEW.revision != COALESCE((SELECT MAX(revision) FROM financial_bill_assessments WHERE preview_id = NEW.preview_id), 0) + 1
 OR (SELECT s.source_type FROM financial_import_previews p JOIN financial_sources s ON s.id = p.source_id WHERE p.id = NEW.preview_id) != 'CREDIT_CARD'
BEGIN SELECT RAISE(ABORT, 'invalid financial bill assessment'); END;""")
    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_financial_bill_evidence_insert BEFORE INSERT ON financial_bill_evidence
WHEN NEW.document_sha256 != (SELECT sha256 FROM financial_documents WHERE id = NEW.document_id)
 OR NEW.position > (SELECT evidence_count FROM financial_bill_assessments WHERE id = NEW.assessment_id)
 OR NEW.assessment_id IS NOT (SELECT a.id FROM financial_bill_assessments a WHERE a.id = NEW.assessment_id
 AND a.revision = (SELECT MAX(b.revision) FROM financial_bill_assessments b WHERE b.preview_id = a.preview_id))
BEGIN SELECT RAISE(ABORT, 'invalid financial bill evidence'); END;""")
    op.execute("""CREATE TRIGGER IF NOT EXISTS trg_financial_bill_link_insert BEFORE INSERT ON financial_bill_assessment_links
WHEN NOT EXISTS (SELECT 1 FROM financial_bill_assessments a JOIN financial_statements s ON s.preview_id = a.preview_id
 WHERE a.id = NEW.assessment_id AND s.id = NEW.statement_id AND s.statement_type = 'CARD_BILL' AND a.status = 'VERIFIED'
 AND a.revision = (SELECT MAX(b.revision) FROM financial_bill_assessments b WHERE b.preview_id = a.preview_id)
 AND s.due_on = json_extract(a.header, '$.due_on') AND s.total_amount_cents = json_extract(a.header, '$.total_amount_cents')
 AND s.period_start IS json_extract(a.header, '$.period_start') AND s.period_end IS json_extract(a.header, '$.period_end'))
BEGIN SELECT RAISE(ABORT, 'invalid financial bill assessment link'); END;""")


def downgrade() -> None:
    for table in ('financial_bill_assessment_links', 'financial_bill_evidence', 'financial_bill_assessments'):
        if op.get_bind().execute(sa.text(f'SELECT 1 FROM {table} LIMIT 1')).first():
            raise RuntimeError('Cannot downgrade populated bill assessments; preserve history and restore a verified backup instead.')
    for table in ('financial_bill_assessment_links', 'financial_bill_evidence', 'financial_bill_assessments'):
        op.drop_table(table)
