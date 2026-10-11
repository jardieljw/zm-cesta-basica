import datetime
from sqlalchemy import String, Boolean, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, utc_now

class PairedDevice(Base):
    __tablename__ = "paired_devices"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    device_name: Mapped[str] = mapped_column(String(100), nullable=False)
    device_public_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    paired_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    last_seen_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

class PairingSession(Base):
    __tablename__ = "pairing_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    pin_code: Mapped[str] = mapped_column(String(10), unique=True, nullable=False, index=True)
    expires_at: Mapped[datetime.datetime] = mapped_column(DateTime, nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
