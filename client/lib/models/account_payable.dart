class PayablePayment {
  final String id;
  final String payableId;
  final String accountId;
  final String? accountName;
  final DateTime paymentDate;
  final int amountCents;
  final String paymentMethod;
  final String status; // CONFIRMED, REVERSED
  final String? reversalReason;
  final String? reversalOfId;
  final String? notes;
  final DateTime createdAt;

  PayablePayment({
    required this.id,
    required this.payableId,
    required this.accountId,
    this.accountName,
    required this.paymentDate,
    required this.amountCents,
    required this.paymentMethod,
    required this.status,
    this.reversalReason,
    this.reversalOfId,
    this.notes,
    required this.createdAt,
  });

  factory PayablePayment.fromJson(Map<String, dynamic> json) {
    return PayablePayment(
      id: json['id'] as String,
      payableId: json['payable_id'] as String,
      accountId: json['account_id'] as String,
      accountName: json['account_name'] as String?,
      paymentDate: _utc(json['payment_date'] as String),
      amountCents: (json['amount_cents'] as num).toInt(),
      paymentMethod: json['payment_method'] as String? ?? 'BOLETO',
      status: json['status'] as String? ?? 'CONFIRMED',
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
    'payable_id': payableId,
    'account_id': accountId,
    'account_name': accountName,
    'payment_date': paymentDate.toUtc().toIso8601String(),
    'amount_cents': amountCents,
    'payment_method': paymentMethod,
    'status': status,
    'reversal_reason': reversalReason,
    'reversal_of_id': reversalOfId,
    'notes': notes,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class AccountPayable {
  final String id;
  final int payableNumber;
  final String description;
  final String beneficiary;
  final String category;
  final String nature; // BUSINESS, PERSONAL_WITHDRAWAL
  final int originalAmountCents;
  final int paidAmountCents;
  final int balanceCents;
  final DateTime dueDate;
  final String paymentMethod;
  final String status; // OPEN, PARTIAL, PAID, CANCELED
  final bool isOverdue;
  final String? purchaseId;
  final int installmentNumber;
  final int totalInstallments;
  final String? installmentGroupId;
  final bool isRecurrent;
  final String? recurrencePeriod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int paymentsCount;
  final List<PayablePayment> payments;
  final int paymentReviewVersion;

  AccountPayable({
    required this.id,
    required this.payableNumber,
    required this.description,
    required this.beneficiary,
    required this.category,
    required this.nature,
    required this.originalAmountCents,
    required this.paidAmountCents,
    required this.balanceCents,
    required this.dueDate,
    required this.paymentMethod,
    required this.status,
    this.isOverdue = false,
    this.purchaseId,
    this.installmentNumber = 1,
    this.totalInstallments = 1,
    this.installmentGroupId,
    this.isRecurrent = false,
    this.recurrencePeriod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.paymentsCount = 0,
    this.payments = const [],
    this.paymentReviewVersion = 0,
  });

  factory AccountPayable.fromJson(Map<String, dynamic> json) {
    return AccountPayable(
      id: json['id'] as String,
      payableNumber: (json['payable_number'] as num?)?.toInt() ?? 0,
      description: json['description'] as String,
      beneficiary: json['beneficiary'] as String,
      category: json['category'] as String,
      nature: json['nature'] as String? ?? 'BUSINESS',
      originalAmountCents: (json['original_amount_cents'] as num).toInt(),
      paidAmountCents: (json['paid_amount_cents'] as num?)?.toInt() ?? 0,
      balanceCents: (json['balance_cents'] as num).toInt(),
      dueDate: DateTime.parse(json['due_date'] as String),
      paymentMethod: json['payment_method'] as String? ?? 'BOLETO',
      status: json['status'] as String? ?? 'OPEN',
      isOverdue: json['is_overdue'] as bool? ?? false,
      purchaseId: json['purchase_id'] as String?,
      installmentNumber: (json['installment_number'] as num?)?.toInt() ?? 1,
      totalInstallments: (json['total_installments'] as num?)?.toInt() ?? 1,
      installmentGroupId: json['installment_group_id'] as String?,
      isRecurrent: json['is_recurrent'] as bool? ?? false,
      recurrencePeriod: json['recurrence_period'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paymentsCount: (json['payments_count'] as num?)?.toInt() ?? 0,
      payments: json['payments'] != null
          ? (json['payments'] as List<dynamic>)
                .map((p) => PayablePayment.fromJson(p as Map<String, dynamic>))
                .toList()
          : const [],
      paymentReviewVersion:
          (json['payment_review_version'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountPayableCreate {
  final String description;
  final String beneficiary;
  final String category;
  final String nature;
  final int originalAmountCents;
  final DateTime dueDate;
  final String paymentMethod;
  final String? purchaseId;
  final int totalInstallments;
  final List<DateTime>? installmentDueDates;
  final bool isRecurrent;
  final String? recurrencePeriod;
  final String? notes;

  AccountPayableCreate({
    required this.description,
    required this.beneficiary,
    required this.category,
    this.nature = 'BUSINESS',
    required this.originalAmountCents,
    required this.dueDate,
    this.paymentMethod = 'BOLETO',
    this.purchaseId,
    this.totalInstallments = 1,
    this.installmentDueDates,
    this.isRecurrent = false,
    this.recurrencePeriod,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'beneficiary': beneficiary,
    'category': category,
    'nature': nature,
    'original_amount_cents': originalAmountCents,
    'due_date': dueDate.toIso8601String(),
    'payment_method': paymentMethod,
    if (purchaseId != null) 'purchase_id': purchaseId,
    'total_installments': totalInstallments,
    if (installmentDueDates != null)
      'installment_due_dates': installmentDueDates!
          .map((d) => d.toIso8601String())
          .toList(),
    'is_recurrent': isRecurrent,
    if (recurrencePeriod != null) 'recurrence_period': recurrencePeriod,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

class PayablePaymentCreate {
  final int amountCents;
  final String? accountId;
  final String paymentMethod;
  final DateTime? paymentDate;
  final String? notes;
  final int? expectedBalanceCents;
  final String? paymentBusinessDate;

  PayablePaymentCreate({
    required this.amountCents,
    this.accountId,
    this.paymentMethod = 'BOLETO',
    this.paymentDate,
    this.notes,
    this.expectedBalanceCents,
    this.paymentBusinessDate,
  });

  Map<String, dynamic> toJson() => {
    'amount_cents': amountCents,
    'account_id': accountId,
    'payment_method': paymentMethod,
    if (paymentDate != null) 'payment_date': paymentDate!.toIso8601String(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    if (expectedBalanceCents != null)
      'expected_balance_cents': expectedBalanceCents,
    if (paymentBusinessDate != null)
      'payment_business_date': paymentBusinessDate,
  };
}
