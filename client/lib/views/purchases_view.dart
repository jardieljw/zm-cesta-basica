import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';
import 'purchase_form_view.dart';

class PurchasesView extends StatefulWidget {
  const PurchasesView({super.key});

  @override
  State<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends State<PurchasesView> {
  final PurchaseService _purchaseService = PurchaseService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _purchaseService.getPurchases(
        status: _statusFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _purchases = items;
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
      case 'DRAFT':
        return Colors.amber.shade800;
      case 'CANCELED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'CONFIRMADA';
      case 'DRAFT':
        return 'RASCUNHO';
      case 'CANCELED':
        return 'CANCELADA';
      default:
        return status;
    }
  }

  Future<void> _showCancelDialog(Purchase purchase) async {
    final reasonController = TextEditingController();
    bool isCancelling = false;
    String? cancelError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Cancelar Compra #${purchase.purchaseNumber}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Esta operacao realizara o estorno contabil dos produtos no livro-razao. '
                    'Se os produtos ja foram consumidos e nao houver saldo suficiente, a operacao sera rejeitada.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
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
                      child: Text(cancelError!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                    ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo do Cancelamento (opcional)',
                      hintText: 'Ex: Devolucao ou erro de digitacao',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: isCancelling
                      ? null
                      : () async {
                          setDialogState(() {
                            isCancelling = true;
                            cancelError = null;
                          });
                          try {
                            await _purchaseService.cancelPurchase(
                              purchase.id,
                              reason: reasonController.text.trim().isNotEmpty
                                  ? reasonController.text.trim()
                                  : null,
                            );
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Compra cancelada e estornada com sucesso!')),
                              );
                              _loadPurchases();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isCancelling = false;
                              cancelError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar Estorno', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Compra #${purchase.purchaseNumber}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(purchase.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatStatus(purchase.status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Fornecedor: ${purchase.supplierName ?? "Nao informado"}', style: const TextStyle(fontSize: 15)),
                  Text('Data: ${_dateFormat.format(purchase.purchaseDate.toLocal())}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  if (purchase.notes != null) ...[
                    const SizedBox(height: 8),
                    Text('Observacoes: ${purchase.notes!}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                  const Divider(height: 32),
                  const Text('Itens da Compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...purchase.items.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item.packagingName != null
                              ? '${item.packagesCount} embalagens (${item.packagingName}) = ${item.quantityInBaseUnits} ${item.productBaseUnit}'
                              : '${item.quantityInBaseUnits} ${item.productBaseUnit} (direto na unidade base)',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currencyFormat.format(item.totalPriceReais),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Unit: ${_currencyFormat.format(item.unitPriceReais)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Geral:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        _currencyFormat.format(purchase.totalAmountReais),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras & Reposicao de Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nova Compra'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormView()),
          );
          if (created == true) {
            _loadPurchases();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por fornecedor ou NF...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadPurchases();
              },
            ),
          ),

          // Chips de filtro por status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _statusFilter == null,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _statusFilter = null);
                      _loadPurchases();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Confirmadas'),
                  selected: _statusFilter == 'CONFIRMED',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'CONFIRMED' : null);
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Rascunhos'),
                  selected: _statusFilter == 'DRAFT',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'DRAFT' : null);
                    _loadPurchases();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Canceladas'),
                  selected: _statusFilter == 'CANCELED',
                  onSelected: (val) {
                    setState(() => _statusFilter = val ? 'CANCELED' : null);
                    _loadPurchases();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

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
                            ElevatedButton(onPressed: _loadPurchases, child: const Text('Tentar Novamente')),
                          ],
                        ),
                      )
                    : _purchases.isEmpty
                        ? const Center(child: Text('Nenhuma compra cadastrada.'))
                        : RefreshIndicator(
                            onRefresh: _loadPurchases,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _purchases.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = _purchases[index];
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () => _showPurchaseDetails(p),
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(p.status).withOpacity(0.15),
                                      child: Text(
                                        '#${p.purchaseNumber}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _getStatusColor(p.status),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      p.supplierName ?? 'Fornecedor Nao Informado',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_dateFormat.format(p.purchaseDate.toLocal())),
                                          Text('${p.items.length} itens cadastrados'),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _currencyFormat.format(p.totalAmountReais),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (p.status == 'CONFIRMED') ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                            tooltip: 'Estornar Compra',
                                            onPressed: () => _showCancelDialog(p),
                                          ),
                                        ],
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
