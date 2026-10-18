import datetime
import calendar
from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import func, and_, or_

from app.models.products import Product, BasketType
from app.models.movements import InventoryMovement
from app.models.purchases import Purchase, PurchaseItem
from app.models.production import ProductionBatch, ProductionBatchItem
from app.models.customers import Customer
from app.models.sales import Sale, SaleItem, SalesReceivable, ReceivablePayment
from app.models.dispatches import (
    ResponsiblePerson,
    StockDispatch,
    DispatchItem,
    DispatchReturn,
    DispatchLoss,
    DispatchExpense,
    DispatchRepayment,
    DispatchSettlement,
)
from app.models.financial import FinancialAccount, CashFlowEntry, AccountPayable, PayablePayment
from app.schemas.reports import (
    FilterInfo,
    DashboardResponse,
    DashboardProductionSummary,
    DashboardSalesSummary,
    DashboardDispatchesSummary,
    DashboardInventorySummary,
    DashboardFinancialSummary,
    BasketTypeCount,
    LowStockItem,
    BasketStockItem,
    PendingDivergenceItem,
    ResponsibleUnremittedItem,
    DashboardBatchRecord,
    DashboardSaleRecord,
    DashboardDispatchRecord,
    DashboardReceivableRecord,
    DashboardPayableRecord,
    DashboardCashRecord,
    ReportMetadata,
    ReportResponse,
)


def _to_utc_aware(dt: Optional[datetime.datetime]) -> Optional[datetime.datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone(datetime.timezone.utc)


def resolve_date_filter(
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
) -> Tuple[Optional[datetime.datetime], Optional[datetime.datetime], FilterInfo]:
    """
    Resolves standard date filter intervals: today, date, range, month, year, or all.
    Returns (start_datetime, end_datetime, FilterInfo).
    """
    now = datetime.datetime.now(datetime.timezone.utc)
    today = now.date()

    try:
        if filter_type == "today":
            start_dt = datetime.datetime.combine(today, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(today, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Hoje ({today.strftime('%d/%m/%Y')})"

        elif filter_type == "date" and date_str:
            parsed_d = datetime.date.fromisoformat(date_str)
            start_dt = datetime.datetime.combine(parsed_d, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(parsed_d, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Data específica: {parsed_d.strftime('%d/%m/%Y')}"

        elif filter_type == "range" and start_date_str and end_date_str:
            d1 = datetime.date.fromisoformat(start_date_str)
            d2 = datetime.date.fromisoformat(end_date_str)
            if d1 > d2:
                d1, d2 = d2, d1
            start_dt = datetime.datetime.combine(d1, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(d2, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Intervalo: {d1.strftime('%d/%m/%Y')} a {d2.strftime('%d/%m/%Y')}"

        elif filter_type == "month":
            m = month or today.month
            y = year or today.year
            _, last_day = calendar.monthrange(y, m)
            d1 = datetime.date(y, m, 1)
            d2 = datetime.date(y, m, last_day)
            start_dt = datetime.datetime.combine(d1, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(d2, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Mês {m:02d}/{y}"

        elif filter_type == "year":
            y = year or today.year
            d1 = datetime.date(y, 1, 1)
            d2 = datetime.date(y, 12, 31)
            start_dt = datetime.datetime.combine(d1, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(d2, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Ano {y}"

        elif filter_type == "all":
            start_dt = None
            end_dt = None
            label = "Todo o período"

        else:
            # Default to today
            start_dt = datetime.datetime.combine(today, datetime.time.min, tzinfo=datetime.timezone.utc)
            end_dt = datetime.datetime.combine(today, datetime.time.max, tzinfo=datetime.timezone.utc)
            label = f"Hoje ({today.strftime('%d/%m/%Y')})"
    except (ValueError, TypeError) as exc:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Formato de data inválido. Utilize o formato YYYY-MM-DD."
        ) from exc

    info = FilterInfo(
        filter_type=filter_type,
        start_date=start_dt,
        end_date=end_dt,
        label=label,
    )
    return start_dt, end_dt, info


def get_dashboard_data(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
) -> DashboardResponse:
    """
    Gathers operational and financial KPIs for the dashboard strictly via read-only queries.
    Never modifies database state.
    """
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    now_utc = datetime.datetime.now(datetime.timezone.utc)

    # 1. PRODUCTION
    prod_query = db.query(ProductionBatch).filter(ProductionBatch.status != "CANCELED")
    if start_dt and end_dt:
        prod_query = prod_query.filter(
            ProductionBatch.occurred_at >= start_dt,
            ProductionBatch.occurred_at <= end_dt
        )
    batches = prod_query.order_by(ProductionBatch.occurred_at.desc()).all()

    total_assembled = sum(b.quantity_produced for b in batches)
    prod_by_basket: Dict[str, BasketTypeCount] = {}
    batch_records: List[DashboardBatchRecord] = []

    for b in batches:
        b_name = b.basket_type.name if b.basket_type else "Cesta"
        if b.basket_type_id not in prod_by_basket:
            prod_by_basket[b.basket_type_id] = BasketTypeCount(
                basket_type_id=b.basket_type_id,
                basket_type_name=b_name,
                count=0,
                total_cents=0
            )
        prod_by_basket[b.basket_type_id].count += b.quantity_produced

        batch_records.append(
            DashboardBatchRecord(
                id=b.id,
                batch_number=b.batch_number,
                basket_type_name=b_name,
                quantity_produced=b.quantity_produced,
                unit_cost_cents=b.unit_cost_cents,
                total_cost_cents=b.total_cost_cents,
                is_custom=b.is_custom,
                status=b.status,
                occurred_at=b.occurred_at,
            )
        )

    prod_summary = DashboardProductionSummary(
        assembled_count=total_assembled,
        by_basket_type=list(prod_by_basket.values()),
        batches=batch_records[:50]
    )

    # 2. SALES
    sales_query = db.query(Sale).filter(Sale.status == "CONFIRMED")
    if start_dt and end_dt:
        sales_query = sales_query.filter(
            Sale.sale_date >= start_dt,
            Sale.sale_date <= end_dt
        )
    sales = sales_query.order_by(Sale.sale_date.desc()).all()

    total_sold_count = 0
    total_sold_cents = 0
    sales_by_basket: Dict[str, BasketTypeCount] = {}
    sale_records: List[DashboardSaleRecord] = []

    for s in sales:
        total_sold_cents += s.total_amount_cents
        for item in s.items:
            total_sold_count += item.quantity
            b_name = item.basket_type.name if item.basket_type else "Cesta"
            if item.basket_type_id not in sales_by_basket:
                sales_by_basket[item.basket_type_id] = BasketTypeCount(
                    basket_type_id=item.basket_type_id,
                    basket_type_name=b_name,
                    count=0,
                    total_cents=0
                )
            sales_by_basket[item.basket_type_id].count += item.quantity
            sales_by_basket[item.basket_type_id].total_cents = (
                (sales_by_basket[item.basket_type_id].total_cents or 0) + item.total_cents
            )

        sale_records.append(
            DashboardSaleRecord(
                id=s.id,
                sale_number=s.sale_number,
                customer_name=s.customer.name if s.customer else (s.customer_name or "Consumidor Final"),
                sale_mode=s.sale_mode,
                payment_mode=s.payment_mode,
                payment_status=s.payment_status,
                total_amount_cents=s.total_amount_cents,
                sale_date=s.sale_date,
                status=s.status,
            )
        )

    sales_summary = DashboardSalesSummary(
        sold_count=total_sold_count,
        total_sold_cents=total_sold_cents,
        by_basket_type=list(sales_by_basket.values()),
        sales=sale_records[:50]
    )

    # 3. DISPATCHES & ROUTE RESPONSIBILITY
    disp_query = db.query(StockDispatch).filter(StockDispatch.status != "CANCELED")
    if start_dt and end_dt:
        disp_query = disp_query.filter(
            StockDispatch.dispatch_date >= start_dt,
            StockDispatch.dispatch_date <= end_dt
        )
    dispatches = disp_query.order_by(StockDispatch.dispatch_date.desc()).all()

    total_dispatched_count = 0
    dispatches_by_basket: Dict[str, BasketTypeCount] = {}
    dispatch_records: List[DashboardDispatchRecord] = []

    for d in dispatches:
        resp_name = d.responsible_person.name if d.responsible_person else "Responsável"
        d_baskets = sum(it.quantity for it in d.items)
        total_dispatched_count += d_baskets

        for it in d.items:
            b_name = it.basket_type.name if it.basket_type else "Cesta"
            if it.basket_type_id not in dispatches_by_basket:
                dispatches_by_basket[it.basket_type_id] = BasketTypeCount(
                    basket_type_id=it.basket_type_id,
                    basket_type_name=b_name,
                    count=0
                )
            dispatches_by_basket[it.basket_type_id].count += it.quantity

        dispatch_records.append(
            DashboardDispatchRecord(
                id=d.id,
                dispatch_number=d.dispatch_number,
                responsible_person_name=resp_name,
                dispatch_date=d.dispatch_date,
                total_baskets=d_baskets,
                status=d.status,
            )
        )

    # Calculate unremitted cash by responsible persons:
    # Dispatches that are OPEN (active route holding cash) or have settlement PENDING_INVESTIGATION
    unremitted_items: List[ResponsibleUnremittedItem] = []

    # 1. Open dispatches (active routes)
    open_dispatches = db.query(StockDispatch).filter(
        StockDispatch.status == "OPEN"
    ).order_by(StockDispatch.dispatch_date.desc()).all()

    for d in open_dispatches:
        resp_id = d.responsible_person_id
        resp_name = d.responsible_person.name if d.responsible_person else "Responsável"
        resp_phone = d.responsible_person.phone if d.responsible_person else None

        # Cash sales made on route
        cash_sales = sum(
            s.total_amount_cents
            for s in d.sales
            if s.status == "CONFIRMED" and s.payment_mode == "CASH_IMMEDIATE"
        )
        # Cash collected from previous receivables during route
        receivable_cash = sum(
            p.amount_cents
            for p in db.query(ReceivablePayment).filter(
                ReceivablePayment.dispatch_id == d.id,
                ReceivablePayment.status == "CONFIRMED",
                ReceivablePayment.payment_method == "CASH"
            ).all()
        )
        # Route expenses
        route_expenses = sum(e.amount_cents for e in d.expenses)
        expected_cash = max(0, cash_sales + receivable_cash - route_expenses)
        repaid_cash = sum(r.amount_cents for r in d.repayments if r.payment_method == "CASH")
        unremitted = max(0, expected_cash - repaid_cash)

        if unremitted > 0:
            unremitted_items.append(
                ResponsibleUnremittedItem(
                    responsible_person_id=resp_id,
                    responsible_person_name=resp_name,
                    phone=resp_phone,
                    dispatch_id=d.id,
                    dispatch_number=d.dispatch_number,
                    dispatch_date=d.dispatch_date,
                    cash_sales_cents=cash_sales,
                    receivable_cash_cents=receivable_cash,
                    route_expenses_cents=route_expenses,
                    repaid_cash_cents=repaid_cash,
                    unremitted_cash_cents=unremitted,
                    status=d.status,
                )
            )

    # 2. Concluded dispatches with settlement PENDING_INVESTIGATION where expected > repaid
    pending_invest_settlements = db.query(DispatchSettlement).filter(
        DispatchSettlement.status == "PENDING_INVESTIGATION"
    ).all()

    for s in pending_invest_settlements:
        if any(it.dispatch_id == s.dispatch_id for it in unremitted_items):
            continue
        d = s.dispatch
        if not d or d.status == "CANCELED":
            continue
        resp_id = d.responsible_person_id
        resp_name = d.responsible_person.name if d.responsible_person else "Responsável"
        resp_phone = d.responsible_person.phone if d.responsible_person else None

        unremitted_diff = max(0, s.expected_cash_cents - s.actual_repaid_cash_cents)
        if unremitted_diff > 0:
            unremitted_items.append(
                ResponsibleUnremittedItem(
                    responsible_person_id=resp_id,
                    responsible_person_name=resp_name,
                    phone=resp_phone,
                    dispatch_id=d.id,
                    dispatch_number=d.dispatch_number,
                    dispatch_date=d.dispatch_date,
                    cash_sales_cents=s.expected_cash_cents,
                    receivable_cash_cents=0,
                    route_expenses_cents=0,
                    repaid_cash_cents=s.actual_repaid_cash_cents,
                    unremitted_cash_cents=unremitted_diff,
                    status="EM_INVESTIGACAO",
                )
            )

    unremitted_total_cents = sum(it.unremitted_cash_cents for it in unremitted_items)

    # Pending Divergences
    pending_settlements = db.query(DispatchSettlement).filter(
        DispatchSettlement.status == "PENDING_INVESTIGATION"
    ).all()
    pending_divergences_list = [
        PendingDivergenceItem(
            dispatch_id=s.dispatch_id,
            dispatch_number=s.dispatch.dispatch_number if s.dispatch else 0,
            responsible_person_name=(
                s.dispatch.responsible_person.name
                if s.dispatch and s.dispatch.responsible_person
                else "Responsável"
            ),
            settled_at=s.settled_at,
            basket_discrepancy_qty=s.basket_discrepancy_qty,
            cash_discrepancy_cents=s.cash_discrepancy_cents,
            direct_company_received_cents=s.direct_company_received_cents,
            status=s.status,
            notes=s.notes,
            investigation_notes=s.investigation_notes,
        )
        for s in pending_settlements
    ]

    dispatches_summary = DashboardDispatchesSummary(
        dispatched_count=total_dispatched_count,
        by_basket_type=list(dispatches_by_basket.values()),
        responsible_unremitted_cents=unremitted_total_cents,
        responsible_unremitted_items=unremitted_items[:50],
        pending_divergences_count=len(pending_divergences_list),
        pending_divergences=pending_divergences_list,
        dispatches=dispatch_records[:50]
    )

    # 4. INVENTORY & STOCK ALERT
    products = db.query(Product).filter(Product.is_active == True).all()
    low_stock_items: List[LowStockItem] = []

    for p in products:
        # Physical store stock
        stock_sum = db.query(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).filter(
            InventoryMovement.product_id == p.id,
            InventoryMovement.location_type == "STORE"
        ).scalar() or 0

        if stock_sum < p.minimum_stock:
            low_stock_items.append(
                LowStockItem(
                    id=p.id,
                    name=p.name,
                    sku=p.sku,
                    base_unit=p.base_unit,
                    current_stock=stock_sum,
                    min_stock=p.minimum_stock,
                    difference=p.minimum_stock - stock_sum,
                )
            )

    basket_types = db.query(BasketType).filter(BasketType.is_active == True).all()
    basket_stock_list: List[BasketStockItem] = []

    for bt in basket_types:
        store_baskets = db.query(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).filter(
            InventoryMovement.basket_type_id == bt.id,
            InventoryMovement.location_type == "STORE"
        ).scalar() or 0

        transit_baskets = db.query(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).filter(
            InventoryMovement.basket_type_id == bt.id,
            InventoryMovement.location_type == "TRANSIT"
        ).scalar() or 0

        basket_stock_list.append(
            BasketStockItem(
                basket_type_id=bt.id,
                name=bt.name,
                code=bt.code,
                stock_store=store_baskets,
                stock_transit=transit_baskets,
                total_stock=store_baskets + transit_baskets,
            )
        )

    inventory_summary = DashboardInventorySummary(
        total_products_count=len(products),
        low_stock_products_count=len(low_stock_items),
        low_stock_items=low_stock_items,
        basket_stock=basket_stock_list,
    )

    # 5. FINANCIAL
    # Receivables (Open & Overdue)
    all_open_receivables = db.query(SalesReceivable).filter(
        SalesReceivable.status.in_(["OPEN", "PARTIAL"])
    ).all()
    receivables_open_cents = sum(r.balance_cents for r in all_open_receivables)
    receivables_overdue_cents = sum(
        r.balance_cents for r in all_open_receivables if _to_utc_aware(r.due_date) < now_utc
    )

    # Effective payments received in period
    rec_pay_query = db.query(ReceivablePayment).filter(ReceivablePayment.status == "CONFIRMED")
    if start_dt and end_dt:
        rec_pay_query = rec_pay_query.filter(
            ReceivablePayment.payment_date >= start_dt,
            ReceivablePayment.payment_date <= end_dt
        )
    effective_received_cents = sum(p.amount_cents for p in rec_pay_query.all())

    receivable_drilldown = [
        DashboardReceivableRecord(
            id=r.id,
            sale_number=r.sale.sale_number if r.sale else 0,
            customer_name=r.customer.name if r.customer else "Cliente",
            due_date=r.due_date,
            original_amount_cents=r.original_amount_cents,
            paid_amount_cents=r.paid_amount_cents,
            balance_cents=r.balance_cents,
            status=r.status,
            is_overdue=_to_utc_aware(r.due_date) < now_utc,
        )
        for r in all_open_receivables[:50]
    ]

    # Accounts Payable (Open & Overdue)
    all_open_payables = db.query(AccountPayable).filter(
        AccountPayable.status.in_(["OPEN", "PARTIAL"])
    ).all()
    payables_open_cents = sum(p.balance_cents for p in all_open_payables)
    payables_overdue_cents = sum(
        p.balance_cents for p in all_open_payables if _to_utc_aware(p.due_date) < now_utc
    )

    # Effective payments made in period
    pay_pay_query = db.query(PayablePayment).filter(PayablePayment.status == "CONFIRMED")
    if start_dt and end_dt:
        pay_pay_query = pay_pay_query.filter(
            PayablePayment.payment_date >= start_dt,
            PayablePayment.payment_date <= end_dt
        )
    effective_paid_cents = sum(p.amount_cents for p in pay_pay_query.all())

    payable_drilldown = [
        DashboardPayableRecord(
            id=p.id,
            payable_number=p.payable_number,
            beneficiary=p.beneficiary,
            category=p.category,
            nature=p.nature,
            due_date=p.due_date,
            original_amount_cents=p.original_amount_cents,
            paid_amount_cents=p.paid_amount_cents,
            balance_cents=p.balance_cents,
            status=p.status,
            is_overdue=_to_utc_aware(p.due_date) < now_utc,
        )
        for p in all_open_payables[:50]
    ]

    # Cash Flow Entries in period
    cash_query = db.query(CashFlowEntry)
    if start_dt and end_dt:
        cash_query = cash_query.filter(
            CashFlowEntry.occurred_at >= start_dt,
            CashFlowEntry.occurred_at <= end_dt
        )
    cash_entries = cash_query.order_by(CashFlowEntry.occurred_at.desc()).all()

    cash_inflow_cents = sum(c.amount_cents for c in cash_entries if c.entry_type == "CREDIT")
    cash_outflow_cents = sum(c.amount_cents for c in cash_entries if c.entry_type == "DEBIT")
    net_cash_flow_cents = cash_inflow_cents - cash_outflow_cents

    # Current Treasury Balance across all active accounts
    current_treasury_balance_cents = db.query(
        func.coalesce(func.sum(FinancialAccount.current_balance_cents), 0)
    ).filter(FinancialAccount.is_active == True).scalar() or 0

    # Projected Inflow and Outflow (without conflating projection with realized money)
    # Filter receivables and payables due within the period
    proj_rec_query = db.query(SalesReceivable).filter(SalesReceivable.status.in_(["OPEN", "PARTIAL"]))
    proj_pay_query = db.query(AccountPayable).filter(AccountPayable.status.in_(["OPEN", "PARTIAL"]))
    if start_dt and end_dt:
        proj_rec_query = proj_rec_query.filter(
            SalesReceivable.due_date >= start_dt,
            SalesReceivable.due_date <= end_dt
        )
        proj_pay_query = proj_pay_query.filter(
            AccountPayable.due_date >= start_dt,
            AccountPayable.due_date <= end_dt
        )
    projected_inflow_cents = sum(r.balance_cents for r in proj_rec_query.all())
    projected_outflow_cents = sum(p.balance_cents for p in proj_pay_query.all())
    projected_treasury_balance_cents = (
        current_treasury_balance_cents + projected_inflow_cents - projected_outflow_cents
    )

    cash_drilldown = [
        DashboardCashRecord(
            id=c.id,
            entry_type=c.entry_type,
            amount_cents=c.amount_cents,
            category=c.category,
            nature=c.nature,
            description=c.description,
            occurred_at=c.occurred_at,
            source_type=c.source_type,
        )
        for c in cash_entries[:50]
    ]

    financial_summary = DashboardFinancialSummary(
        receivables_open_cents=receivables_open_cents,
        receivables_overdue_cents=receivables_overdue_cents,
        effective_received_cents=effective_received_cents,
        payables_open_cents=payables_open_cents,
        payables_overdue_cents=payables_overdue_cents,
        effective_paid_cents=effective_paid_cents,
        cash_inflow_cents=cash_inflow_cents,
        cash_outflow_cents=cash_outflow_cents,
        net_cash_flow_cents=net_cash_flow_cents,
        current_treasury_balance_cents=current_treasury_balance_cents,
        projected_inflow_cents=projected_inflow_cents,
        projected_outflow_cents=projected_outflow_cents,
        projected_treasury_balance_cents=projected_treasury_balance_cents,
        receivables_records=receivable_drilldown,
        payables_records=payable_drilldown,
        cash_records=cash_drilldown,
    )

    return DashboardResponse(
        filter_info=filter_info,
        production=prod_summary,
        sales=sales_summary,
        dispatches=dispatches_summary,
        inventory=inventory_summary,
        financial=financial_summary,
    )


# ==================== THE 8 CANONICAL REPORTS ====================

def get_report_sales_dispatches(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    basket_type_id: Optional[str] = None,
    customer_id: Optional[str] = None,
    responsible_id: Optional[str] = None,
    sale_mode: Optional[str] = None,
    include_dispatches: bool = True,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )

    # 1. Sales
    sales_q = db.query(Sale).filter(Sale.status == "CONFIRMED")
    if start_dt and end_dt:
        sales_q = sales_q.filter(Sale.sale_date >= start_dt, Sale.sale_date <= end_dt)
    if customer_id:
        sales_q = sales_q.filter(Sale.customer_id == customer_id)
    if responsible_id:
        sales_q = sales_q.filter(Sale.responsible_person_id == responsible_id)
    if sale_mode:
        sales_q = sales_q.filter(Sale.sale_mode == sale_mode)
    sales = sales_q.order_by(Sale.sale_date.desc()).all()

    # 2. Dispatches (only when not filtering specifically by customer or sale_mode)
    if not include_dispatches or customer_id or sale_mode:
        dispatches = []
    else:
        disp_q = db.query(StockDispatch).filter(StockDispatch.status != "CANCELED")
        if start_dt and end_dt:
            disp_q = disp_q.filter(StockDispatch.dispatch_date >= start_dt, StockDispatch.dispatch_date <= end_dt)
        if responsible_id:
            disp_q = disp_q.filter(StockDispatch.responsible_person_id == responsible_id)
        dispatches = disp_q.order_by(StockDispatch.dispatch_date.desc()).all()

    headers = [
        "Data/Hora", "Tipo de Operação", "Referência", "Cliente / Responsável",
        "Tipo de Cesta", "Quantidade", "Valor Unit. (R$)", "Valor Total (R$)",
        "Meio de Pagamento", "Status"
    ]
    columns = [
        "date", "operation_type", "reference", "party",
        "basket_name", "quantity", "unit_price_cents", "total_price_cents",
        "payment_info", "status"
    ]

    rows = []
    total_sold_qty = 0
    total_sold_cents = 0
    total_dispatched_qty = 0

    for s in sales:
        party = s.customer.name if s.customer else (s.customer_name or "Consumidor Final")
        op_type = "Venda Balcão" if s.sale_mode == "DIRECT_STORE" else "Venda em Rota"
        if not s.items and not basket_type_id:
            total_sold_cents += s.total_amount_cents
            rows.append({
                "date": s.sale_date,
                "operation_type": op_type,
                "reference": f"Venda #{s.sale_number}",
                "party": party,
                "basket_name": "-",
                "quantity": 1,
                "unit_price_cents": s.total_amount_cents,
                "total_price_cents": s.total_amount_cents,
                "payment_info": s.payment_mode,
                "status": s.status,
            })
        for it in s.items:
            if basket_type_id and it.basket_type_id != basket_type_id:
                continue
            total_sold_qty += it.quantity
            total_sold_cents += it.total_cents
            rows.append({
                "date": s.sale_date,
                "operation_type": op_type,
                "reference": f"Venda #{s.sale_number}",
                "party": party,
                "basket_name": it.basket_type.name if it.basket_type else "Cesta",
                "quantity": it.quantity,
                "unit_price_cents": it.unit_price_cents,
                "total_price_cents": it.total_cents,
                "payment_info": s.payment_mode,
                "status": s.status,
            })

    for d in dispatches:
        party = d.responsible_person.name if d.responsible_person else "Responsável"
        if not d.items and not basket_type_id:
            rows.append({
                "date": d.dispatch_date,
                "operation_type": "Saída Custódia",
                "reference": f"Saída #{d.dispatch_number}",
                "party": party,
                "basket_name": "-",
                "quantity": 0,
                "unit_price_cents": 0,
                "total_price_cents": 0,
                "payment_info": "Custódia",
                "status": d.status,
            })
        for it in d.items:
            if basket_type_id and it.basket_type_id != basket_type_id:
                continue
            total_dispatched_qty += it.quantity
            rows.append({
                "date": d.dispatch_date,
                "operation_type": "Saída Custódia",
                "reference": f"Saída #{d.dispatch_number}",
                "party": party,
                "basket_name": it.basket_type.name if it.basket_type else "Cesta",
                "quantity": it.quantity,
                "unit_price_cents": it.unit_price_cents,
                "total_price_cents": it.quantity * it.unit_price_cents,
                "payment_info": "Custódia",
                "status": d.status,
            })

    # Sort rows by date desc
    rows.sort(key=lambda r: r["date"], reverse=True)

    metadata = ReportMetadata(
        report_type="sales-dispatches",
        title="Relatório de Vendas e Saídas de Cestas" if include_dispatches else "Relatório de Vendas de Cestas",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "quantity": total_sold_qty + total_dispatched_qty,
        "total_price_cents": total_sold_cents,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_assembly(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    basket_type_id: Optional[str] = None,
    is_custom: Optional[bool] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    query = db.query(ProductionBatch).filter(ProductionBatch.status != "CANCELED")
    if start_dt and end_dt:
        query = query.filter(ProductionBatch.occurred_at >= start_dt, ProductionBatch.occurred_at <= end_dt)
    if basket_type_id:
        query = query.filter(ProductionBatch.basket_type_id == basket_type_id)
    if is_custom is not None:
        query = query.filter(ProductionBatch.is_custom == is_custom)
    batches = query.order_by(ProductionBatch.occurred_at.desc()).all()

    headers = [
        "Lote #", "Data/Hora", "Tipo de Cesta", "Composição", "Qtd Produzida",
        "Custo Unit. (R$)", "Custo Total (R$)", "Status"
    ]
    columns = [
        "batch_number", "date", "basket_name", "batch_type", "quantity_produced",
        "unit_cost_cents", "total_cost_cents", "status"
    ]

    rows = []
    tot_qty = 0
    tot_cost = 0

    for b in batches:
        tot_qty += b.quantity_produced
        tot_cost += b.total_cost_cents
        rows.append({
            "batch_number": f"Lote #{b.batch_number}",
            "date": b.occurred_at,
            "basket_name": b.basket_type.name if b.basket_type else "Cesta",
            "batch_type": "Personalizada" if b.is_custom else "Padrão",
            "quantity_produced": b.quantity_produced,
            "unit_cost_cents": b.unit_cost_cents,
            "total_cost_cents": b.total_cost_cents,
            "status": b.status,
        })

    metadata = ReportMetadata(
        report_type="assembly",
        title="Relatório de Montagem e Produção de Cestas",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "quantity_produced": tot_qty,
        "total_cost_cents": tot_cost,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_purchases_movements(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    product_id: Optional[str] = None,
    movement_type: Optional[str] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    query = db.query(InventoryMovement)
    if start_dt and end_dt:
        query = query.filter(InventoryMovement.occurred_at >= start_dt, InventoryMovement.occurred_at <= end_dt)
    if product_id:
        query = query.filter(InventoryMovement.product_id == product_id)
    if movement_type:
        query = query.filter(InventoryMovement.movement_type == movement_type)
    movements = query.order_by(InventoryMovement.occurred_at.desc()).all()

    headers = [
        "Data/Hora", "Tipo de Movimento", "Item / Insumo", "Tipo de Item",
        "Localização", "Variação (Delta)", "Unidade", "Origem", "Motivo / Justificativa"
    ]
    columns = [
        "date", "movement_type", "item_name", "item_type",
        "location", "quantity_delta", "unit", "source", "reason"
    ]

    rows = []
    tot_delta = 0

    for m in movements:
        tot_delta += m.quantity_delta
        if m.product:
            item_name = m.product.name
            unit = m.product.base_unit
        elif m.basket_type:
            item_name = m.basket_type.name
            unit = "un"
        else:
            item_name = "Item"
            unit = "-"

        rows.append({
            "date": m.occurred_at,
            "movement_type": m.movement_type,
            "item_name": item_name,
            "item_type": m.item_type,
            "location": m.location_type,
            "quantity_delta": m.quantity_delta,
            "unit": unit,
            "source": f"{m.source_type} ({m.source_id[:8]})",
            "reason": m.reason or "-",
        })

    metadata = ReportMetadata(
        report_type="purchases-movements",
        title="Relatório de Compras e Movimentações do Razão de Estoque",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "quantity_delta": tot_delta,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_receivables(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    status_filter: Optional[str] = None,
    customer_id: Optional[str] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    query = db.query(SalesReceivable)
    if start_dt and end_dt:
        query = query.filter(
            or_(
                and_(SalesReceivable.due_date >= start_dt, SalesReceivable.due_date <= end_dt),
                and_(SalesReceivable.created_at >= start_dt, SalesReceivable.created_at <= end_dt)
            )
        )
    if status_filter:
        query = query.filter(SalesReceivable.status == status_filter)
    if customer_id:
        query = query.filter(SalesReceivable.customer_id == customer_id)
    receivables = query.order_by(SalesReceivable.due_date.asc()).all()

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    headers = [
        "Venda #", "Data da Venda", "Cliente", "Data de Vencimento",
        "Valor Original (R$)", "Valor Pago (R$)", "Saldo Restante (R$)",
        "Situação", "Quitação Confirmada"
    ]
    columns = [
        "sale_number", "sale_date", "customer_name", "due_date",
        "original_amount_cents", "paid_amount_cents", "balance_cents",
        "status", "is_paid"
    ]

    rows = []
    tot_orig = 0
    tot_paid = 0
    tot_bal = 0

    for r in receivables:
        tot_orig += r.original_amount_cents
        tot_paid += r.paid_amount_cents
        tot_bal += r.balance_cents
        is_paid = "SIM (Quitado)" if r.status == "PAID" else "NÃO"
        rows.append({
            "sale_number": f"Venda #{r.sale.sale_number}" if r.sale else "-",
            "sale_date": r.sale.sale_date if r.sale else r.created_at,
            "customer_name": r.customer.name if r.customer else "Cliente",
            "due_date": r.due_date,
            "original_amount_cents": r.original_amount_cents,
            "paid_amount_cents": r.paid_amount_cents,
            "balance_cents": r.balance_cents,
            "status": "VENCIDO" if (r.status in ["OPEN", "PARTIAL"] and _to_utc_aware(r.due_date) < now_utc) else r.status,
            "is_paid": is_paid,
        })

    metadata = ReportMetadata(
        report_type="receivables",
        title="Relatório de Contas a Receber, Pagamentos e Quitações",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "original_amount_cents": tot_orig,
        "paid_amount_cents": tot_paid,
        "balance_cents": tot_bal,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_payables(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    status_filter: Optional[str] = None,
    beneficiary: Optional[str] = None,
    category: Optional[str] = None,
    nature: Optional[str] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    query = db.query(AccountPayable)
    if start_dt and end_dt:
        query = query.filter(AccountPayable.due_date >= start_dt, AccountPayable.due_date <= end_dt)
    if status_filter:
        query = query.filter(AccountPayable.status == status_filter)
    if beneficiary:
        query = query.filter(AccountPayable.beneficiary.ilike(f"%{beneficiary}%"))
    if category:
        query = query.filter(AccountPayable.category == category)
    if nature:
        query = query.filter(AccountPayable.nature == nature)
    payables = query.order_by(AccountPayable.due_date.asc()).all()

    now_utc = datetime.datetime.now(datetime.timezone.utc)
    headers = [
        "Título #", "Vencimento", "Beneficiário / Fornecedor", "Categoria", "Natureza",
        "Valor Nominal (R$)", "Valor Pago (R$)", "Saldo em Aberto (R$)",
        "Forma Pagamento", "Situação"
    ]
    columns = [
        "payable_number", "due_date", "beneficiary", "category", "nature",
        "original_amount_cents", "paid_amount_cents", "balance_cents",
        "payment_method", "status"
    ]

    rows = []
    tot_orig = 0
    tot_paid = 0
    tot_bal = 0

    for p in payables:
        tot_orig += p.original_amount_cents
        tot_paid += p.paid_amount_cents
        tot_bal += p.balance_cents
        status_desc = "VENCIDA" if (p.status in ["OPEN", "PARTIAL"] and _to_utc_aware(p.due_date) < now_utc) else p.status
        rows.append({
            "payable_number": f"Título #{p.payable_number}",
            "due_date": p.due_date,
            "beneficiary": p.beneficiary,
            "category": p.category,
            "nature": "Operacional" if p.nature == "BUSINESS" else "Retirada Sócio",
            "original_amount_cents": p.original_amount_cents,
            "paid_amount_cents": p.paid_amount_cents,
            "balance_cents": p.balance_cents,
            "payment_method": p.payment_method,
            "status": status_desc,
        })

    metadata = ReportMetadata(
        report_type="payables",
        title="Relatório de Contas a Pagar, Vencimentos e Pagamentos",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "original_amount_cents": tot_orig,
        "paid_amount_cents": tot_paid,
        "balance_cents": tot_bal,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_dispatch_settlements(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
    responsible_id: Optional[str] = None,
    status_filter: Optional[str] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )
    query = db.query(StockDispatch).filter(StockDispatch.status != "CANCELED")
    if start_dt and end_dt:
        query = query.filter(StockDispatch.dispatch_date >= start_dt, StockDispatch.dispatch_date <= end_dt)
    if responsible_id:
        query = query.filter(StockDispatch.responsible_person_id == responsible_id)
    dispatches = query.order_by(StockDispatch.dispatch_date.desc()).all()

    headers = [
        "Saída #", "Data Saída", "Responsável", "Retiradas", "Vendidas",
        "Devolvidas", "Avariadas", "Em Custódia", "Diferença",
        "Esperado (R$)", "Repassado (R$)", "Dif. Caixa (R$)", "Direto Empresa (R$)", "Status"
    ]
    columns = [
        "dispatch_number", "dispatch_date", "responsible_name", "qty_dispatched",
        "qty_sold", "qty_returned", "qty_lost", "qty_custody", "qty_discrepancy",
        "expected_cash_cents", "repaid_cash_cents", "cash_discrepancy_cents",
        "direct_company_cents", "status"
    ]

    rows = []
    tot_disp = 0
    tot_sold = 0
    tot_ret = 0
    tot_repaid = 0
    tot_diff = 0

    for d in dispatches:
        resp_name = d.responsible_person.name if d.responsible_person else "Responsável"
        total_disp = sum(it.quantity for it in d.items)

        settlement = d.settlements[0] if d.settlements else None
        if settlement:
            q_sold = settlement.total_sold_qty
            q_ret = settlement.total_returned_qty
            q_lost = settlement.total_lost_qty
            q_cust = settlement.total_remaining_custody_qty
            q_diff = settlement.basket_discrepancy_qty
            c_exp = settlement.expected_cash_cents
            c_rep = settlement.actual_repaid_cash_cents
            c_diff = settlement.cash_discrepancy_cents
            c_dir = settlement.direct_company_received_cents
            st = settlement.status
        else:
            q_sold = sum(it.quantity for s in d.sales for it in s.items if s.status == "CONFIRMED")
            q_ret = sum(r.quantity for r in d.returns)
            q_lost = sum(l.quantity for l in d.losses)
            q_cust = max(0, total_disp - (q_sold + q_ret + q_lost))
            q_diff = 0
            cash_sales = sum(
                s.total_amount_cents
                for s in d.sales
                if s.status == "CONFIRMED" and s.payment_mode == "CASH_IMMEDIATE"
            )
            route_exp = sum(e.amount_cents for e in d.expenses)
            c_exp = max(0, cash_sales - route_exp)
            c_rep = sum(r.amount_cents for r in d.repayments if r.payment_method == "CASH")
            c_diff = c_rep - c_exp
            c_dir = sum(
                s.total_amount_cents
                for s in d.sales
                if s.status == "CONFIRMED" and s.payment_mode in ["PIX", "CARD"]
            )
            st = d.status

        if status_filter and st != status_filter:
            continue

        tot_disp += total_disp
        tot_sold += q_sold
        tot_ret += q_ret
        tot_repaid += c_rep
        tot_diff += c_diff

        rows.append({
            "dispatch_number": f"Saída #{d.dispatch_number}",
            "dispatch_date": d.dispatch_date,
            "responsible_name": resp_name,
            "qty_dispatched": total_disp,
            "qty_sold": q_sold,
            "qty_returned": q_ret,
            "qty_lost": q_lost,
            "qty_custody": q_cust,
            "qty_discrepancy": q_diff,
            "expected_cash_cents": c_exp,
            "repaid_cash_cents": c_rep,
            "cash_discrepancy_cents": c_diff,
            "direct_company_cents": c_dir,
            "status": st,
        })

    metadata = ReportMetadata(
        report_type="dispatch-settlements",
        title="Relatório de Conferência de Saídas e Repasses de Rotas",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "qty_dispatched": tot_disp,
        "qty_sold": tot_sold,
        "qty_returned": tot_ret,
        "repaid_cash_cents": tot_repaid,
        "cash_discrepancy_cents": tot_diff,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_physical_inventory(
    db: Session,
    category: Optional[str] = None,
    only_below_min: bool = False,
) -> ReportResponse:
    filter_info = FilterInfo(
        filter_type="all",
        label="Posição Atual do Estoque e Contagem Física",
    )
    products_q = db.query(Product).filter(Product.is_active == True)
    if category:
        products_q = products_q.filter(Product.category.ilike(f"%{category}%"))
    products = products_q.order_by(Product.name.asc()).all()

    headers = [
        "Item / Produto", "Tipo", "Unidade", "Custo Unit. (R$)",
        "Saldo no Sistema", "Estoque Físico (Contagem)", "Diferença",
        "Estoque Mínimo", "Valor em Estoque (R$)", "Situação"
    ]
    columns = [
        "item_name", "item_type", "unit", "cost_cents",
        "system_stock", "physical_stock", "difference",
        "min_stock", "total_stock_value_cents", "status"
    ]

    rows = []
    tot_value_cents = 0

    for p in products:
        stock_sum = db.query(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).filter(
            InventoryMovement.product_id == p.id,
            InventoryMovement.location_type == "STORE"
        ).scalar() or 0

        if only_below_min and stock_sum >= p.minimum_stock:
            continue

        cost_cents = round(p.cost_price_microcents / 10000.0) if p.cost_price_microcents else 0
        stock_val = cost_cents * stock_sum
        tot_value_cents += stock_val
        status = "ABAIXO DO MÍNIMO" if stock_sum < p.minimum_stock else "REGULAR"

        rows.append({
            "item_name": p.name,
            "item_type": "Insumo / Produto",
            "unit": p.base_unit,
            "cost_cents": cost_cents,
            "system_stock": stock_sum,
            "physical_stock": "",  # Empty for manual writing or filled if counted
            "difference": "",
            "min_stock": p.minimum_stock,
            "total_stock_value_cents": stock_val,
            "status": status,
        })

    # Add Basket types (only when not filtering for below minimum)
    if not only_below_min and (not category or category.lower() in ["cesta", "cestas"]):
        basket_types = db.query(BasketType).filter(BasketType.is_active == True).order_by(BasketType.name.asc()).all()
        for bt in basket_types:
            b_stock = db.query(func.coalesce(func.sum(InventoryMovement.quantity_delta), 0)).filter(
                InventoryMovement.basket_type_id == bt.id,
                InventoryMovement.location_type == "STORE"
            ).scalar() or 0

            rows.append({
                "item_name": f"Cesta: {bt.name}",
                "item_type": "Cesta Pronta",
                "unit": "un",
                "cost_cents": 0,
                "system_stock": b_stock,
                "physical_stock": "",
                "difference": "",
                "min_stock": 0,
                "total_stock_value_cents": 0,
                "status": "REGULAR",
            })

    metadata = ReportMetadata(
        report_type="physical-inventory",
        title="Posição de Estoque e Folha de Contagem Física (Auditoria)",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "total_stock_value_cents": tot_value_cents,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


def get_report_financial_summary(
    db: Session,
    filter_type: str = "today",
    date_str: Optional[str] = None,
    start_date_str: Optional[str] = None,
    end_date_str: Optional[str] = None,
    month: Optional[int] = None,
    year: Optional[int] = None,
) -> ReportResponse:
    start_dt, end_dt, filter_info = resolve_date_filter(
        filter_type, date_str, start_date_str, end_date_str, month, year
    )

    # 1. Gross Revenue & CMV from Sales
    sales_q = db.query(Sale).filter(Sale.status == "CONFIRMED")
    if start_dt and end_dt:
        sales_q = sales_q.filter(Sale.sale_date >= start_dt, Sale.sale_date <= end_dt)
    sales = sales_q.all()

    gross_revenue_cents = sum(s.total_amount_cents for s in sales)
    total_cmv_cents = sum(it.total_cost_cents for s in sales for it in s.items)
    gross_profit_cents = gross_revenue_cents - total_cmv_cents
    margin_percent = round((gross_profit_cents / gross_revenue_cents * 100), 1) if gross_revenue_cents > 0 else 0.0

    # 2. Operating Expenses (Paid in Period)
    cash_debits_q = db.query(CashFlowEntry).filter(
        CashFlowEntry.entry_type == "DEBIT"
    )
    if start_dt and end_dt:
        cash_debits_q = cash_debits_q.filter(
            CashFlowEntry.occurred_at >= start_dt,
            CashFlowEntry.occurred_at <= end_dt
        )
    cash_debits = cash_debits_q.all()

    operating_expenses_cents = sum(d.amount_cents for d in cash_debits if d.nature == "BUSINESS")
    personal_withdrawals_cents = sum(d.amount_cents for d in cash_debits if d.nature == "PERSONAL_WITHDRAWAL")
    net_operating_result_cents = gross_profit_cents - operating_expenses_cents

    # 3. Cash Inflow & Outflow
    cash_credits_q = db.query(CashFlowEntry).filter(CashFlowEntry.entry_type == "CREDIT")
    if start_dt and end_dt:
        cash_credits_q = cash_credits_q.filter(
            CashFlowEntry.occurred_at >= start_dt,
            CashFlowEntry.occurred_at <= end_dt
        )
    cash_inflows_cents = sum(c.amount_cents for c in cash_credits_q.all())
    cash_outflows_cents = sum(c.amount_cents for c in cash_debits)
    net_cash_period_cents = cash_inflows_cents - cash_outflows_cents

    # 4. Current Balance & Projection
    current_balance_cents = db.query(
        func.coalesce(func.sum(FinancialAccount.current_balance_cents), 0)
    ).filter(FinancialAccount.is_active == True).scalar() or 0

    # Filter receivables and payables due within the period
    proj_rec_query = db.query(SalesReceivable).filter(SalesReceivable.status.in_(["OPEN", "PARTIAL"]))
    proj_pay_query = db.query(AccountPayable).filter(AccountPayable.status.in_(["OPEN", "PARTIAL"]))
    if start_dt and end_dt:
        proj_rec_query = proj_rec_query.filter(
            SalesReceivable.due_date >= start_dt,
            SalesReceivable.due_date <= end_dt
        )
        proj_pay_query = proj_pay_query.filter(
            AccountPayable.due_date >= start_dt,
            AccountPayable.due_date <= end_dt
        )
    open_rec_cents = sum(r.balance_cents for r in proj_rec_query.all())
    open_pay_cents = sum(p.balance_cents for p in proj_pay_query.all())
    projected_balance_cents = current_balance_cents + open_rec_cents - open_pay_cents

    headers = ["Indicador Gerencial / Financeiro", "Classificação", "Valor (R$)", "Observação"]
    columns = ["indicator", "classification", "amount_cents", "notes"]

    rows = [
        {"indicator": "1. Receita Bruta de Vendas", "classification": "Receita Operacional", "amount_cents": gross_revenue_cents, "notes": f"{len(sales)} vendas confirmadas no período"},
        {"indicator": "2. Custo das Mercadorias Vendidas (CMV)", "classification": "Custos do Razão", "amount_cents": total_cmv_cents, "notes": "Custo exato congelado nas composições"},
        {"indicator": "3. Lucro Bruto Operacional", "classification": "Resultado Bruto", "amount_cents": gross_profit_cents, "notes": f"Margem Bruta: {margin_percent}%"},
        {"indicator": "4. Despesas Operacionais Pagas", "classification": "Despesas do Negócio", "amount_cents": operating_expenses_cents, "notes": "Energia, aluguel, frete, manutenção, insumos"},
        {"indicator": "5. Resultado Operacional Líquido", "classification": "Lucro Líquido Operacional", "amount_cents": net_operating_result_cents, "notes": "Lucro antes das retiradas particulares"},
        {"indicator": "6. Retiradas de Sócios / Pró-labore", "classification": "Despesas Pessoais", "amount_cents": personal_withdrawals_cents, "notes": "Segregadas do resultado operacional do negócio"},
        {"indicator": "7. Entradas Efetivas de Caixa", "classification": "Fluxo de Caixa", "amount_cents": cash_inflows_cents, "notes": "Dinheiro, Pix e cartões recebidos no período"},
        {"indicator": "8. Saídas Efetivas de Caixa", "classification": "Fluxo de Caixa", "amount_cents": cash_outflows_cents, "notes": "Pagamentos e despesas liquidadas no período"},
        {"indicator": "9. Saldo Líquido do Caixa no Período", "classification": "Fluxo de Caixa", "amount_cents": net_cash_period_cents, "notes": "Variação de tesouraria no período"},
        {"indicator": "10. Saldo Disponível Atual em Tesouraria", "classification": "Posição Financeira Real", "amount_cents": current_balance_cents, "notes": "Soma de todas as contas ativas da empresa"},
        {"indicator": "11. Previsão de Entradas (A Receber)", "classification": "Projeção Futura (Não Realizado)", "amount_cents": open_rec_cents, "notes": "Títulos e fiados em aberto a receber"},
        {"indicator": "12. Previsão de Saídas (A Pagar)", "classification": "Projeção Futura (Não Realizado)", "amount_cents": open_pay_cents, "notes": "Obrigações e títulos em aberto a pagar"},
        {"indicator": "13. Saldo de Caixa Projetado", "classification": "Projeção Financeira", "amount_cents": projected_balance_cents, "notes": "Disponível + A Receber - A Pagar (Projeção)"},
    ]

    metadata = ReportMetadata(
        report_type="financial-summary",
        title="DRE Gerencial e Demonstrativo Financeiro de Caixa",
        generated_at=datetime.datetime.now(datetime.timezone.utc),
        filter_info=filter_info,
        total_rows=len(rows),
    )
    totals = {
        "amount_cents": net_operating_result_cents,
    }
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)


# ==================== THE 4 CANONICAL BLANK & AUDIT FORMS ====================

def get_blank_form_data(
    form_type: str,
    db: Optional[Session] = None,
    filled: bool = False,
) -> ReportResponse:
    """
    Generates the 4 canonical forms.
    When filled=False: produces empty lines for ballpoint pen handwriting.
    When filled=True: populates the EXACT same canonical table columns with real application data for physical audit.
    """
    now = datetime.datetime.now(datetime.timezone.utc)
    label = (
        "Documento Preenchido para Auditoria e Conferência Física"
        if filled
        else "Formulário em Branco para Preenchimento Manual à Caneta"
    )
    filter_info = FilterInfo(filter_type="all", label=label)

    totals: Dict[str, Any] = {}

    if form_type == "payments":
        headers = [
            "Data Venda", "Cliente / Identificação", "Tipo de Cesta", "Qtd",
            "Valor Total (R$)", "Data Prevista", "Data do pagamento", "Total Recebido (R$)",
            "Saldo Restante (R$)", "Quitação / Visto", "Observações"
        ]
        columns = [
            "sale_date", "customer", "basket_type", "qty",
            "total_cents", "due_date", "payment_date", "received_cents",
            "balance_cents", "signature", "notes"
        ]
        title = (
            "Tabela de Pagamentos de Cestas (Auditoria e Conferência Física)"
            if filled
            else "Tabela de Pagamentos de Cestas (Preenchimento Manual à Caneta)"
        )

        rows = []
        if filled and db:
            receivables = db.query(SalesReceivable).options(
                selectinload(SalesReceivable.customer),
                selectinload(SalesReceivable.sale).selectinload(Sale.items).selectinload(SaleItem.basket_type),
            ).filter(SalesReceivable.status != 'CANCELED').order_by(SalesReceivable.due_date.asc()).all()
            latest_payments = dict(db.query(ReceivablePayment.receivable_id, func.max(ReceivablePayment.payment_date))
                .filter(ReceivablePayment.status == 'CONFIRMED').group_by(ReceivablePayment.receivable_id).all())
            tot_val = 0
            tot_rec = 0
            tot_bal = 0
            for r in receivables:
                s = r.sale
                cust_name = r.customer.name if r.customer else (s.customer_name if s else "Consumidor")
                basket_names = ", ".join(it.basket_type.name for it in s.items if it.basket_type) if (s and s.items) else "Cesta Padrão"
                qty = sum(it.quantity for it in s.items) if (s and s.items) else 1

                pay_date = latest_payments.get(r.id) or ''

                status_label = "QUITADO" if r.status == "PAID" else ("PARCIAL" if r.status == "PARTIAL" else "[   ] ABERTO")
                tot_val += r.original_amount_cents
                tot_rec += r.paid_amount_cents
                tot_bal += r.balance_cents

                rows.append({
                    "sale_date": s.sale_date if s else r.created_at,
                    "customer": f"{cust_name} (#{s.sale_number})" if s else cust_name,
                    "basket_type": basket_names,
                    "qty": qty,
                    "total_cents": r.original_amount_cents,
                    "due_date": r.due_date,
                    "payment_date": pay_date,
                    "received_cents": r.paid_amount_cents,
                    "balance_cents": r.balance_cents,
                    "signature": status_label,
                    "notes": "Venda a prazo" if s and s.payment_mode == 'CREDIT_TERM' else "",
                })
            totals = {
                "total_cents": tot_val,
                "received_cents": tot_rec,
                "balance_cents": tot_bal,
            }

    elif form_type == "payables":
        headers = [
            "Descrição da Obrigação", "Beneficiário / Fornecedor", "Categoria", "Valor (R$)",
            "Data Vencimento", "Data do pagamento", "Valor Pago (R$)", "Saldo Restante (R$)", "Forma Pagamento", "Quitação / Visto", "Observações / NF"
        ]
        columns = [
            "description", "beneficiary", "category", "amount_cents",
            "due_date", "payment_date", "paid_amount_cents", "balance_cents", "payment_method", "signature", "notes"
        ]
        title = (
            "Tabela de Contas a Pagar (Auditoria e Conferência Física)"
            if filled
            else "Tabela de Contas a Pagar (Preenchimento Manual à Caneta)"
        )

        rows = []
        if filled and db:
            payables = db.query(AccountPayable).filter(AccountPayable.status != 'CANCELED').order_by(AccountPayable.due_date.asc()).all()
            latest_payments = dict(db.query(PayablePayment.payable_id, func.max(PayablePayment.payment_date))
                .filter(PayablePayment.status == 'CONFIRMED').group_by(PayablePayment.payable_id).all())
            tot_amount = 0
            tot_paid = 0
            tot_balance = 0
            for p in payables:
                pay_date = latest_payments.get(p.id) or ''
                status_label = "QUITADO" if p.status == "PAID" else ("PARCIAL" if p.status == "PARTIAL" else "[   ] ABERTO")
                tot_amount += p.original_amount_cents
                tot_paid += p.paid_amount_cents
                tot_balance += p.balance_cents

                rows.append({
                    "description": p.description,
                    "beneficiary": p.beneficiary,
                    "category": p.category,
                    "amount_cents": p.original_amount_cents,
                    "due_date": p.due_date,
                    "payment_date": pay_date,
                    "paid_amount_cents": p.paid_amount_cents,
                    "balance_cents": p.balance_cents,
                    "payment_method": p.payment_method,
                    "signature": status_label,
                    "notes": p.notes or "",
                })
            totals = {
                "amount_cents": tot_amount,
                "paid_amount_cents": tot_paid,
                "balance_cents": tot_balance,
            }

    elif form_type == "dispatch_conference":
        headers = [
            "Data / Horário", "Responsável", "Tipo de Cesta", "Qtd Retirada", "Preço Unit. (R$)",
            "Personalizações", "Vendidas", "Devolvidas", "Avariadas", "Custódia", "Visto Conferência"
        ]
        columns = [
            "date_time", "responsible", "basket_type", "qty_dispatched", "unit_price_cents",
            "customizations", "qty_sold", "qty_returned", "qty_lost", "qty_custody", "signature"
        ]
        title = (
            "Folha de Conferência de Saídas de Cestas (Auditoria Física)"
            if filled
            else "Folha de Conferência de Saídas de Cestas (Preenchimento Manual)"
        )

        rows = []
        if filled and db:
            dispatches = db.query(StockDispatch).filter(StockDispatch.status != "CANCELED").order_by(StockDispatch.dispatch_date.desc()).all()
            tot_disp = 0
            tot_sold = 0
            for d in dispatches:
                resp_name = d.responsible_person.name if d.responsible_person else "Responsável"
                settlement = d.settlements[0] if d.settlements else None
                for it in d.items:
                    b_name = it.basket_type.name if it.basket_type else "Cesta"
                    # Basket-specific metrics
                    q_sold_item = sum(
                        s_it.quantity
                        for s in d.sales
                        if s.status == "CONFIRMED"
                        for s_it in s.items
                        if s_it.basket_type_id == it.basket_type_id
                    )
                    q_ret_item = sum(
                        r.quantity
                        for r in d.returns
                        if r.basket_type_id == it.basket_type_id
                    )
                    q_lost_item = sum(
                        l.quantity
                        for l in d.losses
                        if l.basket_type_id == it.basket_type_id
                    )
                    q_cust_item = max(0, it.quantity - (q_sold_item + q_ret_item + q_lost_item))
                    sig = settlement.status if settlement else d.status
                    custom_desc = it.notes or ("Personalizada" if (it.production_batch and it.production_batch.is_custom) else "-")

                    tot_disp += it.quantity
                    tot_sold += q_sold_item
                    rows.append({
                        "date_time": d.dispatch_date,
                        "responsible": resp_name,
                        "basket_type": b_name,
                        "qty_dispatched": it.quantity,
                        "unit_price_cents": it.unit_price_cents,
                        "customizations": custom_desc,
                        "qty_sold": q_sold_item,
                        "qty_returned": q_ret_item,
                        "qty_lost": q_lost_item,
                        "qty_custody": q_cust_item,
                        "signature": sig,
                    })
            totals = {
                "qty_dispatched": tot_disp,
                "qty_sold": tot_sold,
            }

    elif form_type == "physical_inventory":
        headers = [
            "Produto / Cesta", "Unidade", "Saldo Sistema", "Quantidade Física (Contada)",
            "Diferença (+/-)", "Observações e Justificativa", "Assinatura / Visto"
        ]
        columns = [
            "item_name", "unit", "system_stock", "physical_stock",
            "difference", "notes", "signature"
        ]
        title = (
            "Folha de Contagem Física de Estoque (Auditoria e Balanço)"
            if filled
            else "Folha de Contagem Física de Estoque (Preenchimento Manual)"
        )

        rows = []
        if filled and db:
            products = db.query(Product).filter(Product.is_active == True).order_by(Product.name.asc()).all()
            product_stocks = dict(db.query(InventoryMovement.product_id, func.sum(InventoryMovement.quantity_delta))
                .filter(InventoryMovement.location_type == 'STORE').group_by(InventoryMovement.product_id).all())
            basket_stocks = dict(db.query(InventoryMovement.basket_type_id, func.sum(InventoryMovement.quantity_delta))
                .filter(InventoryMovement.location_type == 'STORE').group_by(InventoryMovement.basket_type_id).all())
            for p in products:
                stock_sum = product_stocks.get(p.id) or 0
                rows.append({
                    "item_name": p.name,
                    "unit": p.base_unit,
                    "system_stock": stock_sum,
                    "physical_stock": "",  # Empty for pen counting on clipboard!
                    "difference": "",
                    "notes": f"Mínimo: {p.minimum_stock}",
                    "signature": "",
                })

            basket_types = db.query(BasketType).filter(BasketType.is_active == True).order_by(BasketType.name.asc()).all()
            for bt in basket_types:
                b_stock = basket_stocks.get(bt.id) or 0
                rows.append({
                    "item_name": f"Cesta: {bt.name}",
                    "unit": "un",
                    "system_stock": b_stock,
                    "physical_stock": "",
                    "difference": "",
                    "notes": "Estoque loja",
                    "signature": "",
                })

    else:
        raise ValueError(f"Formulário desconhecido: {form_type}")

    # An empty audit must remain empty; handwriting lines are presentation only.
    if not rows and not filled:
        rows = [
            {col: "" for col in columns}
            for _ in range(15)
        ]

    metadata = ReportMetadata(
        report_type=f"{'audit' if filled else 'blank'}-{form_type}",
        title=title,
        generated_at=now,
        filter_info=filter_info,
        total_rows=len(rows),
    )
    return ReportResponse(metadata=metadata, headers=headers, columns=columns, rows=rows, totals=totals)

