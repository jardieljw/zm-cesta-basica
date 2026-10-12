import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report.dart';

class ReportPdfBuilder {
  static final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String _formatCell(dynamic value, String colName) {
    if (value == null) return '';
    if (colName.endsWith('_cents') || colName.contains('valor') || colName.contains('preco') || colName.contains('total')) {
      if (value is int) {
        return _currencyFormat.format(value / 100.0);
      } else if (value is double) {
        return _currencyFormat.format(value / 100.0);
      }
    }
    if (value is DateTime) {
      return _dateFormat.format(value);
    }
    return value.toString();
  }

  /// Builds a paginated A4 PDF for any of the 8 canonical filled reports.
  static Future<Uint8List> buildReportPdf(
    ReportResponse report, {
    bool isLandscape = false,
  }) async {
    final pdf = pw.Document();
    final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36), // ~13mm safe margin
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      report.metadata.companyName.toUpperCase(),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      report.metadata.title,
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      'Filtro: ${report.metadata.filterInfo.label}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Emissão: ${_dateFormat.format(report.metadata.generatedAt)}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                    if (context.pageNumber > 1)
                      pw.Text(
                        'Continuação da Tabela',
                        style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ZM Cesta Básica - Sistema de Gestão',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: report.headers,
              data: report.rows.map((row) {
                return report.columns.map((col) => _formatCell(row[col], col)).toList();
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: isLandscape ? 8 : 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: pw.TextStyle(
                fontSize: isLandscape ? 7.5 : 7,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            if (report.totals.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey500, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAIS DO RELATÓRIO',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.Row(
                      children: report.totals.entries.map((entry) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 16),
                          child: pw.Text(
                            '${entry.key}: ${_formatCell(entry.value, entry.key)}',
                            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Builds a blank printable A4 form with spacious lines (approx. 9-10mm height) for pen handwriting.
  static Future<Uint8List> buildBlankFormPdf(
    ReportResponse blankReport, {
    bool isLandscape = true,
    int blankRowCount = 16,
  }) async {
    final pdf = pw.Document();
    final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ZM CESTA BÁSICA - CONTROLE OPERACIONAL',
                      style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      blankReport.metadata.title,
                      style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Formulário Oficial de Prancheta para Preenchimento Manual à Caneta',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Data: ____/____/________',
                      style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Visto / Auditor: __________________',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 3),
                      pw.Text('Assinatura do Responsável', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 3),
                      pw.Text('Visto do Conferente / Auditor', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Documento para Auditoria Física e Prestação de Contas', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          // Generate empty row data
          final emptyRows = List.generate(
            blankRowCount,
            (_) => List.generate(blankReport.headers.length, (_) => ''),
          );

          return [
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: blankReport.headers,
              data: emptyRows,
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              headerStyle: pw.TextStyle(
                fontSize: isLandscape ? 8.5 : 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              // Generous row height: 26 pt (~9.2mm) for easy pen handwriting!
              cellHeight: 26,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
