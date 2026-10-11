import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
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
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  void _confirmInactivation(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inativar Produto'),
        content: Text(
          'Deseja inativar o produto "${p.name}"?\n\n'
          'A exclusao fisica e proibida para preservar a integridade das transacoes anteriores. O produto deixara de aparecer em novas composicoes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
                    const SnackBar(content: Text('Produto inativado com sucesso.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Falha ao inativar produto: $e')),
                  );
                }
              }
            },
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo de Produtos e Insumos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
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
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, SKU ou codigo de barras...',
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
                          label: Text(cat),
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
                            const Text(
                              'Nenhum produto encontrado com os filtros selecionados.',
                              style: TextStyle(color: Colors.black54, fontSize: 16),
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
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: catColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    p.category,
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
                    child: const Text('INATIVO', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                Text(
                  '${p.baseUnit}',
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
                  if (p.sku != null) Text('SKU: ${p.sku}  ', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  if (p.barcode != null) Text('EAN: ${p.barcode}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                    const Text('Estoque Minimo:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('${p.minimumStock} ${p.baseUnit}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custo Ref.:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('R\$ ${p.costPriceReais.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Venda Ref.:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(
                      'R\$ ${p.salePriceReais.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
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
                  label: Text('Embalagens (${p.packagings.length})'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => PackagingsDialog(product: p),
                  ).then((_) => _loadProducts()),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
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
                    tooltip: 'Inativar',
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
