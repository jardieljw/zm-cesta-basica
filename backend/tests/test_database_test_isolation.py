from pathlib import Path
import app.main as app_main
import app.core.database as database_module
from app.core.config import settings


def test_startup_and_internal_session_factory_share_temporary_database(client, test_engine, test_db_path):
    assert app_main.engine is test_engine
    assert database_module.engine is test_engine
    assert settings.DATABASE_PATH.resolve() == test_db_path.resolve()
    with database_module.SessionLocal() as session:
        assert session.bind is test_engine
        assert Path(session.bind.url.database).resolve() == test_db_path.resolve()
