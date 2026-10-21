import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, Boolean, event, DDL
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class Sale(Base):
    __tablename__ = "sales"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    sale_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    customer_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("customers.id"), nullable=True, index=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="CONFIRMED", index=True) # CONFIRMED, CANCELED
    sale_mode: Mapped[str] = mapped_column(String(30), nullable=False, default="DIRECT_STORE", index=True) # DIRECT_STORE, COMMERCIAL_ROUTE
    payment_mode: Mapped[str] = mapped_column(String(30), nullable=False, default="CASH_IMMEDIATE", index=True) # CASH_IMMEDIATE, PIX, CARD, CREDIT_TERM
    payment_status: Mapped[str] = mapped_column(String(20), nullable=False, default="PAID", index=True) # PAID, PENDING, PARTIAL
    sale_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    customer_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True) # Snapshot / free-text
    payment_method: Mapped[Optional[str]] = mapped_column(String(50), nullable=True) # Legacy / auxiliary
    total_amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(100), unique=True, nullable=True)
    dispatch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=True, index=True)
    responsible_person_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("responsible_persons.id"), nullable=True, index=True)
    account_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("financial_accounts.id"), nullable=True, index=True)
    canceled_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime, nullable=True)
    cancellation_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    customer: Mapped[Optional["app.models.customers.Customer"]] = relationship("app.models.customers.Customer", back_populates="sales")
    dispatch: Mapped[Optional["app.models.dispatches.StockDispatch"]] = relationship("app.models.dispatches.StockDispatch", back_populates="sales")
    responsible_person: Mapped[Optional["app.models.dispatches.ResponsiblePerson"]] = relationship("app.models.dispatches.ResponsiblePerson")
    financial_account: Mapped[Optional["app.models.financial.FinancialAccount"]] = relationship("app.models.financial.FinancialAccount")
    items: Mapped[List["SaleItem"]] = relationship(back_populates="sale", cascade="all, delete-orphan")
    receivable: Mapped[Optional["SalesReceivable"]] = relationship(back_populates="sale", uselist=False, cascade="all, delete-orphan")

class SaleItem(Base):
    __tablename__ = "sale_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    sale_id: Mapped[str] = mapped_column(String(36), ForeignKey("sales.id"), nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False, index=True)
    production_batch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=True, index=True)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    discount_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_cost_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_cost_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    sale: Mapped["Sale"] = relationship(back_populates="items")
    basket_type: Mapped["app.models.products.BasketType"] = relationship("app.models.products.BasketType")
    production_batch: Mapped[Optional["app.models.production.ProductionBatch"]] = relationship("app.models.production.ProductionBatch")

class SaleRecipeReference(Base):
    """Frozen recipe candidates for standard ready-stock sales without lot attribution."""
    __tablename__ = 'sale_recipe_references'
    sale_item_id: Mapped[str] = mapped_column(String(36), ForeignKey('sale_items.id'), primary_key=True)
    recipe_version_id: Mapped[str] = mapped_column(String(36), ForeignKey('recipe_versions.id'), primary_key=True)


for _action in ('UPDATE', 'DELETE'):
    event.listen(SaleRecipeReference.__table__, 'after_create', DDL(
        f"CREATE TRIGGER IF NOT EXISTS trg_sale_recipe_references_{_action.lower()} "
        f"BEFORE {_action} ON sale_recipe_references BEGIN "
        "SELECT RAISE(ABORT, 'sale recipe references are immutable'); END;"
    ).execute_if(dialect='sqlite'))


class SalesReceivable(Base):
    __tablename__ = "sales_receivables"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    sale_id: Mapped[str] = mapped_column(String(36), ForeignKey("sales.id"), nullable=False, index=True)
    customer_id: Mapped[str] = mapped_column(String(36), ForeignKey("customers.id"), nullable=False, index=True)
    due_date: Mapped[datetime.datetime] = mapped_column(DateTime, nullable=False, index=True)
    original_amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    paid_amount_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    balance_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="OPEN", index=True) # OPEN, PARTIAL, PAID, CANCELED
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    sale: Mapped["Sale"] = relationship(back_populates="receivable")
    customer: Mapped["app.models.customers.Customer"] = relationship("app.models.customers.Customer", back_populates="receivables")
    payments: Mapped[List["ReceivablePayment"]] = relationship(back_populates="receivable", cascade="all, delete-orphan")

class ReceivablePayment(Base):
    __tablename__ = "receivable_payments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    receivable_id: Mapped[str] = mapped_column(String(36), ForeignKey("sales_receivables.id"), nullable=False, index=True)
    payment_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    payment_method: Mapped[str] = mapped_column(String(50), nullable=False, default="CASH") # CASH, PIX, CARD, OTHER
    dispatch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=True, index=True)
    account_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("financial_accounts.id"), nullable=True, index=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="CONFIRMED", index=True) # CONFIRMED, REVERSED
    reversal_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reversal_of_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("receivable_payments.id"), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    receivable: Mapped["SalesReceivable"] = relationship(back_populates="payments")
    dispatch: Mapped[Optional["app.models.dispatches.StockDispatch"]] = relationship("app.models.dispatches.StockDispatch")
    financial_account: Mapped[Optional["app.models.financial.FinancialAccount"]] = relationship("app.models.financial.FinancialAccount")
