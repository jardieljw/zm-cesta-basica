import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class ProductionBatch(Base):
    __tablename__ = "production_batches"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    batch_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False, index=True)
    recipe_version_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("recipe_versions.id"), nullable=True, index=True)
    quantity_produced: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="CONFIRMED", index=True) # CONFIRMED, DISASSEMBLED, CANCELED
    is_custom: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    is_direct_sale: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    custom_description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    occurred_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    unit_cost_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_cost_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    canceled_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime, nullable=True)
    cancellation_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    basket_type: Mapped["app.models.products.BasketType"] = relationship("app.models.products.BasketType")
    recipe_version: Mapped[Optional["app.models.products.RecipeVersion"]] = relationship("app.models.products.RecipeVersion")
    items: Mapped[List["ProductionBatchItem"]] = relationship(back_populates="batch", cascade="all, delete-orphan")

class ProductionBatchItem(Base):
    __tablename__ = "production_batch_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    batch_id: Mapped[str] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=False, index=True)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"), nullable=False, index=True)
    quantity_consumed_base_units: Mapped[int] = mapped_column(Integer, nullable=False)
    section: Mapped[str] = mapped_column(String(50), nullable=False)
    unit_cost_microcents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_cost_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    batch: Mapped["ProductionBatch"] = relationship(back_populates="items")
    product: Mapped["app.models.products.Product"] = relationship("app.models.products.Product")
