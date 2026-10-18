import '../utils/adaptive_ui_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/secure_storage.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../models/connection_status.dart';
import '../models/backup.dart';
import '../services/backup_service.dart';
import '../services/printer_service.dart';
import '../widgets/shared/printer_selection_dialog.dart';
import '../l10n/l10n_extension.dart';
import 'pairing_view.dart';
import '../utils/api_error_mapper.dart';

class SettingsView extends StatefulWidget {
  final SecureStorageService? storage;
  final ConnectivityService? connectivity;
  final AuthService? auth;
  final BackupService? backupService;
  final PrinterService? printerService;
  const SettingsView({
    super.key,
    this.storage,
    this.connectivity,
    this.auth,
    this.backupService,
    this.printerService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SecureStorageService _storage;
  late final AuthService _auth;
  late final ConnectivityService _connectivity;
  late final PrinterService _printers;

  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _fpCtrl = TextEditingController();
  final TextEditingController _tokenCtrl = TextEditingController();

  String? _deviceId;
  String? _deviceName;
  bool _hasToken = false;
  bool _isSaving = false;
  bool _isCheckingConnection = false;
  bool _isGeneratingQr = false;
  ServerStatus? _serverStatus;

  late final BackupService _backupService;
  List<BackupItemModel> _backups = [];
  bool _isCreatingBackup = false;
  bool _isCreatingDatabase = false;
  bool _isRestoringBackup = false;
  bool get _backupBusy =>
      _isCreatingBackup || _isRestoringBackup || _isCreatingDatabase;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? SecureStorageService();
    _auth = widget.auth ?? AuthService(storage: _storage);
    _connectivity =
        widget.connectivity ?? ConnectivityService(storage: _storage);
    _backupService = widget.backupService ?? BackupService();
    _printers = widget.printerService ?? PrinterService();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _fpCtrl.dispose();
    _tokenCtrl.dispose();
    if (widget.printerService == null) _printers.dispose();
    super.dispose();
  }

  Future<void> _confirmRestore(BackupItemModel backup) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupRestoreConfirmTitle),
        content: Text(l10n.backupRestoreConfirmBody(backup.filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.backupRestoreCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.backupRestoreConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoringBackup = true);
    try {
      final res = await _backupService.restoreBackup(backup.filename);
      await _loadBackups();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.backupRestoreSuccessMsg(res.safetyBackupFilename ?? '-'),
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupRestoreErrorMsg(e.toString())),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRestoringBackup = false);
    }
  }

  Future<void> _loadBackups() async {
    try {
      final list = await _backupService.listBackups();
      if (!mounted) return;
      setState(() => _backups = list);
    } catch (_) {
      // Lista indisponível (sem pareamento/servidor offline): mantém vazia.
    }
  }

  Future<void> _createBackup() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCreatingBackup = true);
    try {
      final res = await _backupService.createBackup();
      await _loadBackups();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupSuccessMsg(res.backupFilename)),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupErrorMsg(e.toString())),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _createNewDatabase() async {
    if (_backupBusy) return;
    final l10n = context.l10n;
    var confirmation = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(l10n.newDatabaseTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.newDatabaseConfirmationBody),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => update(() => confirmation = value),
                  decoration: InputDecoration(
                    labelText: l10n.newDatabaseConfirmationLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: confirmation.trim().toUpperCase() == 'NOVO BANCO'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(l10n.newDatabaseConfirmAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCreatingDatabase = true);
    try {
      final result = await _backupService.createNewDatabase();
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            result.operationReplayed
                ? l10n.newDatabaseAlreadyProcessed
                : l10n.newDatabaseSuccess(result.safetyBackupFilename),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.toLocalizedMessage(error, l10n)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingDatabase = false);
    }
  }

  Future<void> _loadSettings() async {
    final url = await _storage.getServerUrl() ?? 'https://127.0.0.1:8000';
    final fp = await _storage.getFingerprint() ?? '';
    final id = await _storage.getDevicePublicId();
    final name = await _storage.getDeviceName();
    final status = await _connectivity.checkConnection();
    final authenticated = status.isOnline && await _connectivity.isPaired();
    if (!mounted) return;

    setState(() {
      _urlCtrl.text = url;
      _fpCtrl.text = fp;
      _deviceId = id ?? '-';
      _deviceName = name ?? '-';
      _hasToken = authenticated;
      _serverStatus = status;
    });
    if (_hasToken) {
      _loadBackups();
    }
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    final status = await _connectivity.checkConnection();
    final authenticated = status.isOnline && await _connectivity.isPaired();
    if (!mounted) return;
    setState(() {
      _serverStatus = status;
      _hasToken = authenticated;
      _isCheckingConnection = false;
    });
  }

  Future<void> _generatePairingQr() async {
    final l10n = context.l10n;
    setState(() => _isGeneratingQr = true);
    try {
      final pairingData = await _auth.initiatePairing();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.settingsQrDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsQrDialogInstructions,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: pairingData.qrPayload,
                    version: QrVersions.auto,
                    size: 240.0,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: adaptiveUiSurface(context, Colors.amber.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: SelectableText(
                    l10n.settingsPinExpiresLabel(pairingData.pinCode),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: adaptiveUiText(context, Colors.amber.shade900),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.settingsQrManualTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCopyableRow(
                  label: l10n.settingsQrServerUrlLabel,
                  value: pairingData.serverUrl,
                ),
                const SizedBox(height: 8),
                _buildCopyableRow(
                  label: l10n.settingsQrFingerprintLabel,
                  value: pairingData.tlsFingerprintSha256,
                  isMonospace: true,
                ),
                const SizedBox(height: 8),
                _buildCopyableRow(
                  label: l10n.settingsQrPinLabel,
                  value: pairingData.pinCode,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.settingsQrClose),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQr = false);
      }
    }
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: adaptiveUiSurface(context, Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copiar',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(l10n.settingsCopiedToClipboard),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final url = _urlCtrl.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsHttpsUrlRequired)),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final oldUrl = await _storage.getServerUrl();
      if (oldUrl != null &&
          oldUrl.replaceFirst(RegExp(r'/$'), '') !=
              url.replaceFirst(RegExp(r'/$'), '')) {
        await _storage.clearAll();
      }
      await _storage.saveServerUrl(url);
      await _storage.saveFingerprint(_fpCtrl.text.trim());
      final suppliedToken = _tokenCtrl.text.trim();
      if (suppliedToken.isNotEmpty) {
        await _storage.saveDeviceToken(suppliedToken);
      }
      final status = await _connectivity.checkConnection();
      final authenticated =
          status.isOnline &&
          await _connectivity.isPaired(
            allowLocalPairing: suppliedToken.isEmpty,
          );
      _tokenCtrl.clear();
      await _loadSettings();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authenticated
                ? l10n.settingsAuthenticatedSuccess
                : l10n.settingsSavedNeedsAuthentication,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.toLocalizedMessage(error, l10n)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsUnpairedSuccess)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isOnline = _serverStatus?.isOnline ?? false;

    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (!isOnline) {
      badgeColor = Colors.red.shade700;
      statusText = l10n.settingsStatusDisconnected;
      statusIcon = Icons.cloud_off;
    } else if (!_hasToken) {
      badgeColor = Colors.amber.shade800;
      statusText = l10n.settingsStatusConnectedWaiting;
      statusIcon = Icons.link_off;
    } else {
      badgeColor = Colors.green.shade700;
      statusText = l10n.settingsStatusConnectedPaired;
      statusIcon = Icons.cloud_done;
    }

    final isAndroidDevice = defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHeaderTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Status da Conexão
            Card(
              elevation: 2,
              color: badgeColor.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: badgeColor, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(statusIcon, color: badgeColor, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasToken
                                ? l10n.settingsStatusPairedSubtitle
                                : l10n.settingsStatusWaitingSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Verificar Conexão
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCheckingConnection ? null : _checkConnection,
              icon: _isCheckingConnection
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.homeCheckConnection),
            ),
            const SizedBox(height: 24),

            // SEÇÃO DIFERENCIADA POR PLATAFORMA:
            // No Android: Opção de Parear Dispositivo (Escanear QR Code com Câmera ou digitar PIN)
            if (isAndroidDevice)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.settingsPairDeviceSection,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.settingsPairDeviceDesc,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PairingView(storage: _storage, auth: _auth),
                            ),
                          );
                          _loadSettings();
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.settingsPairDeviceButton),
                      ),
                    ],
                  ),
                ),
              )
            // No Windows (Computador Servidor): Opção de Gerar QR Code para Celular
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            l10n.settingsGenerateQrTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.settingsGenerateQrDesc,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isGeneratingQr ? null : _generatePairingQr,
                        icon: _isGeneratingQr
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.qr_code_2),
                        label: Text(l10n.settingsGenerateQrButton),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Configurações de Rede / URL do Servidor
            if (!isAndroidDevice) ...[
              Text(
                l10n.settingsServerNetworkSection,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAndroidDevice
                    ? l10n.settingsNetworkSectionDescAndroid
                    : l10n.settingsNetworkSectionDescWindows,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adaptiveUiSurface(context, Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: adaptiveUiSurface(context, Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: adaptiveUiText(context, Colors.blue.shade800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.settingsFingerprintExplanation,
                        style: TextStyle(
                          fontSize: 12,
                          color: adaptiveUiText(context, Colors.blue.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenCtrl,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.settingsDeviceTokenLabel,
                  helperText: l10n.settingsTokenEntryHelp,
                  helperMaxLines: 4,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: Text(l10n.settingsSaveAuthenticate),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.pin),
                label: Text(l10n.settingsPairComputer),
                onPressed: _isSaving
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PairingView(storage: _storage, auth: _auth),
                          ),
                        );
                        if (mounted) await _loadSettings();
                      },
              ),
            ],
            if (!isAndroidDevice) const SizedBox(height: 24),

            Card(
              child: ListTile(
                key: const ValueKey('settings-printers'),
                leading: const Icon(Icons.print_outlined),
                title: Text(l10n.printerDialogTitle),
                subtitle: Text(l10n.printerSettingsEntryHelp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => PrinterSelectionDialog(service: _printers),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Backup e Segurança do Banco de Dados (requer dispositivo pareado)
            if (_hasToken) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.backup, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.backupSectionTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.backupSectionDesc,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _backupBusy ? null : _createBackup,
                        icon: _isCreatingBackup
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt),
                        label: Text(
                          _isCreatingBackup
                              ? l10n.backupCreating
                              : l10n.backupCreateButton,
                        ),
                      ),
                      if (!isAndroidDevice) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _backupBusy ? null : _createNewDatabase,
                          icon: const Icon(Icons.storage),
                          label: Text(
                            _isCreatingDatabase
                                ? l10n.newDatabaseCreating
                                : l10n.newDatabaseTitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.newDatabaseHelp,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        l10n.backupListTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_backups.isEmpty)
                        Text(
                          l10n.backupEmptyList,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        )
                      else
                        ..._backups
                            .take(10)
                            .map(
                              (b) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.storage,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  b.filename,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${b.formattedSize} • ${b.modifiedAt.split('.').first.replaceFirst('T', ' ')}',
                                ),
                                trailing: TextButton.icon(
                                  onPressed: _backupBusy
                                      ? null
                                      : () => _confirmRestore(b),
                                  icon: const Icon(Icons.restore, size: 18),
                                  label: Text(l10n.backupRestoreButton),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(height: 40),

            // Informações do Dispositivo
            Text(
              l10n.settingsDeviceInfoSection,
              style: theme.textTheme.titleMedium,
            ),
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
              subtitle: Text(
                _hasToken
                    ? l10n.settingsDeviceTokenConfigured
                    : l10n.settingsDeviceTokenMissing,
              ),
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
