import 'package:flutter/material.dart';
import '../models/stock_summary.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../services/product_service.dart';
import 'stock_adjustment_dialog.dart';
import 'inventory_movements_view.dart';

class InventorySummaryView extends StatefulWidget {
  const InventorySummaryView({super.key});

  @override
  State<InventorySummaryView> createState() => _InventorySummaryViewState();
}

class _InventorySummaryViewState extends State<InventorySummaryView> {
  final InventoryService _inventoryService = InventoryService();
  final ProductService _productService = ProductService();

  List<ProductStockSummary> _items = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _belowMinimumOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
    final result = await showDialog(
      context: context,
      builder: (_) => StockAdjustmentDialog(
        products: _allProducts,
        initialProductId: productId,
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajuste de estoque registrado com sucesso!')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldo de Estoque em Tempo Real'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Extrato do Razao Contabil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryMovementsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Ajuste Manual',
            onPressed: () => _openAdjustmentDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa e filtro de estoque minimo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou SKU...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) {
                      _searchQuery = val.trim();
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Apenas Abaixo do Minimo'),
                  selected: _belowMinimumOnly,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red.shade800,
                  onSelected: (val) {
                    setState(() => _belowMinimumOnly = val);
                    _loadData();
                  },
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
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadData, child: const Text('Tentar Novamente')),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(child: Text('Nenhum item encontrado no estoque.'))
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  elevation: item.isBelowMinimum ? 2 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: item.isBelowMinimum
                                        ? BorderSide(color: Colors.red.shade300, width: 1.5)
                                        : BorderSide.none,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: item.isBelowMinimum
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      child: Icon(
                                        item.isBelowMinimum
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_outline,
                                        color: item.isBelowMinimum
                                            ? Colors.red.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (item.isBelowMinimum)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade600,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'ABAIXO DO MINIMO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Text('Saldo Atual: ', style: TextStyle(color: Colors.grey.shade700)),
                                          Text(
                                            '${item.currentStock} ${item.baseUnit}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: item.isBelowMinimum ? Colors.red.shade800 : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text('Minimo: ${item.minimumStock} ${item.baseUnit}',
                                              style: TextStyle(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.tune),
                                      tooltip: 'Ajustar Estoque Deste Produto',
                                      onPressed: () => _openAdjustmentDialog(item.productId),
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
