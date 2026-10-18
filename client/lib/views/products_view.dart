import '../widgets/shared/responsive_filter_bar.dart';
import '../utils/scroll_layout.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import '../models/stock_summary.dart';
import '../services/inventory_service.dart';
import '../widgets/shared/approved_app_style.dart';
import 'stock_adjustment_dialog.dart';
import 'product_form_view.dart';
import 'packagings_dialog.dart';

class ProductsView extends StatefulWidget {
  final ProductService? service;
  final InventoryService? inventoryService;
  final bool initialLowStockOnly;
  const ProductsView({
    super.key,
    this.service,
    this.inventoryService,
    this.initialLowStockOnly = false,
  });

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  late final ProductService _service;
  late final InventoryService _inventoryService;
  final Set<String> _deletingProducts = {};

  List<Product> _products = [];
  Map<String, ProductStockSummary> _stockMap = {};
  bool _isLoading = true;
  String _selectedCategory = 'TODAS';
  bool? _filterActive;
  late bool _lowStockOnly;
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
    _service = widget.service ?? ProductService();
    _inventoryService =
        widget.inventoryService ?? InventoryService(client: _service.client);
    _lowStockOnly = widget.initialLowStockOnly;
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
      final productsFuture = _service.getProducts(
        category: _selectedCategory == 'TODAS' ? null : _selectedCategory,
        isActive: _filterActive,
        search: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
      );
      final summaryFuture = _inventoryService
          .getSummary()
          .catchError((_) => <ProductStockSummary>[]);

      final results = await Future.wait([productsFuture, summaryFuture]);
      final list = results[0] as List<Product>;
      final stockList = results[1] as List<ProductStockSummary>;

      if (!mounted) return;
      setState(() {
        _products = list;
        _stockMap = {for (final s in stockList) s.productId: s};
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

  List<Product> get _displayedProducts {
    if (!_lowStockOnly) return _products;
    return _products.where((p) {
      final stock = _stockMap[p.id];
      if (stock != null) {
        return stock.isBelowMinimum || stock.currentStock < p.minimumStock;
      }
      return false;
    }).toList();
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.inactivateProduct(p.id);
                _loadProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.productInactivatedSuccess),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.productInactivateError(e.toString()),
                      ),
                    ),
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

  Future<void> _confirmDeletion(Product product) async {
    if (_deletingProducts.contains(product.id)) return;
    setState(() => _deletingProducts.add(product.id));
    final l10n = context.l10n;
    try {
      final check = await _service.checkDeletion(product.id);
      if (!mounted) return;
      if (!check.canDelete) {
        final labels = check.reasons
            .map((reason) {
              switch (reason) {
                case 'RECIPES':
                  return l10n.productUsageRecipes;
                case 'PURCHASES':
                  return l10n.productUsagePurchases;
                case 'PRODUCTION':
                  return l10n.productUsageProduction;
                case 'MOVEMENTS':
                  return l10n.productUsageMovements;
                default:
                  return l10n.productUsageHistory;
              }
            })
            .join('\n');
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.productDeleteBlockedTitle),
            content: SingleChildScrollView(
              child: Text(l10n.productDeleteBlocked(product.name, labels)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonClose),
              ),
            ],
          ),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.productDeleteTitle),
          content: Text(l10n.productDeleteConfirm(product.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.productDeleteButton),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _service.deleteUnusedProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productDeletedSuccess)));
      await _loadProducts();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.toLocalizedMessage(error, l10n)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingProducts.remove(product.id));
    }
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
    final pColors = AppPalette.of(context);
    final l10n = context.l10n;

    return ApprovedPage(
      title: l10n.productsCatalogTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadProducts,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        tooltip: l10n.productNew,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormView()),
          );
          if (res == true) _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ApprovedChoice<bool>(
                    value: _lowStockOnly,
                    options: const [
                      ApprovedChoiceOption(
                        value: false,
                        label: 'Todos os produtos',
                        icon: Icons.inventory_2_outlined,
                      ),
                      ApprovedChoiceOption(
                        value: true,
                        label: 'Abaixo do mínimo',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                    onChanged: (val) => setState(() => _lowStockOnly = val),
                  ),
                ),
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
                    fillColor: pColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                  ),
                  onSubmitted: (_) => _loadProducts(),
                ),
                const SizedBox(height: 10),
                ResponsiveFilterBar(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(_formatCategory(context, cat)),
                      selected: isSelected,
                      selectedColor: pColors.soft,
                      backgroundColor: pColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? pColors.accent : pColors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? pColors.accent : pColors.line,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                          _loadProducts();
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Lista de Produtos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: pColors.sub,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _lowStockOnly
                                ? 'Nenhum produto abaixo do estoque mínimo'
                                : l10n.productEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: pColors.sub,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: fabScrollPadding(context, extended: false),
                      itemCount:
                          _displayedProducts.length + (_lowStockOnly ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_lowStockOnly && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ApprovedHeroCard(
                              eyebrow: 'Atenção ao estoque',
                              title: '${_displayedProducts.length} itens',
                              subtitle:
                                  'Produtos que atingiram ou ficaram abaixo do estoque mínimo',
                            ),
                          );
                        }
                        final p = _displayedProducts[
                            _lowStockOnly ? index - 1 : index];
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
    final pColors = AppPalette.of(context);
    final stock = _stockMap[p.id];
    final currentQty = stock?.currentStock;
    final isLow = stock?.isBelowMinimum == true ||
        (currentQty != null && currentQty < p.minimumStock);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: pColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: pColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pColors.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatCategory(context, p.category),
                    style: TextStyle(
                      color: pColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pColors.warnFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ABAIXO DO MÍNIMO',
                      style: TextStyle(
                        color: pColors.warn,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (!p.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pColors.soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.productInactive.toUpperCase(),
                      style: TextStyle(
                        color: pColors.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  p.baseUnit,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: pColors.sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: pColors.ink,
                decoration: p.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            if (p.sku != null || p.barcode != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (p.sku != null)
                    Text(
                      l10n.productSkuLabel(p.sku!),
                      style: TextStyle(
                        color: pColors.sub,
                        fontSize: 12,
                      ),
                    ),
                  if (p.sku != null && p.barcode != null)
                    const SizedBox(width: 12),
                  if (p.barcode != null)
                    Text(
                      l10n.productBarcodeLabel(p.barcode!),
                      style: TextStyle(
                        color: pColors.sub,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
            Divider(height: 24, color: pColors.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estoque atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentQty != null
                          ? AppFormatters.formatQuantity(currentQty, p.baseUnit)
                          : '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLow ? pColors.warn : pColors.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.productMinStock,
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatQuantity(p.minimumStock, p.baseUnit),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pColors.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.productCostPriceRef,
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(p.costPriceCents),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pColors.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.productSalePriceRef,
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(p.salePriceCents),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: pColors.line),
                      foregroundColor: pColors.ink,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Ajustar'),
                    onPressed: () async {
                      final res = await showDialog(
                        context: context,
                        builder: (_) => StockAdjustmentDialog(
                          products: _products,
                          initialProductId: p.id,
                        ),
                      );
                      if (res != null) _loadProducts();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: pColors.line),
                      foregroundColor: pColors.ink,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text(
                      l10n.productPackagingsCount(p.packagings.length),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          PackagingsDialog(product: p, service: _service),
                    ).then((_) => _loadProducts()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.commonEdit,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormView(productToEdit: p),
                      ),
                    );
                    if (res == true) _loadProducts();
                  },
                ),
                if (p.isActive)
                  IconButton(
                    icon: const Icon(Icons.visibility_off_outlined, size: 20),
                    tooltip: l10n.productInactivateButton,
                    onPressed: _deletingProducts.contains(p.id)
                        ? null
                        : () => _confirmInactivation(p),
                  ),
                IconButton(
                  icon: _deletingProducts.contains(p.id)
                      ? const Icon(Icons.hourglass_top, size: 20)
                      : const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                  tooltip: l10n.productDeleteButton,
                  onPressed: _deletingProducts.contains(p.id)
                      ? null
                      : () => _confirmDeletion(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
