import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/views/basket_types_view.dart';
import 'basket_assemblies_test.dart' as fixtures;

class CatalogApi extends fixtures.AssemblyApi {
  bool exists = true, active = true, blocked = false;
  String mode = 'PERMANENT';
  final deletions = <String>[];

  @override
  Future<dynamic> get(String path) async {
    if (path.endsWith('/deletion-check')) {
      return {
        'can_delete': !blocked,
        'deletion_mode': mode,
        'reasons': blocked ? ['STOCK_REMAINS'] : []
      };
    }
    if (path.startsWith('/api/v1/basket-types')) {
      return exists
          ? [
              {...fixtures.basket(), 'is_active': active}
            ]
          : [];
    }
    return super.get(path);
  }

  @override
  Future<dynamic> delete(String path, {bool isMutation = true}) async {
    deletions.add(path);
    if (path.endsWith('/catalog')) {
      exists = false;
      return {'deleted': true, 'deletion_mode': mode};
    }
    active = false;
    return {};
  }
}

void main() {
  Future<void> open(WidgetTester tester, CatalogApi api) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: BasketTypesView(apiClient: api)));
    await tester.pumpAndSettle();
  }

  for (final mode in ['PERMANENT', 'CATALOG_ONLY']) {
    testWidgets('basket deletion confirms correct history policy for $mode',
        (tester) async {
      final api = CatalogApi()..mode = mode;
      await open(tester, api);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Excluir cesta'));
      await tester.tap(find.byTooltip('Excluir cesta'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(mode == 'PERMANENT'
              ? 'receitas nunca utilizadas'
              : 'Essa ação não apaga o histórico'),
          findsOneWidget);
      expect(api.deletions, isEmpty);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir cesta'));
      await tester.pumpAndSettle();
      expect(api.deletions, ['/api/v1/basket-types/basket/catalog']);
      expect(find.text('Cesta Básica'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancel and stock blocker send no deletion request',
      (tester) async {
    final api = CatalogApi();
    await open(tester, api);
    await tester.ensureVisible(find.byTooltip('Excluir cesta'));
    await tester.tap(find.byTooltip('Excluir cesta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.deletions, isEmpty);
    api.blocked = true;
    await tester.tap(find.byTooltip('Excluir cesta'));
    await tester.pumpAndSettle();
    expect(find.text('Cesta ainda em uso'), findsOneWidget);
    expect(find.textContaining('Ainda há cestas em estoque'), findsOneWidget);
    expect(api.deletions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inactivation keeps its old endpoint distinct from deletion',
      (tester) async {
    final api = CatalogApi();
    await open(tester, api);
    await tester.ensureVisible(find.byIcon(Icons.visibility_off_outlined));
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Inativar'));
    await tester.pumpAndSettle();
    expect(api.deletions, ['/api/v1/basket-types/basket']);
    expect(find.text('Cesta Básica'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
