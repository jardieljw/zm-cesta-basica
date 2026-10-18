import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';

class MockTreasuryImportApi extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];

  bool posted = false;

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
    if (path.contains('/previews/prev-123/items')) return [];
    if (path.contains('/previews/prev-123/errors')) return [];
    if (path.contains('/previews/prev-123/pages')) return [];
    if (path.contains('/previews/prev-123')) return preview;
    if (path.contains('/documents/doc-123')) return {'id': 'doc-123', 'filename': 'extrato_nubank.pdf'};
    if (path.contains('/sources')) return [source];
    if (path.contains('/statements/st-123')) return posted ? statementAfter : statementBefore;
    if (path.contains('/statements')) return [posted ? statementAfter : statementBefore];
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
  testWidgets('FinancialPdfPreviewView renders Post to Treasury button and executes post flow', (tester) async {
    final mockApi = MockTreasuryImportApi();
    final service = FinancialImportService(apiClient: mockApi);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FinancialPdfPreviewView(
            service: service,
            previewId: 'prev-123',
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Verify "Lançar no Caixa / Tesouraria" button is visible
    final postButton = find.byKey(const ValueKey('post-to-treasury-button'));
    await tester.ensureVisible(postButton);
    await tester.pumpAndSettle();
    expect(postButton, findsOneWidget);
    expect(find.text('Lançar no Caixa / Tesouraria'), findsOneWidget);

    // Tap button to post
    await tester.tap(postButton);
    await tester.pumpAndSettle();

    // Verify post endpoint was called
    expect(mockApi.posts.any((p) => p.contains('/statements/st-123/post-to-treasury')), isTrue);

    // Verify snackbar feedback
    expect(find.textContaining('lançamentos lançados na Tesouraria'), findsOneWidget);

    final linkedText = find.textContaining('2 de 2 movimentações já registradas');
    expect(linkedText, findsOneWidget);
  });
}
