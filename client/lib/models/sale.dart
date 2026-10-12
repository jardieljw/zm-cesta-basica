class SaleItemCustomIngredient {
  final String productId;
  final int quantityInBaseUnits;
  final String? section;

  SaleItemCustomIngredient({
    required this.productId,
    required this.quantityInBaseUnits,
    this.section = 'PERSONALIZADO',
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity_in_base_units': quantityInBaseUnits,
        'section': section,
      };

  factory SaleItemCustomIngredient.fromJson(Map<String, dynamic> json) =>
      SaleItemCustomIngredient(
        productId: json['product_id'] as String,
        quantityInBaseUnits: (json['quantity_in_base_units'] as num).toInt(),
        section: json['section'] as String?,
      );
}

class SaleItemCreate {
  final String basketTypeId;
  final int quantity;
  final int unitPriceCents;
  final int discountCents;
  final bool assembleOnDemand;
  final bool isCustom;
  final String? customDescription;
  final List<SaleItemCustomIngredient>? customItems;
  final String? productionBatchId;

  SaleItemCreate({
    required this.basketTypeId,
    required this.quantity,
    required this.unitPriceCents,
    this.discountCents = 0,
    this.assembleOnDemand = false,
    this.isCustom = false,
    this.customDescription,
    this.customItems,
    this.productionBatchId,
  });

  Map<String, dynamic> toJson() => {
        'basket_type_id': basketTypeId,
        'quantity': quantity,
        'unit_price_cents': unitPriceCents,
        'discount_cents': discountCents,
        'assemble_on_demand': assembleOnDemand,
        'is_custom': isCustom,
        'custom_description': customDescription,
        'custom_items': customItems?.map((e) => e.toJson()).toList(),
        'production_batch_id': productionBatchId,
      };
}

class SaleCreate {
  final String? customerId;
  final String? customerName;
  final String saleMode;
  final String? dispatchId;
  final String? responsiblePersonId;
  final String paymentMode;
  final DateTime? saleDate;
  final DateTime? dueDate;
  final bool allowCreditOverride;
  final String? notes;
  final List<SaleItemCreate> items;

  SaleCreate({
    this.customerId,
    this.customerName,
    this.saleMode = 'DIRECT_STORE',
    this.dispatchId,
    this.responsiblePersonId,
    this.paymentMode = 'CASH_IMMEDIATE',
    this.saleDate,
    this.dueDate,
    this.allowCreditOverride = false,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'customer_name': customerName,
        'sale_mode': saleMode,
        'dispatch_id': dispatchId,
        'responsible_person_id': responsiblePersonId,
        'payment_mode': paymentMode,
        'sale_date': saleDate?.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'allow_credit_override': allowCreditOverride,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class SaleItem {
  final String id;
  final String basketTypeId;
  final String? basketTypeName;
  final String? productionBatchId;
  final int quantity;
  final int unitPriceCents;
  final int discountCents;
  final int totalCents;
  final int unitCostCents;
  final int totalCostCents;

  SaleItem({
    required this.id,
    required this.basketTypeId,
    this.basketTypeName,
    this.productionBatchId,
    required this.quantity,
    required this.unitPriceCents,
    required this.discountCents,
    required this.totalCents,
    required this.unitCostCents,
    required this.totalCostCents,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      basketTypeId: json['basket_type_id'] as String,
      basketTypeName: json['basket_type_name'] as String?,
      productionBatchId: json['production_batch_id'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPriceCents: (json['unit_price_cents'] as num).toInt(),
      discountCents: (json['discount_cents'] as num?)?.toInt() ?? 0,
      totalCents: (json['total_cents'] as num).toInt(),
      unitCostCents: (json['unit_cost_cents'] as num?)?.toInt() ?? 0,
      totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

class Sale {
  final String id;
  final int saleNumber;
  final String? customerId;
  final String? customerName;
  final String status;
  final String saleMode;
  final String? dispatchId;
  final String? responsiblePersonId;
  final String? responsiblePersonName;
  final String paymentMode;
  final String paymentStatus;
  final DateTime saleDate;
  final int totalAmountCents;
  final int totalCostCents;
  final int grossMarginCents;
  final DateTime? canceledAt;
  final String? cancellationReason;
  final String? notes;
  final List<SaleItem> items;
  final String? receivableId;
  final DateTime? receivableDueDate;
  final int? receivableBalanceCents;
  final String? receivableStatus;

  Sale({
    required this.id,
    required this.saleNumber,
    this.customerId,
    this.customerName,
    required this.status,
    required this.saleMode,
    this.dispatchId,
    this.responsiblePersonId,
    this.responsiblePersonName,
    required this.paymentMode,
    required this.paymentStatus,
    required this.saleDate,
    required this.totalAmountCents,
    required this.totalCostCents,
    required this.grossMarginCents,
    this.canceledAt,
    this.cancellationReason,
    this.notes,
    required this.items,
    this.receivableId,
    this.receivableDueDate,
    this.receivableBalanceCents,
    this.receivableStatus,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      saleNumber: (json['sale_number'] as num).toInt(),
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      status: json['status'] as String,
      saleMode: json['sale_mode'] as String? ?? 'DIRECT_STORE',
      dispatchId: json['dispatch_id'] as String?,
      responsiblePersonId: json['responsible_person_id'] as String?,
      responsiblePersonName: json['responsible_person_name'] as String?,
      paymentMode: json['payment_mode'] as String? ?? 'CASH_IMMEDIATE',
      paymentStatus: json['payment_status'] as String? ?? 'PAID',
      saleDate: DateTime.parse(json['sale_date'] as String),
      totalAmountCents: (json['total_amount_cents'] as num).toInt(),
      totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
      grossMarginCents: (json['gross_margin_cents'] as num?)?.toInt() ?? 0,
      canceledAt: json['canceled_at'] != null ? DateTime.parse(json['canceled_at'] as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      receivableId: json['receivable_id'] as String?,
      receivableDueDate: json['receivable_due_date'] != null
          ? DateTime.parse(json['receivable_due_date'] as String)
          : null,
      receivableBalanceCents: (json['receivable_balance_cents'] as num?)?.toInt(),
      receivableStatus: json['receivable_status'] as String?,
    );
  }
}
