from pydantic import BaseModel
import datetime

class HealthResponse(BaseModel):
    status: str
    version: str
    database_status: str
    tls_fingerprint_sha256: str
    timestamp: datetime.datetime
