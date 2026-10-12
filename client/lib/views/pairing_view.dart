import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../l10n/l10n_extension.dart';

class PairingView extends StatefulWidget {
  const PairingView({super.key});

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final SecureStorageService _storage = SecureStorageService();
  MobileScannerController? _scannerController;
  int _scannerKeyIndex = 0;

  final TextEditingController _serverUrlCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _fingerprintCtrl = TextEditingController();
  final TextEditingController _deviceNameCtrl = TextEditingController();

  bool _isPairing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initScanner();
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
    if (_tabController.index == 1) {
      if (_scannerController == null) {
        _initScanner();
      }
    } else {
      _stopScanner();
    }
    setState(() {});
  }

  void _initScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  void _restartScanner() {
    setState(() {
      _scannerKeyIndex++;
      _initScanner();
    });
  }

  void _stopScanner() {
    _scannerController?.stop();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController?.dispose();
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

    try {
      final creds = await _authService.pairWithPin(
        pinCode: pin,
        serverUrl: url,
        tlsFingerprint: fp,
        customDeviceName: _deviceNameCtrl.text.trim().isNotEmpty ? _deviceNameCtrl.text.trim() : null,
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
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = l10n.pairingError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
      }
    }
  }

  Future<void> _onQrCodeScanned(BarcodeCapture capture) async {
    final l10n = context.l10n;
    if (_isPairing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });

    try {
      final creds = await _authService.pairWithQrPayload(rawValue);
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
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = l10n.pairingError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
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
            Tab(icon: const Icon(Icons.qr_code_scanner), text: l10n.pairingTabQr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualPinTab(),
          _buildQrScannerTab(),
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
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
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
              labelText: '${l10n.settingsDeviceNameLabel} (${l10n.commonOptional})',
              hintText: l10n.pairingDeviceNameHint,
              prefixIcon: const Icon(Icons.phone_android),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.pairingQrInstructions,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_scannerController != null)
                MobileScanner(
                  key: ValueKey(_scannerKeyIndex),
                  controller: _scannerController!,
                  onDetect: _onQrCodeScanned,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 56, color: Colors.blue.shade700),
                            const SizedBox(height: 16),
                            Text(
                              l10n.cameraPermissionDenied,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.pairingCameraInitializeHint,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
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
