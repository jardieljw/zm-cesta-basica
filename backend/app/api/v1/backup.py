import os
from typing import List
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Header
from secrets import compare_digest
from app.core.database import get_db
from app.core.security import hash_token
from app.core.new_database import create_and_activate_database
from sqlalchemy import select
from app.models.idempotency import IdempotencyRecord
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
    NewDatabaseRequest, NewDatabaseResponse,
)

router = APIRouter()

@router.post('/backup/new-database', response_model=NewDatabaseResponse)
def new_database(req: NewDatabaseRequest,
                 authorization: Optional[str] = Header(None),
                 key: str = Header(..., alias='X-Idempotency-Key'),
                 current_device: PairedDevice = Depends(get_current_device),
                 db: Session = Depends(get_db)):
    parts = (authorization or '').split()
    if len(parts) != 2 or parts[0].lower() != 'bearer' or not compare_digest(hash_token(parts[1]), current_device.token_hash):
        raise HTTPException(401, detail={'error_code': 'UNAUTHORIZED', 'message': 'Token valido obrigatorio.'})
    if not key.strip() or len(key) > 100:
        raise HTTPException(422, detail={'error_code': 'VALIDATION_ERROR', 'message': 'Chave de operacao invalida.'})
    bind = db.get_bind()
    db.close()
    try:
        return create_and_activate_database(bind, key.strip(), req.model_dump())
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(500, detail={'error_code': 'NEW_DATABASE_FAILED',
            'message': 'Nao foi possivel ativar o novo banco. O backup de seguranca foi preservado.'})

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
    db: Session = Depends(get_db),
):
    """Restores database from an existing backup after verifying integrity.

    Antes de sobrescrever o banco, gera automaticamente um backup de segurança
    (tag 'pre_restore') do estado atual, permitindo desfazer a restauração.
    """
    safe_name = os.path.basename(req.backup_filename)
    if safe_name != req.backup_filename or not safe_name.lower().endswith(".db"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nome de arquivo de backup invalido.",
        )

    backup_file = settings.BACKUP_DIR / safe_name
    if not backup_file.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Arquivo de backup nao encontrado: {req.backup_filename}",
        )

    try:
        bind = db.get_bind()
        db.close()
        # Maintenance receipts survive restoration too: a lost response must not
        # re-execute a database replacement after an operator restored old data.
        with Session(bind) as receipt_db:
            receipts = receipt_db.scalars(select(IdempotencyRecord).where(
                IdempotencyRecord.operation_type == 'NEW_DATABASE')).all()
            receipt_data = [{column.name: getattr(record, column.name)
                for column in IdempotencyRecord.__table__.columns} for record in receipts]
        bind.dispose()
        safety = create_backup(tag="pre_restore")
        res = restore_backup(backup_file)
        bind.dispose()
        with Session(bind) as receipt_db:
            for record in receipt_data:
                exists = receipt_db.scalar(select(IdempotencyRecord).where(
                    IdempotencyRecord.idempotency_key == record['idempotency_key']))
                if exists is None:
                    receipt_db.add(IdempotencyRecord(**record))
            receipt_db.commit()
        return BackupRestoreResponse(
            status=res["status"],
            restored_from=res["restored_from"],
            target_path=res["target_path"],
            integrity_ok=res["integrity_ok"],
            restored_at=res["restored_at"],
            safety_backup_filename=safety["backup_filename"],
        )
    except BackupError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Falha ao restaurar backup: {str(e)}",
        )
