import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/inventory_service.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/services/product_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/payable_form_view.dart';
import 'package:zm_cesta_basica_client/views/products_view.dart';
import 'package:zm_cesta_basica_client/views/financial_sources_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

class _FakeProductApi extends ApiClient {
  final products = [
    {
      'id': 'p1',
      'name': 'Arroz Branco 5kg',
      'category': 'ALIMENTACAO',
      'base_unit': 'G',
      'minimum_stock': 50000,
      'cost_price_cents': 2000,
      'sale_price_cents': 2800,
      'created_at': '2026-10-14T03:00:00Z',
      'updated_at': '2026-10-14T03:00:00Z',
      'is_active': true,
      'packagings': [],
    },
    {
      'id': 'p2',
      'name': 'Feijão Carioca 1kg',
      'category': 'ALIMENTACAO',
      'base_unit': 'G',
      'minimum_stock': 20000,
      'cost_price_cents': 700,
      'sale_price_cents': 950,
      'created_at': '2026-10-14T03:00:00Z',
      'updated_at': '2026-10-14T03:00:00Z',
      'is_active': true,
      'packagings': [],
    },
  ];

  final stockSummaries = [
    {
      'product_id': 'p1',
      'product_name': 'Arroz Branco 5kg',
      'category': 'ALIMENTACAO',
      'base_unit': 'G',
      'current_stock': 10000, // below minimum 50000
      'minimum_stock': 50000,
      'is_below_minimum': true,
      'cost_price_cents': 2000,
      'sale_price_cents': 2800,
    },
    {
      'product_id': 'p2',
      'product_name': 'Feijão Carioca 1kg',
      'category': 'ALIMENTACAO',
      'base_unit': 'G',
      'current_stock': 35000, // above minimum 20000
      'minimum_stock': 20000,
      'is_below_minimum': false,
      'cost_price_cents': 700,
      'sale_price_cents': 950,
    },
  ];

  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/v1/products')) return products;
    if (path.startsWith('/api/v1/inventory/summary')) return stockSummaries;
    throw StateError('Unexpected get: $path');
  }
}

class _FakePayableApi extends ApiClient {
  Map<String, dynamic>? lastCreatedBody;

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    if (path == '/api/v1/payables') {
      lastCreatedBody = body as Map<String, dynamic>;
      return [
        {
          'id': 'payable-123',
          'payable_number': 101,
          'description': body['description'],
          'beneficiary': body['beneficiary'],
          'category': body['category'],
          'nature': body['nature'],
          'original_amount_cents': body['original_amount_cents'],
          'balance_cents': body['original_amount_cents'],
          'paid_amount_cents': 0,
          'due_date': body['due_date'],
          'payment_method': body['payment_method'],
          'status': 'OPEN',
          'is_overdue': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'payments_count': 0,
          'payments': [],
          'payment_review_version': 0,
        }
      ];
    }
    throw StateError('Unexpected post: $path');
  }
}

class _FakeSourcesApi extends ApiClient {
  ApiOrigin origin = ApiOrigin(url: 'https://test.invalid', fingerprint: 'AA');
  @override
  Future<ApiOrigin> readOrigin() async => origin;
  @override
  ApiClient bindOrigin(ApiOrigin origin) => this;
  @override
  void close() {}

  final sources = [
    {
      'id': 'src-1',
      'name': 'Banco do Brasil Principal',
      'institution': 'Banco do Brasil',
      'source_type': 'BANK_ACCOUNT',
      'holder_type': 'PJ',
      'currency': 'BRL',
    },
  ];

  @override
  Future<dynamic> get(String path) async {
    if (path.contains('/financial-imports/sources')) return sources;
    if (path.contains('/treasury/accounts')) return [];
    throw StateError('Unexpected get: $path');
  }
}

void main() {
  setUpAll(AppFormatters.initialize);

  Widget testApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      theme: approvedAppTheme(Brightness.light),
      home: child,
    );
  }

  testWidgets(
      'ProductsView displays both products by default and filters to low stock with hero card',
      (tester) async {
    final api = _FakeProductApi();
    final productService = ProductService(client: api);
    final inventoryService = InventoryService(client: api);

    await tester.pumpWidget(
      testApp(
        ProductsView(
          service: productService,
          inventoryService: inventoryService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both products are visible initially
    expect(find.text('Arroz Branco 5kg'), findsOneWidget);
    expect(find.text('Feijão Carioca 1kg'), findsOneWidget);

    // Below minimum badge is visible for Arroz
    expect(find.text('ABAIXO DO MÍNIMO'), findsOneWidget);

    // Switch to Abaixo do mínimo filter
    await tester.tap(find.text('Abaixo do mínimo'));
    await tester.pumpAndSettle();

    // Hero card is visible
    expect(find.text('Atenção ao estoque'), findsOneWidget);
    expect(find.text('1 itens'), findsOneWidget);

    // Only Arroz is visible, Feijão is filtered out
    expect(find.text('Arroz Branco 5kg'), findsOneWidget);
    expect(find.text('Feijão Carioca 1kg'), findsNothing);

    // Adjust button is present on the product card
    expect(find.text('Ajustar'), findsOneWidget);
  });

  testWidgets(
      'ProductsView with initialLowStockOnly starts with hero card and low stock items',
      (tester) async {
    final api = _FakeProductApi();
    await tester.pumpWidget(
      testApp(
        ProductsView(
          service: ProductService(client: api),
          inventoryService: InventoryService(client: api),
          initialLowStockOnly: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atenção ao estoque'), findsOneWidget);
    expect(find.text('Arroz Branco 5kg'), findsOneWidget);
    expect(find.text('Feijão Carioca 1kg'), findsNothing);
  });

  testWidgets(
      'PayableFormDialog includes nature selector and saves PERSONAL_WITHDRAWAL properly',
      (tester) async {
    final api = _FakePayableApi();
    final service = PayableService(client: api);

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => PayableFormDialog(service: service),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify dialog title and fields
    expect(find.text('Nova conta a pagar'), findsOneWidget);
    expect(find.text('Natureza da obrigação'), findsOneWidget);
    expect(find.text('Operacional do negócio'), findsOneWidget);

    // Fill in required fields
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Descrição da despesa'),
        'Retirada pro-labore');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Favorecido / Fornecedor'),
        'Sócio Fundador');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor total'), '5000,00');

    // Change nature to PERSONAL_WITHDRAWAL
    await tester.ensureVisible(find.text('Operacional do negócio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operacional do negócio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirada de sócio / Particular').last);
    await tester.pumpAndSettle();

    // Click Salvar
    await tester.ensureVisible(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Dialog closed
    expect(find.text('Nova conta a pagar'), findsNothing);
    expect(api.lastCreatedBody?['nature'], 'PERSONAL_WITHDRAWAL');
  });

  testWidgets('FinancialSourcesView allows inspecting details on tap',
      (tester) async {
    final api = _FakeSourcesApi();

    await tester.pumpWidget(
      testApp(
        FinancialSourcesView(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Banco do Brasil Principal'), findsOneWidget);

    // Tap on row
    await tester.tap(find.text('Banco do Brasil Principal'));
    await tester.pumpAndSettle();

    // Detail dialog appears
    expect(find.text('Instituição emissora'), findsOneWidget);
    expect(find.text('Banco do Brasil'), findsOneWidget);
    expect(find.text('Pessoa jurídica'), findsOneWidget);
    expect(find.text('BRL'), findsOneWidget);

    // Close detail dialog
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Instituição emissora'), findsNothing);
  });
}
