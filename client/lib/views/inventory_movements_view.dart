import 'package:flutter/material.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';

class InventoryMovementsView extends StatefulWidget {
  final String? initialProductId;

  const InventoryMovementsView({super.key, this.initialProductId});

  @override
  State<InventoryMovementsView> createState() => _InventoryMovementsViewState();
}

class _InventoryMovementsViewState extends State<InventoryMovementsView> {
  final InventoryService _inventoryService = InventoryService();

  List<InventoryMovement> _movements = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedMovementType;

  @override
  void initState() {
    super.initState();
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

      setState(() {
        _movements = result['items'] as List<InventoryMovement>;
        _isLoading = false;
      });
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryMovementsHeaderTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
            onPressed: _loadMovements,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros rapidos de tipo de movimento
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.inventoryMovementsFilterAll),
                  selected: _selectedMovementType == null,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMovementType = null);
                      _loadMovements();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.inventoryMovementsFilterPurchase),
                  selected: _selectedMovementType == 'PURCHASE',
                  onSelected: (val) {
                    setState(() => _selectedMovementType = val ? 'PURCHASE' : null);
                    _loadMovements();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.inventoryMovementsFilterCancel),
                  selected: _selectedMovementType == 'PURCHASE_CANCEL',
                  onSelected: (val) {
                    setState(() => _selectedMovementType = val ? 'PURCHASE_CANCEL' : null);
                    _loadMovements();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.inventoryMovementsFilterAdjustment),
                  selected: _selectedMovementType == 'ADJUSTMENT_IN',
                  onSelected: (val) {
                    setState(() => _selectedMovementType = val ? 'ADJUSTMENT_IN' : null);
                    _loadMovements();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.inventoryMovementsFilterAssembly),
                  selected: _selectedMovementType == 'ASSEMBLY_PRODUCE',
                  onSelected: (val) {
                    setState(() => _selectedMovementType = val ? 'ASSEMBLY_PRODUCE' : null);
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
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadMovements, child: Text(l10n.commonRefresh)),
                          ],
                        ),
                      )
                    : _movements.isEmpty
                        ? Center(child: Text(l10n.inventoryMovementsEmpty))
                        : RefreshIndicator(
                            onRefresh: _loadMovements,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _movements.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final m = _movements[index];
                                final isPositive = m.quantityDelta > 0;
                                final deltaText = isPositive ? '+${m.quantityDelta}' : '${m.quantityDelta}';

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Badge com Delta
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            deltaText,
                                            style: TextStyle(
                                              color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Detalhes
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getBadgeColor(m.movementType),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      _formatMovementType(context, m.movementType),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    AppFormatters.formatDateTime(m.occurredAt.toLocal()),
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                m.productName ?? m.basketTypeName ?? '-',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              if (m.reason != null && m.reason!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  m.reason!,
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
