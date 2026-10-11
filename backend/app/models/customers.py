import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Boolean, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class Customer(Base):
    __tablename__ = "customers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    document_cpf_cnpj: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    credit_limit_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False) # 0 = no limit / unconstrained
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    sales: Mapped[List["Sale"]] = relationship("Sale", back_populates="customer")
    receivables: Mapped[List["SalesReceivable"]] = relationship("SalesReceivable", back_populates="customer")
