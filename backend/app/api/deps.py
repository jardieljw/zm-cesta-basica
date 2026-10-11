import datetime
from typing import Optional, Generator
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import hash_token
from app.models.auth import PairedDevice
from app.models.base import utc_now

def get_current_device(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
) -> PairedDevice:
    """
    Validates the Bearer token sent in Authorization header against paired_devices.
    The server only stores SHA-256 token hashes, never raw plaintext tokens.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticacao necessaria. Cabecalho Authorization ausente.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Formato de token invalido. Esperado 'Bearer <token>'.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    raw_token = parts[1]
    computed_hash = hash_token(raw_token)

    device = db.execute(
        select(PairedDevice).where(PairedDevice.token_hash == computed_hash)
    ).scalar_one_or_none()

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Dispositivo nao encontrado ou token invalido.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not device.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Dispositivo revogado. Solicite novo pareamento com o servidor.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    now = utc_now()
    last_seen = device.last_seen_at
    if last_seen is not None and last_seen.tzinfo is None and now.tzinfo is not None:
        last_seen = last_seen.replace(tzinfo=datetime.timezone.utc)

    if last_seen is None or (now - last_seen).total_seconds() >= 60:
        device.last_seen_at = now

    try:
        db.commit()
    except Exception:
        db.rollback()

    return device

def get_idempotency_key(
    x_idempotency_key: Optional[str] = Header(None, alias="X-Idempotency-Key")
) -> Optional[str]:
    """Extracts idempotency key from request header."""
    return x_idempotency_key
