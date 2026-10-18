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
      paymentDate: _utc(json['payment_date'] as String),
      amountCents: (json['amount_cents'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'CONFIRMED',
      isRouteCollection: json['is_route_collection'] as bool? ?? false,
      repassStatus: json['repass_status'] as String? ?? 'DIRECT_COMPANY',
      reversalReason: json['reversal_reason'] as String?,
      reversalOfId: json['reversal_of_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: _utc(json['created_at'] as String),
    );
  }
  static DateTime _utc(String value) => DateTime.parse(
    RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value) ? value : '${value}Z',
  ).toUtc();

  Map<String, dynamic> toJson() => {
    'id': id,
    'receivable_id': receivableId,
    'dispatch_id': dispatchId,
    'account_id': accountId,
    'account_name': accountName,
    'payment_date': paymentDate.toUtc().toIso8601String(),
    'amount_cents': amountCents,
    'payment_method': paymentMethod,
    'status': status,
    'is_route_collection': isRouteCollection,
    'repass_status': repassStatus,
    'reversal_reason': reversalReason,
    'reversal_of_id': reversalOfId,
    'notes': notes,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class ReceivablePaymentCreate {
  final int amountCents;
  final String paymentMethod;
  final String? accountId;
  final String? dispatchId;
  final DateTime? paymentDate;
  final String? notes;
  final int? expectedBalanceCents;
  final String? paymentBusinessDate;

  ReceivablePaymentCreate({
    required this.amountCents,
    this.paymentMethod = 'CASH',
    this.accountId,
    this.dispatchId,
    this.paymentDate,
    this.notes,
    this.expectedBalanceCents,
    this.paymentBusinessDate,
  });

  Map<String, dynamic> toJson() => {
    'amount_cents': amountCents,
    'payment_method': paymentMethod,
    if (accountId != null) 'account_id': accountId,
    if (dispatchId != null) 'dispatch_id': dispatchId,
    if (paymentDate != null || paymentBusinessDate == null)
      'payment_date': paymentDate?.toIso8601String(),
    'notes': paymentBusinessDate == null ? notes : notes?.trim(),
    if (expectedBalanceCents != null)
      'expected_balance_cents': expectedBalanceCents,
    if (paymentBusinessDate != null)
      'payment_business_date': paymentBusinessDate,
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
  final int paymentReviewVersion;

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
    this.paymentReviewVersion = 0,
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      paymentsCount: (json['payments_count'] as num?)?.toInt() ?? 0,
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'] as String)
          : null,
      paymentReviewVersion:
          (json['payment_review_version'] as num?)?.toInt() ?? 0,
      payments: json['payments'] != null
          ? (json['payments'] as List<dynamic>)
                .map(
                  (e) => ReceivablePayment.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }
}
