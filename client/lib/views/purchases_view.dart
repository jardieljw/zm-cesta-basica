import 'package:flutter/material.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'purchase_form_view.dart';

class PurchasesView extends StatefulWidget {
  const PurchasesView({super.key});

  @override
  State<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends State<PurchasesView> {
  final PurchaseService _purchaseService = PurchaseService();

  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _purchaseService.getPurchases(
        status: _statusFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _purchases = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green.shade700;
      case 'DRAFT':
        return Colors.amber.shade800;
      case 'CANCELED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(BuildContext context, String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'CONFIRMED':
        return l10n.purchaseStatusConfirmed;
      case 'DRAFT':
        return l10n.purchaseStatusDraft;
      case 'CANCELED':
        return l10n.purchaseStatusCanceled;
      default:
        return status;
    }
  }

  Future<void> _showCancelDialog(Purchase purchase) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    bool isCancelling = false;
    String? cancelError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.purchaseCancelTitle(purchase.purchaseNumber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.purchaseCancelWarning,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  if (cancelError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(cancelError!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                    ),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: l10n.purchaseCancelReasonLabel,
                      hintText: l10n.purchaseCancelReasonHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.commonBack),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: isCancelling
                      ? null
                      : () async {
                          setDialogState(() {
                            isCancelling = true;
                            cancelError = null;
                          });
                          try {
                            await _purchaseService.cancelPurchase(
                              purchase.id,
                              reason: reasonController.text.trim().isNotEmpty
                                  ? reasonController.text.trim()
                                  : null,
                            );
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.purchaseCancelSuccess)),
                              );
                              _loadPurchases();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isCancelling = false;
                              cancelError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.purchaseCancelButton, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.purchaseNumberTitle(purchase.purchaseNumber),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(purchase.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatStatus(context, purchase.status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.purchaseDetailSupplier(purchase.supplierName ?? '-'), style: const TextStyle(fontSize: 15)),
                  Text(l10n.purchaseDetailDate(AppFormatters.formatDateTime(purchase.purchaseDate.toLocal())), style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  if (purchase.notes != null) ...[
                    const SizedBox(height: 8),
                    Text('${l10n.commonNotes}: ${purchase.notes!}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                  const Divider(height: 32),
                  Text(l10n.purchaseDetailItems(purchase.items.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...purchase.items.map((item) {
                    final itemTotalCents = (item.totalPriceReais * 100).round();
                    final itemUnitCents = (item.unitPriceReais * 100).round();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item.packagingName != null
                              ? '${item.packagesCount} (${item.packagingName}) = ${AppFormatters.formatQuantity(item.quantityInBaseUnits, item.productBaseUnit)}'
                              : AppFormatters.formatQuantity(item.quantityInBaseUnits, item.productBaseUnit),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppFormatters.formatCurrency(itemTotalCents),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(l10n.purchaseDetailUnitCost(AppFormatters.formatCurrency(itemUnitCents)),
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.purchaseTotalCost, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        AppFormatters.formatCurrency((purchase.totalAmountReais * 100).round()),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchasesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadPurchases,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.purchaseNew),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormView()),
          );
          if (created == true) {
            _loadPurchases();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.purchaseSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadPurchases();
              },
            ),
          ),

          // Chips de filtro por status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.purchaseFilterAll),
                  selected: _statusFilter == null,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _statusFilter = null);
                      _loadPurchases();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.purchaseFilterConfirmed),
                  selected: _statusFilter == 'CONFIRMED',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'CONFIRMED' : null);
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.purchaseFilterDraft),
                  selected: _statusFilter == 'DRAFT',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'DRAFT' : null);
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.purchaseFilterCanceled),
                  selected: _statusFilter == 'CANCELED',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'CANCELED' : null);
                    _loadPurchases();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadPurchases, child: Text(l10n.commonRefresh)),
                          ],
                        ),
                      )
                    : _purchases.isEmpty
                        ? Center(child: Text(l10n.purchaseEmpty))
                        : RefreshIndicator(
                            onRefresh: _loadPurchases,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _purchases.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = _purchases[index];
                                final totalCents = (p.totalAmountReais * 100).round();
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () => _showPurchaseDetails(p),
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(p.status).withValues(alpha: 0.15),
                                      child: Text(
                                        '#${p.purchaseNumber}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _getStatusColor(p.status),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      p.supplierName ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(AppFormatters.formatDate(p.purchaseDate.toLocal())),
                                          Text(l10n.purchaseDetailItems(p.items.length)),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppFormatters.formatCurrency(totalCents),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (p.status == 'CONFIRMED') ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                            tooltip: l10n.purchaseCancelButton,
                                            onPressed: () => _showCancelDialog(p),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
