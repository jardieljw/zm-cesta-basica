class Customer {
  final String id;
  final String name;
  final String? documentCpfCnpj;
  final String? phone;
  final String? address;
  final int creditLimitCents;
  final bool isActive;
  final String? notes;
  final int currentDebtCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.documentCpfCnpj,
    this.phone,
    this.address,
    required this.creditLimitCents,
    required this.isActive,
    this.notes,
    required this.currentDebtCents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      documentCpfCnpj: json['document_cpf_cnpj'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      creditLimitCents: (json['credit_limit_cents'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      currentDebtCents: (json['current_debt_cents'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'document_cpf_cnpj': documentCpfCnpj,
      'phone': phone,
      'address': address,
      'credit_limit_cents': creditLimitCents,
      'is_active': isActive,
      'notes': notes,
      'current_debt_cents': currentDebtCents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int? get availableCreditCents =>
      creditLimitCents > 0 ? (creditLimitCents - currentDebtCents > 0 ? creditLimitCents - currentDebtCents : 0) : null;
}

class CustomerStatementEntry {
  final String id;
  final DateTime occurredAt;
  final String entryType;
  final String description;
  final int amountCents;
  final String referenceId;

  CustomerStatementEntry({
    required this.id,
    required this.occurredAt,
    required this.entryType,
    required this.description,
    required this.amountCents,
    required this.referenceId,
  });

  factory CustomerStatementEntry.fromJson(Map<String, dynamic> json) {
    return CustomerStatementEntry(
      id: json['id'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      entryType: json['entry_type'] as String,
      description: json['description'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      referenceId: json['reference_id'] as String,
    );
  }
}

class CustomerStatementResponse {
  final Customer customer;
  final int creditLimitCents;
  final int currentDebtCents;
  final int? availableCreditCents;
  final List<CustomerStatementEntry> entries;

  CustomerStatementResponse({
    required this.customer,
    required this.creditLimitCents,
    required this.currentDebtCents,
    this.availableCreditCents,
    required this.entries,
  });

  factory CustomerStatementResponse.fromJson(Map<String, dynamic> json) {
    return CustomerStatementResponse(
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      creditLimitCents: (json['credit_limit_cents'] as num).toInt(),
      currentDebtCents: (json['current_debt_cents'] as num).toInt(),
      availableCreditCents: (json['available_credit_cents'] as num?)?.toInt(),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => CustomerStatementEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
