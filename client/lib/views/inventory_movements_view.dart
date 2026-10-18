import '../widgets/shared/responsive_filter_bar.dart';
import 'package:flutter/material.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../core/api_client.dart';
import '../widgets/shared/approved_app_style.dart';

class InventoryMovementsView extends StatefulWidget {
  final String? initialProductId;
  final ApiClient? apiClient;

  const InventoryMovementsView({
    super.key,
    this.initialProductId,
    this.apiClient,
  });

  @override
  State<InventoryMovementsView> createState() => _InventoryMovementsViewState();
}

class _InventoryMovementsViewState extends State<InventoryMovementsView> {
  late final InventoryService _inventoryService;

  List<InventoryMovement> _movements = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedMovementType;

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService(client: widget.apiClient);
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _inventoryService.getMovements(
        productId: widget.initialProductId,
        movementType: _selectedMovementType,
        page: 1,
        pageSize: 100,
      );

      if (!mounted) return;
      setState(() {
        _movements = result['items'] as List<InventoryMovement>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'PURCHASE':
        return Colors.blue.shade700;
      case 'PURCHASE_CANCEL':
        return Colors.orange.shade800;
      case 'ADJUSTMENT_IN':
        return Colors.green.shade700;
      case 'ADJUSTMENT_OUT':
        return Colors.deepOrange.shade700;
      case 'LOSS':
        return Colors.red.shade700;
      case 'ASSEMBLY_CONSUME':
        return Colors.purple.shade700;
      case 'ASSEMBLY_PRODUCE':
        return Colors.teal.shade700;
      case 'SALE':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatMovementType(BuildContext context, String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'PURCHASE':
        return l10n.movementPurchase;
      case 'PURCHASE_CANCEL':
        return l10n.movementPurchaseCancel;
      case 'ADJUSTMENT_IN':
        return l10n.movementAdjustmentIn;
      case 'ADJUSTMENT_OUT':
        return l10n.movementAdjustmentOut;
      case 'LOSS':
        return l10n.movementLoss;
      case 'ASSEMBLY_CONSUME':
        return l10n.movementAssemblyConsume;
      case 'ASSEMBLY_PRODUCE':
        return l10n.movementAssemblyProduce;
      case 'SALE':
        return l10n.movementSale;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);

    return ApprovedPage(
      title: l10n.inventoryMovementsHeaderTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadMovements,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtros rapidos de tipo de movimento
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ResponsiveFilterBar(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: pColors.line),
                  label: Text(l10n.inventoryMovementsFilterAll),
                  selected: _selectedMovementType == null,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMovementType = null);
                      _loadMovements();
                    }
                  },
                ),
                FilterChip(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: pColors.line),
                  label: Text(l10n.inventoryMovementsFilterPurchase),
                  selected: _selectedMovementType == 'PURCHASE',
                  onSelected: (val) {
                    setState(
                      () => _selectedMovementType = val ? 'PURCHASE' : null,
                    );
                    _loadMovements();
                  },
                ),
                FilterChip(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: pColors.line),
                  label: Text(l10n.inventoryMovementsFilterCancel),
                  selected: _selectedMovementType == 'PURCHASE_CANCEL',
                  onSelected: (val) {
                    setState(
                      () => _selectedMovementType = val
                          ? 'PURCHASE_CANCEL'
                          : null,
                    );
                    _loadMovements();
                  },
                ),
                FilterChip(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: pColors.line),
                  label: Text(l10n.inventoryMovementsFilterAdjustment),
                  selected: _selectedMovementType == 'ADJUSTMENT_IN',
                  onSelected: (val) {
                    setState(
                      () =>
                          _selectedMovementType = val ? 'ADJUSTMENT_IN' : null,
                    );
                    _loadMovements();
                  },
                ),
                FilterChip(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: pColors.line),
                  label: Text(l10n.inventoryMovementsFilterAssembly),
                  selected: _selectedMovementType == 'ASSEMBLY_PRODUCE',
                  onSelected: (val) {
                    setState(
                      () => _selectedMovementType = val
                          ? 'ASSEMBLY_PRODUCE'
                          : null,
                    );
                    _loadMovements();
                  },
                ),
              ],
            ),
          ),

          // Lista de movimentacoes
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
                          onPressed: _loadMovements,
                          child: Text(l10n.commonRefresh),
                        ),
                      ],
                    ),
                  )
                : _movements.isEmpty
                ? Center(child: Text(l10n.inventoryMovementsEmpty))
                : RefreshIndicator(
                    onRefresh: _loadMovements,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _movements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final m = _movements[index];
                        final isPositive = m.quantityDelta > 0;
                        final deltaText = isPositive
                            ? '+${m.quantityDelta}'
                            : '${m.quantityDelta}';

                        return Container(
                          decoration: BoxDecoration(
                            color: pColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: pColors.line),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge com Delta
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isPositive
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      deltaText,
                                      style: TextStyle(
                                        color: isPositive
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Detalhes
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getBadgeColor(
                                                m.movementType,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _formatMovementType(
                                                context,
                                                m.movementType,
                                              ),
                                              style: TextStyle(
                                                color: _getBadgeColor(
                                                  m.movementType,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            AppFormatters.formatDateTime(
                                              m.occurredAt.toLocal(),
                                            ),
                                            style: TextStyle(
                                              color: pColors.sub,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        m.productName ??
                                            m.basketTypeName ??
                                            '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (m.reason != null &&
                                          m.reason!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          m.reason!,
                                          style: TextStyle(
                                            color: pColors.sub,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
