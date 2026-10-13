import os
import sqlite3
import pytest
from pathlib import Path
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from app.core.backup import create_backup, restore_backup, check_sqlite_integrity, BackupError, list_backups
from app.models.base import Base
from app.models.products import Product

def test_backup_and_restore_cycle(tmp_path: Path):
    db_file = tmp_path / "original.db"
    backup_file = tmp_path / "backups" / "backup_test.db"
    restored_file = tmp_path / "restored.db"

    # Setup initial database
    engine = create_engine(f"sqlite:///{db_file.as_posix()}")
    Base.metadata.create_all(bind=engine)

    with Session(engine) as s:
        s.add(Product(
            id="prod-1",
            name="Produto Antes do Backup",
            category="ALIMENTACAO",
            base_unit="UNIT"
        ))
        s.commit()
    engine.dispose()

    # Step 1: Create backup
    res_backup = create_backup(source_path=db_file, destination_path=backup_file)
    assert res_backup["status"] == "success"
    assert res_backup["integrity_ok"] is True
    assert backup_file.exists()
    assert check_sqlite_integrity(backup_file) is True

    # Step 2: Mutate original database after backup
    engine2 = create_engine(f"sqlite:///{db_file.as_posix()}")
    with Session(engine2) as s:
        s.add(Product(
            id="prod-2",
            name="Produto Criado Apos Backup",
            category="LIMPEZA",
            base_unit="UNIT"
        ))
        s.commit()
    engine2.dispose()

    # Step 3: Restore backup to restored_file
    res_restore = restore_backup(backup_path=backup_file, target_path=restored_file)
    assert res_restore["status"] == "success"
    assert res_restore["integrity_ok"] is True

    # Step 4: Verify restored database matches pre-mutation backup state
    engine_restored = create_engine(f"sqlite:///{restored_file.as_posix()}")
    with Session(engine_restored) as s:
        p1 = s.get(Product, "prod-1")
        p2 = s.get(Product, "prod-2")
        assert p1 is not None
        assert p1.name == "Produto Antes do Backup"
        assert p2 is None # prod-2 was created AFTER the backup, so it must NOT be in restored DB
    engine_restored.dispose()

def test_corrupted_backup_is_rejected(tmp_path: Path):
    corrupted_file = tmp_path / "corrupted.db"
    target_file = tmp_path / "target.db"

    # Write corrupt data
    corrupted_file.write_bytes(b"CORRUPTED_NOT_A_SQLITE_DATABASE_HEADER")

    assert check_sqlite_integrity(corrupted_file) is False

    with pytest.raises(BackupError) as exc_info:
        restore_backup(backup_path=corrupted_file, target_path=target_file)

    assert "corrupted" in str(exc_info.value).lower()

def test_backup_api_endpoints(client: TestClient, authenticated_device, tmp_path: Path):
    _, _, headers = authenticated_device

    # Create backup via API
    res_create = client.post("/api/v1/backup/create", headers=headers)
    assert res_create.status_code == 200
    data_create = res_create.json()
    assert data_create["status"] == "success"
    assert data_create["integrity_ok"] is True
    filename = data_create["backup_filename"]

    # List backups via API
    res_list = client.get("/api/v1/backup/list", headers=headers)
    assert res_list.status_code == 200
    list_items = res_list.json()
    assert any(b["filename"] == filename for b in list_items)

    # Restore backup via API
    res_restore = client.post(
        "/api/v1/backup/restore",
        headers=headers,
        json={"backup_filename": filename}
    )
    assert res_restore.status_code == 200
    data_restore = res_restore.json()
    assert data_restore["status"] == "success"
    assert data_restore["integrity_ok"] is True


def test_restore_api_creates_safety_backup_and_rejects_bad_names(client: TestClient, authenticated_device):
    _, _, headers = authenticated_device

    filename = client.post("/api/v1/backup/create", headers=headers).json()["backup_filename"]

    res = client.post("/api/v1/backup/restore", headers=headers, json={"backup_filename": filename})
    assert res.status_code == 200
    safety = res.json()["safety_backup_filename"]
    assert safety and "pre_restore" in safety

    listed = [b["filename"] for b in client.get("/api/v1/backup/list", headers=headers).json()]
    assert safety in listed

    for bad in ["../estoque.db", "sub\\x.db", "arquivo.txt"]:
        r = client.post("/api/v1/backup/restore", headers=headers, json={"backup_filename": bad})
        assert r.status_code == 400

    r = client.post("/api/v1/backup/restore", headers=headers, json={"backup_filename": "nao_existe.db"})
    assert r.status_code == 404
