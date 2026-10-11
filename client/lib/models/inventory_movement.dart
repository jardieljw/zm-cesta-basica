class InventoryMovement {
  final String id;
  final String itemType;
  final String? productId;
  final String? productName;
  final String? basketTypeId;
  final String? basketTypeName;
  final String? productionBatchId;
  final String movementType;
  final int quantityDelta;
  final String sourceType;
  final String sourceId;
  final String? reversalOfId;
  final DateTime occurredAt;
  final String? reason;
  final int? runningBalance;

  InventoryMovement({
    required this.id,
    required this.itemType,
    this.productId,
    this.productName,
    this.basketTypeId,
    this.basketTypeName,
    this.productionBatchId,
    required this.movementType,
    required this.quantityDelta,
    required this.sourceType,
    required this.sourceId,
    this.reversalOfId,
    required this.occurredAt,
    this.reason,
    this.runningBalance,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as String,
      itemType: json['item_type'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      basketTypeId: json['basket_type_id'] as String?,
      basketTypeName: json['basket_type_name'] as String?,
      productionBatchId: json['production_batch_id'] as String?,
      movementType: json['movement_type'] as String,
      quantityDelta: json['quantity_delta'] as int,
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String,
      reversalOfId: json['reversal_of_id'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      reason: json['reason'] as String?,
      runningBalance: json['running_balance'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'product_id': productId,
      'product_name': productName,
      'basket_type_id': basketTypeId,
      'basket_type_name': basketTypeName,
      'production_batch_id': productionBatchId,
      'movement_type': movementType,
      'quantity_delta': quantityDelta,
      'source_type': sourceType,
      'source_id': sourceId,
      'reversal_of_id': reversalOfId,
      'occurred_at': occurredAt.toIso8601String(),
      'reason': reason,
      'running_balance': runningBalance,
    };
  }
}
