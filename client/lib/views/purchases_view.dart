import '../utils/adaptive_ui_color.dart';
import '../core/api_client.dart';
import '../widgets/shared/responsive_filter_bar.dart';
import '../utils/scroll_layout.dart';
import 'package:flutter/material.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'purchase_form_view.dart';
import '../widgets/shared/approved_app_style.dart';

class PurchasesView extends StatefulWidget {
  final ApiClient? apiClient;
  const PurchasesView({super.key, this.apiClient});

  @override
  State<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends State<PurchasesView> {
  late final PurchaseService _purchaseService;

  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _purchaseService = PurchaseService(client: widget.apiClient);
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

  String _formatPaymentMode(BuildContext context, String mode) {
    final l10n = context.l10n;
    switch (mode) {
      case 'CREDIT_TERM':
        return l10n.purchasePaymentStatusPending;
      case 'CASH_IMMEDIATE':
      default:
        return l10n.purchasePaymentStatusPaid;
    }
  }

  String _formatPaymentMethod(BuildContext context, String method) {
    final l10n = context.l10n;
    switch (method.toUpperCase()) {
      case 'BOLETO':
        return l10n.payablePaymentMethodBoleto;
      case 'PIX':
        return l10n.payablePaymentMethodPix;
      case 'TRANSFERENCIA':
        return l10n.payablePaymentMethodTransfer;
      case 'CHEQUE':
        return l10n.payablePaymentMethodCheck;
      case 'CARTAO_CREDITO':
        return l10n.payablePaymentMethodCard;
      case 'DINHEIRO':
        return l10n.payablePaymentMethodCash;
      default:
        return l10n.payablePaymentMethodOther;
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (cancelError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: adaptiveUiSurface(context, Colors.red.shade50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: adaptiveUiSurface(
                            context,
                            Colors.red.shade200,
                          ),
                        ),
                      ),
                      child: Text(
                        cancelError!,
                        style: TextStyle(
                          color: adaptiveUiText(context, Colors.red.shade800),
                          fontSize: 12,
                        ),
                      ),
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
                  onPressed: isCancelling
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.commonBack),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
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
                                SnackBar(
                                  content: Text(l10n.purchaseCancelSuccess),
                                ),
                              );
                              _loadPurchases();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isCancelling = false;
                              cancelError = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.purchaseCancelButton,
                          style: const TextStyle(color: Colors.white),
                        ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(purchase.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatStatus(context, purchase.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.purchaseDetailSupplier(purchase.supplierName ?? '-'),
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    l10n.purchaseDetailDate(
                      AppFormatters.formatDateTime(
                        purchase.purchaseDate.toLocal(),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        purchase.paymentMode == 'CREDIT_TERM'
                            ? Icons.schedule
                            : Icons.check_circle_outline,
                        size: 16,
                        color: purchase.paymentMode == 'CREDIT_TERM'
                            ? adaptiveUiText(context, Colors.orange.shade800)
                            : adaptiveUiText(context, Colors.green.shade800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.purchasePaymentDetailMethod(
                          _formatPaymentMethod(context, purchase.paymentMethod),
                          _formatPaymentMode(context, purchase.paymentMode),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: purchase.paymentMode == 'CREDIT_TERM'
                              ? adaptiveUiText(context, Colors.orange.shade900)
                              : adaptiveUiText(context, Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                  if (purchase.paymentMode == 'CREDIT_TERM' &&
                      purchase.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.purchasePaymentDetailDueDate(
                        AppFormatters.formatDate(purchase.dueDate!),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (purchase.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.commonNotes}: ${purchase.notes!}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  Text(
                    l10n.purchaseDetailItems(purchase.items.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...purchase.items.map((item) {
                    final itemTotalCents = (item.totalPriceReais * 100).round();
                    final itemUnitCents = (item.unitPriceReais * 100).round();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.packagingName != null
                              ? '${item.packagesCount} (${item.packagingName}) = ${AppFormatters.formatQuantity(item.quantityInBaseUnits, item.productBaseUnit)}'
                              : AppFormatters.formatQuantity(
                                  item.quantityInBaseUnits,
                                  item.productBaseUnit,
                                ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(itemTotalCents),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              l10n.purchaseDetailUnitCost(
                                AppFormatters.formatCurrency(itemUnitCents),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.purchaseTotalCost,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(
                          (purchase.totalAmountReais * 100).round(),
                        ),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: adaptiveUiText(context, Colors.green.shade800),
                        ),
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
    final pColors = AppPalette.of(context);

    return ApprovedPage(
      title: l10n.purchasesTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadPurchases,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        tooltip: l10n.purchaseNew,
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormView()),
          );
          if (created == true) {
            _loadPurchases();
          }
        },
        child: const Icon(Icons.add_shopping_cart),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.purchaseSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: pColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: pColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: pColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: pColors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadPurchases();
              },
            ),
          ),

          // Chips de filtro por status
          ResponsiveFilterBar(
            padding: EdgeInsets.zero,
            children: [
              FilterChip(
                shape: const StadiumBorder(),
                side: BorderSide(color: pColors.line),
                label: Text(l10n.purchaseFilterAll),
                selected: _statusFilter == null,
                onSelected: (val) {
                  if (val) {
                    setState(() => _statusFilter = null);
                    _loadPurchases();
                  }
                },
              ),
              FilterChip(
                shape: const StadiumBorder(),
                side: BorderSide(color: pColors.line),
                label: Text(l10n.purchaseFilterConfirmed),
                selected: _statusFilter == 'CONFIRMED',
                onSelected: (val) {
                  setState(() => _statusFilter = val ? 'CONFIRMED' : null);
                  _loadPurchases();
                },
              ),
              FilterChip(
                shape: const StadiumBorder(),
                side: BorderSide(color: pColors.line),
                label: Text(l10n.purchaseFilterDraft),
                selected: _statusFilter == 'DRAFT',
                onSelected: (val) {
                  setState(() => _statusFilter = val ? 'DRAFT' : null);
                  _loadPurchases();
                },
              ),
              FilterChip(
                shape: const StadiumBorder(),
                side: BorderSide(color: pColors.line),
                label: Text(l10n.purchaseFilterCanceled),
                selected: _statusFilter == 'CANCELED',
                onSelected: (val) {
                  setState(() => _statusFilter = val ? 'CANCELED' : null);
                  _loadPurchases();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPurchases,
                          child: Text(l10n.commonRefresh),
                        ),
                      ],
                    ),
                  )
                : _purchases.isEmpty
                ? Center(child: Text(l10n.purchaseEmpty))
                : RefreshIndicator(
                    onRefresh: _loadPurchases,
                    child: ListView.separated(
                      padding: fabScrollPadding(context, extended: false),
                      itemCount: _purchases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = _purchases[index];
                        final totalCents = (p.totalAmountReais * 100).round();
                        return Container(
                          decoration: BoxDecoration(
                            color: pColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: pColors.line),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _showPurchaseDetails(p),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(p.status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '#${p.purchaseNumber}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: _getStatusColor(p.status),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.supplierName ?? '-',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                AppFormatters.formatDate(p.purchaseDate.toLocal()),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: pColors.sub,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              AppFormatters.formatCurrency(totalCents),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 17,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(p.status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                _formatStatus(context, p.status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: _getStatusColor(p.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: pColors.soft,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            p.paymentMode == 'CREDIT_TERM'
                                                ? Icons.schedule
                                                : Icons.check_circle_outline,
                                            size: 15,
                                            color: p.paymentMode == 'CREDIT_TERM'
                                                ? Colors.orange.shade800
                                                : Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.purchasePaymentDetailMethod(
                                              _formatPaymentMethod(context, p.paymentMethod),
                                              _formatPaymentMode(context, p.paymentMode),
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: p.paymentMode == 'CREDIT_TERM'
                                                  ? Colors.orange.shade900
                                                  : Colors.green.shade900,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            l10n.purchaseDetailItems(p.items.length),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: pColors.sub,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (p.status == 'CONFIRMED') ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(999),
                                              onTap: () => _showCancelDialog(p),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(color: Colors.red.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.cancel_outlined, size: 14, color: Colors.red.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.purchaseCancelButton,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
