import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_bill_review_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

class ReviewService extends FinancialImportService {
  int total = 10000;
  FinancialJson? saved;
  final operations = <String>[];
  List<FinancialJson> get items => [
    {
      'id': 'i1',
      'position': 1,
      'normalized_data': {
        'description': 'Compra a conferir',
        'transaction_date': '2026-10-01',
        'amount_cents': 10000,
      },
    },
  ];
  FinancialJson get statement => {
    'id': 's1',
    'statement_type': 'CARD_BILL',
    'due_on': '2026-10-20',
    'total_amount_cents': total,
  };
  @override
  Future<FinancialJson> get(String path) async => statement;
  @override
  Future<List<FinancialJson>> allRows(String path) async => items;
  @override
  Future<FinancialJson?> getSemanticReview(String id) async => saved;
  @override
  Future<List<FinancialJson>> getObligations(String id) async => [];
  @override
  Future<FinancialJson> saveSemanticReview(
    String id, {
    FinancialJson? context,
    required int expectedRevision,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    operations.add('save');
    saved = {
      'id': 'r${expectedRevision + 1}',
      'revision': expectedRevision + 1,
      'is_balanced': total == 10000,
      'status': total == 10000 ? 'APPROVED' : 'DRAFT',
      'items': items,
    };
    return saved!;
  }

  @override
  Future<List<FinancialJson>> generateObligations(
    String id, {
    FinancialJson? context,
    String? reviewId,
    String? notes,
  }) async {
    operations.add('generate');
    expect(reviewId, saved!['id']);
    return [];
  }
}

Future<void> mountReview(WidgetTester tester, ReviewService service) async {
  tester.view.physicalSize = const Size(1100, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      theme: approvedAppTheme(Brightness.light),
      home: FinancialBillReviewView(
        service: service,
        statementId: 's1',
        initialStatement: service.statement,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'classifications start unselected and cannot generate by description',
    (tester) async {
      final service = ReviewService();
      await mountReview(tester, service);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('generate-obligations-button')),
            )
            .onPressed,
        isNull,
      );
      expect(service.operations, isEmpty);
      final dropdown = find.byKey(const ValueKey('category-dropdown-i1'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      expect(find.text('Selecionar classificação'), findsWidgets);
    },
  );
  testWidgets(
    'edited classification is saved as new revision before generation',
    (tester) async {
      final service = ReviewService()
        ..saved = {
          'id': 'r1',
          'revision': 1,
          'is_balanced': true,
          'status': 'APPROVED',
          'items': [
            {'item_id': 'i1', 'semantic_category': 'PURCHASE_BUSINESS'},
          ],
        };
      await mountReview(tester, service);
      final dropdown = find.byKey(const ValueKey('category-dropdown-i1'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gasto Sócio (Retirada)').last);
      await tester.pumpAndSettle();
      final generate = find.byKey(
        const ValueKey('top-generate-obligations-btn'),
      );
      await tester.ensureVisible(generate);
      await tester.pumpAndSettle();
      await tester.tap(generate);
      await tester.pumpAndSettle();
      expect(service.operations, ['save', 'generate']);
      expect(service.saved!['revision'], 2);
      expect(
        service.saved!['items'][0]['semantic_category'],
        'PURCHASE_PERSONAL',
      );
    },
  );
  testWidgets('four cents remain unbalanced despite old approved review', (
    tester,
  ) async {
    final service = ReviewService()
      ..total = 10004
      ..saved = {
        'id': 'r1',
        'revision': 1,
        'is_balanced': true,
        'status': 'APPROVED',
        'items': [
          {'item_id': 'i1', 'semantic_category': 'PURCHASE_BUSINESS'},
        ],
      };
    await mountReview(tester, service);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('generate-obligations-button')),
          )
          .onPressed,
      isNull,
    );
    expect(service.operations, isEmpty);
  });
}
