import datetime
from typing import Optional, List
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, utc_now

class ResponsiblePerson(Base):
    __tablename__ = "responsible_persons"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    dispatches: Mapped[List["StockDispatch"]] = relationship(back_populates="responsible_person")


class StockDispatch(Base):
    __tablename__ = "stock_dispatches"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_number: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    responsible_person_id: Mapped[str] = mapped_column(String(36), ForeignKey("responsible_persons.id"), nullable=False, index=True)
    dispatch_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(30), default="OPEN", nullable=False, index=True)  # OPEN, CONCLUDED, CANCELED
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    responsible_person: Mapped["ResponsiblePerson"] = relationship(back_populates="dispatches")
    items: Mapped[List["DispatchItem"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    returns: Mapped[List["DispatchReturn"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    losses: Mapped[List["DispatchLoss"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    expenses: Mapped[List["DispatchExpense"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    repayments: Mapped[List["DispatchRepayment"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    settlements: Mapped[List["DispatchSettlement"]] = relationship(back_populates="dispatch", cascade="all, delete-orphan")
    sales: Mapped[List["app.models.sales.Sale"]] = relationship("app.models.sales.Sale", back_populates="dispatch")


class DispatchItem(Base):
    __tablename__ = "dispatch_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False, index=True)
    production_batch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=True, index=True)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="items")
    basket_type: Mapped["app.models.products.BasketType"] = relationship("app.models.products.BasketType")
    production_batch: Mapped[Optional["app.models.production.ProductionBatch"]] = relationship("app.models.production.ProductionBatch")


class DispatchReturn(Base):
    __tablename__ = "dispatch_returns"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False, index=True)
    production_batch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=True, index=True)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    returned_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="returns")
    basket_type: Mapped["app.models.products.BasketType"] = relationship("app.models.products.BasketType")
    production_batch: Mapped[Optional["app.models.production.ProductionBatch"]] = relationship("app.models.production.ProductionBatch")


class DispatchLoss(Base):
    __tablename__ = "dispatch_losses"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    basket_type_id: Mapped[str] = mapped_column(String(36), ForeignKey("basket_types.id"), nullable=False, index=True)
    production_batch_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("production_batches.id"), nullable=True, index=True)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    occurred_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="losses")
    basket_type: Mapped["app.models.products.BasketType"] = relationship("app.models.products.BasketType")
    production_batch: Mapped[Optional["app.models.production.ProductionBatch"]] = relationship("app.models.production.ProductionBatch")


class DispatchExpense(Base):
    __tablename__ = "dispatch_expenses"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    expense_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    receipt_ref: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    authorized_by: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="expenses")


class DispatchRepayment(Base):
    __tablename__ = "dispatch_repayments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    repayment_date: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    payment_method: Mapped[str] = mapped_column(String(50), default="CASH", nullable=False)
    account_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("financial_accounts.id"), nullable=True, index=True)
    received_by: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="repayments")
    financial_account: Mapped[Optional["app.models.financial.FinancialAccount"]] = relationship("app.models.financial.FinancialAccount")


class DispatchSettlement(Base):
    __tablename__ = "dispatch_settlements"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    dispatch_id: Mapped[str] = mapped_column(String(36), ForeignKey("stock_dispatches.id"), nullable=False, index=True)
    audited_by: Mapped[str] = mapped_column(String(100), nullable=False)
    settled_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False, index=True)
    total_dispatched_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    total_sold_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    total_returned_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    total_lost_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    total_remaining_custody_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    basket_discrepancy_qty: Mapped[int] = mapped_column(Integer, nullable=False)
    expected_cash_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    actual_repaid_cash_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    cash_discrepancy_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    direct_company_received_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="RESOLVED", nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    investigation_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, nullable=False)
    updated_at: Mapped[datetime.datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    dispatch: Mapped["StockDispatch"] = relationship(back_populates="settlements")
