import '../utils/adaptive_ui_color.dart';
import '../core/api_client.dart';
import '../widgets/shared/responsive_filter_bar.dart';
import 'package:flutter/material.dart';
import '../models/sales_receivable.dart';
import '../services/receivable_service.dart';
import '../services/receivable_payment_coordinator.dart';
import '../widgets/shared/financial_surface.dart';
import '../widgets/shared/approved_app_style.dart';
import '../utils/money_input.dart';
import 'receivable_payment_view.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class ReceivablesView extends StatefulWidget {
  final ApiClient? apiClient;
  final ReceivableService? service;
  final ReceivablePaymentCoordinator? paymentCoordinator;
  const ReceivablesView({
    super.key,
    this.apiClient,
    this.service,
    this.paymentCoordinator,
  });

  @override
  State<ReceivablesView> createState() => _ReceivablesViewState();
}

class _ReceivablesViewState extends State<ReceivablesView> {
  late final ReceivableService _receivableService;
  late final ReceivablePaymentCoordinator _paymentCoordinator;
  List<ReceivablePaymentAttempt> _pendingPayments = [];
  int _requestVersion = 0, _pendingVersion = 0, _nextOffset = 0;
  bool _pendingReadFailed = false, _hasMore = false, _loadingMore = false;
  String? _moreError, _appliedScope;
  Future<List<SalesReceivable>> Function(int)? _fetchPage;

  List<SalesReceivable> _receivables = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  bool _overdueOnly = false;
  bool _showAdvancedFilters = false;

  DateTime? _saleDateFrom;
  DateTime? _saleDateTo;
  DateTime? _dueDateFrom;
  DateTime? _dueDateTo;
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _basketTypeController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _receivableService =
        widget.service ?? ReceivableService(client: widget.apiClient);
    _paymentCoordinator =
        widget.paymentCoordinator ??
        ReceivablePaymentCoordinator(service: _receivableService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReceivables();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _basketTypeController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    if (widget.paymentCoordinator == null) _paymentCoordinator.dispose();
    if (widget.service == null && widget.apiClient == null) {
      _receivableService.close();
    }
    super.dispose();
  }

  Future<void> _loadReceivables() async {
    if (!mounted) return;
    final version = ++_requestVersion;
    _loadPendingPayments();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingMore = false;
      _moreError = null;
      _hasMore = false;
    });
    try {
      final minText = _minAmountController.text.trim();
      final maxText = _maxAmountController.text.trim();
      final min = minText.isEmpty ? null : MoneyInput.cents(minText);
      final max = maxText.isEmpty ? null : MoneyInput.cents(maxText);
      if ((minText.isNotEmpty && min == null) ||
          (maxText.isNotEmpty && max == null) ||
          (min != null && max != null && min > max)) {
        throw ApiException(
          statusCode: 422,
          message: 'Invalid amount filter',
          errorCode: 'VALIDATION_ERROR',
        );
      }
      // Freeze the applied query. Editing a field does not change subsequent pages
      // until Apply is chosen, and old responses cannot replace a newer query.
      final status = _statusFilter, overdue = _overdueOnly;
      final customer = _customerController.text.trim(),
          basket = _basketTypeController.text.trim();
      final saleFrom = _saleDateFrom, saleTo = _saleDateTo;
      final dueFrom = _dueDateFrom, dueTo = _dueDateTo;
      Future<List<SalesReceivable>> fetch(int offset) =>
          _receivableService.getReceivables(
            status: status == 'UNPAID' ? null : status,
            openOnly: status == 'UNPAID',
            overdueOnly: overdue,
            customerId: customer.isEmpty ? null : customer,
            basketTypeId: basket.isEmpty ? null : basket,
            saleDateFrom: saleFrom,
            saleDateTo: saleTo,
            dueDateFrom: dueFrom,
            dueDateTo: dueTo,
            minAmountCents: min,
            maxAmountCents: max,
            limit: 100,
            offset: offset,
          );
      final scope = _filterScope(
        additional:
            customer.isNotEmpty ||
            basket.isNotEmpty ||
            saleFrom != null ||
            saleTo != null ||
            dueFrom != null ||
            dueTo != null ||
            min != null ||
            max != null,
      );
      final items = await fetch(0);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _receivables = items;
        _fetchPage = fetch;
        _nextOffset = items.length;
        _hasMore = items.length == 100;
        _isLoading = false;
        _appliedScope = scope;
      });
    } catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _fetchPage == null) return;
    final version = _requestVersion;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final items = await _fetchPage!(_nextOffset);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        final ids = _receivables.map((item) => item.id).toSet();
        _receivables.addAll(items.where((item) => ids.add(item.id)));
        _nextOffset += items.length;
        _hasMore = items.length == 100;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted && version == _requestVersion) {
        setState(() {
          _loadingMore = false;
          _moreError = context.l10n.paymentFlowMoreFailed;
        });
      }
    }
  }

  Future<void> _loadPendingPayments() async {
    final version = ++_pendingVersion;
    try {
      final pending = await _paymentCoordinator.pending();
      if (mounted && version == _pendingVersion) {
        setState(() {
          _pendingPayments = pending;
          _pendingReadFailed = false;
        });
      }
    } catch (_) {
      if (mounted && version == _pendingVersion) {
        setState(() => _pendingReadFailed = true);
      }
    }
  }

  String _filterScope({bool additional = false}) {
    final l = context.l10n;
    final status = _statusFilter == null
        ? l.receiptFlowFilterAll
        : _statusFilter == 'UNPAID'
        ? l.receiptFlowFilterOpen
        : _formatStatus(context, _statusFilter!);
    return l.receiptFlowFilterScope(
          status,
          _overdueOnly ? l.receivableOverdue : l.receiptFlowFilterAnyDue,
        ) +
        (additional ? ' · ${l.receiptFlowFilterApplied}' : '');
  }

  Future<void> _openPayment(String id) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceivablePaymentView(
          receivableId: id,
          coordinator: _paymentCoordinator,
        ),
      ),
    );
    if (mounted) await _loadReceivables();
  }

  Widget _pendingSection() {
    final l = context.l10n;
    if (_pendingPayments.isEmpty && !_pendingReadFailed) {
      return const SizedBox.shrink();
    }
    return FinancialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.paymentFlowPendingTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_pendingReadFailed) ...[
            Text(l.paymentFlowPendingReadError),
            TextButton(
              onPressed: _loadPendingPayments,
              child: Text(l.commonRefresh),
            ),
          ],
          for (final attempt in _pendingPayments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                attempt.confirmation == null
                    ? Icons.sync
                    : Icons.check_circle_outline,
              ),
              title: Text(
                l.receiptFlowPendingItem(
                  attempt.customerName,
                  attempt.saleNumber,
                ),
              ),
              subtitle: Text(
                attempt.confirmation == null
                    ? l.paymentFlowUncertain
                    : l.receiptFlowConfirmed,
              ),
              onTap: () => _openPayment(attempt.receivableId),
            ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _overdueOnly = false;
      _saleDateFrom = null;
      _saleDateTo = null;
      _dueDateFrom = null;
      _dueDateTo = null;
      _customerController.clear();
      _basketTypeController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    _loadReceivables();
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
  int get _partialCount =>
      _receivables.where((r) => r.status == 'PARTIAL').length;

  Widget _buildRepassBadge(BuildContext context, ReceivablePayment p) {
    final l10n = context.l10n;
    Color bg;
    Color fg;
    String text;

    switch (p.repassStatus) {
      case 'PENDING_REPASS':
        bg = adaptiveUiSurface(context, Colors.orange.shade100);
        fg = Colors.orange.shade900;
        text = l10n.receivableRepassPending;
        break;
      case 'REPASSED':
        bg = adaptiveUiSurface(context, Colors.blue.shade100);
        fg = Colors.blue.shade900;
        text = l10n.receivableRepassDone;
        break;
      default:
        bg = adaptiveUiSurface(context, Colors.green.shade100);
        fg = Colors.green.shade900;
        text = l10n.receivableRepassDirect;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showHistoryDialog(SalesReceivable receivable) async {
    final l10n = context.l10n;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<SalesReceivable>(
            future: _receivableService.getReceivable(receivable.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return AlertDialog(
                  content: Text(
                    ApiErrorMapper.toLocalizedMessage(snapshot.error, l10n),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.commonClose),
                    ),
                  ],
                );
              }

              final detail = snapshot.data!;
              return AlertDialog(
                title: Text(l10n.receivablePaymentsHistory),
                content: SizedBox(
                  width: 520,
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
                              title: Row(
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(p.amountCents),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: isConfirmed
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildRepassBadge(context, p),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppFormatters.formatDateTime(p.paymentDate)} · ${p.paymentMethod}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (!isConfirmed && p.reversalReason != null)
                                    Text(
                                      l10n.receiptFlowReversalReason(
                                        p.reversalReason!,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    ),
                                  if (p.notes != null)
                                    Text(
                                      p.notes!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isConfirmed
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.undo,
                                        color: Colors.orange,
                                      ),
                                      tooltip: l10n.receivableReversePayment,
                                      onPressed: () async {
                                        final reasonCtrl =
                                            TextEditingController();
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            title: Text(
                                              l10n.receivableReversePayment,
                                            ),
                                            content: TextField(
                                              controller: reasonCtrl,
                                              decoration: InputDecoration(
                                                labelText: l10n
                                                    .receivableReverseReason,
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(dCtx, false),
                                                child: Text(l10n.commonCancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(dCtx, true),
                                                child: Text(l10n.commonConfirm),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true &&
                                            reasonCtrl.text.trim().isNotEmpty) {
                                          try {
                                            await _receivableService
                                                .cancelPayment(
                                                  p.id,
                                                  reasonCtrl.text.trim(),
                                                );
                                            setDialogState(() {});
                                            _loadReceivables();
                                          } catch (err) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    ApiErrorMapper.toLocalizedMessage(
                                                      err,
                                                      l10n,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    )
                                  : null,
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
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveFilterBar(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.commonStatus,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.categoryAll),
                    ),
                    DropdownMenuItem(
                      value: 'UNPAID',
                      child: Text(l10n.receiptFlowFilterOpen),
                    ),
                    DropdownMenuItem(
                      value: 'PARTIAL',
                      child: Text(l10n.receivableStatusPartial),
                    ),
                    DropdownMenuItem(
                      value: 'PAID',
                      child: Text(l10n.receivableStatusPaid),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELED',
                      child: Text(l10n.receivableStatusCanceled),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _statusFilter = val);
                    _loadReceivables();
                  },
                ),
              ),
              FilterChip(
                label: Text(l10n.receivableOverdue),
                selected: _overdueOnly,
                onSelected: (val) {
                  setState(() => _overdueOnly = val);
                  _loadReceivables();
                },
              ),
              FilterChip(
                avatar: Icon(
                  _showAdvancedFilters ? Icons.expand_less : Icons.tune,
                  size: 16,
                ),
                label: Text(
                  _showAdvancedFilters
                      ? l10n.receivableFilterHideAdvanced
                      : l10n.receivableFilterAdvanced,
                ),
                selected: _showAdvancedFilters,
                onSelected: (val) {
                  setState(() => _showAdvancedFilters = val);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                onPressed: _loadReceivables,
              ),
            ],
          ),
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: adaptiveUiSurface(context, Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          _saleDateFrom != null && _saleDateTo != null
                              ? '${AppFormatters.formatDate(_saleDateFrom!)} - ${AppFormatters.formatDate(_saleDateTo!)}'
                              : l10n.receivableFilterPeriod,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDateRange:
                                _saleDateFrom != null && _saleDateTo != null
                                ? DateTimeRange(
                                    start: _saleDateFrom!,
                                    end: _saleDateTo!,
                                  )
                                : null,
                          );
                          if (range != null) {
                            setState(() {
                              _saleDateFrom = range.start;
                              _saleDateTo = range.end;
                            });
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event_available, size: 16),
                        label: Text(
                          _dueDateFrom != null && _dueDateTo != null
                              ? '${AppFormatters.formatDate(_dueDateFrom!)} - ${AppFormatters.formatDate(_dueDateTo!)}'
                              : l10n.receivableFilterDuePeriod,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDateRange:
                                _dueDateFrom != null && _dueDateTo != null
                                ? DateTimeRange(
                                    start: _dueDateFrom!,
                                    end: _dueDateTo!,
                                  )
                                : null,
                          );
                          if (range != null) {
                            setState(() {
                              _dueDateFrom = range.start;
                              _dueDateTo = range.end;
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _customerController,
                          decoration: InputDecoration(
                            labelText: l10n.receivableFilterCustomer,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _loadReceivables(),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _basketTypeController,
                          decoration: InputDecoration(
                            labelText: l10n.receivableFilterBasketType,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _loadReceivables(),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _minAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.receivableFilterMinValue,
                            prefixText: 'R\$ ',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _loadReceivables(),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _maxAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.receivableFilterMaxValue,
                            prefixText: 'R\$ ',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _loadReceivables(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: Text(l10n.receivableFilterClear),
                        onPressed: _clearFilters,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search, size: 16),
                        label: Text(l10n.receivableFilterApply),
                        onPressed: _loadReceivables,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
    final l = context.l10n;
    return FinancialJourneyTheme(
      child: ApprovedPage(
        title: l.receivablesTitle,
        body: ListView(
          key: const PageStorageKey('receivables-list'),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isLoading && _errorMessage == null) ...[
                      _buildSummaryHeader(context),
                      const SizedBox(height: 20),
                    ],
                    FinancialSurface(
                      child: ExpansionTile(
                        key: const ValueKey('receipt-filters'),
                        maintainState: true,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(l.receiptFlowFilters),
                        subtitle: Text(_appliedScope ?? _filterScope()),
                        children: [_buildFilterBar(context)],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _pendingSection(),
                    if (_pendingPayments.isNotEmpty || _pendingReadFailed)
                      const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage != null)
                      FinancialSurface(
                        child: Column(
                          children: [
                            Text(_errorMessage!),
                            TextButton(
                              onPressed: _loadReceivables,
                              child: Text(l.commonRefresh),
                            ),
                          ],
                        ),
                      )
                    else if (_receivables.isEmpty)
                      FinancialSurface(child: Text(l.receivablesEmpty))
                    else
                      FinancialSurface(
                        child: Column(
                          children: [
                            for (var i = 0; i < _receivables.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              _buildReceivableCard(context, _receivables[i]),
                            ],
                          ],
                        ),
                      ),
                    if (_moreError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_moreError!),
                      ),
                    if (_hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: OutlinedButton(
                          onPressed: _loadingMore ? null : _loadMore,
                          child: Text(
                            _loadingMore ? l.commonLoading : l.paymentFlowMore,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final l = context.l10n;
    return FinancialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.receiptFlowSummary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              _buildSummaryItem(
                l.receivablesSummaryTotal,
                AppFormatters.formatCurrency(_totalBalanceCents),
              ),
              _buildSummaryItem(
                l.receivablesSummaryOpen,
                _openCount.toString(),
              ),
              _buildSummaryItem(
                l.receivablesSummaryPartial,
                _partialCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    ],
  );

  Widget _buildReceivableCard(BuildContext context, SalesReceivable r) {
    final l = context.l10n, theme = Theme.of(context);
    final isOpen = {'OPEN', 'PARTIAL'}.contains(r.status) && r.balanceCents > 0;
    final overdue = r.isOverdue && isOpen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openPayment(r.id),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 480 ||
                    MediaQuery.textScalerOf(context).scale(16) > 22;
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(l.receiptFlowSaleRef(r.saleNumber)),
                    if (r.basketTypesSummary?.isNotEmpty == true)
                      Text(
                        r.basketTypesSummary!,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                );
                final amount = Text(
                  AppFormatters.formatCurrency(r.balanceCents),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [identity, const SizedBox(height: 8), amount],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: identity),
                          const SizedBox(width: 20),
                          amount,
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.receivableDueDateLabel(AppFormatters.formatDate(r.dueDate)),
            style: theme.textTheme.bodyMedium,
          ),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '${l.receivableOriginalAmount}: ${AppFormatters.formatCurrency(r.originalAmountCents)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${l.receiptFlowReceived}: ${AppFormatters.formatCurrency(r.paidAmountCents)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: overdue
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  '${_formatStatus(context, r.status)}${overdue ? ' · ${l.receivableOverdue}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overdue
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openPayment(r.id),
                child: Text(
                  isOpen ? l.receiptFlowRegister : l.receiptFlowDetail,
                ),
              ),
              if (r.paymentsCount > 0)
                IconButton(
                  tooltip: l.receivablePaymentsHistory,
                  icon: const Icon(Icons.history_outlined),
                  onPressed: () => _showHistoryDialog(r),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
