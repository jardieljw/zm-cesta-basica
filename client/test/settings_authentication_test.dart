import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/core/constants.dart';
import 'package:zm_cesta_basica_client/core/secure_storage.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/services/auth_service.dart';
import 'package:zm_cesta_basica_client/services/backup_service.dart';
import 'package:zm_cesta_basica_client/services/connectivity_service.dart';
import 'package:zm_cesta_basica_client/services/printer_service.dart';
import 'package:zm_cesta_basica_client/views/pairing_view.dart';
import 'package:zm_cesta_basica_client/views/settings_view.dart';

class _Storage extends SecureStorageService {
  String url = 'https://127.0.0.1:8000';
  String? token;
  String? id;
  String? name;
  String fp = '';
  @override
  Future<String?> getServerUrl() async => url;
  @override
  Future<void> saveServerUrl(String value) async {
    url = value;
  }

  @override
  Future<String?> getFingerprint() async => fp;
  @override
  Future<void> saveFingerprint(String value) async {
    fp = value;
  }

  @override
  Future<String?> getDeviceToken() async => token;
  @override
  Future<void> saveDeviceToken(String value) async {
    token = value;
  }

  @override
  Future<String?> getDevicePublicId() async => id;
  @override
  Future<String?> getDeviceName() async => name;
  @override
  Future<void> saveDeviceIdentity({
    required String devicePublicId,
    required String deviceName,
  }) async {
    id = devicePublicId;
    name = deviceName;
  }

  @override
  Future<void> clearAll() async {
    token = null;
    id = null;
    name = null;
    fp = '';
  }
}

class _Api extends ApiClient {
  final _Storage storage;
  int localPairings = 0;
  final newDatabaseKeys = <String?>[];
  bool failNewDatabase = false;
  _Api(this.storage);
  @override
  Future<dynamic> get(String path) async {
    if (path == ApiConstants.healthPath) return {'version': 'test'};
    if (path == ApiConstants.devicesListPath) {
      if (storage.token == 'valid-token') return [];
      throw ApiException(statusCode: 401, message: 'unauthorized');
    }
    if (path == '/api/v1/backup/list') return [];
    throw StateError('Unexpected request: $path');
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    if (path == '/api/v1/backup/new-database') {
      newDatabaseKeys.add(idempotencyKey);
      expect(body, {'confirmation': 'NOVO BANCO'});
      if (failNewDatabase) {
        throw ApiException(statusCode: 0, message: 'response lost');
      }
      return {
        'integrity_ok': true,
        'safety_backup_filename': 'before.db',
        'active_database_path': 'estoque.db',
      };
    }
    expect(path, ApiConstants.pairingLocalMasterPath);
    localPairings++;
    return {
      'device_token': 'valid-token',
      'device_public_id': 'local',
      'device_name': 'Windows',
    };
  }
}

class _OfflineApi extends _Api {
  int requests = 0;
  _OfflineApi(super.storage);
  @override
  Future<dynamic> get(String path) async {
    requests++;
    throw ApiException(statusCode: 0, message: 'offline');
  }
}

class _LocalPrinterService extends PrinterService {
  int testPrints = 0;
  @override
  bool get isAndroid => true;
  @override
  Future<PrintingInfo> capabilities() async =>
      const PrintingInfo(canPrint: true);
  @override
  Future<List<Printer>> installedPrinters(PrintingInfo info) async => [];
  @override
  Future<bool> printDocument({
    required Future<Uint8List> Function(PdfPageFormat) buildPdf,
    required String name,
    required PdfPageFormat format,
    Printer? printer,
    bool dynamicLayout = true,
  }) async {
    final bytes = await buildPdf(format);
    expect(bytes.length, greaterThan(1000));
    expect(name, 'ZM_teste_A4.pdf');
    testPrints++;
    return false;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final l10n = AppLocalizationsPt();
  Future<void> render(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: widget,
      ),
    );
    await tester.pumpAndSettle();
  }

  SettingsView settings(_Storage store, _Api api, bool windows) => SettingsView(
        storage: store,
        auth: AuthService(storage: store, apiClient: api),
        connectivity: ConnectivityService(
          storage: store,
          apiClient: api,
          isWindows: windows,
        ),
        backupService: BackupService(apiClient: api, storage: store),
      );

  testWidgets(
    'printer diagnosis and test page work without server or authentication',
    (tester) async {
      final store = _Storage();
      final api = _OfflineApi(store);
      final printers = _LocalPrinterService();
      addTearDown(printers.dispose);
      await render(
        tester,
        SettingsView(
          storage: store,
          auth: AuthService(storage: store, apiClient: api),
          connectivity: ConnectivityService(
            storage: store,
            apiClient: api,
            isWindows: false,
          ),
          backupService: BackupService(apiClient: api, storage: store),
          printerService: printers,
        ),
      );
      expect(find.text(l10n.settingsStatusDisconnected), findsOneWidget);
      final requests = api.requests;
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-printers')),
      );
      await tester.tap(find.byKey(const ValueKey('settings-printers')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('printer-system-print')), findsNothing);
      final testPage = find.byKey(const ValueKey('printer-test-page'));
      await tester.ensureVisible(testPage);
      await tester.tap(testPage);
      await tester.pumpAndSettle();
      expect(printers.testPrints, 1);
      expect(api.requests, requests);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'local authentication requires Windows, HTTPS and an actual loopback host',
    () async {
      for (final url in [
        'https://127.0.0.1:8000',
        'https://localhost:8000',
        'https://[::1]:8000',
        'https://localhost.example.com:8000',
        'https://192.168.1.10:8000',
        'http://localhost:8000',
      ]) {
        for (final windows in [true, false]) {
          final store = _Storage()..url = url;
          final api = _Api(store);
          final service = ConnectivityService(
            storage: store,
            apiClient: api,
            isWindows: windows,
          );
          final allowed = windows &&
              [
                'https://127.0.0.1:8000',
                'https://localhost:8000',
                'https://[::1]:8000',
              ].contains(url);
          expect(await service.isPaired(allowLocalPairing: true), allowed);
          expect(api.localPairings, allowed ? 1 : 0);
        }
      }
    },
  );
  test('a stored invalid token does not count as authentication', () async {
    final store = _Storage()..token = 'revoked-token';
    final api = _Api(store);
    final service = ConnectivityService(
      storage: store,
      apiClient: api,
      isWindows: true,
    );
    expect(await service.isPaired(), isFalse);
    expect(api.localPairings, 0);
    store.token = 'valid-token';
    expect(await service.isPaired(), isTrue);
    expect(api.localPairings, 0);
  });
  testWidgets(
    'Windows save authenticates the local computer and refreshes its status',
    (tester) async {
      final store = _Storage();
      final api = _Api(store);
      await render(tester, settings(store, api, true));
      expect(find.text(l10n.settingsStatusConnectedWaiting), findsOneWidget);
      final save = find.text(l10n.settingsSaveAuthenticate);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.localPairings, 1);
      expect(store.token, 'valid-token');
      expect(find.text(l10n.settingsStatusConnectedPaired), findsOneWidget);
      expect(find.text('valid-token'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets(
    'Windows accepts a supplied token without automatically replacing it',
    (tester) async {
      final store = _Storage()..url = 'https://192.168.1.10:8000';
      final api = _Api(store);
      await render(tester, settings(store, api, true));
      final token = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == l10n.settingsDeviceTokenLabel,
      );
      await tester.ensureVisible(token);
      await tester.enterText(token, 'valid-token');
      await tester.tap(find.text(l10n.settingsSaveAuthenticate));
      await tester.pumpAndSettle();
      expect(api.localPairings, 0);
      expect(find.text(l10n.settingsStatusConnectedPaired), findsOneWidget);
      expect((tester.widget<TextField>(token)).controller!.text, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets(
    'Android settings only offer device pairing rather than network editing',
    (tester) async {
      final store = _Storage();
      final api = _Api(store);
      await render(tester, settings(store, api, false));
      expect(find.text(l10n.settingsPairDeviceButton), findsOneWidget);
      expect(find.text(l10n.settingsServerNetworkSection), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(l10n.settingsGenerateQrButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'Windows PIN pairing does not initialize a camera or offer a scanner tab',
    (tester) async {
      final store = _Storage();
      final api = _Api(store);
      await render(
        tester,
        PairingView(
          storage: store,
          auth: AuthService(storage: store, apiClient: api),
        ),
      );
      expect(find.text(l10n.pairingTabQr), findsNothing);
      expect(find.text(l10n.pairingTabManual), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  test(
    'lost new database response keeps the same request key across service instances',
    () async {
      final store = _Storage();
      final api = _Api(store)..failNewDatabase = true;
      await expectLater(
        BackupService(apiClient: api, storage: store).createNewDatabase(),
        throwsA(isA<ApiException>()),
      );
      api.failNewDatabase = false;
      await BackupService(apiClient: api, storage: store).createNewDatabase();
      expect(api.newDatabaseKeys[0], isNotNull);
      expect(api.newDatabaseKeys[1], api.newDatabaseKeys[0]);
      await BackupService(apiClient: api, storage: store).createNewDatabase();
      expect(api.newDatabaseKeys[2], isNot(api.newDatabaseKeys[0]));
    },
  );

  testWidgets(
    'new database requires typed confirmation and cancellation sends no request',
    (tester) async {
      final store = _Storage()..token = 'valid-token';
      final api = _Api(store);
      await render(tester, settings(store, api, true));
      final create = find.widgetWithText(OutlinedButton, l10n.newDatabaseTitle);
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(
        FilledButton,
        l10n.newDatabaseConfirmAction,
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(find.widgetWithText(TextButton, l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(api.newDatabaseKeys, isEmpty);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final input = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == l10n.newDatabaseConfirmationLabel,
      );
      await tester.enterText(input, 'NOVO BANCO');
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(api.newDatabaseKeys.length, 1);
      expect(find.text(l10n.newDatabaseSuccess('before.db')), findsOneWidget);
      expect(find.text(l10n.settingsStatusConnectedPaired), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'authenticated Android has backup but not the database replacement action',
    (tester) async {
      final store = _Storage()..token = 'valid-token';
      final api = _Api(store);
      await render(tester, settings(store, api, false));
      expect(find.text(l10n.backupCreateButton), findsOneWidget);
      expect(find.text(l10n.newDatabaseTitle), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
