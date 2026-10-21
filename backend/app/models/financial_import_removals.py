"""Visibility and withdrawal state; original financial evidence stays immutable."""
from sqlalchemy import String, Integer, Boolean, JSON, DateTime, ForeignKey, CheckConstraint, event, DDL
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, utc_now

class FinancialImportRemoval(Base):
    __tablename__ = 'financial_import_removals'
    __table_args__ = (CheckConstraint('generation > 0', name='ck_import_removal_generation'),)
    document_id: Mapped[str] = mapped_column(ForeignKey('financial_documents.id'), primary_key=True)
    generation: Mapped[int] = mapped_column(Integer, nullable=False)
    removed: Mapped[bool] = mapped_column(Boolean, nullable=False)
    effects: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    updated_by: Mapped[str] = mapped_column(ForeignKey('paired_devices.id'), nullable=False)
    updated_at: Mapped[object] = mapped_column(DateTime, nullable=False, default=utc_now)
    @property
    def id(self):
        return self.document_id


for _operation in ('INSERT', 'UPDATE', 'DELETE'):
    event.listen(FinancialImportRemoval.__table__, 'after_create', DDL(
        f'CREATE TRIGGER IF NOT EXISTS trg_fin_import_legacy_no_{_operation.lower()} '
        f'BEFORE {_operation} ON financial_import_removals BEGIN '
        "SELECT RAISE(ABORT, 'legacy import withdrawals are read only'); END;"
    ).execute_if(dialect='sqlite'))
