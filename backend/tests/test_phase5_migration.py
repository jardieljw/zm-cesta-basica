import tempfile
from pathlib import Path
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect


def test_alembic_phase5_migration_upgrade_and_downgrade(tmp_path: Path):
    """Verifies that Alembic migration f5a6b7c8d905 upgrades and downgrades cleanly on SQLite."""
    test_db = tmp_path / "migration_test.db"
    db_url = f"sqlite:///{test_db.as_posix()}"

    backend_dir = Path(__file__).resolve().parent.parent
    alembic_ini = backend_dir / "alembic.ini"

    cfg = Config(str(alembic_ini))
    cfg.set_main_option("sqlalchemy.url", db_url)
    cfg.set_main_option("script_location", str(backend_dir / "alembic"))

    # Upgrade to head (f5a6b7c8d905)
    command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    assert "customers" in tables
    assert "sales" in tables
    assert "sale_items" in tables
    assert "sales_receivables" in tables
    assert "receivable_payments" in tables

    sales_cols = {c["name"] for c in inspector.get_columns("sales")}
    assert "customer_id" in sales_cols
    assert "sale_mode" in sales_cols
    assert "payment_mode" in sales_cols
    assert "payment_status" in sales_cols

    sale_items_cols = {c["name"] for c in inspector.get_columns("sale_items")}
    assert "unit_cost_cents" in sale_items_cols
    assert "total_cost_cents" in sale_items_cols

    # Downgrade back to Phase 4 (e4f5a6b7c804)
    command.downgrade(cfg, "e4f5a6b7c804")

    inspector_down = inspect(engine)
    tables_down = inspector_down.get_table_names()
    assert "customers" not in tables_down
    assert "sales_receivables" not in tables_down
    assert "receivable_payments" not in tables_down

    engine.dispose()
