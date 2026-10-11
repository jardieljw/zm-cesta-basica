import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';

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
    final pin = _pinCtrl.text.trim();
    final url = _serverUrlCtrl.text.trim();
    final fp = _fingerprintCtrl.text.trim();

    if (pin.length != 6) {
      setState(() => _errorMessage = 'O PIN deve conter exatamente 6 digitos.');
      return;
    }

    if (url.isEmpty) {
      setState(() => _errorMessage = 'Informe o endereco IP/URL do servidor.');
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
            content: Text('Dispositivo "${creds.deviceName}" pareado com sucesso!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao parear: $e');
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
      }
    }
  }

  Future<void> _onQrCodeScanned(BarcodeCapture capture) async {
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
            content: Text('Pareado via QR Code: "${creds.deviceName}"!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'QR Code invalido: $e');
    } finally {
      if (mounted) {
        setState(() => _isPairing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pareamento de Dispositivo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pin), text: 'PIN Manual'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear QR Code'),
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
            decoration: const InputDecoration(
              labelText: 'URL / IP do Servidor Local',
              hintText: 'https://192.168.1.100:8000',
              prefixIcon: Icon(Icons.lan),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN Temporario de 6 digitos',
              hintText: 'Ex: 482910',
              prefixIcon: Icon(Icons.lock_clock),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fingerprintCtrl,
            decoration: const InputDecoration(
              labelText: 'Impressao Digital TLS (SHA-256)',
              hintText: 'Ex: E3:4A:... (exibido na tela do servidor)',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deviceNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome deste Aparelho (Opcional)',
              hintText: 'Ex: Celular Balcao 01',
              prefixIcon: Icon(Icons.phone_android),
              border: OutlineInputBorder(),
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
                : const Text('Confirmar Pareamento e Gerar Token'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrScannerTab() {
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aponte a camera para o QR Code gerado na tela do computador servidor.',
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
