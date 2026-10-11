import datetime
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_cert_fingerprint, generate_self_signed_cert
from app.schemas.health import HealthResponse

router = APIRouter()

@router.get("/health", response_model=HealthResponse)
@router.get("/ping", response_model=HealthResponse)
def get_health(db: Session = Depends(get_db)):
    """Health check endpoint to test server status, database connectivity and TLS fingerprint."""
    cert_path = settings.CERTS_DIR / "server.crt"
    key_path = settings.CERTS_DIR / "server.key"

    if not cert_path.exists():
        fingerprint, _ = generate_self_signed_cert(cert_path, key_path)
    else:
        fingerprint = get_cert_fingerprint(cert_path)

    # Verify database connection
    db_status = "ok"
    try:
        db.execute(text("SELECT 1")).scalar()
    except Exception as e:
        db_status = f"error: {str(e)}"

    return HealthResponse(
        status="ok",
        version=settings.VERSION,
        database_status=db_status,
        tls_fingerprint_sha256=fingerprint,
        timestamp=datetime.datetime.now(datetime.timezone.utc),
    )
