import 'package:flutter/material.dart';
import '../models/production_batch.dart';
import '../services/production_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'production_assembly_view.dart';
import 'production_disassembly_dialog.dart';

class ProductionBatchesView extends StatefulWidget {
  const ProductionBatchesView({super.key});

  @override
  State<ProductionBatchesView> createState() => _ProductionBatchesViewState();
}

class _ProductionBatchesViewState extends State<ProductionBatchesView> {
  final ProductionService _productionService = ProductionService();

  List<ProductionBatch> _batches = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _statusFilter;
  bool? _isCustomFilter;
  String _searchQuery = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _productionService.getBatches(
        status: _statusFilter,
        isCustom: _isCustomFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _currentPage,
        pageSize: 50,
      );

      setState(() {
        _batches = result.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green.shade700;
      case 'DISASSEMBLED':
        return Colors.orange.shade800;
      case 'CANCELED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'CONFIRMED':
        return l10n.productionStatusConfirmed;
      case 'DISASSEMBLED':
        return l10n.productionStatusDisassembled;
      case 'CANCELED':
        return l10n.productionStatusCanceled;
      default:
        return status;
    }
  }

  Future<void> _openDisassembly(ProductionBatch batch) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ProductionDisassemblyDialog(batch: batch),
    );

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: Text(result['message'] as String? ?? context.l10n.productionDisassembledSuccess),
          ),
        );
      }
      _loadBatches();
    }
  }

  Future<void> _openCancelReversal(ProductionBatch batch) async {
    final reasonController = TextEditingController();
    bool isCancelling = false;
    String? cancelError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.productionBatchCancelTitle(batch.batchNumber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.productionBatchCancelDescription,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  if (cancelError != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        cancelError!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                      ),
                    ),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: '${context.l10n.productionBatchCancelReasonLabel} *',
                      hintText: context.l10n.productionBatchCancelReasonHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.commonBack),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isCancelling
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.length < 3) {
                            setDialogState(() {
                              cancelError = context.l10n.validationMinChars(3);
                            });
                            return;
                          }

                          setDialogState(() {
                            isCancelling = true;
                            cancelError = null;
                          });

                          try {
                            final res = await _productionService.cancelBatch(
                              batch.id,
                              reason: reason,
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red.shade800,
                                  content: Text(
                                    res['message'] as String? ?? context.l10n.productionBatchCancelSuccess,
                                  ),
                                ),
                              );
                              _loadBatches();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isCancelling = false;
                              cancelError = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
                            });
                          }
                        },
                  child: isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.l10n.productionBatchCancelConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBatchDetails(ProductionBatch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(batch.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(batch.status)),
                        ),
                        child: Text(
                          _formatStatus(batch.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(batch.status),
                          ),
                        ),
                      ),
                      if (batch.isCustom) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade400),
                          ),
                          child: Text(
                            context.l10n.productionCustom,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                      if (batch.isDirectSale) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade400),
                          ),
                          child: Text(
                            context.l10n.productionDirectSale,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lote #${batch.batchNumber} - ${batch.basketTypeName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (batch.isCustom && batch.customDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.productionBatchDescriptionLabel(batch.customDescription!),
                      style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStat(
                          context.l10n.productionBatchDetailProduced,
                          '${batch.quantityProduced} un',
                          Icons.inventory,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailStat(
                          context.l10n.productionBatchDetailStock,
                          '${batch.currentBatchStock} un',
                          Icons.warehouse,
                        ),
                      ),
                    ],
                  ),
                  if (batch.quantityDisassembled > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailStat(
                      context.l10n.productionBatchDetailDisassembled,
                      '${batch.quantityDisassembled} un',
                      Icons.remove_circle_outline,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailStat(
                          context.l10n.productionBatchDetailUnitCost,
                          AppFormatters.formatCurrency(batch.unitCostCents),
                          Icons.monetization_on_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailStat(
                          context.l10n.productionBatchDetailTotalCost,
                          AppFormatters.formatCurrency(batch.totalCostCents),
                          Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.productionBatchDetailDate(AppFormatters.formatDateTime(batch.occurredAt)),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  if (batch.notes != null && batch.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.productionBatchDetailNotes(batch.notes!),
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
                  ],
                  if (batch.canceledAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.productionBatchDetailDisassembledAt(
                        AppFormatters.formatDateTime(batch.canceledAt!),
                        batch.cancellationReason ?? '-',
                      ),
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const Divider(height: 32),
                  Text(
                    context.l10n.productionBatchSnapshotTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...batch.items.map((it) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    context.l10n.productionBatchSectionLabel(
                                      it.section,
                                      AppFormatters.formatCurrencyFromMicrocents(it.unitCostMicrocents),
                                    ),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatters.formatQuantity(it.quantityConsumedBaseUnits, it.productBaseUnit),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  context.l10n.productionBatchTotalItemCost(AppFormatters.formatCurrency(it.totalCostCents)),
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (batch.status == 'CONFIRMED' && batch.currentBatchStock > 0)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.build_circle_outlined, color: Colors.orange),
                            label: Text(context.l10n.productionBatchDisassembleButton, style: const TextStyle(color: Colors.orange)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _openDisassembly(batch);
                            },
                          ),
                        ),
                        if (batch.currentBatchStock >= batch.quantityProduced) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.replay, color: Colors.red),
                              label: Text(context.l10n.productionBatchCancelButton, style: const TextStyle(color: Colors.red)),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openCancelReversal(batch);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.productionBatchesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.commonRefresh,
            onPressed: _loadBatches,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(context.l10n.productionBatchNew),
        onPressed: () async {
          final created = await Navigator.push<ProductionBatch>(
            context,
            MaterialPageRoute(builder: (_) => const ProductionAssemblyView()),
          );
          if (created != null) {
            _loadBatches();
          }
        },
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.l10n.productionBatchSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _currentPage = 1;
                    _loadBatches();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _statusFilter,
                hint: Text(context.l10n.productionBatchFilterAllStatus),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.l10n.productionBatchFilterAllStatus)),
                  DropdownMenuItem(value: 'CONFIRMED', child: Text(context.l10n.productionBatchFilterConfirmed)),
                  DropdownMenuItem(value: 'DISASSEMBLED', child: Text(context.l10n.productionBatchFilterDisassembled)),
                ],
                onChanged: (val) {
                  setState(() {
                    _statusFilter = val;
                    _currentPage = 1;
                  });
                  _loadBatches();
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<bool?>(
                value: _isCustomFilter,
                hint: Text(context.l10n.productionBatchFilterAllTypes),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.l10n.productionBatchFilterAllTypes)),
                  DropdownMenuItem(value: false, child: Text(context.l10n.productionBatchFilterStandard)),
                  DropdownMenuItem(value: true, child: Text(context.l10n.productionBatchFilterCustom)),
                ],
                onChanged: (val) {
                  setState(() {
                    _isCustomFilter = val;
                    _currentPage = 1;
                  });
                  _loadBatches();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${context.l10n.commonError}: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadBatches,
              child: Text(context.l10n.commonTryAgain),
            ),
          ],
        ),
      );
    }

    if (_batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.l10n.productionBatchEmpty,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(context.l10n.productionBatchMountFirst),
              onPressed: () async {
                final created = await Navigator.push<ProductionBatch>(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductionAssemblyView()),
                );
                if (created != null) {
                  _loadBatches();
                }
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          final b = _batches[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showBatchDetails(b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${b.batchNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.basketTypeName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (b.isCustom && b.customDescription != null)
                                Text(
                                  b.customDescription!,
                                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        if (b.isDirectSale) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade400),
                            ),
                            child: Text(
                              'Venda Direta',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(b.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(b.status)),
                          ),
                          child: Text(
                            _formatStatus(b.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(b.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${context.l10n.productionQuantityProduced}: ${b.quantityProduced} un  |  '
                          '${context.l10n.productionCurrentStock}: ${b.currentBatchStock} un'
                          '${b.quantityDisassembled > 0 ? "  |  ${context.l10n.productionQuantityDisassembled}: ${b.quantityDisassembled} un" : ""}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${context.l10n.productionUnitCost}: ${AppFormatters.formatCurrency(b.unitCostCents)}',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppFormatters.formatDateTime(b.occurredAt),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Text(
                          'Total: ${AppFormatters.formatCurrency(b.totalCostCents)}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                    if (b.status == 'CONFIRMED' && b.currentBatchStock > 0) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: Text(context.l10n.productionBatchViewIngredients, style: const TextStyle(fontSize: 12)),
                            onPressed: () => _showBatchDetails(b),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.build_circle_outlined, size: 16, color: Colors.orange),
                            label: Text(context.l10n.productionDisassemble, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                            onPressed: () => _openDisassembly(b),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
