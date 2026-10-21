"""Read-only overview based on sales and their confirmed financial events.

Manual deposits, account balances, transfers and route custody are intentionally
outside the active business dashboard. Immutable payment events are retained so
reversals affect the period when they actually occurred.
"""
import datetime
from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload
from app.models.products import Product, BasketType
from app.models.movements import InventoryMovement
from app.models.sales import Sale, SalesReceivable
from app.models.purchases import Purchase
from app.models.financial import CashFlowEntry, AccountPayable, PayablePayment, FinancialAccount
from app.models.base import utc_now
from app.schemas.reports import (
    FilterInfo, BasketTypeCount, LowStockItem, DashboardSalesSummary,
    DashboardSaleRecord, DashboardReceivableRecord, DashboardPayableRecord,
    ReportMetadata, ReportResponse,
)
from app.schemas.business_dashboard import (
    BusinessBasketStock, BusinessInventory, BusinessPaymentRecord,
    BusinessFinancialSummary, BusinessDashboardResponse,
    BusinessPurchases,
)
from app.services.reports import resolve_date_filter, _to_utc_aware

# Current company timezone: America/Sao_Paulo (UTC-03). No new timezone dependency.
BUSINESS_TZ = datetime.timezone(datetime.timedelta(hours=-3))


def resolve_business_period(filter_type="today", date_str=None, start_date_str=None,
                            end_date_str=None, month=None, year=None):
    today = utc_now().astimezone(BUSINESS_TZ).date()
    effective_type = "date" if filter_type == "today" else filter_type
    start, end, info = resolve_date_filter(
        effective_type, today.isoformat() if filter_type == "today" else date_str,
        start_date_str, end_date_str, month or today.month, year or today.year,
    )
    # The original helper constructs calendar days at UTC midnight. These days
    # belong to the company's local calendar; convert those boundaries to UTC.
    start = start.replace(tzinfo=BUSINESS_TZ).astimezone(datetime.timezone.utc) if start else None
    end = end.replace(tzinfo=BUSINESS_TZ).astimezone(datetime.timezone.utc) if end else None
    if filter_type == "today":
        info.filter_type = "today"
        info.label = f"Hoje ({today.strftime('%d/%m/%Y')})"
    info.start_date, info.end_date = start, end
    return start, end, info


def _in_period(query, column, start, end):
    return query.filter(column >= start, column <= end) if start and end else query


def get_business_dashboard(db: Session, filter_type="today", date_str=None,
                           start_date_str=None, end_date_str=None, month=None, year=None):
    start, end, info = resolve_business_period(
        filter_type, date_str, start_date_str, end_date_str, month, year,
    )
    today = utc_now().astimezone(BUSINESS_TZ).date()
    sales = _in_period(
        db.query(Sale).options(selectinload(Sale.items), selectinload(Sale.customer))
        .filter(Sale.status == "CONFIRMED"), Sale.sale_date, start, end,
    ).order_by(Sale.sale_date.desc()).all()
    by_type = {}
    basket_types = db.query(BasketType).all()
    names = {b.id: b.name for b in basket_types}
    sold_count = cost = missing_cost = 0
    for sale in sales:
        if not sale.items or any(i.total_cost_cents <= 0 for i in sale.items):
            missing_cost += 1
        for item in sale.items:
            sold_count += item.quantity
            cost += item.total_cost_cents
            count = by_type.setdefault(item.basket_type_id, BasketTypeCount(
                basket_type_id=item.basket_type_id,
                basket_type_name=names.get(item.basket_type_id, "Cesta"), count=0, total_cents=0,
            ))
            count.count += item.quantity
            count.total_cents += item.total_cents
    revenue = sum(s.total_amount_cents for s in sales)
    sales_summary = DashboardSalesSummary(
        sold_count=sold_count, total_sold_cents=revenue, by_basket_type=list(by_type.values()),
        sales=[DashboardSaleRecord(
            id=s.id, sale_number=s.sale_number,
            customer_name=s.customer.name if s.customer else s.customer_name,
            sale_mode=s.sale_mode, payment_mode=s.payment_mode, payment_status=s.payment_status,
            total_amount_cents=s.total_amount_cents, sale_date=_to_utc_aware(s.sale_date), status=s.status,
        ) for s in sales],
    )
    stocks = dict(db.query(InventoryMovement.product_id, func.sum(InventoryMovement.quantity_delta))
                  .filter(InventoryMovement.item_type == "PRODUCT", InventoryMovement.location_type == "STORE")
                  .group_by(InventoryMovement.product_id).all())
    products = db.query(Product).filter(Product.is_active.is_(True)).all()
    low = [LowStockItem(
        id=p.id, name=p.name, sku=p.sku, base_unit=p.base_unit,
        current_stock=stocks.get(p.id, 0), min_stock=p.minimum_stock,
        difference=p.minimum_stock - stocks.get(p.id, 0),
    ) for p in products if stocks.get(p.id, 0) < p.minimum_stock]
    basket_stocks = dict(db.query(InventoryMovement.basket_type_id, func.sum(InventoryMovement.quantity_delta))
                         .filter(InventoryMovement.item_type == "BASKET", InventoryMovement.location_type == "STORE")
                         .group_by(InventoryMovement.basket_type_id).all())
    inventory = BusinessInventory(
        total_products_count=len(products), low_stock_products_count=len(low), low_stock_items=low,
        basket_stock=[BusinessBasketStock(basket_type_id=b.id, name=b.name, code=b.code,
                     stock_store=basket_stocks.get(b.id, 0)) for b in basket_types if b.is_active],
    )

    receivables = db.query(SalesReceivable).options(
        selectinload(SalesReceivable.sale), selectinload(SalesReceivable.customer)
    ).filter(SalesReceivable.status.in_(["OPEN", "PARTIAL"])).order_by(SalesReceivable.due_date).all()
    payables = db.query(AccountPayable).filter(AccountPayable.status.in_(["OPEN", "PARTIAL"]))\
        .order_by(AccountPayable.due_date).all()
    # Due dates are calendar dates, unlike the UTC timestamps of actual payments.
    def due_in_period(record):
        return not start or start.astimezone(BUSINESS_TZ).date() <= record.due_date.date() <= end.astimezone(BUSINESS_TZ).date()

    def due_date(record):
        return datetime.datetime.combine(record.due_date.date(), datetime.time.min, BUSINESS_TZ)

    # Only events created by active sales, receivable, payable, purchase flows, or bank statement imports.
    # Never infer company receipts from manual credits or inter-account transfers.
    entries = _in_period(db.query(CashFlowEntry).filter(CashFlowEntry.source_type.in_(
        ["SALE", "RECEIVABLE_PAYMENT", "PAYABLE_PAYMENT", "PURCHASE", "BANK_IMPORT"]
    )), CashFlowEntry.occurred_at, start, end).order_by(CashFlowEntry.occurred_at.desc()).all()
    payment_ids = {e.source_id for e in entries if e.source_type == "PAYABLE_PAYMENT"}
    payments = db.query(PayablePayment).options(selectinload(PayablePayment.payable))\
        .filter(PayablePayment.id.in_(payment_ids)).all() if payment_ids else []
    payment_map = {p.id: p for p in payments}
    received = paid = stock_paid = expenses = withdrawals = unclassified_paid = 0
    received_records, paid_records = [], []
    for entry in entries:
        is_receipt = entry.source_type in ["SALE", "RECEIVABLE_PAYMENT"] or (
            entry.source_type == "BANK_IMPORT" and entry.entry_type == "CREDIT"
        )
        amount = entry.amount_cents * (1 if entry.entry_type == ("CREDIT" if is_receipt else "DEBIT") else -1)
        record = BusinessPaymentRecord(
            id=entry.id, description=entry.description, amount_cents=amount,
            occurred_at=_to_utc_aware(entry.occurred_at), payment_method=entry.payment_method,
            is_reversal=amount < 0,
        )
        if is_receipt:
            received += amount
            received_records.append(record)
        else:
            paid += amount
            paid_records.append(record)
            payment = payment_map.get(entry.source_id)
            from app.services.financial_payment_composition import entry_composition
            composition = entry_composition(entry, payment)
            withdrawals += composition['personal_cents']
            stock_paid += composition['stock_cents']
            expenses += composition['business_cents']
            unclassified_paid += composition['unclassified_cents']
    active_accounts = db.query(FinancialAccount).filter(FinancialAccount.is_active.is_(True))\
        .order_by(FinancialAccount.is_default.desc(), FinancialAccount.name).all()
    available_balance = sum(a.current_balance_cents for a in active_accounts)
    accounts_balances = [
        {
            "id": a.id,
            "name": a.name,
            "account_type": a.account_type,
            "bank_name": a.bank_name,
            "account_number": a.account_number,
            "current_balance_cents": a.current_balance_cents,
            "is_default": a.is_default,
        }
        for a in active_accounts
    ]
    financial = BusinessFinancialSummary(
        available_balance_cents=available_balance,
        accounts_balances=accounts_balances,
        effective_received_cents=received, effective_paid_cents=paid,
        payment_difference_cents=received - paid,
        receivables_open_cents=sum(r.balance_cents for r in receivables),
        receivables_overdue_cents=sum(r.balance_cents for r in receivables if r.due_date.date() < today),
        payables_open_cents=sum(p.balance_cents for p in payables),
        payables_overdue_cents=sum(p.balance_cents for p in payables if p.due_date.date() < today),
        receivables_due_in_period_cents=sum(r.balance_cents for r in receivables if due_in_period(r)),
        payables_due_in_period_cents=sum(p.balance_cents for p in payables if due_in_period(p)),
        sales_revenue_cents=revenue, sold_baskets_cost_cents=cost,
        gross_profit_cents=revenue - cost, operating_expenses_paid_cents=expenses,
        operating_result_cents=revenue - cost - expenses,
        stock_purchases_paid_cents=stock_paid, personal_withdrawals_paid_cents=withdrawals,
        unclassified_paid_cents=unclassified_paid,
        sales_without_cost_count=missing_cost, received_records=received_records, paid_records=paid_records,
        receivables_records=[DashboardReceivableRecord(
            id=r.id, sale_number=r.sale.sale_number if r.sale else 0,
            customer_name=r.customer.name if r.customer else "Cliente", due_date=due_date(r),
            original_amount_cents=r.original_amount_cents, paid_amount_cents=r.paid_amount_cents,
            balance_cents=r.balance_cents, status=r.status, is_overdue=r.due_date.date() < today,
        ) for r in receivables],
        payables_records=[DashboardPayableRecord(
            id=p.id, payable_number=p.payable_number, beneficiary=p.beneficiary,
            category=p.category, nature=p.nature, due_date=due_date(p),
            original_amount_cents=p.original_amount_cents, paid_amount_cents=p.paid_amount_cents,
            balance_cents=p.balance_cents, status=p.status, is_overdue=p.due_date.date() < today,
        ) for p in payables],
    )
    purchases = _in_period(db.query(Purchase).filter(Purchase.status == "CONFIRMED"),
                           Purchase.purchase_date, start, end).all()
    purchases_summary = BusinessPurchases(purchase_count=len(purchases),
        total_amount_cents=sum(p.total_amount_cents for p in purchases))
    return BusinessDashboardResponse(filter_info=info, sales=sales_summary,
                                    purchases=purchases_summary, inventory=inventory, financial=financial)


def get_business_financial_report(db: Session, **filters) -> ReportResponse:
    overview = get_business_dashboard(db, **filters)
    f = overview.financial
    indicators = [
        ("Valor das vendas", f.sales_revenue_cents, "Inclui vendas a prazo, mesmo ainda não recebidas."),
        ("Custo das cestas vendidas", f.sold_baskets_cost_cents, "Custo registrado na venda; não descontar a compra dos insumos novamente."),
        ("Lucro bruto das vendas", f.gross_profit_cents, "Valor das vendas menos o custo das cestas vendidas."),
        ("Outras despesas do negócio pagas", f.operating_expenses_paid_cents, "Exclui compras de estoque vinculadas e retiradas pessoais."),
        ("Resultado gerencial do período", f.operating_result_cents, "Lucro bruto menos outras despesas pagas; pode incluir vendas ainda não recebidas."),
        ("Recebimentos confirmados", f.effective_received_cents, "Vendas à vista e recebimentos de fiados, com seus estornos."),
        ("Pagamentos confirmados", f.effective_paid_cents, "Compras e obrigações pagas, com seus estornos."),
        ("Diferença entre recebido e pago", f.payment_difference_cents, "Comparação do período; não é saldo bancário nem lucro."),
        ("Compras de estoque pagas", f.stock_purchases_paid_cents, "Já estão nos pagamentos; o custo vendido é apurado separadamente."),
        ("Retiradas pessoais pagas", f.personal_withdrawals_paid_cents, "Já estão nos pagamentos; não reduzem o resultado das vendas."),
        ("Pagamentos sem finalidade informada", f.unclassified_paid_cents, "Incluídos nos pagamentos; finalidade pendente, sem despesa operacional presumida."),
        ("Total pendente a receber", f.receivables_open_cents, "Pendências atuais, independentemente do período selecionado."),
        ("Total pendente a pagar", f.payables_open_cents, "Pendências atuais, independentemente do período selecionado."),
        ("A receber com vencimento no período", f.receivables_due_in_period_cents, "Somente valores ainda pendentes."),
        ("A pagar com vencimento no período", f.payables_due_in_period_cents, "Somente valores ainda pendentes."),
    ]
    if f.sales_without_cost_count:
        indicators.append(("Vendas com custo incompleto", 0, f"{f.sales_without_cost_count} venda(s); resultado gerencial incompleto."))
    rows = [{"indicator": label, "amount_cents": amount, "notes": note} for label, amount, note in indicators]
    return ReportResponse(
        metadata=ReportMetadata(report_type="business-financial-summary", title="Resultado, Recebimentos e Pagamentos",
                                generated_at=utc_now(), filter_info=overview.filter_info, total_rows=len(rows)),
        headers=["Indicador", "Valor (R$)", "Como interpretar"], columns=["indicator", "amount_cents", "notes"],
        rows=rows, totals={},
    )
