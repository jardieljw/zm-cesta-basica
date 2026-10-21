import sqlite3
from contextlib import closing
import pytest
from alembic import command
from test_financial_imports_migration import config


def snapshot(path):
    with closing(sqlite3.connect(path)) as db:
        return {name: (tuple(c[1] for c in db.execute('PRAGMA table_info("'+name+'")')),
            db.execute('SELECT * FROM "'+name+'" ORDER BY rowid').fetchall())
            for name, in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name!='alembic_version'")}


def test_catalog_migration_preserves_existing_rows_and_undoes_only_unused_columns(tmp_path):
    source=tmp_path/'catalog.db'
    command.upgrade(config(source),'f17e8f901037')
    with closing(sqlite3.connect(source)) as db:
        db.execute("INSERT INTO products (id,name,category,base_unit,minimum_stock,cost_price_cents,cost_price_microcents,sale_price_cents,is_active,created_at,updated_at) VALUES ('rice','Arroz','ALIMENTACAO','UNIT',0,100,1000000,200,1,'2026-10-20','2026-10-20')")
        db.commit()
    before=snapshot(source)
    command.upgrade(config(source),'head')
    with closing(sqlite3.connect(source)) as db:
        for table,(columns,rows) in before.items():
            sql='SELECT '+','.join('"'+c+'"' for c in columns)+' FROM "'+table+'" ORDER BY rowid'
            assert db.execute(sql).fetchall()==rows
        assert db.execute('SELECT removed_at FROM products').fetchone()==(None,)
        assert db.execute('PRAGMA foreign_key_check').fetchall()==[]
        assert db.execute('PRAGMA integrity_check').fetchone()==('ok',)
    command.downgrade(config(source),'f17e8f901037')
    assert snapshot(source)==before


def test_catalog_migration_refuses_to_erase_recorded_removals(tmp_path):
    path=tmp_path/'recorded.db'
    command.upgrade(config(path),'head')
    with closing(sqlite3.connect(path)) as db:
        db.execute("INSERT INTO products (id,name,category,base_unit,minimum_stock,cost_price_cents,cost_price_microcents,sale_price_cents,is_active,created_at,updated_at,removed_at) VALUES ('rice','Arroz','ALIMENTACAO','UNIT',0,100,1000000,200,0,'2026-10-20','2026-10-20','2026-10-20')")
        db.commit()
    before=snapshot(path)
    with pytest.raises(RuntimeError,match='exclusões'):
        command.downgrade(config(path),'f17e8f901037')
    assert snapshot(path)==before
