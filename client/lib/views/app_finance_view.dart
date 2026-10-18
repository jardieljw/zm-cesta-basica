import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../services/app_overview_controller.dart';
import '../utils/formatters.dart';
import '../utils/app_date_labels.dart';
import '../utils/api_error_mapper.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_period_selector.dart';
import '../widgets/shared/approved_icon.dart';
import 'financial_imports_view.dart';
import 'financial_sources_view.dart';

class AppFinanceView extends StatefulWidget {
  final AppOverviewController controller;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<OverviewAccount> onAccount;
  final void Function(bool, String) onPending;
  final VoidCallback onPayableTools, onReceivableTools;
  const AppFinanceView({
    super.key,
    required this.controller,
    required this.tab,
    required this.onTab,
    required this.onAccount,
    required this.onPending,
    required this.onPayableTools,
    required this.onReceivableTools,
  });
  @override
  State<AppFinanceView> createState() => _AppFinanceViewState();
}

class _AppFinanceViewState extends State<AppFinanceView> {
  bool _expanded = false;
  AppOverviewController get c => widget.controller;
  String _scope(DueScope scope) {
    final l = context.l10n;
    return switch (scope) {
      DueScope.week => l.appThisWeek,
      DueScope.today => l.appDueToday,
      DueScope.month => l.appThisMonth,
      DueScope.overdue => l.appOverdue,
      DueScope.next => l.appNextThree,
      DueScope.open => l.appAllOpen,
    };
  }

  String _range(DueScope scope) {
    final range = switch (scope) {
      DueScope.week => c.bounds(OverviewPeriod.week),
      DueScope.month => c.bounds(OverviewPeriod.month),
      DueScope.next => (
        c.businessDay.add(const Duration(days: 1)),
        c.businessDay.add(const Duration(days: 3)),
      ),
      _ => (c.businessDay, c.businessDay),
    };
    return scope == DueScope.open
        ? context.l10n.appCurrentPosition
        : scope == DueScope.overdue
        ? context.l10n.appBeforeDate(AppFormatters.formatDate(c.businessDay))
        : '${_scope(scope)} · ${appDateRange(context, range.$1, range.$2)}';
  }

  int _total(List<OverviewAccount> items) =>
      items.fold(0, (n, a) => n + a.balance);
  Widget _tabs() {
    final l = context.l10n, p = AppPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Semantics(
                  selected: widget.tab == i,
                  child: TextButton(
                    key: ValueKey('finance-tab-$i'),
                    onPressed: () {
                      setState(() => _expanded = false);
                      widget.onTab(i);
                    },
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      foregroundColor: widget.tab == i ? p.accentInk : p.ink,
                      backgroundColor: widget.tab == i
                          ? p.accent
                          : Colors.transparent,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      [l.appSummary, l.appPayTab, l.appReceiveTab][i],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filter(bool payable) {
    final l = context.l10n,
        p = AppPalette.of(context),
        scope = payable ? c.payScope : c.receiveScope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _expanded ? p.accent : p.line),
          ),
          child: InkWell(
            key: const ValueKey('approved-finance-filter'),
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ApprovedIcon('sliders-horizontal', size: 18, color: p.sub),
                    const SizedBox(width: 8),
                    Text(l.appFilter),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scope(scope),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 13, color: p.sub),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotatedBox(
                      quarterTurns: _expanded ? 2 : 0,
                      child: ApprovedIcon(
                        'chevron-down',
                        size: 18,
                        color: p.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appDueScope,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in DueScope.values)
                      ChoiceChip(
                        label: Text(_scope(option)),
                        selected: option == scope,
                        onSelected: (_) {
                          c.selectScope(payable, option);
                          setState(() => _expanded = false);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _balance(bool payable, List<OverviewAccount> items) {
    final l = context.l10n;
    final supportStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 13);
    final partial = items.where((a) => a.paid > 0).length;
    return ApprovedSurface(
      key: const ValueKey('finance-balance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            payable ? l.appBalancePay : l.appBalanceReceive,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            AppFormatters.formatCurrency(_total(items)),
            style: Theme.of(context).textTheme.headlineMedium,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _range(payable ? c.payScope : c.receiveScope),
            style: supportStyle,
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(l.appOpenCount(items.length), style: supportStyle),
              if (partial > 0)
                Text(l.appPartialCount(partial), style: supportStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _account(OverviewAccount a) {
    final l = context.l10n, p = AppPalette.of(context);
    final due = a.due == c.businessDay, late = a.due.isBefore(c.businessDay);
    final origin = a.payable ? l.appPurchaseOrigin : l.appSaleOrigin;
    final status = a.paid > 0 ? l.appPartial : l.appOpen;
    return InkWell(
      onTap: () => widget.onAccount(a),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  l.appOriginDue(
                    origin,
                    AppFormatters.formatDate(a.due, pattern: "dd 'de' MMM"),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l.appOriginalPaid(
                    AppFormatters.formatCurrency(a.original),
                    a.payable ? l.appPaid : l.appReceived,
                    AppFormatters.formatCurrency(a.paid),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
            final amount = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatCurrency(a.balance),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: late || due ? p.warnFill : p.soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$status${late
                        ? ' · ${l.appOverdue}'
                        : due
                        ? ' · ${l.appDueTodayShort}'
                        : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: late || due ? p.warn : p.sub,
                    ),
                  ),
                ),
              ],
            );
            final adapted =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(15) > 21;
            return adapted
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: amount,
                            ),
                          ),
                          ApprovedIcon('chevron-right', size: 16, color: p.sub),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 14),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * .52,
                        ),
                        child: amount,
                      ),
                      const SizedBox(width: 14),
                      ApprovedIcon('chevron-right', size: 16, color: p.sub),
                    ],
                  );
          },
        ),
      ),
    );
  }

  List<Widget> _pending(bool payable) {
    final l = context.l10n;
    final attempts = payable
        ? c.payPending.map(
            (a) => (a.payableId, a.beneficiary, a.confirmation != null),
          )
        : c.receivePending.map(
            (a) => (a.receivableId, a.customerName, a.confirmation != null),
          );
    if (attempts.isEmpty && !c.pendingUnavailable) return [];
    return [
      ApprovedSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.paymentFlowPendingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (c.pendingUnavailable) Text(l.paymentFlowPendingReadError),
            for (final a in attempts)
              TextButton(
                onPressed: () => widget.onPending(payable, a.$1),
                child: Text(
                  '${a.$2} · ${a.$3 ? (payable ? l.paymentFlowConfirmed : l.receiptFlowConfirmed) : l.paymentFlowUncertain}',
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _deadlines(bool payable) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          payable ? l.appPay : l.appReceive,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final scope in [
          DueScope.today,
          DueScope.overdue,
          DueScope.next,
        ]) ...[
          ApprovedRow(
            title: _scope(scope),
            subtitle: l.appAccountAmount(
              c.accounts(payable, scope).length,
              AppFormatters.formatCurrency(_total(c.accounts(payable, scope))),
            ),
            onTap: () {
              c.selectScope(payable, scope);
              widget.onTab(payable ? 1 : 2);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, summary = c.summary, p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            l.appFinanceContext,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 20),
        _tabs(),
        const SizedBox(height: 20),
        if (widget.tab != 0) ..._pending(widget.tab == 1),
        if (c.loading)
          const Center(child: CircularProgressIndicator())
        else if (c.error != null)
          ApprovedSurface(
            child: Column(
              children: [
                Text(ApiErrorMapper.toLocalizedMessage(c.error, l)),
                TextButton(onPressed: c.refresh, child: Text(l.commonRefresh)),
              ],
            ),
          )
        else if (summary != null && widget.tab == 0) ...[
          ApprovedSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.appOpenInPeriod,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                AppTwoColumns(
                  children: [
                    _summaryMetric(
                      l.appPay,
                      summary.financial.payablesDueInPeriodCents,
                      1,
                    ),
                    _summaryMetric(
                      l.appReceive,
                      summary.financial.receivablesDueInPeriodCents,
                      2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ApprovedSectionHeader(l.appCurrentDeadlines),
          _deadlines(true),
          const SizedBox(height: 20),
          _deadlines(false),
          Text(
            l.appPendingNotBank,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const ApprovedSectionHeader('Tesouraria e Disponibilidade'),
          ApprovedSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Saldo Total Disponível',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      AppFormatters.formatCurrency(summary.financial.treasuryBalanceCents ?? 0),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: (summary.financial.treasuryBalanceCents ?? 0) >= 0
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                    ),
                  ],
                ),
                if (summary.financial.accountsBalances.isNotEmpty) ...[
                  const Divider(height: 24),
                  for (final acc in summary.financial.accountsBalances) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                                size: 18,
                                color: p.sub,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                acc['name'] as String? ?? 'Conta',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Text(
                            AppFormatters.formatCurrency(
                              (acc['current_balance_cents'] as num?)?.toInt() ?? 0,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ((acc['current_balance_cents'] as num?) ?? 0) >= 0
                                  ? null
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
          const SizedBox(height: 20),
          ApprovedSectionHeader(l.appOrganizeFinance),
          ApprovedRow(
            title: l.appAccountsCards,
            subtitle: 'Contas bancárias e cartões cadastrados',
            icon: Icons.account_balance_outlined,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FinancialSourcesView(apiClient: c.api),
                ),
              );
              if (mounted) c.refresh();
            },
          ),
          const SizedBox(height: 8),
          ApprovedRow(
            title: l.appStatements,
            subtitle: l.pdfImportEntry,
            icon: Icons.folder_copy_outlined,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FinancialImportsView(apiClient: c.api),
                ),
              );
              if (mounted) c.refresh();
            },
          ),
        ] else if (summary != null) ...[
          _filter(widget.tab == 1),
          const SizedBox(height: 20),
          _balance(widget.tab == 1, c.accounts(widget.tab == 1)),
          const SizedBox(height: 20),
          if (c.accounts(widget.tab == 1).isEmpty)
            ApprovedSurface(child: Text(l.appNoOpenAccounts))
          else ...[
            ApprovedSectionHeader(
              l.appAccounts,
              trailing: l.appResults(c.accounts(widget.tab == 1).length),
            ),
            ApprovedSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (
                    var i = 0;
                    i < c.accounts(widget.tab == 1).length;
                    i++
                  ) ...[
                    if (i > 0) const Divider(),
                    _account(c.accounts(widget.tab == 1)[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
        if (widget.tab != 0 && c.error != null) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.tab == 1
                ? widget.onPayableTools
                : widget.onReceivableTools,
            child: Text(l.appHistoryAndRecords),
          ),
        ],
      ],
    );
  }

  Widget _summaryMetric(String label, int cents, int tab) => InkWell(
    onTap: () {
      c.selectScope(tab == 1, switch (c.period) {
        OverviewPeriod.day => DueScope.today,
        OverviewPeriod.week => DueScope.week,
        OverviewPeriod.month => DueScope.month,
      });
      widget.onTab(tab);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(cents),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
  );
}
