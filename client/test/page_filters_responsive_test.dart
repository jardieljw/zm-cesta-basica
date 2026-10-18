import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/product_service.dart';
import 'package:zm_cesta_basica_client/views/products_view.dart';
import 'package:zm_cesta_basica_client/views/basket_types_view.dart';
import 'package:zm_cesta_basica_client/views/purchases_view.dart';
import 'package:zm_cesta_basica_client/views/customers_view.dart';
import 'package:zm_cesta_basica_client/views/inventory_summary_view.dart';
import 'package:zm_cesta_basica_client/views/receivables_view.dart';
import 'package:zm_cesta_basica_client/views/sales_view.dart';

class _FiltersApi extends ApiClient {
  final requests = <Uri>[];
  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    requests.add(uri);
    return uri.path.endsWith('/purchases') ? {'items': []} : [];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final pages = <String, Widget Function(_FiltersApi)>{
    'products': (api) => ProductsView(service: ProductService(client: api)),
    'baskets': (api) => BasketTypesView(apiClient: api),
    'purchases': (api) => PurchasesView(apiClient: api),
    'customers': (api) => CustomersView(apiClient: api),
    'inventory': (api) => InventorySummaryView(apiClient: api),
    'receivables': (api) => ReceivablesView(apiClient: api),
  };
  final selections = {
    'products': ('Insumo', 'category', 'INSUMO'),
    'baskets': ('Personalizada', 'category', 'PERSONALIZADA'),
    'purchases': ('Canceladas', 'status', 'CANCELED'),
    'customers': ('Inativo', 'is_active', 'false'),
    'inventory': ('Apenas Abaixo do Mínimo', 'below_minimum_only', 'true'),
    'receivables': ('Vencido', 'overdue_only', 'true'),
  };

  for (final page in pages.entries) {
    for (final width in [320.0, 390.0, 1200.0]) {
      testWidgets(
        '${page.key} filters remain accessible after resize to $width',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final api = _FiltersApi();
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('pt', 'BR'),
              home: page.value(api),
            ),
          );
          await tester.pumpAndSettle();
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpAndSettle();
          if (page.key == 'receivables') {
            await tester.tap(find.byKey(const ValueKey('receipt-filters')));
            await tester.pumpAndSettle();
          }
          final chips = find.byWidgetPredicate(
            (widget) => widget is ChoiceChip || widget is FilterChip,
          );
          expect(chips, findsWidgets);
          for (final element in chips.evaluate()) {
            final finder = find.byWidget(element.widget);
            expect(finder.hitTestable(), findsOneWidget);
            expect(tester.getRect(finder).left, greaterThanOrEqualTo(0));
            expect(tester.getRect(finder).right, lessThanOrEqualTo(width));
          }
          final selection = selections[page.key]!;
          await tester.tap(find.text(selection.$1));
          await tester.pumpAndSettle();
          expect(
            api.requests.any(
              (uri) => uri.queryParameters[selection.$2] == selection.$3,
            ),
            isTrue,
          );
          await tester.binding.setSurfaceSize(const Size(1200, 900));
          await tester.pumpAndSettle();
          final selected = tester.widget(
            find.ancestor(of: find.text(selection.$1), matching: chips),
          );
          expect(
            selected is ChoiceChip
                ? selected.selected
                : (selected as FilterChip).selected,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('sale filter dropdowns remain usable in a narrow window', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _FiltersApi();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: SalesView(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(DropdownButtonFormField<String?>);
    expect(fields, findsNWidgets(2));
    expect(fields.hitTestable(), findsNWidgets(2));
    expect(
      tester.getTopLeft(fields.last).dy,
      greaterThan(tester.getTopLeft(fields.first).dy),
    );
    await tester.tap(fields.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PIX').last);
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['payment_mode'], 'PIX');
    expect(tester.takeException(), isNull);
  });
}
