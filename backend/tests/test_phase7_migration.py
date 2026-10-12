import tempfile
from pathlib import Path
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect, text


def test_alembic_phase7_migration_upgrade_and_downgrade(tmp_path: Path):
    """Verifies that Alembic migration f7a8b9c0d107 upgrades and downgrades cleanly on SQLite."""
    test_db = tmp_path / "migration_test_p7.db"
    db_url = f"sqlite:///{test_db.as_posix()}"

    backend_dir = Path(__file__).resolve().parent.parent
    alembic_ini = backend_dir / "alembic.ini"

    cfg = Config(str(alembic_ini))
    cfg.set_main_option("sqlalchemy.url", db_url)
    cfg.set_main_option("script_location", str(backend_dir / "alembic"))

    # Upgrade to head (f7a8b9c0d107)
    command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    assert "financial_accounts" in tables
    assert "cash_flow_entries" in tables
    assert "accounts_payable" in tables
    assert "payable_payments" in tables

    # Verify seeded default account
    with engine.connect() as conn:
        res = conn.execute(text("SELECT id, name, account_type, is_default FROM financial_accounts")).fetchall()
        assert len(res) >= 1
        assert any(row[1] == "Caixa Físico da Loja" and row[2] == "CASH" and row[3] == 1 for row in res)

    # Verify columns added to sales, receivable_payments, dispatch_repayments, purchases
    sales_cols = {c["name"] for c in inspector.get_columns("sales")}
    assert "account_id" in sales_cols

    rec_cols = {c["name"] for c in inspector.get_columns("receivable_payments")}
    assert "account_id" in rec_cols

    disp_cols = {c["name"] for c in inspector.get_columns("dispatch_repayments")}
    assert "account_id" in disp_cols

    purch_cols = {c["name"] for c in inspector.get_columns("purchases")}
    assert "payment_mode" in purch_cols
    assert "due_date" in purch_cols
    assert "account_id" in purch_cols

    # Verify triggers prevent updates/deletes in SQLite
    with engine.connect() as conn:
        conn.execute(text(
            "INSERT INTO cash_flow_entries (id, account_id, entry_type, amount_cents, category, nature, description, source_type, occurred_at, is_reversal, created_at) "
            "VALUES ('entry-1', '00000000-0000-0000-0000-caixa0000001', 'CREDIT', 1000, 'OUTROS', 'BUSINESS', 'Teste trigger', 'MANUAL', CURRENT_TIMESTAMP, 0, CURRENT_TIMESTAMP)"
        ))
        conn.commit()

        # Update should fail due to trigger
        with pytest.raises(Exception, match="cash_flow_entries is append-only"):
            conn.execute(text("UPDATE cash_flow_entries SET amount_cents = 2000 WHERE id = 'entry-1'"))

        # Delete should fail due to trigger
        with pytest.raises(Exception, match="cash_flow_entries is append-only"):
            conn.execute(text("DELETE FROM cash_flow_entries WHERE id = 'entry-1'"))

    # Downgrade back to Phase 6 (f6a7b8c9d006)
    command.downgrade(cfg, "f6a7b8c9d006")

    inspector_down = inspect(engine)
    tables_down = inspector_down.get_table_names()
    assert "financial_accounts" not in tables_down
    assert "cash_flow_entries" not in tables_down
    assert "accounts_payable" not in tables_down
    assert "payable_payments" not in tables_down

    purch_cols_down = {c["name"] for c in inspector_down.get_columns("purchases")}
    assert "payment_mode" not in purch_cols_down
    assert "due_date" not in purch_cols_down
    assert "account_id" not in purch_cols_down

    engine.dispose()
