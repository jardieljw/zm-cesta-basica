import 'package:flutter/material.dart';
import '../models/dispatch.dart';
import '../models/basket_type.dart';
import '../services/dispatch_service.dart';
import '../services/basket_service.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class _DispatchItemRow {
  BasketType? basketType;
  int quantity = 1;
  int unitPriceCents = 0;
  int availableStoreStock = 0;
  bool isLoadingStock = false;
  final TextEditingController notesController = TextEditingController();

  int get subtotalCents => quantity * unitPriceCents;
}

class DispatchFormView extends StatefulWidget {
  const DispatchFormView({super.key});

  @override
  State<DispatchFormView> createState() => _DispatchFormViewState();
}

class _DispatchFormViewState extends State<DispatchFormView> {
  final DispatchService _dispatchService = DispatchService();
  final BasketService _basketService = BasketService();
  final InventoryService _inventoryService = InventoryService();

  List<ResponsiblePerson> _responsiblePersons = [];
  ResponsiblePerson? _selectedPerson;
  List<BasketType> _basketTypes = [];

  final TextEditingController _notesController = TextEditingController();
  final List<_DispatchItemRow> _items = [];

  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final it in _items) {
      it.notesController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      final persons = await _dispatchService.getResponsiblePersons(isActive: true);
      final baskets = await _basketService.getBasketTypes(isActive: true);

      setState(() {
        _responsiblePersons = persons;
        _basketTypes = baskets;
        _isLoadingInitial = false;
      });

      if (_responsiblePersons.isNotEmpty) {
        _selectedPerson = _responsiblePersons.first;
      }
      if (_basketTypes.isNotEmpty && _items.isEmpty) {
        _addItem();
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoadingInitial = false;
      });
    }
  }

  void _addItem() {
    final row = _DispatchItemRow();
    if (_basketTypes.isNotEmpty) {
      final usedIds = _items.map((it) => it.basketType?.id).whereType<String>().toSet();
      final unused = _basketTypes.firstWhere(
        (b) => !usedIds.contains(b.id),
        orElse: () => _basketTypes.first,
      );
      row.basketType = unused;
      row.unitPriceCents = unused.defaultPriceCents;
      _fetchStockForRow(row);
    }
    setState(() {
      _items.add(row);
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].notesController.dispose();
        _items.removeAt(index);
      });
    }
  }

  Future<void> _fetchStockForRow(_DispatchItemRow row) async {
    if (row.basketType == null) return;
    setState(() => row.isLoadingStock = true);
    try {
      final res = await _inventoryService.getBasketStock(row.basketType!.id);
      final currentStock = (res['current_stock'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          row.availableStoreStock = currentStock;
          row.isLoadingStock = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => row.isLoadingStock = false);
      }
    }
  }

  int get _totalBaskets {
    int sum = 0;
    for (final it in _items) {
      sum += it.quantity;
    }
    return sum;
  }

  int get _totalReferenceCents {
    int sum = 0;
    for (final it in _items) {
      sum += it.subtotalCents;
    }
    return sum;
  }

  Future<void> _submitDispatch() async {
    final l10n = context.l10n;

    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dispatchSelectResponsible)),
      );
      return;
    }

    if (_items.isEmpty) return;

    // 1. Validate individual fields and calculate total quantity per basket type
    final totalQtyPerBasket = <String, int>{};
    for (final it in _items) {
      if (it.basketType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleSelectBasketTypeRequired)),
        );
        return;
      }
      if (it.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleQuantityMustBePositive)),
        );
        return;
      }
      totalQtyPerBasket[it.basketType!.id] = (totalQtyPerBasket[it.basketType!.id] ?? 0) + it.quantity;
    }

    // 2. Validate aggregate stock sufficiency for each basket type
    for (final it in _items) {
      final totalRequested = totalQtyPerBasket[it.basketType!.id] ?? it.quantity;
      if (it.availableStoreStock < totalRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.dispatchInsufficientStoreStock(it.basketType!.name, it.availableStoreStock, totalRequested),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // 3. Consolidate duplicate rows for same basket type before sending to backend
    final consolidatedMap = <String, DispatchItemCreate>{};
    for (final it in _items) {
      final bId = it.basketType!.id;
      final notes = it.notesController.text.trim();
      if (consolidatedMap.containsKey(bId)) {
        final existing = consolidatedMap[bId]!;
        final mergedNotes = [existing.notes, notes].where((s) => s != null && s.isNotEmpty).join('; ');
        consolidatedMap[bId] = DispatchItemCreate(
          basketTypeId: bId,
          quantity: existing.quantity + it.quantity,
          unitPriceCents: it.unitPriceCents > 0 ? it.unitPriceCents : existing.unitPriceCents,
          notes: mergedNotes.isNotEmpty ? mergedNotes : null,
        );
      } else {
        consolidatedMap[bId] = DispatchItemCreate(
          basketTypeId: bId,
          quantity: it.quantity,
          unitPriceCents: it.unitPriceCents,
          notes: notes.isNotEmpty ? notes : null,
        );
      }
    }

    final dispatchItems = consolidatedMap.values.toList();

    final data = StockDispatchCreate(
      responsiblePersonId: _selectedPerson!.id,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      items: dispatchItems,
    );

    try {
      await _dispatchService.createDispatch(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dispatchCreatedSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, l10n);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dispatchFormTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dispatchFormTitle),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.dispatchTotalBaskets}: $_totalBaskets ${l10n.commonUnit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${l10n.dispatchTotalReference}: ${AppFormatters.formatCurrency(_totalReferenceCents)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.dispatchSubmit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitDispatch,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Select Responsible Person Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 16,
                          child: Icon(Icons.person, color: Colors.blue.shade800, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.dispatchResponsible,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ResponsiblePerson>(
                      initialValue: _selectedPerson,
                      decoration: InputDecoration(
                        labelText: '${l10n.dispatchSelectResponsible} *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _responsiblePersons.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPerson = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.commonNotes,
                        hintText: 'Observações da saída física (opcional)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dispatchItemsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.dispatchAddItem),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;

              return Card(
                key: ValueKey(row.hashCode),
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<BasketType>(
                              initialValue: row.basketType,
                              decoration: InputDecoration(
                                labelText: '${l10n.dispatchItemBasket} *',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _basketTypes.map((b) {
                                return DropdownMenuItem(
                                  value: b,
                                  child: Text(b.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  row.basketType = val;
                                  if (val != null) {
                                    row.unitPriceCents = val.defaultPriceCents;
                                  }
                                });
                                _fetchStockForRow(row);
                              },
                            ),
                          ),
                          if (_items.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ],
                      ),
                      if (row.basketType != null &&
                          _items.where((it) => it.basketType?.id == row.basketType?.id).length > 1) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.amber.shade900),
                              const SizedBox(width: 4),
                              Text(
                                l10n.dispatchDuplicateBasketConsolidatedNotice,
                                style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Quantity
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: row.quantity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '${l10n.dispatchItemQuantity} *',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final qty = int.tryParse(val.trim()) ?? 0;
                                setState(() => row.quantity = qty);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reference Unit Price
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: (row.unitPriceCents / 100.0).toStringAsFixed(2).replaceAll('.', ','),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: l10n.dispatchItemUnitPrice,
                                prefixText: 'R\$ ',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final cleaned = val.replaceAll('.', '').replaceAll(',', '.').trim();
                                final parsed = (double.tryParse(cleaned) ?? 0.0) * 100;
                                setState(() => row.unitPriceCents = parsed.round());
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Subtotal display
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(l10n.dispatchItemSubtotal, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                Text(
                                  AppFormatters.formatCurrency(row.subtotalCents),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stock indicator
                      Row(
                        children: [
                          if (row.isLoadingStock)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          else
                            Icon(
                              row.availableStoreStock >= row.quantity ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                              size: 16,
                              color: row.availableStoreStock >= row.quantity ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.dispatchAvailableStoreStock(row.availableStoreStock),
                            style: TextStyle(
                              fontSize: 12,
                              color: row.availableStoreStock >= row.quantity ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: row.notesController,
                        decoration: InputDecoration(
                          labelText: l10n.dispatchItemNotes,
                          hintText: 'Ex: Cesta personalizada, lote específico',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
