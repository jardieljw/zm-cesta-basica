import '../core/api_client.dart';
import '../widgets/shared/responsive_filter_bar.dart';
import 'package:flutter/material.dart';
import '../models/stock_summary.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'stock_adjustment_dialog.dart';
import 'inventory_movements_view.dart';
import '../widgets/shared/approved_app_style.dart';

class InventorySummaryView extends StatefulWidget {
  final ApiClient? apiClient;
  const InventorySummaryView({super.key, this.apiClient});

  @override
  State<InventorySummaryView> createState() => _InventorySummaryViewState();
}

class _InventorySummaryViewState extends State<InventorySummaryView> {
  late final InventoryService _inventoryService;
  late final ProductService _productService;

  List<ProductStockSummary> _items = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _belowMinimumOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService(client: widget.apiClient);
    _productService = ProductService(client: widget.apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = _inventoryService.getSummary(
        belowMinimumOnly: _belowMinimumOnly,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final productsFuture = _productService.getProducts(isActive: true);

      final results = await Future.wait([summaryFuture, productsFuture]);

      setState(() {
        _items = results[0] as List<ProductStockSummary>;
        _allProducts = results[1] as List<Product>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openAdjustmentDialog([String? productId]) async {
    final l10n = context.l10n;
    final result = await showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        products: _allProducts,
        initialProductId: productId,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventorySummaryAdjustmentSuccess)),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);

    return ApprovedPage(
      title: l10n.inventorySummaryHeaderTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: l10n.inventorySummaryHistoryTooltip,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryMovementsView(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: l10n.inventorySummaryAdjustmentTooltip,
          onPressed: () => _openAdjustmentDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadData,
        ),
      ],
      body: Column(
        children: [
          // Barra de pesquisa e filtro de estoque minimo
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.inventorySummarySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: pColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _loadData();
                  },
                ),
                const SizedBox(height: 8),
                ResponsiveFilterBar(
                  padding: EdgeInsets.zero,
                  children: [
                    FilterChip(
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: _belowMinimumOnly
                            ? Colors.red.shade400
                            : pColors.line,
                      ),
                      label: Text(l10n.inventorySummaryBelowMinFilter),
                      selected: _belowMinimumOnly,
                      selectedColor: Colors.red.withValues(alpha: 0.12),
                      checkmarkColor: Colors.red.shade700,
                      onSelected: (val) {
                        setState(() => _belowMinimumOnly = val);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteudo principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: Text(l10n.commonRefresh),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                ? Center(child: Text(l10n.inventorySummaryEmpty))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: pColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: item.isBelowMinimum
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : pColors.line,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.isBelowMinimum
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    item.isBelowMinimum
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    color: item.isBelowMinimum
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (item.isBelowMinimum)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                l10n.inventorySummaryStatusAlert,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            l10n.inventorySummaryCurrentStock(
                                              AppFormatters.formatQuantity(
                                                item.currentStock,
                                                item.baseUnit,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: item.isBelowMinimum
                                                  ? Colors.red.shade700
                                                  : pColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            l10n.inventorySummaryMinStock(
                                              AppFormatters.formatQuantity(
                                                item.minimumStock,
                                                item.baseUnit,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: pColors.sub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.tune),
                                  tooltip: l10n.inventorySummaryAdjustmentTooltip,
                                  onPressed: () =>
                                      _openAdjustmentDialog(item.productId),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
