import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _errorMessage;
  DashboardSummary? _summary;

  // Filter state
  String _selectedFilterType = 'today';
  DateTime _selectedDate = DateTime.now();
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String _formatDateParam(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? dateParam;
      String? startParam;
      String? endParam;
      int? monthParam;
      int? yearParam;

      if (_selectedFilterType == 'date') {
        dateParam = _formatDateParam(_selectedDate);
      } else if (_selectedFilterType == 'range') {
        startParam = _formatDateParam(_selectedRange.start);
        endParam = _formatDateParam(_selectedRange.end);
      } else if (_selectedFilterType == 'month') {
        monthParam = _selectedMonth;
        yearParam = _selectedYear;
      } else if (_selectedFilterType == 'year') {
        yearParam = _selectedYear;
      }

      final summary = await _dashboardService.getDashboardSummary(
        filterType: _selectedFilterType,
        date: dateParam,
        startDate: startParam,
        endDate: endParam,
        month: monthParam,
        year: yearParam,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Dashboard',
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterBar(theme),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          onPressed: _loadDashboard,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_summary != null) ...[
                _buildFilterInfoBadge(theme, _summary!.filterInfo),
                const SizedBox(height: 16),
                _buildProductionSection(theme, _summary!.production),
                const SizedBox(height: 16),
                _buildSalesSection(theme, _summary!.sales),
                const SizedBox(height: 16),
                _buildDispatchesSection(theme, _summary!.dispatches),
                const SizedBox(height: 16),
                _buildInventorySection(theme, _summary!.inventory),
                const SizedBox(height: 16),
                _buildFinancialSection(theme, _summary!.financial),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(l10n.dashboardFilterToday),
                  selected: _selectedFilterType == 'today',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilterType = 'today');
                      _loadDashboard();
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.dashboardFilterDate),
                  selected: _selectedFilterType == 'date',
                  onSelected: (selected) async {
                    if (selected) {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _selectedFilterType = 'date';
                        });
                        _loadDashboard();
                      }
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.dashboardFilterRange),
                  selected: _selectedFilterType == 'range',
                  onSelected: (selected) async {
                    if (selected) {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: _selectedRange,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedRange = picked;
                          _selectedFilterType = 'range';
                        });
                        _loadDashboard();
                      }
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.dashboardFilterMonth),
                  selected: _selectedFilterType == 'month',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilterType = 'month');
                      _loadDashboard();
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.dashboardFilterYear),
                  selected: _selectedFilterType == 'year',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilterType = 'year');
                      _loadDashboard();
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.dashboardFilterAll),
                  selected: _selectedFilterType == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilterType = 'all');
                      _loadDashboard();
                    }
                  },
                ),
              ],
            ),
            if (_selectedFilterType == 'date') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Data selecionada: ${AppFormatters.formatDate(_selectedDate)}'),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Alterar'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadDashboard();
                      }
                    },
                  ),
                ],
              ),
            ] else if (_selectedFilterType == 'range') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Período: ${AppFormatters.formatDate(_selectedRange.start)} até ${AppFormatters.formatDate(_selectedRange.end)}'),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: const Text('Alterar'),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: _selectedRange,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _selectedRange = picked);
                        _loadDashboard();
                      }
                    },
                  ),
                ],
              ),
            ] else if (_selectedFilterType == 'month') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: _selectedMonth,
                    items: List.generate(12, (i) => i + 1).map((m) {
                      return DropdownMenuItem(value: m, child: Text('Mês $m'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        _loadDashboard();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: [2024, 2025, 2026, 2027].map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _loadDashboard();
                      }
                    },
                  ),
                ],
              ),
            ] else if (_selectedFilterType == 'year') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ano: '),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: [2024, 2025, 2026, 2027].map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _loadDashboard();
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterInfoBadge(ThemeData theme, FilterInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Período em Exibição: ${info.label}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 1: PRODUCTION
  // ==========================================
  Widget _buildProductionSection(ThemeData theme, DashboardProductionSummary prod) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  radius: 20,
                  child: Icon(Icons.precision_manufacturing, color: Colors.purple.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionProduction,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text('Lotes (${prod.batches.length})'),
                  onPressed: () => _showProductionBatchesDrilldown(prod.batches),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showProductionBatchesDrilldown(prod.batches),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardAssembledBaskets,
                            style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${prod.assembledCount} un.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (prod.byBasketType.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Montagem por Tipo de Cesta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: prod.byBasketType.map((bt) {
                  return Chip(
                    backgroundColor: Colors.purple.shade50,
                    label: Text(
                      '${bt.basketTypeName}: ${bt.count} un.',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProductionBatchesDrilldown(List<DashboardBatchRecord> batches) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalhamento de Lotes Montados (${batches.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: batches.isEmpty
                        ? const Center(child: Text('Nenhum lote montado no período.'))
                        : ListView.separated(
                            itemCount: batches.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final b = batches[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple.shade100,
                                  child: Text('#${b.batchNumber}', style: TextStyle(color: Colors.purple.shade900, fontSize: 12)),
                                ),
                                title: Text(
                                  b.basketTypeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Qtd: ${b.quantityProduced} un. | Custo un: ${AppFormatters.formatCurrency(b.unitCostCents)} | Data: ${AppFormatters.formatDateTime(b.occurredAt)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(b.totalCostCents),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      b.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: b.status == 'COMPLETED' ? Colors.green.shade700 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 2: SALES
  // ==========================================
  Widget _buildSalesSection(ThemeData theme, DashboardSalesSummary sales) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  radius: 20,
                  child: Icon(Icons.point_of_sale, color: Colors.indigo.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionSales,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text('Vendas (${sales.sales.length})'),
                  onPressed: () => _showSalesDrilldown(sales.sales),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showSalesDrilldown(sales.sales),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardSoldBaskets,
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sales.soldCount} un.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showSalesDrilldown(sales.sales),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardTotalSold,
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatCurrency(sales.totalSoldCents),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (sales.byBasketType.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Vendas por Tipo de Cesta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: sales.byBasketType.map((bt) {
                  return Chip(
                    backgroundColor: Colors.indigo.shade50,
                    label: Text(
                      '${bt.basketTypeName}: ${bt.count} un. (${AppFormatters.formatCurrency(bt.totalCents)})',
                      style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSalesDrilldown(List<DashboardSaleRecord> sales) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalhamento de Vendas (${sales.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: sales.isEmpty
                        ? const Center(child: Text('Nenhuma venda registrada no período.'))
                        : ListView.separated(
                            itemCount: sales.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = sales[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text('#${s.saleNumber}', style: TextStyle(color: Colors.indigo.shade900, fontSize: 12)),
                                ),
                                title: Text(
                                  s.customerName ?? 'Cliente Balcão / Consumidor',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Modo: ${s.saleMode} | Pagto: ${s.paymentMode} | ${AppFormatters.formatDateTime(s.saleDate)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(s.totalAmountCents),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      s.paymentStatus,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: s.paymentStatus == 'PAID' ? Colors.green.shade700 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 3: DISPATCHES
  // ==========================================
  Widget _buildDispatchesSection(ThemeData theme, DashboardDispatchesSummary disp) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 20,
                  child: Icon(Icons.local_shipping, color: Colors.blue.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionDispatches,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text('Saídas (${disp.dispatches.length})'),
                  onPressed: () => _showDispatchesDrilldown(disp.dispatches),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardDispatchedBaskets,
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${disp.dispatchedCount} un.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showUnremittedDrilldown(disp.responsibleUnremittedItems),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardUnremittedCash,
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatCurrency(disp.responsibleUnremittedCents),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDivergencesDrilldown(disp.pendingDivergences),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: disp.pendingDivergencesCount > 0 ? Colors.red.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: disp.pendingDivergencesCount > 0 ? Colors.red.shade300 : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardPendingDivergences,
                            style: TextStyle(
                              fontSize: 12,
                              color: disp.pendingDivergencesCount > 0 ? Colors.red.shade900 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${disp.pendingDivergencesCount}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: disp.pendingDivergencesCount > 0 ? Colors.red.shade900 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (disp.pendingDivergencesCount > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.warning, color: Colors.red, size: 16),
                  label: Text('Examinar Divergências Pendentes (${disp.pendingDivergencesCount})', style: const TextStyle(color: Colors.red)),
                  onPressed: () => _showDivergencesDrilldown(disp.pendingDivergences),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDispatchesDrilldown(List<DashboardDispatchRecord> dispatches) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalhamento de Saídas de Cestas (${dispatches.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: dispatches.isEmpty
                        ? const Center(child: Text('Nenhuma saída registrada no período.'))
                        : ListView.separated(
                            itemCount: dispatches.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final d = dispatches[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text('#${d.dispatchNumber}', style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
                                ),
                                title: Text(d.responsiblePersonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Data: ${AppFormatters.formatDateTime(d.dispatchDate)} | Cestas: ${d.totalBaskets} un.'),
                                trailing: Chip(
                                  label: Text(d.status, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: d.status == 'SETTLED' ? Colors.green.shade100 : Colors.blue.shade100,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUnremittedDrilldown(List<ResponsibleUnremittedItem> items) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repasses de Rota Pendentes (${items.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Nenhum valor retido por responsável no momento.'))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(Icons.account_balance_wallet, color: Colors.blue.shade800, size: 20),
                                ),
                                title: Text(
                                  '${item.responsiblePersonName} (Saída #${item.dispatchNumber})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.phone != null) Text('Tel: ${item.phone}'),
                                    Text('Data: ${AppFormatters.formatDateTime(item.dispatchDate)}'),
                                    Text(
                                      'Vendas Rota: ${AppFormatters.formatCurrency(item.cashSalesCents)} | Despesas: ${AppFormatters.formatCurrency(item.routeExpensesCents)} | Repassado: ${AppFormatters.formatCurrency(item.repaidCashCents)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(item.unremittedCashCents),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    Text(
                                      item.status,
                                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDivergencesDrilldown(List<PendingDivergenceItem> divergences) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Divergências Pendentes de Acerto de Rota',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: divergences.isEmpty
                        ? const Center(child: Text('Nenhuma divergência pendente.'))
                        : ListView.separated(
                            itemCount: divergences.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final div = divergences[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: const Icon(Icons.warning, color: Colors.red, size: 20),
                                ),
                                title: Text(
                                  'Saída #${div.dispatchNumber} - ${div.responsiblePersonName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Acerto em: ${AppFormatters.formatDateTime(div.settledAt)}'),
                                    Text(
                                      'Falta Cestas: ${div.basketDiscrepancyQty} un. | Falta Dinheiro: ${AppFormatters.formatCurrency(div.cashDiscrepancyCents)}',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                    if (div.notes != null && div.notes!.isNotEmpty)
                                      Text('Obs: ${div.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(div.status, style: const TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.red.shade50,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 4: INVENTORY
  // ==========================================
  Widget _buildInventorySection(ThemeData theme, DashboardInventorySummary inv) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  radius: 20,
                  child: Icon(Icons.inventory, color: Colors.orange.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionInventory,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.warning_amber, size: 18, color: Colors.red),
                  label: Text(
                    'Críticos (${inv.lowStockProductsCount})',
                    style: TextStyle(color: inv.lowStockProductsCount > 0 ? Colors.red : Colors.grey),
                  ),
                  onPressed: () => _showLowStockDrilldown(inv.lowStockItems),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produtos Cadastrados',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${inv.totalProductsCount} itens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showLowStockDrilldown(inv.lowStockItems),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inv.lowStockProductsCount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: inv.lowStockProductsCount > 0 ? Colors.red.shade300 : Colors.green.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.lowStockProductsCount > 0 ? l10n.dashboardLowStockAlert : l10n.dashboardStockNormal,
                            style: TextStyle(
                              fontSize: 12,
                              color: inv.lowStockProductsCount > 0 ? Colors.red.shade900 : Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inv.lowStockProductsCount} produto(s)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: inv.lowStockProductsCount > 0 ? Colors.red.shade900 : Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (inv.basketStock.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Saldo Disponível de Cestas Montadas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('Cesta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Loja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Trânsito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  ...inv.basketStock.map((b) {
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(b.name, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${b.stockStore}', style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${b.stockTransit}', style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${b.totalStock}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLowStockDrilldown(List<LowStockItem> items) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Produtos Abaixo do Estoque Mínimo (${items.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Todos os itens estão acima do estoque mínimo.'))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: const Icon(Icons.priority_high, color: Colors.red),
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('SKU: ${item.sku ?? '-'} | Un: ${item.baseUnit}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Atual: ${item.currentStock} / Mín: ${item.minStock}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Déficit: ${item.difference} ${item.baseUnit}',
                                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 5: FINANCIAL & TREASURY
  // ==========================================
  Widget _buildFinancialSection(ThemeData theme, DashboardFinancialSummary fin) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  radius: 20,
                  child: Icon(Icons.account_balance, color: Colors.teal.shade800, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionFinancial,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text('Caixa (${fin.cashRecords.length})'),
                  onPressed: () => _showCashDrilldown(fin.cashRecords),
                ),
              ],
            ),
            const Divider(height: 24),

            // Realized Cash & Treasury
            const Text(
              'Movimentações Efetivas e Saldo em Caixa (Realizado):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardEffectiveReceived,
                          style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(fin.effectiveReceivedCents),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardEffectivePaid,
                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(fin.effectivePaidCents),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade400, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardTreasuryBalance,
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(fin.currentTreasuryBalanceCents),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Open Receivables and Payables
            const Text(
              'Títulos em Aberto e Vencidos:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showReceivablesDrilldown(fin.receivablesRecords),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dashboardOpenReceivables, style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatCurrency(fin.receivablesOpenCents),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                          if (fin.receivablesOverdueCents > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Vencidos: ${AppFormatters.formatCurrency(fin.receivablesOverdueCents)}',
                              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showPayablesDrilldown(fin.payablesRecords),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dashboardOpenPayables, style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatCurrency(fin.payablesOpenCents),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                          ),
                          if (fin.payablesOverdueCents > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Vencidos: ${AppFormatters.formatCurrency(fin.payablesOverdueCents)}',
                              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cash Projection Card & Strict Distinction Warning
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.query_builder, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dashboardProjectedCash,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.dashboardProjectionNotice,
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Entradas Previstas: ${AppFormatters.formatCurrency(fin.projectedInflowCents)}', style: const TextStyle(fontSize: 12)),
                      Text('Saídas Previstas: ${AppFormatters.formatCurrency(fin.projectedOutflowCents)}', style: const TextStyle(fontSize: 12)),
                      Text(
                        'Saldo Projetado: ${AppFormatters.formatCurrency(fin.projectedTreasuryBalanceCents)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashDrilldown(List<DashboardCashRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lançamentos do Livro-Caixa (${records.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: records.isEmpty
                        ? const Center(child: Text('Nenhum lançamento no período.'))
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = records[i];
                              final isCredit = r.entryType == 'CREDIT';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCredit ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isCredit ? Colors.green.shade800 : Colors.red.shade800,
                                    size: 18,
                                  ),
                                ),
                                title: Text(r.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${r.category} | ${r.nature} | ${AppFormatters.formatDateTime(r.occurredAt)}'),
                                trailing: Text(
                                  '${isCredit ? "+" : "-"}${AppFormatters.formatCurrency(r.amountCents)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReceivablesDrilldown(List<DashboardReceivableRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contas a Receber em Aberto / Vencidas (${records.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: records.isEmpty
                        ? const Center(child: Text('Nenhum título a receber em aberto.'))
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = records[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: r.isOverdue ? Colors.red.shade100 : Colors.amber.shade100,
                                  child: Icon(
                                    r.isOverdue ? Icons.event_busy : Icons.event,
                                    color: r.isOverdue ? Colors.red.shade800 : Colors.amber.shade800,
                                    size: 18,
                                  ),
                                ),
                                title: Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Venda #${r.saleNumber} | Vencimento: ${AppFormatters.formatDate(r.dueDate)} ${r.isOverdue ? "(VENCIDO)" : ""}',
                                  style: TextStyle(color: r.isOverdue ? Colors.red : Colors.black54),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(r.balanceCents),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: r.isOverdue ? Colors.red.shade800 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Orig: ${AppFormatters.formatCurrency(r.originalAmountCents)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPayablesDrilldown(List<DashboardPayableRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contas a Pagar em Aberto / Vencidas (${records.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: records.isEmpty
                        ? const Center(child: Text('Nenhuma conta a pagar em aberto.'))
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = records[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.isOverdue ? Colors.red.shade100 : Colors.blueGrey.shade100,
                                  child: Icon(
                                    p.isOverdue ? Icons.warning : Icons.schedule,
                                    color: p.isOverdue ? Colors.red.shade800 : Colors.blueGrey.shade800,
                                    size: 18,
                                  ),
                                ),
                                title: Text(p.beneficiary, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '#${p.payableNumber} | Cat: ${p.category} | Venc: ${AppFormatters.formatDate(p.dueDate)} ${p.isOverdue ? "(VENCIDO)" : ""}',
                                  style: TextStyle(color: p.isOverdue ? Colors.red : Colors.black54),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(p.balanceCents),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: p.isOverdue ? Colors.red.shade800 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Orig: ${AppFormatters.formatCurrency(p.originalAmountCents)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
