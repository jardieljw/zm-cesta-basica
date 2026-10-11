import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../services/basket_service.dart';

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
      text: bt != null ? (bt.defaultPriceCents / 100.0).toStringAsFixed(2) : '0.00',
    );

    if (bt != null) {
      _category = _categories.contains(bt.category) ? bt.category : _categories.first;
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

    final defaultPrice = ((double.tryParse(_defaultPriceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0) * 100).round();

    final data = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
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
          SnackBar(content: Text('Falha ao salvar tipo de cesta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.basketTypeToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tipo de Cesta' : 'Novo Tipo de Cesta'),
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
                decoration: const InputDecoration(
                  labelText: 'Codigo Identificador * (Letras maiusculas)',
                  hintText: 'Ex: BASICA_COMPLETA, CESTA_CARNE',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Codigo e obrigatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome Comercial da Cesta *',
                  hintText: 'Ex: Cesta Basica Completa (Alimentacao + Limpeza)',
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
                    child: TextFormField(
                      controller: _defaultPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preco Sugerido / Base (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descricao da Cesta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aceita Customizacao na Venda?'),
                subtitle: const Text('Permite montar e faturar como lote personalizado.'),
                value: _allowsCustomization,
                onChanged: (val) => setState(() => _allowsCustomization = val),
              ),
              SwitchListTile(
                title: const Text('Controla Estoque de Cestas Prontas?'),
                subtitle: const Text('Registra saldo acabado das cestas montadas antes da venda.'),
                value: _tracksFinishedStock,
                onChanged: (val) => setState(() => _tracksFinishedStock = val),
              ),
              SwitchListTile(
                title: const Text('Status Ativo'),
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
                label: Text(isEditing ? 'Atualizar Tipo de Cesta' : 'Cadastrar Tipo de Cesta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
