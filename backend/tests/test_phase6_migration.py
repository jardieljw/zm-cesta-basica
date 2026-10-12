import tempfile
from pathlib import Path
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect


def test_alembic_phase6_migration_upgrade_and_downgrade(tmp_path: Path):
    """Verifies that Alembic migration f6a7b8c9d006 upgrades and downgrades cleanly on SQLite."""
    test_db = tmp_path / "migration_test_p6.db"
    db_url = f"sqlite:///{test_db.as_posix()}"

    backend_dir = Path(__file__).resolve().parent.parent
    alembic_ini = backend_dir / "alembic.ini"

    cfg = Config(str(alembic_ini))
    cfg.set_main_option("sqlalchemy.url", db_url)
    cfg.set_main_option("script_location", str(backend_dir / "alembic"))

    # Upgrade to head (f6a7b8c9d006)
    command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    assert "responsible_persons" in tables
    assert "stock_dispatches" in tables
    assert "dispatch_items" in tables
    assert "dispatch_returns" in tables
    assert "dispatch_losses" in tables
    assert "dispatch_expenses" in tables
    assert "dispatch_repayments" in tables
    assert "dispatch_settlements" in tables

    inv_cols = {c["name"] for c in inspector.get_columns("inventory_movements")}
    assert "location_type" in inv_cols
    assert "responsible_person_id" in inv_cols

    sales_cols = {c["name"] for c in inspector.get_columns("sales")}
    assert "dispatch_id" in sales_cols
    assert "responsible_person_id" in sales_cols

    rec_cols = {c["name"] for c in inspector.get_columns("receivable_payments")}
    assert "dispatch_id" in rec_cols

    # Downgrade back to Phase 5 (f5a6b7c8d905)
    command.downgrade(cfg, "f5a6b7c8d905")

    inspector_down = inspect(engine)
    tables_down = inspector_down.get_table_names()
    assert "responsible_persons" not in tables_down
    assert "stock_dispatches" not in tables_down
    assert "dispatch_items" not in tables_down
    assert "dispatch_returns" not in tables_down
    assert "dispatch_losses" not in tables_down
    assert "dispatch_expenses" not in tables_down
    assert "dispatch_repayments" not in tables_down
    assert "dispatch_settlements" not in tables_down

    engine.dispose()
