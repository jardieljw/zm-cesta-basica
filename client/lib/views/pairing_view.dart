import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../l10n/l10n_extension.dart';

class PairingView extends StatefulWidget {
  final AuthService? auth;
  final SecureStorageService? storage;
  const PairingView({super.key, this.auth, this.storage});

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final AuthService _authService;
  late final SecureStorageService _storage;
  MobileScannerController? _scannerController;
  int _scannerKeyIndex = 0;
  StreamSubscription<BarcodeCapture>? _scannerSubscription;
  Future<void> _scannerOperation = Future<void>.value();
  AppLifecycleState? _appLifecycle;
  bool _scannerClosing = false;

  final TextEditingController _serverUrlCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _fingerprintCtrl = TextEditingController();
  final TextEditingController _deviceNameCtrl = TextEditingController();

  bool _isPairing = false;
  bool _pairingComplete = false;
  String? _errorMessage;
  bool get _supportsScanner => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? SecureStorageService();
    _authService = widget.auth ?? AuthService(storage: _storage);
    _tabController = TabController(
      length: _supportsScanner ? 2 : 1,
      initialIndex: _supportsScanner ? 1 : 0,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    if (_supportsScanner) {
      _appLifecycle = WidgetsBinding.instance.lifecycleState;
      WidgetsBinding.instance.addObserver(this);
      _initScanner();
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScanner());
    }
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    final savedUrl = await _storage.getServerUrl();
    final savedFp = await _storage.getFingerprint();
    if (mounted) {
      setState(() {
        if (savedUrl != null && savedUrl.isNotEmpty) {
          _serverUrlCtrl.text = savedUrl;
        } else {
          _serverUrlCtrl.text = 'https://192.168.1.100:8000';
        }
        if (savedFp != null && savedFp.isNotEmpty) {
          _fingerprintCtrl.text = savedFp;
        }
      });
    }
  }

  void _onTabChanged() {
    _updateScanner();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
    _scannerSubscription = _scannerController!.barcodes.listen(
      _onQrCodeScanned,
      onError: (Object error, StackTrace stack) {
        debugPrint('QR camera detection failed: $error\n$stack');
        if (mounted && !_scannerClosing) {
          setState(() => _errorMessage = context.l10n.pairingCameraUnavailable);
        }
      },
    );
  }

  bool get _shouldRunScanner =>
      !_scannerClosing &&
      mounted &&
      _supportsScanner &&
      _tabController.index == 1 &&
      !_isPairing &&
      !_pairingComplete &&
      (_appLifecycle == null || _appLifecycle == AppLifecycleState.resumed);

  // Serialize native camera operations, including a start awaiting permission.
  // Disposing an old controller after starting a new one can close the new camera.
  void _updateScanner({bool restart = false}) {
    if (!_supportsScanner || _scannerClosing) return;
    _scannerOperation = _scannerOperation
        .then((_) async {
          if (_scannerClosing) return;
          if (restart) {
            unawaited(_scannerSubscription?.cancel());
            await _scannerController?.dispose();
            if (_scannerClosing) return;
            setState(() {
              _scannerKeyIndex++;
              _initScanner();
            });
            // Version 7 requires the preview widget to attach this controller.
            await WidgetsBinding.instance.endOfFrame;
            if (_scannerClosing) return;
          }
          final controller = _scannerController;
          if (controller == null) return;
          if (_shouldRunScanner) {
            await controller.start();
            // The user may have left the tab/app while permission was pending.
            if (!_shouldRunScanner) await controller.stop();
          } else {
            await controller.stop();
          }
        })
        .catchError((Object error, StackTrace stack) {
          debugPrint('QR camera operation failed: $error\n$stack');
          if (mounted && !_scannerClosing) {
            setState(
              () => _errorMessage = context.l10n.pairingCameraUnavailable,
            );
          }
        });
  }

  void _restartScanner() => _updateScanner(restart: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycle = state;
    // The permission dialog itself changes lifecycle before start completes.
    // Let that operation finish instead of launching another permission request.
    if (_scannerController?.value.isInitialized != true) return;
    _updateScanner(
      restart:
          state == AppLifecycleState.resumed &&
          _scannerController?.value.error != null,
    );
  }

  @override
  void dispose() {
    _scannerClosing = true;
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    unawaited(
      _scannerOperation.then((_) async {
        unawaited(_scannerSubscription?.cancel());
        await _scannerController?.dispose();
      }),
    );
    _serverUrlCtrl.dispose();
    _pinCtrl.dispose();
    _fingerprintCtrl.dispose();
    _deviceNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitManualPairing() async {
    final l10n = context.l10n;
    final pin = _pinCtrl.text.trim();
    final url = _serverUrlCtrl.text.trim();
    final fp = _fingerprintCtrl.text.trim();

    if (pin.length != 6) {
      setState(() => _errorMessage = l10n.pairingPinValidation);
      return;
    }

    if (url.isEmpty) {
      setState(() => _errorMessage = l10n.pairingUrlValidation);
      return;
    }

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });
    _updateScanner();

    try {
      final creds = await _authService.pairWithPin(
        pinCode: pin,
        serverUrl: url,
        tlsFingerprint: fp,
        customDeviceName: _deviceNameCtrl.text.trim().isNotEmpty
            ? _deviceNameCtrl.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(l10n.pairingSuccess(creds.deviceName)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = l10n.pairingError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
        _updateScanner();
      }
    }
  }

  Future<void> _onQrCodeScanned(BarcodeCapture capture) async {
    if (!_shouldRunScanner) return;
    final l10n = context.l10n;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });
    _updateScanner();

    try {
      final creds = await _authService.pairWithQrPayload(rawValue);
      if (mounted) {
        _pairingComplete = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(l10n.pairingSuccess(creds.deviceName)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = l10n.pairingError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
        _updateScanner();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairingViewTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.pin), text: l10n.pairingTabManual),
            if (_supportsScanner)
              Tab(
                icon: const Icon(Icons.qr_code_scanner),
                text: l10n.pairingTabQr,
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualPinTab(),
          if (_supportsScanner) _buildQrScannerTab(),
        ],
      ),
    );
  }

  Widget _buildManualPinTab() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          TextField(
            controller: _serverUrlCtrl,
            decoration: InputDecoration(
              labelText: l10n.serverUrlLabel,
              hintText: l10n.pairingServerUrlHint,
              prefixIcon: const Icon(Icons.lan),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: l10n.pairingTabManual,
              hintText: l10n.pairingPinHint,
              prefixIcon: const Icon(Icons.lock_clock),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fingerprintCtrl,
            decoration: InputDecoration(
              labelText: l10n.fingerprintLabel,
              hintText: l10n.pairingFingerprintHint,
              prefixIcon: const Icon(Icons.fingerprint),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deviceNameCtrl,
            decoration: InputDecoration(
              labelText:
                  '${l10n.settingsDeviceNameLabel} (${l10n.commonOptional})',
              hintText: l10n.pairingDeviceNameHint,
              prefixIcon: const Icon(Icons.phone_android),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isPairing ? null : _submitManualPairing,
            child: _isPairing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(l10n.pairingButton),
          ),
        ],
      ),
    );
  }

  Widget _buildQrScannerTab() {
    final l10n = context.l10n;
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.pairingQrInstructions, textAlign: TextAlign.center),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_scannerController != null)
                MobileScanner(
                  key: ValueKey(_scannerKeyIndex),
                  controller: _scannerController!,
                  useAppLifecycleState: false,
                  placeholderBuilder: (context) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.cameraStarting),
                      ],
                    ),
                  ),
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 56,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
                                  ? l10n.cameraPermissionDenied
                                  : l10n.pairingCameraUnavailable,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
                                  ? l10n.pairingCameraPermissionHint
                                  : l10n.pairingCameraInitializeHint,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _restartScanner,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.cameraPermissionRequest),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_isPairing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
