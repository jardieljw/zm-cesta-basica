import 'package:flutter/material.dart';
import '../core/secure_storage.dart';
import '../services/auth_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final SecureStorageService _storage = SecureStorageService();
  final AuthService _auth = AuthService();

  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _fpCtrl = TextEditingController();

  String? _deviceId;
  String? _deviceName;
  bool _hasToken = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await _storage.getServerUrl() ?? 'https://127.0.0.1:8000';
    final fp = await _storage.getFingerprint() ?? '';
    final id = await _storage.getDevicePublicId();
    final name = await _storage.getDeviceName();
    final token = await _storage.getDeviceToken();

    setState(() {
      _urlCtrl.text = url;
      _fpCtrl.text = fp;
      _deviceId = id ?? 'Nao definido';
      _deviceName = name ?? 'Nao definido';
      _hasToken = token != null && token.isNotEmpty;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await _storage.saveServerUrl(_urlCtrl.text.trim());
    await _storage.saveFingerprint(_fpCtrl.text.trim());
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracoes de rede salvas.')),
      );
    }
  }

  Future<void> _unpairDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Desconexao'),
        content: const Text('Deseja realmente desvincular este dispositivo do servidor local?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.disconnect();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispositivo desvinculado com sucesso.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracoes de Rede e Dispositivo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL Base do Servidor Local',
                hintText: 'https://192.168.1.100:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fpCtrl,
              decoration: const InputDecoration(
                labelText: 'Impressao Digital TLS Pinning (SHA-256)',
                hintText: 'E3:4A:...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: const Text('Salvar Parametros de Rede'),
            ),
            const Divider(height: 40),
            Text('Status do Dispositivo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Identificador Publico:'),
              subtitle: Text(_deviceId ?? ''),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nome do Aparelho:'),
              subtitle: Text(_deviceName ?? ''),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Token Criptografico Salvo:'),
              subtitle: Text(_hasToken ? 'Sim (Armazenado de forma segura)' : 'Nao pareado'),
              trailing: Icon(
                _hasToken ? Icons.check_circle : Icons.cancel,
                color: _hasToken ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (_hasToken)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: _unpairDevice,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Desvincular e Apagar Credenciais'),
              ),
          ],
        ),
      ),
    );
  }
}
