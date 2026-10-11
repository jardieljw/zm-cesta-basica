import os
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.backup import create_backup, restore_backup, list_backups, BackupError
from app.api.deps import get_current_device
from app.models.auth import PairedDevice
from app.schemas.backup import (
    BackupCreateResponse,
    BackupItem,
    BackupRestoreRequest,
    BackupRestoreResponse,
)

router = APIRouter()

@router.post("/backup/create", response_model=BackupCreateResponse)
def trigger_backup(
    current_device: PairedDevice = Depends(get_current_device),
):
    """Creates a verified external backup file using SQLite online backup API."""
    try:
        res = create_backup()
        return BackupCreateResponse(
            status=res["status"],
            backup_filename=res["backup_filename"],
            backup_path=res["backup_path"],
            size_bytes=res["size_bytes"],
            integrity_ok=res["integrity_ok"],
            created_at=res["created_at"],
        )
    except BackupError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Falha ao gerar backup: {str(e)}",
        )

@router.get("/backup/list", response_model=List[BackupItem])
def get_backups(
    current_device: PairedDevice = Depends(get_current_device),
):
    """Lists all available backup files."""
    backups = list_backups()
    return [
        BackupItem(
            filename=b["filename"],
            path=b["path"],
            size_bytes=b["size_bytes"],
            modified_at=b["modified_at"],
        )
        for b in backups
    ]

@router.post("/backup/restore", response_model=BackupRestoreResponse)
def trigger_restore(
    req: BackupRestoreRequest,
    current_device: PairedDevice = Depends(get_current_device),
):
    """Restores database from an existing backup after verifying integrity."""
    backup_file = settings.BACKUP_DIR / req.backup_filename
    if not backup_file.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Arquivo de backup nao encontrado: {req.backup_filename}",
        )

    try:
        res = restore_backup(backup_file)
        from app.core.database import engine
        engine.dispose()
        return BackupRestoreResponse(
            status=res["status"],
            restored_from=res["restored_from"],
            target_path=res["target_path"],
            integrity_ok=res["integrity_ok"],
            restored_at=res["restored_at"],
        )
    except BackupError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Falha ao restaurar backup: {str(e)}",
        )
