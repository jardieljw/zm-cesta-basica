import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/basket_type.dart';
import 'package:zm_cesta_basica_client/services/catalog_action_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/utils/api_error_mapper.dart';
import 'package:zm_cesta_basica_client/views/recipe_view.dart';
import 'package:zm_cesta_basica_client/views/basket_disassembly_view.dart';
import 'package:zm_cesta_basica_client/views/basket_assemblies_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/catalog_blockers.dart';
import 'package:zm_cesta_basica_client/views/sales_view.dart';
import 'package:zm_cesta_basica_client/views/sale_form_view.dart';
import 'package:zm_cesta_basica_client/views/receivable_payment_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';
import 'financial_pdf_import_test.dart' as harness;

final basket = {
  'id': 'basket',
  'code': 'P',
  'name': 'Cesta padrão',
  'default_price_cents': 15000,
};
Map<String, dynamic> recipe(int number, {String status = 'ACTIVE'}) => {
  'id': 'recipe-$number',
  'basket_type_id': 'basket',
  'version_number': number,
  'status': status,
  'created_at': '2026-10-20T10:00:00Z',
  'suggested_price_cents': 16000,
  'items': [
    {
      'id': 'item-$number',
      'recipe_version_id': 'recipe-$number',
      'product_id': 'rice',
      'product_name': 'Arroz',
      'product_base_unit': 'UNIT',
      'quantity_in_base_units': 1,
      'section': 'ALIMENTACAO',
      'is_required': true,
    },
  ],
};
final batch = {
  'id': 'batch',
  'basket_type_id': 'basket',
  'batch_number': 7,
  'quantity_produced': 2,
  'current_batch_stock': 2,
  'status': 'CONFIRMED',
  'is_custom': false,
  'is_direct_sale': false,
  'occurred_at': '2026-10-20T10:00:00Z',
  'total_cost_cents': 2000,
  'items': [
    {
      'product_name': 'Arroz',
      'product_base_unit': 'UNIT',
      'quantity_consumed_base_units': 2,
    },
  ],
};

class CatalogApi extends ApiClient {
  bool blocked = false,
      loseResponse = false,
      rejectRecipe = false,
      inactiveRice = false;
  final requests = <String>[];
  final keys = <String?>[];
  final payloads = <dynamic>[];
  List<Map<String, dynamic>> versions = [
    recipe(2),
    recipe(1, status: 'ARCHIVED'),
  ];
  @override
  Future<dynamic> get(String path) async {
    requests.add(path);
    if (path.endsWith('/deletion-check')) {
      return {
        'can_modify': !blocked,
        'blockers': [
          {
            'kind': 'ACTIVE_SALES',
            'id': 'sale',
            'label': 'Venda nº 3 · Maria',
            'target': {'sale_id': 'sale'},
          },
        ],
      };
    }
    if (path.endsWith('/recipes')) return versions;
    if (path.startsWith('/api/v1/basket-types?')) {
      return [
        {...basket, 'active_recipe': recipe(2)},
      ];
    }
    if (path.startsWith('/api/v1/customers')) return [];
    if (path == '/api/v1/products?is_active=true' ||
        path == '/api/v1/products') {
      return [
        {
          'id': 'rice',
          'name': 'Arroz',
          'category': 'ALIMENTACAO',
          'base_unit': 'UNIT',
          'is_active': !inactiveRice,
          'created_at': '2026-10-20T10:00:00Z',
          'updated_at': '2026-10-20T10:00:00Z',
        },
      ];
    }
    if (path == '/api/v1/basket-types/basket') return basket;
    if (path == '/api/v1/production/batches/batch') return batch;
    if (path.contains('/stock')) return {'current_stock': 2};
    if (path == '/api/v1/sales/sale') {
      return {
        'id': 'sale',
        'sale_number': 3,
        'customer_name': 'Maria',
        'status': 'CONFIRMED',
        'sale_date': '2026-10-20T10:00:00Z',
        'total_amount_cents': 15000,
        'items': [],
      };
    }
    throw StateError(path);
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    requests.add(path);
    if (path.endsWith('/disassembly-preview')) {
      return {
        'quantity': 2,
        'items': [
          {
            'product_name': 'Arroz',
            'product_base_unit': 'UNIT',
            'quantity_returned_base_units': 2,
          },
        ],
      };
    }
    keys.add(idempotencyKey);
    payloads.add(body);
    if (loseResponse) {
      loseResponse = false;
      throw ApiException(statusCode: 0, message: 'Resposta perdida');
    }
    if (path.endsWith('/recipes')) {
      versions = [recipe(3), ...versions];
      return versions.first;
    }
    if (path == '/api/v1/sales') {
      return {
        'id': 'sale',
        'sale_number': 3,
        'status': 'CONFIRMED',
        'sale_date': '2026-10-20T10:00:00Z',
        'total_amount_cents': 15000,
        'items': [],
      };
    }
    return {'batch_id': 'batch', 'quantity_disassembled': 2};
  }

  @override
  Future<dynamic> delete(
    String path, {
    bool isMutation = true,
    String? idempotencyKey,
  }) async {
    requests.add(path);
    versions.removeWhere((r) => r['version_number'] == 1);
    return {'deleted': true};
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    requests.add(path);
    keys.add(idempotencyKey);
    payloads.add(body);
    if (loseResponse) {
      loseResponse = false;
      throw ApiException(statusCode: 0, message: 'Resposta perdida');
    }
    if (rejectRecipe) {
      rejectRecipe = false;
      throw ApiException(statusCode: 409, message: 'Confira os dados');
    }
    return {...recipe(1), ...Map<String, dynamic>.from(body as Map)};
  }
}

class ReceiptApi extends CatalogApi {
  @override
  Future<ApiOrigin> readOrigin() async =>
      ApiOrigin(url: 'https://test.invalid:8000', fingerprint: 'TEST');
  @override
  ApiClient bindOrigin(ApiOrigin origin) => this;
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/v1/sales?')) {
      return [
        {
          ...Map<String, dynamic>.from(
            await super.get('/api/v1/sales/sale') as Map,
          ),
          'receivable_id': 'title-correct',
          'receivable_status': 'PAID',
          'receivable_balance_cents': 0,
        },
      ];
    }
    if (path == '/api/v1/receivables/title-correct') {
      requests.add(path);
      return {
        'id': 'title-correct',
        'sale_id': 'sale',
        'sale_number': 3,
        'customer_id': 'customer',
        'customer_name': 'Maria',
        'due_date': '2026-10-20',
        'original_amount_cents': 15000,
        'paid_amount_cents': 15000,
        'balance_cents': 0,
        'status': 'PAID',
        'payments': [],
      };
    }
    return super.get(path);
  }
}

Widget app(Widget page) => MaterialApp(
  theme: approvedAppTheme(Brightness.light),
  builder: (_, child) =>
      RepaintBoundary(key: const ValueKey('pdf-capture'), child: child!),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('pt', 'BR'),
  home: page,
);

void main() {
  testWidgets('catalog conflict keeps the concrete explanation instead of a generic conflict', (tester) async {
    await tester.pumpWidget(app(const SizedBox(key: ValueKey('error-context'))));
    final l = AppLocalizations.of(tester.element(find.byKey(const ValueKey('error-context'))))!;
    const message = 'É possível confirmar somente 0 cestas desta receita. Confira a venda nº 3.';
    expect(ApiErrorMapper.toLocalizedMessage(ApiException(statusCode: 409,
        errorCode: 'ASSEMBLY_RECIPE_STOCK_UNCERTAIN', message: message), l), message);
  });
  setUpAll(() async {
    await AppFormatters.initialize();
    await harness.loadImportFonts();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1200.0]) {
    testWidgets('recipe target, price and editor are usable at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = CatalogApi();
      await tester.pumpWidget(
        app(
          RecipeView(
            basketType: BasketType.fromJson(basket),
            apiClient: api,
            initialVersionNumber: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('160,00'), findsOneWidget);
      await tester.ensureVisible(find.text('Editar receita'));
      await tester.tap(find.text('Editar receita'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Preço sugerido (R\$)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await harness.capture(tester, 'catalog-receita-editor-${width.toInt()}');
    });
    testWidgets('disassembly reviews quantities before confirming at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = CatalogApi();
      await tester.pumpWidget(
        app(BasketDisassemblyView(batch: batch, apiClient: api)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Desfazer montagem');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Revisar desmontagem'));
      await tester.tap(find.text('Revisar desmontagem'));
      await tester.pumpAndSettle();
      expect(api.keys, isEmpty);
      expect(find.text('Produtos que voltarão ao estoque'), findsOneWidget);
      expect(api.requests.last, endsWith('/disassembly-preview'));
      expect(tester.takeException(), isNull);
      await harness.capture(tester, 'catalog-desmontagem-${width.toInt()}');
    });
  }
  testWidgets('lost disassembly resumes same payload/key after reopening', (
    tester,
  ) async {
    final api = CatalogApi()..loseResponse = true;
    final service = CatalogActionService(client: api);
    final payload = {
      'quantity_to_disassemble': 2,
      'reason': 'Desfazer montagem',
    };
    await expectLater(
      service.run(
        'disassemble_batch',
        '/api/v1/production/batches/batch/disassemble',
        'POST',
        payload,
      ),
      throwsA(isA<ApiException>()),
    );
    await tester.pumpWidget(
      app(BasketDisassemblyView(batch: batch, apiClient: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retomar confirmação pendente'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );
    await tester.ensureVisible(find.text('Retomar confirmação pendente'));
    await tester.tap(find.text('Retomar confirmação pendente'));
    await tester.pumpAndSettle();
    expect(api.keys.length, 2);
    expect(api.keys[1], api.keys[0]);
    expect(api.payloads[1], api.payloads[0]);
    expect(await service.pending('disassemble_batch'), isNull);
  });
  testWidgets('dependency opens exact assembly instead of an unfiltered list', (
    tester,
  ) async {
    final api = CatalogApi();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: CatalogBlockers(
            apiClient: api,
            blockers: const [
              {
                'kind': 'PRODUCTION',
                'id': 'batch',
                'label': 'Montagem nº 7',
                'target': {'basket_id': 'basket', 'batch_id': 'batch'},
              },
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Montagem nº 7'));
    await tester.pumpAndSettle();
    expect(find.byType(BasketAssembliesView), findsOneWidget);
    expect(api.requests, contains('/api/v1/production/batches/batch'));
    expect(find.text('Desmontar cestas'), findsOneWidget);
  });
  testWidgets('protected recipe identifies sale and opens only that sale', (
    tester,
  ) async {
    final api = CatalogApi()..blocked = true;
    await tester.pumpWidget(
      app(
        RecipeView(
          basketType: BasketType.fromJson(basket),
          apiClient: api,
          initialVersionNumber: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Excluir receita'));
    await tester.tap(find.text('Excluir receita'));
    await tester.pumpAndSettle();
    expect(find.text('Venda nº 3 · Maria'), findsOneWidget);
    await tester.tap(find.text('Venda nº 3 · Maria'));
    await tester.pumpAndSettle();
    expect(find.byType(SalesView), findsOneWidget);
    expect(api.requests, contains('/api/v1/sales/sale'));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'same basket uses recipe price and accepts a negotiated sale price',
    (tester) async {
      final api = CatalogApi();
      await tester.pumpWidget(app(SaleFormView(apiClient: api)));
      await tester.pumpAndSettle();
      final price = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == '160,00',
      );
      expect(price, findsOneWidget);
      await tester.ensureVisible(price);
      await tester.enterText(price, '175,00');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Confirmar'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(api.payloads.last['items'][0]['basket_type_id'], 'basket');
      expect(api.payloads.last['items'][0]['unit_price_cents'], 17500);
      expect(api.requests.where((p) => p == '/api/v1/basket-types'), isEmpty);
    },
  );
  testWidgets(
    'cancellation opens exact received title without reversing automatically',
    (tester) async {
      final api = ReceiptApi();
      await tester.pumpWidget(app(SalesView(apiClient: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar Venda'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar a venda nº 3?'), findsOneWidget);
      await tester.tap(find.text('Ver recebimentos desta venda'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceivablePaymentView), findsOneWidget);
      expect(api.requests, contains('/api/v1/receivables/title-correct'));
      expect(api.payloads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inactive ingredient is visible and cannot silently disappear on edit',
    (tester) async {
      final api = CatalogApi()..inactiveRice = true;
      await tester.pumpWidget(
        app(
          RecipeView(basketType: BasketType.fromJson(basket), apiClient: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Editar receita'));
      await tester.tap(find.text('Editar receita'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Produto inativo'), findsWidgets);
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nenhum ingrediente foi removido automaticamente'),
        findsOneWidget,
      );
      expect(api.payloads, isEmpty);
      expect(find.byType(Dialog), findsOneWidget);
    },
  );

  testWidgets('invalid price explains correction and keeps the editor open', (
    tester,
  ) async {
    final api = CatalogApi();
    await tester.pumpWidget(
      app(RecipeView(basketType: BasketType.fromJson(basket), apiClient: api)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar receita'));
    await tester.tap(find.text('Editar receita'));
    await tester.pumpAndSettle();
    final price = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '160,00',
    );
    await tester.enterText(price, '-1');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe um preço válido, igual ou maior que zero.'),
      findsOneWidget,
    );
    expect(api.payloads, isEmpty);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets(
    'rejected retry restores notes price ingredients and original recipe target',
    (tester) async {
      final api = CatalogApi()..loseResponse = true;
      final actions = CatalogActionService(client: api);
      final payload = {
        'notes': 'Manter meus dados',
        'suggested_price_cents': 17350,
        'items': [
          {
            'product_id': 'rice',
            'quantity_in_base_units': 2,
            'section': 'ALIMENTACAO',
            'is_required': true,
          },
        ],
      };
      await expectLater(
        actions.run(
          'recipe_basket',
          '/api/v1/basket-types/basket/recipes/1',
          'PUT',
          payload,
        ),
        throwsA(isA<ApiException>()),
      );
      api.rejectRecipe = true;
      await tester.pumpWidget(
        app(
          RecipeView(basketType: BasketType.fromJson(basket), apiClient: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retomar confirmação pendente'));
      await tester.pumpAndSettle();
      expect(await actions.pending('recipe_basket'), isNull);
      expect(await actions.rejectedDraft('recipe_basket'), isNotNull);
      await tester.tap(find.text('Rever dados da receita'));
      await tester.pumpAndSettle();
      expect(find.text('Manter meus dados'), findsOneWidget);
      expect(find.text('173,50'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(api.requests.where((p) => p.endsWith('/recipes/1')).length, 3);
      expect(api.payloads.last, payload);
      expect(await actions.rejectedDraft('recipe_basket'), isNull);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
