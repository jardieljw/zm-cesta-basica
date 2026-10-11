import 'package:flutter/material.dart';
import '../models/connection_status.dart';
import '../services/connectivity_service.dart';
import '../core/secure_storage.dart';
import '../l10n/l10n_extension.dart';
import 'pairing_view.dart';
import 'settings_view.dart';
import 'products_view.dart';
import 'basket_types_view.dart';
import 'purchases_view.dart';
import 'inventory_summary_view.dart';
import 'inventory_movements_view.dart';
import 'production_batches_view.dart';
import 'production_assembly_view.dart';
import 'customers_view.dart';
import 'sales_view.dart';
import 'receivables_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ConnectivityService _connectivity = ConnectivityService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = false;
  ServerStatus? _serverStatus;
  bool _isPaired = false;
  String? _serverUrl;
  String? _fingerprint;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    final status = await _connectivity.checkConnection();
    final paired = await _connectivity.isPaired();
    final url = await _storage.getServerUrl();
    final fp = await _storage.getFingerprint();

    setState(() {
      _serverStatus = status;
      _isPaired = paired;
      _serverUrl = url ?? 'https://127.0.0.1:8000';
      _fingerprint = fp;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isOnline = _serverStatus?.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeHeaderTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.moduleSettings,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
              _refreshStatus();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConnectionBadge(theme, isOnline),
              const SizedBox(height: 24),
              _buildModuleNavigation(theme, isOnline),
              const SizedBox(height: 24),
              _buildServerInfoCard(theme),
              const SizedBox(height: 24),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleNavigation(ThemeData theme, bool isOnline) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homePhase2Header,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductsView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 24,
                          child: Icon(Icons.inventory_2, color: Colors.blue.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleProducts,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeProductsDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BasketTypesView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          radius: 24,
                          child: Icon(Icons.shopping_basket, color: Colors.purple.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleBasketTypes,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeBasketTypesDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.homePhase3Header,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PurchasesView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 24,
                          child: Icon(Icons.local_shipping, color: Colors.teal.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.modulePurchases,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homePurchasesDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventorySummaryView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: 24,
                          child: Icon(Icons.assessment, color: Colors.green.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleInventorySummary,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeInventorySummaryDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryMovementsView()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    radius: 24,
                    child: Icon(Icons.receipt_long, color: Colors.amber.shade900, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.moduleInventoryMovements,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeInventoryMovementsDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.homePhase4Header,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductionBatchesView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          radius: 24,
                          child: Icon(Icons.precision_manufacturing, color: Colors.indigo.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleProduction,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeProductionBatchesDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductionAssemblyView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          radius: 24,
                          child: Icon(Icons.handyman, color: Colors.orange.shade900, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleAssembly,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeProductionAssemblyDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.homePhase5Header,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomersView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 24,
                          child: Icon(Icons.people, color: Colors.blue.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleCustomers,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeCustomersDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SalesView()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: 24,
                          child: Icon(Icons.point_of_sale, color: Colors.green.shade800, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moduleSales,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeSalesDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceivablesView()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    radius: 24,
                    child: Icon(Icons.account_balance_wallet, color: Colors.amber.shade900, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.moduleReceivables,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeReceivablesDescription,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildConnectionBadge(ThemeData theme, bool isOnline) {
    Color badgeColor;
    String statusText;
    IconData icon;

    if (!isOnline) {
      badgeColor = Colors.red.shade700;
      statusText = 'Servidor Local Desconectado';
      icon = Icons.cloud_off;
    } else if (!_isPaired) {
      badgeColor = Colors.amber.shade800;
      statusText = 'Conectado (Aguardando Pareamento)';
      icon = Icons.link_off;
    } else {
      badgeColor = Colors.green.shade700;
      statusText = 'Conectado e Pareado com Sucesso';
      icon = Icons.cloud_done;
    }

    return Card(
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
            Icon(icon, color: badgeColor, size: 36),
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
                    _isPaired
                        ? 'Operacoes comerciais autenticadas ativas.'
                        : 'Pareie este dispositivo com o servidor para habilitar operacoes.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard(ThemeData theme) {
    final l10n = context.l10n;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeLocalConnectionInfo, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _infoRow('${l10n.serverUrlLabel}:', _serverUrl ?? l10n.homeNotConfigured),
            const SizedBox(height: 12),
            _infoRow('${l10n.homeApiVersionLabel}:', _serverStatus?.version ?? l10n.homeNotAvailable),
            const SizedBox(height: 12),
            _infoRow('${l10n.homeDatabaseStatusLabel}:', _serverStatus?.databaseStatus ?? l10n.homeNotAvailable),
            const SizedBox(height: 12),
            _infoRow(
              '${l10n.homeTlsFingerprintLabel}:',
              _fingerprint ?? _serverStatus?.tlsFingerprint ?? l10n.homePending,
              isMonospace: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: isMonospace ? 'monospace' : null,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _refreshStatus,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh),
          label: Text(context.l10n.homeCheckConnection),
        ),
        const SizedBox(height: 12),
        if (!_isPaired)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingView()),
              );
              _refreshStatus();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(context.l10n.homePairDevice),
          ),
      ],
    );
  }
}
