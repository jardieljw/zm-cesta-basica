import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/stock_adjustment.dart';
import '../services/inventory_service.dart';

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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      setState(() => _errorMessage = 'Selecione um produto.');
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune, color: Colors.blue),
          SizedBox(width: 8),
          Text('Ajuste Manual de Estoque'),
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
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Produto / Insumo *',
                    border: OutlineInputBorder(),
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
                  validator: (v) => v == null ? 'Selecione um produto' : null,
                ),
                const SizedBox(height: 16),

                // Tipo de Ajuste
                DropdownButtonFormField<String>(
                  value: _adjustmentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Operacao *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'IN', child: Text('Sobra / Entrada (+) [ADJUSTMENT_IN]')),
                    DropdownMenuItem(value: 'OUT', child: Text('Avaria / Saida (-) [ADJUSTMENT_OUT]')),
                    DropdownMenuItem(value: 'LOSS', child: Text('Perda / Descarte (-) [LOSS]')),
                    DropdownMenuItem(value: 'COUNT', child: Text('Balanco / Contagem Fisica [COUNT]')),
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
                    labelText: _adjustmentType == 'COUNT'
                        ? 'Saldo Contado em Estoque *'
                        : 'Quantidade a Ajustar *',
                    hintText: 'Ex: 10',
                    border: const OutlineInputBorder(),
                    helperText: _adjustmentType == 'COUNT'
                        ? 'O sistema calculara a diferenca automaticamente.'
                        : 'Sempre informe um numero inteiro positivo.',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Informe um numero inteiro valido';
                    if (_adjustmentType != 'COUNT' && n <= 0) return 'Deve ser maior que zero';
                    if (_adjustmentType == 'COUNT' && n < 0) return 'Nao pode ser negativo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Justificativa Obrigatoria
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Justificativa Obrigatoria (Auditoria) *',
                    hintText: 'Ex: Avaria durante transporte de mercadorias',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'A justificativa deve conter pelo menos 3 caracteres.';
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
          child: const Text('Cancelar'),
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
              : const Text('Confirmar Ajuste', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
