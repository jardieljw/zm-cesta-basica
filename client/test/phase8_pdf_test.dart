import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/dashboard.dart';
import 'package:zm_cesta_basica_client/models/report.dart';
import 'package:zm_cesta_basica_client/utils/report_pdf_builder.dart';

void main() {
  group('Phase 8 ReportPdfBuilder PDF Generation Tests', () {
    final sampleReport = ReportResponse(
      metadata: ReportMetadata(
        reportType: 'sales-dispatches',
        title: 'Relatório Demonstrativo de Vendas e Saídas',
        companyName: 'ZM Cesta Básica Ltda',
        generatedAt: DateTime.parse('2026-10-12T14:30:00Z'),
        filterInfo: FilterInfo(filterType: 'today', label: 'Hoje (12/10/2026)'),
        totalRows: 5,
      ),
      headers: ['Data/Hora', 'Venda #', 'Cliente', 'Modo', 'Valor Total'],
      columns: ['date', 'sale_number', 'customer_name', 'sale_mode', 'total_amount_cents'],
      rows: [
        {
          'date': '12/10/2026 09:30',
          'sale_number': 101,
          'customer_name': 'Mercadinho Primavera',
          'sale_mode': 'DIRECT_STORE',
          'total_amount_cents': 15000,
        },
        {
          'date': '12/10/2026 10:15',
          'sale_number': 102,
          'customer_name': 'Padaria Pão Quente',
          'sale_mode': 'ROUTE_DISPATCH',
          'total_amount_cents': 32000,
        },
        {
          'date': '12/10/2026 11:00',
          'sale_number': 103,
          'customer_name': 'Comercial Silva',
          'sale_mode': 'DIRECT_STORE',
          'total_amount_cents': 21000,
        },
      ],
      totals: {
        'total_amount_cents': 68000,
      },
    );

    test('buildReportPdf generates valid PDF bytes in portrait format', () async {
      final bytes = await ReportPdfBuilder.buildReportPdf(sampleReport, isLandscape: false);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // PDF documents start with '%PDF-'
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('buildReportPdf generates valid PDF bytes in landscape format', () async {
      final bytes = await ReportPdfBuilder.buildReportPdf(sampleReport, isLandscape: true);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('buildReportPdf generates valid PDF when rows and totals are empty', () async {
      final emptyReport = ReportResponse(
        metadata: ReportMetadata(
          reportType: 'physical-inventory',
          title: 'Contagem Física de Estoque',
          companyName: 'ZM Cesta Básica',
          generatedAt: DateTime.now(),
          filterInfo: FilterInfo(filterType: 'all', label: 'Todos os registros'),
          totalRows: 0,
        ),
        headers: ['Código', 'Produto', 'Unidade', 'Estoque Sistema', 'Contagem Física'],
        columns: ['code', 'name', 'unit', 'system_stock', 'physical_count'],
        rows: [],
        totals: {},
      );

      final bytes = await ReportPdfBuilder.buildReportPdf(emptyReport);
      expect(bytes, isNotEmpty);
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('buildBlankFormPdf generates valid printable A4 form with spacious rows', () async {
      final blankReport = ReportResponse(
        metadata: ReportMetadata(
          reportType: 'blank_template',
          title: 'Tabela de Pagamentos de Cestas (Fiados / Quitações)',
          companyName: 'ZM Cesta Básica',
          generatedAt: DateTime.now(),
          filterInfo: FilterInfo(filterType: 'template', label: 'Modelo Oficial de Prancheta'),
          totalRows: 0,
        ),
        headers: ['Data', 'Nº Venda', 'Cliente / Destinatário', 'Qtd Cestas', 'Valor Total', 'Forma Pagto', 'Assinatura / Visto'],
        columns: ['date', 'sale_number', 'customer', 'baskets_qty', 'total_amount', 'payment_method', 'signature'],
        rows: [],
        totals: {},
      );

      final bytes = await ReportPdfBuilder.buildBlankFormPdf(
        blankReport,
        isLandscape: true,
        blankRowCount: 16,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');

      // Test with custom row count (25 rows)
      final bytes25 = await ReportPdfBuilder.buildBlankFormPdf(
        blankReport,
        isLandscape: true,
        blankRowCount: 25,
      );
      expect(bytes25, isNotEmpty);
      expect(bytes25.length, greaterThan(1000));
    });
  });
}
