class FilterInfo {
  final String filterType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String label;

  FilterInfo({
    required this.filterType,
    this.startDate,
    this.endDate,
    required this.label,
  });

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      filterType: json['filter_type'] as String? ?? 'today',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      label: json['label'] as String? ?? '',
    );
  }
}

class BasketTypeCount {
  final String basketTypeId;
  final String basketTypeName;
  final int count;
  final int totalCents;

  BasketTypeCount({
    required this.basketTypeId,
    required this.basketTypeName,
    required this.count,
    this.totalCents = 0,
  });

  factory BasketTypeCount.fromJson(Map<String, dynamic> json) {
    return BasketTypeCount(
      basketTypeId: json['basket_type_id'] as String? ?? '',
      basketTypeName: json['basket_type_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalCents: json['total_cents'] as int? ?? 0,
    );
  }
}

class LowStockItem {
  final String id;
  final String name;
  final String? sku;
  final String baseUnit;
  final int currentStock;
  final int minStock;
  final int difference;

  LowStockItem({
    required this.id,
    required this.name,
    this.sku,
    required this.baseUnit,
    required this.currentStock,
    required this.minStock,
    required this.difference,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      baseUnit: json['base_unit'] as String? ?? 'un',
      currentStock: json['current_stock'] as int? ?? 0,
      minStock: json['min_stock'] as int? ?? 0,
      difference: json['difference'] as int? ?? 0,
    );
  }
}

class BasketStockItem {
  final String basketTypeId;
  final String name;
  final String code;
  final int stockStore;

  BasketStockItem({
    required this.basketTypeId,
    required this.name,
    required this.code,
    required this.stockStore,
  });

  factory BasketStockItem.fromJson(Map<String, dynamic> json) {
    return BasketStockItem(
      basketTypeId: json['basket_type_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      stockStore: json['stock_store'] as int? ?? 0,
    );
  }
}

class DashboardSaleRecord {
  final String id;
  final int saleNumber;
  final String? customerName;
  final String saleMode;
  final String paymentMode;
  final String paymentStatus;
  final int totalAmountCents;
  final DateTime saleDate;
  final String status;

  DashboardSaleRecord({
    required this.id,
    required this.saleNumber,
    this.customerName,
    required this.saleMode,
    required this.paymentMode,
    required this.paymentStatus,
    required this.totalAmountCents,
    required this.saleDate,
    required this.status,
  });

  factory DashboardSaleRecord.fromJson(Map<String, dynamic> json) {
    return DashboardSaleRecord(
      id: json['id'] as String? ?? '',
      saleNumber: json['sale_number'] as int? ?? 0,
      customerName: json['customer_name'] as String?,
      saleMode: json['sale_mode'] as String? ?? 'DIRECT_STORE',
      paymentMode: json['payment_mode'] as String? ?? 'CASH_IMMEDIATE',
      paymentStatus: json['payment_status'] as String? ?? 'PAID',
      totalAmountCents: json['total_amount_cents'] as int? ?? 0,
      saleDate: DateTime.parse(json['sale_date'] as String),
      status: json['status'] as String? ?? '',
    );
  }
}

class DashboardReceivableRecord {
  final String id;
  final int saleNumber;
  final String customerName;
  final DateTime dueDate;
  final int originalAmountCents;
  final int paidAmountCents;
  final int balanceCents;
  final String status;
  final bool isOverdue;

  DashboardReceivableRecord({
    required this.id,
    required this.saleNumber,
    required this.customerName,
    required this.dueDate,
    required this.originalAmountCents,
    required this.paidAmountCents,
    required this.balanceCents,
    required this.status,
    required this.isOverdue,
  });

  factory DashboardReceivableRecord.fromJson(Map<String, dynamic> json) {
    return DashboardReceivableRecord(
      id: json['id'] as String? ?? '',
      saleNumber: json['sale_number'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date'] as String),
      originalAmountCents: json['original_amount_cents'] as int? ?? 0,
      paidAmountCents: json['paid_amount_cents'] as int? ?? 0,
      balanceCents: json['balance_cents'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }
}

class DashboardPayableRecord {
  final String id;
  final int payableNumber;
  final String beneficiary;
  final String category;
  final String nature;
  final DateTime dueDate;
  final int originalAmountCents;
  final int paidAmountCents;
  final int balanceCents;
  final String status;
  final bool isOverdue;

  DashboardPayableRecord({
    required this.id,
    required this.payableNumber,
    required this.beneficiary,
    required this.category,
    required this.nature,
    required this.dueDate,
    required this.originalAmountCents,
    required this.paidAmountCents,
    required this.balanceCents,
    required this.status,
    required this.isOverdue,
  });

  factory DashboardPayableRecord.fromJson(Map<String, dynamic> json) {
    return DashboardPayableRecord(
      id: json['id'] as String? ?? '',
      payableNumber: json['payable_number'] as int? ?? 0,
      beneficiary: json['beneficiary'] as String? ?? '',
      category: json['category'] as String? ?? '',
      nature: json['nature'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date'] as String),
      originalAmountCents: json['original_amount_cents'] as int? ?? 0,
      paidAmountCents: json['paid_amount_cents'] as int? ?? 0,
      balanceCents: json['balance_cents'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }
}

class DashboardSalesSummary {
  final int soldCount;
  final int totalSoldCents;
  final List<BasketTypeCount> byBasketType;
  final List<DashboardSaleRecord> sales;

  DashboardSalesSummary({
    required this.soldCount,
    required this.totalSoldCents,
    required this.byBasketType,
    required this.sales,
  });

  factory DashboardSalesSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSalesSummary(
      soldCount: json['sold_count'] as int? ?? 0,
      totalSoldCents: json['total_sold_cents'] as int? ?? 0,
      byBasketType: (json['by_basket_type'] as List<dynamic>? ?? [])
          .map((e) => BasketTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      sales: (json['sales'] as List<dynamic>? ?? [])
          .map((e) => DashboardSaleRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardInventorySummary {
  final int totalProductsCount;
  final int lowStockProductsCount;
  final List<LowStockItem> lowStockItems;
  final List<BasketStockItem> basketStock;

  DashboardInventorySummary({
    required this.totalProductsCount,
    required this.lowStockProductsCount,
    required this.lowStockItems,
    required this.basketStock,
  });

  factory DashboardInventorySummary.fromJson(Map<String, dynamic> json) {
    return DashboardInventorySummary(
      totalProductsCount: json['total_products_count'] as int? ?? 0,
      lowStockProductsCount: json['low_stock_products_count'] as int? ?? 0,
      lowStockItems: (json['low_stock_items'] as List<dynamic>? ?? [])
          .map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      basketStock: (json['basket_stock'] as List<dynamic>? ?? [])
          .map((e) => BasketStockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BusinessPaymentRecord {
  final String id;
  final String description;
  final int amountCents;
  final DateTime occurredAt;
  final String paymentMethod;
  final bool isReversal;

  BusinessPaymentRecord(
      {required this.id,
      required this.description,
      required this.amountCents,
      required this.occurredAt,
      required this.paymentMethod,
      required this.isReversal});

  factory BusinessPaymentRecord.fromJson(Map<String, dynamic> json) =>
      BusinessPaymentRecord(
        id: json['id'] as String,
        description: json['description'] as String,
        amountCents: (json['amount_cents'] as num).toInt(),
        occurredAt: DateTime.parse(json['occurred_at'] as String),
        paymentMethod: json['payment_method'] as String,
        isReversal: json['is_reversal'] as bool? ?? false,
      );
}

class DashboardFinancialSummary {
  final int effectiveReceivedCents;
  final int effectivePaidCents;
  final int paymentDifferenceCents;
  final int receivablesOpenCents;
  final int receivablesOverdueCents;
  final int payablesOpenCents;
  final int payablesOverdueCents;
  final int receivablesDueInPeriodCents;
  final int payablesDueInPeriodCents;
  final int salesRevenueCents;
  final int soldBasketsCostCents;
  final int grossProfitCents;
  final int operatingExpensesPaidCents;
  final int operatingResultCents;
  final int stockPurchasesPaidCents;
  final int personalWithdrawalsPaidCents;
  final int salesWithoutCostCount;
  final List<BusinessPaymentRecord> receivedRecords;
  final List<BusinessPaymentRecord> paidRecords;
  final int? treasuryBalanceCents;
  final List<Map<String, dynamic>> accountsBalances;
  final List<DashboardReceivableRecord> receivablesRecords;
  final List<DashboardPayableRecord> payablesRecords;

  DashboardFinancialSummary({
    this.treasuryBalanceCents,
    this.accountsBalances = const [],
    this.effectiveReceivedCents = 0,
    this.effectivePaidCents = 0,
    this.paymentDifferenceCents = 0,
    this.receivablesOpenCents = 0,
    this.receivablesOverdueCents = 0,
    this.payablesOpenCents = 0,
    this.payablesOverdueCents = 0,
    this.receivablesDueInPeriodCents = 0,
    this.payablesDueInPeriodCents = 0,
    this.salesRevenueCents = 0,
    this.soldBasketsCostCents = 0,
    this.grossProfitCents = 0,
    this.operatingExpensesPaidCents = 0,
    this.operatingResultCents = 0,
    this.stockPurchasesPaidCents = 0,
    this.personalWithdrawalsPaidCents = 0,
    this.salesWithoutCostCount = 0,
    this.receivedRecords = const [],
    this.paidRecords = const [],
    this.receivablesRecords = const [],
    this.payablesRecords = const [],
  });

  factory DashboardFinancialSummary.fromJson(Map<String, dynamic> json) =>
      DashboardFinancialSummary(
        treasuryBalanceCents: (json['available_balance_cents'] ??
                json['treasury_balance_cents'] as num?)
            ?.toInt(),
        accountsBalances: (json['accounts_balances'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        effectiveReceivedCents:
            (json['effective_received_cents'] as num?)?.toInt() ?? 0,
        effectivePaidCents:
            (json['effective_paid_cents'] as num?)?.toInt() ?? 0,
        paymentDifferenceCents:
            (json['payment_difference_cents'] as num?)?.toInt() ?? 0,
        receivablesOpenCents:
            (json['receivables_open_cents'] as num?)?.toInt() ?? 0,
        receivablesOverdueCents:
            (json['receivables_overdue_cents'] as num?)?.toInt() ?? 0,
        payablesOpenCents: (json['payables_open_cents'] as num?)?.toInt() ?? 0,
        payablesOverdueCents:
            (json['payables_overdue_cents'] as num?)?.toInt() ?? 0,
        receivablesDueInPeriodCents:
            (json['receivables_due_in_period_cents'] as num?)?.toInt() ?? 0,
        payablesDueInPeriodCents:
            (json['payables_due_in_period_cents'] as num?)?.toInt() ?? 0,
        salesRevenueCents: (json['sales_revenue_cents'] as num?)?.toInt() ?? 0,
        soldBasketsCostCents:
            (json['sold_baskets_cost_cents'] as num?)?.toInt() ?? 0,
        grossProfitCents: (json['gross_profit_cents'] as num?)?.toInt() ?? 0,
        operatingExpensesPaidCents:
            (json['operating_expenses_paid_cents'] as num?)?.toInt() ?? 0,
        operatingResultCents:
            (json['operating_result_cents'] as num?)?.toInt() ?? 0,
        stockPurchasesPaidCents:
            (json['stock_purchases_paid_cents'] as num?)?.toInt() ?? 0,
        personalWithdrawalsPaidCents:
            (json['personal_withdrawals_paid_cents'] as num?)?.toInt() ?? 0,
        salesWithoutCostCount:
            (json['sales_without_cost_count'] as num?)?.toInt() ?? 0,
        receivedRecords: (json['received_records'] as List<dynamic>? ?? [])
            .map((e) =>
                BusinessPaymentRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        paidRecords: (json['paid_records'] as List<dynamic>? ?? [])
            .map((e) =>
                BusinessPaymentRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        receivablesRecords: (json['receivables_records'] as List<dynamic>? ??
                [])
            .map((e) =>
                DashboardReceivableRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        payablesRecords: (json['payables_records'] as List<dynamic>? ?? [])
            .map((e) =>
                DashboardPayableRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DashboardSummary {
  final FilterInfo filterInfo;
  final DashboardSalesSummary sales;
  final DashboardPurchasesSummary purchases;
  final DashboardInventorySummary inventory;
  final DashboardFinancialSummary financial;

  DashboardSummary(
      {required this.filterInfo,
      required this.sales,
      required this.purchases,
      required this.inventory,
      required this.financial});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        filterInfo:
            FilterInfo.fromJson(json['filter_info'] as Map<String, dynamic>),
        sales: DashboardSalesSummary.fromJson(
            json['sales'] as Map<String, dynamic>),
        purchases: DashboardPurchasesSummary.fromJson(
            json['purchases'] as Map<String, dynamic>? ?? {}),
        inventory: DashboardInventorySummary.fromJson(
            json['inventory'] as Map<String, dynamic>),
        financial: DashboardFinancialSummary.fromJson(
            json['financial'] as Map<String, dynamic>),
      );
}

class DashboardPurchasesSummary {
  final int purchaseCount;
  final int totalAmountCents;
  DashboardPurchasesSummary(
      {required this.purchaseCount, required this.totalAmountCents});
  factory DashboardPurchasesSummary.fromJson(Map<String, dynamic> json) =>
      DashboardPurchasesSummary(
        purchaseCount: (json['purchase_count'] as num?)?.toInt() ?? 0,
        totalAmountCents: (json['total_amount_cents'] as num?)?.toInt() ?? 0,
      );
}
