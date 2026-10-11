import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'sale_form_view.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final SaleService _saleService = SaleService();

  List<Sale> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  String? _paymentModeFilter;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _saleService.getSales(
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

  Future<void> _showCancelDialog(Sale sale) async {
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
              title: Text(l10n.saleCancelConfirm(sale.saleNumber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.saleCancelReason,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: cancelError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isCancelling
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
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
                            await _saleService.cancelSale(sale.id, reason);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.saleCanceledSuccess)),
                              );
                              _loadSales();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isCancelling = false;
                              cancelError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                            });
                          }
                        },
                  child: isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.saleCancel, style: const TextStyle(color: Colors.white)),
                ),
              ],
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
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  '${l10n.saleCustomer}: ${sale.customerName ?? l10n.saleCustomerAnonymous}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    Text(l10n.saleNetTotal, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      AppFormatters.formatCurrency(sale.totalAmountCents),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (sale.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(l10n.saleNotesPrefix(sale.notes!), style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SaleFormView()),
          );
          if (res == true) _loadSales();
        },
        icon: const Icon(Icons.point_of_sale),
        label: Text(l10n.saleNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      labelText: l10n.commonStatus,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                      DropdownMenuItem(value: 'CONFIRMED', child: Text(l10n.saleStatusConfirmed)),
                      DropdownMenuItem(value: 'CANCELED', child: Text(l10n.saleStatusCanceled)),
                    ],
                    onChanged: (val) {
                      setState(() => _statusFilter = val);
                      _loadSales();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _paymentModeFilter,
                    decoration: InputDecoration(
                      labelText: l10n.salePaymentMode,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                      DropdownMenuItem(value: 'CASH_IMMEDIATE', child: Text(l10n.salePaymentModeCash)),
                      DropdownMenuItem(value: 'PIX', child: Text(l10n.salePaymentModePix)),
                      DropdownMenuItem(value: 'CARD', child: Text(l10n.salePaymentModeCard)),
                      DropdownMenuItem(value: 'CREDIT_TERM', child: Text(l10n.salePaymentModeCredit)),
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
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadSales,
                              child: Text(l10n.commonRefresh),
                            ),
                          ],
                        ),
                      )
                    : _sales.isEmpty
                        ? Center(
                            child: Text(l10n.salesEmpty),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                            itemCount: _sales.length,
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
    final isConfirmed = sale.status == 'CONFIRMED';
    final isCredit = sale.paymentMode == 'CREDIT_TERM';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isConfirmed ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        isConfirmed ? Icons.shopping_bag : Icons.cancel,
                        color: isConfirmed ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.saleNumber(sale.saleNumber),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          AppFormatters.formatDateTime(sale.saleDate),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  AppFormatters.formatCurrency(sale.totalAmountCents),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isConfirmed ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sale.customerName ?? l10n.saleCustomerAnonymous,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(_formatPaymentMode(context, sale.paymentMode), style: const TextStyle(fontSize: 11)),
                  backgroundColor: isCredit ? Colors.orange.shade50 : Colors.blue.shade50,
                ),
                if (isConfirmed)
                  Chip(
                    label: Text(
                      sale.paymentStatus == 'PAID'
                          ? l10n.salePaymentStatusPaid
                          : (sale.paymentStatus == 'PARTIAL' ? l10n.salePaymentStatusPartial : l10n.salePaymentStatusPending),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: sale.paymentStatus == 'PAID'
                        ? Colors.green.shade50
                        : Colors.orange.shade100,
                  ),
                if (!isConfirmed)
                  Chip(
                    label: Text(l10n.saleStatusCanceled, style: const TextStyle(fontSize: 11, color: Colors.red)),
                    backgroundColor: Colors.red.shade50,
                  ),
              ],
            ),
            const Divider(height: 20),
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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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
