// Optional, isolated HTTPS acceptance; configuration is private and never committed.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/core/secure_storage.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/views/home_view.dart';
import 'package:zm_cesta_basica_client/views/payable_payment_view.dart';
import 'financial_pdf_import_test.dart' as harness;
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

class _Storage extends SecureStorageService {
  _Storage(this.config);
  final Map config;
  @override
  Future<String?> getServerUrl() async => config['url'] as String;
  @override
  Future<String?> getFingerprint() async => config['fingerprint'] as String;
  @override
  Future<String?> getDeviceToken() async => config['token'] as String;
}

class _RealHttp extends HttpOverrides {}

// Real ApiClient requests, with sockets scoped to each call: pooled sockets
// otherwise retain FakeAsync timers across widget replacements in this harness.
class _SocketApi extends ApiClient {
  _SocketApi(this.connection, [this.origin]);
  final SecureStorageService connection;
  final ApiOrigin? origin;
  Future<T> _request<T>(Future<T> Function(ApiClient) action) async {
    final base = ApiClient(storage: connection);
    final client = origin == null ? base : base.bindOrigin(origin!);
    try {
      return await action(client);
    } finally {
      client.close();
      base.close();
    }
  }

  @override
  Future<ApiOrigin> readOrigin() => _request((c) => c.readOrigin());
  @override
  ApiClient bindOrigin(ApiOrigin origin) => _SocketApi(connection, origin);
  @override
  Future<dynamic> get(String path) => _request((c) => c.get(path));
  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) => _request(
    (c) => c.post(
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      isMutation: isMutation,
    ),
  );
  @override
  Future<dynamic> uploadBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    required String idempotencyKey,
  }) => _request(
    (c) => c.uploadBytes(
      path,
      bytes: bytes,
      contentType: contentType,
      idempotencyKey: idempotencyKey,
    ),
  );
}

Future<void> _tick(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump(const Duration(milliseconds: 100));
}

String? _debugPath;
Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var n = 0; n < 180; n++) {
    await _tick(tester);
    if (ready()) return;
  }
  if (_debugPath != null) {
    File(_debugPath!).writeAsStringSync(
      jsonEncode(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList(),
      ),
    );
  }
  throw StateError('Isolated HTTPS UI condition not reached');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  bool exists() {
    try {
      final elements = finder.evaluate();
      if (elements.isEmpty) return false;
      final widget = elements.first.widget;
      if (widget is IconButton && widget.onPressed == null) return false;
      if (widget is FloatingActionButton && widget.onPressed == null) {
        return false;
      }
      if (widget is ButtonStyleButton && widget.onPressed == null) return false;
      return true;
    } on StateError {
      // Finder.first/last can throw while an asynchronous page is still empty.
      return false;
    }
  }

  await _until(tester, exists);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await _until(tester, exists);
  // Start async event handlers outside FakeAsync, so real socket timers advance.
  await tester.runAsync(() async => tester.tap(finder));
  await _tick(tester);
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 950);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: approvedAppTheme(Brightness.light),
      home: child,
    ),
  );
  await _tick(tester);
}

void main() {
  const configPath = String.fromEnvironment('E4_HTTPS_CONFIG');
  setUpAll(() {
    HttpOverrides.global = _RealHttp();
  });
  tearDownAll(() {
    HttpOverrides.global = null;
  });
  testWidgets(
    'T16 real HTTPS from Home: import, confirm, return to Financeiro, Pagar, filters, items and agenda',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await harness.loadImportFonts();
      final config = jsonDecode(File(configPath).readAsStringSync()) as Map;
      _debugPath = config['debug_path'] as String?;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _SocketApi(_Storage(config));
      final payables = PayableService(client: _SocketApi(_Storage(config)));
      await _mount(
        tester,
        HomeView(
          apiClient: api,
          pickFinancialDocument: () async => FinancialImportFile(
            'synthetic-ui.pdf',
            File(config['pdf_path'] as String).readAsBytesSync(),
          ),
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('area-1')));
      await _tap(tester, find.text('Extratos e faturas'));
      final sourceField = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.key.toString().contains('pdf-source-'),
      );
      await _until(tester, () => sourceField.evaluate().isNotEmpty);
      tester.widget<DropdownButtonFormField<String>>(sourceField).onChanged!(
        config['source_id'] as String,
      );
      await _tick(tester);
      await _tap(tester, find.text('Selecionar documento').first);
      await _tap(tester, find.byKey(const ValueKey('read-document-fab')));
      await _until(
        tester,
        () => find.byType(CheckboxListTile).evaluate().isNotEmpty,
      );
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(
        tester,
        find
            .text(
              'Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga',
            )
            .last,
      );
      await _tap(tester, find.byType(CheckboxListTile).last);
      await _tap(tester, find.byKey(const ValueKey('bill-integrate-confirm')));
      await _tap(tester, find.text('Ver conta e pagamentos'));
      await _until(
        tester,
        () =>
            find.byType(PayablePaymentView).evaluate().isNotEmpty &&
            find.text('Itens da fatura').evaluate().isNotEmpty,
      );
      await _tap(tester, find.text('Itens da fatura'));
      expect(find.text('Loja UI - 3/10'), findsOneWidget);
      // Return along the same production navigation stack, without mounting Pagar directly.
      for (var i = 0; i < 3; i++) {
        await _tap(tester, find.byType(BackButton).last);
      }
      await _tap(tester, find.byKey(const ValueKey('finance-tab-1')));
      await _tap(tester, find.byKey(const ValueKey('finance-history')));
      await _tap(tester, find.byTooltip('Filtros'));
      await _tap(tester, find.text('Todos os períodos'));
      await tester.enterText(
        find.byKey(const ValueKey('payable-bank-card-filter')),
        'E5 UI card',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payable-merchant-filter')),
        'Loja UI',
      );
      await _tap(tester, find.text('Aplicar Filtros'));
      await _tap(tester, find.text('Consultar agenda e vínculos'));
      await _until(
        tester,
        () => find
            .textContaining(RegExp(r'Estimativas livres:.*700,07'))
            .evaluate()
            .isNotEmpty,
      );
      final result = await tester.runAsync(
        () => payables.getInstallmentAgenda({
          'source_id': config['source_id'] as String,
          'month': '11',
          'year': '2026',
        }),
      );
      expect(result!['count'], 1);
      expect(result['estimated_cents'], 10001);
      expect(
        (result['items'] as List).single['estimated_due_on'],
        '2026-11-24',
      );
      // Exercise removal and deliberate reimport through the same production UI.
      final beforeRemoval =
          await tester.runAsync(
                () => api.get(
                  '/api/v1/payables?source_id=${config['source_id']}',
                ),
              )
              as List;
      final originalTitleId = (beforeRemoval.single as Map)['id'];
      await _tap(
        tester,
        find.byType(BackButton).last,
      ); // agenda -> Pagar completo
      await _tap(
        tester,
        find.byType(BackButton).last,
      ); // Pagar completo -> Financeiro
      await _tap(tester, find.byKey(const ValueKey('finance-tab-0')));
      await _tap(tester, find.text('Extratos e faturas'));
      await _tap(tester, find.text('Ver documento').first);
      await _until(
        tester,
        () => find
            .byKey(const ValueKey('remove-current-import'))
            .evaluate()
            .isNotEmpty,
      );
      await _tap(tester, find.byKey(const ValueKey('remove-current-import')));
      await _tap(tester, find.byKey(const ValueKey('confirm-import-removal')));
      await _until(
        tester,
        () => find.text('Selecionar documento').evaluate().isNotEmpty,
      );
      final removedTitles =
          await tester.runAsync(
                () => api.get(
                  '/api/v1/payables?source_id=${config['source_id']}',
                ),
              )
              as List;
      expect(removedTitles, isEmpty);
      final removedAgenda = await tester.runAsync(
        () => payables.getInstallmentAgenda({
          'source_id': config['source_id'] as String,
        }),
      );
      expect(removedAgenda!['count'], 0);
      await _tap(tester, find.text('Selecionar documento').first);
      await _tap(tester, find.byKey(const ValueKey('read-document-fab')));
      await _until(
        tester,
        () => find
            .textContaining('Você importou este arquivo novamente.')
            .evaluate()
            .isNotEmpty,
      );
      final notYetRestored =
          await tester.runAsync(
                () => api.get(
                  '/api/v1/payables?source_id=${config['source_id']}',
                ),
              )
              as List;
      expect(notYetRestored, isEmpty);
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(
        tester,
        find
            .text(
              'Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga',
            )
            .last,
      );
      await _tap(tester, find.byType(CheckboxListTile).last);
      await _tap(tester, find.byKey(const ValueKey('bill-integrate-confirm')));
      await _until(
        tester,
        () => find.text('Ver conta e pagamentos').evaluate().isNotEmpty,
      );
      final restoredTitles =
          await tester.runAsync(
                () => api.get(
                  '/api/v1/payables?source_id=${config['source_id']}',
                ),
              )
              as List;
      expect(restoredTitles.length, 1);
      expect((restoredTitles.single as Map)['id'], originalTitleId);
      final restoredAgenda = await tester.runAsync(
        () => payables.getInstallmentAgenda({
          'source_id': config['source_id'] as String,
        }),
      );
      expect(restoredAgenda!['estimated_cents'], 70007);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      api.close();
      payables.close();
      await tester.pump(const Duration(seconds: 30));
    },
    skip: configPath.isEmpty,
  );
}
