import '../widgets/shared/responsive_filter_bar.dart';
import '../utils/scroll_layout.dart';
import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../core/api_client.dart';
import '../services/sale_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'sale_form_view.dart';
import 'receivable_payment_view.dart';
import '../services/receivable_payment_coordinator.dart';
import '../services/receivable_service.dart';
import '../widgets/shared/approved_app_style.dart';

class SalesView extends StatefulWidget {
  final ApiClient? apiClient;
  final String? initialSaleId;
  const SalesView({super.key, this.apiClient, this.initialSaleId});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  late final SaleService _saleService;

  List<Sale> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  String? _paymentModeFilter;

  @override
  void initState() {
    super.initState();
    _saleService = SaleService(client: widget.apiClient);
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = widget.initialSaleId != null
          ? [await _saleService.getSale(widget.initialSaleId!)]
          : await _saleService.getSales(
              status: _statusFilter,
              paymentMode: _paymentModeFilter,
            );
      setState(() {
        _sales = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _showReceipts(Sale sale) async {
    final coordinator = ReceivablePaymentCoordinator(
      service: ReceivableService(client: widget.apiClient),
    );
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceivablePaymentView(
            receivableId: sale.receivableId!,
            coordinator: coordinator,
          ),
        ),
      );
    } finally {
      coordinator.dispose();
    }
    if (mounted) await _loadSales();
  }

  Future<void> _showCancelDialog(Sale sale) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    bool isCancelling = false;
    bool receiptBlocked = false;
    String? cancelError;
    final assemblyChoices = <String, bool?>{
      for (final item in sale.items.where((it) => it.assembledOnDemand))
        item.id: null,
    };

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !isCancelling,
              child: AlertDialog(
                title: Text(l10n.saleCancelConfirm(sale.saleNumber)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${sale.customerName ?? l10n.saleCustomerAnonymous} · ${AppFormatters.formatDate(sale.saleDate)}',
                      ),
                      const SizedBox(height: 12),
                      if (sale.receivableId != null &&
                          (receiptBlocked ||
                              [
                                'PAID',
                                'PARTIAL',
                              ].contains(sale.receivableStatus))) ...[
                        Text(l10n.catalogReceiptHelp),
                        TextButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          onPressed: isCancelling
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await _showReceipts(sale);
                                },
                          label: Text(l10n.catalogViewReceipts),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (assemblyChoices.isNotEmpty) ...[
                        Text(l10n.saleCancelAssemblyHelp),
                        const SizedBox(height: 12),
                        for (final item in sale.items.where(
                          (it) => assemblyChoices.containsKey(it.id),
                        )) ...[
                          Text(
                            '${item.basketTypeName ?? item.basketTypeId} (${item.quantity})',
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<bool>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.saleCancelAssemblyQuestion,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: false,
                                child: Text(
                                  l10n.saleCancelKeepBaskets,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text(
                                  l10n.saleCancelReturnIngredients,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: isCancelling
                                ? null
                                : (value) => setDialogState(
                                    () => assemblyChoices[item.id] = value,
                                  ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                      Text(
                        l10n.saleCancelReason,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        enabled: !isCancelling,
                        controller: reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (cancelError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            cancelError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isCancelling ? null : () => Navigator.pop(ctx),
                    child: Text(l10n.commonCancel),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: isCancelling
                        ? null
                        : () async {
                            final reason = reasonController.text.trim();
                            if (assemblyChoices.values.any(
                              (value) => value == null,
                            )) {
                              setDialogState(
                                () => cancelError =
                                    l10n.saleCancelAssemblyRequired,
                              );
                              return;
                            }
                            if (reason.length < 3) {
                              setDialogState(() {
                                cancelError = l10n.commonRequired;
                              });
                              return;
                            }

                            setDialogState(() {
                              isCancelling = true;
                              cancelError = null;
                            });

                            try {
                              await _saleService.cancelSale(
                                sale.id,
                                reason,
                                unassembledItemIds: assemblyChoices.entries
                                    .where((e) => e.value == true)
                                    .map((e) => e.key)
                                    .toList(),
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.saleCanceledSuccess),
                                  ),
                                );
                                _loadSales();
                              }
                            } catch (e) {
                              setDialogState(() {
                                isCancelling = false;
                                receiptBlocked =
                                    e is ApiException &&
                                    e.errorCode == 'SALE_HAS_RECEIPTS';
                                cancelError = ApiErrorMapper.toLocalizedMessage(
                                  e,
                                  l10n,
                                );
                              });
                            }
                          },
                    child: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.saleCancel,
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailDialog(Sale sale) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saleNumber(sale.saleNumber)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.saleDate}: ${AppFormatters.formatDateTime(sale.saleDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${l10n.saleCustomer}: ${sale.customerName ?? l10n.saleCustomerAnonymous}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 20),
                ...sale.items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${it.quantity}x ${it.basketTypeName ?? it.basketTypeId}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(it.totalCents),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.saleNetTotal,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppFormatters.formatCurrency(sale.totalAmountCents),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (sale.totalCostCents > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.saleCmvAndMargin(
                      AppFormatters.formatCurrency(sale.totalCostCents),
                      AppFormatters.formatCurrency(sale.grossMarginCents),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (sale.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.saleNotesPrefix(sale.notes!),
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMode(BuildContext context, String mode) {
    final l10n = context.l10n;
    switch (mode) {
      case 'CASH_IMMEDIATE':
        return l10n.salePaymentModeCash;
      case 'PIX':
        return l10n.salePaymentModePix;
      case 'CARD':
        return l10n.salePaymentModeCard;
      case 'CREDIT_TERM':
        return l10n.salePaymentModeCredit;
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);

    return ApprovedPage(
      title: l10n.salesTitle,
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SaleFormView()),
          );
          if (res == true) _loadSales();
        },
        tooltip: l10n.saleNew,
        child: const Icon(Icons.point_of_sale),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ResponsiveFilterBar(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      labelText: l10n.commonStatus,
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
                        borderSide: BorderSide(
                          color: pColors.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.categoryAll),
                      ),
                      DropdownMenuItem(
                        value: 'CONFIRMED',
                        child: Text(l10n.saleStatusConfirmed),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELED',
                        child: Text(l10n.saleStatusCanceled),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _statusFilter = val);
                      _loadSales();
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _paymentModeFilter,
                    decoration: InputDecoration(
                      labelText: l10n.salePaymentMode,
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
                        borderSide: BorderSide(
                          color: pColors.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.categoryAll),
                      ),
                      DropdownMenuItem(
                        value: 'CASH_IMMEDIATE',
                        child: Text(l10n.salePaymentModeCash),
                      ),
                      DropdownMenuItem(
                        value: 'PIX',
                        child: Text(l10n.salePaymentModePix),
                      ),
                      DropdownMenuItem(
                        value: 'CARD',
                        child: Text(l10n.salePaymentModeCard),
                      ),
                      DropdownMenuItem(
                        value: 'CREDIT_TERM',
                        child: Text(l10n.salePaymentModeCredit),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _paymentModeFilter = val);
                      _loadSales();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadSales,
                          child: Text(l10n.commonRefresh),
                        ),
                      ],
                    ),
                  )
                : _sales.isEmpty
                ? Center(child: Text(l10n.salesEmpty))
                : ListView.separated(
                    padding: fabScrollPadding(context, top: 0, extended: false),
                    itemCount: _sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return _buildSaleCard(context, sale);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, Sale sale) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);
    final isConfirmed = sale.status == 'CONFIRMED';
    final isCredit = sale.paymentMode == 'CREDIT_TERM';

    return Container(
      decoration: BoxDecoration(
        color: pColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isConfirmed ? Icons.shopping_bag : Icons.cancel,
                        color: isConfirmed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.saleNumber(sale.saleNumber),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTime(sale.saleDate),
                          style: TextStyle(fontSize: 12, color: pColors.sub),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  AppFormatters.formatCurrency(sale.totalAmountCents),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: isConfirmed ? pColors.ink : pColors.sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: pColors.sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sale.customerName ?? l10n.saleCustomerAnonymous,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: pColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatPaymentMode(context, sale.paymentMode),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCredit
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                if (isConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sale.paymentStatus == 'PAID'
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sale.paymentStatus == 'PAID'
                          ? l10n.salePaymentStatusPaid
                          : (sale.paymentStatus == 'PARTIAL'
                                ? l10n.salePaymentStatusPartial
                                : l10n.salePaymentStatusPending),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sale.paymentStatus == 'PAID'
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                if (!isConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.saleStatusCanceled,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showDetailDialog(sale),
                  child: Text(l10n.commonViewDetails),
                ),
                if (isConfirmed) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    onPressed: () => _showCancelDialog(sale),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text(l10n.saleCancel),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
