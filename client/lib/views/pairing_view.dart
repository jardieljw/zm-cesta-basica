import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';

class PairingView extends StatefulWidget {
  const PairingView({super.key});

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  final TextEditingController _serverUrlCtrl = TextEditingController(text: 'https://192.168.1.100:8000');
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _fingerprintCtrl = TextEditingController();
  final TextEditingController _deviceNameCtrl = TextEditingController();

  bool _isPairing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              MobileScanner(
                onDetect: _onQrCodeScanned,
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
