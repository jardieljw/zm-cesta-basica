"""Previous-release evidence remains byte-for-byte intact after the new DDL."""
import datetime
import sqlite3

import pytest
import sqlalchemy as sa
from alembic import command
from sqlalchemy.orm import Session

from app.core.database import create_db_engine
from app.models import PairedDevice
from app.models.financial import FinancialAccount
from app.schemas.financial_imports import FinancialSourceCreate, FinancialReviewCorrectionCreate
from app.services import financial_imports as service
from app.services.financial_review_corrections import current_item, correct_review
from test_financial_imports_migration import config, snapshot


def test_upgrade_preserves_prior_previews_reviews_aliases_and_books_then_allows_audited_correction(tmp_path, monkeypatch):
    path = tmp_path / "prior-financial-release.db"
    cfg = config(path)
    command.upgrade(cfg, "fb1e2f3a5411")
    engine = create_db_engine("sqlite:///" + path.as_posix())
    with Session(engine) as db:
        db.add(PairedDevice(id="prior-device", device_name="Anterior", device_public_id="prior-release", token_hash="synthetic-hash"))
        db.add(FinancialAccount(id="prior-bank", name="Outro banco", account_type="BANK", initial_balance_cents=50000, current_balance_cents=50000))
        db.commit()
        source = service.create_source(db, FinancialSourceCreate(source_type="BANK_ACCOUNT", financial_account_id="prior-bank",
            name="Conta PJ", institution="Banco exemplo", holder_type="PJ"), "prior-device")
        document = service.store_document(db, b"date,amount\n2025-07-10,-50.00", "prior.csv", "text/csv", "prior-device")["document"]
        db.commit()
    # Reflect the old release, because current ORM review queries require the
    # new tables and must not run against an unmigrated database.
    metadata = sa.MetaData()
    metadata.reflect(engine)
    created = {"created_by": "prior-device", "created_at": datetime.datetime(2025, 7, 10, 12)}
    fact = {"transaction_date": "2025-07-10", "amount_cents": -5000, "description": "Fornecedor sintetico"}
    identified = {**fact, "external_id_namespace": "bank:csv", "external_id": "prior-alias"}
    with engine.begin() as db:
        db.execute(metadata.tables["financial_import_previews"].insert().values(id="prior-preview", document_id=document["id"],
            source_id=source["id"], reader_id="generic_csv", reader_version="1", options={"retained": "original-options"},
            request_sha256="a" * 64, result_sha256="b" * 64, status="READY", result={"items": [fact, identified]}, **created))
        db.execute(metadata.tables["financial_statements"].insert().values(id="prior-statement", document_id=document["id"],
            source_id=source["id"], preview_id="prior-preview", statement_type="BANK_STATEMENT", payload_sha256="c" * 64, **created))
        db.execute(metadata.tables["financial_transactions"].insert().values(id="prior-transaction", source_id=source["id"],
            transaction_date=datetime.date(2025, 7, 10), date_kind="AS_REPORTED", amount_cents=-5000,
            description="Fornecedor sintetico", transaction_kind="OTHER", **created))
        for position, data in enumerate((fact, identified), 1):
            db.execute(metadata.tables["financial_statement_items"].insert().values(id=f"prior-item-{position}", statement_id="prior-statement",
                position=position, raw_text=f"Original {position}", normalized_data=data, review_status="NEW" if position == 1 else "LINKED",
                transaction_id="prior-transaction", reviewed_by="prior-device", reviewed_at=created["created_at"]))
        db.execute(metadata.tables["financial_transaction_identities"].insert().values(id="prior-identity", source_id=source["id"],
            transaction_id="prior-transaction", namespace="bank:csv", external_id="prior-alias"))
    before = snapshot(path)
    with sqlite3.connect(path) as db:
        before_schema = db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").fetchall()
    monkeypatch.setattr(sa, "engine_from_config", lambda *args, **kwargs: create_db_engine("sqlite:///" + path.as_posix()))
    command.upgrade(cfg, "head")
    assert snapshot(path, before.keys()) == before
    with engine.connect() as db:
        assert db.exec_driver_sql("PRAGMA foreign_keys").scalar() == 1
        assert db.exec_driver_sql("PRAGMA foreign_key_check").all() == []
        assert db.exec_driver_sql("PRAGMA integrity_check").scalar() == "ok"
        after_schema = db.exec_driver_sql("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").all()
        assert all(row in after_schema for row in before_schema)
    with Session(engine) as db:
        assert current_item(db, "prior-item-2")["review_revision"] == 0
        corrected = correct_review(db, "prior-item-2", FinancialReviewCorrectionCreate(
            action="NEW", expected_revision=0, reason="Duas operacoes diferentes confirmadas no original"), "prior-device")
        assert corrected["transaction"]["id"] != "prior-transaction"
        db.commit()
    unchanged = {"financial_statement_items", "financial_transaction_identities", "financial_import_previews", "financial_statements",
                 "financial_accounts", "cash_flow_entries", "accounts_payable", "payable_payments", "inventory_movements"}
    assert snapshot(path, unchanged) == {name: before[name] for name in unchanged}
    with pytest.raises(RuntimeError, match="preserve history"):
        command.downgrade(cfg, "fb1e2f3a5411")
    with sqlite3.connect(path) as db:
        assert db.execute("SELECT version_num FROM alembic_version").fetchone() == ("fc2f3a4b6512",)
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []
    engine.dispose()
