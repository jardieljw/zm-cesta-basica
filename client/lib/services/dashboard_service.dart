import '../core/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<DashboardSummary> getDashboardSummary({
    String filterType = 'today',
    String? date,
    String? startDate,
    String? endDate,
    int? month,
    int? year,
  }) async {
    final params = <String>['filter_type=$filterType'];
    if (date != null && date.isNotEmpty) params.add('date=$date');
    if (startDate != null && startDate.isNotEmpty) {
      params.add('start_date=$startDate');
    }
    if (endDate != null && endDate.isNotEmpty) params.add('end_date=$endDate');
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');

    final query = '?${params.join('&')}';
    final response =
        await _client.get('/api/v1/dashboard/business-summary$query');
    return DashboardSummary.fromJson(response as Map<String, dynamic>);
  }
}
