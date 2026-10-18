import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/utils/api_error_mapper.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

const root = FinancialImportService.root;
FinancialPdfFile sampleFile() => FinancialPdfFile(
  'Fatura teste #1.pdf',
  Uint8List.fromList('%PDF-1.7\nsynthetic'.codeUnits),
);

class ImportApi extends ApiClient {
  final gets = <String>[];
  final writes = <({String path, Object? body, String? key})>[];
  bool invalid = false,
      confirmed = false,
      failConfirmOnce = false,
      failSourceOnce = false;
  String? loadError;
  int itemCount = 1, errorCount = 1;
  Completer<void>? uploadGate;
  ApiOrigin origin = ApiOrigin(
    url: 'https://financial-test.invalid',
    fingerprint: 'AA',
  );
  FinancialJson get source => {
    'id': 's1',
    'source_type': 'CREDIT_CARD',
    'currency': 'BRL',
    'name': 'Cartão de teste',
    'institution': 'Banco de teste',
    'holder_type': 'PJ',
  };
  FinancialJson get preview => {
    'id': 'p1',
    'source_id': 's1',
    'document_id': 'd1',
    'reader_id': 'pdf_auto',
    'created_at': '2026-10-17T12:00:00Z',
    'status': invalid ? 'INVALID' : 'READY',
    'result_sha256': 'a' * 64,
    'items_count': itemCount,
    'errors_count': invalid ? errorCount : 0,
    'pages_count': 6,
    'detected_institution': 'PICPAY',
    'extracted_header': {
      'statement_type': 'CARD_BILL',
      'due_on': '2026-10-20',
      'total_amount_cents': 12034,
      'minimum_payment_cents': 1200,
    },
    'field_sources': {
      'due_on': {'page_number': 2},
    },
    'warnings': [
      {'code': 'PDF_PARTIAL_DATE_YEAR_FROM_BILL_CONTEXT'},
    ],
    'checks': [
      {'code': 'PDF_SUMMARY_DETAILS', 'matches': !invalid},
    ],
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
    if (loadError != null) {
      throw ApiException(statusCode: 503, message: '', errorCode: loadError);
    }
    final uri = Uri.parse(path),
        offset = int.parse(Uri.parse(path).queryParameters['offset'] ?? '0');
    final limit = int.parse(uri.queryParameters['limit'] ?? '100');
    if (uri.path == '$root/sources') return [source];
    if (uri.path == '$root/readers') {
      return [
        {'id': 'pdf_auto', 'version': '1', 'media_type': 'application/pdf'},
        {'id': 'nubank_card_csv', 'version': '1', 'media_type': 'text/csv'},
      ];
    }
    if (uri.path == '/api/v1/treasury/accounts') return [];
    if (uri.path == '$root/previews') return [preview];
    if (uri.path == '$root/previews/p1') return preview;
    if (uri.path == '$root/documents/d1') {
      return {'id': 'd1', 'filename': 'Fatura teste.pdf'};
    }
    if (uri.path == '$root/statements') {
      return [
        if (confirmed) {'id': 'st1', 'preview_id': 'p1'},
      ];
    }
    if (uri.path == '$root/previews/p1/items') {
      return [
        for (var i = offset; i < itemCount && i < offset + limit; i++)
          {
            'position': i + 1,
            'page_number': 2,
            'raw_text': 'Linha original sintética $i',
            'candidates': [],
            'data': {
              'transaction_date': '2026-10-10',
              'amount_cents': i == 0 ? -1234 : 500,
              'description': 'Lançamento sintético $i',
              'installment_number': 2,
              'total_installments': 3,
            },
          },
      ];
    }
    if (uri.path == '$root/previews/p1/errors') {
      return [
        if (invalid)
          for (var i = offset; i < errorCount && i < offset + limit; i++)
            {'code': 'PDF_SUMMARY_DETAIL_MISMATCH', 'page_number': 2},
      ];
    }
    if (uri.path == '$root/previews/p1/pages') {
      return [
        for (var i = offset; i < 6 && i < offset + limit; i++)
          {'page_number': i + 1, 'text': 'Texto sintético da página ${i + 1}'},
      ];
    }
    throw StateError('Unexpected read: $path');
  }

  @override
  Future<dynamic> uploadBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    expect(contentType, 'application/pdf');
    expect(bytes, sampleFile().bytes);
    writes.add((path: path, body: bytes, key: idempotencyKey));
    if (uploadGate != null) await uploadGate!.future;
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
    if (path == '/api/v1/treasury/accounts') return {'id': 'bank1'};
    if (path == '$root/sources') {
      if (failSourceOnce) {
        failSourceOnce = false;
        throw ApiException(statusCode: 0, message: 'lost');
      }
      return {...source, ...body as Map, 'id': 's1'};
    }
    if (path == '$root/documents/d1/previews') return {'preview': preview};
    if (path == '$root/previews/p1/confirm') {
      confirmed = true;
      if (failConfirmOnce) {
        failConfirmOnce = false;
        throw ApiException(statusCode: 0, message: 'lost');
      }
      return {
        'statement': {
          'id': 'st1',
          'preview_id': 'p1',
          'pending_count': itemCount,
        },
      };
    }
    throw StateError('Unexpected write: $path');
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: approvedAppTheme(dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('pdf-capture'),
          child: child!,
        ),
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> click(WidgetTester tester, Finder f, {double delta = 300}) async {
  bool isVisible() {
    try {
      return f.evaluate().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  if (!isVisible()) {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      for (var i = 0; i < 50 && !isVisible(); i++) {
        await tester.drag(scrollable.first, Offset(0, -delta));
        await tester.pumpAndSettle();
      }
    }
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PDF_IMPORT_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('pdf-capture')),
  );
  await tester.runAsync(() async {
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    final dir = await Directory(
      'build/pdf-import-preview',
    ).create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    bitmap.dispose();
  });
}

void main() {
  setUpAll(AppFormatters.initialize);
  test(
    'upload is binary, PDF auto uses selected origin and confirmation sends exact preconditions',
    () async {
      final api = ImportApi(),
          service = FinancialImportService(apiClient: ImportApi());
      final live = FinancialImportService(apiClient: api);
      final p = await live.importPdf(sampleFile(), 's1');
      await live.confirm(p);
      expect(
        api.writes[0].path,
        '$root/documents?filename=Fatura+teste+%231.pdf',
      );
      expect(api.writes[1].body, {
        'source_id': 's1',
        'currency': 'BRL',
        'reader_id': 'pdf_auto',
      });
      expect(api.writes.last.body, {
        'expected_source_id': 's1',
        'expected_result_sha256': 'a' * 64,
        'statement_type': 'CARD_BILL',
      });
      expect(
        api.writes.every((w) => w.key != null && w.key!.length <= 120),
        isTrue,
      );
      service.close();
    },
  );
  test(
    'same original and confirmation reuse keys after service restart; other server has other keys',
    () async {
      final api = ImportApi()..failConfirmOnce = true;
      var service = FinancialImportService(apiClient: api);
      final p = await service.importPdf(sampleFile(), 's1');
      await expectLater(service.confirm(p), throwsA(isA<ApiException>()));
      final first = api.writes.last;
      service.close();
      service = FinancialImportService(apiClient: api);
      await service.importPdf(sampleFile(), 's1');
      await service.confirm(p);
      expect(api.writes.last.key, first.key);
      expect(api.writes.last.body, first.body);
      expect(api.writes[0].key, api.writes[3].key);
      api.origin = ApiOrigin(url: 'https://other.invalid', fingerprint: 'BB');
      await FinancialImportService(apiClient: api).confirm(p);
      expect(api.writes.last.key, isNot(first.key));
    },
  );
  test('invalid file or blocked preview never sends mutation', () async {
    final api = ImportApi()..invalid = true;
    final service = FinancialImportService(apiClient: api);
    await expectLater(
      service.importPdf(FinancialPdfFile('x.pdf', Uint8List(10)), 's1'),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      service.importPdf(
        FinancialPdfFile('x.pdf', Uint8List(10 * 1024 * 1024 + 1)),
        's1',
      ),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      service.confirm(api.preview),
      throwsA(isA<ApiException>()),
    );
    expect(api.writes, isEmpty);
  });
  test(
    'bank source retry recovers account command without ledger writes',
    () async {
      final api = ImportApi()..failSourceOnce = true;
      Future<FinancialJson> create() =>
          FinancialImportService(apiClient: api).createSource(
            name: 'Conta teste',
            institution: 'Banco teste',
            sourceType: 'BANK_ACCOUNT',
            holderType: 'PF',
          );
      await expectLater(create(), throwsA(isA<ApiException>()));
      await create();
      expect(api.writes[0].key, api.writes[2].key);
      expect(api.writes[1].key, api.writes[3].key);
      expect((api.writes[0].body as Map)['initial_balance_cents'], 0);
      expect((api.writes[1].body as Map)['financial_account_id'], 'bank1');
      expect(
        api.writes.where(
          (w) => w.path.contains('entries') || w.path.contains('payments'),
        ),
        isEmpty,
      );
    },
  );
  testWidgets(
    'select PDF, origin, read and confirm pending evidence through real service',
    (tester) async {
      final api = ImportApi();
      await mount(
        tester,
        FinancialImportsView(
          service: FinancialImportService(apiClient: api),
          pickFile: () async => sampleFile(),
        ),
      );
      await click(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.text('Cartão de teste · Banco de teste · PJ').last);
      await tester.pumpAndSettle();
      await click(tester, find.text('Selecionar PDF'));
      await click(tester, find.text('Ler documento'));
      expect(find.text('Fatura teste.pdf'), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(12034)), findsOneWidget);
      final button = find.byKey(const ValueKey('pdf-confirm'));
      expect(tester.widget<FloatingActionButton>(button).onPressed, isNull);
      await click(tester, find.byType(CheckboxListTile));
      await click(tester, button);
      expect(find.byKey(const ValueKey('pdf-confirm')), findsNothing);
      expect(api.confirmed, isTrue);
      await tester.scrollUntilVisible(
        find.text(
          'Documento guardado. Os lançamentos continuam pendentes de revisão, sem criar dívidas ou pagamentos.',
        ),
        -300,
      );
      expect(
        find.text(
          'Documento guardado. Os lançamentos continuam pendentes de revisão, sem criar dívidas ou pagamentos.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'blocked controls cannot confirm; pagination keeps negative amounts and source pages',
    (tester) async {
      final api = ImportApi()
        ..invalid = true
        ..itemCount = 51
        ..errorCount = 51;
      await mount(
        tester,
        FinancialPdfPreviewView(
          service: FinancialImportService(apiClient: api),
          previewId: 'p1',
        ),
      );
      expect(find.byKey(const ValueKey('pdf-confirm')), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      await capture(tester, 'blocked-phone');
      await click(tester, find.text('Carregar mais').first);
      expect(api.gets.any((p) => p.contains('/errors?offset=50')), isTrue);
      await click(tester, find.text('Carregar mais').first);
      expect(api.gets.any((p) => p.contains('/items?offset=50')), isTrue);
      await tester.scrollUntilVisible(
        find.text(AppFormatters.formatCurrency(-1234)),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(AppFormatters.formatCurrency(-1234)),
        findsOneWidget,
      );
      await click(tester, find.text('Carregar mais').last);
      expect(api.gets.any((p) => p.contains('/pages?offset=5')), isTrue);
      expect(api.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('lost confirmation is recovered when reopening server preview', (
    tester,
  ) async {
    final api = ImportApi()..confirmed = true;
    await mount(
      tester,
      FinancialPdfPreviewView(
        service: FinancialImportService(apiClient: api),
        previewId: 'p1',
      ),
    );
    expect(find.byKey(const ValueKey('pdf-confirm')), findsNothing);
    expect(find.text('Documento guardado · revisão pendente'), findsOneWidget);
    expect(api.writes, isEmpty);
  });
  testWidgets('schema failure explains update and preserves blocked import', (
    tester,
  ) async {
    final api = ImportApi()..loadError = 'FINANCIAL_SCHEMA_NOT_READY';
    await mount(
      tester,
      FinancialImportsView(service: FinancialImportService(apiClient: api)),
    );
    expect(find.textContaining('migração financeira'), findsOneWidget);
    expect(find.text('Ler documento'), findsNothing);
    expect(api.writes, isEmpty);
  });
  for (final config in [
    (const Size(320, 780), false, 1.0),
    (const Size(390, 844), true, 1.0),
    (const Size(1200, 900), false, 1.0),
    (const Size(390, 844), true, 1.7),
  ]) {
    testWidgets('import and source registration adapt $config', (tester) async {
      final api = ImportApi();
      await mount(
        tester,
        FinancialImportsView(service: FinancialImportService(apiClient: api)),
        size: config.$1,
        dark: config.$2,
        scale: config.$3,
      );
      await capture(
        tester,
        'import-${config.$1.width.toInt()}-${config.$2}-${config.$3}',
      );
      await click(tester, find.text('Cadastrar conta ou cartão'));
      expect(find.text('Instituição financeira'), findsOneWidget);
      await capture(
        tester,
        'source-${config.$1.width.toInt()}-${config.$2}-${config.$3}',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(
        tester,
        FinancialPdfPreviewView(
          service: FinancialImportService(apiClient: api),
          previewId: 'p1',
        ),
        size: config.$1,
        dark: config.$2,
        scale: config.$3,
      );
      await capture(
        tester,
        'preview-${config.$1.width.toInt()}-${config.$2}-${config.$3}',
      );
      await click(tester, find.byType(CheckboxListTile));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'PDF limitation errors are localized without exposing technical code',
    (tester) async {
      await mount(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox).first);
      final l = AppLocalizations.of(context)!;
      for (final code in [
        'PDF_PASSWORD_REQUIRED',
        'PDF_OCR_OR_TEXT_REQUIRED',
        'PDF_LAYOUT_UNSUPPORTED',
        'PDF_RUNTIME_UNAVAILABLE',
        'PDF_PROCESSING_BUSY',
        'PDF_UNPARSED_MONEY_ROW',
      ]) {
        final message = ApiErrorMapper.toLocalizedMessage(
          ApiException(statusCode: 422, message: 'private', errorCode: code),
          l,
        );
        expect(message, isNot(contains('private')));
        expect(message, isNot(contains('PDF_')));
      }
    },
  );
}
