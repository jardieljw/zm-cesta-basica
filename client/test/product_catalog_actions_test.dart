import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/models/product.dart';
import 'package:zm_cesta_basica_client/services/product_service.dart';
import 'package:zm_cesta_basica_client/services/purchase_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/products_view.dart';
import 'package:zm_cesta_basica_client/views/packagings_dialog.dart';
import 'package:zm_cesta_basica_client/views/purchase_form_view.dart';

class _CatalogApi extends ApiClient {
  bool used = false;
  bool deleted = false;
  bool isActive = true;
  final deletedPaths = <String>[];
  Map<String, dynamic> get product => {
        'id': 'rice',
        'name': 'Arroz',
        'category': 'ALIMENTACAO',
        'base_unit': 'G',
        'created_at': '2026-10-14T03:00:00Z',
        'updated_at': '2026-10-14T03:00:00Z',
        'is_active': isActive,
        'packagings': [
          {
            'id': 'old',
            'product_id': 'rice',
            'name': 'Saco antigo',
            'quantity_in_base_units': 1000,
            'is_default': true,
            'is_active': false
          },
          {
            'id': 'sack',
            'product_id': 'rice',
            'name': 'Saco de 5 kg',
            'quantity_in_base_units': 5000,
            'is_default': false,
            'is_active': true
          },
        ],
      };
  @override
  Future<dynamic> get(String path) async {
    if (path.endsWith('/deletion-check')) {
      return {
        'can_delete': !used,
        'reasons': used ? ['RECIPES'] : []
      };
    }
    if (path.endsWith('/packagings')) return product['packagings'];
    if (path.startsWith('/api/v1/products')) return deleted ? [] : [product];
    throw StateError('Unexpected request: $path');
  }

  @override
  Future<dynamic> delete(String path, {bool isMutation = true, String? idempotencyKey}) async {
    deletedPaths.add(path);
    deleted = true;
    return {'deleted': true};
  }
}

void main() {
  setUpAll(AppFormatters.initialize);
  final l10n = AppLocalizationsPt();
  Future<void> render(WidgetTester tester, Widget view,
      {double width = 1000}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: view,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('unused product is permanently deleted only after confirmation',
      (tester) async {
    final api = _CatalogApi();
    await render(tester, ProductsView(service: ProductService(client: api)));
    expect(tester.getRect(find.byType(ListView)).bottom,
        greaterThan(tester.getRect(find.byType(FloatingActionButton)).bottom));
    expect(find.byTooltip(l10n.commonEdit), findsOneWidget);
    expect(find.byTooltip(l10n.productInactivateButton), findsOneWidget);
    expect(find.byTooltip(l10n.productDeleteButton), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.productDeleteButton));
    await tester.pumpAndSettle();
    expect(api.deletedPaths, isEmpty);
    await tester
        .tap(find.widgetWithText(ElevatedButton, l10n.productDeleteButton));
    await tester.pumpAndSettle();
    expect(api.deletedPaths, ['/api/v1/products/rice/permanent']);
    expect(find.text(l10n.productEmpty), findsOneWidget);
  });

  testWidgets(
      'used product explains its history and never sends permanent deletion',
      (tester) async {
    final api = _CatalogApi()..used = true;
    await render(tester, ProductsView(service: ProductService(client: api)));
    await tester.tap(find.byTooltip(l10n.productDeleteButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.productDeleteBlockedTitle), findsOneWidget);
    expect(find.textContaining('Receitas de cestas'), findsOneWidget);
    expect(api.deletedPaths, isEmpty);
  });

  testWidgets('inactive product keeps edit and delete actions visible',
      (tester) async {
    final api = _CatalogApi()..isActive = false;
    await render(tester, ProductsView(service: ProductService(client: api)));
    expect(find.byTooltip(l10n.commonEdit), findsOneWidget);
    expect(find.byTooltip(l10n.productInactivateButton), findsNothing);
    expect(find.byTooltip(l10n.productDeleteButton), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('packaging explanation is readable in a narrow dialog',
      (tester) async {
    final api = _CatalogApi();
    await render(
        tester,
        PackagingsDialog(
            product: Product.fromJson(api.product),
            service: ProductService(client: api)),
        width: 360);
    expect(find.textContaining('Não é a embalagem vazia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'three active 5kg sacks at 25 reais add 15000g and total 75 reais',
      (tester) async {
    final api = _CatalogApi();
    await render(
        tester,
        PurchaseFormView(
            productService: ProductService(client: api),
            purchaseService: PurchaseService(client: api)));
    final quantity = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.labelText == l10n.purchaseQuantityPackages);
    final price = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.labelText == l10n.purchasePricePerPackage);
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '3');
    await tester.enterText(price, '25,00');
    await tester.pumpAndSettle();
    expect(
        find.text(l10n.purchaseFormConvertedStock(15000, 'G')), findsOneWidget);
    expect(
        find.text(
            l10n.purchaseFormTotalItem(AppFormatters.formatCurrency(7500))),
        findsOneWidget);
    expect(find.text('Saco antigo (1000 G)'), findsNothing);
    expect(find.textContaining('Cada "Saco de 5 kg"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
