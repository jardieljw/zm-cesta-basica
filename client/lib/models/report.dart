import 'dashboard.dart';

class ReportMetadata {
  final String reportType;
  final String title;
  final String companyName;
  final DateTime generatedAt;
  final FilterInfo filterInfo;
  final int totalRows;

  ReportMetadata({
    required this.reportType,
    required this.title,
    required this.companyName,
    required this.generatedAt,
    required this.filterInfo,
    required this.totalRows,
  });

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      reportType: json['report_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyName: json['company_name'] as String? ?? 'ZM Cesta Básica',
      generatedAt: DateTime.parse(json['generated_at'] as String),
      filterInfo:
          FilterInfo.fromJson(json['filter_info'] as Map<String, dynamic>),
      totalRows: json['total_rows'] as int? ?? 0,
    );
  }
}

class ReportResponse {
  final ReportMetadata metadata;
  final List<String> headers;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> totals;

  ReportResponse({
    required this.metadata,
    required this.headers,
    required this.columns,
    required this.rows,
    required this.totals,
  });

  Map<String, dynamic> toJson() => {
        'metadata': {
          'report_type': metadata.reportType,
          'title': metadata.title,
          'company_name': metadata.companyName,
          'generated_at': metadata.generatedAt.toIso8601String(),
          'total_rows': metadata.totalRows,
          'filter_info': {
            'filter_type': metadata.filterInfo.filterType,
            'label': metadata.filterInfo.label
          },
        },
        'headers': headers,
        'columns': columns,
        'rows': rows,
        'totals': totals,
      };

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      metadata:
          ReportMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      headers: (json['headers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      columns: (json['columns'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      totals: Map<String, dynamic>.from(json['totals'] as Map? ?? {}),
    );
  }
}
