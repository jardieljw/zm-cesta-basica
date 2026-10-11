import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class ProductionBatch(Base):
    __tablename__ = "production_batches"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    batch_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False)
    recipe_version_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("recipe_versions.id"), nullable=True)
    quantity_produced: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="CONFIRMED") # CONFIRMED, CANCELED
    is_custom: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_direct_sale: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    custom_description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    occurred_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    items: Mapped[List["ProductionBatchItem"]] = relationship(back_populates="batch", cascade="all, delete-orphan")

class ProductionBatchItem(Base):
    __tablename__ = "production_batch_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    batch_id: Mapped[str] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=False)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"), nullable=False)
    quantity_consumed_base_units: Mapped[int] = mapped_column(Integer, nullable=False)
    section: Mapped[str] = mapped_column(String(50), nullable=False)

    batch: Mapped["ProductionBatch"] = relationship(back_populates="items")
