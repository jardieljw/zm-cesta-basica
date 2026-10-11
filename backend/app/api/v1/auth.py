import json
import uuid
import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    generate_pin_code,
    generate_device_token,
    hash_token,
    get_cert_fingerprint,
    generate_self_signed_cert,
    get_local_ip,
)
from app.models.auth import PairedDevice, PairingSession
from app.models.base import utc_now
from app.schemas.auth import (
    PairingInitiateResponse,
    PairingRequest,
    PairingResponse,
    PairedDeviceItem,
    DeviceRevokeRequest,
    DeviceRevokeResponse,
)
from app.api.deps import get_current_device

router = APIRouter()

@router.post("/pairing/initiate", response_model=PairingInitiateResponse)
def initiate_pairing(db: Session = Depends(get_db)):
    """
    Generates a temporary, ephemeral 6-digit PIN and QR Code payload.
    The QR Code only contains discovery metadata (host, port, TLS fingerprint, ephemeral PIN).
    Permanent tokens are NEVER exposed via QR Code.
    """
    cert_path = settings.CERTS_DIR / "server.crt"
    key_path = settings.CERTS_DIR / "server.key"

    if not cert_path.exists():
        fingerprint, _ = generate_self_signed_cert(cert_path, key_path)
    else:
        fingerprint = get_cert_fingerprint(cert_path)

    now = utc_now()
    expires_at = now + datetime.timedelta(minutes=settings.PAIRING_PIN_EXPIRES_MINUTES)

    # Clean up stale/expired or already used pairing sessions to prevent table bloat and PIN collisions
    db.execute(
        delete(PairingSession).where(
            (PairingSession.is_used == True) | (PairingSession.expires_at < now)
        )
    )
    db.flush()

    # Generate a non-colliding ephemeral PIN code
    pin = None
    for _ in range(10):
        candidate_pin = generate_pin_code()
        existing = db.execute(
            select(PairingSession).where(PairingSession.pin_code == candidate_pin)
        ).scalar_one_or_none()
        if existing is None:
            pin = candidate_pin
            break

    if pin is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Nao foi possivel gerar PIN unico no momento. Tente novamente."
        )

    session_record = PairingSession(
        id=str(uuid.uuid4()),
        pin_code=pin,
        expires_at=expires_at,
        is_used=False,
        created_at=now,
    )
    db.add(session_record)
    db.commit()

    local_ip = get_local_ip()
    server_url = f"https://{local_ip}:{settings.PORT}"

    qr_data = {
        "server_url": server_url,
        "tls_fingerprint_sha256": fingerprint,
        "pin_code": pin,
        "expires_at": expires_at.isoformat(),
    }

    return PairingInitiateResponse(
        pin_code=pin,
        expires_at=expires_at,
        server_url=server_url,
        tls_fingerprint_sha256=fingerprint,
        qr_payload=json.dumps(qr_data),
    )

@router.post("/pairing/confirm", response_model=PairingResponse)
def confirm_pairing(req: PairingRequest, db: Session = Depends(get_db)):
    """
    Confirms device pairing using the ephemeral PIN.
    Issues a cryptographically random Bearer token returned once to the client.
    The server stores ONLY the SHA-256 hash of the token.
    """
    now = utc_now()
    session_record = db.execute(
        select(PairingSession)
        .where(
            PairingSession.pin_code == req.pin_code,
            PairingSession.is_used == False,
        )
        .order_by(PairingSession.created_at.desc())
    ).scalars().first()

    if session_record is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="PIN invalido ou ja utilizado.",
        )

    exp = session_record.expires_at
    if exp.tzinfo is None and now.tzinfo is not None:
        exp = exp.replace(tzinfo=datetime.timezone.utc)

    if exp < now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O PIN informado expirou. Gere um novo PIN no servidor.",
        )

    # Invalidate the PIN session immediately
    session_record.is_used = True

    # Generate permanent random token for this device
    raw_token = generate_device_token()
    token_digest = hash_token(raw_token)

    # Upsert paired device record
    device = db.execute(
        select(PairedDevice).where(PairedDevice.device_public_id == req.device_public_id)
    ).scalar_one_or_none()

    if device is not None:
        device.device_name = req.device_name
        device.token_hash = token_digest
        device.is_active = True
        device.last_seen_at = utc_now()
    else:
        device = PairedDevice(
            id=str(uuid.uuid4()),
            device_name=req.device_name,
            device_public_id=req.device_public_id,
            token_hash=token_digest,
            is_active=True,
            paired_at=utc_now(),
            last_seen_at=utc_now(),
        )
        db.add(device)

    db.commit()
    db.refresh(device)

    return PairingResponse(
        device_id=device.id,
        device_name=device.device_name,
        device_public_id=device.device_public_id,
        device_token=raw_token,
        message="Pareamento realizado com sucesso. Armazene o token de forma segura.",
    )

@router.get("/devices", response_model=List[PairedDeviceItem])
def list_paired_devices(
    current_device: PairedDevice = Depends(get_current_device),
    db: Session = Depends(get_db)
):
    """Lists all paired devices registered in the server."""
    devices = db.execute(select(PairedDevice).order_by(PairedDevice.paired_at.desc())).scalars().all()
    return [
        PairedDeviceItem(
            id=d.id,
            device_name=d.device_name,
            device_public_id=d.device_public_id,
            is_active=d.is_active,
            paired_at=d.paired_at,
            last_seen_at=d.last_seen_at,
        )
        for d in devices
    ]

@router.post("/devices/revoke", response_model=DeviceRevokeResponse)
def revoke_device(
    req: DeviceRevokeRequest,
    current_device: PairedDevice = Depends(get_current_device),
    db: Session = Depends(get_db)
):
    """Revokes a paired device. Revoked devices immediately fail authentication with 401."""
    device = db.execute(
        select(PairedDevice).where(PairedDevice.device_public_id == req.device_public_id)
    ).scalar_one_or_none()

    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dispositivo nao encontrado para revogacao.",
        )

    device.is_active = False
    db.commit()

    return DeviceRevokeResponse(
        device_public_id=device.device_public_id,
        is_active=device.is_active,
        message=f"Dispositivo '{device.device_name}' revogado com sucesso.",
    )
