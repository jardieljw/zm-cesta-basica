import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field


class FilterInfo(BaseModel):
    filter_type: str = Field(..., description="Tipo de filtro: today, date, range, month, year, all")
    start_date: Optional[datetime.datetime] = None
    end_date: Optional[datetime.datetime] = None
    label: str = Field(..., description="Descricao legivel do periodo selecionado")


class BasketTypeCount(BaseModel):
    basket_type_id: str
    basket_type_name: str
    count: int
    total_cents: Optional[int] = 0


class LowStockItem(BaseModel):
    id: str
    name: str
    sku: Optional[str] = None
    base_unit: str
    current_stock: int
    min_stock: int
    difference: int


class BasketStockItem(BaseModel):
    basket_type_id: str
    name: str
    code: str
    stock_store: int
    stock_transit: int
    total_stock: int


class PendingDivergenceItem(BaseModel):
    dispatch_id: str
    dispatch_number: int
    responsible_person_name: str
    settled_at: datetime.datetime
    basket_discrepancy_qty: int
    cash_discrepancy_cents: int
    direct_company_received_cents: int
    status: str
    notes: Optional[str] = None
    investigation_notes: Optional[str] = None


class ResponsibleUnremittedItem(BaseModel):
    responsible_person_id: str
    responsible_person_name: str
    phone: Optional[str] = None
    dispatch_id: str
    dispatch_number: int
    dispatch_date: datetime.datetime
    cash_sales_cents: int
    receivable_cash_cents: int
    route_expenses_cents: int
    repaid_cash_cents: int
    unremitted_cash_cents: int
    status: str


# Dashboard Drilldown Items
class DashboardBatchRecord(BaseModel):
    id: str
    batch_number: int
    basket_type_name: str
    quantity_produced: int
    unit_cost_cents: int
    total_cost_cents: int
    is_custom: bool
    status: str
    occurred_at: datetime.datetime


class DashboardSaleRecord(BaseModel):
    id: str
    sale_number: int
    customer_name: Optional[str] = None
    sale_mode: str
    payment_mode: str
    payment_status: str
    total_amount_cents: int
    sale_date: datetime.datetime
    status: str


class DashboardDispatchRecord(BaseModel):
    id: str
    dispatch_number: int
    responsible_person_name: str
    dispatch_date: datetime.datetime
    total_baskets: int
    status: str


class DashboardReceivableRecord(BaseModel):
    id: str
    sale_number: int
    customer_name: str
    due_date: datetime.datetime
    original_amount_cents: int
    paid_amount_cents: int
    balance_cents: int
    status: str
    is_overdue: bool


class DashboardPayableRecord(BaseModel):
    id: str
    payable_number: int
    beneficiary: str
    category: str
    nature: str
    due_date: datetime.datetime
    original_amount_cents: int
    paid_amount_cents: int
    balance_cents: int
    status: str
    is_overdue: bool


class DashboardCashRecord(BaseModel):
    id: str
    entry_type: str
    amount_cents: int
    category: str
    nature: str
    description: str
    occurred_at: datetime.datetime
    source_type: str


# Dashboard Subsections
class DashboardProductionSummary(BaseModel):
    assembled_count: int = 0
    by_basket_type: List[BasketTypeCount] = []
    batches: List[DashboardBatchRecord] = []


class DashboardSalesSummary(BaseModel):
    sold_count: int = 0
    total_sold_cents: int = 0
    by_basket_type: List[BasketTypeCount] = []
    sales: List[DashboardSaleRecord] = []


class DashboardDispatchesSummary(BaseModel):
    dispatched_count: int = 0
    by_basket_type: List[BasketTypeCount] = []
    responsible_unremitted_cents: int = 0
    responsible_unremitted_items: List[ResponsibleUnremittedItem] = []
    pending_divergences_count: int = 0
    pending_divergences: List[PendingDivergenceItem] = []
    dispatches: List[DashboardDispatchRecord] = []


class DashboardInventorySummary(BaseModel):
    total_products_count: int = 0
    low_stock_products_count: int = 0
    low_stock_items: List[LowStockItem] = []
    basket_stock: List[BasketStockItem] = []


class DashboardFinancialSummary(BaseModel):
    # Contas a Receber
    receivables_open_cents: int = 0
    receivables_overdue_cents: int = 0
    effective_received_cents: int = 0
    # Contas a Pagar
    payables_open_cents: int = 0
    payables_overdue_cents: int = 0
    effective_paid_cents: int = 0
    # Tesouraria / Livro-Caixa
    cash_inflow_cents: int = 0
    cash_outflow_cents: int = 0
    net_cash_flow_cents: int = 0
    current_treasury_balance_cents: int = 0
    # Previsão de Caixa (sem misturar com realizado)
    projected_inflow_cents: int = 0
    projected_outflow_cents: int = 0
    projected_treasury_balance_cents: int = 0
    # Drill-downs
    receivables_records: List[DashboardReceivableRecord] = []
    payables_records: List[DashboardPayableRecord] = []
    cash_records: List[DashboardCashRecord] = []


class DashboardResponse(BaseModel):
    filter_info: FilterInfo
    production: DashboardProductionSummary
    sales: DashboardSalesSummary
    dispatches: DashboardDispatchesSummary
    inventory: DashboardInventorySummary
    financial: DashboardFinancialSummary


# ==================== REPORTS ====================

class ReportMetadata(BaseModel):
    report_type: str
    title: str
    company_name: str = "ZM Cesta Básica"
    generated_at: datetime.datetime
    filter_info: FilterInfo
    total_rows: int


class ReportResponse(BaseModel):
    metadata: ReportMetadata
    headers: List[str]
    columns: List[str]
    rows: List[Dict[str, Any]]
    totals: Dict[str, Any]
