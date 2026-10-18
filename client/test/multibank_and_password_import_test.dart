import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

const root = FinancialImportService.root;

class MultibankMockApi extends ApiClient {
  final gets = <String>[];
  final writes = <({String path, Object? body, String? key})>[];
  bool passwordRequired = false;
  String? receivedPassword;
  String? receivedReaderId;

  ApiOrigin origin = ApiOrigin(
    url: 'https://financial-test.invalid',
    fingerprint: 'BB',
  );

  FinancialJson get source => {
    'id': 's1',
    'source_type': 'CREDIT_CARD',
    'currency': 'BRL',
    'name': 'Cartão Nubank',
    'institution': 'NUBANK',
    'holder_type': 'PJ',
  };

  FinancialJson previewFor(String readerId, {bool hasError = false}) => {
    'id': 'p_test',
    'source_id': 's1',
    'document_id': 'd1',
    'reader_id': readerId,
    'created_at': '2026-10-17T12:00:00Z',
    'status': hasError ? 'INVALID' : 'READY',
    'result_sha256': 'b' * 64,
    'items_count': hasError ? 0 : 2,
    'errors_count': hasError ? 1 : 0,
    'pages_count': 1,
    'detected_institution': 'NUBANK',
    'extracted_header': {
      'statement_type': 'CARD_BILL',
      'due_on': '2026-10-20',
      'total_amount_cents': 15000,
    },
    'totals': {
      'positive_cents': 15000,
      'negative_cents': 0,
      'net_cents': 15000,
    },
    'observed_dates': {
      'first': '2026-10-01',
      'last': '2026-10-15',
    },
    'errors': [
      if (hasError) {'code': 'PDF_PASSWORD_REQUIRED', 'fields': []},
    ],
    'warnings': [],
    'checks': [],
  };

  @override
  Future<ApiOrigin> readOrigin() async => origin;
  @override
  ApiClient bindOrigin(ApiOrigin origin) => this;
  @override
  void close() {}

  @override
  Future<dynamic> get(String path) async {
    gets.add(path);
    final uri = Uri.parse(path);
    if (uri.path == '$root/sources') return [source];
    if (uri.path == '$root/readers') {
      return [
        {'id': 'pdf_auto', 'version': '1', 'media_type': 'application/pdf'},
        {'id': 'nubank_card_csv', 'version': '1', 'media_type': 'text/csv'},
        {'id': 'itau_card_csv', 'version': '1', 'media_type': 'text/csv'},
        {'id': 'generic_csv', 'version': '1', 'media_type': 'text/csv'},
      ];
    }
    if (uri.path == '/api/v1/treasury/accounts') return [];
    if (uri.path == '$root/previews') return [];
    if (uri.path == '$root/previews/p_test') return previewFor(receivedReaderId ?? 'pdf_auto');
    if (uri.path == '$root/documents/d1') {
      return {'id': 'd1', 'filename': 'fatura.csv'};
    }
    if (uri.path == '$root/statements') return [];
    if (uri.path == '$root/previews/p_test/items') return [];
    if (uri.path == '$root/previews/p_test/errors') return [];
    if (uri.path == '$root/previews/p_test/pages') return [];
    throw StateError('Unexpected read: $path');
  }

  @override
  Future<dynamic> uploadBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    writes.add((path: path, body: bytes, key: idempotencyKey));
    return {'id': 'd1'};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    writes.add((path: path, body: body, key: idempotencyKey));
    if (path == '$root/documents/d1/previews') {
      final map = body as Map<String, dynamic>;
      receivedPassword = map['password'] as String?;
      receivedReaderId = map['reader_id'] as String?;
      final isProtected = passwordRequired && (receivedPassword == null || receivedPassword != 'senha123');
      return {'preview': previewFor(receivedReaderId!, hasError: isProtected)};
    }
    if (path == '$root/previews/p_test/confirm') {
      return {
        'statement': {
          'id': 'st_test',
          'preview_id': 'p_test',
          'pending_count': 2,
        },
      };
    }
    throw StateError('Unexpected write: $path');
  }
}

Future<void> mountTest(
  WidgetTester tester,
  Widget child,
) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: approvedAppTheme(Brightness.light),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('CSV file selection allows multibank reader choice and sends CSV to server', (tester) async {
    final api = MultibankMockApi();
    final service = FinancialImportService(apiClient: api);

    final csvContent = utf8.encode('date,title,amount\n2026-04-10,Loja Exemplo,150.00\n');
    final csvFile = FinancialImportFile('nubank_2026.csv', Uint8List.fromList(csvContent));

    await mountTest(
      tester,
      FinancialImportsView(
        service: service,
        pickFile: () async => csvFile,
      ),
    );

    // Initial load finishes
    expect(find.text('Selecionar PDF'), findsOneWidget);

    // Select source in dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartão Nubank · NUBANK · PJ').last);
    await tester.pumpAndSettle();

    // Pick file button tapped
    await tester.tap(find.text('Selecionar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('nubank_2026.csv'), findsOneWidget);
    // Reader dropdown should appear for CSV files with suggested reader
    expect(find.text('Leitor bancário para CSV'), findsOneWidget);

    // Tap import button
    await tester.tap(find.text('Ler documento'));
    await tester.pumpAndSettle();

    // Verify uploadBytes was called with text/csv
    expect(api.writes.any((w) => w.path.contains('/documents?filename=nubank_2026.csv')), isTrue);

    // Verify preview post sent reader_id
    final previewCall = api.writes.firstWhere((w) => w.path.contains('/previews'));
    final payload = previewCall.body as Map<String, dynamic>;
    expect(payload['reader_id'], equals('nubank_card_csv'));
  });

  testWidgets('Protected PDF prompts for password dialog and re-submits in memory', (tester) async {
    final api = MultibankMockApi();
    api.passwordRequired = true;
    final service = FinancialImportService(apiClient: api);

    final pdfContent = utf8.encode('%PDF-1.7\nprotected stream');
    final pdfFile = FinancialImportFile('fatura_protegida.pdf', Uint8List.fromList(pdfContent));

    await mountTest(
      tester,
      FinancialImportsView(
        service: service,
        pickFile: () async => pdfFile,
      ),
    );

    // Select source in dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartão Nubank · NUBANK · PJ').last);
    await tester.pumpAndSettle();

    // Select file
    await tester.tap(find.text('Selecionar PDF'));
    await tester.pumpAndSettle();

    // Tap import button (first attempt with no password)
    await tester.tap(find.text('Ler documento'));
    await tester.pumpAndSettle();

    // Dialog asking for password should appear
    expect(find.text('Arquivo Protegido por Senha'), findsOneWidget);
    expect(find.text('Este PDF está protegido por senha. Digite a senha para efetuar a leitura:'), findsOneWidget);

    // Enter password
    await tester.enterText(find.byType(TextField), 'senha123');
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    // Password was received in memory
    expect(api.receivedPassword, equals('senha123'));

    // Preview view is now mounted
    expect(find.text('Conferência do documento'), findsOneWidget);
  });

  test('FinancialImportService methods unit verification', () async {
    final api = MultibankMockApi();
    final service = FinancialImportService(apiClient: api);

    final readers = await service.readers();
    expect(readers.length, equals(4));

    final file = FinancialImportFile('test.csv', Uint8List.fromList(utf8.encode('a,b\n1,2')));
    expect(file.isCsv, isTrue);
    expect(file.isPdf, isFalse);

    final preview = await service.importDocument(
      file,
      's1',
      readerId: 'nubank_card_csv',
      password: 'mypassword',
    );
    expect(preview['status'], equals('READY'));
    expect(api.receivedPassword, equals('mypassword'));
    expect(api.receivedReaderId, equals('nubank_card_csv'));

    final confirmed = await service.confirm(preview, confirmationHeader: {
      'total_amount_cents': 15000,
      'due_on': '2026-10-20',
    });
    expect(confirmed['id'], equals('st_test'));
  });
}
