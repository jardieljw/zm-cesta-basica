import os
import tempfile
import uuid
import datetime
from pathlib import Path
from typing import Generator
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session

from app.core.config import settings
from app.core.database import get_db, configure_sqlite_pragmas, enforce_begin_immediate
from app.core.security import generate_self_signed_cert, generate_device_token, hash_token
from app.models import Base, PairedDevice
from app.main import app

@pytest.fixture(scope="session")
def test_temp_dir():
    with tempfile.TemporaryDirectory() as td:
        yield Path(td)

@pytest.fixture(scope="function")
def test_db_path(tmp_path):
    return tmp_path / "test_estoque.db"

@pytest.fixture(scope="function")
def test_engine(test_db_path):
    db_url = f"sqlite:///{test_db_path.as_posix()}"
    engine = create_engine(
        db_url,
        connect_args={"check_same_thread": False},
    )
    event.listen(engine, "connect", configure_sqlite_pragmas)
    event.listen(engine, "begin", enforce_begin_immediate)

    Base.metadata.create_all(bind=engine)
    yield engine
    engine.dispose()

@pytest.fixture(scope="function")
def test_session(test_engine) -> Generator[Session, None, None]:
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, expire_on_commit=False, bind=test_engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

@pytest.fixture(scope="function")
def client(test_engine, test_session, tmp_path) -> Generator[TestClient, None, None]:
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    def override_get_db():
        session = TestingSessionLocal()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db

    # Ensure certs exist in temporary location for tests
    test_certs = tmp_path / "certs"
    test_certs.mkdir(parents=True, exist_ok=True)
    settings.CERTS_DIR = test_certs
    settings.BACKUP_DIR = tmp_path / "backups"
    settings.BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    settings.DATABASE_PATH = Path(test_session.bind.url.database)

    cert_path = test_certs / "server.crt"
    key_path = test_certs / "server.key"
    generate_self_signed_cert(cert_path, key_path)

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()

@pytest.fixture(scope="function")
def authenticated_device(test_session) -> tuple[PairedDevice, str, dict]:
    """Creates a paired device and returns (device_model, raw_token, auth_headers)."""
    raw_token = generate_device_token()
    token_digest = hash_token(raw_token)
    device = PairedDevice(
        id=str(uuid.uuid4()),
        device_name="Terminal Teste",
        device_public_id=f"device-{uuid.uuid4().hex[:8]}",
        token_hash=token_digest,
        is_active=True,
        paired_at=datetime.datetime.now(datetime.timezone.utc),
        last_seen_at=datetime.datetime.now(datetime.timezone.utc),
    )
    test_session.add(device)
    test_session.commit()

    headers = {"Authorization": f"Bearer {raw_token}"}
    return device, raw_token, headers
