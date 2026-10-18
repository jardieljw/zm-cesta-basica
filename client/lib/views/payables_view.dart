import '../utils/scroll_layout.dart';
import '../widgets/payables/payable_filters_panel.dart';
import '../widgets/shared/financial_summary_panel.dart';
import '../widgets/shared/approved_app_style.dart';
import 'package:flutter/material.dart';
import '../models/account_payable.dart';
import '../services/payable_service.dart';
import '../services/payable_payment_coordinator.dart';
import 'payable_payment_view.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class PayablesView extends StatefulWidget {
  const PayablesView({super.key, this.service, this.paymentCoordinator});
  final PayableService? service;
  final PayablePaymentCoordinator? paymentCoordinator;

  @override
  State<PayablesView> createState() => _PayablesViewState();
}

class _PayablesViewState extends State<PayablesView> {
  late final PayableService _payableService;
  int _requestVersion = 0, _pendingVersion = 0, _nextOffset = 0;
  late final PayablePaymentCoordinator _paymentCoordinator;
  List<PayablePaymentAttempt> _pendingPayments = [];
  bool _pendingReadFailed = false, _hasMore = false, _loadingMore = false;
  String? _moreError;
  String? _beneficiaryFilter;

  List<AccountPayable> _payables = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _statusFilter;
  String? _categoryFilter;
  String? _natureFilter;
  bool _overdueOnly = false;
  final TextEditingController _beneficiaryController = TextEditingController();
  int? _monthFilter;
  int? _yearFilter;
  DateTime? _dueDateFrom;
  DateTime? _dueDateTo;

  @override
  void initState() {
    super.initState();
    _payableService = widget.service ?? PayableService();
    _paymentCoordinator =
        widget.paymentCoordinator ??
        PayablePaymentCoordinator(service: _payableService);
    _loadPayables();
  }

  @override
  void dispose() {
    _beneficiaryController.dispose();
    if (widget.paymentCoordinator == null) _paymentCoordinator.dispose();
    if (widget.service == null) _payableService.close();
    super.dispose();
  }

  Future<void> _loadPayables() async {
    if (!mounted) return;
    final requestVersion = ++_requestVersion;
    _loadPendingPayments();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingMore = false;
      _moreError = null;
      _hasMore = false;
    });

    try {
      final items = await _fetchPayables();
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _payables = items;
        _nextOffset = items.length;
        _hasMore = items.length == 100;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<List<AccountPayable>> _fetchPayables({int offset = 0}) =>
      _payableService.getPayables(
        dueDateFrom: _dueDateFrom,
        dueDateTo: _dueDateTo,
        status: _statusFilter,
        category: _categoryFilter,
        nature: _natureFilter,
        beneficiary: _beneficiaryFilter,
        overdueOnly: _overdueOnly,
        month: _monthFilter,
        year: _yearFilter,
        limit: 100,
        offset: offset,
      );

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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final version = _requestVersion;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final items = await _fetchPayables(offset: _nextOffset);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        final ids = _payables.map((p) => p.id).toSet();
        _payables.addAll(items.where((p) => ids.add(p.id)));
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

  Future<void> _openPayment(String id) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PayablePaymentView(payableId: id, coordinator: _paymentCoordinator),
      ),
    );
    if (mounted) await _loadPayables();
  }

  Widget _pendingSection() {
    if (_pendingPayments.isEmpty && !_pendingReadFailed) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ApprovedSurface(
        padding: const EdgeInsets.all(18),
        radius: 24,
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
                  l.paymentFlowPendingItem(
                    attempt.beneficiary,
                    attempt.payableNumber,
                  ),
                ),
                subtitle: Text(
                  attempt.confirmation == null
                      ? l.paymentFlowUncertain
                      : l.paymentFlowConfirmed,
                ),
                onTap: () => _openPayment(attempt.payableId),
              ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _categoryFilter = null;
      _natureFilter = null;
      _overdueOnly = false;
      _beneficiaryController.clear();
      _beneficiaryFilter = null;
      _monthFilter = null;
      _yearFilter = null;
      _dueDateFrom = null;
      _dueDateTo = null;
    });
    _loadPayables();
  }

  Future<void> _generateNextRecurrence(AccountPayable payable) async {
    final l10n = context.l10n;
    try {
      await _payableService.generateNextRecurrence(payable.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.payableRecurrenceSuccess)));
        _loadPayables();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
        );
      }
    }
  }

  int get _totalOpenCents {
    int sum = 0;
    for (final p in _payables) {
      if (p.status == 'OPEN' || p.status == 'PARTIAL') {
        sum += p.balanceCents;
      }
    }
    return sum;
  }

  int get _overdueCents {
    int sum = 0;
    for (final p in _payables) {
      if (p.isOverdue) {
        sum += p.balanceCents;
      }
    }
    return sum;
  }

  int get _paidCents {
    int sum = 0;
    for (final p in _payables) {
      sum += p.paidAmountCents;
    }
    return sum;
  }

  int _parseToCents(String text) {
    final cleaned = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final val = double.tryParse(cleaned) ?? 0.0;
    return (val * 100).round();
  }

  Future<void> _showCreatePayableDialog() async {
    final l10n = context.l10n;
    final descController = TextEditingController();
    final benController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final installmentsController = TextEditingController(text: '1');
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));
    String category = 'FORNECEDOR';
    String nature = 'BUSINESS';
    String paymentMethod = 'BOLETO';
    bool isRecurrent = false;
    String recurrencePeriod = 'MONTHLY';
    bool isSaving = false;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.payablesNew),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (formError != null) ...[
                        Text(
                          formError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: l10n.payableDescription,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: benController,
                        decoration: InputDecoration(
                          labelText: l10n.payableBeneficiary,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: InputDecoration(
                                labelText: l10n.payableCategory,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'FORNECEDOR',
                                  child: Text(l10n.payableCategorySupplier),
                                ),
                                DropdownMenuItem(
                                  value: 'ENERGIA',
                                  child: Text(l10n.payableCategoryElectricity),
                                ),
                                DropdownMenuItem(
                                  value: 'ALUGUEL',
                                  child: Text(l10n.payableCategoryRent),
                                ),
                                DropdownMenuItem(
                                  value: 'FRETE',
                                  child: Text(l10n.payableCategoryFreight),
                                ),
                                DropdownMenuItem(
                                  value: 'MANUTENCAO',
                                  child: Text(l10n.payableCategoryMaintenance),
                                ),
                                DropdownMenuItem(
                                  value: 'EMPRESTIMO',
                                  child: Text(l10n.payableCategoryLoan),
                                ),
                                DropdownMenuItem(
                                  value: 'CARTAO_CREDITO',
                                  child: Text(l10n.payableCategoryCreditCard),
                                ),
                                DropdownMenuItem(
                                  value: 'RETIRADA_SOCIO',
                                  child: Text(
                                    l10n.payableCategoryPartnerWithdrawal,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'IMPOSTO',
                                  child: Text(l10n.payableCategoryTaxes),
                                ),
                                DropdownMenuItem(
                                  value: 'OUTROS',
                                  child: Text(l10n.payableCategoryOthers),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => category = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: nature,
                              decoration: InputDecoration(
                                labelText: l10n.payableNature,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'BUSINESS',
                                  child: Text(l10n.payableNatureBusiness),
                                ),
                                DropdownMenuItem(
                                  value: 'PERSONAL_WITHDRAWAL',
                                  child: Text(l10n.payableNaturePersonal),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => nature = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.payableOriginalAmount,
                                prefixText: 'R\$ ',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentMethod,
                              decoration: InputDecoration(
                                labelText: l10n.payablePaymentMethod,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'BOLETO',
                                  child: Text(l10n.payablePaymentMethodBoleto),
                                ),
                                DropdownMenuItem(
                                  value: 'PIX',
                                  child: Text(l10n.payablePaymentMethodPix),
                                ),
                                DropdownMenuItem(
                                  value: 'TRANSFERENCIA',
                                  child: Text(
                                    l10n.payablePaymentMethodTransfer,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'CHEQUE',
                                  child: Text(l10n.payablePaymentMethodCheck),
                                ),
                                DropdownMenuItem(
                                  value: 'CARTAO_CREDITO',
                                  child: Text(l10n.payablePaymentMethodCard),
                                ),
                                DropdownMenuItem(
                                  value: 'DINHEIRO',
                                  child: Text(l10n.payablePaymentMethodCash),
                                ),
                                DropdownMenuItem(
                                  value: 'OUTRO',
                                  child: Text(l10n.payablePaymentMethodOther),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => paymentMethod = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          '${l10n.payableDueDate}: ${AppFormatters.formatDate(selectedDueDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDueDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: installmentsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.payableTotalInstallments,
                                helperText: l10n.payableInstallmentsHelper,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.payableRecurrent),
                        value: isRecurrent,
                        onChanged: (val) {
                          setDialogState(() => isRecurrent = val ?? false);
                        },
                      ),
                      if (isRecurrent) ...[
                        DropdownButtonFormField<String>(
                          initialValue: recurrencePeriod,
                          decoration: InputDecoration(
                            labelText: l10n.payableRecurrenceFrequency,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'MONTHLY',
                              child: Text(l10n.payableRecurrenceMonthly),
                            ),
                            DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text(l10n.payableRecurrenceWeekly),
                            ),
                            DropdownMenuItem(
                              value: 'YEARLY',
                              child: Text(l10n.payableRecurrenceYearly),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => recurrencePeriod = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: l10n.commonNotes,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (descController.text.trim().isEmpty) {
                            setDialogState(
                              () => formError =
                                  'Informe a descrição da obrigação.',
                            );
                            return;
                          }
                          if (benController.text.trim().isEmpty) {
                            setDialogState(
                              () => formError =
                                  'Informe o favorecido/fornecedor.',
                            );
                            return;
                          }
                          final cents = _parseToCents(amountController.text);
                          if (cents <= 0) {
                            setDialogState(
                              () => formError =
                                  l10n.payablePaymentAmountMustBePositive,
                            );
                            return;
                          }
                          final installments =
                              int.tryParse(installmentsController.text) ?? 1;
                          if (installments < 1) {
                            setDialogState(
                              () => formError =
                                  'Número de parcelas deve ser ao menos 1.',
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });

                          try {
                            await _payableService.createPayable(
                              AccountPayableCreate(
                                description: descController.text.trim(),
                                beneficiary: benController.text.trim(),
                                category: category,
                                nature: nature,
                                originalAmountCents: cents,
                                dueDate: selectedDueDate,
                                paymentMethod: paymentMethod,
                                totalInstallments: installments,
                                isRecurrent: isRecurrent,
                                recurrencePeriod: isRecurrent
                                    ? recurrencePeriod
                                    : null,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              ),
                            );

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.commonSuccess)),
                              );
                              _loadPayables();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              formError = ApiErrorMapper.toLocalizedMessage(
                                e,
                                l10n,
                              );
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHistoryDialog(AccountPayable payable) async {
    final l10n = context.l10n;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<AccountPayable>(
            future: _payableService.getPayable(payable.id),
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
                title: Text(l10n.payableHistoryAction),
                content: SizedBox(
                  width: 520,
                  child: detail.payments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(child: Text(l10n.payableNoPaymentsYet)),
                        )
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
                                isConfirmed ? Icons.check_circle_outline : Icons.cancel_outlined,
                                color: isConfirmed ? AppPalette.of(context).accent : AppPalette.of(context).sub,
                              ),
                              title: Text(
                                AppFormatters.formatCurrency(p.amountCents),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isConfirmed
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppFormatters.formatDateTime(p.paymentDate)} via ${p.paymentMethod}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (!isConfirmed && p.reversalReason != null)
                                    Text(
                                      'Estornado: ${p.reversalReason}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppPalette.of(context).warn,
                                      ),
                                    ),
                                  if (p.notes != null)
                                    Text(
                                      context.l10n.commonNotesPrefix(p.notes!),
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
                                      icon: Icon(
                                        Icons.undo,
                                        color: AppPalette.of(context).warn,
                                      ),
                                      tooltip: l10n.payableRevertPaymentTooltip,
                                      onPressed: () async {
                                        final reasonController =
                                            TextEditingController();
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            title: Text(
                                              l10n.payableRevertPaymentTitle,
                                            ),
                                            content: TextField(
                                              controller: reasonController,
                                              decoration: InputDecoration(
                                                labelText: l10n
                                                    .payableRevertPaymentReason,
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
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: AppPalette.of(context).warn,
                                                  foregroundColor: AppPalette.of(context).accentInk,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(dCtx, true),
                                                child: Text(l10n.commonConfirm),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true &&
                                            reasonController.text
                                                .trim()
                                                .isNotEmpty) {
                                          try {
                                            await _payableService.cancelPayment(
                                              p.id,
                                              reasonController.text.trim(),
                                            );
                                            setDialogState(() {});
                                            _loadPayables();
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

  Future<void> _cancelPayable(AccountPayable payable) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.payableCancelConfirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.payableConfirmCancelObligationNamed(
                payable.description,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.payableCancelReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.of(context).warn,
              foregroundColor: AppPalette.of(context).accentInk,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.commonConfirm,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _payableService.cancelPayable(
          payable.id,
          reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.payableCancelSuccess)));
          _loadPayables();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
          );
        }
      }
    }
  }

  Widget _buildSummaryHeader() {
    final l = context.l10n;
    final pal = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ApprovedSurface(
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Theme(
          data: Theme.of(context).copyWith(
            cardTheme: Theme.of(context).cardTheme.copyWith(color: Colors.transparent),
          ),
          child: FinancialSummaryPanel(
            caption: l.payableDisplayedSummary,
            metrics: [
              FinancialSummaryMetric(
                l.payableOpenShort,
                _totalOpenCents,
                pal.ink,
              ),
              FinancialSummaryMetric(
                l.payableOverdue,
                _overdueCents,
                pal.warn,
              ),
              FinancialSummaryMetric(
                l.payablePaidAmount,
                _paidCents,
                pal.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    final initial = PayableFilters(
      status: _statusFilter,
      category: _categoryFilter,
      nature: _natureFilter,
      month: _monthFilter,
      year: _yearFilter,
      from: _dueDateFrom,
      to: _dueDateTo,
      overdue: _overdueOnly,
    );
    final PayableFilters? result;
    if (MediaQuery.sizeOf(context).width < 640) {
      result = await showModalBottomSheet<PayableFilters>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: .9,
          child: PayableFiltersPanel(initial: initial),
        ),
      );
    } else {
      result = await showDialog<PayableFilters>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
            child: PayableFiltersPanel(initial: initial),
          ),
        ),
      );
    }
    if (!mounted || result == null) return;
    setState(() {
      _statusFilter = result!.status;
      _categoryFilter = result.category;
      _natureFilter = result.nature;
      _monthFilter = result.month;
      _yearFilter = result.year;
      _dueDateFrom = result.from;
      _dueDateTo = result.to;
      _overdueOnly = result.overdue;
    });
    _loadPayables();
  }

  void _search() {
    final text = _beneficiaryController.text.trim();
    setState(() => _beneficiaryFilter = text.isEmpty ? null : text);
    _loadPayables();
  }

  Widget _buildFilterBar() {
    final l = context.l10n;
    final p = AppPalette.of(context);
    Widget chip(String label, VoidCallback clear) => InputChip(
      deleteIcon: const Icon(Icons.close, size: 16),
      deleteButtonTooltipMessage: l.receivableFilterClear,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: p.soft,
      side: BorderSide(color: p.line),
      onDeleted: () {
        setState(clear);
        _loadPayables();
      },
    );
    final chips = <Widget>[
      if (_beneficiaryFilter != null)
        chip(_beneficiaryFilter!, () {
          _beneficiaryFilter = null;
          _beneficiaryController.clear();
        }),
      if (_statusFilter != null)
        chip(_statusLabel(_statusFilter!), () => _statusFilter = null),
      if (_categoryFilter != null)
        chip(_categoryLabel(_categoryFilter!), () => _categoryFilter = null),
      if (_natureFilter != null)
        chip(
          _natureFilter == 'BUSINESS'
              ? l.payableNatureBusiness
              : l.payableNaturePersonal,
          () => _natureFilter = null,
        ),
      if (_monthFilter != null)
        chip(
          '${l.payableFilterMonth}: $_monthFilter',
          () => _monthFilter = null,
        ),
      if (_yearFilter != null)
        chip('${l.payableFilterYear}: $_yearFilter', () => _yearFilter = null),
      if (_dueDateFrom != null && _dueDateTo != null)
        chip(
          '${AppFormatters.formatDate(_dueDateFrom!)} – ${AppFormatters.formatDate(_dueDateTo!)}',
          () {
            _dueDateFrom = null;
            _dueDateTo = null;
          },
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _beneficiaryController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l.payableBeneficiary,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(
                tooltip: l.payableSearch,
                icon: const Icon(Icons.search),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _search();
                },
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _showFilters,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l.payableFiltersTitle),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              FilterChip(
                label: Text(l.payableOverdue),
                selected: _overdueOnly,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  setState(() => _overdueOnly = v);
                  _loadPayables();
                },
              ),
              if (chips.isNotEmpty ||
                  _overdueOnly ||
                  _beneficiaryFilter != null)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(l.receivableFilterClear),
                ),
              ...chips,
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String value) {
    final l = context.l10n;
    return switch (value) {
      'OPEN' => l.payableStatusOpen,
      'PARTIAL' => l.payableStatusPartial,
      'PAID' => l.payableStatusPaid,
      'CANCELED' => l.payableStatusCanceled,
      _ => value,
    };
  }

  String _categoryLabel(String value) {
    final l = context.l10n;
    return switch (value) {
      'FORNECEDOR' => l.payableCategorySupplier,
      'ENERGIA' => l.payableCategoryElectricity,
      'ALUGUEL' => l.payableCategoryRent,
      'FRETE' => l.payableCategoryFreightShort,
      'MANUTENCAO' => l.payableCategoryMaintenance,
      'EMPRESTIMO' => l.payableCategoryLoan,
      'CARTAO_CREDITO' => l.payableCategoryCreditCard,
      'RETIRADA_SOCIO' => l.payableCategoryPartnerWithdrawal,
      'IMPOSTO' => l.payableCategoryTaxesShort,
      'OUTROS' => l.payableCategoryOthers,
      _ => value,
    };
  }

  String _paymentMethodLabel(String value) {
    final l = context.l10n;
    return switch (value) {
      'BOLETO' => l.payablePaymentMethodBoleto,
      'PIX' => l.payablePaymentMethodPix,
      'TRANSFERENCIA' => l.payablePaymentMethodTransfer,
      'CHEQUE' => l.payablePaymentMethodCheck,
      'CARTAO_CREDITO' => l.payablePaymentMethodCard,
      'DINHEIRO' => l.payablePaymentMethodCash,
      'OUTRO' => l.payablePaymentMethodOther,
      _ => value,
    };
  }

  Widget _payableTag(String label, {IconData? icon, Color? color}) {
    final pal = AppPalette.of(context);
    final tagColor = color ?? pal.sub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pal.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pal.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tagColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountPayable p) {
    final l10n = context.l10n;
    final pal = AppPalette.of(context);
    Color bg;
    Color fg;
    String text;

    if (p.isOverdue) {
      bg = pal.warnFill;
      fg = pal.warn;
      text = l10n.payableOverdue;
    } else {
      switch (p.status) {
        case 'PAID':
          bg = pal.soft;
          fg = pal.accent;
          text = l10n.payableStatusPaid;
          break;
        case 'PARTIAL':
          bg = pal.warnFill;
          fg = pal.warn;
          text = l10n.payableStatusPartial;
          break;
        case 'CANCELED':
          bg = pal.page;
          fg = pal.sub;
          text = l10n.payableStatusCanceled;
          break;
        default:
          bg = pal.soft;
          fg = pal.accent;
          text = l10n.payableStatusOpen;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildPayableCard(AccountPayable p) {
    final l10n = context.l10n;
    final pal = AppPalette.of(context);
    final canPay = p.status == 'OPEN' || p.status == 'PARTIAL';
    final canCancel = p.status == 'OPEN' && p.paidAmountCents == 0;
    return ApprovedSurface(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${p.payableNumber} · ${p.description}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: pal.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${l10n.payableBeneficiary}: ${p.beneficiary}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: pal.sub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(p),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _payableTag(_categoryLabel(p.category)),
              if (p.paymentMethod.isNotEmpty)
                _payableTag(
                  _paymentMethodLabel(p.paymentMethod),
                  icon: Icons.payment_outlined,
                ),
              if (p.nature == 'PERSONAL_WITHDRAWAL')
                _payableTag(
                  l10n.payableNaturePersonal,
                  icon: Icons.person_outline,
                  color: pal.warn,
                ),
              if (p.totalInstallments > 1)
                _payableTag(
                  l10n.payableInstallment(
                    p.installmentNumber,
                    p.totalInstallments,
                  ),
                  icon: Icons.calendar_today_outlined,
                ),
              if (p.isRecurrent)
                _payableTag(
                  l10n.payableRecurrent,
                  icon: Icons.repeat,
                  color: pal.accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pal.page,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pal.line),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.payableBalance,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: pal.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(p.balanceCents),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: p.isOverdue ? pal.warn : pal.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: p.isOverdue ? pal.warn : pal.sub,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.payableDueDate}: ${AppFormatters.formatDate(p.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: p.isOverdue ? FontWeight.bold : FontWeight.w500,
                            color: p.isOverdue ? pal.warn : pal.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.payableOriginalAmount}: ${AppFormatters.formatCurrency(p.originalAmountCents)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: pal.sub,
                      ),
                    ),
                    if (p.paidAmountCents > 0) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${l10n.payablePaidAmount}: ${AppFormatters.formatCurrency(p.paidAmountCents)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: pal.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (p.isRecurrent)
                TextButton.icon(
                  icon: Icon(Icons.repeat, size: 16, color: pal.accent),
                  label: Text(
                    l10n.payableGenerateNextRecurrence,
                    style: TextStyle(color: pal.accent, fontSize: 13),
                  ),
                  onPressed: () => _generateNextRecurrence(p),
                ),
              if (p.paymentsCount > 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.history, size: 16),
                  label: Text('${l10n.payableHistoryAction} (${p.paymentsCount})'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showHistoryDialog(p),
                ),
              if (canCancel)
                TextButton.icon(
                  icon: Icon(Icons.cancel_outlined, size: 16, color: pal.warn),
                  label: Text(
                    l10n.payableCancelAction,
                    style: TextStyle(color: pal.warn, fontSize: 13),
                  ),
                  onPressed: () => _cancelPayable(p),
                ),
              if (canPay)
                FilledButton.icon(
                  icon: const Icon(Icons.payment, size: 16),
                  label: Text(l10n.payablePaymentAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: pal.accent,
                    foregroundColor: pal.accentInk,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openPayment(p.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final padding = fabScrollPadding(context, top: 12, extended: false);
    return ApprovedPage(
      title: l.payablesTitle,
      actions: [
        IconButton(
          tooltip: l.payableFiltersTitle,
          onPressed: _showFilters,
          icon: const Icon(Icons.tune),
        ),
        IconButton(
          tooltip: l.commonRefresh,
          onPressed: _loadPayables,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        tooltip: l.payableCreateShort,
        shape: const CircleBorder(),
        onPressed: _showCreatePayableDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayables,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _pendingSection()),
            SliverToBoxAdapter(child: _buildSummaryHeader()),
            SliverToBoxAdapter(child: _buildFilterBar()),
            if (_isLoading || _errorMessage != null || _payables.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: padding,
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : _errorMessage != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _loadPayables,
                                child: Text(l.commonRefresh),
                              ),
                            ],
                          )
                        : Text(
                            l.payableNoPayables,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
            if (!_isLoading && _errorMessage == null && _payables.isNotEmpty)
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: index < _payables.length
                          ? _buildPayableCard(_payables[index])
                          : Column(
                              children: [
                                if (_moreError != null) Text(_moreError!),
                                OutlinedButton(
                                  onPressed: _loadingMore ? null : _loadMore,
                                  child: Text(
                                    _loadingMore
                                        ? l.commonLoading
                                        : l.paymentFlowMore,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    childCount: _payables.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
