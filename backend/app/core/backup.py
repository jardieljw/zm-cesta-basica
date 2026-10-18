import os
import sqlite3
import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional
from app.core.config import settings

class BackupError(Exception):
    pass

def check_sqlite_integrity(db_path: Path) -> bool:
    """Verifies SQLite file integrity using PRAGMA integrity_check."""
    if not db_path.exists():
        return False
    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check;")
        rows = cursor.fetchall()
        return len(rows) == 1 and rows[0][0].lower() == "ok"
    except Exception:
        return False
    finally:
        conn.close()

def create_backup(
    source_path: Optional[Path] = None,
    destination_path: Optional[Path] = None,
    tag: str = "manual"
) -> Dict[str, Any]:
    """
    Creates an atomic online backup of the SQLite database using sqlite3.Connection.backup.
    Safely reads both main DB and WAL pages into a separate backup file outside the main DB.
    """
    src = source_path or settings.DATABASE_PATH
    if not src.exists():
        raise BackupError(f"Database source file not found: {src}")

    settings.ensure_directories()

    if destination_path is None:
        timestamp_str = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
        dest = settings.BACKUP_DIR / f"estoque_backup_{tag}_{timestamp_str}.db"
    else:
        dest = destination_path

    dest.parent.mkdir(parents=True, exist_ok=True)

    src_conn = sqlite3.connect(src)
    dst_conn = sqlite3.connect(dest)
    try:
        with dst_conn:
            src_conn.backup(dst_conn, pages=-1)
    finally:
        dst_conn.close()
        src_conn.close()

    # Validate integrity of the newly created backup
    is_valid = check_sqlite_integrity(dest)
    if not is_valid:
        if dest.exists():
            dest.unlink()
        raise BackupError("Backup file failed SQLite PRAGMA integrity_check.")

    size_bytes = dest.stat().st_size

    return {
        "status": "success",
        "backup_path": str(dest.resolve()),
        "backup_filename": dest.name,
        "size_bytes": size_bytes,
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "integrity_ok": is_valid,
    }

def restore_backup(
    backup_path: Path,
    target_path: Optional[Path] = None
) -> Dict[str, Any]:
    """
    Restores database from an external backup file.
    Validates backup integrity before and after restoration.
    """
    if not backup_path.exists():
        raise BackupError(f"Backup file not found: {backup_path}")

    # Check integrity of backup source before touching target
    if not check_sqlite_integrity(backup_path):
        raise BackupError(f"Backup file is corrupted: {backup_path}")

    target = target_path or settings.DATABASE_PATH
    target.parent.mkdir(parents=True, exist_ok=True)

    bck_conn = sqlite3.connect(backup_path)
    tgt_conn = sqlite3.connect(target)
    try:
        with tgt_conn:
            bck_conn.backup(tgt_conn, pages=-1)
    finally:
        tgt_conn.close()
        bck_conn.close()

    if not check_sqlite_integrity(target):
        raise BackupError("Restored target database failed SQLite PRAGMA integrity_check.")

    return {
        "status": "success",
        "restored_from": str(backup_path.resolve()),
        "target_path": str(target.resolve()),
        "restored_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "integrity_ok": True,
    }

def list_backups(backup_dir: Optional[Path] = None) -> List[Dict[str, Any]]:
    """Lists all available backup files."""
    b_dir = backup_dir or settings.BACKUP_DIR
    if not b_dir.exists():
        return []

    files = sorted(b_dir.glob("*.db"), key=lambda p: p.stat().st_mtime, reverse=True)
    results = []
    for f in files:
        results.append({
            "filename": f.name,
            "path": str(f.resolve()),
            "size_bytes": f.stat().st_size,
            "modified_at": datetime.datetime.fromtimestamp(f.stat().st_mtime, datetime.timezone.utc).isoformat(),
        })
    return results
