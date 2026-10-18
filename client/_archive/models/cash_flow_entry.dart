import 'financial_account.dart';

class CashFlowEntry {
  final String id;
  final String accountId;
  final String? accountName;
  final String entryType; // CREDIT, DEBIT
  final int amountCents;
  final String category;
  final String nature; // BUSINESS, PERSONAL_WITHDRAWAL
  final String description;
  final String sourceType;
  final String? sourceId;
  final String paymentMethod;
  final DateTime occurredAt;
  final String? reversalOfId;
  final bool isReversal;
  final String? notes;
  final DateTime createdAt;

  CashFlowEntry({
    required this.id,
    required this.accountId,
    this.accountName,
    required this.entryType,
    required this.amountCents,
    required this.category,
    required this.nature,
    required this.description,
    required this.sourceType,
    this.sourceId,
    required this.paymentMethod,
    required this.occurredAt,
    this.reversalOfId,
    this.isReversal = false,
    this.notes,
    required this.createdAt,
  });

  factory CashFlowEntry.fromJson(Map<String, dynamic> json) {
    return CashFlowEntry(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      accountName: json['account_name'] as String?,
      entryType: json['entry_type'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      category: json['category'] as String,
      nature: json['nature'] as String? ?? 'BUSINESS',
      description: json['description'] as String,
      sourceType: json['source_type'] as String? ?? 'MANUAL',
      sourceId: json['source_id'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      reversalOfId: json['reversal_of_id'] as String?,
      isReversal: json['is_reversal'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CashFlowEntryCreate {
  final String accountId;
  final String entryType; // CREDIT, DEBIT
  final int amountCents;
  final String category;
  final String nature; // BUSINESS, PERSONAL_WITHDRAWAL
  final String description;
  final String sourceType;
  final String? sourceId;
  final String paymentMethod;
  final DateTime? occurredAt;
  final String? notes;

  CashFlowEntryCreate({
    required this.accountId,
    required this.entryType,
    required this.amountCents,
    required this.category,
    this.nature = 'BUSINESS',
    required this.description,
    this.sourceType = 'MANUAL',
    this.sourceId,
    this.paymentMethod = 'CASH',
    this.occurredAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'entry_type': entryType,
        'amount_cents': amountCents,
        'category': category,
        'nature': nature,
        'description': description,
        'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
        'payment_method': paymentMethod,
        if (occurredAt != null) 'occurred_at': occurredAt!.toIso8601String(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class FinancialTransfer {
  final String transferId;
  final String sourceAccountId;
  final String sourceAccountName;
  final String destinationAccountId;
  final String destinationAccountName;
  final int amountCents;
  final DateTime transferDate;
  final String sourceEntryId;
  final String destinationEntryId;
  final String description;
  final String? notes;

  FinancialTransfer({
    required this.transferId,
    required this.sourceAccountId,
    required this.sourceAccountName,
    required this.destinationAccountId,
    required this.destinationAccountName,
    required this.amountCents,
    required this.transferDate,
    required this.sourceEntryId,
    required this.destinationEntryId,
    required this.description,
    this.notes,
  });

  factory FinancialTransfer.fromJson(Map<String, dynamic> json) {
    return FinancialTransfer(
      transferId: json['transfer_id'] as String,
      sourceAccountId: json['source_account_id'] as String,
      sourceAccountName: json['source_account_name'] as String? ?? '',
      destinationAccountId: json['destination_account_id'] as String,
      destinationAccountName: json['destination_account_name'] as String? ?? '',
      amountCents: (json['amount_cents'] as num).toInt(),
      transferDate: DateTime.parse(json['transfer_date'] as String),
      sourceEntryId: json['source_entry_id'] as String? ?? '',
      destinationEntryId: json['destination_entry_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class FinancialTransferCreate {
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountCents;
  final DateTime? transferDate;
  final String? description;
  final String? notes;

  FinancialTransferCreate({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountCents,
    this.transferDate,
    this.description,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'source_account_id': sourceAccountId,
        'destination_account_id': destinationAccountId,
        'amount_cents': amountCents,
        if (transferDate != null) 'transfer_date': transferDate!.toIso8601String(),
        if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class TreasurySummary {
  final int totalAvailableCents;
  final int cashBalanceCents;
  final int bankBalanceCents;
  final int openReceivablesCents;
  final int overdueReceivablesCents;
  final int openPayablesCents;
  final int overduePayablesCents;
  final int routeCashPendingCents;
  final int projectedNetCents;
  final int periodBusinessExpensesCents;
  final int periodPersonalWithdrawalsCents;
  final List<FinancialAccount> accounts;

  TreasurySummary({
    required this.totalAvailableCents,
    required this.cashBalanceCents,
    required this.bankBalanceCents,
    required this.openReceivablesCents,
    required this.overdueReceivablesCents,
    required this.openPayablesCents,
    required this.overduePayablesCents,
    required this.routeCashPendingCents,
    required this.projectedNetCents,
    this.periodBusinessExpensesCents = 0,
    this.periodPersonalWithdrawalsCents = 0,
    this.accounts = const [],
  });

  factory TreasurySummary.fromJson(Map<String, dynamic> json) {
    return TreasurySummary(
      totalAvailableCents: (json['total_available_cents'] as num?)?.toInt() ?? 0,
      cashBalanceCents: (json['cash_balance_cents'] as num?)?.toInt() ?? 0,
      bankBalanceCents: (json['bank_balance_cents'] as num?)?.toInt() ?? 0,
      openReceivablesCents: (json['open_receivables_cents'] as num?)?.toInt() ?? 0,
      overdueReceivablesCents: (json['overdue_receivables_cents'] as num?)?.toInt() ?? 0,
      openPayablesCents: (json['open_payables_cents'] as num?)?.toInt() ?? 0,
      overduePayablesCents: (json['overdue_payables_cents'] as num?)?.toInt() ?? 0,
      routeCashPendingCents: (json['route_cash_pending_cents'] as num?)?.toInt() ?? 0,
      projectedNetCents: (json['projected_net_cents'] as num?)?.toInt() ?? 0,
      periodBusinessExpensesCents: (json['period_business_expenses_cents'] as num?)?.toInt() ?? 0,
      periodPersonalWithdrawalsCents: (json['period_personal_withdrawals_cents'] as num?)?.toInt() ?? 0,
      accounts: json['accounts'] != null
          ? (json['accounts'] as List<dynamic>)
              .map((a) => FinancialAccount.fromJson(a as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
