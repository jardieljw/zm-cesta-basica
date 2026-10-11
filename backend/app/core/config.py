import os
from pathlib import Path
from pydantic import BaseModel

BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseModel):
    PROJECT_NAME: str = "ZM Cesta Basica - API Local"
    VERSION: str = "0.1.0"
    API_V1_PREFIX: str = "/api/v1"

    DATA_DIR: Path = BASE_DIR / "data"
    BACKUP_DIR: Path = BASE_DIR / "backups"
    CERTS_DIR: Path = BASE_DIR / "certs"

    DATABASE_PATH: Path = BASE_DIR / "data" / "estoque.db"
    DATABASE_URL: str = f"sqlite:///{DATABASE_PATH.as_posix()}"

    HOST: str = "0.0.0.0"
    PORT: int = 8000
    PAIRING_PIN_EXPIRES_MINUTES: int = 5
    BUSY_TIMEOUT_MS: int = 5000

    SQLITE_SYNCHRONOUS: str = "FULL"
    SQLITE_JOURNAL_MODE: str = "WAL"

    def ensure_directories(self) -> None:
        self.DATA_DIR.mkdir(parents=True, exist_ok=True)
        self.BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        self.CERTS_DIR.mkdir(parents=True, exist_ok=True)

settings = Settings()
