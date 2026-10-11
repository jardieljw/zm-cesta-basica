import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';

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
          SnackBar(content: Text(context.l10n.productFormSaveError(e.toString()))),
        );
      }
    }
  }

  String _formatCategory(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'ALIMENTACAO':
        return l10n.categoryFood;
      case 'LIMPEZA':
        return l10n.categoryCleaning;
      case 'CARNE':
        return l10n.categoryMeat;
      case 'OUTROS':
        return l10n.categoryOthers;
      case 'INSUMO':
        return l10n.categoryInput;
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.productFormEditTitle : l10n.productFormNewTitle),
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
                decoration: InputDecoration(
                  labelText: l10n.productFormNameLabel,
                  hintText: l10n.productFormNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? l10n.productFormNameRequired : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.productFormCategoryLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(_formatCategory(context, c)))).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _baseUnit,
                      decoration: InputDecoration(
                        labelText: l10n.productFormBaseUnitLabel,
                        border: const OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: l10n.productFormSkuLabel,
                        hintText: l10n.productFormSkuHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.productFormBarcodeLabel,
                        hintText: l10n.productFormBarcodeHint,
                        border: const OutlineInputBorder(),
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
                        labelText: l10n.productFormMinStockLabel(_baseUnit),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final n = int.tryParse(val.trim());
                        if (n == null || n < 0) return l10n.productFormMinStockInvalid;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.productFormCostPriceLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.productFormSalePriceLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.productFormNotesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.productFormStatusActive),
                subtitle: Text(l10n.productFormStatusActiveSubtitle),
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
                label: Text(isEditing ? l10n.productFormSaveUpdate : l10n.productFormSaveCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
