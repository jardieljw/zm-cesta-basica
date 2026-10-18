import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zm_cesta_basica_client/core/secure_storage.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/views/pairing_view.dart';

// No server, credentials or business data are used by this camera smoke test.
class _Storage extends SecureStorageService {
  @override
  Future<String?> getServerUrl() async => null;
  @override
  Future<String?> getFingerprint() async => null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native Android camera starts and restarts in pairing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: PairingView(storage: _Storage()),
      ),
    );
    await tester.pump();

    Future<void> waitForCamera() async {
      for (var attempt = 0; attempt < 60; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        final scanner = find.byType(MobileScanner);
        if (scanner.evaluate().isEmpty) continue;
        final state = tester.widget<MobileScanner>(scanner).controller!.value;
        if (state.error != null) fail('Native camera error: ${state.error}');
        if (state.isRunning && state.size.width > 0 && state.size.height > 0) {
          debugPrint('NATIVE_CAMERA_READY ${state.size}');
          return;
        }
      }
      fail('Native camera did not become ready within 30 seconds');
    }

    await waitForCamera();
    final l10n = AppLocalizationsPt();
    await tester.tap(find.text(l10n.pairingTabManual));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.pairingTabQr));
    await waitForCamera();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
