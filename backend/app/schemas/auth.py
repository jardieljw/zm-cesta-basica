import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

class PairingInitiateResponse(BaseModel):
    pin_code: str
    expires_at: datetime.datetime
    server_url: str
    tls_fingerprint_sha256: str
    qr_payload: str

class PairingRequest(BaseModel):
    pin_code: str = Field(..., min_length=6, max_length=10)
    device_name: str = Field(..., min_length=1, max_length=100)
    device_public_id: str = Field(..., min_length=1, max_length=100)

class PairingResponse(BaseModel):
    device_id: str
    device_name: str
    device_public_id: str
    device_token: str # Returned ONLY ONCE upon pairing confirmation
    message: str

class PairedDeviceItem(BaseModel):
    id: str
    device_name: str
    device_public_id: str
    is_active: bool
    paired_at: datetime.datetime
    last_seen_at: datetime.datetime

class DeviceRevokeRequest(BaseModel):
    device_public_id: str

class DeviceRevokeResponse(BaseModel):
    device_public_id: str
    is_active: bool
    message: str
