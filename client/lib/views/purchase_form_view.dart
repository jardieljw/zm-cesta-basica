import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/purchase_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';

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
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  final DateTime _purchaseDate = DateTime.now();
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
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      setState(() => _errorMessage = l10n.purchaseFormAtLeastOneItem);
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
          SnackBar(content: Text(l10n.purchaseFormSuccess)),
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
    final l10n = context.l10n;
    if (_isLoadingProducts) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.purchaseFormTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseFormTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.purchaseFormSaveButton,
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
                      Text(l10n.purchaseSupplier,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _supplierController,
                        decoration: InputDecoration(
                          labelText: l10n.purchaseFormSupplierLabel,
                          hintText: l10n.purchaseFormSupplierHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: InputDecoration(
                                labelText: '${l10n.commonStatus} *',
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: 'CONFIRMED', child: Text(l10n.purchaseStatusConfirmedWithStock)),
                                DropdownMenuItem(value: 'DRAFT', child: Text(l10n.purchaseStatusDraftWithoutStock)),
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
                        decoration: InputDecoration(
                          labelText: '${l10n.purchaseFormInvoiceLabel} / ${l10n.purchaseFormNotesLabel}',
                          hintText: l10n.purchaseFormNotesHint,
                          border: const OutlineInputBorder(),
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
                  Text(l10n.purchaseFormItemsHeader, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.purchaseFormAddItem),
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
                              Text(l10n.purchaseItemIndex(index + 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (_items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: l10n.commonDelete,
                                  onPressed: () => _removeItem(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Selecao de Produto
                          DropdownButtonFormField<String>(
                            initialValue: item.productId,
                            decoration: InputDecoration(
                              labelText: l10n.purchaseFormProductLabel,
                              border: const OutlineInputBorder(),
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
                            initialValue: item.packagingId,
                            decoration: InputDecoration(
                              labelText: l10n.purchaseFormPackagingLabel,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(l10n.purchaseFormBaseUnitPackaging(item.product?.baseUnit ?? 'UN')),
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
                                        ? l10n.purchaseFormQtyLabel
                                        : '${l10n.purchaseFormQtyLabel} (${item.product?.baseUnit ?? "UN"})',
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
                                    if (n == null || n <= 0) return l10n.purchaseFormQtyRequired;
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.unitPriceReais > 0 ? '${item.unitPriceReais}' : '',
                                  decoration: InputDecoration(
                                    labelText: l10n.purchaseFormUnitCostLabel,
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) {
                                    setState(() {
                                      item.unitPriceReais = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                    });
                                  },
                                  validator: (v) {
                                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                                    if (n == null || n < 0) return l10n.purchaseFormUnitCostRequired;
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
                                  l10n.purchaseFormConvertedStock(item.quantityInBaseUnits, item.product?.baseUnit ?? 'UN'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Text(
                                  l10n.purchaseFormTotalItem(AppFormatters.formatCurrency((item.totalPriceReais * 100).round())),
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
                      Text('${l10n.purchaseTotalCost}:',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        AppFormatters.formatCurrency((_totalPurchaseReais * 100).round()),
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
                    : Text(l10n.purchaseFormSaveButton, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
