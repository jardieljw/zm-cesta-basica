"""Frozen additive E2 migration, populated copy and full model/schema parity."""
from contextlib import closing
import sqlite3
import pytest
from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from app.models import Base
from app.core.database import create_db_engine
from test_financial_imports_migration import config


def test_t15_populated_copy_migration_preserves_every_old_column_and_schema(tmp_path):
    original=tmp_path/'prior.db'; copied=tmp_path/'copy.db'
    cfg=config(original);command.upgrade(cfg,'fe4b5c6d8714')
    with closing(sqlite3.connect(original)) as db:
        db.execute("""INSERT INTO accounts_payable(id,payable_number,description,beneficiary,category,nature,original_amount_cents,paid_amount_cents,balance_cents,due_date,payment_method,status,installment_number,total_installments,is_recurrent,created_at,updated_at)
          VALUES ('old',1,'Divida antiga','Fornecedor','OUTROS','BUSINESS',10000,4000,6000,'2025-01-10','PIX','PARTIAL',1,1,0,'2025-01-01','2025-01-01')""")
        db.execute("INSERT INTO financial_accounts(id,name,account_type,initial_balance_cents,current_balance_cents,is_active,is_default,created_at,updated_at) VALUES ('bank','Banco','BANK',0,-4000,1,0,'2025-01-01','2025-01-01')")
        db.execute("INSERT INTO payable_payments(id,payable_id,account_id,payment_date,amount_cents,payment_method,status,created_at) VALUES ('paid','old','bank','2025-01-02',4000,'PIX','CONFIRMED','2025-01-02')")
        db.commit()
        columns={t:[r[1] for r in db.execute('PRAGMA table_info('+t+')')] for t in ('accounts_payable','payable_payments')}
        before={t:db.execute('SELECT * FROM '+t).fetchall() for t in columns}
        schema=db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('trigger','index')").fetchall()
        with closing(sqlite3.connect(copied)) as target: db.backup(target)
    command.upgrade(config(copied),'head')
    with closing(sqlite3.connect(copied)) as db:
        for table,names in columns.items():
            assert db.execute('SELECT '+','.join(names)+' FROM '+table).fetchall()==before[table]
        assert db.execute('SELECT bill_revision_id,stock_cents,business_cents,personal_cents,unclassified_cents FROM payable_payments').fetchone()==(None,)*5
        after_schema=db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('trigger','index')").fetchall()
        assert all(row in after_schema for row in schema)
        assert db.execute('PRAGMA integrity_check').fetchone()==('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall()==[]
        assert db.execute('SELECT COUNT(*) FROM financial_bill_cycles').fetchone()==(0,)
    engine=create_db_engine('sqlite:///'+copied.as_posix())
    try:
        with engine.connect() as conn:
            # Two pre-existing indexes are absent in the historical ORM. Their
            # preservation is already asserted above, without changing them.
            def include(obj,name,kind,reflected,compare_to):
                return not (kind=='index' and name in {'ix_dispatch_expenses_expense_date','ix_purchases_payment_mode'})
            assert compare_metadata(MigrationContext.configure(conn,opts={'include_object':include}),Base.metadata)==[]
    finally: engine.dispose()
    command.downgrade(config(copied),'fe4b5c6d8714')
    with closing(sqlite3.connect(copied)) as db:
        assert {t:db.execute('SELECT * FROM '+t).fetchall() for t in columns}==before
    with closing(sqlite3.connect(original)) as db:
        assert db.execute('SELECT version_num FROM alembic_version').fetchone()==('fe4b5c6d8714',)
