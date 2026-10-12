import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report.dart';

class ReportPdfBuilder {
  static final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Cleans and sanitizes strings to be safe for Helvetica/Standard-14 PDF fonts.
  /// Translates common Unicode punctuation to safe ASCII equivalents.
  static String _cleanText(String input) {
    if (input.isEmpty) return input;
    var text = input
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '--')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2022', '*')
        .replaceAll('\u2026', '...')
        .replaceAll('\u00A0', ' ')
        .replaceAll('•', '*')
        .replaceAll('–', '-')
        .replaceAll('—', '--')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('‘', "'");

    final runes = text.runes.map((r) => r <= 255 ? r : 0x3F).toList();
    return String.fromCharCodes(runes);
  }

  /// Translates snake_case database total keys into human-readable Portuguese labels.
  static String formatTotalLabel(String key) {
    const labels = {
      'quantity': 'Qtd Total',
      'total_price_cents': 'Valor Total',
      'quantity_produced': 'Qtd Produzida',
      'total_cost_cents': 'Custo Total',
      'quantity_delta': 'Variação Líquida',
      'original_amount_cents': 'Valor Original',
      'paid_amount_cents': 'Valor Pago',
      'balance_cents': 'Saldo em Aberto',
      'qty_dispatched': 'Qtd Retirada',
      'qty_sold': 'Qtd Vendida',
      'qty_returned': 'Qtd Devolvida',
      'repaid_cash_cents': 'Total Repassado',
      'cash_discrepancy_cents': 'Diferença Caixa',
      'total_stock_value_cents': 'Valor Total Estoque',
      'amount_cents': 'Resultado Líquido',
      'total_cents': 'Valor Total',
      'received_cents': 'Valor Recebido',
    };
    return labels[key] ?? key;
  }

  static String _formatCell(dynamic value, String colName) {
    if (value == null) return '';
    final colLower = colName.toLowerCase();
    if (colLower.endsWith('_cents') || colLower.contains('valor') || colLower.contains('preco')) {
      if (value is int) {
        return _currencyFormat.format(value / 100.0);
      } else if (value is double) {
        return _currencyFormat.format(value / 100.0);
      }
    }
    if (value is DateTime) {
      if (value.hour == 0 && value.minute == 0) {
        return _dateFormat.format(value);
      }
      return _dateTimeFormat.format(value);
    }
    if (value is String && (colLower.contains('date') || colLower.contains('data') || colLower.contains('at') || colLower.contains('vencimento'))) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        if (parsed.hour == 0 && parsed.minute == 0 && !value.contains('T')) {
          return _dateFormat.format(parsed);
        }
        return _dateTimeFormat.format(parsed);
      }
    }
    return _cleanText(value.toString());
  }

  /// Builds a paginated A4 PDF for any of the 8 canonical filled reports.
  static Future<Uint8List> buildReportPdf(
    ReportResponse report, {
    bool isLandscape = false,
  }) async {
    final pdf = pw.Document();
    final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    // Calculate column alignments
    final cellAlignments = <int, pw.AlignmentGeometry>{};
    final headerAlignments = <int, pw.AlignmentGeometry>{};
    for (var i = 0; i < report.columns.length; i++) {
      final col = report.columns[i].toLowerCase();
      if (col.endsWith('_cents') ||
          col.contains('valor') ||
          col.contains('preco') ||
          col.contains('qty') ||
          col.contains('quantity') ||
          col.contains('delta') ||
          col.contains('stock') ||
          col.contains('saldo')) {
        cellAlignments[i] = pw.Alignment.centerRight;
        headerAlignments[i] = pw.Alignment.centerRight;
      } else if (col.contains('date') ||
          col.contains('data') ||
          col.contains('at') ||
          col.contains('vencimento') ||
          col.contains('status') ||
          col.contains('sig') ||
          col.contains('is_')) {
        cellAlignments[i] = pw.Alignment.center;
        headerAlignments[i] = pw.Alignment.center;
      } else {
        cellAlignments[i] = pw.Alignment.centerLeft;
        headerAlignments[i] = pw.Alignment.centerLeft;
      }
    }

    final sanitizedHeaders = report.headers.map(_cleanText).toList();

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
                      _cleanText(report.metadata.companyName.toUpperCase()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      _cleanText(report.metadata.title),
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      _cleanText('Filtro: ${report.metadata.filterInfo.label}'),
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
                      'Emissão: ${_dateTimeFormat.format(report.metadata.generatedAt)}',
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
              headers: sanitizedHeaders,
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
              cellAlignments: cellAlignments,
              headerAlignments: headerAlignments,
              cellPadding: pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: report.metadata.reportType.startsWith('audit-') ? 6 : 4,
              ),
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
                            '${formatTotalLabel(entry.key)}: ${_formatCell(entry.value, entry.key)}',
                            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            if (report.metadata.reportType.startsWith('audit-')) ...[
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 3),
                      pw.Text('Assinatura do Responsável', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 3),
                      pw.Text('Visto do Conferente / Auditor', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
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
    final sanitizedHeaders = blankReport.headers.map(_cleanText).toList();

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
                      _cleanText(blankReport.metadata.title),
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
            (_) => List.generate(sanitizedHeaders.length, (_) => ''),
          );

          return [
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: sanitizedHeaders,
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
