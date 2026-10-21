"""E4 migration: populated copy, schema parity, immutable rows, invalid writes and safe rollback."""
import sqlite3
from contextlib import closing
from alembic import command
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
import pytest
from test_financial_imports_migration import config, snapshot
from test_financial_bill_cycles import api, bill, integrate


def test_e4_populated_copy_migration_preserves_all_history(tmp_path):
    original=tmp_path/'original.db';copy=tmp_path/'copy.db'
    command.upgrade(config(original),'ff5c6d7e9815')
    with closing(sqlite3.connect(original)) as db:
        db.execute("INSERT INTO accounts_payable(id,payable_number,description,beneficiary,category,nature,original_amount_cents,paid_amount_cents,balance_cents,due_date,payment_method,status,installment_number,total_installments,is_recurrent,created_at,updated_at) VALUES ('old',1,'Antiga','Loja','OUTROS','BUSINESS',10001,1,10000,'2026-10-31','PIX','PARTIAL',1,1,0,'2026-01-01','2026-01-01')")
        db.commit()
        tables=[r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name != 'alembic_version'")]
        before={t:db.execute('SELECT * FROM '+t).fetchall() for t in tables}
        protections=db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('trigger','index')").fetchall()
        with closing(sqlite3.connect(copy)) as target:db.backup(target)
    command.upgrade(config(copy),'head')
    with closing(sqlite3.connect(copy)) as db:
        assert {t:db.execute('SELECT * FROM '+t).fetchall() for t in tables}==before
        assert all(r in db.execute("SELECT type,name,sql FROM sqlite_master WHERE type IN ('trigger','index')").fetchall() for r in protections if r[1] != 'trg_substituted_payable_guard')
        assert db.execute('PRAGMA integrity_check').fetchone()==('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall()==[]
        for t in ('series','occurrences','forecasts','decisions'):
            assert db.execute('SELECT COUNT(*) FROM financial_installment_'+t).fetchone()==(0,)
    command.downgrade(config(copy),'ff5c6d7e9815')
    with closing(sqlite3.connect(copy)) as db:assert {t:db.execute('SELECT * FROM '+t).fetchall() for t in tables}==before


def test_e4_invalid_writes_immutability_and_downgrade_refusal(api,test_db_path):
    p,c=bill(api);integrate(api,p,c)
    with closing(sqlite3.connect(test_db_path)) as db:
        db.execute('PRAGMA foreign_keys=ON')
        for statement in ["UPDATE financial_installment_forecasts SET amount_cents=1", "DELETE FROM financial_installment_occurrences",
            "INSERT INTO financial_installment_forecasts(id,series_id,number,reference,amount_cents) SELECT 'bad',id,1000,'2026-13',1 FROM financial_installment_series"]:
            with pytest.raises(sqlite3.IntegrityError):db.execute(statement)
            db.rollback()
        db.execute('CREATE TABLE IF NOT EXISTS alembic_version(version_num VARCHAR(32) NOT NULL PRIMARY KEY)')
        db.execute("INSERT INTO alembic_version VALUES ('f06d7e8f0926')");db.commit()
    with pytest.raises(RuntimeError,match='preserve history'):command.downgrade(config(test_db_path),'ff5c6d7e9815')
