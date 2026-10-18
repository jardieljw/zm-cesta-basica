import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report.dart';
import '../models/form_print_options.dart';

class FormPdfResult {
  final Uint8List bytes;
  final int pages;
  final int rows;
  const FormPdfResult(this.bytes, this.pages, this.rows);
}

class FormPdfBuilder {
  static String text(Object? value) => (value ?? '')
      .toString()
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('“', '"')
      .replaceAll('”', '"');

  static String formatCell(dynamic value, String column) {
    if (value == null || value == '') return '';
    if (column.endsWith('_cents') && value is num) {
      return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(value / 100);
    }
    if (column.endsWith('_date') || value is DateTime) {
      var date =
          value is DateTime ? value : DateTime.tryParse(value.toString());
      // Due dates are calendar dates; legacy naive sale/payment timestamps are UTC.
      if (date != null &&
          column != 'due_date' &&
          value is String &&
          value.contains('T') &&
          !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
        date = DateTime.tryParse('${value}Z');
      }
      if (date != null) {
        return DateFormat('dd/MM/yyyy')
            .format(column == 'due_date' ? date : date.toLocal());
      }
    }
    if (value is num) return NumberFormat.decimalPattern('pt_BR').format(value);
    return text(value);
  }

  static Future<FormPdfResult> build(
      ReportResponse source, FormPrintOptions options,
      {required bool blank}) async {
    if (blank && options.blankRowCount == null) {
      // Real layout validation also covers taller headers with custom fonts and widths.
      var rows =
          options.automaticRows((options.columns ?? source.columns).length);
      while (true) {
        final result = await build(
            source, options.copyWith(blankRowCount: rows),
            blank: true);
        if (result.pages == 1 || rows == 1) return result;
        rows--;
      }
    }
    final report = options.select(source);
    final count = report.columns.length;
    final landscape = options.landscape(count);
    final page = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    final doc = pw.Document();
    final data = blank
        ? List.generate(options.blankRows(count), (_) => List.filled(count, ''))
        : report.rows
            .map((row) =>
                report.columns.map((c) => formatCell(row[c], c)).toList())
            .toList();
    final weights = {
      for (var i = 0; i < count; i++)
        i: pw.FlexColumnWidth(options.weight(report.columns[i]))
    };
    doc.addPage(pw.MultiPage(
      pageFormat: page,
      maxPages: 2000,
      margin: pw.EdgeInsets.fromLTRB(
          options.marginLeftMm * PdfPageFormat.mm,
          options.marginTopMm * PdfPageFormat.mm,
          options.marginRightMm * PdfPageFormat.mm,
          options.marginBottomMm * PdfPageFormat.mm),
      header: (context) => pw.Container(
          height: 28 * PdfPageFormat.mm,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(text(report.metadata.companyName),
                    style: const pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(text(report.metadata.title),
                    maxLines: 2,
                    style: const pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(
                    blank
                        ? 'Data: ____/____/________   Responsável: ____________________'
                        : 'Consulta: ${DateFormat('dd/MM/yyyy HH:mm').format(report.metadata.generatedAt.toLocal())} - ${report.metadata.totalRows} registros',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 3),
                pw.Divider(height: 1),
              ])),
      footer: (context) => pw.Container(
          height: (options.showSignatures ? 18 : 9) * PdfPageFormat.mm,
          child:
              pw.Column(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            if (options.showSignatures) ...[
              pw.Row(children: [
                pw.Expanded(
                    child: pw.Text('Responsável: ____________________',
                        style: const pw.TextStyle(fontSize: 8))),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Text('Conferente: ____________________',
                        style: const pw.TextStyle(fontSize: 8))),
              ]),
              pw.SizedBox(height: 8),
            ],
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8)),
          ])),
      build: (context) => [
        pw.TableHelper.fromTextArray(
            headers: report.headers.map(text).toList(),
            data: data,
            columnWidths: weights,
            headerHeight: 18 * PdfPageFormat.mm,
            cellHeight: options.rowHeightMm * PdfPageFormat.mm,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            headerPadding: const pw.EdgeInsets.all(3),
            headerStyle: pw.TextStyle(
                fontSize: options.fontSize, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: options.fontSize),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              for (var i = 0; i < count; i++)
                if (report.columns[i].endsWith('_cents'))
                  i: pw.Alignment.centerRight
            },
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5)),
        if (!blank && data.isEmpty)
          pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text('Nenhum registro encontrado.')),
        if (!blank && report.totals.isNotEmpty)
          pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: report.totals.entries
                      .map((entry) => pw.Text(
                          '${report.headers[report.columns.indexOf(entry.key)]}: ${formatCell(entry.value, entry.key)}',
                          style: pw.TextStyle(
                              fontSize: options.fontSize,
                              fontWeight: pw.FontWeight.bold)))
                      .toList())),
      ],
    ));
    final bytes = await doc.save();
    return FormPdfResult(
        bytes, doc.document.pdfPageList.pages.length, data.length);
  }
}
