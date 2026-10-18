import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/reports_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/sale_form_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/animated_reveal.dart';

class _FakeApi extends ApiClient {
  final paths = <String>[];
  int stock = 2;
  bool tracksStock = true;
  Map<String, dynamic>? salePayload;

  @override
  Future<dynamic> get(String path) async {
    paths.add(path);
    if (path.startsWith('/api/v1/basket-types')) {
      return [
        {
          'id': 'basket',
          'code': 'BASICA',
          'name': 'Cesta Básica',
          'default_price_cents': 10000,
          'tracks_finished_stock': tracksStock
        }
      ];
    }
    if (path.startsWith('/api/v1/customers')) return [];
    if (path.startsWith('/api/v1/inventory/baskets/')) {
      return {'current_stock': stock};
    }
    if (path.startsWith('/api/v1/reports/')) {
      return {
        'metadata': {
          'generated_at': '2026-10-13T12:00:00Z',
          'filter_info': {'filter_type': 'all', 'label': 'Todos'}
        },
        'headers': [],
        'columns': [],
        'rows': [],
        'totals': {}
      };
    }
    throw StateError('Unexpected request: $path');
  }

  @override
  Future<List<int>> getBytes(String path) async {
    paths.add(path);
    return [1, 2, 3];
  }

  @override
  Future<dynamic> post(String path,
      {dynamic body, String? idempotencyKey, bool isMutation = true}) async {
    expect(path, '/api/v1/sales');
    salePayload = Map<String, dynamic>.from(body as Map);
    return {
      'id': 'sale',
      'sale_number': 1,
      'status': 'CONFIRMED',
      'sale_date': '2026-10-13T12:00:00Z',
      'total_amount_cents': 10000,
      'items': []
    };
  }
}

class _DelayedStockApi extends _FakeApi {
  bool delayStock = false;
  final pending = <Completer<dynamic>>[];

  @override
  Future<dynamic> get(String path) {
    if (delayStock && path.startsWith('/api/v1/inventory/baskets/')) {
      final response = Completer<dynamic>();
      pending.add(response);
      return response.future;
    }
    return super.get(path);
  }
}

class _FailedStockApi extends _FakeApi {
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/v1/inventory/baskets/')) {
      throw StateError('offline');
    }
    return super.get(path);
  }
}

void main() {
  setUpAll(AppFormatters.initialize);

  Future<void> openSale(WidgetTester tester, _FakeApi api) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: SaleFormView(apiClient: api),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'direct sale uses store stock without requesting archived dispatches',
      (tester) async {
    final api = _FakeApi();
    await openSale(tester, api);
    expect(api.paths.any((p) => p.contains('/dispatches')), isFalse);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload!['sale_mode'], 'DIRECT_STORE');
    expect(api.salePayload!['dispatch_id'], isNull);
    expect(api.salePayload!['responsible_person_id'], isNull);
    expect(api.salePayload!['items'][0]['assemble_on_demand'], isFalse);
  });

  testWidgets(
      'insufficient finished stock blocks sale, on-demand assembly still works',
      (tester) async {
    final api = _FakeApi()..stock = 0;
    await openSale(tester, api);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload, isNull);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload!['items'][0]['assemble_on_demand'], isTrue);
    expect(api.salePayload!['sale_mode'], 'DIRECT_STORE');
  });

  testWidgets('ready stock folds smoothly and keeps quantity when switching',
      (tester) async {
    await openSale(tester, _FakeApi());
    expect(find.text('Pronta'), findsOneWidget);
    expect(find.text('Montar'), findsOneWidget);
    final reveal = find.byType(AnimatedReveal);
    final initialHeight = tester.getSize(reveal).height;
    expect(initialHeight, greaterThan(0));
    final quantity = find.widgetWithText(TextFormField, 'Quantidade');
    await tester.enterText(quantity, '2');
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.getSize(reveal).height, greaterThan(0));
    expect(tester.getSize(reveal).height, lessThan(initialHeight));
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, 0);
    expect(
        find.text(
            'Consome os produtos da composição e registra a montagem ao confirmar a venda.'),
        findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, greaterThan(0));
    expect(find.text('Cestas prontas disponíveis: 2'), findsOneWidget);
    final field = tester.widget<TextFormField>(quantity);
    expect(field.controller?.text ?? field.initialValue, '2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mode control fits a phone and honors reduced motion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 980));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: SaleFormView(apiClient: _FakeApi()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.getSize(find.byType(AnimatedReveal)).height, 0);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedReveal)).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('newer stock query wins after rapid mode changes',
      (tester) async {
    final api = _DelayedStockApi();
    await openSale(tester, api);
    api.delayStock = true;
    await tester.ensureVisible(find.byType(Switch));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(Switch));
      await tester.pump();
    }
    expect(api.pending.length, 2);
    expect(find.text('Consultando saldo…'), findsOneWidget);
    api.pending[1].complete({'current_stock': 9});
    await tester.pumpAndSettle();
    expect(find.text('Cestas prontas disponíveis: 9'), findsOneWidget);
    api.pending[0].complete({'current_stock': 1});
    await tester.pumpAndSettle();
    expect(find.text('Cestas prontas disponíveis: 9'), findsOneWidget);
    expect(find.text('Cestas prontas disponíveis: 1'), findsNothing);
  });

  testWidgets('stock failure is explicit and only blocks ready sale',
      (tester) async {
    final api = _FailedStockApi();
    await openSale(tester, api);
    expect(find.text('Não foi possível consultar o saldo. Tente novamente.'),
        findsOneWidget);
    expect(find.text('Cestas prontas disponíveis: 0'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload, isNull);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload!['items'][0]['assemble_on_demand'], isTrue);
  });

  testWidgets(
      'disabled ready stock automatically assembles without a stock query',
      (tester) async {
    final api = _FakeApi()..tracksStock = false;
    await openSale(tester, api);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Montar na venda'), findsOneWidget);
    expect(api.paths.any((p) => p.startsWith('/api/v1/inventory/baskets/')),
        isFalse);
    expect(tester.getSize(find.byType(AnimatedReveal)).height, 0);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.salePayload!['items'][0]['assemble_on_demand'], isTrue);
  });

  test('sales report and both exports enforce the same transfer exclusion',
      () async {
    final api = _FakeApi();
    final service = ReportsService(client: api);
    await service.getReport('sales', filterType: 'all');
    for (final format in ['csv', 'xlsx']) {
      await service
          .downloadReportFile('sales', format, filters: {'filter_type': 'all'});
    }
    for (final path in api.paths) {
      final uri = Uri.parse(path);
      expect(uri.path, startsWith('/api/v1/reports/sales-dispatches'));
      expect(uri.queryParameters['include_dispatches'], 'false');
      expect(uri.queryParameters['filter_type'], 'all');
    }
  });
}
