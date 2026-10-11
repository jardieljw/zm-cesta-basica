import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../models/product.dart';
import '../services/basket_service.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';

class RecipeView extends StatefulWidget {
  final BasketType basketType;

  const RecipeView({super.key, required this.basketType});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final BasketService _basketService = BasketService();
  final ProductService _productService = ProductService();

  List<RecipeVersion> _versions = [];
  RecipeVersion? _selectedVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _basketService.getRecipeVersions(widget.basketType.id);
      RecipeVersion? active = list.where((v) => v.status == 'ACTIVE').firstOrNull ?? list.firstOrNull;

      setState(() {
        _versions = list;
        _selectedVersion = active;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recipeLoadError(e.toString()))),
        );
      }
    }
  }

  void _showNewRecipeVersionDialog() async {
    final l10n = context.l10n;
    // Carrega produtos ativos disponiveis
    List<Product> activeProducts = [];
    try {
      activeProducts = await _productService.getProducts(isActive: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recipeLoadProductsError(e.toString()))),
        );
      }
      return;
    }

    if (activeProducts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recipeNoActiveProducts)),
        );
      }
      return;
    }

    // Itens da nova versao inicializados a partir da versao atual ou vazios
    List<Map<String, dynamic>> draftItems = [];
    if (_selectedVersion != null) {
      for (var it in _selectedVersion!.items) {
        // Apenas mantem se o produto estiver entre os ativos
        if (activeProducts.any((p) => p.id == it.productId)) {
          draftItems.add({
            'product_id': it.productId,
            'quantity_in_base_units': it.quantityInBaseUnits,
            'section': it.section,
            'is_required': it.isRequired,
          });
        }
      }
    }

    final notesCtrl = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 650,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recipeDialogTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text(
                    l10n.recipeDialogSubtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.recipeDialogNotesLabel,
                      hintText: l10n.recipeDialogNotesHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.recipeDialogItemsTitle(draftItems.length), style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.recipeAddIngredient),
                        onPressed: () {
                          // Adiciona primeiro produto ativo ainda nao na lista
                          final available = activeProducts.where(
                            (p) => !draftItems.any((it) => it['product_id'] == p.id),
                          ).toList();

                          if (available.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.recipeDialogAllProductsAdded)),
                            );
                            return;
                          }

                          final defaultProd = available.first;
                          setDialogState(() {
                            draftItems.add({
                              'product_id': defaultProd.id,
                              'quantity_in_base_units': 1,
                              'section': 'ALIMENTACAO',
                              'is_required': true,
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: draftItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l10n.recipeDialogNoItems),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: draftItems.length,
                            itemBuilder: (context, index) {
                              final item = draftItems[index];
                              final selectedProd = activeProducts.firstWhere(
                                (p) => p.id == item['product_id'],
                                orElse: () => activeProducts.first,
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: item['product_id'] as String,
                                          items: activeProducts.map((p) => DropdownMenuItem(
                                            value: p.id,
                                            child: Text('${p.name} (${p.baseUnit})', overflow: TextOverflow.ellipsis),
                                          )).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              if (draftItems.any((it) => it != item && it['product_id'] == val)) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(l10n.recipeDialogDuplicateItem)),
                                                );
                                                return;
                                              }
                                              setDialogState(() => item['product_id'] = val);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item['quantity_in_base_units'].toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: l10n.recipeDialogQtyLabel(selectedProd.baseUnit),
                                            border: const OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            final n = int.tryParse(val.trim());
                                            if (n != null && n > 0) {
                                              item['quantity_in_base_units'] = n;
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: item['section'] as String,
                                          items: [
                                            DropdownMenuItem(value: 'ALIMENTACAO', child: Text(l10n.categoryFood)),
                                            DropdownMenuItem(value: 'LIMPEZA', child: Text(l10n.categoryCleaning)),
                                            DropdownMenuItem(value: 'CARNE', child: Text(l10n.categoryMeat)),
                                            DropdownMenuItem(value: 'OUTROS', child: Text(l10n.categoryOthers)),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setDialogState(() => item['section'] = val);
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          setDialogState(() => draftItems.removeAt(index));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () async {
                      if (draftItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.recipeDialogValidationMinItems)),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await _basketService.createRecipeVersion(widget.basketType.id, {
                          'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                          'items': draftItems,
                        });
                        _loadVersions();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.recipeDialogSaveSuccess)),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.recipeDialogSaveError(e.toString()))),
                          );
                        }
                      }
                    },
                    child: Text(l10n.recipeDialogSaveButton),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipeAppTitle(widget.basketType.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadVersions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.playlist_add),
        label: Text(l10n.recipeNewVersionButton),
        onPressed: _showNewRecipeVersionDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _versions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          l10n.recipeEmptyVersions,
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(l10n.recipeCreateFirstVersion),
                          onPressed: _showNewRecipeVersionDialog,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImmutabilityBanner(theme),
                      const SizedBox(height: 16),
                      _buildVersionSelectorCard(theme),
                      const SizedBox(height: 16),
                      if (_selectedVersion != null) _buildRecipeItemsSection(theme, _selectedVersion!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildImmutabilityBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.recipeImmutabilityBanner,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSelectorCard(ThemeData theme) {
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.history, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Text(l10n.recipeVersionDisplayed, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedVersion?.id,
              items: _versions.map((v) {
                final isActive = v.status == 'ACTIVE';
                return DropdownMenuItem(
                  value: v.id,
                  child: Row(
                    children: [
                      Text(l10n.recipeVersionItem(v.versionNumber)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? l10n.recipeStatusActive : l10n.recipeStatusArchived,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green.shade800 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (id) {
                final chosen = _versions.firstWhere((v) => v.id == id);
                setState(() => _selectedVersion = chosen);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeItemsSection(ThemeData theme, RecipeVersion version) {
    final l10n = context.l10n;
    // Agrupa itens por secao (ALIMENTACAO, LIMPEZA, CARNE, etc.)
    final Map<String, List<RecipeItem>> grouped = {};
    for (var item in version.items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (version.notes != null && version.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(l10n.recipeNotesLabel(version.notes!), style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ...grouped.entries.map((entry) {
          final section = entry.key;
          final items = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recipeSectionHeader(_formatSection(context, section), items.length),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const Divider(height: 20),
                  ...items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              it.productName ?? l10n.recipeUnknownIngredient(it.productId),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Text(
                            AppFormatters.formatQuantity(it.quantityInBaseUnits, it.productBaseUnit ?? 'un'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatSection(BuildContext context, String sec) {
    final l10n = context.l10n;
    switch (sec) {
      case 'ALIMENTACAO':
        return l10n.categoryFood;
      case 'LIMPEZA':
        return l10n.categoryCleaning;
      case 'CARNE':
        return l10n.categoryMeat;
      case 'OUTROS':
        return l10n.categoryOthers;
      default:
        return sec;
    }
  }
}
