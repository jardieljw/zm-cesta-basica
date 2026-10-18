import '../widgets/shared/responsive_filter_bar.dart';
import '../utils/scroll_layout.dart';
import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../services/basket_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import 'basket_type_form_view.dart';
import 'recipe_view.dart';
import '../core/api_client.dart';
import 'basket_assemblies_view.dart';
import 'basket_assembly_form_view.dart';
import '../widgets/shared/approved_app_style.dart';
import '../utils/api_error_mapper.dart';

class BasketTypesView extends StatefulWidget {
  final ApiClient? apiClient;
  const BasketTypesView({super.key, this.apiClient});

  @override
  State<BasketTypesView> createState() => _BasketTypesViewState();
}

class _BasketTypesViewState extends State<BasketTypesView> {
  late final BasketService _service;

  List<BasketType> _basketTypes = [];
  bool _isLoading = true;
  String _selectedCategory = 'TODAS';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _deletingBaskets = {};
  final Set<String> _checkingDeletion = {};

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
    _service = BasketService(client: widget.apiClient);
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
        search: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _basketTypes = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.basketTypeLoadError(e.toString())),
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.inactivateBasketType(bt.id);
                _loadBasketTypes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.basketTypeInactivatedSuccess),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.basketTypeInactivateError(e.toString()),
                      ),
                    ),
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

  Future<void> _confirmDeletion(BasketType basket) async {
    if (_deletingBaskets.contains(basket.id)) return;
    setState(() {
      _deletingBaskets.add(basket.id);
      _checkingDeletion.add(basket.id);
    });
    final l10n = context.l10n;
    try {
      final check = await _service.checkDeletion(basket.id);
      if (!mounted) return;
      setState(() => _checkingDeletion.remove(basket.id));
      if (check['can_delete'] != true) {
        final reasons = (check['reasons'] as List)
            .map((reason) {
              switch (reason) {
                case 'ACTIVE_SALES':
                  return l10n.basketDeleteActiveSales;
                case 'STOCK_REMAINS':
                  return l10n.basketDeleteStockRemains;
                case 'ACTIVE_DISPATCHES':
                  return l10n.basketDeleteActiveDispatches;
                default:
                  return l10n.basketDeleteBlockedHelp;
              }
            })
            .join('\n\n');
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.basketDeleteBlockedTitle),
            content: SingleChildScrollView(child: Text(reasons)),
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
      final permanent = check['deletion_mode'] == 'PERMANENT';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.basketDeleteButton),
          content: Text(
            permanent
                ? l10n.basketDeleteUnusedConfirm(basket.name)
                : l10n.basketDeleteCatalogConfirm(basket.name),
          ),
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
              child: Text(l10n.basketDeleteButton),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _checkingDeletion.add(basket.id));
      final result = await _service.deleteFromCatalog(basket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['deletion_mode'] == 'PERMANENT'
                ? l10n.basketDeletedPermanently
                : l10n.basketRemovedFromCatalog,
          ),
        ),
      );
      await _loadBasketTypes();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.toLocalizedMessage(error, l10n)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingBaskets.remove(basket.id);
          _checkingDeletion.remove(basket.id);
        });
      }
    }
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
    final pColors = AppPalette.of(context);
    final l10n = context.l10n;

    return ApprovedPage(
      title: l10n.basketTypesHeaderTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadBasketTypes,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        tooltip: l10n.basketTypeNew,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BasketTypeFormView()),
          );
          if (res == true) _loadBasketTypes();
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
                  onSubmitted: (_) => _loadBasketTypes(),
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
                          _loadBasketTypes();
                        }
                      },
                    );
                  }).toList(),
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
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.basketTypeEmpty,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBasketTypes,
                    child: ListView.builder(
                      padding: fabScrollPadding(context, extended: false),
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

  void _openBasketHub(BasketType bt) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ApprovedSurface(
            padding: const EdgeInsets.all(22),
            radius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bt.name,
                            style: Theme.of(dialogCtx).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${bt.code} · ${_formatCategory(dialogCtx, bt.category)} · ${AppFormatters.formatCurrency(bt.defaultPriceCents)}',
                            style: Theme.of(dialogCtx).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ApprovedRow(
                  title: '1. Composição',
                  subtitle: bt.activeRecipe != null
                      ? 'Receita ativa (versão ${bt.activeRecipe!.versionNumber}, ${bt.activeRecipe!.items.length} itens)'
                      : 'Sem receita ativa definida',
                  icon: Icons.receipt_long,
                  onTap: () async {
                    Navigator.pop(dialogCtx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeView(basketType: bt),
                      ),
                    );
                    _loadBasketTypes();
                  },
                ),
                const SizedBox(height: 8),
                ApprovedRow(
                  title: '2. Registrar montagem',
                  subtitle: 'Produção padrão ou personalizada com baixa de estoque',
                  icon: Icons.add_circle_outline,
                  onTap: () async {
                    Navigator.pop(dialogCtx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasketAssemblyFormView(
                          basketType: bt,
                          apiClient: widget.apiClient,
                        ),
                      ),
                    );
                    _loadBasketTypes();
                  },
                ),
                const SizedBox(height: 8),
                ApprovedRow(
                  title: '3. Histórico de montagens',
                  subtitle: 'Lotes montados e custos unitários congelados',
                  icon: Icons.history,
                  onTap: () async {
                    Navigator.pop(dialogCtx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasketAssembliesView(
                          basketType: bt,
                          apiClient: widget.apiClient,
                        ),
                      ),
                    );
                    _loadBasketTypes();
                  },
                ),
                const SizedBox(height: 20),
                ApprovedSecondaryButton(
                  text: l10n.commonClose,
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasketTypeCard(ThemeData theme, BasketType bt) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);
    final activeRecipe = bt.activeRecipe;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: pColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: pColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openBasketHub(bt),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                            bt.code,
                            style: TextStyle(
                              color: pColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pColors.page,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: pColors.line),
                          ),
                          child: Text(
                            _formatCategory(context, bt.category),
                            style: TextStyle(
                              color: pColors.sub,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!bt.isActive) ...[
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
                              l10n.productInactive.toUpperCase(),
                              style: TextStyle(
                                color: pColors.warn,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatCurrency(bt.defaultPriceCents),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: pColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bt.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: pColors.ink,
                  decoration: bt.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              if (bt.description != null && bt.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  bt.description!,
                  style: TextStyle(color: pColors.sub, fontSize: 13),
                ),
              ],
              Divider(height: 24, color: pColors.line),
              Row(
                children: [
                  Icon(
                    activeRecipe != null
                        ? Icons.verified
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: activeRecipe != null ? Colors.green : pColors.warn,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activeRecipe != null
                          ? l10n.basketTypeRecipeActive(
                              activeRecipe.versionNumber,
                              activeRecipe.items.length,
                            )
                          : l10n.basketTypeRecipeNone,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: activeRecipe != null
                            ? Colors.green.shade800
                            : pColors.warn,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: pColors.line),
                      foregroundColor: pColors.ink,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text(l10n.assemblyHistory),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BasketAssembliesView(
                            basketType: bt,
                            apiClient: widget.apiClient,
                          ),
                        ),
                      );
                      if (mounted) _loadBasketTypes();
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: const StadiumBorder(),
                      backgroundColor: pColors.soft,
                      foregroundColor: pColors.accent,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(l10n.basketTypeManageRecipe),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeView(basketType: bt),
                        ),
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
                        MaterialPageRoute(
                          builder: (_) =>
                              BasketTypeFormView(basketTypeToEdit: bt),
                        ),
                      );
                      if (res == true) _loadBasketTypes();
                    },
                  ),
                  if (bt.isActive)
                    IconButton(
                      icon: const Icon(Icons.visibility_off_outlined, size: 20),
                      tooltip: l10n.basketTypeInactivateButton,
                      onPressed: () => _confirmInactivation(bt),
                    ),
                  IconButton(
                    tooltip: l10n.basketDeleteButton,
                    onPressed: _deletingBaskets.contains(bt.id)
                        ? null
                        : () => _confirmDeletion(bt),
                    icon: _checkingDeletion.contains(bt.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
