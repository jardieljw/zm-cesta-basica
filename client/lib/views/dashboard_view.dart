import '../utils/adaptive_ui_color.dart';
import '../widgets/shared/responsive_filter_bar.dart';
import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class DashboardView extends StatefulWidget {
  final DashboardService? service;
  const DashboardView({super.key, this.service});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardService _dashboardService;

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
    _dashboardService = widget.service ?? DashboardService();
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
            tooltip: l10n.commonRefresh,
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
                  color: adaptiveUiSurface(context, Colors.red.shade50),
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
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.commonTryAgain),
                          onPressed: _loadDashboard,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_summary != null) ...[
                _buildFilterInfoBadge(theme, _summary!.filterInfo),
                const SizedBox(height: 16),
                _buildSalesSection(theme, _summary!.sales),
                const SizedBox(height: 16),
                _buildPurchasesSection(theme, _summary!.purchases),
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
            ResponsiveFilterBar(
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
                  Text(
                    context.l10n.dashboardSelectedDate(
                      AppFormatters.formatDate(_selectedDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(context.l10n.commonChange),
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
                  Text(
                    context.l10n.commonPeriodLabel(
                      AppFormatters.formatDate(_selectedRange.start),
                      AppFormatters.formatDate(_selectedRange.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(context.l10n.commonChange),
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
                      return DropdownMenuItem(
                        value: m,
                        child: Text(context.l10n.commonMonthNumber(m)),
                      );
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
                  Text(context.l10n.commonYearLabel),
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
        color: adaptiveUiSurface(context, Colors.blue.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: adaptiveUiSurface(context, Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: adaptiveUiText(context, Colors.blue.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Período em Exibição: ${info.label}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: adaptiveUiText(context, Colors.blue.shade900),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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
                  backgroundColor: adaptiveUiSurface(
                    context,
                    Colors.indigo.shade100,
                  ),
                  radius: 20,
                  child: Icon(
                    Icons.point_of_sale,
                    color: adaptiveUiText(context, Colors.indigo.shade800),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionSales,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text(
                    context.l10n.dashboardSalesCount(sales.sales.length),
                  ),
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
                        color: adaptiveUiSurface(
                          context,
                          Colors.indigo.shade50,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardSoldBaskets,
                            style: TextStyle(
                              fontSize: 12,
                              color: adaptiveUiText(
                                context,
                                Colors.indigo.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sales.soldCount} un.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: adaptiveUiText(
                                context,
                                Colors.indigo.shade900,
                              ),
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
                        color: adaptiveUiSurface(
                          context,
                          Colors.indigo.shade50,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardTotalSold,
                            style: TextStyle(
                              fontSize: 12,
                              color: adaptiveUiText(
                                context,
                                Colors.indigo.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatCurrency(sales.totalSoldCents),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: adaptiveUiText(
                                context,
                                Colors.indigo.shade900,
                              ),
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
              Text(
                'Vendas por Tipo de Cesta:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: sales.byBasketType.map((bt) {
                  return Chip(
                    backgroundColor: adaptiveUiSurface(
                      context,
                      Colors.indigo.shade50,
                    ),
                    label: Text(
                      '${bt.basketTypeName}: ${bt.count} un. (${AppFormatters.formatCurrency(bt.totalCents)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: adaptiveUiText(context, Colors.indigo.shade900),
                      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                        ? Center(child: Text(context.l10n.dashboardNoSales))
                        : ListView.separated(
                            itemCount: sales.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = sales[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: adaptiveUiSurface(
                                    context,
                                    Colors.indigo.shade100,
                                  ),
                                  child: Text(
                                    '#${s.saleNumber}',
                                    style: TextStyle(
                                      color: adaptiveUiText(
                                        context,
                                        Colors.indigo.shade900,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s.customerName ??
                                      context.l10n.saleCustomerAnonymous,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  context.l10n.companyPaymentDescription(
                                    _paymentLabel(s.paymentMode),
                                    AppFormatters.formatDateTime(
                                      s.saleDate.toLocal(),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(
                                        s.totalAmountCents,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      s.paymentStatus == 'PAID'
                                          ? context.l10n.companyPaidStatus
                                          : (s.paymentStatus == 'PARTIAL'
                                                ? context
                                                      .l10n
                                                      .companyPartialStatus
                                                : context
                                                      .l10n
                                                      .companyPendingStatus),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: s.paymentStatus == 'PAID'
                                            ? adaptiveUiText(
                                                context,
                                                Colors.green.shade700,
                                              )
                                            : adaptiveUiText(
                                                context,
                                                Colors.orange.shade800,
                                              ),
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
  // SECTION 4: INVENTORY
  // ==========================================
  Widget _buildPurchasesSection(
    ThemeData theme,
    DashboardPurchasesSummary purchases,
  ) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.companyPurchasesTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(l10n.companyPurchaseCount(purchases.purchaseCount)),
            const SizedBox(height: 6),
            Text(
              AppFormatters.formatCurrency(purchases.totalAmountCents),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(l10n.companyPurchasesExplanation),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(
    ThemeData theme,
    DashboardInventorySummary inv,
  ) {
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
                  backgroundColor: adaptiveUiSurface(
                    context,
                    Colors.orange.shade100,
                  ),
                  radius: 20,
                  child: Icon(
                    Icons.inventory,
                    color: adaptiveUiText(context, Colors.orange.shade800),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.dashboardSectionInventory,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: Colors.red,
                  ),
                  label: Text(
                    'Críticos (${inv.lowStockProductsCount})',
                    style: TextStyle(
                      color: inv.lowStockProductsCount > 0
                          ? Colors.red
                          : Colors.grey,
                    ),
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
                      color: adaptiveUiSurface(context, Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produtos Cadastrados',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${inv.totalProductsCount} itens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: adaptiveUiText(
                              context,
                              Colors.orange.shade900,
                            ),
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
                        color: inv.lowStockProductsCount > 0
                            ? adaptiveUiSurface(context, Colors.red.shade50)
                            : adaptiveUiSurface(context, Colors.green.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: inv.lowStockProductsCount > 0
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.lowStockProductsCount > 0
                                ? l10n.dashboardLowStockAlert
                                : l10n.dashboardStockNormal,
                            style: TextStyle(
                              fontSize: 12,
                              color: inv.lowStockProductsCount > 0
                                  ? adaptiveUiText(context, Colors.red.shade900)
                                  : adaptiveUiText(
                                      context,
                                      Colors.green.shade900,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inv.lowStockProductsCount} produto(s)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: inv.lowStockProductsCount > 0
                                  ? adaptiveUiText(context, Colors.red.shade900)
                                  : adaptiveUiText(
                                      context,
                                      Colors.green.shade900,
                                    ),
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
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: adaptiveUiSurface(context, Colors.grey.shade100),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.l10n.dashboardStockColBasket,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.l10n.companyStockAvailable,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...inv.basketStock.map((b) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            b.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${b.stockStore}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
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
                        ? Center(
                            child: Text(context.l10n.dashboardAllAboveMinStock),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: adaptiveUiSurface(
                                    context,
                                    Colors.red.shade100,
                                  ),
                                  child: const Icon(
                                    Icons.priority_high,
                                    color: Colors.red,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${context.l10n.dashboardItemSku(item.sku ?? "-")} | Un: ${item.baseUnit}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Atual: ${item.currentStock} / Mín: ${item.minStock}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Déficit: ${item.difference} ${item.baseUnit}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
  // SECTION 5: FINANCIAL & TREASURY
  // ==========================================
  Widget _financialTile(
    String title,
    int value,
    Color color, {
    VoidCallback? onTap,
    String? caption,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, color: color)),
            const SizedBox(height: 6),
            Text(
              AppFormatters.formatCurrency(value),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(caption, style: const TextStyle(fontSize: 12)),
            ],
            if (onTap != null) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.commonViewDetails,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _financialGrid(List<Widget> tiles) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 560
          ? 1
          : (constraints.maxWidth < 900 ? 2 : 3);
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles
            .map((tile) => SizedBox(width: width, child: tile))
            .toList(),
      );
    },
  );

  Widget _buildFinancialSection(
    ThemeData theme,
    DashboardFinancialSummary fin,
  ) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.companyFinanceTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.companyPaymentsScope),
            if (fin.treasuryBalanceCents != null || fin.accountsBalances.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Disponibilidade e Saldos (Caixa e Bancos)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: adaptiveUiSurface(context, Colors.teal.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Saldo Total Disponível',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          AppFormatters.formatCurrency(fin.treasuryBalanceCents ?? 0),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: (fin.treasuryBalanceCents ?? 0) >= 0 ? Colors.teal.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    if (fin.accountsBalances.isNotEmpty) ...[
                      const Divider(height: 18),
                      for (final acc in fin.accountsBalances) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    acc['account_type'] == 'CASH'
                                        ? Icons.point_of_sale_outlined
                                        : Icons.account_balance_outlined,
                                    size: 16,
                                    color: Colors.teal.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    acc['name'] as String? ?? 'Conta',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                AppFormatters.formatCurrency(
                                  (acc['current_balance_cents'] as num?)?.toInt() ?? 0,
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ((acc['current_balance_cents'] as num?) ?? 0) >= 0
                                      ? Colors.teal.shade900
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _financialGrid([
              _financialTile(
                l10n.companyReceived,
                fin.effectiveReceivedCents,
                Colors.green.shade800,
                onTap: () => _showPaymentRecords(fin.receivedRecords, true),
              ),
              _financialTile(
                l10n.companyPaid,
                fin.effectivePaidCents,
                Colors.red.shade800,
                onTap: () => _showPaymentRecords(fin.paidRecords, false),
              ),
              _financialTile(
                l10n.companyPaymentDifference,
                fin.paymentDifferenceCents,
                fin.paymentDifferenceCents >= 0
                    ? Colors.blue.shade800
                    : Colors.red.shade800,
                caption: l10n.companyDifferenceExplanation,
              ),
            ]),
            const Divider(height: 32),
            Text(l10n.companyResultTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.companyResultExplanation),
            const SizedBox(height: 14),
            if (fin.salesWithoutCostCount > 0) ...[
              Text(
                l10n.companyMissingCost(fin.salesWithoutCostCount),
                style: TextStyle(
                  color: adaptiveUiText(context, Colors.orange.shade900),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _financialGrid([
              _financialTile(
                l10n.companySalesRevenue,
                fin.salesRevenueCents,
                Colors.indigo.shade800,
              ),
              _financialTile(
                l10n.companySoldCost,
                fin.soldBasketsCostCents,
                Colors.blueGrey.shade800,
              ),
              _financialTile(
                l10n.companyGrossProfit,
                fin.grossProfitCents,
                Colors.indigo.shade800,
              ),
              _financialTile(
                l10n.companyOperatingExpenses,
                fin.operatingExpensesPaidCents,
                Colors.red.shade800,
              ),
              _financialTile(
                l10n.companyOperatingResult,
                fin.operatingResultCents,
                fin.operatingResultCents >= 0
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              l10n.companyStockPaid(
                AppFormatters.formatCurrency(fin.stockPurchasesPaidCents),
              ),
            ),
            Text(
              l10n.companyWithdrawalsPaid(
                AppFormatters.formatCurrency(fin.personalWithdrawalsPaidCents),
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.companyCostExplanation, style: theme.textTheme.bodySmall),
            const Divider(height: 32),
            Text(l10n.companyPendingTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.companyPendingScope),
            const SizedBox(height: 14),
            _financialGrid([
              _financialTile(
                l10n.companyPendingReceivable,
                fin.receivablesOpenCents,
                Colors.orange.shade900,
                onTap: () => _showReceivablesDrilldown(fin.receivablesRecords),
                caption: l10n.companyOverdueAmount(
                  AppFormatters.formatCurrency(fin.receivablesOverdueCents),
                ),
              ),
              _financialTile(
                l10n.companyPendingPayable,
                fin.payablesOpenCents,
                Colors.red.shade800,
                onTap: () => _showPayablesDrilldown(fin.payablesRecords),
                caption: l10n.companyOverdueAmount(
                  AppFormatters.formatCurrency(fin.payablesOverdueCents),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _financialGrid([
              _financialTile(
                l10n.companyReceivableDueInPeriod,
                fin.receivablesDueInPeriodCents,
                Colors.orange.shade900,
              ),
              _financialTile(
                l10n.companyPayableDueInPeriod,
                fin.payablesDueInPeriodCents,
                Colors.red.shade800,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) {
    final l10n = context.l10n;
    switch (method) {
      case 'CREDIT_TERM':
        return l10n.salePaymentModeCredit;
      case 'CASH':
      case 'CASH_IMMEDIATE':
      case 'DINHEIRO':
        return l10n.payablePaymentMethodCash;
      case 'PIX':
        return l10n.payablePaymentMethodPix;
      case 'CARD':
      case 'CARTAO_CREDITO':
        return l10n.payablePaymentMethodCard;
      case 'TRANSFER':
      case 'TRANSFERENCIA':
      case 'BANK_TRANSFER':
        return l10n.payablePaymentMethodTransfer;
      case 'CHECK':
      case 'CHEQUE':
        return l10n.payablePaymentMethodCheck;
      case 'BOLETO':
        return l10n.payablePaymentMethodBoleto;
      default:
        return l10n.payablePaymentMethodOther;
    }
  }


  void _showPaymentRecords(List<BusinessPaymentRecord> records, bool received) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        received
                            ? l10n.companyReceivedDetails
                            : l10n.companyPaidDetails,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: records.isEmpty
                      ? Center(child: Text(l10n.companyNoPayments))
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = records[i];
                            final color = r.isReversal
                                ? Colors.orange.shade800
                                : (received
                                      ? Colors.green.shade800
                                      : Colors.red.shade800);
                            return ListTile(
                              leading: Icon(
                                r.isReversal
                                    ? Icons.undo
                                    : (received
                                          ? Icons.task_alt
                                          : Icons.receipt_long),
                                color: color,
                              ),
                              title: Text(r.description),
                              subtitle: Text(
                                l10n.companyPaymentDescription(
                                  _paymentLabel(r.paymentMethod),
                                  AppFormatters.formatDateTime(
                                    r.occurredAt.toLocal(),
                                  ),
                                ),
                              ),
                              trailing: Text(
                                AppFormatters.formatCurrency(r.amountCents),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _showReceivablesDrilldown(List<DashboardReceivableRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                        ? Center(
                            child: Text(
                              context.l10n.dashboardNoOpenReceivables,
                            ),
                          )
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = records[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: r.isOverdue
                                      ? adaptiveUiSurface(
                                          context,
                                          Colors.red.shade100,
                                        )
                                      : adaptiveUiSurface(
                                          context,
                                          Colors.amber.shade100,
                                        ),
                                  child: Icon(
                                    r.isOverdue
                                        ? Icons.event_busy
                                        : Icons.event,
                                    color: r.isOverdue
                                        ? adaptiveUiText(
                                            context,
                                            Colors.red.shade800,
                                          )
                                        : adaptiveUiText(
                                            context,
                                            Colors.amber.shade800,
                                          ),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  r.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Venda #${r.saleNumber} | Vencimento: ${AppFormatters.formatDate(r.dueDate.toLocal())} ${r.isOverdue ? "(VENCIDO)" : ""}',
                                  style: TextStyle(
                                    color: r.isOverdue
                                        ? Colors.red
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(
                                        r.balanceCents,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: r.isOverdue
                                            ? adaptiveUiText(
                                                context,
                                                Colors.red.shade800,
                                              )
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Orig: ${AppFormatters.formatCurrency(r.originalAmountCents)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
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

  void _showPayablesDrilldown(List<DashboardPayableRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                        ? Center(
                            child: Text(context.l10n.dashboardNoOpenPayables),
                          )
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = records[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.isOverdue
                                      ? adaptiveUiSurface(
                                          context,
                                          Colors.red.shade100,
                                        )
                                      : adaptiveUiSurface(
                                          context,
                                          Colors.blueGrey.shade100,
                                        ),
                                  child: Icon(
                                    p.isOverdue
                                        ? Icons.warning
                                        : Icons.schedule,
                                    color: p.isOverdue
                                        ? adaptiveUiText(
                                            context,
                                            Colors.red.shade800,
                                          )
                                        : adaptiveUiText(
                                            context,
                                            Colors.blueGrey.shade800,
                                          ),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  p.beneficiary,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '#${p.payableNumber} | Cat: ${p.category} | Venc: ${AppFormatters.formatDate(p.dueDate.toLocal())} ${p.isOverdue ? "(VENCIDO)" : ""}',
                                  style: TextStyle(
                                    color: p.isOverdue
                                        ? Colors.red
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(
                                        p.balanceCents,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: p.isOverdue
                                            ? adaptiveUiText(
                                                context,
                                                Colors.red.shade800,
                                              )
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Orig: ${AppFormatters.formatCurrency(p.originalAmountCents)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
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
}
