import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../services/basket_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'basket_type_form_view.dart';
import 'recipe_view.dart';

class BasketTypesView extends StatefulWidget {
  const BasketTypesView({super.key});

  @override
  State<BasketTypesView> createState() => _BasketTypesViewState();
}

class _BasketTypesViewState extends State<BasketTypesView> {
  final BasketService _service = BasketService();

  List<BasketType> _basketTypes = [];
  bool _isLoading = true;
  String _selectedCategory = 'TODAS';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'TODAS',
    'PADRAO',
    'NATALINA',
    'CARNE',
    'PERSONALIZADA',
  ];

  @override
  void initState() {
    super.initState();
    _loadBasketTypes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBasketTypes() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getBasketTypes(
        category: _selectedCategory == 'TODAS' ? null : _selectedCategory,
        search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
      );
      setState(() {
        _basketTypes = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.basketTypeLoadError(e.toString()))),
        );
      }
    }
  }

  void _confirmInactivation(BasketType bt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.basketTypeInactivateTitle),
        content: Text(context.l10n.basketTypeInactivateConfirm(bt.name)),
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
                await _service.inactivateBasketType(bt.id);
                _loadBasketTypes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.basketTypeInactivatedSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.basketTypeInactivateError(e.toString()))),
                  );
                }
              }
            },
            child: Text(context.l10n.basketTypeInactivateButton),
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
      case 'PADRAO':
        return l10n.categoryStandard;
      case 'NATALINA':
        return l10n.categoryChristmas;
      case 'CARNE':
        return l10n.categoryMeat;
      case 'PERSONALIZADA':
        return l10n.categoryCustom;
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
        title: Text(l10n.basketTypesHeaderTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadBasketTypes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.basketTypeNew),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BasketTypeFormView()),
          );
          if (res == true) _loadBasketTypes();
        },
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.basketTypeSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadBasketTypes();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _loadBasketTypes(),
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
                              _loadBasketTypes();
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
          // Lista de Tipos de Cestas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _basketTypes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              l10n.basketTypeEmpty,
                              style: const TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBasketTypes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _basketTypes.length,
                          itemBuilder: (context, index) {
                            final bt = _basketTypes[index];
                            return _buildBasketTypeCard(theme, bt);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasketTypeCard(ThemeData theme, BasketType bt) {
    final l10n = context.l10n;
    final activeRecipe = bt.activeRecipe;

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
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Text(
                    bt.code,
                    style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatCategory(context, bt.category),
                    style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!bt.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.productInactive.toUpperCase(),
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(bt.defaultPriceCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bt.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: bt.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            if (bt.description != null && bt.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(bt.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  activeRecipe != null ? Icons.verified : Icons.warning_amber_rounded,
                  size: 18,
                  color: activeRecipe != null ? Colors.green : Colors.amber.shade800,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activeRecipe != null
                        ? l10n.basketTypeRecipeActive(activeRecipe.versionNumber, activeRecipe.items.length)
                        : l10n.basketTypeRecipeNone,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: activeRecipe != null ? Colors.green.shade800 : Colors.amber.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(l10n.basketTypeManageRecipe),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecipeView(basketType: bt)),
                    );
                    _loadBasketTypes();
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.commonEdit,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BasketTypeFormView(basketTypeToEdit: bt)),
                    );
                    if (res == true) _loadBasketTypes();
                  },
                ),
                if (bt.isActive)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: l10n.basketTypeInactivateButton,
                    onPressed: () => _confirmInactivation(bt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
