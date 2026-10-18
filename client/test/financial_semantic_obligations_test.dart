import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_bill_review_view.dart';

class MockSemanticImportApi extends ApiClient {
  final gets = <String>[];
  final writes = <({String path, Object? body, String? key})>[];

  Map<String, dynamic>? currentReview;
  List<Map<String, dynamic>> currentObligations = [];

  final testStatement = {
    'id': 'st-nubank-2026',
    'statement_type': 'CARD_BILL',
    'due_on': '2026-03-24',
    'total_amount_cents': 271259, // R$ 2.712,59
  };

  final testItems = [
    {
      'id': 'item-1',
      'position': 1,
      'normalized_data': {
        'description': 'Saldo em atraso',
        'transaction_date': '2026-03-24',
        'amount_cents': 120391, // 1203.91
      },
    },
    {
      'id': 'item-2',
      'position': 2,
      'normalized_data': {
        'description': 'Juros de atraso',
        'transaction_date': '2026-03-24',
        'amount_cents': 50775, // 507.75
      },
    },
    {
      'id': 'item-3',
      'position': 3,
      'normalized_data': {
        'description': 'Limite convertido em saldo na sua conta do Nubank',
        'transaction_date': '2026-03-24',
        'amount_cents': 5464, // 54.64
      },
    },
    {
      'id': 'item-4',
      'position': 4,
      'normalized_data': {
        'description': 'Dmoveldesignmovel - Parcela 9/10',
        'transaction_date': '2026-03-17',
        'amount_cents': 40000, // 400.00
      },
    },
    {
      'id': 'item-5',
      'position': 5,
      'normalized_data': {
        'description': 'Picpay*Jardiel Wends - Parcela 3/10',
        'transaction_date': '2026-03-17',
        'amount_cents': 49538, // 495.38
      },
    },
    {
      'id': 'item-6',
      'position': 6,
      'normalized_data': {
        'description': 'Mercadopago *Baseusbr - Parcela 9/9',
        'transaction_date': '2026-03-17',
        'amount_cents': 5091, // 50.91
      },
    },
  ];

  @override
  Future<ApiOrigin> readOrigin() async =>
      ApiOrigin(url: 'https://test.local', fingerprint: 'AA');

  @override
  ApiClient bindOrigin(ApiOrigin origin) => this;

  @override
  void close() {}

  @override
  Future<dynamic> get(String path) async {
    gets.add(path);
    if (path.contains('/statements/st-nubank-2026/semantic-reviews/current')) {
      if (currentReview == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Review not found',
          errorCode: 'FINANCIAL_REVIEW_NOT_FOUND',
        );
      }
      return currentReview;
    }
    if (path.contains('/statements/st-nubank-2026/obligations')) {
      return currentObligations;
    }
    if (path.contains('/statements/st-nubank-2026/items')) {
      return testItems;
    }
    if (path.contains('/statements/st-nubank-2026')) {
      return testStatement;
    }
    return {};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    writes.add((path: path, body: body, key: idempotencyKey));
    if (path.contains('/semantic-reviews')) {
      final req = body as Map<String, dynamic>;
      final items = (req['items'] as List).cast<Map<String, dynamic>>();

      currentReview = {
        'id': 'rev-1',
        'statement_id': 'st-nubank-2026',
        'revision': ((req['expected_revision'] as int?) ?? 0) + 1,
        'declared_total_cents': 271259,
        'is_balanced': true,
        'status': 'APPROVED',
        'equation_difference_cents': 0,
        'items': items,
      };
      return currentReview!;
    }
    if (path.contains('/generate-obligations')) {
      currentObligations = [
        {
          'id': 'ob-1',
          'payable_number': 101,
          'description': 'Fatura Nubank: Dmoveldesignmovel - Parcela 9/10',
          'amount_cents': 40000,
          'nature': 'BUSINESS',
          'status': 'OPEN',
        },
        {
          'id': 'ob-2',
          'payable_number': 102,
          'description': 'Fatura Nubank (Retirada Socio): Picpay*Jardiel Wends',
          'amount_cents': 49538,
          'nature': 'PERSONAL_WITHDRAWAL',
          'status': 'OPEN',
        },
        {
          'id': 'ob-3',
          'payable_number': 103,
          'description': 'Fatura Nubank: Mercadopago *Baseusbr',
          'amount_cents': 5091,
          'nature': 'BUSINESS',
          'status': 'OPEN',
        },
        {
          'id': 'ob-4',
          'payable_number': 104,
          'description': 'Fatura Nubank (Encargos/Juros): Juros de atraso',
          'amount_cents': 50775,
          'nature': 'BUSINESS',
          'status': 'OPEN',
        },
        {
          'id': 'ob-5',
          'payable_number': 105,
          'description': 'Fatura Nubank (Encargos/Juros): Limite convertido em saldo',
          'amount_cents': 5464,
          'nature': 'BUSINESS',
          'status': 'OPEN',
        },
      ];
      return {'obligations': currentObligations};
    }
    return {};
  }
}

Widget buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('FinancialBillReviewView end-to-end review and obligations generation', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockApi = MockSemanticImportApi();
    final service = FinancialImportService(apiClient: mockApi);

    await tester.pumpWidget(
      buildTestApp(
        FinancialBillReviewView(
          service: service,
          statementId: 'st-nubank-2026',
        ),
      ),
    );

    // Initial loading
    await tester.pumpAndSettle();

    // Verify Statement details are displayed
    expect(find.text('Revisão Semântica da Fatura'), findsOneWidget);
    expect(find.textContaining('Fatura de Cartão de Crédito'), findsOneWidget);
    expect(find.textContaining('2.712,59'), findsWidgets);

    // Verify items are displayed
    expect(find.text('Saldo em atraso'), findsOneWidget);
    expect(find.text('Dmoveldesignmovel - Parcela 9/10'), findsOneWidget);
    expect(find.text('Picpay*Jardiel Wends - Parcela 3/10'), findsOneWidget);

    // Verify equation balance: 120391 + 50775 + 5464 + 40000 + 49538 + 5091 = 271259 = R$ 2.712,59!
    expect(find.textContaining('BALANCEADA (0 diff)'), findsOneWidget);

    // Save classification
    final saveButton = find.byKey(const ValueKey('save-semantic-review-button'));
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify review saved
    expect(mockApi.writes.any((w) => w.path.contains('/semantic-reviews')), isTrue);
    expect(find.textContaining('Revisão Atual: #1 (APPROVED)'), findsOneWidget);

    // Generate obligations
    final generateButton = find.byKey(const ValueKey('generate-obligations-button'));
    expect(generateButton, findsOneWidget);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    // Verify obligations generated
    expect(mockApi.writes.any((w) => w.path.contains('/generate-obligations')), isTrue);
    expect(find.textContaining('Obrigações Geradas em Contas a Pagar (5 títulos)'), findsOneWidget);
    expect(find.textContaining('#101 Fatura Nubank: Dmoveldesignmovel'), findsOneWidget);
    expect(find.textContaining('#102 Fatura Nubank (Retirada Socio): Picpay*Jardiel Wends'), findsOneWidget);
  });
}
