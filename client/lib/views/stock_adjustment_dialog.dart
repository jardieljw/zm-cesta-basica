import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/stock_adjustment.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final List<Product> products;
  final String? initialProductId;

  const StockAdjustmentDialog({
    super.key,
    required this.products,
    this.initialProductId,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final InventoryService _inventoryService = InventoryService();

  late String? _selectedProductId;
  String _adjustmentType = 'IN'; // IN, OUT, LOSS, COUNT
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId ??
        (widget.products.isNotEmpty ? widget.products.first.id : null);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      setState(() => _errorMessage = l10n.stockAdjustmentSelectProductError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final val = int.tryParse(_quantityController.text.trim()) ?? 0;
    final request = StockAdjustmentRequest(
      itemType: 'PRODUCT',
      productId: _selectedProductId,
      adjustmentType: _adjustmentType,
      quantityDelta: _adjustmentType != 'COUNT' ? val : null,
      physicalCount: _adjustmentType == 'COUNT' ? val : null,
      reason: _reasonController.text.trim(),
    );

    try {
      final response = await _inventoryService.createAdjustment(request);
      if (mounted) {
        Navigator.of(context).pop(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedProduct = widget.products.where((p) => p.id == _selectedProductId).firstOrNull;
    final unit = selectedProduct?.baseUnit ?? 'UN';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.tune, color: Colors.blue),
          const SizedBox(width: 8),
          Text(l10n.stockAdjustmentDialogTitle),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),

                // Seletor de Produto
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  decoration: InputDecoration(
                    labelText: l10n.stockAdjustmentProductLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: widget.products.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text('${p.name} (${p.baseUnit})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedProductId = val);
                  },
                  validator: (v) => v == null ? l10n.stockAdjustmentSelectProductError : null,
                ),
                const SizedBox(height: 16),

                // Tipo de Ajuste
                DropdownButtonFormField<String>(
                  initialValue: _adjustmentType,
                  decoration: InputDecoration(
                    labelText: l10n.stockAdjustmentTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'IN', child: Text(l10n.stockAdjustmentTypeIn)),
                    DropdownMenuItem(value: 'OUT', child: Text(l10n.stockAdjustmentTypeOut)),
                    DropdownMenuItem(value: 'LOSS', child: Text(l10n.stockAdjustmentTypeLoss)),
                    DropdownMenuItem(value: 'COUNT', child: Text(l10n.stockAdjustmentTypeCount)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _adjustmentType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Quantidade
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.stockAdjustmentQtyLabel(unit),
                    hintText: l10n.stockAdjustmentQtyHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return l10n.stockAdjustmentQtyRequired;
                    if (_adjustmentType != 'COUNT' && n <= 0) return l10n.stockAdjustmentQtyRequired;
                    if (_adjustmentType == 'COUNT' && n < 0) return l10n.stockAdjustmentQtyRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Justificativa Obrigatoria
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${l10n.commonNotes} *',
                    hintText: l10n.stockAdjustmentReasonHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return l10n.stockAdjustmentReasonRequired;
                    }
                    return null;
                  },
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
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.stockAdjustmentConfirmButton, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
