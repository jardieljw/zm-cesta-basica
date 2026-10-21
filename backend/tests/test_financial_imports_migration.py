import datetime
import sqlite3
from pathlib import Path

import pytest
import sqlalchemy as sa
from alembic import command
from alembic.config import Config
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.database import create_db_engine
from app.models import Base, PairedDevice
from app.models.financial import FinancialAccount
from app.schemas.financial import AccountPayableCreate, PayablePaymentCreate
from app.schemas.financial_imports import (
    FinancialSourceCreate, FinancialStatementCreate, FinancialItemReview, FinancialReconciliationCreate,
)
from app.services.financial import create_account_payable, record_payable_payment
from app.services import financial_imports as service

NEW_TABLES = {
    "financial_bill_assessments", "financial_bill_evidence", "financial_bill_assessment_links",
    "financial_sources", "financial_documents", "financial_statements", "financial_statement_items",
    "financial_transactions", "financial_transaction_identities", "financial_reconciliations", "financial_import_audit",
    "financial_import_previews",
    "financial_review_corrections", "financial_identity_changes",
}


def config(path):
    backend = Path(__file__).resolve().parents[1]
    result = Config(str(backend / "alembic.ini"))
    result.set_main_option("script_location", str(backend / "alembic"))
    result.set_main_option("sqlalchemy.url", "sqlite:///" + path.as_posix())
    return result


def snapshot(path, tables=None):
    with sqlite3.connect(path) as db:
        tables = tables or {r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table'")} - {"alembic_version"}
        # Compare the original columns; E2's migration tests separately verify
        # that the new optional columns are NULL on every legacy row.
        additions = {'accounts_payable': {'superseded_by_id'}, 'payable_payments': {'bill_revision_id','stock_cents','business_cents','personal_cents','unclassified_cents'}}
        result = {}
        for table in tables:
            columns = [r[1] for r in db.execute(f'PRAGMA table_info("{table}")') if r[1] not in additions.get(table, set())]
            projection = ','.join('"'+c+'"' for c in columns)
            result[table] = sorted(db.execute(f'SELECT {projection} FROM "{table}"').fetchall(), key=repr)
        return result


def test_populated_migration_preserves_old_history_indexes_and_supports_evidence(tmp_path, test_engine):
    path = tmp_path / "populated.db"
    cfg = config(path)
    command.upgrade(cfg, "f9c0d1e2f309")
    engine = create_db_engine("sqlite:///" + path.as_posix())
    with Session(engine) as db:
        db.add(PairedDevice(id="migration-device", device_name="Teste", device_public_id="migration-test", token_hash="synthetic-hash"))
        db.add(FinancialAccount(id="migration-bank", name="Banco existente", account_type="BANK", initial_balance_cents=50000, current_balance_cents=50000))
        db.commit()
        # Populate the actual previous schema, independent of today's ORM columns.
        payment_id = 'legacy-payment'
        db.execute(text("""INSERT INTO accounts_payable
          (id,payable_number,description,beneficiary,category,nature,original_amount_cents,paid_amount_cents,balance_cents,due_date,payment_method,status,installment_number,total_installments,is_recurrent,created_at,updated_at)
          VALUES ('legacy-payable',1,'Divida antiga','Fornecedor exemplo','OUTROS','BUSINESS',10000,4000,6000,'2024-06-10','BOLETO','PARTIAL',1,1,0,'2024-06-01','2024-06-01')"""))
        db.execute(text("""INSERT INTO payable_payments(id,payable_id,account_id,payment_date,amount_cents,payment_method,status,created_at)
          VALUES ('legacy-payment','legacy-payable','migration-bank','2024-06-10',4000,'BOLETO','CONFIRMED','2024-06-10')"""))
        db.execute(text("""INSERT INTO cash_flow_entries(id,account_id,entry_type,amount_cents,category,nature,description,source_type,source_id,payment_method,occurred_at,is_reversal,created_at)
          VALUES ('legacy-cash','migration-bank','DEBIT',4000,'OUTROS','BUSINESS','Pagamento antigo','PAYABLE_PAYMENT','legacy-payment','BOLETO','2024-06-10',0,'2024-06-10')"""))
        db.execute(text("UPDATE financial_accounts SET current_balance_cents=46000 WHERE id='migration-bank'"))
        db.commit()
    before = snapshot(path)
    with sqlite3.connect(path) as db:
        old_schema = db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").fetchall()
    command.upgrade(cfg, "head")
    assert snapshot(path, before.keys()) == before
    with sqlite3.connect(path) as db:
        after_schema = db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('index','trigger') ORDER BY name").fetchall()
        assert all(row in after_schema for row in old_schema)
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []
    with engine.connect() as connection:
        def included(obj, name, kind, reflected, compare_to):
            return name in NEW_TABLES if kind == "table" else getattr(getattr(obj, "table", None), "name", None) in NEW_TABLES
        context = MigrationContext.configure(connection, opts={"include_object": included})
        assert compare_metadata(context, Base.metadata) == []
    # Triggers created by migrations must also match isolated model-based tests.
    with sqlite3.connect(path) as migrated, test_engine.connect() as model_connection:
        sql = "SELECT name,sql FROM sqlite_master WHERE type='trigger' AND name LIKE 'trg_financial_%' ORDER BY name"
        normalize = lambda rows: [(name, " ".join(code.replace("IF NOT EXISTS", "").split())) for name, code in rows]
        assert normalize(migrated.execute(sql).fetchall()) == normalize(model_connection.exec_driver_sql(sql).fetchall())
    with Session(engine) as db:
        source = service.create_source(db, FinancialSourceCreate(
            source_type="BANK_ACCOUNT", financial_account_id="migration-bank", name="Conta PJ", institution="Banco exemplo", holder_type="PJ",
        ), "migration-device")
        document = service.store_document(db, b"date,amount\n2024-06-10,-40.00", "example.csv", "text/csv", "migration-device")["document"]
        statement = service.create_statement(db, FinancialStatementCreate(
            document_id=document["id"], source_id=source["id"], statement_type="BANK_STATEMENT",
            items=[{"position": 1, "data": {"transaction_date": "2024-06-10", "amount_cents": -4000, "description": "Pagamento"}}],
        ), "migration-device")["statement"]
        from app.models.financial_imports import FinancialStatementItem
        from sqlalchemy import select
        item = db.scalar(select(FinancialStatementItem).where(FinancialStatementItem.statement_id == statement["id"]))
        tx = service.review_item(db, item.id, FinancialItemReview(action="NEW", reason="Conferido"), "migration-device")["transaction"]
        entry_id = db.execute(text("SELECT id FROM cash_flow_entries WHERE source_id=:id"), {"id": payment_id}).scalar_one()
        service.create_reconciliation(db, FinancialReconciliationCreate(
            transaction_id=tx["id"], cash_flow_entry_id=entry_id, amount_cents=4000, reason="Pagamento existente",
        ), "migration-device")
        db.commit()
    assert snapshot(path, before.keys()) == before
    with pytest.raises(RuntimeError, match="preserve history"):
        command.downgrade(cfg, "f9c0d1e2f309")
    with sqlite3.connect(path) as db:
        assert db.execute("SELECT COUNT(*) FROM financial_documents").fetchone() == (1,)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []
    engine.dispose()


def test_empty_migration_can_be_reversed_without_touching_prior_tables(tmp_path):
    path = tmp_path / "empty.db"
    cfg = config(path)
    command.upgrade(cfg, "f9c0d1e2f309")
    before = snapshot(path)
    command.upgrade(cfg, "head")
    command.downgrade(cfg, "f9c0d1e2f309")
    assert snapshot(path) == before
    command.upgrade(cfg, "head")
    assert snapshot(path, before.keys()) == before


def test_csv_migration_preserves_populated_financial_evidence_with_foreign_keys_on(tmp_path, monkeypatch):
    path = tmp_path / "existing-evidence.db"
    cfg = config(path)
    command.upgrade(cfg, "fa0d1e2f4310")
    engine = create_db_engine("sqlite:///" + path.as_posix())
    now = datetime.datetime(2025, 7, 10)
    with Session(engine) as db:
        db.add(PairedDevice(id="reader-device", device_name="Teste", device_public_id="reader-test", token_hash="synthetic-hash"))
        db.add(FinancialAccount(id="reader-bank", name="Banco antigo", account_type="BANK", initial_balance_cents=50000, current_balance_cents=50000))
        db.commit()
        source = service.create_source(db, FinancialSourceCreate(source_type="BANK_ACCOUNT", financial_account_id="reader-bank",
            name="Conta antiga", institution="Outro banco", holder_type="PJ"), "reader-device")
        document = service.store_document(db, b"Data;Valor;Descricao\n10/07/2025;-40,00;Exemplo\n", "before.csv", "text/csv", "reader-device")["document"]
        db.commit()
    # Seed using the reflected previous schema, never a future model's columns.
    metadata = sa.MetaData()
    metadata.reflect(engine)
    with engine.begin() as db:
        db.execute(metadata.tables["financial_statements"].insert().values(id="old-statement", document_id=document["id"],
            source_id=source["id"], statement_type="BANK_STATEMENT", payload_sha256="a" * 64, created_by="reader-device", created_at=now))
        db.execute(metadata.tables["financial_transactions"].insert().values(id="old-transaction", source_id=source["id"],
            external_id_namespace="bank:transaction", external_id="old-id", transaction_date=now.date(), date_kind="AS_REPORTED",
            amount_cents=-4000, description="Transacao antiga", transaction_kind="OTHER", created_by="reader-device", created_at=now))
        db.execute(metadata.tables["financial_transaction_identities"].insert().values(id="old-identity", source_id=source["id"],
            transaction_id="old-transaction", namespace="bank:transaction", external_id="old-id"))
        db.execute(metadata.tables["financial_statement_items"].insert().values(id="old-item", statement_id="old-statement", position=1,
            raw_text="Texto original", normalized_data={"transaction_date": "2025-07-10", "amount_cents": -4000, "description": "Transacao antiga"},
            review_status="NEW", transaction_id="old-transaction", reviewed_by="reader-device", reviewed_at=now))
    # Snapshot old columns: the only differences allowed are new nullable columns.
    def old_values():
        with engine.connect() as db:
            return {name: db.execute(sa.select(table).order_by(*table.primary_key.columns)).all() for name, table in metadata.tables.items()
                    if name != "alembic_version"}
    before = old_values()
    with engine.connect() as db:
        old_triggers = db.exec_driver_sql("SELECT name,sql FROM sqlite_master WHERE type='trigger' ORDER BY name").all()
    # Exercise this additive revision under the application's real FK/transaction
    # configuration rather than relying on SQLite's foreign_keys=OFF default.
    monkeypatch.setattr(sa, "engine_from_config", lambda *args, **kwargs: create_db_engine("sqlite:///" + path.as_posix()))
    command.upgrade(cfg, "head")
    assert old_values() == before
    with engine.connect() as db:
        assert db.exec_driver_sql("PRAGMA foreign_keys").scalar() == 1
        assert db.exec_driver_sql("PRAGMA foreign_key_check").all() == []
        assert db.exec_driver_sql("PRAGMA integrity_check").scalar() == "ok"
        assert all(row in db.exec_driver_sql("SELECT name,sql FROM sqlite_master WHERE type='trigger' ORDER BY name").all() for row in old_triggers)
        assert db.exec_driver_sql("SELECT purchase_date,booking_date FROM financial_transactions").one() == (None, None)
    from app.schemas.financial_readers import FinancialPreviewCreate, FinancialPreviewConfirm
    from app.services.financial_previews import create_preview, confirm_preview
    with Session(engine) as db:
        p = create_preview(db, document["id"], FinancialPreviewCreate(source_id=source["id"], currency="BRL", reader_id="generic_csv", options={
            "columns": {"transaction_date": "Data", "amount": "Valor", "description": "Descricao"},
            "delimiter": ";", "date_format": "DD/MM/YYYY", "decimal_separator": ",", "amount_convention": "CREDITS_POSITIVE",
        }), "reader-device")["preview"]
        s = confirm_preview(db, p["id"], FinancialPreviewConfirm(expected_source_id=source["id"], expected_result_sha256=p["result_sha256"],
            statement_type="BANK_STATEMENT"), "reader-device")["statement"]
        db.commit()
        assert s["preview_id"] == p["id"]
    with pytest.raises(RuntimeError, match="preserve history"):
        command.downgrade(cfg, "fa0d1e2f4310")
    with engine.connect() as db:
        assert db.exec_driver_sql("SELECT version_num FROM alembic_version").scalar() == "fb1e2f3a5411"
    engine.dispose()
