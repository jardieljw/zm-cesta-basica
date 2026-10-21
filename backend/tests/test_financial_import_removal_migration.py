import sqlite3
from contextlib import closing
import pytest
from alembic import command
from test_financial_imports_migration import config


def rows(path):
    with closing(sqlite3.connect(path)) as db:
        return {name:db.execute('SELECT * FROM "'+name+'" ORDER BY rowid').fetchall() for name, in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'") if name!='alembic_version'}


def test_populated_f06_copy_migration_preserves_all_existing_rows_and_empty_downgrade(tmp_path):
    source=tmp_path/'source.db';copy=tmp_path/'copy.db'
    command.upgrade(config(source),'f06d7e8f0926')
    with closing(sqlite3.connect(source)) as db:
        db.execute("INSERT INTO accounts_payable(id,payable_number,description,beneficiary,category,nature,original_amount_cents,paid_amount_cents,balance_cents,due_date,payment_method,status,installment_number,total_installments,is_recurrent,created_at,updated_at) VALUES ('existing',1,'Conta preservada','Fornecedor','OUTROS','BUSINESS',12345,0,12345,'2026-10-24','PIX','OPEN',1,1,0,'2026-10-20','2026-10-20')")
        db.commit()
        with closing(sqlite3.connect(copy)) as target:db.backup(target)
    before=rows(source)
    command.upgrade(config(copy),'f17e8f901037')
    after=rows(copy)
    assert set(after)-set(before)=={'financial_import_removals'}
    assert all(after[name]==data for name,data in before.items())
    with closing(sqlite3.connect(copy)) as db:
        assert db.execute('PRAGMA integrity_check').fetchone()==('ok',)
        assert db.execute('PRAGMA foreign_key_check').fetchall()==[]
    command.downgrade(config(copy),'f06d7e8f0926')
    assert rows(copy)==before and rows(source)==before


def test_recorded_withdrawals_block_destructive_downgrade(api,test_db_path):
    from test_financial_bill_cycles import bill,integrate
    from test_financial_import_removals import remove
    p,c=bill(api);integrate(api,p,c);remove(api,p)
    command.stamp(config(test_db_path),'f17e8f901037')
    before=rows(test_db_path)
    with pytest.raises(RuntimeError,match='recorded import withdrawals'):
        command.downgrade(config(test_db_path),'f06d7e8f0926')
    assert rows(test_db_path)==before

from test_financial_bill_cycles import api
