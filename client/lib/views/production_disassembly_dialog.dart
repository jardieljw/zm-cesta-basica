import 'package:flutter/material.dart';
import '../models/production_batch.dart';
import '../services/production_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class _TriageItemDraft {
  final ProductionBatchItem item;
  final TextEditingController intactController;
  final TextEditingController lossController;

  _TriageItemDraft({
    required this.item,
    required this.intactController,
    required this.lossController,
  });

  void dispose() {
    intactController.dispose();
    lossController.dispose();
  }
}

class ProductionDisassemblyDialog extends StatefulWidget {
  final ProductionBatch batch;

  const ProductionDisassemblyDialog({
    super.key,
    required this.batch,
  });

  @override
  State<ProductionDisassemblyDialog> createState() =>
      _ProductionDisassemblyDialogState();
}

class _ProductionDisassemblyDialogState
    extends State<ProductionDisassemblyDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductionService _productionService = ProductionService();

  late final TextEditingController _quantityController;
  final TextEditingController _reasonController = TextEditingController();

  final List<_TriageItemDraft> _triageItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  int get _maxDisassembleQty {
    final remainingInBatch = widget.batch.quantityProduced - widget.batch.quantityDisassembled;
    final batchLimit = remainingInBatch > 0 ? remainingInBatch : widget.batch.quantityProduced;
    final stock = widget.batch.currentBatchStock;
    if (stock <= 0) return 0;
    return stock > batchLimit ? batchLimit : stock;
  }

  @override
  void initState() {
    super.initState();
    final maxQty = _maxDisassembleQty;
    final defaultQty = maxQty > 0 ? maxQty : 1;
    _quantityController = TextEditingController(text: defaultQty.toString());

    _initTriageItems(defaultQty);
  }

  void _initTriageItems(int qtyToDisassemble) {
    for (final draft in _triageItems) {
      draft.dispose();
    }
    _triageItems.clear();

    final totalProduced = widget.batch.quantityProduced > 0
        ? widget.batch.quantityProduced
        : 1;

    for (final item in widget.batch.items) {
      final proportional = (item.quantityConsumedBaseUnits * qtyToDisassemble / totalProduced).round();
      _triageItems.add(
        _TriageItemDraft(
          item: item,
          intactController: TextEditingController(text: proportional.toString()),
          lossController: TextEditingController(text: '0'),
        ),
      );
    }
  }

  void _recalcTriage(int newQty) {
    final totalProduced = widget.batch.quantityProduced > 0
        ? widget.batch.quantityProduced
        : 1;

    for (final draft in _triageItems) {
      final proportional = (draft.item.quantityConsumedBaseUnits * newQty / totalProduced).round();
      draft.intactController.text = proportional.toString();
      draft.lossController.text = '0';
    }
    setState(() {});
  }

  void _markAllIntact() {
    final maxQty = _maxDisassembleQty;
    final qty = int.tryParse(_quantityController.text.trim()) ?? (maxQty > 0 ? maxQty : 1);
    _recalcTriage(qty);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    for (final draft in _triageItems) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qtyToDisassemble = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qtyToDisassemble <= 0) {
      setState(() => _errorMessage = context.l10n.validationMustBePositive);
      return;
    }

    final maxAllowed = _maxDisassembleQty;
    if (maxAllowed <= 0 || qtyToDisassemble > maxAllowed) {
      setState(() => _errorMessage =
          context.l10n.validationInsufficientStockForDisassembly(maxAllowed));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final triagePayload = _triageItems.map((draft) {
      final intact = int.tryParse(draft.intactController.text.trim()) ?? 0;
      final loss = int.tryParse(draft.lossController.text.trim()) ?? 0;
      return {
        'product_id': draft.item.productId,
        'intact_quantity': intact,
        'loss_quantity': loss,
      };
    }).toList();

    final data = {
      'quantity_to_disassemble': qtyToDisassemble,
      'reason': _reasonController.text.trim(),
      'triage_items': triagePayload,
    };

    try {
      final response = await _productionService.disassembleBatch(
        widget.batch.id,
        data,
      );
      if (mounted) {
        Navigator.of(context).pop(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.build_circle_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.productionDisassembleTitle(widget.batch.batchNumber),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cesta: ${widget.batch.basketTypeName}${widget.batch.isCustom ? ' (${l10n.productionCustom})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.productionQuantityProduced}: ${widget.batch.quantityProduced} ${l10n.commonUnit}  |  ${l10n.productionCurrentStock}: ${widget.batch.currentBatchStock} ${l10n.commonUnit}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.productionDisassembleDescription,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${l10n.productionDisassembleQtyLabel} *',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.commonRequired;
                          }
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return l10n.validationMustBePositive;
                          }
                          final maxAllowed = _maxDisassembleQty;
                          if (maxAllowed <= 0) {
                            return l10n.validationInsufficientStockForDisassembly(0);
                          }
                          if (n > maxAllowed) {
                            return 'Max: $maxAllowed';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          final n = int.tryParse(val.trim());
                          final maxAllowed = _maxDisassembleQty;
                          if (n != null && n > 0 && n <= maxAllowed) {
                            _recalcTriage(n);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: '${l10n.productionDisassembleReasonLabel} *',
                          hintText: l10n.productionDisassembleReasonHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return l10n.validationMinChars(3);
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.productionDisassembleTriageTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(l10n.productionDisassembleAllIntact, style: const TextStyle(fontSize: 12)),
                      onPressed: _markAllIntact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_triageItems.isEmpty)
                  const Text('Nenhum insumo registrado neste lote.')
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _triageItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final draft = _triageItems[idx];
                        final item = draft.item;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      l10n.productionBatchConsumedTotal(AppFormatters.formatQuantity(item.quantityConsumedBaseUnits, item.productBaseUnit)),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: draft.intactController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.productionIntactQtyLabel(item.productBaseUnit),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return l10n.commonRequired;
                                    final val = int.tryParse(v.trim());
                                    if (val == null || val < 0) return l10n.validationInvalid;
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: draft.lossController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.productionLossQtyLabel(item.productBaseUnit),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return l10n.commonRequired;
                                    final val = int.tryParse(v.trim());
                                    if (val == null || val < 0) return l10n.validationInvalid;
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.productionDisassembleConfirm),
        ),
      ],
    );
  }
}
