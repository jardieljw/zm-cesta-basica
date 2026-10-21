class ProductPackaging {
  final String id;
  final String productId;
  final String name;
  final int quantityInBaseUnits;
  final bool isDefault;
  final bool isActive;

  ProductPackaging({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantityInBaseUnits,
    required this.isDefault,
    required this.isActive,
  });

  factory ProductPackaging.fromJson(Map<String, dynamic> json) {
    return ProductPackaging(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      quantityInBaseUnits: json['quantity_in_base_units'] as int,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity_in_base_units': quantityInBaseUnits,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String category;
  final String baseUnit;
  final int minimumStock;
  final int costPriceCents;
  final int salePriceCents;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductPackaging> packagings;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.category,
    required this.baseUnit,
    required this.minimumStock,
    required this.costPriceCents,
    required this.salePriceCents,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.packagings = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var rawPackagings = json['packagings'] as List<dynamic>? ?? [];
    List<ProductPackaging> packagingsList = rawPackagings
        .map((p) => ProductPackaging.fromJson(p as Map<String, dynamic>))
        .toList();

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String,
      baseUnit: json['base_unit'] as String,
      minimumStock: json['minimum_stock'] as int? ?? 0,
      costPriceCents: json['cost_price_cents'] as int? ?? 0,
      salePriceCents: json['sale_price_cents'] as int? ?? 0,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      packagings: packagingsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'base_unit': baseUnit,
      'minimum_stock': minimumStock,
      'cost_price_cents': costPriceCents,
      'sale_price_cents': salePriceCents,
      'notes': notes,
      'is_active': isActive,
    };
  }

  double get costPriceReais => costPriceCents / 100.0;
  double get salePriceReais => salePriceCents / 100.0;
}

class ProductDeletionCheck {
  final bool canDelete;
  final List<String> reasons;
  final List<Map<String, dynamic>> blockers;
  ProductDeletionCheck({
    required this.canDelete,
    required this.reasons,
    this.blockers = const [],
  });
  factory ProductDeletionCheck.fromJson(Map<String, dynamic> json) =>
      ProductDeletionCheck(
        canDelete: json['can_delete'] as bool,
        blockers: (json['blockers'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        reasons: (json['reasons'] as List<dynamic>)
            .map((r) => r as String)
            .toList(),
      );
}
