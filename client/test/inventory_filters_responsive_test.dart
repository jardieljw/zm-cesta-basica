import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/views/inventory_movements_view.dart';

class _FiltersApi extends ApiClient {
  final requests = <Uri>[];
  @override
  Future<dynamic> get(String path) async {
    requests.add(Uri.parse(path));
    return {
      'items': [],
      'total': 0,
      'page': 1,
      'page_size': 100,
      'total_pages': 1
    };
  }
}

void main() {
  for (final width in [320.0, 390.0, 850.0, 1200.0]) {
    testWidgets('all movement filters stay visible at width $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _FiltersApi();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home:
            InventoryMovementsView(apiClient: api, initialProductId: 'product'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(5));
      for (final filter in find.byType(FilterChip).evaluate()) {
        final finder = find.byWidget(filter.widget);
        expect(finder.hitTestable(), findsOneWidget);
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      await tester.tap(find.text('Produção / Montagem'));
      await tester.pumpAndSettle();
      expect(api.requests.last.queryParameters['movement_type'],
          'ASSEMBLY_PRODUCE');
      expect(api.requests.last.queryParameters['product_id'], 'product');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filters rearrange when an open window becomes narrow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: InventoryMovementsView(apiClient: _FiltersApi()),
    ));
    await tester.pumpAndSettle();
    final first = tester.getTopLeft(find.text('Todos os Tipos')).dy;
    expect(tester.getTopLeft(find.text('Produção / Montagem')).dy, first);
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Produção / Montagem')).dy,
        greaterThan(tester.getTopLeft(find.text('Todos os Tipos')).dy));
    expect(find.text('Produção / Montagem').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
