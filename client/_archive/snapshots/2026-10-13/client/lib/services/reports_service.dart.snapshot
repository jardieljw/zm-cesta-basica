import '../core/api_client.dart';
import '../models/report.dart';

class ReportsService {
  final ApiClient _client;

  ReportsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<ReportResponse> getReport(
    String reportType, {
    String filterType = 'today',
    String? date,
    String? startDate,
    String? endDate,
    int? month,
    int? year,
    String? basketTypeId,
    String? customerId,
    String? responsibleId,
    String? productId,
    String? category,
    String? status,
    String? nature,
    bool onlyBelowMin = false,
  }) async {
    final params = <String>['filter_type=$filterType'];
    if (date != null && date.isNotEmpty) params.add('date=$date');
    if (startDate != null && startDate.isNotEmpty) params.add('start_date=$startDate');
    if (endDate != null && endDate.isNotEmpty) params.add('end_date=$endDate');
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (basketTypeId != null && basketTypeId.isNotEmpty) params.add('basket_type_id=$basketTypeId');
    if (customerId != null && customerId.isNotEmpty) params.add('customer_id=$customerId');
    if (responsibleId != null && responsibleId.isNotEmpty) params.add('responsible_id=$responsibleId');
    if (productId != null && productId.isNotEmpty) params.add('product_id=$productId');
    if (category != null && category.isNotEmpty) params.add('category=${Uri.encodeComponent(category)}');
    if (status != null && status.isNotEmpty) params.add('status=$status');
    if (nature != null && nature.isNotEmpty) params.add('nature=$nature');
    if (onlyBelowMin) params.add('only_below_min=true');

    final query = '?${params.join('&')}';
    final response = await _client.get('/api/v1/reports/$reportType$query');
    return ReportResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<ReportResponse> getBlankTemplate(String formType, {bool filled = false}) async {
    final response = await _client.get('/api/v1/reports/blank-templates/$formType?filled=$filled');
    return ReportResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<List<int>> downloadReportFile(
    String reportType,
    String format, {
    Map<String, String>? filters,
  }) async {
    final params = <String>['format=$format'];
    if (filters != null) {
      filters.forEach((key, value) {
        if (value.isNotEmpty) {
          params.add('$key=${Uri.encodeComponent(value)}');
        }
      });
    }
    final query = '?${params.join('&')}';
    return await _client.getBytes('/api/v1/reports/$reportType/export$query');
  }

  Future<List<int>> downloadBlankTemplateXlsx(String formType, {bool filled = false}) async {
    return await _client.getBytes('/api/v1/reports/blank-templates/$formType/export?filled=$filled');
  }
}
