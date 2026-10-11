import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'product_form_view.dart';
import 'packagings_dialog.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'TODAS';
  bool? _filterActive;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'TODAS',
    'ALIMENTACAO',
    'LIMPEZA',
    'CARNE',
    'OUTROS',
    'INSUMO',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getProducts(
        category: _selectedCategory == 'TODAS' ? null : _selectedCategory,
        isActive: _filterActive,
        search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
      );
      setState(() {
        _products = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.productLoadError(e.toString()))),
        );
      }
    }
  }

  void _confirmInactivation(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.productInactivateTitle),
        content: Text(context.l10n.productInactivateConfirm(p.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.inactivateProduct(p.id);
                _loadProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.productInactivatedSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.productInactivateError(e.toString()))),
                  );
                }
              }
            },
            child: Text(context.l10n.productInactivateButton),
          ),
        ],
      ),
    );
  }

  String _formatCategory(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'TODAS':
        return l10n.categoryAll;
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
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsCatalogTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.productNew),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormView()),
          );
          if (res == true) _loadProducts();
        },
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.productSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadProducts();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _loadProducts(),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_formatCategory(context, cat)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                              _loadProducts();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Lista de Produtos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              l10n.productEmpty,
                              style: const TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final p = _products[index];
                            return _buildProductCard(theme, p);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ThemeData theme, Product p) {
    final l10n = context.l10n;
    Color catColor;
    switch (p.category) {
      case 'ALIMENTACAO':
        catColor = Colors.orange.shade800;
        break;
      case 'LIMPEZA':
        catColor = Colors.blue.shade700;
        break;
      case 'CARNE':
        catColor = Colors.red.shade800;
        break;
      default:
        catColor = Colors.teal.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: catColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _formatCategory(context, p.category),
                    style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                if (!p.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.productInactive.toUpperCase(),
                      style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                const Spacer(),
                Text(
                  p.baseUnit,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: p.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            if (p.sku != null || p.barcode != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (p.sku != null) Text(l10n.productSkuLabel(p.sku!), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  if (p.barcode != null) Text(l10n.productBarcodeLabel(p.barcode!), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.productCostPriceRef, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(AppFormatters.formatCurrency(p.costPriceCents), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.productSalePriceRef, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(
                      AppFormatters.formatCurrency(p.salePriceCents),
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.productMinStock, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(AppFormatters.formatQuantity(p.minimumStock, p.baseUnit), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(l10n.productPackagingsCount(p.packagings.length)),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => PackagingsDialog(product: p),
                  ).then((_) => _loadProducts()),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.commonEdit,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductFormView(productToEdit: p)),
                    );
                    if (res == true) _loadProducts();
                  },
                ),
                if (p.isActive)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: l10n.productInactivateButton,
                    onPressed: () => _confirmInactivation(p),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
