import '../utils/scroll_layout.dart';
import '../core/api_client.dart';
import '../utils/api_error_mapper.dart';
import '../services/catalog_action_service.dart';
import '../widgets/shared/catalog_blockers.dart';
import 'package:flutter/material.dart';
import '../models/basket_type.dart';
import '../models/product.dart';
import '../services/basket_service.dart';
import '../services/product_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';

class RecipeView extends StatefulWidget {
  final BasketType basketType;
  final ApiClient? apiClient;
  final int? initialVersionNumber;

  const RecipeView({
    super.key,
    required this.basketType,
    this.apiClient,
    this.initialVersionNumber,
  });

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  late final BasketService _basketService;
  late final ProductService _productService;
  late final CatalogActionService _actions;

  List<RecipeVersion> _versions = [];
  RecipeVersion? _selectedVersion;
  bool _isLoading = true;
  bool _recipeBusy = false;
  Map<String, dynamic>? _pendingAction;
  Map<String, dynamic>? _rejectedDraft;

  void _openRecoveredDraft() {
    final command = _rejectedDraft;
    if (command == null) return;
    final editing = command['method'] == 'PUT';
    _showNewRecipeVersionDialog(
      editing: editing,
      editingNumber: editing
          ? int.tryParse((command['path'] as String).split('/').last)
          : null,
      recovered: Map<String, dynamic>.from(command['payload'] as Map),
    );
  }

  Future<void> _resumeAction() async {
    final pending = _pendingAction;
    if (pending == null || _recipeBusy) return;
    setState(() => _recipeBusy = true);
    try {
      await _actions.run(
        'recipe_${widget.basketType.id}',
        pending['path'] as String,
        pending['method'] as String,
        Map<String, dynamic>.from(pending['payload'] as Map),
      );
      await _loadVersions();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMapper.toLocalizedMessage(error, context.l10n),
            ),
          ),
        );
      }
    } finally {
      final pending = await _actions.pending('recipe_${widget.basketType.id}');
      final rejected = await _actions.rejectedDraft(
        'recipe_${widget.basketType.id}',
      );
      if (mounted) {
        setState(() {
          _recipeBusy = false;
          _pendingAction = pending;
          _rejectedDraft = rejected;
        });
      }
    }
  }

  Future<void> _recipeAction(String action) async {
    final recipe = _selectedVersion;
    if (recipe == null || _recipeBusy || _pendingAction != null) return;
    setState(() => _recipeBusy = true);
    final path =
        '/api/v1/basket-types/${widget.basketType.id}/recipes/${recipe.versionNumber}';
    try {
      if (action == 'remove' || action == 'edit') {
        final check =
            await (widget.apiClient ?? ApiClient()).get('$path/deletion-check')
                as Map;
        if (!mounted) return;
        if (check['can_modify'] != true) {
          await showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(context.l10n.catalogRecipeProtected),
              content: SingleChildScrollView(
                child: CatalogBlockers(
                  apiClient: widget.apiClient,
                  blockers: (check['blockers'] as List)
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.commonClose),
                ),
              ],
            ),
          );
          return;
        }
      }
      if (!mounted) return;
      if (action == 'edit') {
        _showNewRecipeVersionDialog(editing: true);
        return;
      }
      if (action == 'remove') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.catalogDeleteRecipe),
            content: Text(context.l10n.catalogDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.catalogDeleteRecipe),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      await _actions.run(
        'recipe_${widget.basketType.id}',
        action == 'remove' ? path : '$path/$action',
        action == 'remove' ? 'DELETE' : 'POST',
        {},
      );
      if (mounted) await _loadVersions();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMapper.toLocalizedMessage(error, context.l10n),
            ),
          ),
        );
      }
    } finally {
      final pending = await _actions.pending('recipe_${widget.basketType.id}');
      final rejected = await _actions.rejectedDraft(
        'recipe_${widget.basketType.id}',
      );
      if (mounted) {
        setState(() {
          _recipeBusy = false;
          _pendingAction = pending;
          _rejectedDraft = rejected;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _basketService = BasketService(client: widget.apiClient);
    _productService = ProductService(client: widget.apiClient);
    _actions = CatalogActionService(client: widget.apiClient);
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _basketService.getRecipeVersions(widget.basketType.id);
      final pending = await _actions.pending('recipe_${widget.basketType.id}');
      final rejected = await _actions.rejectedDraft(
        'recipe_${widget.basketType.id}',
      );
      RecipeVersion? active =
          list
              .where((v) => v.versionNumber == widget.initialVersionNumber)
              .firstOrNull ??
          list.where((v) => v.status == 'ACTIVE').firstOrNull ??
          list.firstOrNull;

      setState(() {
        _pendingAction = pending;
        _rejectedDraft = rejected;
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

  void _showNewRecipeVersionDialog({
    bool editing = false,
    int? editingNumber,
    Map<String, dynamic>? recovered,
  }) async {
    if (_pendingAction != null || (_recipeBusy && !editing)) return;
    final l10n = context.l10n;
    // Carrega produtos ativos disponiveis
    List<Product> activeProducts = [];
    try {
      activeProducts = await _productService.getProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.recipeLoadProductsError(e.toString())),
          ),
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

    // Keep every ingredient visible, including inactive referenced products.
    final draftItems = recovered != null
        ? (recovered['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
        : (_selectedVersion?.items ?? []).map((it) => it.toJson()).toList();
    final unavailable = draftItems
        .where((it) => !activeProducts.any((p) => p.id == it['product_id']))
        .toList();
    if (unavailable.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.catalogInactiveRecipeHelp)));
      }
      return;
    }
    final initialPrice = recovered != null
        ? recovered['suggested_price_cents'] as int?
        : _selectedVersion?.suggestedPriceCents;
    final notesCtrl = TextEditingController(
      text: recovered != null
          ? recovered['notes'] as String?
          : editing
          ? _selectedVersion?.notes
          : null,
    );
    final priceCtrl = TextEditingController(
      text: initialPrice == null
          ? ''
          : (initialPrice / 100).toStringAsFixed(2).replaceAll('.', ','),
    );

    bool saving = false;
    String? saveError;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return PopScope(
            canPop: !saving,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: 650,
                child: AbsorbPointer(
                  absorbing: saving,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              editing
                                  ? l10n.catalogEditRecipe
                                  : l10n.recipeDialogTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        Text(
                          l10n.recipeDialogSubtitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.catalogRecipePrice,
                            helperText: l10n.catalogRecipePriceHelp,
                            helperMaxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.recipeDialogItemsTitle(draftItems.length),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.recipeAddIngredient),
                              onPressed: () {
                                // Adiciona primeiro produto ativo ainda nao na lista
                                final available = activeProducts
                                    .where(
                                      (p) =>
                                          p.isActive &&
                                          !draftItems.any(
                                            (it) => it['product_id'] == p.id,
                                          ),
                                    )
                                    .toList();

                                if (available.isEmpty) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.recipeDialogAllProductsAdded,
                                      ),
                                    ),
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
                                    final selectedProd = activeProducts
                                        .firstWhere(
                                          (p) => p.id == item['product_id'],
                                          orElse: () => activeProducts.first,
                                        );

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 12,
                                          children: [
                                            SizedBox(
                                              width:
                                                  MediaQuery.sizeOf(
                                                        context,
                                                      ).width <
                                                      600
                                                  ? MediaQuery.sizeOf(
                                                          context,
                                                        ).width -
                                                        144
                                                  : 230,
                                              child: DropdownButtonFormField<String>(
                                                isExpanded: true,
                                                initialValue:
                                                    item['product_id']
                                                        as String,
                                                items: activeProducts
                                                    .map(
                                                      (p) => DropdownMenuItem(
                                                        value: p.id,
                                                        enabled: p.isActive,
                                                        child: Text(
                                                          '${p.name} (${p.baseUnit})${p.isActive ? '' : ' · ${l10n.catalogInactiveIngredient}'}',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    if (draftItems.any(
                                                      (it) =>
                                                          it != item &&
                                                          it['product_id'] ==
                                                              val,
                                                    )) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            l10n.recipeDialogDuplicateItem,
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    setDialogState(
                                                      () => item['product_id'] =
                                                          val,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 140,
                                              child: TextFormField(
                                                initialValue:
                                                    item['quantity_in_base_units']
                                                        .toString(),
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: l10n
                                                      .recipeDialogQtyLabel(
                                                        selectedProd.baseUnit,
                                                      ),
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                                onChanged: (val) {
                                                  final n = int.tryParse(
                                                    val.trim(),
                                                  );
                                                  if (n != null && n > 0) {
                                                    item['quantity_in_base_units'] =
                                                        n;
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 190,
                                              child:
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    isExpanded: true,
                                                    initialValue:
                                                        item['section']
                                                            as String,
                                                    items: [
                                                      DropdownMenuItem(
                                                        value: 'ALIMENTACAO',
                                                        child: Text(
                                                          l10n.categoryFood,
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'LIMPEZA',
                                                        child: Text(
                                                          l10n.categoryCleaning,
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'CARNE',
                                                        child: Text(
                                                          l10n.categoryMeat,
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'OUTROS',
                                                        child: Text(
                                                          l10n.categoryOthers,
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setDialogState(
                                                          () =>
                                                              item['section'] =
                                                                  val,
                                                        );
                                                      }
                                                    },
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setDialogState(
                                                  () => draftItems.removeAt(
                                                    index,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (saveError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              saveError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (saving) const LinearProgressIndicator(),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () async {
                            if (draftItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.recipeDialogValidationMinItems,
                                  ),
                                ),
                              );
                              return;
                            }
                            if (draftItems.any(
                              (it) => !activeProducts.any(
                                (p) => p.id == it['product_id'] && p.isActive,
                              ),
                            )) {
                              setDialogState(
                                () =>
                                    saveError = l10n.catalogInactiveRecipeHelp,
                              );
                              return;
                            }
                            setDialogState(() {
                              saving = true;
                              saveError = null;
                            });
                            try {
                              final rawPrice = priceCtrl.text.trim();
                              final parsedPrice = rawPrice.isEmpty
                                  ? null
                                  : double.tryParse(
                                      rawPrice.replaceAll(',', '.'),
                                    );
                              if (rawPrice.isNotEmpty &&
                                  (parsedPrice == null ||
                                      !parsedPrice.isFinite ||
                                      parsedPrice < 0)) {
                                setDialogState(() {
                                  saving = false;
                                  saveError = l10n.catalogInvalidPrice;
                                });
                                return;
                              }
                              await _actions.run(
                                'recipe_${widget.basketType.id}',
                                '/api/v1/basket-types/${widget.basketType.id}/recipes${editing ? '/${editingNumber ?? _selectedVersion!.versionNumber}' : ''}',
                                editing ? 'PUT' : 'POST',
                                {
                                  'suggested_price_cents': parsedPrice == null
                                      ? null
                                      : (parsedPrice * 100).round(),
                                  'notes': notesCtrl.text.trim().isNotEmpty
                                      ? notesCtrl.text.trim()
                                      : null,
                                  'items': draftItems,
                                },
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              await _loadVersions();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.recipeDialogSaveSuccess),
                                  ),
                                );
                              }
                            } catch (e) {
                              final pending = await _actions.pending(
                                'recipe_${widget.basketType.id}',
                              );
                              if (mounted) {
                                setState(() => _pendingAction = pending);
                                _rejectedDraft = await _actions.rejectedDraft(
                                  'recipe_${widget.basketType.id}',
                                );
                                if (pending != null) {
                                  Navigator.pop(ctx);
                                } else {
                                  setDialogState(() {
                                    saving = false;
                                    saveError =
                                        ApiErrorMapper.toLocalizedMessage(
                                          e,
                                          l10n,
                                        );
                                  });
                                }
                              }
                            }
                          },
                          child: Text(
                            editing
                                ? l10n.commonSave
                                : l10n.recipeDialogSaveButton,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    final pColors = AppPalette.of(context);
    final l10n = context.l10n;

    return ApprovedPage(
      title: l10n.recipeAppTitle(widget.basketType.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadVersions,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        tooltip: l10n.recipeNewVersionButton,
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        onPressed: _showNewRecipeVersionDialog,
        child: const Icon(Icons.playlist_add),
      ),
      body: Column(
        children: [
          if (_pendingAction == null && _rejectedDraft != null)
            TextButton(
              onPressed: _recipeBusy ? null : _openRecoveredDraft,
              child: Text(l10n.catalogRestoreRecipeDraft),
            ),
          if (_pendingAction != null)
            TextButton(
              onPressed: _recipeBusy ? null : _resumeAction,
              child: Text(l10n.catalogRetryAction),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _versions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: pColors.sub,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.recipeEmptyVersions,
                            style: TextStyle(fontSize: 16, color: pColors.sub),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              backgroundColor: pColors.accent,
                              foregroundColor: pColors.accentInk,
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.recipeCreateFirstVersion),
                            onPressed: _showNewRecipeVersionDialog,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: fabScrollPadding(
                      context,
                      horizontal: 0,
                      top: 0,
                      extended: false,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImmutabilityBanner(pColors),
                        const SizedBox(height: 16),
                        _buildVersionSelectorCard(pColors),
                        const SizedBox(height: 16),
                        if (_selectedVersion != null)
                          _buildRecipeItemsSection(
                            theme,
                            pColors,
                            _selectedVersion!,
                          ),
                        if (_selectedVersion != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(l10n.catalogEditRecipe),
                                  onPressed: () => _recipeAction('edit'),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(l10n.catalogDeleteRecipe),
                                  onPressed: () => _recipeAction('remove'),
                                ),
                                TextButton(
                                  onPressed: () => _recipeAction(
                                    _selectedVersion!.status == 'ACTIVE'
                                        ? 'deactivate'
                                        : 'activate',
                                  ),
                                  child: Text(
                                    _selectedVersion!.status == 'ACTIVE'
                                        ? l10n.catalogDeactivateRecipe
                                        : l10n.catalogActivateRecipe,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmutabilityBanner(AppPalette pColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pColors.soft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pColors.line),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock, color: pColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.recipeImmutabilityBanner,
              style: TextStyle(
                fontSize: 13,
                color: pColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSelectorCard(AppPalette pColors) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: pColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Icon(Icons.history, color: pColors.sub),
            const SizedBox(width: 12),
            Text(
              l10n.recipeVersionDisplayed,
              style: TextStyle(fontWeight: FontWeight.w700, color: pColors.ink),
            ),
            const SizedBox(width: 12),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.12)
                              : pColors.soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isActive
                              ? l10n.recipeStatusActive
                              : l10n.recipeStatusArchived,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.green.shade700
                                : pColors.sub,
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

  Widget _buildRecipeItemsSection(
    ThemeData theme,
    AppPalette pColors,
    RecipeVersion version,
  ) {
    final l10n = context.l10n;
    final Map<String, List<RecipeItem>> grouped = {};
    for (var item in version.items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (version.suggestedPriceCents != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${l10n.saleUnitPrice}: ${AppFormatters.formatCurrency(version.suggestedPriceCents!)}',
            ),
          ),
        if (version.notes != null && version.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              l10n.recipeNotesLabel(version.notes!),
              style: TextStyle(fontStyle: FontStyle.italic, color: pColors.sub),
            ),
          ),
        ...grouped.entries.map((entry) {
          final section = entry.key;
          final items = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: pColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pColors.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recipeSectionHeader(
                      _formatSection(context, section),
                      items.length,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: pColors.accent,
                    ),
                  ),
                  const Divider(height: 20),
                  ...items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              it.productName ??
                                  l10n.recipeUnknownIngredient(it.productId),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: pColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            AppFormatters.formatQuantity(
                              it.quantityInBaseUnits,
                              it.productBaseUnit ?? 'un',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: pColors.ink,
                            ),
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
