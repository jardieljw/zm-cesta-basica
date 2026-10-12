import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine
from app.models import Base
from app.core.security import generate_self_signed_cert, get_local_ip, get_cert_fingerprint
from app.api.v1.router import api_v1_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("zm_backend")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup tasks
    settings.ensure_directories()
    cert_path = settings.CERTS_DIR / "server.crt"
    key_path = settings.CERTS_DIR / "server.key"

    fingerprint, _ = generate_self_signed_cert(cert_path, key_path)
    local_ip = get_local_ip()

    logger.info("=" * 60)
    logger.info(f"Iniciando {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info(f"Endereco Local: https://127.0.0.1:{settings.PORT}")
    logger.info(f"Endereco Rede Wi-Fi: https://{local_ip}:{settings.PORT}")
    logger.info(f"Impressao Digital TLS (SHA-256): {fingerprint}")
    logger.info("=" * 60)

    # Initialize database tables if not existing
    Base.metadata.create_all(bind=engine)
    from sqlalchemy.orm import Session as _Session
    from app.services.financial import ensure_default_financial_account
    with _Session(engine) as _init_db:
        ensure_default_financial_account(_init_db)

    yield

    # Shutdown tasks
    logger.info("Encerrando servidor...")
    engine.dispose()

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_v1_router, prefix=settings.API_V1_PREFIX)

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "online",
        "docs_url": "/docs",
    }
