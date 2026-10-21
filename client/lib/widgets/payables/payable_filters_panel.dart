import 'package:flutter/material.dart';
import '../../l10n/l10n_extension.dart';
import '../../utils/formatters.dart';

/// Presentation-only filter draft. Nothing is queried until Apply is selected.
class PayableFilters {
  final String? status, category, nature, bankCard, merchant;
  final int? month, year;
  final DateTime? from, to;
  final bool overdue;
  const PayableFilters({
    this.status,
    this.category,
    this.nature,
    this.bankCard,
    this.merchant,
    this.month,
    this.year,
    this.from,
    this.to,
    this.overdue = false,
  });
}

class PayableFiltersPanel extends StatefulWidget {
  final PayableFilters initial;
  final DateTime? businessToday;
  const PayableFiltersPanel({
    super.key,
    required this.initial,
    this.businessToday,
  });
  @override
  State<PayableFiltersPanel> createState() => _PayableFiltersPanelState();
}

class _PayableFiltersPanelState extends State<PayableFiltersPanel> {
  String? _statusFilter, _categoryFilter, _natureFilter;
  int? _monthFilter, _yearFilter;
  DateTime? _dueDateFrom, _dueDateTo;
  bool _overdueOnly = false;
  late final TextEditingController _bankCard, _merchant;
  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _statusFilter = f.status;
    _categoryFilter = f.category;
    _natureFilter = f.nature;
    _monthFilter = f.month;
    _yearFilter = f.year;
    _dueDateFrom = f.from;
    _dueDateTo = f.to;
    _overdueOnly = f.overdue;
    _bankCard = TextEditingController(text: f.bankCard);
    _merchant = TextEditingController(text: f.merchant);
  }

  @override
  void dispose() {
    _bankCard.dispose();
    _merchant.dispose();
    super.dispose();
  }

  void _period(int index) => setState(() {
    final day =
        widget.businessToday ??
        DateTime.now().toUtc().subtract(const Duration(hours: 3));
    final today = DateTime(day.year, day.month, day.day);
    _monthFilter = null;
    _yearFilter = null;
    _dueDateFrom = switch (index) {
      0 => today,
      1 => today.subtract(Duration(days: today.weekday - 1)),
      2 => DateTime(today.year, today.month),
      _ => DateTime(today.year, today.month + 1),
    };
    _dueDateTo = switch (index) {
      0 => today,
      1 => _dueDateFrom!.add(const Duration(days: 6)),
      2 => DateTime(today.year, today.month + 1, 0),
      _ => DateTime(today.year, today.month + 2, 0),
    };
  });

  void _clear() => setState(() {
    _statusFilter = null;
    _categoryFilter = null;
    _natureFilter = null;
    _monthFilter = null;
    _yearFilter = null;
    _dueDateFrom = null;
    _dueDateTo = null;
    _overdueOnly = false;
    _bankCard.clear();
    _merchant.clear();
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.payableFiltersTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l.commonCancel,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(child: SingleChildScrollView(child: _buildFilterBar())),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _clear,
                    child: Text(l.receivableFilterClear),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      PayableFilters(
                        status: _statusFilter,
                        category: _categoryFilter,
                        nature: _natureFilter,
                        bankCard: _bankCard.text.trim().isEmpty
                            ? null
                            : _bankCard.text.trim(),
                        merchant: _merchant.text.trim().isEmpty
                            ? null
                            : _merchant.text.trim(),
                        month: _monthFilter,
                        year: _yearFilter,
                        from: _dueDateFrom,
                        to: _dueDateTo,
                        overdue: _overdueOnly,
                      ),
                    ),
                    child: Text(l.receivableFilterApply),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth >= 520
            ? (constraints.maxWidth - 44) / 2
            : constraints.maxWidth - 32;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextField(
                  key: const ValueKey('payable-bank-card-filter'),
                  controller: _bankCard,
                  decoration: InputDecoration(
                    labelText: l10n.payableBankCardFilter,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextField(
                  key: const ValueKey('payable-merchant-filter'),
                  controller: _merchant,
                  decoration: InputDecoration(
                    labelText: l10n.payableMerchantFilter,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const ValueKey('payable-period-all'),
                      label: Text(l10n.payableFilterPeriodAll),
                      onPressed: () => setState(() {
                        _monthFilter = null;
                        _yearFilter = null;
                        _dueDateFrom = null;
                        _dueDateTo = null;
                      }),
                    ),
                    for (final (index, label) in [
                      l10n.payableToday,
                      l10n.payableThisWeek,
                      l10n.payableThisMonth,
                      l10n.payableNextMonth,
                    ].indexed)
                      ActionChip(
                        key: ValueKey('payable-period-$index'),
                        label: Text(label),
                        onPressed: () => _period(index),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  key: ValueKey(_statusFilter),
                  initialValue: _statusFilter,
                  decoration: InputDecoration(
                    labelText: l10n.payableStatus,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.categoryAll),
                    ),
                    DropdownMenuItem(
                      value: 'OPEN',
                      child: Text(l10n.payableStatusOpen),
                    ),
                    DropdownMenuItem(
                      value: 'PARTIAL',
                      child: Text(l10n.payableStatusPartial),
                    ),
                    DropdownMenuItem(
                      value: 'PAID',
                      child: Text(l10n.payableStatusPaid),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELED',
                      child: Text(l10n.payableStatusCanceled),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _statusFilter = val);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  key: ValueKey(_categoryFilter),
                  initialValue: _categoryFilter,
                  decoration: InputDecoration(
                    labelText: l10n.payableCategory,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.categoryAll),
                    ),
                    DropdownMenuItem(
                      value: 'FORNECEDOR',
                      child: Text(l10n.payableCategorySupplier),
                    ),
                    DropdownMenuItem(
                      value: 'ENERGIA',
                      child: Text(l10n.payableCategoryElectricity),
                    ),
                    DropdownMenuItem(
                      value: 'ALUGUEL',
                      child: Text(l10n.payableCategoryRent),
                    ),
                    DropdownMenuItem(
                      value: 'FRETE',
                      child: Text(l10n.payableCategoryFreightShort),
                    ),
                    DropdownMenuItem(
                      value: 'MANUTENCAO',
                      child: Text(l10n.payableCategoryMaintenance),
                    ),
                    DropdownMenuItem(
                      value: 'EMPRESTIMO',
                      child: Text(l10n.payableCategoryLoan),
                    ),
                    DropdownMenuItem(
                      value: 'CARTAO_CREDITO',
                      child: Text(l10n.payableCategoryCreditCard),
                    ),
                    DropdownMenuItem(
                      value: 'RETIRADA_SOCIO',
                      child: Text(l10n.payableCategoryPartnerWithdrawal),
                    ),
                    DropdownMenuItem(
                      value: 'IMPOSTO',
                      child: Text(l10n.payableCategoryTaxesShort),
                    ),
                    DropdownMenuItem(
                      value: 'OUTROS',
                      child: Text(l10n.payableCategoryOthers),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _categoryFilter = val);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  key: ValueKey(_natureFilter),
                  initialValue: _natureFilter,
                  decoration: InputDecoration(
                    labelText: l10n.payableNature,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.categoryAll),
                    ),
                    DropdownMenuItem(
                      value: 'BUSINESS',
                      child: Text(l10n.payableNatureBusiness),
                    ),
                    DropdownMenuItem(
                      value: 'PERSONAL_WITHDRAWAL',
                      child: Text(l10n.payableNaturePersonal),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _natureFilter = val);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  key: ValueKey(_monthFilter),
                  initialValue: _monthFilter,
                  decoration: InputDecoration(
                    labelText: l10n.payableFilterMonth,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.filterAllOption),
                    ),
                    DropdownMenuItem(value: 1, child: Text(l10n.monthJan)),
                    DropdownMenuItem(value: 2, child: Text(l10n.monthFeb)),
                    DropdownMenuItem(value: 3, child: Text(l10n.monthMar)),
                    DropdownMenuItem(value: 4, child: Text(l10n.monthApr)),
                    DropdownMenuItem(value: 5, child: Text(l10n.monthMay)),
                    DropdownMenuItem(value: 6, child: Text(l10n.monthJun)),
                    DropdownMenuItem(value: 7, child: Text(l10n.monthJul)),
                    DropdownMenuItem(value: 8, child: Text(l10n.monthAug)),
                    DropdownMenuItem(value: 9, child: Text(l10n.monthSep)),
                    DropdownMenuItem(value: 10, child: Text(l10n.monthOct)),
                    DropdownMenuItem(value: 11, child: Text(l10n.monthNov)),
                    DropdownMenuItem(value: 12, child: Text(l10n.monthDec)),
                  ],
                  onChanged: (val) {
                    setState(() => _monthFilter = val);
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  key: ValueKey(_yearFilter),
                  initialValue: _yearFilter,
                  decoration: InputDecoration(
                    labelText: l10n.payableFilterYear,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.filterAllOption),
                    ),
                    const DropdownMenuItem(value: 2024, child: Text('2024')),
                    const DropdownMenuItem(value: 2025, child: Text('2025')),
                    const DropdownMenuItem(value: 2026, child: Text('2026')),
                    const DropdownMenuItem(value: 2027, child: Text('2027')),
                    const DropdownMenuItem(value: 2028, child: Text('2028')),
                    const DropdownMenuItem(value: 2029, child: Text('2029')),
                    const DropdownMenuItem(value: 2030, child: Text('2030')),
                  ],
                  onChanged: (val) {
                    setState(() => _yearFilter = val);
                  },
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  _dueDateFrom != null && _dueDateTo != null
                      ? '${AppFormatters.formatDate(_dueDateFrom!)} - ${AppFormatters.formatDate(_dueDateTo!)}'
                      : l10n.payableFilterPeriod,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDateRange: _dueDateFrom != null && _dueDateTo != null
                        ? DateTimeRange(start: _dueDateFrom!, end: _dueDateTo!)
                        : null,
                  );
                  if (range != null && mounted) {
                    setState(() {
                      _dueDateFrom = range.start;
                      _dueDateTo = range.end;
                    });
                  }
                },
              ),
              FilterChip(
                label: Text(l10n.payableOverdue),
                selected: _overdueOnly,
                onSelected: (val) {
                  setState(() => _overdueOnly = val);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
