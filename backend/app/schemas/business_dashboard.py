"""Business overview without bank balances, deposits or route settlement data."""
import datetime
from typing import List
from pydantic import BaseModel, Field
from app.schemas.reports import (
    FilterInfo, DashboardSalesSummary, DashboardReceivableRecord,
    DashboardPayableRecord, LowStockItem,
)


class BusinessBasketStock(BaseModel):
    basket_type_id: str
    name: str
    code: str
    stock_store: int


class BusinessInventory(BaseModel):
    total_products_count: int
    low_stock_products_count: int
    low_stock_items: List[LowStockItem]
    basket_stock: List[BusinessBasketStock]


class BusinessPaymentRecord(BaseModel):
    id: str
    description: str
    amount_cents: int  # Positive confirmed amount; negative cancellation/refund.
    occurred_at: datetime.datetime
    payment_method: str
    is_reversal: bool


class BusinessPurchases(BaseModel):
    purchase_count: int
    total_amount_cents: int


class BusinessFinancialSummary(BaseModel):
    available_balance_cents: int = 0
    accounts_balances: List[dict] = Field(default_factory=list)
    effective_received_cents: int
    effective_paid_cents: int
    payment_difference_cents: int
    receivables_open_cents: int
    receivables_overdue_cents: int
    payables_open_cents: int
    payables_overdue_cents: int
    receivables_due_in_period_cents: int
    payables_due_in_period_cents: int
    sales_revenue_cents: int
    sold_baskets_cost_cents: int
    gross_profit_cents: int
    operating_expenses_paid_cents: int
    operating_result_cents: int
    stock_purchases_paid_cents: int
    personal_withdrawals_paid_cents: int
    sales_without_cost_count: int
    received_records: List[BusinessPaymentRecord] = Field(default_factory=list)
    paid_records: List[BusinessPaymentRecord] = Field(default_factory=list)
    receivables_records: List[DashboardReceivableRecord] = Field(default_factory=list)
    payables_records: List[DashboardPayableRecord] = Field(default_factory=list)


class BusinessDashboardResponse(BaseModel):
    filter_info: FilterInfo
    sales: DashboardSalesSummary
    purchases: BusinessPurchases
    inventory: BusinessInventory
    financial: BusinessFinancialSummary
