import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductFormView extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormView({super.key, this.productToEdit});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();

  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _salePriceCtrl;
  late TextEditingController _notesCtrl;

  String _category = 'ALIMENTACAO';
  String _baseUnit = 'UN';
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'ALIMENTACAO',
    'LIMPEZA',
    'CARNE',
    'OUTROS',
    'INSUMO',
  ];

  final List<String> _baseUnits = [
    'UN',
    'KG',
    'G',
    'LT',
    'ML',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _minStockCtrl = TextEditingController(text: (p?.minimumStock ?? 0).toString());
    _costPriceCtrl = TextEditingController(
      text: p != null ? (p.costPriceCents / 100.0).toStringAsFixed(2) : '0.00',
    );
    _salePriceCtrl = TextEditingController(
      text: p != null ? (p.salePriceCents / 100.0).toStringAsFixed(2) : '0.00',
    );
    _notesCtrl = TextEditingController(text: p?.notes ?? '');

    if (p != null) {
      _category = _categories.contains(p.category) ? p.category : _categories.first;
      _baseUnit = _baseUnits.contains(p.baseUnit) ? p.baseUnit : _baseUnits.first;
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _minStockCtrl.dispose();
    _costPriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final minStock = int.tryParse(_minStockCtrl.text.trim()) ?? 0;
    final costPrice = ((double.tryParse(_costPriceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0) * 100).round();
    final salePrice = ((double.tryParse(_salePriceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0) * 100).round();

    final data = {
      'name': _nameCtrl.text.trim(),
      'sku': _skuCtrl.text.trim().isNotEmpty ? _skuCtrl.text.trim() : null,
      'barcode': _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      'category': _category,
      'base_unit': _baseUnit,
      'minimum_stock': minStock,
      'cost_price_cents': costPrice,
      'sale_price_cents': salePrice,
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'is_active': _isActive,
    };

    try {
      if (widget.productToEdit == null) {
        await _service.createProduct(data);
      } else {
        await _service.updateProduct(widget.productToEdit!.id, data);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao salvar produto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Produto / Insumo' : 'Novo Produto / Insumo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto *',
                  hintText: 'Ex: Arroz Agulhinha 5kg, Detergente 500ml',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nome e obrigatorio' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _baseUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidade Base no Estoque *',
                        border: OutlineInputBorder(),
                      ),
                      items: _baseUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => _baseUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Codigo Interno',
                        hintText: 'Ex: ARR-5KG',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Codigo de Barras / EAN',
                        hintText: 'Ex: 7891234567890',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estoque Minimo ($_baseUnit)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final n = int.tryParse(val.trim());
                        if (n == null || n < 0) return 'Minimo deve ser >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preco de Custo (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preco de Venda (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observacoes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Status Ativo'),
                subtitle: const Text('Produtos inativos nao podem ser incluidos em novas receitas ou compras.'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(isEditing ? 'Atualizar Produto' : 'Cadastrar Produto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
