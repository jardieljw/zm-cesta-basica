import '../core/api_client.dart';
import '../models/sales_receivable.dart';

class ReceivableService {
  final ApiClient _client;

  ReceivableService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<SalesReceivable>> getReceivables({
    String? customerId,
    String? status,
    bool overdueOnly = false,
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
    if (overdueOnly) {
      queryParams.add('overdue_only=true');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/receivables$query');

    final rawList = response as List<dynamic>? ?? [];
    return rawList
        .map((j) => SalesReceivable.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<SalesReceivable> getReceivable(String id) async {
    final response = await _client.get('/api/v1/receivables/$id');
    return SalesReceivable.fromJson(response as Map<String, dynamic>);
  }

  Future<ReceivablePayment> recordPayment(
    String receivableId,
    ReceivablePaymentCreate data, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/receivables/$receivableId/payments',
      body: data.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return ReceivablePayment.fromJson(response as Map<String, dynamic>);
  }

  Future<ReceivablePayment> cancelPayment(
    String paymentId,
    String reason, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/receivables/payments/$paymentId/cancel',
      body: {'reason': reason},
      idempotencyKey: idempotencyKey,
    );
    return ReceivablePayment.fromJson(response as Map<String, dynamic>);
  }
}
