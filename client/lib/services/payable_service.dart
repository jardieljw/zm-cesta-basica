import '../core/api_client.dart';
import '../models/account_payable.dart';

class PayableService {
  final ApiClient _client;

  PayableService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<AccountPayable>> getPayables({
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? month,
    int? year,
    String? category,
    String? beneficiary,
    String? status,
    String? nature,
    bool overdueOnly = false,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String>[
      'limit=$limit',
      'offset=$offset',
    ];
    if (dueDateFrom != null) {
      params.add('due_date_from=${Uri.encodeComponent(dueDateFrom.toIso8601String())}');
    }
    if (dueDateTo != null) {
      params.add('due_date_to=${Uri.encodeComponent(dueDateTo.toIso8601String())}');
    }
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (beneficiary != null && beneficiary.isNotEmpty) {
      params.add('beneficiary=${Uri.encodeComponent(beneficiary)}');
    }
    if (status != null && status.isNotEmpty) {
      params.add('status=${Uri.encodeComponent(status)}');
    }
    if (nature != null && nature.isNotEmpty) {
      params.add('nature=${Uri.encodeComponent(nature)}');
    }
    if (overdueOnly) {
      params.add('overdue_only=true');
    }

    final query = '?${params.join('&')}';
    final response = await _client.get('/api/v1/payables$query');
    final list = response as List<dynamic>? ?? [];
    return list.map((j) => AccountPayable.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<AccountPayable> getPayable(String id) async {
    final response = await _client.get('/api/v1/payables/$id');
    return AccountPayable.fromJson(response as Map<String, dynamic>);
  }

  Future<List<AccountPayable>> createPayable(
    AccountPayableCreate data, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/payables',
      body: data.toJson(),
      idempotencyKey: idempotencyKey,
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((j) => AccountPayable.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<PayablePayment> recordPayment(
    String payableId,
    PayablePaymentCreate data, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/payables/$payableId/payments',
      body: data.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return PayablePayment.fromJson(response as Map<String, dynamic>);
  }

  Future<PayablePayment> cancelPayment(
    String paymentId,
    String reason, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/payables/payments/$paymentId/cancel',
      body: {'reason': reason},
      idempotencyKey: idempotencyKey,
    );
    return PayablePayment.fromJson(response as Map<String, dynamic>);
  }

  Future<AccountPayable> cancelPayable(
    String payableId,
    String reason, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/payables/$payableId/cancel',
      body: {'reason': reason},
      idempotencyKey: idempotencyKey,
    );
    return AccountPayable.fromJson(response as Map<String, dynamic>);
  }

  Future<AccountPayable> generateNextRecurrence(
    String payableId, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/payables/$payableId/next-recurrence',
      body: {},
      idempotencyKey: idempotencyKey,
    );
    return AccountPayable.fromJson(response as Map<String, dynamic>);
  }
}
