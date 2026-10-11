import 'package:flutter/material.dart';
import '../core/secure_storage.dart';
import '../services/auth_service.dart';
import '../l10n/l10n_extension.dart';

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
      _deviceId = id ?? '-';
      _deviceName = name ?? '-';
      _hasToken = token != null && token.isNotEmpty;
    });
  }

  Future<void> _saveSettings() async {
    final l10n = context.l10n;
    setState(() => _isSaving = true);
    await _storage.saveServerUrl(_urlCtrl.text.trim());
    await _storage.saveFingerprint(_fpCtrl.text.trim());
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaved)),
      );
    }
  }

  Future<void> _unpairDevice() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsUnpairTitle),
        content: Text(l10n.settingsUnpairContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsUnpairConfirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.disconnect();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsUnpairedSuccess)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsHeaderTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: l10n.serverUrlLabel,
                hintText: l10n.settingsServerUrlHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fpCtrl,
              decoration: InputDecoration(
                labelText: l10n.fingerprintLabel,
                hintText: l10n.settingsFingerprintHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.security),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: Text(l10n.settingsSaveButton),
            ),
            const Divider(height: 40),
            Text(l10n.settingsDeviceInfoSection, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsDeviceIdLabel),
              subtitle: Text(_deviceId ?? '-'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsDeviceNameLabel),
              subtitle: Text(_deviceName ?? '-'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsDeviceTokenLabel),
              subtitle: Text(_hasToken ? l10n.settingsDeviceTokenConfigured : l10n.settingsDeviceTokenMissing),
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
                label: Text(l10n.settingsUnpairButton),
              ),
          ],
        ),
      ),
    );
  }
}
