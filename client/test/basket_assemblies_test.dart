import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/basket_type.dart';
import 'package:zm_cesta_basica_client/services/basket_assembly_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/basket_assemblies_view.dart';
import 'package:zm_cesta_basica_client/views/basket_types_view.dart';

Map<String, dynamic> basket({bool stock = true}) => {
      'id': 'basket',
      'code': '01',
      'name': 'Cesta Básica',
      'tracks_finished_stock': stock,
      'active_recipe': {
        'id': 'recipe',
        'basket_type_id': 'basket',
        'version_number': 1,
        'status': 'ACTIVE',
        'created_at': '2026-10-14T12:00:00Z',
        'items': []
      },
    };

Map<String, dynamic> batch({bool sale = false}) => {
      'id': sale ? 'sale-batch' : 'batch',
      'basket_type_id': 'basket',
      'batch_number': sale ? 2 : 1,
      'quantity_produced': sale ? 2 : 5,
      'status': 'CONFIRMED',
      'is_custom': false,
      'is_direct_sale': sale,
      'occurred_at': '2026-10-14T12:30:00Z',
      'total_cost_cents': 700,
      'items': [],
    };

class AssemblyApi extends ApiClient {
  bool stockEnabled = true, enough = true, loseResponse = false;
  int creates = 0;
  final keys = <String?>[];
  Map<String, dynamic>? payload;
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/v1/basket-types/basket') {
      return basket(stock: stockEnabled);
    }
    if (path.startsWith('/api/v1/basket-types')) {
      return [basket(stock: stockEnabled)];
    }
    if (path.startsWith('/api/v1/production/batches?')) {
      expect(Uri.parse(path).queryParameters['basket_type_id'], 'basket');
      return {
        'items': [batch(), batch(sale: true)],
        'total_pages': 1
      };
    }
    if (path.contains('/stock')) return {'current_stock': 5};
    throw StateError(path);
  }

  @override
  Future<dynamic> post(String path,
      {dynamic body, String? idempotencyKey, bool isMutation = true}) async {
    if (path == '/api/v1/production/preview') {
      expect(isMutation, isFalse);
      return {
        'can_produce': enough,
        'recipe_version_number': 1,
        'estimated_total_cost_cents': 700,
        'items': [
          {
            'product_name': 'Arroz',
            'product_base_unit': 'G',
            'quantity_required': 5000,
            'current_stock': enough ? 10000 : 0,
            'is_sufficient': enough,
            'missing_quantity': enough ? 0 : 5000
          }
        ]
      };
    }
    expect(path, '/api/v1/production/batches');
    creates++;
    keys.add(idempotencyKey);
    payload = Map<String, dynamic>.from(body as Map);
    if (loseResponse) {
      loseResponse = false;
      throw ApiException(statusCode: 0, message: 'Response lost');
    }
    return batch();
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

  for (final size in [const Size(420, 860), const Size(1200, 800)]) {
    testWidgets('review and confirm assembly at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = AssemblyApi();
      await open(
          tester,
          BasketAssembliesView(
              basketType: BasketType.fromJson(basket()), apiClient: api));
      expect(find.text('Montagem antecipada'), findsOneWidget);
      expect(find.text('Montada na venda'), findsOneWidget);
      await tester.tap(find.text('Registrar montagem'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantidade'), '5');
      await tester.tap(find.text('Revisar montagem'));
      await tester.pumpAndSettle();
      expect(api.creates, 0);
      expect(find.text('Produtos a consumir'), findsOneWidget);
      await tester.tap(find.text('Confirmar montagem'));
      await tester.pumpAndSettle();
      expect(api.creates, 1);
      expect(api.payload!['quantity_produced'], 5);
      expect(api.payload!['is_direct_sale'], isFalse);
      expect(api.payload!['expected_recipe_version_number'], 1);
      expect(
          DateTime.parse(api.payload!['occurred_at'] as String).isUtc, isTrue);
      expect(find.text('Montagem registrada e estoque atualizado.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('basket card opens its history', (tester) async {
    final api = AssemblyApi();
    await open(tester, BasketTypesView(apiClient: api));
    await tester.tap(find.text('Montagens'));
    await tester.pumpAndSettle();
    expect(find.text('Montagens — Cesta Básica'), findsOneWidget);
  });
  testWidgets('insufficient products cannot confirm', (tester) async {
    final api = AssemblyApi()..enough = false;
    await open(
        tester,
        BasketAssembliesView(
            basketType: BasketType.fromJson(basket()), apiClient: api));
    await tester.tap(find.text('Registrar montagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull);
    expect(api.creates, 0);
  });
  testWidgets('history remains available without ready stock', (tester) async {
    final api = AssemblyApi()..stockEnabled = false;
    await open(
        tester,
        BasketAssembliesView(
            basketType: BasketType.fromJson(basket(stock: false)),
            apiClient: api));
    expect(find.text('Montada na venda'), findsOneWidget);
    expect(find.text('Registrar montagem'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
  testWidgets('pending confirmation survives leaving and reopening form',
      (tester) async {
    final api = AssemblyApi()..loseResponse = true;
    await open(
        tester,
        BasketAssembliesView(
            basketType: BasketType.fromJson(basket()), apiClient: api));
    await tester.tap(find.text('Registrar montagem'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade'), '5');
    await tester.tap(find.text('Revisar montagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar montagem'));
    await tester.pumpAndSettle();
    expect(api.creates, 1);
    expect(find.text('Retomar confirmação'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retomar confirmação'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Quantidade'));
    expect(field.controller!.text, '5');
    expect(field.enabled, isFalse);
    await tester.tap(find.text('Retomar confirmação'));
    await tester.pumpAndSettle();
    expect(api.keys[0], api.keys[1]);
    expect(api.payload!['quantity_produced'], 5);
    expect(
        find.text('Montagem registrada e estoque atualizado.'), findsOneWidget);
  });

  test('lost response retains identity across service recreation', () async {
    final api = AssemblyApi()..loseResponse = true;
    final payload = {
      'basket_type_id': 'basket',
      'quantity_produced': 5,
      'occurred_at': '2026-10-14T12:30:00Z',
      'is_custom': false
    };
    await expectLater(BasketAssemblyService(client: api).create(payload),
        throwsA(isA<ApiException>()));
    final service = BasketAssemblyService(client: api);
    expect(await service.pending('basket'), isNotNull);
    await service.create(payload);
    expect(api.keys[0], api.keys[1]);
    expect(await service.pending('basket'), isNull);
  });
}
