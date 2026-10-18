import datetime
from typing import List, Optional, Literal
from pydantic import BaseModel

class BackupCreateResponse(BaseModel):
    status: str
    backup_filename: str
    backup_path: str
    size_bytes: int
    integrity_ok: bool
    created_at: str

class BackupItem(BaseModel):
    filename: str
    path: str
    size_bytes: int
    modified_at: str

class BackupRestoreRequest(BaseModel):
    backup_filename: str

class BackupRestoreResponse(BaseModel):
    status: str
    restored_from: str
    target_path: str
    integrity_ok: bool
    restored_at: str
    safety_backup_filename: Optional[str] = None

class NewDatabaseRequest(BaseModel):
    confirmation: Literal['NOVO BANCO']

class NewDatabaseResponse(BaseModel):
    status: str
    active_database_path: str
    safety_backup_filename: str
    safety_backup_path: str
    integrity_ok: bool
    message: str
    operation_replayed: bool = False
