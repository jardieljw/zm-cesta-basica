import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/purchase_service.dart';

class _PurchaseItemDraft {
  String? productId;
  String? packagingId;
  double packagesCount = 1.0;
  double unitPriceReais = 0.0;

  Product? product;
  ProductPackaging? packaging;

  int get quantityInBaseUnits {
    if (packaging != null) {
      return (packagesCount * packaging!.quantityInBaseUnits).round();
    }
    return packagesCount.round();
  }

  double get totalPriceReais => packagesCount * unitPriceReais;
}

class PurchaseFormView extends StatefulWidget {
  const PurchaseFormView({super.key});

  @override
  State<PurchaseFormView> createState() => _PurchaseFormViewState();
}

class _PurchaseFormViewState extends State<PurchaseFormView> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final PurchaseService _purchaseService = PurchaseService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  String _status = 'CONFIRMED';

  List<Product> _products = [];
  final List<_PurchaseItemDraft> _items = [];
  bool _isLoadingProducts = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final list = await _productService.getProducts(isActive: true);
      setState(() {
        _products = list;
        _isLoadingProducts = false;
        if (_items.isEmpty && _products.isNotEmpty) {
          _addItem();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingProducts = false;
      });
    }
  }

  void _addItem() {
    setState(() {
      final draft = _PurchaseItemDraft();
      if (_products.isNotEmpty) {
        draft.productId = _products.first.id;
        draft.product = _products.first;
        if (draft.product!.packagings.isNotEmpty) {
          draft.packaging = draft.product!.packagings.firstWhere(
            (p) => p.isDefault,
            orElse: () => draft.product!.packagings.first,
          );
          draft.packagingId = draft.packaging?.id;
        }
      }
      _items.add(draft);
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
  }

  double get _totalPurchaseReais {
    return _items.fold(0.0, (acc, item) => acc + item.totalPriceReais);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      setState(() => _errorMessage = 'Adicione pelo menos um item à compra.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'supplier_name': _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
      'purchase_date': _purchaseDate.toUtc().toIso8601String(),
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      'status': _status,
      'items': _items.map((it) {
        return {
          'product_id': it.productId,
          'packaging_id': it.packagingId,
          'packages_count': it.packagesCount,
          'unit_price_cents': (it.unitPriceReais * 100).round(),
        };
      }).toList(),
    };

    try {
      await _purchaseService.createPurchase(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProducts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova Compra')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Compra de Fornecedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Salvar Compra',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)),
                ),

              // Dados Gerais da Compra
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dados do Fornecedor e Documento',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _supplierController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Fornecedor / Razao Social',
                          hintText: 'Ex: Atacadao de Alimentos Ltda',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status da Operacao *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmar Imediatamente (Aumenta Estoque)')),
                                DropdownMenuItem(value: 'DRAFT', child: Text('Salvar Rascunho (Sem movimentar estoque)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Numero da NF-e / Observacoes',
                          hintText: 'Ex: NF-e 45892 chave 3526...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lista Dinamica de Itens
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Itens da Compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Item'),
                    onPressed: _addItem,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final availablePackagings = item.product?.packagings ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade100,
                                child: Text('${index + 1}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                              ),
                              const SizedBox(width: 8),
                              const Text('Item da Compra', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (_items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remover Item',
                                  onPressed: () => _removeItem(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Selecao de Produto
                          DropdownButtonFormField<String>(
                            value: item.productId,
                            decoration: const InputDecoration(
                              labelText: 'Produto / Insumo *',
                              border: OutlineInputBorder(),
                            ),
                            items: _products.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text('${p.name} (${p.baseUnit})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                item.productId = val;
                                item.product = _products.firstWhere((p) => p.id == val);
                                if (item.product!.packagings.isNotEmpty) {
                                  item.packaging = item.product!.packagings.firstWhere(
                                    (pkg) => pkg.isDefault,
                                    orElse: () => item.product!.packagings.first,
                                  );
                                  item.packagingId = item.packaging?.id;
                                } else {
                                  item.packaging = null;
                                  item.packagingId = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Selecao de Embalagem Comercial ou Unidade Base
                          DropdownButtonFormField<String?>(
                            value: item.packagingId,
                            decoration: const InputDecoration(
                              labelText: 'Embalagem de Compra (Conversao Automatica)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Direto na unidade base (${item.product?.baseUnit ?? "UN"})'),
                              ),
                              ...availablePackagings.map((pkg) {
                                return DropdownMenuItem<String?>(
                                  value: pkg.id,
                                  child: Text('${pkg.name} (${pkg.quantityInBaseUnits} ${item.product?.baseUnit})'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                item.packagingId = val;
                                if (val != null) {
                                  item.packaging = availablePackagings.firstWhere((p) => p.id == val);
                                } else {
                                  item.packaging = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Quantidade e Preco Unitario
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${item.packagesCount}',
                                  decoration: InputDecoration(
                                    labelText: item.packaging != null
                                        ? 'Qtd de Embalagens *'
                                        : 'Qtd de Unidades *',
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) {
                                    setState(() {
                                      item.packagesCount = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                  validator: (v) {
                                    final n = double.tryParse(v ?? '');
                                    if (n == null || n <= 0) return 'Informe qtd valida';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.unitPriceReais > 0 ? '${item.unitPriceReais}' : '',
                                  decoration: InputDecoration(
                                    labelText: item.packaging != null
                                        ? 'Preco por Embalagem (R\$) *'
                                        : 'Preco Unitario (R\$) *',
                                    border: const OutlineInputBorder(),
                                    prefixText: 'R\$ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) {
                                    setState(() {
                                      item.unitPriceReais = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                    });
                                  },
                                  validator: (v) {
                                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                                    if (n == null || n < 0) return 'Informe preco valido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Previa da Conversao e Subtotal
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Entrada no Estoque: ${item.quantityInBaseUnits} ${item.product?.baseUnit ?? "UN"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Text(
                                  'Subtotal: ${_currencyFormat.format(item.totalPriceReais)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Banner Total
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total da Compra:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        _currencyFormat.format(_totalPurchaseReais),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar Compra', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
