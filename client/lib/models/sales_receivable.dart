class ReceivablePayment {
  final String id;
  final String receivableId;
  final String? dispatchId;
  final String? accountId;
  final String? accountName;
  final DateTime paymentDate;
  final int amountCents;
  final String paymentMethod;
  final String status;
  final bool isRouteCollection;
  final String repassStatus; // DIRECT_COMPANY, PENDING_REPASS, REPASSED
  final String? reversalReason;
  final String? reversalOfId;
  final String? notes;
  final DateTime createdAt;

  ReceivablePayment({
    required this.id,
    required this.receivableId,
    this.dispatchId,
    this.accountId,
    this.accountName,
    required this.paymentDate,
    required this.amountCents,
    required this.paymentMethod,
    required this.status,
    this.isRouteCollection = false,
    this.repassStatus = 'DIRECT_COMPANY',
    this.reversalReason,
    this.reversalOfId,
    this.notes,
    required this.createdAt,
  });

  factory ReceivablePayment.fromJson(Map<String, dynamic> json) {
    return ReceivablePayment(
      id: json['id'] as String,
      receivableId: json['receivable_id'] as String,
      dispatchId: json['dispatch_id'] as String?,
      accountId: json['account_id'] as String?,
      accountName: json['account_name'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amountCents: (json['amount_cents'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'CONFIRMED',
      isRouteCollection: json['is_route_collection'] as bool? ?? false,
      repassStatus: json['repass_status'] as String? ?? 'DIRECT_COMPANY',
      reversalReason: json['reversal_reason'] as String?,
      reversalOfId: json['reversal_of_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReceivablePaymentCreate {
  final int amountCents;
  final String paymentMethod;
  final String? accountId;
  final String? dispatchId;
  final DateTime? paymentDate;
  final String? notes;

  ReceivablePaymentCreate({
    required this.amountCents,
    this.paymentMethod = 'CASH',
    this.accountId,
    this.dispatchId,
    this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount_cents': amountCents,
        'payment_method': paymentMethod,
        if (accountId != null) 'account_id': accountId,
        if (dispatchId != null) 'dispatch_id': dispatchId,
        'payment_date': paymentDate?.toIso8601String(),
        'notes': notes,
      };
}

class SalesReceivable {
  final String id;
  final String saleId;
  final int saleNumber;
  final String customerId;
  final String customerName;
  final DateTime dueDate;
  final int originalAmountCents;
  final int paidAmountCents;
  final int balanceCents;
  final String status;
  final bool isOverdue;
  final String? basketTypesSummary;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int paymentsCount;
  final DateTime? saleDate;
  final List<ReceivablePayment> payments;

  SalesReceivable({
    required this.id,
    required this.saleId,
    required this.saleNumber,
    required this.customerId,
    required this.customerName,
    required this.dueDate,
    required this.originalAmountCents,
    required this.paidAmountCents,
    required this.balanceCents,
    required this.status,
    this.isOverdue = false,
    this.basketTypesSummary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.paymentsCount = 0,
    this.saleDate,
    this.payments = const [],
  });

  factory SalesReceivable.fromJson(Map<String, dynamic> json) {
    return SalesReceivable(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      saleNumber: (json['sale_number'] as num?)?.toInt() ?? 0,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date'] as String),
      originalAmountCents: (json['original_amount_cents'] as num).toInt(),
      paidAmountCents: (json['paid_amount_cents'] as num?)?.toInt() ?? 0,
      balanceCents: (json['balance_cents'] as num).toInt(),
      status: json['status'] as String? ?? 'OPEN',
      isOverdue: json['is_overdue'] as bool? ?? false,
      basketTypesSummary: json['basket_types_summary'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      paymentsCount: (json['payments_count'] as num?)?.toInt() ?? 0,
      saleDate: json['sale_date'] != null ? DateTime.parse(json['sale_date'] as String) : null,
      payments: json['payments'] != null
          ? (json['payments'] as List<dynamic>)
              .map((e) => ReceivablePayment.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
