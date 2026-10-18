import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../services/basket_service.dart';
import '../l10n/l10n_extension.dart';

class BasketTypeFormView extends StatefulWidget {
  final BasketType? basketTypeToEdit;

  const BasketTypeFormView({super.key, this.basketTypeToEdit});

  @override
  State<BasketTypeFormView> createState() => _BasketTypeFormViewState();
}

class _BasketTypeFormViewState extends State<BasketTypeFormView> {
  final _formKey = GlobalKey<FormState>();
  final BasketService _service = BasketService();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _defaultPriceCtrl;

  String _category = 'PADRAO';
  bool _allowsCustomization = false;
  bool _tracksFinishedStock = true;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'PADRAO',
    'NATALINA',
    'CARNE',
    'PERSONALIZADA',
    'OUTROS',
  ];

  @override
  void initState() {
    super.initState();
    final bt = widget.basketTypeToEdit;
    _codeCtrl = TextEditingController(text: bt?.code ?? '');
    _nameCtrl = TextEditingController(text: bt?.name ?? '');
    _descriptionCtrl = TextEditingController(text: bt?.description ?? '');
    _defaultPriceCtrl = TextEditingController(
      text: bt != null
          ? (bt.defaultPriceCents / 100.0).toStringAsFixed(2)
          : '0.00',
    );

    if (bt != null) {
      _category =
          _categories.contains(bt.category) ? bt.category : _categories.first;
      _allowsCustomization = bt.allowsCustomization;
      _tracksFinishedStock = bt.tracksFinishedStock;
      _isActive = bt.isActive;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _defaultPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final defaultPrice =
        ((double.tryParse(_defaultPriceCtrl.text.trim().replaceAll(',', '.')) ??
                    0.0) *
                100)
            .round();

    final data = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isNotEmpty
          ? _descriptionCtrl.text.trim()
          : null,
      'category': _category,
      'default_price_cents': defaultPrice,
      'allows_customization': _allowsCustomization,
      'tracks_finished_stock': _tracksFinishedStock,
      'is_active': _isActive,
    };

    try {
      if (widget.basketTypeToEdit == null) {
        await _service.createBasketType(data);
      } else {
        await _service.updateBasketType(widget.basketTypeToEdit!.id, data);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.l10n.basketTypeFormSaveError(e.toString()))),
        );
      }
    }
  }

  String _formatCategory(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'PADRAO':
        return l10n.categoryStandard;
      case 'NATALINA':
        return l10n.categoryChristmas;
      case 'CARNE':
        return l10n.categoryMeat;
      case 'PERSONALIZADA':
        return l10n.categoryCustom;
      case 'OUTROS':
        return l10n.categoryOthers;
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.basketTypeToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? l10n.basketTypeFormEditTitle
            : l10n.basketTypeFormNewTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeCtrl,
                enabled: !isEditing, // Codigo identificador e fixo apos criacao
                decoration: InputDecoration(
                  labelText: l10n.basketTypeFormCodeLabel,
                  hintText: l10n.basketTypeFormCodeHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.basketTypeFormCodeRequired
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.basketTypeFormNameLabel,
                  hintText: l10n.basketTypeFormNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.basketTypeFormNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.basketTypeFormCategoryLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(_formatCategory(context, c))))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _defaultPriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.basketTypeFormPriceLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.basketTypeFormDescLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.basketTypeFormAllowsCustom),
                subtitle: Text(l10n.basketTypeFormAllowsCustomSubtitle),
                value: _allowsCustomization,
                onChanged: (val) => setState(() => _allowsCustomization = val),
              ),
              SwitchListTile(
                title: Text(l10n.basketTypeFormTracksStock),
                subtitle: Text(_tracksFinishedStock
                    ? l10n.basketTypeFormTracksStockSubtitle
                    : l10n.basketTypeFormNoStockSubtitle),
                value: _tracksFinishedStock,
                onChanged: (val) => setState(() => _tracksFinishedStock = val),
              ),
              SwitchListTile(
                title: Text(l10n.basketTypeFormStatusActive),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(isEditing
                    ? l10n.basketTypeFormSaveUpdate
                    : l10n.basketTypeFormSaveCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
