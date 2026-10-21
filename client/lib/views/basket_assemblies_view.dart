import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/basket_type.dart';
import '../services/basket_service.dart';
import '../services/basket_assembly_service.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/scroll_layout.dart';
import 'basket_assembly_form_view.dart';
import 'basket_disassembly_view.dart';
import '../widgets/shared/approved_app_style.dart';

class BasketAssembliesView extends StatefulWidget {
  final BasketType basketType;
  final ApiClient? apiClient;
  final String? focusBatchId;
  const BasketAssembliesView({
    super.key,
    required this.basketType,
    this.apiClient,
    this.focusBatchId,
  });
  @override
  State<BasketAssembliesView> createState() => _BasketAssembliesViewState();
}

class _BasketAssembliesViewState extends State<BasketAssembliesView> {
  late final BasketAssemblyService _service;
  late BasketType _basket;
  List<Map<String, dynamic>> _history = [];
  int _page = 1;
  int _totalPages = 1;
  int? _stock;
  bool _loading = true;
  bool _pending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _basket = widget.basketType;
    _service = BasketAssemblyService(client: widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        BasketService(client: widget.apiClient).getBasketType(_basket.id),
        _service.history(_basket.id, _page, focusBatchId: widget.focusBatchId),
        _service.pending(_basket.id),
      ]);
      final basket = results[0] as BasketType;
      final history = results[1] as Map<String, dynamic>;
      int? stock;
      if (basket.tracksFinishedStock) {
        final response = await InventoryService(
          client: widget.apiClient,
        ).getBasketStock(basket.id);
        stock = (response['current_stock'] as num).toInt();
      }
      if (!mounted) return;
      setState(() {
        _basket = basket;
        _history = (history['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _totalPages = (history['total_pages'] as num).toInt();
        _stock = stock;
        _pending = results[2] != null;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BasketAssemblyFormView(
          basketType: _basket,
          apiClient: widget.apiClient,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _page = 1;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.assemblySaved)));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);
    final canRegister =
        _basket.isActive &&
        _basket.tracksFinishedStock &&
        _basket.activeRecipe != null;
    return ApprovedPage(
      title: l10n.assemblyHistoryTitle(_basket.name),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
        ),
      ],
      floatingActionButton:
          !_loading && _error == null && (canRegister || _pending)
          ? FloatingActionButton.extended(
              shape: const StadiumBorder(),
              backgroundColor: pColors.accent,
              foregroundColor: pColors.accentInk,
              onPressed: _register,
              icon: const Icon(Icons.add),
              label: Text(
                _pending ? l10n.assemblyRetry : l10n.assemblyRegister,
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: Text(l10n.commonRefresh),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: fabScrollPadding(context, horizontal: 0, top: 0),
                    children: [
                      if (_stock != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: pColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: pColors.line),
                          ),
                          child: Text(
                            l10n.assemblyStandardStock(_stock!),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: pColors.ink,
                            ),
                          ),
                        ),
                      if (!canRegister)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            !_basket.isActive
                                ? l10n.assemblyInactiveHelp
                                : !_basket.tracksFinishedStock
                                ? l10n.assemblyNoStockHelp
                                : l10n.assemblyNoRecipeHelp,
                          ),
                        ),
                      if (_pending)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.assemblyPendingHelp),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.assemblyHistory,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: pColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.assemblyHistoryHelp,
                        style: TextStyle(color: pColors.sub, fontSize: 13),
                      ),
                      if (_history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(l10n.assemblyHistoryEmpty),
                        ),
                      for (final batch in _history) _batchCard(batch),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _page > 1
                                ? () {
                                    _page--;
                                    _load();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: l10n.assemblyPreviousPage,
                          ),
                          Flexible(
                            child: Text(l10n.assemblyPage(_page, _totalPages)),
                          ),
                          IconButton(
                            onPressed: _page < _totalPages
                                ? () {
                                    _page++;
                                    _load();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: l10n.assemblyNextPage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _batchCard(Map<String, dynamic> batch) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);
    final isCustom = batch['is_custom'] == true;
    final isDirectSale = batch['is_direct_sale'] == true;
    final undone = batch['status'] == 'DISASSEMBLED';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Material(
        color: pColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: pColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ExpansionTile(
            initiallyExpanded: widget.focusBatchId == batch['id'],
            tilePadding: EdgeInsets.zero,
            title: Text(
              l10n.assemblyBatch(
                (batch['batch_number'] as num).toInt(),
                (batch['quantity_produced'] as num).toInt(),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: pColors.ink,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatDateTime(
                    DateTime.parse(batch['occurred_at'] as String).toLocal(),
                  ),
                  style: TextStyle(color: pColors.sub, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDirectSale
                            ? Colors.purple.withValues(alpha: 0.12)
                            : Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isDirectSale
                            ? l10n.assemblyOriginSale
                            : l10n.assemblyOriginAdvance,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDirectSale
                              ? Colors.purple.shade700
                              : Colors.teal.shade700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: undone
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        undone ? l10n.assemblyUndone : l10n.assemblyRecorded,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: undone
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCustom) Text(l10n.assemblyCustom),
                if (isCustom && batch['custom_description'] != null)
                  Text(batch['custom_description'] as String),
                if (isCustom && batch['current_batch_stock'] != null)
                  Text(
                    l10n.assemblyCustomStock(
                      (batch['current_batch_stock'] as num).toInt(),
                    ),
                  ),
              ],
            ),
            children: [
              if (!undone && batch['status'] == 'CONFIRMED')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.undo),
                    label: Text(l10n.catalogDisassemble),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BasketDisassemblyView(
                            batch: batch,
                            apiClient: widget.apiClient,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.catalogDisassemblyDone),
                          ),
                        );
                      }
                      await _load();
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.assemblyRecordedCost(
                    AppFormatters.formatCurrency(
                      batch['total_cost_cents'] as num,
                    ),
                  ),
                ),
              ),
              if (batch['recipe_version_number'] != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.recipeVersionItem(
                      (batch['recipe_version_number'] as num).toInt(),
                    ),
                  ),
                ),
              if (batch['notes'] != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(batch['notes'] as String),
                ),
              if (batch['cancellation_reason'] != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(batch['cancellation_reason'] as String),
                ),
              for (final raw in batch['items'] as List)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(raw['product_name'] as String),
                  subtitle: Text(
                    AppFormatters.formatQuantity(
                      raw['quantity_consumed_base_units'] as num,
                      raw['product_base_unit'] as String,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
