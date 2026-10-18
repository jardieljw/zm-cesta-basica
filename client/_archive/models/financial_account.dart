class FinancialAccount {
  final String id;
  final String name;
  final String accountType; // CASH, BANK, OTHER
  final String? bankName;
  final String? accountNumber;
  final int initialBalanceCents;
  final int currentBalanceCents;
  final bool isActive;
  final bool isDefault;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialAccount({
    required this.id,
    required this.name,
    required this.accountType,
    this.bankName,
    this.accountNumber,
    required this.initialBalanceCents,
    required this.currentBalanceCents,
    required this.isActive,
    required this.isDefault,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialAccount.fromJson(Map<String, dynamic> json) {
    return FinancialAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['account_type'] as String? ?? 'CASH',
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      initialBalanceCents: (json['initial_balance_cents'] as num?)?.toInt() ?? 0,
      currentBalanceCents: (json['current_balance_cents'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'account_type': accountType,
        'bank_name': bankName,
        'account_number': accountNumber,
        'initial_balance_cents': initialBalanceCents,
        'current_balance_cents': currentBalanceCents,
        'is_active': isActive,
        'is_default': isDefault,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class FinancialAccountCreate {
  final String name;
  final String accountType;
  final String? bankName;
  final String? accountNumber;
  final int initialBalanceCents;
  final bool isDefault;
  final String? notes;

  FinancialAccountCreate({
    required this.name,
    this.accountType = 'CASH',
    this.bankName,
    this.accountNumber,
    this.initialBalanceCents = 0,
    this.isDefault = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'account_type': accountType,
        if (bankName != null && bankName!.trim().isNotEmpty) 'bank_name': bankName!.trim(),
        if (accountNumber != null && accountNumber!.trim().isNotEmpty) 'account_number': accountNumber!.trim(),
        'initial_balance_cents': initialBalanceCents,
        'is_default': isDefault,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class FinancialAccountUpdate {
  final String? name;
  final String? bankName;
  final String? accountNumber;
  final bool? isActive;
  final bool? isDefault;
  final String? notes;

  FinancialAccountUpdate({
    this.name,
    this.bankName,
    this.accountNumber,
    this.isActive,
    this.isDefault,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name!.trim();
    if (bankName != null) data['bank_name'] = bankName!.trim();
    if (accountNumber != null) data['account_number'] = accountNumber!.trim();
    if (isActive != null) data['is_active'] = isActive;
    if (isDefault != null) data['is_default'] = isDefault;
    if (notes != null) data['notes'] = notes!.trim();
    return data;
  }
}
