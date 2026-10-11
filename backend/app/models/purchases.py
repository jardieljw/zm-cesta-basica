import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Numeric, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class Purchase(Base):
    __tablename__ = "purchases"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    purchase_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="CONFIRMED") # DRAFT, CONFIRMED, CANCELED
    purchase_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    supplier_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    total_amount_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    items: Mapped[List["PurchaseItem"]] = relationship(back_populates="purchase", cascade="all, delete-orphan")

class PurchaseItem(Base):
    __tablename__ = "purchase_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    purchase_id: Mapped[str] = mapped_column(String(36), ForeignKey("purchases.id"), nullable=False)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"), nullable=False)
    packaging_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("product_packagings.id"), nullable=True)
    packages_count: Mapped[float] = mapped_column(Numeric(10, 3), nullable=False)
    quantity_in_base_units: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    total_price_cents: Mapped[int] = mapped_column(Integer, nullable=False)

    purchase: Mapped["Purchase"] = relationship(back_populates="items")
    product: Mapped["app.models.products.Product"] = relationship("app.models.products.Product")
    packaging: Mapped[Optional["app.models.products.ProductPackaging"]] = relationship("app.models.products.ProductPackaging")
