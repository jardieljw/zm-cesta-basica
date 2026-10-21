import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/views/financial_segments_view.dart';
import 'package:zm_cesta_basica_client/widgets/payables/payable_filters_panel.dart';
import 'package:zm_cesta_basica_client/views/payables_view.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'financial_pdf_import_test.dart' as harness;
import 'financial_bill_cycle_integration_test.dart' as cycles;

class DueApi extends cycles.CycleApi {
  @override
  FinancialJson get preview => {
    ...super.preview,
    'content_type': 'DETAILED_CARD_BILL',
    'status': 'INVALID',
    'extracted_header': {
      'statement_type': 'CARD_BILL',
      'total_amount_cents': 13000,
    },
    'header_candidates': {
      'due_on': [
        {'value': '2026-10-24', 'page_number': 2},
        {'value': '2026-10-26', 'page_number': 1},
      ],
    },
    'readiness': {
      'header_status': 'CONFLICTING',
      'details_status': 'AVAILABLE_UNRECONCILED',
      'difference_cents': 2,
    },
  };
  @override
  Future<dynamic> get(String path) async {
    final result = await super.get(path);
    if (Uri.parse(path).path.endsWith('/bill-integration')) {
      return {
        ...result as Map,
        'header': preview['extracted_header'],
        'header_candidates': preview['header_candidates'],
        'readiness': preview['readiness'],
      };
    }
    return result;
  }
}

class SegmentApi extends cycles.CycleApi {
  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    if (path.endsWith('/select-segment')) {
      writes.add((path: path, body: body, key: idempotencyKey));
      return {
        'preview': {...preview, 'content_type': 'RENEGOTIATION'},
      };
    }
    return super.post(
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      isMutation: isMutation,
    );
  }
}

class ComplementApi extends cycles.CycleApi {
  @override
  FinancialJson get preview => {
    ...super.preview,
    'extracted_header': {'statement_type': 'CARD_BILL'},
  };
  @override
  Future<dynamic> get(String path) async {
    final result = await super.get(path);
    if (Uri.parse(path).path.endsWith('/bill-integration')) {
      return {
        ...result as Map,
        'control_candidates': [
          {
            'preview_id': 'summary-control',
            'due_on': '2026-10-24',
            'total_amount_cents': 13000,
            'compiled': true,
          },
        ],
      };
    }
    return result;
  }
}

class CompleteFilterApi extends cycles.CycleApi {
  final queries = <Uri>[];
  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    if (uri.path == '/api/v1/payables/summary') {
      queries.add(uri);
      return {
        'count': 101,
        'open_cents': 1313000,
        'overdue_cents': 0,
        'paid_cents': 0,
        'business_today': '2026-10-19',
      };
    }
    if (uri.path == '/api/v1/payables') {
      queries.add(uri);
      return List.generate(
        100,
        (i) => {
          'id': 'bill-$i',
          'payable_number': i + 1,
          'description': 'Fatura de teste',
          'beneficiary': 'Banco de teste',
          'category': 'CARTAO_CREDITO',
          'nature': 'UNCLASSIFIED',
          'original_amount_cents': 13000,
          'balance_cents': 13000,
          'paid_amount_cents': 0,
          'status': 'OPEN',
          'due_date': '2026-10-24T00:00:00Z',
          'created_at': '2026-10-01T12:00:00Z',
          'updated_at': '2026-10-01T12:00:00Z',
          'financial_bill': cycle,
        },
      );
    }
    return super.get(path);
  }
}

void main() {
  setUpAll(harness.loadImportFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'T04 missing CSV controls are selected once and compilation stays identified',
    (tester) async {
      final api = ComplementApi();
      await cycles.openDraft(tester, api);
      await harness.click(tester, find.textContaining('24/10/2026 ·'));
      expect(
        find.text(
          'Controles de uma compilação fornecida. Confira no documento original; este resumo não comprova todas as compras.',
        ),
        findsOneWidget,
      );
      await cycles.chooseOpen(tester);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect(
        (api.writes.single.body as Map)['control_preview_id'],
        'summary-control',
      );
      expect((api.writes.single.body as Map)['due_on'], '2026-10-24');
      expect(tester.takeException(), isNull);
    },
  );
  for (final config in [
    (const Size(320, 780), 1.7),
    (const Size(1200, 900), 1.0),
  ]) {
    testWidgets('T07 guided due decision preserves candidate pages $config', (
      tester,
    ) async {
      final api = DueApi();
      await harness.mount(
        tester,
        FinancialPdfPreviewView(
          service: FinancialImportService(apiClient: api),
          previewId: 'p1',
        ),
        size: config.$1,
        scale: config.$2,
      );
      expect(
        find.text('Documento lido · confira o vencimento para continuar'),
        findsOneWidget,
      );
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-cycle-open')),
      );
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const ValueKey('bill-integrate-confirm')),
            )
            .onPressed,
        isNull,
      );
      await harness.capture(tester, 'e3-due-${config.$1.width.toInt()}');
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-due-2026-10-24')),
      );
      await harness.capture(
        tester,
        'e3-due-options-${config.$1.width.toInt()}',
      );
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-due-2026-10-26')),
      );
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-details-ack')),
      );
      // Changing a detail decision invalidates the final acknowledgement.
      await cycles.chooseOpen(tester);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      final command = api.writes.single.body as Map;
      expect(command['due_on'], '2026-10-26');
      expect(command['due_conflict_resolved'], isTrue);
      expect(command['accept_details_pending'], isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('T08 selected renegotiation remains evidence without debt', (
    tester,
  ) async {
    final api = SegmentApi();
    await harness.mount(
      tester,
      FinancialSegmentsView(
        service: FinancialImportService(apiClient: api),
        preview: {
          ...api.preview,
          'segments': const [
            {
              'key': '1',
              'institution': 'Banco de teste',
              'reference_label': 'Outubro/2026',
              'document_kind': 'RENEGOTIATION',
              'content_type': 'SUMMARY_ONLY',
              'extracted_header': {'total_amount_cents': 13000},
            },
          ],
        },
      ),
    );
    await harness.click(tester, find.byType(DropdownButtonFormField<String>));
    await harness.click(
      tester,
      find.text('Cartão de teste · Banco de teste').last,
    );
    await harness.click(tester, find.text('Conferir este ciclo'));
    expect(api.writes.single.path, endsWith('/select-segment'));
    expect(find.byKey(const ValueKey('bill-integrate-confirm')), findsNothing);
    await harness.capture(tester, 'e3-segments-390');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'T10 T16 summary covers all matches and filters use identical queries',
    (tester) async {
      final api = CompleteFilterApi();
      await harness.mount(
        tester,
        PayablesView(service: PayableService(client: api)),
        size: const Size(1200, 900),
      );
      expect(find.text('Total de todo o filtro'), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(1313000)), findsOneWidget);
      await harness.capture(tester, 'e3-positive-payables-1200');
      await harness.click(tester, find.byTooltip('Filtros'));
      await tester.enterText(
        find.byKey(const ValueKey('payable-bank-card-filter')),
        'Inter',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payable-merchant-filter')),
        'Loja A',
      );
      await harness.click(tester, find.text('Aplicar Filtros'));
      final recent = api.queries
          .where((uri) => uri.queryParameters['merchant'] == 'Loja A')
          .toList();
      expect(recent.length, 2);
      expect(
        recent.every((uri) => uri.queryParameters['source_query'] == 'Inter'),
        isTrue,
      );
      expect(find.text(AppFormatters.formatCurrency(1313000)), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (index, start, end) in [
    (0, '2026-12-31', '2026-12-31'),
    (1, '2026-12-28', '2027-01-03'),
    (2, '2026-12-01', '2026-12-31'),
    (3, '2027-01-01', '2027-01-31'),
  ]) {
    testWidgets(
      'T10 civil shortcut $index and bank merchant filters apply once',
      (tester) async {
        PayableFilters? result;
        await harness.mount(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<PayableFilters>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                    height: 740,
                    child: PayableFiltersPanel(
                      initial: const PayableFilters(month: 10, year: 2026),
                      businessToday: DateTime(2026, 12, 31),
                    ),
                  ),
                );
              },
              child: const Text('Filtros'),
            ),
          ),
        );
        await harness.click(tester, find.text('Filtros'));
        await tester.enterText(
          find.byKey(const ValueKey('payable-bank-card-filter')),
          'Banco de teste',
        );
        await tester.enterText(
          find.byKey(const ValueKey('payable-merchant-filter')),
          'Loja A',
        );
        await harness.click(
          tester,
          find.byKey(ValueKey('payable-period-$index')),
        );
        await harness.capture(tester, 'e3-filter-$index');
        expect(result, isNull);
        await harness.click(tester, find.text('Aplicar Filtros'));
        expect(result!.from!.toIso8601String().substring(0, 10), start);
        expect(result!.to!.toIso8601String().substring(0, 10), end);
        expect(result!.month, isNull);
        expect(result!.year, isNull);
        expect(result!.bankCard, 'Banco de teste');
        expect(result!.merchant, 'Loja A');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
