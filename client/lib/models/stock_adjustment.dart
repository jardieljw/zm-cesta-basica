class StockAdjustmentRequest {
  final String itemType;
  final String? productId;
  final String? basketTypeId;
  final String adjustmentType; // 'IN', 'OUT', 'LOSS', 'COUNT'
  final int? quantityDelta;
  final int? physicalCount;
  final String reason;

  StockAdjustmentRequest({
    this.itemType = 'PRODUCT',
    this.productId,
    this.basketTypeId,
    required this.adjustmentType,
    this.quantityDelta,
    this.physicalCount,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'item_type': itemType,
      'adjustment_type': adjustmentType,
      'reason': reason,
    };
    if (productId != null) map['product_id'] = productId;
    if (basketTypeId != null) map['basket_type_id'] = basketTypeId;
    if (quantityDelta != null) map['quantity_delta'] = quantityDelta;
    if (physicalCount != null) map['physical_count'] = physicalCount;
    return map;
  }
}

class StockAdjustmentResponse {
  final String movementId;
  final String itemType;
  final String? productId;
  final String? productName;
  final String? basketTypeId;
  final String? basketTypeName;
  final String adjustmentType;
  final String movementType;
  final int previousStock;
  final int quantityDelta;
  final int newStock;
  final String reason;
  final DateTime occurredAt;

  StockAdjustmentResponse({
    required this.movementId,
    required this.itemType,
    this.productId,
    this.productName,
    this.basketTypeId,
    this.basketTypeName,
    required this.adjustmentType,
    required this.movementType,
    required this.previousStock,
    required this.quantityDelta,
    required this.newStock,
    required this.reason,
    required this.occurredAt,
  });

  factory StockAdjustmentResponse.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentResponse(
      movementId: json['movement_id'] as String,
      itemType: json['item_type'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      basketTypeId: json['basket_type_id'] as String?,
      basketTypeName: json['basket_type_name'] as String?,
      adjustmentType: json['adjustment_type'] as String,
      movementType: json['movement_type'] as String,
      previousStock: json['previous_stock'] as int,
      quantityDelta: json['quantity_delta'] as int,
      newStock: json['new_stock'] as int,
      reason: json['reason'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
    );
  }
}
