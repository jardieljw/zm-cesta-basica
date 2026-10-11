import time
import logging
import sqlite3
from typing import Generator, Callable, TypeVar, Any, Optional
from sqlalchemy import create_engine, event, Engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import OperationalError
from app.core.config import settings

logger = logging.getLogger(__name__)

T = TypeVar("T")

def configure_sqlite_pragmas(dbapi_connection: Any, connection_record: Any) -> None:
    """Configures critical SQLite pragmas for durability, WAL concurrency, and integrity."""
    dbapi_connection.isolation_level = None
    cursor = dbapi_connection.cursor()
    cursor.execute(f"PRAGMA journal_mode = {settings.SQLITE_JOURNAL_MODE};")
    cursor.execute(f"PRAGMA synchronous = {settings.SQLITE_SYNCHRONOUS};")
    cursor.execute(f"PRAGMA busy_timeout = {settings.BUSY_TIMEOUT_MS};")
    cursor.execute("PRAGMA foreign_keys = ON;")
    cursor.close()

def enforce_begin_immediate(conn: Any) -> None:
    """Enforces atomic immediate transactions to acquire SQLite write lock immediately."""
    conn.exec_driver_sql("BEGIN IMMEDIATE")

def create_db_engine(db_url: Optional[str] = None) -> Engine:
    """Factory to create a properly configured SQLite engine."""
    url = db_url or settings.DATABASE_URL
    is_sqlite = url.startswith("sqlite")

    engine = create_engine(
        url,
        connect_args={"check_same_thread": False} if is_sqlite else {},
        pool_pre_ping=True,
    )

    if is_sqlite:
        event.listen(engine, "connect", configure_sqlite_pragmas)
        event.listen(engine, "begin", enforce_begin_immediate)

    return engine

settings.ensure_directories()
engine = create_db_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, expire_on_commit=False, bind=engine)

def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency for obtaining a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def run_with_db_retry(
    operation: Callable[[], T],
    max_retries: int = 5,
    base_delay: float = 0.05
) -> T:
    """
    Executes a callable, catching SQLite transient busy/locked errors
    and retrying with exponential backoff and jitter.
    """
    attempt = 0
    while True:
        try:
            return operation()
        except (OperationalError, sqlite3.OperationalError) as exc:
            msg = str(exc).lower()
            if "locked" in msg or "busy" in msg:
                attempt += 1
                if attempt >= max_retries:
                    logger.error(f"Database locked retry limit reached ({max_retries}). Aborting.")
                    raise
                delay = base_delay * (2 ** (attempt - 1))
                logger.warning(f"Database locked, retrying in {delay:.2f}s (attempt {attempt}/{max_retries})...")
                time.sleep(delay)
            else:
                raise
