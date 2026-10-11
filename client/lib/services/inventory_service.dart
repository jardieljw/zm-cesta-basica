import '../core/api_client.dart';
import '../models/inventory_movement.dart';
import '../models/stock_summary.dart';
import '../models/stock_adjustment.dart';

class InventoryService {
  final ApiClient _client;

  InventoryService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<ProductStockSummary>> getSummary({
    String? category,
    bool? belowMinimumOnly,
    String? search,
  }) async {
    final queryParams = <String>[];
    if (category != null && category.isNotEmpty) {
      queryParams.add('category=${Uri.encodeComponent(category)}');
    }
    if (belowMinimumOnly == true) {
      queryParams.add('below_minimum_only=true');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _client.get('/api/v1/inventory/summary$query');

    if (response is List) {
      return response
          .map((json) => ProductStockSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getMovements({
    String? productId,
    String? movementType,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String>[
      'page=$page',
      'page_size=$pageSize',
    ];
    if (productId != null && productId.isNotEmpty) {
      queryParams.add('product_id=${Uri.encodeComponent(productId)}');
    }
    if (movementType != null && movementType.isNotEmpty) {
      queryParams.add('movement_type=${Uri.encodeComponent(movementType)}');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/inventory/movements$query');

    final rawItems = (response['items'] as List<dynamic>? ?? []);
    final items = rawItems
        .map((j) => InventoryMovement.fromJson(j as Map<String, dynamic>))
        .toList();

    return {
      'items': items,
      'total': response['total'] as int? ?? 0,
      'page': response['page'] as int? ?? 1,
      'page_size': response['page_size'] as int? ?? pageSize,
      'total_pages': response['total_pages'] as int? ?? 1,
    };
  }

  Future<List<InventoryMovement>> getProductMovements(
    String productId, {
    String? movementType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String>[];
    if (movementType != null && movementType.isNotEmpty) {
      queryParams.add('movement_type=${Uri.encodeComponent(movementType)}');
    }
    if (startDate != null) {
      queryParams.add('start_date=${Uri.encodeComponent(startDate.toIso8601String())}');
    }
    if (endDate != null) {
      queryParams.add('end_date=${Uri.encodeComponent(endDate.toIso8601String())}');
    }
    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _client.get('/api/v1/inventory/products/$productId/movements$query');
    if (response is List) {
      return response
          .map((json) => InventoryMovement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getBasketStock(String basketTypeId) async {
    final response = await _client.get('/api/v1/inventory/baskets/$basketTypeId/stock');
    return response as Map<String, dynamic>;
  }

  Future<StockAdjustmentResponse> createAdjustment(StockAdjustmentRequest request) async {
    final response = await _client.post(
      '/api/v1/inventory/adjustments',
      body: request.toJson(),
    );
    return StockAdjustmentResponse.fromJson(response as Map<String, dynamic>);
  }
}
