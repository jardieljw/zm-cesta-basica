import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/views/financial_bank_review_view.dart';
import 'financial_pdf_import_test.dart' as harness;

class MockTreasuryImportApi extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];

  bool posted = false, identityReviewed = false, reconciled = false;
  Map<String, dynamic> get occurrence => {
    'id': 'i1',
    'statement_id': 'st-123',
    'position': 1,
    'review_status': identityReviewed ? 'NEW' : 'PENDING',
    'transaction_id': identityReviewed ? 'tx1' : null,
    'normalized_data': {
      'transaction_date': '2026-10-01',
      'amount_cents': 5000,
      'description': 'Entrada de teste',
    },
  };

  final preview = {
    'id': 'prev-123',
    'document_id': 'doc-123',
    'source_id': 'src-123',
    'reader_id': 'pdf_auto',
    'status': 'READY',
    'result_sha256': 'hash123',
    'items_count': 2,
    'pages_count': 1,
    'extracted_header': {
      'statement_type': 'BANK_STATEMENT',
      'period_start': '2026-08-01',
      'period_end': '2026-08-31',
      'closing_balance_cents': 224000,
    },
    'checks': [],
  };

  final statementBefore = {
    'id': 'st-123',
    'preview_id': 'prev-123',
    'source_id': 'src-123',
    'statement_type': 'BANK_STATEMENT',
    'items_count': 2,
    'linked_count': 0,
    'pending_count': 2,
  };

  final statementAfter = {
    'id': 'st-123',
    'preview_id': 'prev-123',
    'source_id': 'src-123',
    'statement_type': 'BANK_STATEMENT',
    'items_count': 2,
    'linked_count': 2,
    'pending_count': 0,
  };

  final source = {
    'id': 'src-123',
    'name': 'Nubank PJ',
    'institution': 'Nubank',
    'holder_type': 'PJ',
    'currency': 'BRL',
    'source_type': 'BANK_ACCOUNT',
    'financial_account_id': 'acc-123',
  };

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
    if (path.contains('/statements/st-123/items')) return [occurrence];
    if (path.contains('/items/i1/candidates')) return [];
    if (path.contains('/items/i1')) return occurrence;
    if (path.contains('/treasury/entries')) {
      return [
        {
          'id': 'e1',
          'entry_type': 'CREDIT',
          'amount_cents': 5000,
          'description': 'Recebimento existente',
        },
      ];
    }
    if (path.contains('/transactions?')) {
      return [
        {'id': 'tx1', 'unreconciled_amount_cents': reconciled ? 0 : 5000},
      ];
    }
    if (path.contains('/previews/prev-123/items')) return [];
    if (path.contains('/previews/prev-123/errors')) return [];
    if (path.contains('/previews/prev-123/pages')) return [];
    if (path.contains('/previews/prev-123')) return preview;
    if (path.contains('/documents/doc-123')) {
      return {'id': 'doc-123', 'filename': 'extrato_nubank.pdf'};
    }
    if (path.contains('/sources')) return [source];
    if (path.contains('/statements/st-123')) {
      return posted ? statementAfter : statementBefore;
    }
    if (path.contains('/statements')) {
      return [posted ? statementAfter : statementBefore];
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
    posts.add(path);
    if (path.contains('/items/i1/review')) {
      identityReviewed = true;
      return {
        'item': occurrence,
        'transaction': {'id': 'tx1'},
      };
    }
    if (path.endsWith('/reconciliations')) {
      reconciled = true;
      return {
        'reconciliation': {'id': 'r1'},
        'affects_ledger': false,
      };
    }
    if (path.contains('/statements/st-123/post-to-treasury')) {
      posted = true;
      return {
        'statement_id': 'st-123',
        'account_id': 'acc-123',
        'entries_posted': 2,
        'total_credits_cents': 324000,
        'total_debits_cents': 100000,
        'new_balance_cents': 224000,
      };
    }
    return {};
  }
}

void main() {
  setUpAll(harness.loadImportFonts);
  testWidgets('bank occurrence review fits narrow screen and enlarged text', (
    tester,
  ) async {
    final api = MockTreasuryImportApi();
    await harness.mount(
      tester,
      FinancialBankReviewView(
        service: FinancialImportService(apiClient: api),
        statementId: 'st-123',
      ),
      size: const Size(320, 780),
      dark: true,
      scale: 1.7,
    );
    await harness.click(tester, find.text('Entrada de teste'));
    await harness.click(tester, find.byType(CheckboxListTile));
    expect(tester.takeException(), isNull);
    await harness.capture(tester, 'bank-occurrence-narrow-enlarged');
    expect(api.posts, isEmpty);
  });
  testWidgets('preview opens explicit bank review without posting money', (
    tester,
  ) async {
    final api = MockTreasuryImportApi();
    await harness.mount(
      tester,
      FinancialPdfPreviewView(
        service: FinancialImportService(apiClient: api),
        previewId: 'prev-123',
      ),
    );
    final action = find.byKey(const ValueKey('post-to-treasury-button'));
    await harness.click(tester, action);
    expect(find.text('Comparar com registros do aplicativo'), findsOneWidget);
    expect(api.posts, isEmpty);
    expect(find.text('Entrada de teste'), findsOneWidget);
  });
  testWidgets('operator reviews identity then reconciles existing money only', (
    tester,
  ) async {
    final api = MockTreasuryImportApi();
    await harness.mount(
      tester,
      FinancialBankReviewView(
        service: FinancialImportService(apiClient: api),
        statementId: 'st-123',
      ),
    );
    await harness.capture(tester, 'bank-review-safe');
    await harness.click(tester, find.text('Entrada de teste'));
    await tester.enterText(
      find.byType(TextField).first,
      'Conferido no extrato e no registro existente',
    );
    await harness.click(tester, find.byType(CheckboxListTile));
    await harness.click(tester, find.text('Guardar como movimento diferente'));
    expect(api.identityReviewed, isTrue);
    await harness.click(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.textContaining('Recebimento existente').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '50,00');
    await harness.capture(tester, 'bank-link-safe');
    await harness.click(tester, find.text('Vincular evidência ao movimento'));
    expect(api.reconciled, isTrue);
    expect(api.posts.any((p) => p.endsWith('/reconciliations')), isTrue);
    expect(
      api.posts.any(
        (p) =>
            p.contains('/post-to-treasury') || p.endsWith('/treasury/entries'),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
