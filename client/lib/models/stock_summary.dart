class ProductStockSummary {
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String category;
  final String baseUnit;
  final int currentStock;
  final int minimumStock;
  final bool isBelowMinimum;
  final int costPriceCents;
  final int salePriceCents;

  ProductStockSummary({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    required this.category,
    required this.baseUnit,
    required this.currentStock,
    required this.minimumStock,
    required this.isBelowMinimum,
    required this.costPriceCents,
    required this.salePriceCents,
  });

  double get costPriceReais => costPriceCents / 100.0;
  double get salePriceReais => salePriceCents / 100.0;

  factory ProductStockSummary.fromJson(Map<String, dynamic> json) {
    return ProductStockSummary(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String,
      baseUnit: json['base_unit'] as String,
      currentStock: json['current_stock'] as int? ?? 0,
      minimumStock: json['minimum_stock'] as int? ?? 0,
      isBelowMinimum: json['is_below_minimum'] as bool? ?? false,
      costPriceCents: json['cost_price_cents'] as int? ?? 0,
      salePriceCents: json['sale_price_cents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'base_unit': baseUnit,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'is_below_minimum': isBelowMinimum,
      'cost_price_cents': costPriceCents,
      'sale_price_cents': salePriceCents,
    };
  }
}
