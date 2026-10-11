import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../models/product.dart';
import '../models/production_batch.dart';
import '../services/basket_service.dart';
import '../services/product_service.dart';
import '../services/production_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';

class _CustomItemRow {
  String productId;
  String section;
  int quantityPerBasket;

  _CustomItemRow({
    required this.productId,
    this.section = 'ALIMENTOS',
    this.quantityPerBasket = 1,
  });
}

class ProductionAssemblyView extends StatefulWidget {
  const ProductionAssemblyView({super.key});

  @override
  State<ProductionAssemblyView> createState() => _ProductionAssemblyViewState();
}

class _ProductionAssemblyViewState extends State<ProductionAssemblyView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final BasketService _basketService = BasketService();
  final ProductService _productService = ProductService();
  final ProductionService _productionService = ProductionService();

  bool _isLoadingInitial = true;
  String? _initialError;

  List<BasketType> _basketTypes = [];
  List<Product> _products = [];

  // --- TAB 1: Standard Basket State ---
  final _standardFormKey = GlobalKey<FormState>();
  BasketType? _selectedStandardBasket;
  final TextEditingController _standardQtyController =
      TextEditingController(text: '1');
  final TextEditingController _standardNotesController =
      TextEditingController();
  bool _standardIsDirectSale = false;

  bool _isLoadingStandardPreview = false;
  ProductionPreview? _standardPreview;
  String? _standardPreviewError;
  bool _isCreatingStandard = false;

  // --- TAB 2: Custom Basket State ---
  final _customFormKey = GlobalKey<FormState>();
  BasketType? _selectedCustomBaseBasket;
  final TextEditingController _customDescController = TextEditingController();
  final TextEditingController _customQtyController =
      TextEditingController(text: '1');
  final TextEditingController _customNotesController = TextEditingController();
  bool _customIsDirectSale = false;
  final List<_CustomItemRow> _customItems = [];

  bool _isLoadingCustomPreview = false;
  ProductionPreview? _customPreview;
  String? _customPreviewError;
  bool _isCreatingCustom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _standardQtyController.dispose();
    _standardNotesController.dispose();
    _customDescController.dispose();
    _customQtyController.dispose();
    _customNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _initialError = null;
    });

    try {
      final baskets = await _basketService.getBasketTypes(isActive: true);
      final products = await _productService.getProducts(isActive: true);

      setState(() {
        _basketTypes = baskets;
        _products = products;
        _isLoadingInitial = false;

        if (baskets.isNotEmpty) {
          _selectedStandardBasket = baskets.first;
          _selectedCustomBaseBasket = baskets.first;
          _loadStandardPreview();
          _populateCustomFromBase();
        }
      });
    } catch (e) {
      setState(() {
        _initialError = e.toString().replaceAll('Exception: ', '');
        _isLoadingInitial = false;
      });
    }
  }

  // ================= STANDARD BASKET METHODS =================

  Future<void> _loadStandardPreview() async {
    if (_selectedStandardBasket == null) return;
    final qty = int.tryParse(_standardQtyController.text.trim()) ?? 1;
    if (qty <= 0) return;

    setState(() {
      _isLoadingStandardPreview = true;
      _standardPreviewError = null;
    });

    try {
      final preview = await _productionService.previewBatch({
        'basket_type_id': _selectedStandardBasket!.id,
        'quantity_produced': qty,
        'is_custom': false,
        'is_direct_sale': _standardIsDirectSale,
        'notes': _standardNotesController.text.trim(),
      });
      if (mounted) {
        setState(() {
          _standardPreview = preview;
          _isLoadingStandardPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _standardPreviewError = e.toString().replaceAll('Exception: ', '');
          _isLoadingStandardPreview = false;
        });
      }
    }
  }

  Future<void> _submitStandardProduction() async {
    final l10n = context.l10n;
    if (!_standardFormKey.currentState!.validate()) return;
    if (_selectedStandardBasket == null) return;

    final qty = int.tryParse(_standardQtyController.text.trim()) ?? 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assemblyConfirmDialogTitle),
        content: Text(
          l10n.assemblyConfirmDialogContent(qty, _selectedStandardBasket!.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCreatingStandard = true;
      _standardPreviewError = null;
    });

    try {
      final batch = await _productionService.createBatch({
        'basket_type_id': _selectedStandardBasket!.id,
        'quantity_produced': qty,
        'is_custom': false,
        'is_direct_sale': _standardIsDirectSale,
        'notes': _standardNotesController.text.trim().isEmpty
            ? null
            : _standardNotesController.text.trim(),
      });

      if (mounted) {
        final formattedCost = AppFormatters.formatCurrency(batch.unitCostCents);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(
              l10n.assemblyConfirmSuccess(batch.batchNumber, formattedCost),
            ),
          ),
        );
        Navigator.of(context).pop(batch);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _standardPreviewError = e.toString().replaceAll('Exception: ', '');
          _isCreatingStandard = false;
        });
      }
    }
  }

  // ================= CUSTOM BASKET METHODS =================

  void _populateCustomFromBase() {
    if (_selectedCustomBaseBasket == null) return;
    _customItems.clear();

    final activeRecipe = _selectedCustomBaseBasket!.activeRecipe;
    if (activeRecipe != null && activeRecipe.items.isNotEmpty) {
      for (final it in activeRecipe.items) {
        _customItems.add(
          _CustomItemRow(
            productId: it.productId,
            section: it.section,
            quantityPerBasket: it.quantityInBaseUnits,
          ),
        );
      }
    } else if (_products.isNotEmpty) {
      _customItems.add(
        _CustomItemRow(
          productId: _products.first.id,
          section: 'ALIMENTOS',
          quantityPerBasket: 1,
        ),
      );
    }
    _loadCustomPreview();
  }

  void _addCustomItem() {
    if (_products.isEmpty) return;
    setState(() {
      _customItems.add(
        _CustomItemRow(
          productId: _products.first.id,
          section: 'ALIMENTOS',
          quantityPerBasket: 1,
        ),
      );
    });
    _loadCustomPreview();
  }

  void _removeCustomItem(int index) {
    if (_customItems.length <= 1) return;
    setState(() {
      _customItems.removeAt(index);
    });
    _loadCustomPreview();
  }

  Future<void> _loadCustomPreview() async {
    if (_selectedCustomBaseBasket == null) return;
    final qty = int.tryParse(_customQtyController.text.trim()) ?? 1;
    if (qty <= 0 || _customItems.isEmpty) return;

    setState(() {
      _isLoadingCustomPreview = true;
      _customPreviewError = null;
    });

    final customItemsPayload = _customItems
        .where((it) => it.quantityPerBasket > 0)
        .map((it) => {
              'product_id': it.productId,
              'quantity_in_base_units': it.quantityPerBasket,
              'section': it.section,
            })
        .toList();

    try {
      final preview = await _productionService.previewBatch({
        'basket_type_id': _selectedCustomBaseBasket!.id,
        'quantity_produced': qty,
        'is_custom': true,
        'is_direct_sale': _customIsDirectSale,
        'custom_description': _customDescController.text.trim(),
        'notes': _customNotesController.text.trim(),
        'custom_items': customItemsPayload,
      });

      if (mounted) {
        setState(() {
          _customPreview = preview;
          _isLoadingCustomPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customPreviewError = e.toString().replaceAll('Exception: ', '');
          _isLoadingCustomPreview = false;
        });
      }
    }
  }

  Future<void> _submitCustomProduction() async {
    final l10n = context.l10n;
    if (!_customFormKey.currentState!.validate()) return;
    if (_selectedCustomBaseBasket == null) return;
    if (_customItems.isEmpty) {
      setState(() => _customPreviewError = l10n.assemblyCustomQtyValidation);
      return;
    }

    final qty = int.tryParse(_customQtyController.text.trim()) ?? 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assemblySubmitCustom),
        content: Text(
          l10n.assemblyConfirmDialogContent(qty, _customDescController.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCreatingCustom = true;
      _customPreviewError = null;
    });

    final customItemsPayload = _customItems
        .map((it) => {
              'product_id': it.productId,
              'quantity_in_base_units': it.quantityPerBasket,
              'section': it.section,
            })
        .toList();

    try {
      final batch = await _productionService.createBatch({
        'basket_type_id': _selectedCustomBaseBasket!.id,
        'quantity_produced': qty,
        'is_custom': true,
        'is_direct_sale': _customIsDirectSale,
        'custom_description': _customDescController.text.trim(),
        'notes': _customNotesController.text.trim().isEmpty
            ? null
            : _customNotesController.text.trim(),
        'custom_items': customItemsPayload,
      });

      if (mounted) {
        final formattedCost = AppFormatters.formatCurrency(batch.unitCostCents);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blue.shade800,
            content: Text(
              l10n.assemblyConfirmSuccess(batch.batchNumber, formattedCost),
            ),
          ),
        );
        Navigator.of(context).pop(batch);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customPreviewError = e.toString().replaceAll('Exception: ', '');
          _isCreatingCustom = false;
        });
      }
    }
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.assemblyHeaderTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initialError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.assemblyHeaderTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.commonError}: $_initialError', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: Text(l10n.commonRefresh),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assemblyHeaderTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.shopping_basket), text: l10n.assemblyTabStandard),
            Tab(icon: const Icon(Icons.tune), text: l10n.assemblyTabCustom),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStandardTab(),
          _buildCustomTab(),
        ],
      ),
    );
  }

  // ================= TAB 1: STANDARD WIDGETS =================

  Widget _buildStandardTab() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _standardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assemblyHeaderTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStandardBasket?.id,
                            decoration: InputDecoration(
                              labelText: l10n.assemblyStandardBasketLabel,
                              border: const OutlineInputBorder(),
                            ),
                            items: _basketTypes.map((b) {
                              final ver = b.activeRecipe != null
                                  ? ' (v${b.activeRecipe!.versionNumber})'
                                  : ' (${l10n.commonNo} ${l10n.recipesTitle.toLowerCase()})';
                              return DropdownMenuItem(
                                value: b.id,
                                child: Text('${b.name}$ver'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStandardBasket =
                                      _basketTypes.firstWhere((b) => b.id == val);
                                });
                                _loadStandardPreview();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _standardQtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.assemblyStandardQtyLabel,
                              border: const OutlineInputBorder(),
                              suffixText: l10n.commonUnit,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.commonRequired;
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return l10n.assemblyStandardQtyValidation;
                              return null;
                            },
                            onChanged: (_) => _loadStandardPreview(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _standardIsDirectSale,
                          onChanged: (val) {
                            setState(() {
                              _standardIsDirectSale = val ?? false;
                            });
                          },
                        ),
                        Text(l10n.assemblyStandardDirectSale),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _standardNotesController,
                      decoration: InputDecoration(
                        labelText: l10n.assemblyStandardNotesLabel,
                        hintText: l10n.assemblyStandardNotesHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewCard(
              preview: _standardPreview,
              isLoading: _isLoadingStandardPreview,
              errorMessage: _standardPreviewError,
              onRefresh: _loadStandardPreview,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isCreatingStandard
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isCreatingStandard
                    ? l10n.commonLoading
                    : l10n.assemblySubmitStandard,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_standardPreview?.canProduce ?? false)
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_isCreatingStandard || !(_standardPreview?.canProduce ?? false))
                  ? null
                  : _submitStandardProduction,
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: CUSTOM WIDGETS =================

  Widget _buildCustomTab() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _customFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assemblyTabCustom,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCustomBaseBasket?.id,
                            decoration: InputDecoration(
                              labelText: l10n.assemblyCustomBaseBasket,
                              border: const OutlineInputBorder(),
                            ),
                            items: _basketTypes.map((b) {
                              return DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCustomBaseBasket =
                                      _basketTypes.firstWhere((b) => b.id == val);
                                });
                                _populateCustomFromBase();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _customQtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.assemblyStandardQtyLabel,
                              border: const OutlineInputBorder(),
                              suffixText: l10n.commonUnit,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.commonRequired;
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return l10n.assemblyStandardQtyValidation;
                              return null;
                            },
                            onChanged: (_) => _loadCustomPreview(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customDescController,
                      decoration: InputDecoration(
                        labelText: l10n.assemblyCustomDescLabel,
                        hintText: l10n.assemblyCustomDescHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return l10n.assemblyCustomDescRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _customIsDirectSale,
                          onChanged: (val) {
                            setState(() {
                              _customIsDirectSale = val ?? false;
                            });
                          },
                        ),
                        Text(l10n.assemblyStandardDirectSale),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customNotesController,
                      decoration: InputDecoration(
                        labelText: l10n.assemblyStandardNotesLabel,
                        hintText: l10n.assemblyStandardNotesHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.assemblyCustomItemsHeader(_customItems.length),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sync, size: 16),
                              label: Text(l10n.commonRefresh, style: const TextStyle(fontSize: 12)),
                              onPressed: _populateCustomFromBase,
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.assemblyCustomAddItem, style: const TextStyle(fontSize: 12)),
                              onPressed: _addCustomItem,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customItems.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final row = _customItems[idx];
                        return Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                initialValue: row.productId,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: l10n.productName,
                                  border: const OutlineInputBorder(),
                                ),
                                items: _products.map((p) {
                                  return DropdownMenuItem(
                                    value: p.id,
                                    child: Text('${p.name} (${p.baseUnit})', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      row.productId = val;
                                    });
                                    _loadCustomPreview();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: row.section,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: l10n.recipeSection,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'ALIMENTOS', child: Text(l10n.categoryFood)),
                                  DropdownMenuItem(value: 'LIMPEZA', child: Text(l10n.categoryCleaning)),
                                  DropdownMenuItem(value: 'HIGIENE', child: Text(l10n.categoryHygiene)),
                                  DropdownMenuItem(value: 'OUTROS', child: Text(l10n.categoryOthers)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      row.section = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: row.quantityPerBasket.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.recipeQuantityPerBasket,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final n = int.tryParse(val.trim());
                                  if (n != null && n > 0) {
                                    row.quantityPerBasket = n;
                                    _loadCustomPreview();
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: l10n.commonDelete,
                              onPressed: _customItems.length > 1
                                  ? () => _removeCustomItem(idx)
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewCard(
              preview: _customPreview,
              isLoading: _isLoadingCustomPreview,
              errorMessage: _customPreviewError,
              onRefresh: _loadCustomPreview,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isCreatingCustom
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isCreatingCustom
                    ? l10n.commonLoading
                    : l10n.assemblySubmitCustom,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_customPreview?.canProduce ?? false)
                    ? Colors.blue.shade700
                    : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_isCreatingCustom || !(_customPreview?.canProduce ?? false))
                  ? null
                  : _submitCustomProduction,
            ),
          ],
        ),
      ),
    );
  }

  // ================= PREVIEW CARD WIDGET =================

  Widget _buildPreviewCard({
    required ProductionPreview? preview,
    required bool isLoading,
    required String? errorMessage,
    required VoidCallback onRefresh,
  }) {
    final l10n = context.l10n;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      l10n.assemblyFeasibilityTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: l10n.commonRefresh,
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else if (preview != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: preview.canProduce
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          preview.canProduce ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: preview.canProduce
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          preview.canProduce
                              ? l10n.assemblyFeasibleOk
                              : l10n.assemblyFeasibleFail,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: preview.canProduce
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.assemblyUnitCostPreview(AppFormatters.formatCurrency(preview.estimatedUnitCostCents)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        l10n.assemblyTotalCostPreview(AppFormatters.formatCurrency(preview.estimatedTotalCostCents)),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (preview.missingItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itens Faltantes no Estoque (${preview.missingItems.length}):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...preview.missingItems.map(
                        (it) => Text(
                          '• ${it.productName}: Necessário ${AppFormatters.formatQuantity(it.quantityRequired, it.productBaseUnit)}, Estoque atual ${AppFormatters.formatQuantity(it.currentStock, it.productBaseUnit)} (Faltam ${AppFormatters.formatQuantity(it.missingQuantity, it.productBaseUnit)})',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '${l10n.recipeSection}:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: preview.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final it = preview.items[idx];
                    final unitCostCents = (it.unitCostMicrocents / 10000).round();
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
                                  it.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  '${l10n.recipeSection}: ${it.section} | ${l10n.productCostPrice}: ${AppFormatters.formatCurrency(unitCostCents)}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Exigido: ${AppFormatters.formatQuantity(it.quantityRequired, it.productBaseUnit)}\nSaldo: ${AppFormatters.formatQuantity(it.currentStock, it.productBaseUnit)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: it.isSufficient
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: it.isSufficient
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Text(
                              it.isSufficient ? 'OK' : 'Faltam ${AppFormatters.formatQuantity(it.missingQuantity, it.productBaseUnit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: it.isSufficient
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              Text(
                l10n.recipeQuantityPerBasket,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
