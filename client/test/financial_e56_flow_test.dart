import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_bill_integration_view.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/views/payables_view.dart';
import 'package:zm_cesta_basica_client/views/receivables_view.dart';
import 'financial_pdf_import_test.dart' as harness;
import 'financial_e3_review_test.dart' as e3;
import 'approved_app_integration_test.dart' as home;
import 'helpers/approved_overview_fake.dart';

class HomeApi extends ApprovedOverviewApi {
  HomeApi(this.state);
  final String state;
  final filters = e3.CompleteFilterApi();
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/v1/payables') ||
        path.startsWith('/api/v1/financial-imports')) {
      return filters.get(path);
    }
    if (path.startsWith('/api/v1/dashboard/business-summary')) {
      if (state == 'error') throw StateError('Dashboard unavailable');
      final data = await super.get(path) as Map;
      if (state == 'empty') {
        (data['financial'] as Map)['payables_records'] = [];
        (data['financial'] as Map)['receivables_records'] = [];
      }
      return data;
    }
    return super.get(path);
  }
}

class RepeatedDueApi extends e3.DueApi {
  bool saved = false;
  @override
  FinancialJson get preview => {
    ...super.preview,
    'header_candidates': {
      'due_on': [
        {'value': '2026-10-26', 'page_number': 1},
        for (var page = 2; page <= 6; page++)
          {'value': '2026-10-24', 'page_number': page},
      ],
    },
  };
  @override
  Future<dynamic> get(String path) async {
    final data = await super.get(path);
    if (Uri.parse(path).path.endsWith('/bill-integration') && saved) {
      return {
        ...data as Map,
        'expected_revision': 2,
        'cycle': {
          ...cycle,
          'preview_id': 'p1',
          'revision': 2,
          'due_on': '2026-10-26',
          'total_amount_cents': 13000,
          'details_status': 'AVAILABLE_UNRECONCILED',
          'difference_cents': 2,
        },
      };
    }
    return data;
  }
}

void main() {
  setUpAll(harness.loadImportFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final state in ['success', 'empty', 'error']) {
    for (final tab in [1, 2]) {
      testWidgets('Home → Financeiro → $tab: consulta acessível em $state', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = HomeApi(state);
        await home.mountApproved(tester, api);
        await home.clickApproved(tester, find.byKey(const ValueKey('area-1')));
        await home.clickApproved(
          tester,
          find.byKey(ValueKey('finance-tab-$tab')),
        );
        await home.clickApproved(
          tester,
          find.byKey(const ValueKey('finance-history')),
        );
        expect(
          find.byType(tab == 1 ? PayablesView : ReceivablesView),
          findsOneWidget,
        );
        if (tab == 1) {
          await harness.click(tester, find.byTooltip('Filtros'));
          expect(find.text('Todos os períodos'), findsOneWidget);
          await harness.click(tester, find.text('Este mês'));
          await tester.enterText(
            find.byKey(const ValueKey('payable-bank-card-filter')),
            'Inter',
          );
          await harness.click(tester, find.text('Todos os períodos'));
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const ValueKey('payable-bank-card-filter')),
                )
                .controller!
                .text,
            'Inter',
          );
          await harness.click(tester, find.text('Aplicar Filtros'));
          expect(
            api.filters.queries.any(
              (q) => q.queryParameters['source_query'] == 'Inter',
            ),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Lista de faturas atuais oferece uma única conferência e recupera resultado',
    (tester) async {
      final api = RepeatedDueApi()..saved = true;
      await harness.mount(
        tester,
        FinancialImportsView(service: FinancialImportService(apiClient: api)),
      );
      expect(find.text('Revisar e Classificar'), findsNothing);
      await harness.click(
        tester,
        find.byKey(const ValueKey('launch-card-btn-p1')),
      );
      expect(
        find.textContaining('Esta conferência já está salva.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('bill-integrate-confirm')),
        findsNothing,
      );
      expect(api.writes, isEmpty);
    },
  );
  for (final size in [
    const Size(320, 780),
    const Size(390, 844),
    const Size(1200, 900),
  ]) {
    testWidgets(
      'Conflito agrupado no local da decisão e resultado reaproveitado $size',
      (tester) async {
        final api = RepeatedDueApi();
        Future<void> mount() => harness.mount(
          tester,
          FinancialBillIntegrationView(
            service: FinancialImportService(apiClient: api),
            preview: api.preview,
          ),
          size: size,
          scale: size.width == 320 ? 1.7 : 1,
        );
        await mount();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('bill-due-2026-10-24')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('bill-due-2026-10-24')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('bill-due-2026-10-26')),
          findsOneWidget,
        );
        expect(find.textContaining('Páginas: 2, 3, 4, 5, 6'), findsOneWidget);
        expect(find.text('Qual é o vencimento correto?'), findsOneWidget);
        expect(find.text('Como funciona a importação'), findsOneWidget);
        await harness.capture(tester, 'e56-perguntas-${size.width.toInt()}');
        // A fresh mount is equivalent to reopening the same immutable document.
        await tester.pumpWidget(const SizedBox.shrink());
        api.saved = true;
        await mount();
        expect(
          find.byKey(const ValueKey('bill-integrate-confirm')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('bill-due-2026-10-24')), findsNothing);
        expect(
          find.textContaining('Esta conferência já está salva.'),
          findsOneWidget,
        );
        expect(find.textContaining('26/10/2026'), findsOneWidget);
        expect(api.writes, isEmpty);
        await harness.capture(tester, 'e56-resultado-${size.width.toInt()}');
        await harness.click(tester, find.text('Alterar conferência salva'));
        expect(
          find.byKey(const ValueKey('bill-integrate-confirm')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FloatingActionButton>(
                find.byKey(const ValueKey('bill-integrate-confirm')),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
