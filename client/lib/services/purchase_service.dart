import '../core/api_client.dart';
import '../models/purchase.dart';

class PurchaseService {
  final ApiClient _client;

  PurchaseService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Purchase>> getPurchases({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String>[
      'page=$page',
      'page_size=$pageSize',
    ];
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/purchases$query');

    final rawItems = (response['items'] as List<dynamic>? ?? []);
    return rawItems
        .map((j) => Purchase.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> getPurchase(String id) async {
    final response = await _client.get('/api/v1/purchases/$id');
    return Purchase.fromJson(response as Map<String, dynamic>);
  }

  Future<Purchase> createPurchase(Map<String, dynamic> data) async {
    final response = await _client.post('/api/v1/purchases', body: data);
    return Purchase.fromJson(response as Map<String, dynamic>);
  }

  Future<Purchase> updateDraftPurchase(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put('/api/v1/purchases/$id', body: data);
    return Purchase.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteDraftPurchase(String id) async {
    await _client.delete('/api/v1/purchases/$id');
  }

  Future<Purchase> confirmPurchase(String id) async {
    final response = await _client.post('/api/v1/purchases/$id/confirm');
    return Purchase.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> cancelPurchase(String id, {String? reason}) async {
    final body = reason != null ? {'reason': reason} : null;
    final response = await _client.post('/api/v1/purchases/$id/cancel', body: body);
    return response as Map<String, dynamic>;
  }
}
