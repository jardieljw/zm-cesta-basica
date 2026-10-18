import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zm_cesta_basica_client/core/secure_storage.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/views/pairing_view.dart';
import 'package:zm_cesta_basica_client/models/device_auth.dart';
import 'package:zm_cesta_basica_client/services/auth_service.dart';

class _Auth extends AuthService {
  int attempts = 0;
  final result = Completer<DeviceAuthCredentials>();

  @override
  Future<DeviceAuthCredentials> pairWithQrPayload(String payload) {
    attempts++;
    return result.future;
  }
}

class _Storage extends SecureStorageService {
  @override
  Future<String?> getServerUrl() async => null;
  @override
  Future<String?> getFingerprint() async => null;
}

const _camera = MobileScannerViewAttributes(
  cameraDirection: CameraFacing.back,
  currentTorchMode: TorchState.off,
  numberOfCameras: 1,
  size: Size(640, 480),
);

class _CameraPlatform extends MobileScannerPlatform {
  int starts = 0;
  int stops = 0;
  int disposals = 0;
  bool permissionDenied = false;
  Completer<MobileScannerViewAttributes>? pendingStart;
  Completer<void>? pendingDispose;
  final codes = StreamController<BarcodeCapture?>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => codes.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() =>
      const ColoredBox(key: ValueKey('camera-preview'), color: Colors.black);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    expectSync(options.formats, [BarcodeFormat.qrCode]);
    if (permissionDenied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return pendingStart == null ? _camera : await pendingStart!.future;
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> dispose() async {
    disposals++;
    await pendingDispose?.future;
  }
}

void main() {
  final l10n = AppLocalizationsPt();
  late _CameraPlatform camera;

  setUp(() {
    final original = MobileScannerPlatform.instance;
    camera = _CameraPlatform();
    MobileScannerPlatform.instance = camera;
    addTearDown(() async {
      await camera.codes.close();
      MobileScannerPlatform.instance = original;
    });
  });

  Future<void> render(WidgetTester tester, {_Auth? auth}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: PairingView(storage: _Storage(), auth: auth),
      ),
    );
    await tester.pump();
  }

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  testWidgets('Android opens QR first and restarts after switching tabs', (
    tester,
  ) async {
    await render(tester);
    expect(camera.starts, 1);
    expect(find.byKey(const ValueKey('camera-preview')), findsOneWidget);
    await tester.tap(find.text(l10n.pairingTabManual));
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    await tester.tap(find.text(l10n.pairingTabQr));
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('granting first permission does not launch overlapping starts', (
    tester,
  ) async {
    final permission = Completer<MobileScannerViewAttributes>();
    camera.pendingStart = permission;
    await render(tester);
    expect(find.text(l10n.cameraStarting), findsOneWidget);
    await lifecycle(tester, AppLifecycleState.inactive);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(camera.starts, 1);
    expect(camera.stops, 0);
    permission.complete(_camera);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('camera-preview')), findsOneWidget);
    expect(camera.starts, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('camera stops in background and resumes only on QR tab', (
    tester,
  ) async {
    await render(tester);
    await lifecycle(tester, AppLifecycleState.inactive);
    expect(camera.stops, 1);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(camera.starts, 2);
    await tester.tap(find.text(l10n.pairingTabManual));
    await tester.pumpAndSettle();
    await lifecycle(tester, AppLifecycleState.inactive);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(camera.starts, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'denied permission can retry after old camera disposal completes',
    (tester) async {
      camera.permissionDenied = true;
      await render(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.cameraPermissionDenied), findsOneWidget);
      camera.permissionDenied = false;
      final disposal = Completer<void>();
      camera.pendingDispose = disposal;
      await tester.tap(find.text(l10n.cameraPermissionRequest));
      await tester.pump();
      expect(camera.disposals, 1);
      expect(camera.starts, 1);
      disposal.complete();
      await tester.pumpAndSettle();
      expect(camera.starts, 2);
      expect(find.byKey(const ValueKey('camera-preview')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('permission enabled in Android settings recovers on resume', (
    tester,
  ) async {
    camera.permissionDenied = true;
    await render(tester);
    await tester.pumpAndSettle();
    await lifecycle(tester, AppLifecycleState.inactive);
    camera.permissionDenied = false;
    await lifecycle(tester, AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    expect(find.byKey(const ValueKey('camera-preview')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('leaving QR during permission releases camera after grant', (
    tester,
  ) async {
    final permission = Completer<MobileScannerViewAttributes>();
    camera.pendingStart = permission;
    await render(tester);
    await tester.tap(find.text(l10n.pairingTabManual));
    await tester.pump(const Duration(seconds: 1));
    permission.complete(_camera);
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(camera.stops, 1);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('closing screen during permission disposes after pending start', (
    tester,
  ) async {
    final permission = Completer<MobileScannerViewAttributes>();
    camera.pendingStart = permission;
    await render(tester);
    await tester.pumpWidget(const SizedBox());
    permission.complete(_camera);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    expect(camera.disposals, 1);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'QR detection pairs once and resumes scanning after server error',
    (tester) async {
      final auth = _Auth();
      await render(tester, auth: auth);
      const capture = BarcodeCapture(
        barcodes: [Barcode(rawValue: 'pairing-qr')],
      );
      camera.codes.add(capture);
      camera.codes.add(capture);
      await tester.pump();
      expect(auth.attempts, 1);
      expect(camera.stops, 1);
      auth.result.completeError(
        ApiException(statusCode: 503, message: 'Servidor indisponível'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Servidor indisponível'), findsOneWidget);
      expect(camera.starts, 2);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'closing pairing while server responds does not update disposed UI',
    (tester) async {
      final auth = _Auth();
      await render(tester, auth: auth);
      camera.codes.add(
        const BarcodeCapture(barcodes: [Barcode(rawValue: 'pairing-qr')]),
      );
      await tester.pump();
      expect(auth.attempts, 1);
      await tester.pumpWidget(const SizedBox());
      auth.result.completeError(
        ApiException(statusCode: 503, message: 'Servidor indisponível'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('native analyzer error is shown without an unhandled exception', (
    tester,
  ) async {
    await render(tester);
    camera.codes.addError(StateError('simulated native analyzer failure'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.pairingCameraUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
