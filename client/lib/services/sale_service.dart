import '../core/api_client.dart';
import '../models/sale.dart';

class SaleService {
  final ApiClient _client;

  SaleService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Sale>> getSales({
    String? customerId,
    String? status,
    String? paymentMode,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String>[
      'limit=$limit',
      'offset=$offset',
    ];
    if (customerId != null && customerId.isNotEmpty) {
      queryParams.add('customer_id=${Uri.encodeComponent(customerId)}');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (paymentMode != null && paymentMode.isNotEmpty) {
      queryParams.add('payment_mode=${Uri.encodeComponent(paymentMode)}');
    }
    if (startDate != null) {
      queryParams.add('start_date=${Uri.encodeComponent(startDate.toIso8601String())}');
    }
    if (endDate != null) {
      queryParams.add('end_date=${Uri.encodeComponent(endDate.toIso8601String())}');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/sales$query');

    final rawList = response as List<dynamic>? ?? [];
    return rawList
        .map((j) => Sale.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Sale> getSale(String id) async {
    final response = await _client.get('/api/v1/sales/$id');
    return Sale.fromJson(response as Map<String, dynamic>);
  }

  Future<Sale> createSale(SaleCreate data, {String? idempotencyKey}) async {
    final response = await _client.post(
      '/api/v1/sales',
      body: data.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return Sale.fromJson(response as Map<String, dynamic>);
  }

  Future<Sale> cancelSale(String id, String reason, {String? idempotencyKey}) async {
    final response = await _client.post(
      '/api/v1/sales/$id/cancel',
      body: {'reason': reason},
      idempotencyKey: idempotencyKey,
    );
    return Sale.fromJson(response as Map<String, dynamic>);
  }
}
