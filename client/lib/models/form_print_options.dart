import 'dart:math' as math;
import 'report.dart';

/// Shared presentation contract with schemas/form_print.py; units are millimetres.
class FormPrintOptions {
  final List<String>? columns;
  final String orientation;
  final double marginTopMm, marginBottomMm, marginLeftMm, marginRightMm;
  final double rowHeightMm, fontSize;
  final int? blankRowCount;
  final Map<String, double> columnWeights;
  final bool showSignatures;

  const FormPrintOptions(
      {this.columns,
      this.orientation = 'auto',
      this.marginTopMm = 15,
      this.marginBottomMm = 15,
      this.marginLeftMm = 15,
      this.marginRightMm = 15,
      this.rowHeightMm = 9,
      this.fontSize = 9,
      this.blankRowCount,
      this.columnWeights = const {},
      this.showSignatures = true});

  bool landscape(int count) =>
      orientation == 'landscape' || (orientation == 'auto' && count > 5);
  int automaticRows(int count) => math.max(
      1,
      (((landscape(count) ? 210 : 297) -
                  marginTopMm -
                  marginBottomMm -
                  28 -
                  18 -
                  (showSignatures ? 18 : 9)) /
              rowHeightMm)
          .floor());
  int blankRows(int count) => blankRowCount ?? automaticRows(count);
  static double defaultWeight(String column) {
    if (['qty', 'unit'].contains(column)) return 0.7;
    if (['customer', 'description', 'beneficiary', 'item_name', 'notes']
        .contains(column)) {
      return 2.5;
    }
    if (column == 'basket_type') return 1.8;
    return 1.4;
  }

  double weight(String column) =>
      columnWeights[column] ?? defaultWeight(column);

  FormPrintOptions copyWith(
          {List<String>? columns,
          String? orientation,
          double? marginTopMm,
          double? marginBottomMm,
          double? marginLeftMm,
          double? marginRightMm,
          double? rowHeightMm,
          double? fontSize,
          int? blankRowCount,
          bool automaticRows = false,
          Map<String, double>? columnWeights,
          bool? showSignatures}) =>
      FormPrintOptions(
          columns: columns ?? this.columns,
          orientation: orientation ?? this.orientation,
          marginTopMm: marginTopMm ?? this.marginTopMm,
          marginBottomMm: marginBottomMm ?? this.marginBottomMm,
          marginLeftMm: marginLeftMm ?? this.marginLeftMm,
          marginRightMm: marginRightMm ?? this.marginRightMm,
          rowHeightMm: rowHeightMm ?? this.rowHeightMm,
          fontSize: fontSize ?? this.fontSize,
          blankRowCount:
              automaticRows ? null : blankRowCount ?? this.blankRowCount,
          columnWeights: columnWeights ?? this.columnWeights,
          showSignatures: showSignatures ?? this.showSignatures);

  Map<String, dynamic> toJson() => {
        'columns': columns,
        'orientation': orientation,
        'margin_top_mm': marginTopMm,
        'margin_bottom_mm': marginBottomMm,
        'margin_left_mm': marginLeftMm,
        'margin_right_mm': marginRightMm,
        'row_height_mm': rowHeightMm,
        'font_size': fontSize,
        'blank_row_count': blankRowCount,
        'column_weights': columnWeights,
        'show_signatures': showSignatures,
      };

  factory FormPrintOptions.fromJson(Map<String, dynamic> json) {
    double number(String key, double fallback, double min, double max) =>
        ((json[key] as num?)?.toDouble() ?? fallback).clamp(min, max);
    return FormPrintOptions(
      columns: (json['columns'] as List?)?.cast<String>(),
      orientation:
          ['auto', 'portrait', 'landscape'].contains(json['orientation'])
              ? json['orientation'] as String
              : 'auto',
      marginTopMm: number('margin_top_mm', 15, 5, 40),
      marginBottomMm: number('margin_bottom_mm', 15, 5, 40),
      marginLeftMm: number('margin_left_mm', 15, 5, 40),
      marginRightMm: number('margin_right_mm', 15, 5, 40),
      rowHeightMm: number('row_height_mm', 9, 6, 30),
      fontSize: number('font_size', 9, 8, 16),
      blankRowCount: (json['blank_row_count'] as int?)?.clamp(1, 500),
      columnWeights: (json['column_weights'] as Map? ?? {}).map((key, value) =>
          MapEntry(key.toString(), (value as num).toDouble().clamp(0.5, 8))),
      showSignatures: json['show_signatures'] as bool? ?? true,
    );
  }

  ReportResponse select(ReportResponse report) {
    final selected = columns ?? report.columns;
    if (selected.isEmpty ||
        selected.toSet().length != selected.length ||
        selected.any((c) => !report.columns.contains(c))) {
      throw ArgumentError('Invalid form columns');
    }
    return ReportResponse(
        metadata: report.metadata,
        columns: selected,
        headers: selected
            .map((c) => report.headers[report.columns.indexOf(c)])
            .toList(),
        rows: report.rows
            .map((r) => {for (final c in selected) c: r[c] ?? ''})
            .toList(),
        totals: {
          for (final c in selected)
            if (report.totals.containsKey(c)) c: report.totals[c]
        });
  }
}
