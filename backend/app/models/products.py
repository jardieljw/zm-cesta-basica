import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, Boolean, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class Product(Base):
    __tablename__ = "products"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    sku: Mapped[Optional[str]] = mapped_column(String(100), unique=True, nullable=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False) # ALIMENTACAO, LIMPEZA, CARNE, OUTROS
    base_unit: Mapped[str] = mapped_column(String(20), nullable=False) # UNIT, G, ML
    minimum_stock: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    barcode: Mapped[Optional[str]] = mapped_column(String(50), unique=True, nullable=True)
    cost_price_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    cost_price_microcents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    sale_price_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    packagings: Mapped[List["ProductPackaging"]] = relationship(back_populates="product", cascade="all, delete-orphan")

class ProductPackaging(Base):
    __tablename__ = "product_packagings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False) # Ex: "Saco 5 kg", "Fardo c/ 10 un"
    quantity_in_base_units: Mapped[int] = mapped_column(Integer, nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    product: Mapped["Product"] = relationship(back_populates="packagings")

class BasketType(Base):
    __tablename__ = "basket_types"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False) # BASICA_COMPLETA, CARNE, PERSONALIZADA
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    category: Mapped[str] = mapped_column(String(50), default="PADRAO", nullable=False)
    default_price_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    allows_customization: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    tracks_finished_stock: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    removed_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime, nullable=True)

    recipes: Mapped[List["RecipeVersion"]] = relationship(back_populates="basket_type")

class RecipeVersion(Base):
    __tablename__ = "recipe_versions"
    __table_args__ = (
        UniqueConstraint("basket_type_id", "version_number", name="uq_basket_recipe_version"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False)
    version_number: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="ACTIVE") # ACTIVE, ARCHIVED
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    basket_type: Mapped["BasketType"] = relationship(back_populates="recipes")
    items: Mapped[List["RecipeItem"]] = relationship(back_populates="recipe_version", cascade="all, delete-orphan")

class RecipeItem(Base):
    __tablename__ = "recipe_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    recipe_version_id: Mapped[str] = mapped_column(String(36), ForeignKey("recipe_versions.id"), nullable=False)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"), nullable=False)
    quantity_in_base_units: Mapped[int] = mapped_column(Integer, nullable=False)
    section: Mapped[str] = mapped_column(String(50), nullable=False) # ALIMENTACAO, LIMPEZA, CARNE
    is_required: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    recipe_version: Mapped["RecipeVersion"] = relationship(back_populates="items")
    product: Mapped["Product"] = relationship()
