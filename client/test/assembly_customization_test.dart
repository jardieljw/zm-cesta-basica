import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/basket_type.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/basket_assembly_form_view.dart';
import 'package:zm_cesta_basica_client/views/basket_assemblies_view.dart';
import 'basket_assemblies_test.dart' as fixtures;

Map<String, dynamic> customBasket() {
  final result = fixtures.basket();
  result['allows_customization'] = true;
  (result['active_recipe'] as Map)['items'] = [
    {
      'id': 'ingredient',
      'recipe_version_id': 'recipe',
      'product_id': 'rice',
      'product_name': 'Arroz',
      'product_base_unit': 'G',
      'quantity_in_base_units': 5000,
      'section': 'ALIMENTACAO'
    },
  ];
  return result;
}

class CustomApi extends fixtures.AssemblyApi {
  Map<String, dynamic>? reviewed;
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/v1/products')) {
      return [
        for (final (id, name, unit) in [
          ('rice', 'Arroz', 'G'),
          ('soap', 'Sabonete', 'UN')
        ])
          {
            'id': id,
            'name': name,
            'base_unit': unit,
            'category': 'LIMPEZA',
            'created_at': '2026-10-14T12:00:00Z',
            'updated_at': '2026-10-14T12:00:00Z'
          },
      ];
    }
    if (path == '/api/v1/basket-types/basket') return customBasket();
    if (path.startsWith('/api/v1/production/batches?')) {
      return {
        'items': [
          {
            ...fixtures.batch(),
            'is_custom': true,
            'custom_description': 'Dois sabonetes',
            'current_batch_stock': 3
          }
        ],
        'total_pages': 1
      };
    }
    return super.get(path);
  }

  @override
  Future<dynamic> post(String path,
      {dynamic body, String? idempotencyKey, bool isMutation = true}) async {
    if (path.endsWith('/preview')) {
      reviewed = Map<String, dynamic>.from(body as Map);
    }
    return super.post(path,
        body: body, idempotencyKey: idempotencyKey, isMutation: isMutation);
  }
}

void main() {
  setUpAll(AppFormatters.initialize);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> open(WidgetTester tester, Widget view) async {
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: view));
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 1200.0]) {
    testWidgets(
        'custom composition replaces recipe only for this assembly at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = CustomApi();
      final basket = BasketType.fromJson(customBasket());
      await open(
          tester, BasketAssemblyFormView(basketType: basket, apiClient: api));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final description = find.widgetWithText(
          TextFormField, 'Identificação da montagem personalizada');
      await tester.ensureVisible(description);
      await tester.enterText(description, 'Dois sabonetes');
      final product = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(product);
      await tester.tap(product);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabonete').last);
      await tester.pumpAndSettle();
      final quantity = find.byKey(const ValueKey('assembly-ingredient-0-soap'));
      expect(tester.widget<TextFormField>(quantity).initialValue, '');
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '2');
      await tester.tap(find.text('Revisar montagem'));
      await tester.pumpAndSettle();
      expect(api.reviewed!['is_custom'], isTrue);
      expect(
          (api.reviewed!['custom_items'] as List)
              .single['quantity_in_base_units'],
          2);
      expect(
          (api.reviewed!['custom_items'] as List).single['product_id'], 'soap');
      expect(basket.activeRecipe!.items.single.productId, 'rice');
      expect(api.creates, 0);
      await tester.tap(find.text('Confirmar montagem'));
      await tester.pumpAndSettle();
      expect(api.payload!['custom_items'], api.reviewed!['custom_items']);
      expect(api.payload!['custom_description'], 'Dois sabonetes');
      expect(
          api.payload!.containsKey('expected_recipe_version_number'), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'custom pending request restores exact composition and remains locked',
      (tester) async {
    final api = CustomApi()..loseResponse = true;
    final view = BasketAssemblyFormView(
        basketType: BasketType.fromJson(customBasket()), apiClient: api);
    await open(tester, view);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final description = find.widgetWithText(
        TextFormField, 'Identificação da montagem personalizada');
    await tester.ensureVisible(description);
    await tester.enterText(description, 'Arroz especial');
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar montagem'));
    await tester.pumpAndSettle();
    final original = api.payload;
    await tester.pumpWidget(const SizedBox());
    await open(tester, view);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull);
    await tester.tap(find.text('Retomar confirmação'));
    await tester.pumpAndSettle();
    expect(api.payload, original);
    expect(api.keys[0], api.keys[1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history separates custom lot stock from standard ready stock',
      (tester) async {
    await open(
        tester,
        BasketAssembliesView(
            basketType: BasketType.fromJson(customBasket()),
            apiClient: CustomApi()));
    expect(find.text('Dois sabonetes'), findsOneWidget);
    expect(find.text('Prontas desta montagem: 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'adding and removing items requires quantities and invalidates the review',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = CustomApi();
    await open(
        tester,
        BasketAssemblyFormView(
            basketType: BasketType.fromJson(customBasket()), apiClient: api));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final description = find.widgetWithText(
        TextFormField, 'Identificação da montagem personalizada');
    await tester.ensureVisible(description);
    await tester.enterText(description, 'Sem arroz');
    await tester.ensureVisible(find.text('Adicionar produto'));
    await tester.tap(find.text('Adicionar produto'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        'Sabonete');
    await tester.tap(find.widgetWithText(ListTile, 'Sabonete'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remover produto').first);
    await tester.tap(find.text('Remover produto').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    expect(api.reviewed, isNull);
    final quantity = find.byKey(const ValueKey('assembly-ingredient-0-soap'));
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '2');
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    expect((api.reviewed!['custom_items'] as List).length, 1);
    expect(find.text('Confirmar montagem'), findsOneWidget);
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '3');
    await tester.pumpAndSettle();
    expect(find.text('Revisar montagem'), findsOneWidget);
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    expect(
        (api.reviewed!['custom_items'] as List)
            .single['quantity_in_base_units'],
        3);
    expect(api.creates, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'customization disabled in the basket leaves standard assembly intact',
      (tester) async {
    await open(
        tester,
        BasketAssemblyFormView(
            basketType: BasketType.fromJson(fixtures.basket()),
            apiClient: fixtures.AssemblyApi()));
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar montagem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
