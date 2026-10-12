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
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
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
  final int stockTransit;
  final int totalStock;

  BasketStockItem({
    required this.basketTypeId,
    required this.name,
    required this.code,
    required this.stockStore,
    required this.stockTransit,
    required this.totalStock,
  });

  factory BasketStockItem.fromJson(Map<String, dynamic> json) {
    return BasketStockItem(
      basketTypeId: json['basket_type_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      stockStore: json['stock_store'] as int? ?? 0,
      stockTransit: json['stock_transit'] as int? ?? 0,
      totalStock: json['total_stock'] as int? ?? 0,
    );
  }
}

class PendingDivergenceItem {
  final String dispatchId;
  final int dispatchNumber;
  final String responsiblePersonName;
  final DateTime settledAt;
  final int basketDiscrepancyQty;
  final int cashDiscrepancyCents;
  final int directCompanyReceivedCents;
  final String status;
  final String? notes;
  final String? investigationNotes;

  PendingDivergenceItem({
    required this.dispatchId,
    required this.dispatchNumber,
    required this.responsiblePersonName,
    required this.settledAt,
    required this.basketDiscrepancyQty,
    required this.cashDiscrepancyCents,
    required this.directCompanyReceivedCents,
    required this.status,
    this.notes,
    this.investigationNotes,
  });

  factory PendingDivergenceItem.fromJson(Map<String, dynamic> json) {
    return PendingDivergenceItem(
      dispatchId: json['dispatch_id'] as String? ?? '',
      dispatchNumber: json['dispatch_number'] as int? ?? 0,
      responsiblePersonName: json['responsible_person_name'] as String? ?? '',
      settledAt: DateTime.parse(json['settled_at'] as String),
      basketDiscrepancyQty: json['basket_discrepancy_qty'] as int? ?? 0,
      cashDiscrepancyCents: json['cash_discrepancy_cents'] as int? ?? 0,
      directCompanyReceivedCents: json['direct_company_received_cents'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String?,
      investigationNotes: json['investigation_notes'] as String?,
    );
  }
}

class ResponsibleUnremittedItem {
  final String responsiblePersonId;
  final String responsiblePersonName;
  final String? phone;
  final String dispatchId;
  final int dispatchNumber;
  final DateTime dispatchDate;
  final int cashSalesCents;
  final int receivableCashCents;
  final int routeExpensesCents;
  final int repaidCashCents;
  final int unremittedCashCents;
  final String status;

  ResponsibleUnremittedItem({
    required this.responsiblePersonId,
    required this.responsiblePersonName,
    this.phone,
    required this.dispatchId,
    required this.dispatchNumber,
    required this.dispatchDate,
    required this.cashSalesCents,
    required this.receivableCashCents,
    required this.routeExpensesCents,
    required this.repaidCashCents,
    required this.unremittedCashCents,
    required this.status,
  });

  factory ResponsibleUnremittedItem.fromJson(Map<String, dynamic> json) {
    return ResponsibleUnremittedItem(
      responsiblePersonId: json['responsible_person_id'] as String? ?? '',
      responsiblePersonName: json['responsible_person_name'] as String? ?? '',
      phone: json['phone'] as String?,
      dispatchId: json['dispatch_id'] as String? ?? '',
      dispatchNumber: json['dispatch_number'] as int? ?? 0,
      dispatchDate: DateTime.parse(json['dispatch_date'] as String),
      cashSalesCents: json['cash_sales_cents'] as int? ?? 0,
      receivableCashCents: json['receivable_cash_cents'] as int? ?? 0,
      routeExpensesCents: json['route_expenses_cents'] as int? ?? 0,
      repaidCashCents: json['repaid_cash_cents'] as int? ?? 0,
      unremittedCashCents: json['unremitted_cash_cents'] as int? ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

class DashboardBatchRecord {
  final String id;
  final int batchNumber;
  final String basketTypeName;
  final int quantityProduced;
  final int unitCostCents;
  final int totalCostCents;
  final bool isCustom;
  final String status;
  final DateTime occurredAt;

  DashboardBatchRecord({
    required this.id,
    required this.batchNumber,
    required this.basketTypeName,
    required this.quantityProduced,
    required this.unitCostCents,
    required this.totalCostCents,
    required this.isCustom,
    required this.status,
    required this.occurredAt,
  });

  factory DashboardBatchRecord.fromJson(Map<String, dynamic> json) {
    return DashboardBatchRecord(
      id: json['id'] as String? ?? '',
      batchNumber: json['batch_number'] as int? ?? 0,
      basketTypeName: json['basket_type_name'] as String? ?? '',
      quantityProduced: json['quantity_produced'] as int? ?? 0,
      unitCostCents: json['unit_cost_cents'] as int? ?? 0,
      totalCostCents: json['total_cost_cents'] as int? ?? 0,
      isCustom: json['is_custom'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
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

class DashboardDispatchRecord {
  final String id;
  final int dispatchNumber;
  final String responsiblePersonName;
  final DateTime dispatchDate;
  final int totalBaskets;
  final String status;

  DashboardDispatchRecord({
    required this.id,
    required this.dispatchNumber,
    required this.responsiblePersonName,
    required this.dispatchDate,
    required this.totalBaskets,
    required this.status,
  });

  factory DashboardDispatchRecord.fromJson(Map<String, dynamic> json) {
    return DashboardDispatchRecord(
      id: json['id'] as String? ?? '',
      dispatchNumber: json['dispatch_number'] as int? ?? 0,
      responsiblePersonName: json['responsible_person_name'] as String? ?? '',
      dispatchDate: DateTime.parse(json['dispatch_date'] as String),
      totalBaskets: json['total_baskets'] as int? ?? 0,
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

class DashboardCashRecord {
  final String id;
  final String entryType;
  final int amountCents;
  final String category;
  final String nature;
  final String description;
  final DateTime occurredAt;
  final String sourceType;

  DashboardCashRecord({
    required this.id,
    required this.entryType,
    required this.amountCents,
    required this.category,
    required this.nature,
    required this.description,
    required this.occurredAt,
    required this.sourceType,
  });

  factory DashboardCashRecord.fromJson(Map<String, dynamic> json) {
    return DashboardCashRecord(
      id: json['id'] as String? ?? '',
      entryType: json['entry_type'] as String? ?? 'CREDIT',
      amountCents: json['amount_cents'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      nature: json['nature'] as String? ?? 'BUSINESS',
      description: json['description'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      sourceType: json['source_type'] as String? ?? 'MANUAL',
    );
  }
}

class DashboardProductionSummary {
  final int assembledCount;
  final List<BasketTypeCount> byBasketType;
  final List<DashboardBatchRecord> batches;

  DashboardProductionSummary({
    required this.assembledCount,
    required this.byBasketType,
    required this.batches,
  });

  factory DashboardProductionSummary.fromJson(Map<String, dynamic> json) {
    return DashboardProductionSummary(
      assembledCount: json['assembled_count'] as int? ?? 0,
      byBasketType: (json['by_basket_type'] as List<dynamic>? ?? [])
          .map((e) => BasketTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      batches: (json['batches'] as List<dynamic>? ?? [])
          .map((e) => DashboardBatchRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
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

class DashboardDispatchesSummary {
  final int dispatchedCount;
  final List<BasketTypeCount> byBasketType;
  final int responsibleUnremittedCents;
  final List<ResponsibleUnremittedItem> responsibleUnremittedItems;
  final int pendingDivergencesCount;
  final List<PendingDivergenceItem> pendingDivergences;
  final List<DashboardDispatchRecord> dispatches;

  DashboardDispatchesSummary({
    required this.dispatchedCount,
    required this.byBasketType,
    required this.responsibleUnremittedCents,
    this.responsibleUnremittedItems = const [],
    required this.pendingDivergencesCount,
    required this.pendingDivergences,
    required this.dispatches,
  });

  factory DashboardDispatchesSummary.fromJson(Map<String, dynamic> json) {
    return DashboardDispatchesSummary(
      dispatchedCount: json['dispatched_count'] as int? ?? 0,
      byBasketType: (json['by_basket_type'] as List<dynamic>? ?? [])
          .map((e) => BasketTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      responsibleUnremittedCents: json['responsible_unremitted_cents'] as int? ?? 0,
      responsibleUnremittedItems: (json['responsible_unremitted_items'] as List<dynamic>? ?? [])
          .map((e) => ResponsibleUnremittedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingDivergencesCount: json['pending_divergences_count'] as int? ?? 0,
      pendingDivergences: (json['pending_divergences'] as List<dynamic>? ?? [])
          .map((e) => PendingDivergenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dispatches: (json['dispatches'] as List<dynamic>? ?? [])
          .map((e) => DashboardDispatchRecord.fromJson(e as Map<String, dynamic>))
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

class DashboardFinancialSummary {
  final int receivablesOpenCents;
  final int receivablesOverdueCents;
  final int effectiveReceivedCents;
  final int payablesOpenCents;
  final int payablesOverdueCents;
  final int effectivePaidCents;
  final int cashInflowCents;
  final int cashOutflowCents;
  final int netCashFlowCents;
  final int currentTreasuryBalanceCents;
  final int projectedInflowCents;
  final int projectedOutflowCents;
  final int projectedTreasuryBalanceCents;
  final List<DashboardReceivableRecord> receivablesRecords;
  final List<DashboardPayableRecord> payablesRecords;
  final List<DashboardCashRecord> cashRecords;

  DashboardFinancialSummary({
    required this.receivablesOpenCents,
    required this.receivablesOverdueCents,
    required this.effectiveReceivedCents,
    required this.payablesOpenCents,
    required this.payablesOverdueCents,
    required this.effectivePaidCents,
    required this.cashInflowCents,
    required this.cashOutflowCents,
    required this.netCashFlowCents,
    required this.currentTreasuryBalanceCents,
    required this.projectedInflowCents,
    required this.projectedOutflowCents,
    required this.projectedTreasuryBalanceCents,
    required this.receivablesRecords,
    required this.payablesRecords,
    required this.cashRecords,
  });

  factory DashboardFinancialSummary.fromJson(Map<String, dynamic> json) {
    return DashboardFinancialSummary(
      receivablesOpenCents: json['receivables_open_cents'] as int? ?? 0,
      receivablesOverdueCents: json['receivables_overdue_cents'] as int? ?? 0,
      effectiveReceivedCents: json['effective_received_cents'] as int? ?? 0,
      payablesOpenCents: json['payables_open_cents'] as int? ?? 0,
      payablesOverdueCents: json['payables_overdue_cents'] as int? ?? 0,
      effectivePaidCents: json['effective_paid_cents'] as int? ?? 0,
      cashInflowCents: json['cash_inflow_cents'] as int? ?? 0,
      cashOutflowCents: json['cash_outflow_cents'] as int? ?? 0,
      netCashFlowCents: json['net_cash_flow_cents'] as int? ?? 0,
      currentTreasuryBalanceCents: json['current_treasury_balance_cents'] as int? ?? 0,
      projectedInflowCents: json['projected_inflow_cents'] as int? ?? 0,
      projectedOutflowCents: json['projected_outflow_cents'] as int? ?? 0,
      projectedTreasuryBalanceCents: json['projected_treasury_balance_cents'] as int? ?? 0,
      receivablesRecords: (json['receivables_records'] as List<dynamic>? ?? [])
          .map((e) => DashboardReceivableRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      payablesRecords: (json['payables_records'] as List<dynamic>? ?? [])
          .map((e) => DashboardPayableRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      cashRecords: (json['cash_records'] as List<dynamic>? ?? [])
          .map((e) => DashboardCashRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardSummary {
  final FilterInfo filterInfo;
  final DashboardProductionSummary production;
  final DashboardSalesSummary sales;
  final DashboardDispatchesSummary dispatches;
  final DashboardInventorySummary inventory;
  final DashboardFinancialSummary financial;

  DashboardSummary({
    required this.filterInfo,
    required this.production,
    required this.sales,
    required this.dispatches,
    required this.inventory,
    required this.financial,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      filterInfo: FilterInfo.fromJson(json['filter_info'] as Map<String, dynamic>),
      production: DashboardProductionSummary.fromJson(json['production'] as Map<String, dynamic>),
      sales: DashboardSalesSummary.fromJson(json['sales'] as Map<String, dynamic>),
      dispatches: DashboardDispatchesSummary.fromJson(json['dispatches'] as Map<String, dynamic>),
      inventory: DashboardInventorySummary.fromJson(json['inventory'] as Map<String, dynamic>),
      financial: DashboardFinancialSummary.fromJson(json['financial'] as Map<String, dynamic>),
    );
  }
}
