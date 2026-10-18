import '../../lib/core/api_client.dart';
import '../models/dispatch.dart';

class DispatchService {
  final ApiClient _client;

  DispatchService({ApiClient? client}) : _client = client ?? ApiClient();

  // ==================== RESPONSIBLE PERSONS ====================

  Future<List<ResponsiblePerson>> getResponsiblePersons({
    bool? isActive,
    String? search,
  }) async {
    final queryParams = <String>[];
    if (isActive != null) {
      queryParams.add('is_active=$isActive');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _client.get('/api/v1/dispatches/responsible-persons$query');

    final rawList = response as List<dynamic>? ?? [];
    return rawList
        .map((j) => ResponsiblePerson.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ResponsiblePerson> getResponsiblePerson(String id) async {
    final response = await _client.get('/api/v1/dispatches/responsible-persons/$id');
    return ResponsiblePerson.fromJson(response as Map<String, dynamic>);
  }

  Future<ResponsiblePerson> createResponsiblePerson({
    required String name,
    String? phone,
    bool isActive = true,
    String? notes,
  }) async {
    final response = await _client.post(
      '/api/v1/dispatches/responsible-persons',
      body: {
        'name': name,
        'phone': phone,
        'is_active': isActive,
        'notes': notes,
      },
    );
    return ResponsiblePerson.fromJson(response as Map<String, dynamic>);
  }

  Future<ResponsiblePerson> updateResponsiblePerson(
    String id, {
    String? name,
    String? phone,
    bool? isActive,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (isActive != null) body['is_active'] = isActive;
    if (notes != null) body['notes'] = notes;

    final response = await _client.put(
      '/api/v1/dispatches/responsible-persons/$id',
      body: body,
    );
    return ResponsiblePerson.fromJson(response as Map<String, dynamic>);
  }

  Future<ResponsiblePersonCustody> getResponsiblePersonCustody(String personId) async {
    final response = await _client.get('/api/v1/dispatches/responsible-persons/$personId/custody');
    return ResponsiblePersonCustody.fromJson(response as Map<String, dynamic>);
  }

  // ==================== STOCK DISPATCHES ====================

  Future<List<StockDispatch>> getDispatches({
    String? responsiblePersonId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String>[
      'limit=$limit',
      'offset=$offset',
    ];
    if (responsiblePersonId != null && responsiblePersonId.isNotEmpty) {
      queryParams.add('responsible_person_id=${Uri.encodeComponent(responsiblePersonId)}');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (startDate != null) {
      queryParams.add('start_date=${startDate.toIso8601String()}');
    }
    if (endDate != null) {
      queryParams.add('end_date=${endDate.toIso8601String()}');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/dispatches$query');

    final rawList = response as List<dynamic>? ?? [];
    return rawList
        .map((j) => StockDispatch.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<StockDispatchDetail> getDispatch(String id) async {
    final response = await _client.get('/api/v1/dispatches/$id');
    return StockDispatchDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<StockDispatchDetail> createDispatch(
    StockDispatchCreate data, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/api/v1/dispatches',
      body: data.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return StockDispatchDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<StockDispatch> cancelDispatch(String id, String reason) async {
    final response = await _client.post(
      '/api/v1/dispatches/$id/cancel',
      body: {'reason': reason},
    );
    return StockDispatch.fromJson(response as Map<String, dynamic>);
  }

  // ==================== RETURNS & LOSSES ====================

  Future<DispatchReturn> recordReturn(String dispatchId, DispatchReturnCreate data) async {
    final response = await _client.post(
      '/api/v1/dispatches/$dispatchId/returns',
      body: data.toJson(),
    );
    return DispatchReturn.fromJson(response as Map<String, dynamic>);
  }

  Future<DispatchLoss> recordLoss(String dispatchId, DispatchLossCreate data) async {
    final response = await _client.post(
      '/api/v1/dispatches/$dispatchId/losses',
      body: data.toJson(),
    );
    return DispatchLoss.fromJson(response as Map<String, dynamic>);
  }

  // ==================== EXPENSES & REPAYMENTS ====================

  Future<DispatchExpense> recordExpense(String dispatchId, DispatchExpenseCreate data) async {
    final response = await _client.post(
      '/api/v1/dispatches/$dispatchId/expenses',
      body: data.toJson(),
    );
    return DispatchExpense.fromJson(response as Map<String, dynamic>);
  }

  Future<DispatchRepayment> recordRepayment(String dispatchId, DispatchRepaymentCreate data) async {
    final response = await _client.post(
      '/api/v1/dispatches/$dispatchId/repayments',
      body: data.toJson(),
    );
    return DispatchRepayment.fromJson(response as Map<String, dynamic>);
  }

  // ==================== RECONCILIATION & SETTLEMENT ====================

  Future<DispatchReconciliation> getReconciliation(String dispatchId) async {
    final response = await _client.get('/api/v1/dispatches/$dispatchId/reconciliation');
    return DispatchReconciliation.fromJson(response as Map<String, dynamic>);
  }

  Future<DispatchSettlement> settleDispatch(String dispatchId, DispatchSettlementCreate data) async {
    final response = await _client.post(
      '/api/v1/dispatches/$dispatchId/settlement',
      body: data.toJson(),
    );
    return DispatchSettlement.fromJson(response as Map<String, dynamic>);
  }

  Future<DispatchSettlement> updateInvestigation(
    String dispatchId,
    DispatchSettlementInvestigationUpdate data,
  ) async {
    final response = await _client.put(
      '/api/v1/dispatches/$dispatchId/settlement/investigation',
      body: data.toJson(),
    );
    return DispatchSettlement.fromJson(response as Map<String, dynamic>);
  }
}
