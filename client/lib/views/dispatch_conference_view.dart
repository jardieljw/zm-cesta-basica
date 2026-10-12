import 'package:flutter/material.dart';
import '../models/dispatch.dart';
import '../services/dispatch_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class DispatchConferenceView extends StatefulWidget {
  final String dispatchId;

  const DispatchConferenceView({super.key, required this.dispatchId});

  @override
  State<DispatchConferenceView> createState() => _DispatchConferenceViewState();
}

class _DispatchConferenceViewState extends State<DispatchConferenceView> {
  final DispatchService _dispatchService = DispatchService();

  DispatchReconciliation? _reconciliation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReconciliation();
  }

  Future<void> _loadReconciliation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rec = await _dispatchService.getReconciliation(widget.dispatchId);
      setState(() {
        _reconciliation = rec;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  // ==================== DIALOGS ====================

  Future<void> _openReturnDialog() async {
    final l10n = context.l10n;
    if (_reconciliation == null) return;

    final items = _reconciliation!.itemsReconciliation;
    if (items.isEmpty) return;

    DispatchItemReconciliation selectedItem = items.first;
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogReturnTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    DropdownButtonFormField<DispatchItemReconciliation>(
                      initialValue: selectedItem,
                      decoration: InputDecoration(
                        labelText: l10n.dispatchItemBasket,
                        border: const OutlineInputBorder(),
                      ),
                      items: items.map((it) {
                        return DropdownMenuItem(
                          value: it,
                          child: Text(it.basketTypeName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedItem = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogReturnQty} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = int.tryParse(v?.trim() ?? '');
                        if (val == null || val <= 0) return l10n.saleQuantityMustBePositive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dialogReturnNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          await _dispatchService.recordReturn(
                            widget.dispatchId,
                            DispatchReturnCreate(
                              basketTypeId: selectedItem.basketTypeId,
                              productionBatchId: selectedItem.productionBatchId,
                              quantity: int.parse(qtyCtrl.text.trim()),
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      _loadReconciliation();
    }
  }

  Future<void> _openLossDialog() async {
    final l10n = context.l10n;
    if (_reconciliation == null) return;

    final items = _reconciliation!.itemsReconciliation;
    if (items.isEmpty) return;

    DispatchItemReconciliation selectedItem = items.first;
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogLossTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    DropdownButtonFormField<DispatchItemReconciliation>(
                      initialValue: selectedItem,
                      decoration: InputDecoration(
                        labelText: l10n.dispatchItemBasket,
                        border: const OutlineInputBorder(),
                      ),
                      items: items.map((it) {
                        return DropdownMenuItem(
                          value: it,
                          child: Text(it.basketTypeName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedItem = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogLossQty} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = int.tryParse(v?.trim() ?? '');
                        if (val == null || val <= 0) return l10n.saleQuantityMustBePositive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogLossReason} *',
                        hintText: 'Ex: Caixa molhou na chuva durante entrega',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return l10n.dialogLossReasonRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          await _dispatchService.recordLoss(
                            widget.dispatchId,
                            DispatchLossCreate(
                              basketTypeId: selectedItem.basketTypeId,
                              productionBatchId: selectedItem.productionBatchId,
                              quantity: int.parse(qtyCtrl.text.trim()),
                              reason: reasonCtrl.text.trim(),
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      _loadReconciliation();
    }
  }

  Future<void> _openExpenseDialog() async {
    final l10n = context.l10n;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();
    final authByCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogExpenseTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogExpenseDesc} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) return l10n.commonRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogExpenseAmount} *',
                        prefixText: 'R\$ ',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final cleaned = (v ?? '').replaceAll('.', '').replaceAll(',', '.').trim();
                        final val = double.tryParse(cleaned);
                        if (val == null || val <= 0) return l10n.receivablePaymentAmountMustBePositive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: receiptCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dialogExpenseReceipt,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: authByCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dialogExpenseAuthorizedBy,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          final cleaned = amountCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim();
                          final cents = ((double.tryParse(cleaned) ?? 0.0) * 100).round();
                          await _dispatchService.recordExpense(
                            widget.dispatchId,
                            DispatchExpenseCreate(
                              amountCents: cents,
                              description: descCtrl.text.trim(),
                              receiptRef: receiptCtrl.text.trim().isNotEmpty ? receiptCtrl.text.trim() : null,
                              authorizedBy: authByCtrl.text.trim().isNotEmpty ? authByCtrl.text.trim() : null,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      _loadReconciliation();
    }
  }

  Future<void> _openRepaymentDialog() async {
    final l10n = context.l10n;
    final amountCtrl = TextEditingController();
    String method = 'CASH';
    final recByCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Suggest remaining pending cash if > 0
    if (_reconciliation != null && _reconciliation!.pendingCashCents > 0) {
      amountCtrl.text = (_reconciliation!.pendingCashCents / 100.0).toStringAsFixed(2).replaceAll('.', ',');
    }
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogRepaymentTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    if (_reconciliation != null && _reconciliation!.expectedCashCents < 0) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.conferenceExpenseExceedsNotice,
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogRepaymentAmount} *',
                        prefixText: 'R\$ ',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final cleaned = (v ?? '').replaceAll('.', '').replaceAll(',', '.').trim();
                        final val = double.tryParse(cleaned);
                        if (val == null || val <= 0) return l10n.receivablePaymentAmountMustBePositive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: InputDecoration(
                        labelText: l10n.dialogRepaymentMethod,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Dinheiro em Mãos')),
                        DropdownMenuItem(value: 'PIX', child: Text('PIX Repassado')),
                        DropdownMenuItem(value: 'TRANSFER', child: Text('Transferência Bancária')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => method = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recByCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dialogRepaymentReceivedBy,
                        hintText: 'Colaborador que conferiu e recebeu',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dialogRepaymentNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          final cleaned = amountCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim();
                          final cents = ((double.tryParse(cleaned) ?? 0.0) * 100).round();
                          await _dispatchService.recordRepayment(
                            widget.dispatchId,
                            DispatchRepaymentCreate(
                              amountCents: cents,
                              paymentMethod: method,
                              receivedBy: recByCtrl.text.trim().isNotEmpty ? recByCtrl.text.trim() : null,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      _loadReconciliation();
    }
  }

  Future<void> _openSettleDialog() async {
    final l10n = context.l10n;
    if (_reconciliation == null) return;

    final hasDivergence = _reconciliation!.hasBasketDiscrepancy || _reconciliation!.hasCashDiscrepancy;
    final auditByCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final investNotesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogSettleTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    if (hasDivergence) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Text(
                          l10n.dialogSettleWarningDivergent,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: auditByCtrl,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogSettleAuditedBy} *',
                        hintText: 'Nome do conferente / auditor',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) return l10n.dialogSettleAuditedByRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.dialogSettleNotes,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (hasDivergence) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: investNotesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.dialogSettleInvestigationNotes,
                          hintText: 'Justificativa inicial das divergências',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDivergence ? Colors.orange.shade800 : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          await _dispatchService.settleDispatch(
                            widget.dispatchId,
                            DispatchSettlementCreate(
                              auditedBy: auditByCtrl.text.trim(),
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              investigationNotes: investNotesCtrl.text.trim().isNotEmpty ? investNotesCtrl.text.trim() : null,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conferenceSettledSuccess)),
      );
      _loadReconciliation();
    }
  }

  Future<void> _openInvestigationDialog() async {
    final l10n = context.l10n;
    if (_reconciliation == null) return;

    final existing = _reconciliation!.latestSettlement?.investigationNotes ?? '';
    final notesCtrl = TextEditingController(text: existing);
    bool markResolved = false;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.dialogInvestigationTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: '${l10n.dialogInvestigationNotes} *',
                        hintText: 'Descreva a apuração, se foi justificado, perdas aceitas ou ressarcimento',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) return l10n.commonRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dialogInvestigationMarkResolved, style: const TextStyle(fontSize: 14)),
                      value: markResolved,
                      onChanged: (val) => setDialogState(() => markResolved = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        try {
                          await _dispatchService.updateInvestigation(
                            widget.dispatchId,
                            DispatchSettlementInvestigationUpdate(
                              investigationNotes: notesCtrl.text.trim(),
                              markAsResolved: markResolved,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                          });
                        }
                      },
                child: Text(l10n.dialogInvestigationSave),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.conferenceInvestigationUpdatedSuccess)),
      );
      _loadReconciliation();
    }
  }

  // ==================== BUILD UI ====================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue.shade700;
      case 'CONCLUDED':
      case 'RESOLVED':
        return Colors.green.shade700;
      case 'PENDING_INVESTIGATION':
        return Colors.orange.shade800;
      case 'CANCELED':
        return Colors.grey.shade600;
      default:
        return Colors.black87;
    }
  }

  String _getStatusText(String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'OPEN':
        return l10n.dispatchStatusOpen;
      case 'CONCLUDED':
        return l10n.dispatchStatusConcluded;
      case 'PENDING_INVESTIGATION':
        return l10n.dispatchStatusPendingInvestigation;
      case 'CANCELED':
        return l10n.dispatchStatusCanceled;
      case 'RESOLVED':
        return l10n.dispatchStatusResolved;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conferência de Saída')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _reconciliation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conferência de Saída')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? l10n.commonError, style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadReconciliation, child: Text(l10n.commonRefresh)),
            ],
          ),
        ),
      );
    }

    final rec = _reconciliation!;
    final canPerformOperations = rec.dispatchStatus == 'OPEN' || rec.dispatchStatus == 'PENDING_INVESTIGATION';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conferenceTitle(rec.dispatchNumber)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadReconciliation,
          ),
        ],
      ),
      bottomNavigationBar: canPerformOperations
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.assignment_return, size: 16),
                      label: Text(l10n.conferenceActionReturn),
                      onPressed: _openReturnDialog,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                      label: Text(l10n.conferenceActionLoss),
                      onPressed: _openLossDialog,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: Text(l10n.conferenceActionExpense),
                      onPressed: _openExpenseDialog,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_money, size: 16),
                      label: Text(l10n.conferenceActionRepayment),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                      onPressed: _openRepaymentDialog,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(l10n.conferenceActionSettle),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                      onPressed: _openSettleDialog,
                    ),
                    if (rec.dispatchStatus == 'PENDING_INVESTIGATION')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search, size: 16),
                        label: Text(l10n.conferenceActionInvestigation),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                        onPressed: _openInvestigationDialog,
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadReconciliation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(rec.dispatchStatus).withValues(alpha: 0.15),
                        child: Icon(Icons.local_shipping, color: _getStatusColor(rec.dispatchStatus)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec.responsiblePersonName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatDateTime(rec.dispatchDate),
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(rec.dispatchStatus).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getStatusColor(rec.dispatchStatus)),
                        ),
                        child: Text(
                          _getStatusText(rec.dispatchStatus),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getStatusColor(rec.dispatchStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================== PHYSICAL EQUATION CARD ====================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.blue.shade700, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.conferencePhysicalEquationTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rec.hasBasketDiscrepancy ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rec.hasBasketDiscrepancy ? Colors.red.shade300 : Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rec.hasBasketDiscrepancy ? Icons.error_outline : Icons.check_circle_outline,
                              color: rec.hasBasketDiscrepancy ? Colors.red.shade700 : Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec.hasBasketDiscrepancy
                                    ? '${l10n.conferencePhysicalEquationDivergent} (${l10n.conferenceDiscrepancyLabel(rec.basketDiscrepancyQty)})'
                                    : l10n.conferencePhysicalEquationBalanced,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rec.hasBasketDiscrepancy ? Colors.red.shade800 : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4 Terms Breakdown Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildEquationTermChip(l10n.conferenceDispatchedLabel(rec.totalDispatchedQty), Colors.blue),
                          _buildEquationTermChip(l10n.conferenceSoldLabel(rec.totalSoldQty), Colors.teal),
                          _buildEquationTermChip(l10n.conferenceReturnedLabel(rec.totalReturnedQty), Colors.green),
                          _buildEquationTermChip(l10n.conferenceLostLabel(rec.totalLostQty), Colors.red),
                          _buildEquationTermChip(l10n.conferenceCustodyRemainingLabel(rec.totalRemainingCustodyQty), Colors.purple),
                        ],
                      ),
                      const Divider(height: 24),

                      // Item Details Table
                      Text(
                        'Detalhamento por Cesta:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      ...rec.itemsReconciliation.map((it) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.basketTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                'Retiradas: ${it.dispatchedQty} | Vendidas: ${it.soldQty} | Devolvidas: ${it.returnedQty} | Perdas: ${it.lostQty} | Em Trânsito: ${it.remainingCustodyQty}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              if (it.discrepancyQty != 0)
                                Text(
                                  'Divergência: ${it.discrepancyQty} cestas',
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================== FINANCIAL RECONCILIATION CARD ====================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green.shade700, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.conferenceFinancialTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rec.hasCashDiscrepancy ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rec.hasCashDiscrepancy ? Colors.red.shade300 : Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rec.hasCashDiscrepancy ? Icons.error_outline : Icons.check_circle_outline,
                              color: rec.hasCashDiscrepancy ? Colors.red.shade700 : Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec.hasCashDiscrepancy
                                    ? '${l10n.conferenceFinancialDivergent} (Divergência: ${AppFormatters.formatCurrency(rec.cashDiscrepancyCents)})'
                                    : l10n.conferenceFinancialBalanced,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rec.hasCashDiscrepancy ? Colors.red.shade800 : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Financial Lines
                      _buildFinancialRow(
                        l10n.conferenceCashSalesLabel(AppFormatters.formatCurrency(rec.cashSalesCents)),
                        Icons.payments,
                        Colors.black87,
                      ),
                      _buildFinancialRow(
                        l10n.conferenceDebtCollectedLabel(AppFormatters.formatCurrency(rec.cashDebtCollectedCents)),
                        Icons.price_check,
                        Colors.black87,
                      ),
                      _buildFinancialRow(
                        l10n.conferenceExpensesLabel(AppFormatters.formatCurrency(rec.expensesCents)),
                        Icons.remove_circle_outline,
                        Colors.red.shade700,
                      ),
                      const Divider(height: 16),
                      _buildFinancialRow(
                        l10n.conferenceExpectedCashLabel(AppFormatters.formatCurrency(rec.expectedCashCents)),
                        Icons.account_balance_wallet,
                        Colors.blue.shade900,
                        isBold: true,
                      ),
                      _buildFinancialRow(
                        l10n.conferenceActualRepaidLabel(AppFormatters.formatCurrency(rec.actualRepaidCashCents)),
                        Icons.done_all,
                        Colors.green.shade800,
                        isBold: true,
                      ),
                      _buildFinancialRow(
                        l10n.conferencePendingCashLabel(AppFormatters.formatCurrency(rec.pendingCashCents)),
                        Icons.hourglass_bottom,
                        rec.pendingCashCents > 0 ? Colors.orange.shade900 : Colors.grey.shade700,
                        isBold: true,
                      ),
                      if (rec.expectedCashCents < 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.conferenceExpenseExceedsNotice,
                                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 16),

                      // Direct company account segregation notice
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.conferenceDirectCompanyLabel(AppFormatters.formatCurrency(rec.directCompanyReceivedCents)),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.conferenceDirectNotice,
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================== LIST SECTIONS ====================
              // Returns
              _buildSectionCard(
                title: l10n.conferenceReturnsListTitle,
                icon: Icons.assignment_return,
                isEmpty: rec.returns.isEmpty,
                emptyText: l10n.conferenceNoReturns,
                children: rec.returns.map((r) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${r.quantity}x ${r.basketTypeName ?? "Cesta"} intacta'),
                    subtitle: Text('${AppFormatters.formatDateTime(r.returnedAt)}${r.notes != null ? " • ${r.notes}" : ""}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Losses
              _buildSectionCard(
                title: l10n.conferenceLossesListTitle,
                icon: Icons.warning_amber,
                iconColor: Colors.red,
                isEmpty: rec.losses.isEmpty,
                emptyText: l10n.conferenceNoLosses,
                children: rec.losses.map((ls) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${ls.quantity}x ${ls.basketTypeName ?? "Cesta"} - Motivo: ${ls.reason}'),
                    subtitle: Text(AppFormatters.formatDateTime(ls.occurredAt)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Expenses
              _buildSectionCard(
                title: l10n.conferenceExpensesListTitle,
                icon: Icons.receipt_long,
                isEmpty: rec.expenses.isEmpty,
                emptyText: l10n.conferenceNoExpenses,
                children: rec.expenses.map((ex) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${ex.description} - ${AppFormatters.formatCurrency(ex.amountCents)}'),
                    subtitle: Text(
                      '${AppFormatters.formatDateTime(ex.expenseDate)}'
                      '${ex.authorizedBy != null ? " • Aut: ${ex.authorizedBy}" : ""}'
                      '${ex.receiptRef != null ? " • Comp: ${ex.receiptRef}" : ""}',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Repayments
              _buildSectionCard(
                title: l10n.conferenceRepaymentsListTitle,
                icon: Icons.attach_money,
                iconColor: Colors.green,
                isEmpty: rec.repayments.isEmpty,
                emptyText: l10n.conferenceNoRepayments,
                children: rec.repayments.map((rp) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${AppFormatters.formatCurrency(rp.amountCents)} (${rp.paymentMethod})'),
                    subtitle: Text(
                      '${AppFormatters.formatDateTime(rp.repaymentDate)}'
                      '${rp.receivedBy != null ? " • Recebido por: ${rp.receivedBy}" : ""}'
                      '${rp.notes != null ? " • ${rp.notes}" : ""}',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Settlement / Investigation info
              if (rec.latestSettlement != null) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fechamento Formal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Auditor: ${rec.latestSettlement!.auditedBy} • ${AppFormatters.formatDateTime(rec.latestSettlement!.settledAt)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (rec.latestSettlement!.notes != null) ...[
                          const SizedBox(height: 4),
                          Text('Observações: ${rec.latestSettlement!.notes}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                        if (rec.latestSettlement!.investigationNotes != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Investigação: ${rec.latestSettlement!.investigationNotes}',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquationTermChip(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade800),
      ),
    );
  }

  Widget _buildFinancialRow(String text, IconData icon, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required bool isEmpty,
    required String emptyText,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor ?? Colors.black54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(emptyText, style: const TextStyle(color: Colors.black45, fontSize: 13)),
                ),
              ]
            : children,
      ),
    );
  }
}
