class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String productBaseUnit;
  final String? packagingId;
  final String? packagingName;
  final double packagesCount;
  final int quantityInBaseUnits;
  final int unitPriceCents;
  final int totalPriceCents;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.productBaseUnit,
    this.packagingId,
    this.packagingName,
    required this.packagesCount,
    required this.quantityInBaseUnits,
    required this.unitPriceCents,
    required this.totalPriceCents,
  });

  double get unitPriceReais => unitPriceCents / 100.0;
  double get totalPriceReais => totalPriceCents / 100.0;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      productBaseUnit: json['product_base_unit'] as String? ?? '',
      packagingId: json['packaging_id'] as String?,
      packagingName: json['packaging_name'] as String?,
      packagesCount: (json['packages_count'] as num).toDouble(),
      quantityInBaseUnits: json['quantity_in_base_units'] as int,
      unitPriceCents: json['unit_price_cents'] as int,
      totalPriceCents: json['total_price_cents'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'product_base_unit': productBaseUnit,
      'packaging_id': packagingId,
      'packaging_name': packagingName,
      'packages_count': packagesCount,
      'quantity_in_base_units': quantityInBaseUnits,
      'unit_price_cents': unitPriceCents,
      'total_price_cents': totalPriceCents,
    };
  }
}

class Purchase {
  final String id;
  final int purchaseNumber;
  final String status;
  final DateTime purchaseDate;
  final String? supplierName;
  final int totalAmountCents;
  final String? notes;
  final DateTime createdAt;
  final List<PurchaseItem> items;

  Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.status,
    required this.purchaseDate,
    this.supplierName,
    required this.totalAmountCents,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  double get totalAmountReais => totalAmountCents / 100.0;

  factory Purchase.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<PurchaseItem> itemsList = rawItems
        .map((it) => PurchaseItem.fromJson(it as Map<String, dynamic>))
        .toList();

    return Purchase(
      id: json['id'] as String,
      purchaseNumber: json['purchase_number'] as int,
      status: json['status'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      supplierName: json['supplier_name'] as String?,
      totalAmountCents: json['total_amount_cents'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_number': purchaseNumber,
      'status': status,
      'purchase_date': purchaseDate.toIso8601String(),
      'supplier_name': supplierName,
      'total_amount_cents': totalAmountCents,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
