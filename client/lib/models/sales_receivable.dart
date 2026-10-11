class ReceivablePayment {
  final String id;
  final String receivableId;
  final DateTime paymentDate;
  final int amountCents;
  final String paymentMethod;
  final String status;
  final String? reversalReason;
  final String? reversalOfId;
  final String? notes;
  final DateTime createdAt;

  ReceivablePayment({
    required this.id,
    required this.receivableId,
    required this.paymentDate,
    required this.amountCents,
    required this.paymentMethod,
    required this.status,
    this.reversalReason,
    this.reversalOfId,
    this.notes,
    required this.createdAt,
  });

  factory ReceivablePayment.fromJson(Map<String, dynamic> json) {
    return ReceivablePayment(
      id: json['id'] as String,
      receivableId: json['receivable_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amountCents: (json['amount_cents'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'CONFIRMED',
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
  final DateTime? paymentDate;
  final String? notes;

  ReceivablePaymentCreate({
    required this.amountCents,
    this.paymentMethod = 'CASH',
    this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount_cents': amountCents,
        'payment_method': paymentMethod,
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
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
