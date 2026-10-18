"""Additive migration with existing evidence and populated-downgrade refusal."""
import sqlite3

import pytest
from alembic import command
from sqlalchemy.orm import Session

from app.core.database import create_db_engine
from app.models import PairedDevice
from app.schemas.financial_imports import FinancialSourceCreate
from app.schemas.financial_readers import FinancialPreviewCreate
from app.schemas.financial_bill_assessments import BillAssessmentCreate
from app.services import financial_imports, financial_previews, financial_bill_assessments
from test_financial_imports_migration import config, snapshot


def test_additive_bill_migration_preserves_old_evidence_and_prevents_losing_new_history(tmp_path):
    path = tmp_path / "previous-release.db"
    cfg = config(path)
    command.upgrade(cfg, "fc2f3a4b6512")
    engine = create_db_engine("sqlite:///" + path.as_posix())
    try:
        with Session(engine) as db:
            db.add(PairedDevice(id="device", device_name="Teste", device_public_id="synthetic", token_hash="synthetic-hash"))
            db.commit()
            source = financial_imports.create_source(db, FinancialSourceCreate(source_type="CREDIT_CARD", holder_type="PJ",
                name="Cartao existente", institution="Instituicao exemplo"), "device")
            document = financial_imports.store_document(db, b"Dia;Valor;Texto\n10/07/2025;1,00;Compra\n", "prior.csv", "text/csv", "device")["document"]
            preview = financial_previews.create_preview(db, document["id"], FinancialPreviewCreate(
                source_id=source["id"], currency="BRL", reader_id="generic_csv", options={
                "columns": {"transaction_date": "Dia", "amount": "Valor", "description": "Texto"},
                "delimiter": ";", "date_format": "DD/MM/YYYY", "decimal_separator": ",", "amount_convention": "CHARGES_POSITIVE"}), "device")["preview"]
            db.commit()
        before = snapshot(path)
        with sqlite3.connect(path) as db:
            schema = db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").fetchall()
        command.upgrade(cfg, "head")
        assert snapshot(path, before.keys()) == before
        with engine.connect() as db:
            assert db.exec_driver_sql("PRAGMA foreign_keys").scalar() == 1
            assert db.exec_driver_sql("PRAGMA foreign_key_check").all() == []
            assert db.exec_driver_sql("PRAGMA integrity_check").scalar() == "ok"
            after_schema = db.exec_driver_sql("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").all()
            assert all(row in after_schema for row in schema)
        with Session(engine) as db:
            result = financial_bill_assessments.create(db, preview["id"], BillAssessmentCreate(expected_revision=0,
                expected_source_id=source["id"], expected_result_sha256=preview["result_sha256"], reason="Conferencia pendente",
                header={"due_on": "2025-08-10", "total_amount_cents": 100}), "device")
            assert result["assessment"]["status"] == "REVIEW_REQUIRED"
            db.commit()
        with pytest.raises(RuntimeError, match="preserve history"):
            command.downgrade(cfg, "fc2f3a4b6512")
        with sqlite3.connect(path) as db:
            assert db.execute("SELECT version_num FROM alembic_version").fetchone() == ("fd3a4b5c7613",)
            assert db.execute("SELECT count(*) FROM financial_bill_assessments").fetchone() == (1,)
    finally:
        engine.dispose()
