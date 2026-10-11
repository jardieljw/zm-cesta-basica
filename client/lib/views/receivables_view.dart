import 'package:flutter/material.dart';
import '../models/sales_receivable.dart';
import '../services/receivable_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class ReceivablesView extends StatefulWidget {
  const ReceivablesView({super.key});

  @override
  State<ReceivablesView> createState() => _ReceivablesViewState();
}

class _ReceivablesViewState extends State<ReceivablesView> {
  final ReceivableService _receivableService = ReceivableService();

  List<SalesReceivable> _receivables = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  bool _overdueOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReceivables();
  }

  Future<void> _loadReceivables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _receivableService.getReceivables(
        status: _statusFilter,
        overdueOnly: _overdueOnly,
      );
      setState(() {
        _receivables = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  int get _totalBalanceCents {
    int sum = 0;
    for (final r in _receivables) {
      if (r.status == 'OPEN' || r.status == 'PARTIAL') {
        sum += r.balanceCents;
      }
    }
    return sum;
  }

  int get _openCount => _receivables.where((r) => r.status == 'OPEN').length;
  int get _partialCount => _receivables.where((r) => r.status == 'PARTIAL').length;

  Future<void> _showPaymentDialog(SalesReceivable receivable) async {
    final l10n = context.l10n;
    final initialVal = (receivable.balanceCents / 100.0).toStringAsFixed(2).replaceAll('.', ',');
    final amountController = TextEditingController(text: initialVal);
    final notesController = TextEditingController();
    String paymentMethod = 'CASH';
    bool isSaving = false;
    String? payError;

    int parseToCents(String text) {
      final cleaned = text.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.').trim();
      final val = double.tryParse(cleaned) ?? 0.0;
      return (val * 100).round();
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.receivableRecordPayment),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (payError != null) ...[
                      Text(payError!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '${l10n.customerName}: ${receivable.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${l10n.receivableRemainingBalance}: ${AppFormatters.formatCurrency(receivable.balanceCents)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.receivablePaymentAmount,
                        prefixText: 'R\$ ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      decoration: InputDecoration(
                        labelText: l10n.receivablePaymentMethod,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'CASH', child: Text(l10n.salePaymentModeCash)),
                        DropdownMenuItem(value: 'PIX', child: Text(l10n.salePaymentModePix)),
                        DropdownMenuItem(value: 'CARD', child: Text(l10n.salePaymentModeCard)),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => paymentMethod = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: l10n.receivablePaymentNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final cents = parseToCents(amountController.text);
                          if (cents <= 0) {
                            setDialogState(() => payError = l10n.receivablePaymentAmountMustBePositive);
                            return;
                          }
                          if (cents > receivable.balanceCents) {
                            setDialogState(() => payError = l10n.receivablePaymentAmountExceedsBalance);
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            payError = null;
                          });

                          try {
                            await _receivableService.recordPayment(
                              receivable.id,
                              ReceivablePaymentCreate(
                                amountCents: cents,
                                paymentMethod: paymentMethod,
                                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                              ),
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.receivablePaymentSuccess)),
                              );
                              _loadReceivables();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              payError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.commonConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHistoryDialog(SalesReceivable receivable) async {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<SalesReceivable>(
        future: _receivableService.getReceivable(receivable.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AlertDialog(
              content: Text(ApiErrorMapper.toLocalizedMessage(snapshot.error, l10n)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonClose)),
              ],
            );
          }

          final detail = snapshot.data!;
          return AlertDialog(
            title: Text(l10n.receivablePaymentsHistory),
            content: SizedBox(
              width: 500,
              child: detail.payments.isEmpty
                  ? Center(child: Text(l10n.receivableNoPayments))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: detail.payments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = detail.payments[index];
                        final isConfirmed = p.status == 'CONFIRMED';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isConfirmed ? Icons.check_circle : Icons.cancel,
                            color: isConfirmed ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            AppFormatters.formatCurrency(p.amountCents),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isConfirmed ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            '${AppFormatters.formatDateTime(p.paymentDate)} via ${p.paymentMethod}${p.notes != null ? ' - ${p.notes}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonClose),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatStatus(BuildContext context, String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'OPEN':
        return l10n.receivableStatusOpen;
      case 'PARTIAL':
        return l10n.receivableStatusPartial;
      case 'PAID':
        return l10n.receivableStatusPaid;
      case 'CANCELED':
        return l10n.receivableStatusCanceled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receivablesTitle),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      DropdownMenuItem(value: 'OPEN', child: Text(l10n.receivableStatusOpen)),
                      DropdownMenuItem(value: 'PARTIAL', child: Text(l10n.receivableStatusPartial)),
                      DropdownMenuItem(value: 'PAID', child: Text(l10n.receivableStatusPaid)),
                    ],
                    onChanged: (val) {
                      setState(() => _statusFilter = val);
                      _loadReceivables();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(l10n.receivableOverdue),
                  selected: _overdueOnly,
                  onSelected: (val) {
                    setState(() => _overdueOnly = val);
                    _loadReceivables();
                  },
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
                              onPressed: _loadReceivables,
                              child: Text(l10n.commonRefresh),
                            ),
                          ],
                        ),
                      )
                    : _receivables.isEmpty
                        ? Center(child: Text(l10n.receivablesEmpty))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _receivables.length,
                            itemBuilder: (context, index) {
                              final r = _receivables[index];
                              return _buildReceivableCard(context, r);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            l10n.receivablesSummaryTotal,
            AppFormatters.formatCurrency(_totalBalanceCents),
            Colors.red.shade700,
          ),
          _buildSummaryItem(
            l10n.receivablesSummaryOpen,
            _openCount.toString(),
            Colors.orange.shade800,
          ),
          _buildSummaryItem(
            l10n.receivablesSummaryPartial,
            _partialCount.toString(),
            Colors.blue.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }

  Widget _buildReceivableCard(BuildContext context, SalesReceivable r) {
    final l10n = context.l10n;
    final isSettled = r.status == 'PAID';

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        l10n.receivableDueDateLabel(AppFormatters.formatDate(r.dueDate)),
                        style: TextStyle(
                          fontSize: 13,
                          color: r.isOverdue ? Colors.red.shade700 : Colors.black54,
                          fontWeight: r.isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(r.balanceCents),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isSettled ? Colors.green.shade700 : (r.isOverdue ? Colors.red.shade700 : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_formatStatus(context, r.status), style: const TextStyle(fontSize: 11)),
                  backgroundColor: isSettled ? Colors.green.shade50 : Colors.orange.shade50,
                ),
                if (r.isOverdue && !isSettled) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(l10n.receivableOverdue, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.red.shade700,
                  ),
                ],
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.receivableOriginalAmount}: ${AppFormatters.formatCurrency(r.originalAmountCents)} | ${l10n.receivablePaidAmount}: ${AppFormatters.formatCurrency(r.paidAmountCents)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Row(
                  children: [
                    if (r.paymentsCount > 0)
                      IconButton(
                        tooltip: l10n.receivablePaymentsHistory,
                        icon: const Icon(Icons.history, size: 20),
                        onPressed: () => _showHistoryDialog(r),
                      ),
                    if (!isSettled && r.status != 'CANCELED')
                      ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(r),
                        icon: const Icon(Icons.price_check, size: 16),
                        label: Text(l10n.receivableRecordPayment),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
