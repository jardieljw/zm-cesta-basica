import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/dashboard_service.dart';
import '../services/app_overview_controller.dart';
import '../services/sale_service.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/app_date_labels.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_period_selector.dart';
import '../widgets/shared/app_operation_scope.dart';
import '../widgets/shared/approved_icon.dart';
import 'app_finance_view.dart';
import 'app_settings_menu_view.dart';
import 'payable_payment_view.dart';
import 'receivable_payment_view.dart';
import 'settings_view.dart';
import 'products_view.dart';
import 'basket_types_view.dart';
import 'purchases_view.dart';
import 'inventory_movements_view.dart';
import 'customers_view.dart';
import 'sales_view.dart';
import 'sale_origin_view.dart';
import 'receivables_view.dart';
import 'payables_view.dart';
import 'reports_view.dart';
import 'blank_forms_view.dart';

/// FE-052 composition with live services. Each area preserves its own routes.
class HomeView extends StatefulWidget {
  final ConnectivityService? connectivity;
  final DashboardService? dashboard;
  final ApiClient? apiClient;
  final AppOverviewController? controller;
  const HomeView({
    super.key,
    this.connectivity,
    this.dashboard,
    this.apiClient,
    this.controller,
  });
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final AppOverviewController c;
  final _operationLock = AppOperationLock();
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _scroll = List.generate(5, (_) => ScrollController());
  int _area = 0, _financeTab = 0;
  @override
  void initState() {
    super.initState();
    c =
        widget.controller ??
        AppOverviewController(
          client: widget.apiClient,
          service: widget.dashboard,
        );
    c.addListener(_changed);
    _operationLock.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.refresh();
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _operationLock.removeListener(_changed);
    _operationLock.dispose();
    if (widget.controller == null) c.dispose();
    for (final s in _scroll) {
      s.dispose();
    }
    super.dispose();
  }

  void _selectArea(int area) {
    if (_operationLock.locked) return;
    setState(() => _area = area);
  }

  void _finance(int tab, {DueScope? scope}) {
    if (scope != null) c.selectScope(tab == 1, scope);
    _navigators[1].currentState?.popUntil((r) => r.isFirst);
    setState(() {
      _area = 1;
      _financeTab = tab;
    });
  }

  Future<void> _open(Widget page, {int? area}) async {
    await _navigators[area ?? _area].currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) await c.refresh();
  }

  void _payment(bool payable, String id) => _open(
    payable
        ? PayablePaymentView(payableId: id, coordinator: c.payCoordinator)
        : ReceivablePaymentView(
            receivableId: id,
            coordinator: c.receiveCoordinator,
          ),
    area: 1,
  );
  String _when() {
    final l = context.l10n;
    return switch (c.period) {
      OverviewPeriod.day => l.appTodayWhen,
      OverviewPeriod.week => l.appWeekWhen,
      OverviewPeriod.month => l.appMonthWhen,
    };
  }

  String _range() {
    final r = c.bounds(c.period);
    return appDateRange(context, r.$1, r.$2);
  }

  DueScope get _periodScope => switch (c.period) {
    OverviewPeriod.day => DueScope.today,
    OverviewPeriod.week => DueScope.week,
    OverviewPeriod.month => DueScope.month,
  };
  Widget _label(String value) =>
      Text(value, style: Theme.of(context).textTheme.bodySmall);
  Widget _gap([double height = 20]) => SizedBox(height: height);
  Widget _metric(
    String label,
    String amount,
    VoidCallback action, {
    bool tile = false,
    bool number = false,
  }) {
    final baseStyle = Theme.of(context).textTheme.titleLarge;
    final amountStyle = number
        ? baseStyle?.copyWith(fontSize: 26, letterSpacing: 0)
        : baseStyle?.copyWith(letterSpacing: -.5);
    final child = Column(
      crossAxisAlignment:
          tile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: tile ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        _gap(4),
        Text(
          amount,
          textAlign: tile ? TextAlign.center : TextAlign.start,
          style: amountStyle,
        ),
      ],
    );
    return tile
        ? ApprovedSurface(
            padding: const EdgeInsets.all(12),
            child: InkWell(onTap: action, child: child),
          )
        : InkWell(onTap: action, child: child);
  }

  Widget _periods() =>
      AppPeriodSelector(value: c.period, onChanged: c.selectPeriod);
  Widget _failure() => ApprovedSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ApiErrorMapper.toLocalizedMessage(c.error, context.l10n)),
        _gap(12),
        TextButton(
          onPressed: c.refresh,
          child: Text(context.l10n.commonRefresh),
        ),
        TextButton(
          onPressed: () => _open(const SettingsView()),
          child: Text(context.l10n.appSettingsConnection),
        ),
      ],
    ),
  );
  Widget _home() {
    final l = context.l10n, d = c.summary, p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _periods(),
        _gap(12),
        _label(_range()),
        _gap(12),
        if (c.loading)
          const Center(child: CircularProgressIndicator())
        else if (c.error != null)
          _failure()
        else if (d != null) ...[
          ApprovedSurface(
            padding: const EdgeInsets.all(16),
            gradient: LinearGradient(
              begin: const Alignment(-0.82, -0.57),
              end: const Alignment(0.82, 0.57),
              colors: [
                p.panel,
                Color.lerp(p.surface, p.soft, 0.14)!,
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.appYourFinance(_when()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _gap(10),
                AppTwoColumns(
                  children: [
                    _metric(
                      l.appPay,
                      AppFormatters.formatCurrency(
                        d.financial.payablesDueInPeriodCents,
                      ),
                      () => _finance(1, scope: _periodScope),
                    ),
                    _metric(
                      l.appReceive,
                      AppFormatters.formatCurrency(
                        d.financial.receivablesDueInPeriodCents,
                      ),
                      () => _finance(2, scope: _periodScope),
                    ),
                  ],
                ),
                _gap(6),
                _label(l.appOpenDueInPeriod),
                _gap(12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => _finance(0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(l.appOpenFinance)),
                      const SizedBox(width: 10),
                      const ApprovedIcon('arrow-right', size: 17),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _gap(12),
          ApprovedSectionHeader(l.appYourBusiness(_when())),
          AppTwoColumns(
            children: [
              _metric(
                l.appBasketsSold,
                AppFormatters.formatNumber(d.sales.soldCount),
                () => _selectArea(2),
                tile: true,
                number: true,
              ),
              _metric(
                l.appSalesValue,
                AppFormatters.formatCurrency(d.sales.totalSoldCents),
                () => _selectArea(2),
                tile: true,
              ),
            ],
          ),
          _gap(12),
          ApprovedSectionHeader(l.appAttention, trailing: l.appNow),
          _financialAttention(),
          _gap(8),
          _stockAttention(),
        ],
      ],
    );
  }

  Widget _financialAttention() {
    final l = context.l10n,
        late =
            c.accounts(true, DueScope.overdue).length +
            c.accounts(false, DueScope.overdue).length;
    final pay = c
            .accounts(true, DueScope.today)
            .fold(0, (n, a) => n + a.balance),
        receive = c
            .accounts(false, DueScope.today)
            .fold(0, (n, a) => n + a.balance);
    return ApprovedRow(
      compact: true,
      title: late > 0
          ? l.appLateAccounts(late)
          : l.appTodayPay(AppFormatters.formatCurrency(pay)),
      subtitle: late > 0
          ? l.appTodayAmounts(
              AppFormatters.formatCurrency(pay),
              AppFormatters.formatCurrency(receive),
            )
          : 'A receber hoje: ${AppFormatters.formatCurrency(receive)} · Sem atrasadas',
      icon: Icons.event_outlined,
      onTap: () => _finance(1, scope: late > 0 ? DueScope.overdue : DueScope.today),
    );
  }

  Widget _stockAttention() {
    final l = context.l10n,
        items = c.today!.inventory.lowStockItems,
        item = items.isEmpty ? null : items.first;
    return ApprovedRow(
      compact: true,
      title: item == null ? l.appNoLowStock : l.appLowStockProduct(item.name),
      subtitle: item == null
          ? l.appCheckInventory
          : l.appStockMinimum(
              AppFormatters.formatQuantity(item.currentStock, item.baseUnit),
              AppFormatters.formatQuantity(item.minStock, item.baseUnit),
            ),
      icon: Icons.manage_search_outlined,
      onTap: () => _open(
        ProductsView(
          service: ProductService(client: c.api),
          inventoryService: InventoryService(client: c.api),
          initialLowStockOnly: true,
        ),
      ),
    );
  }

  Widget _business() {
    final l = context.l10n, d = c.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _periods(),
        _gap(),
        _label(l.appBusinessContext(_range())),
        _gap(),
        if (c.loading)
          const Center(child: CircularProgressIndicator())
        else if (c.error != null)
          _failure()
        else if (d != null) ...[
          ApprovedSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(l.appSalesWhen(_when())),
                _gap(4),
                Text(
                  AppFormatters.formatCurrency(d.sales.totalSoldCents),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                _label(l.appBasketsCount(d.sales.soldCount)),
              ],
            ),
          ),
          _gap(),
          ApprovedSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(l.appBusinessResult(_range())),
                _gap(4),
                Text(
                  AppFormatters.formatCurrency(
                    d.financial.operatingResultCents,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _gap(),
                Text(
                  l.appResultExplanation,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (d.financial.salesWithoutCostCount > 0) ...[
                  _gap(),
                  ApprovedWarningBox(
                    text: l.appIncompleteCost(d.financial.salesWithoutCostCount),
                  ),
                ],
                _gap(),
                ApprovedSecondaryButton(
                  text: l.appUnderstandResult,
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () =>
                      _open(_ResultPage(controller: c, range: _range())),
                ),
              ],
            ),
          ),
          _gap(),
          if (d.sales.sales.isNotEmpty) ...[
            for (final sale in d.sales.sales.take(1)) ...[
              ApprovedRow(
                title: l.receiptFlowSaleRef(sale.saleNumber),
                subtitle: 'Conferir itens, cliente e pagamento',
                icon: Icons.point_of_sale_outlined,
                onTap: () => _open(
                  SaleOriginView(
                    saleId: sale.id,
                    saleNumber: sale.saleNumber,
                    load: () => SaleService(client: c.api).getSale(sale.id),
                  ),
                ),
              ),
              _gap(8),
            ],
          ] else ...[
            ApprovedRow(
              title: l.appSaleOrigin,
              subtitle: 'Conferir itens, cliente e pagamento',
              icon: Icons.shopping_basket_outlined,
              onTap: () => _open(SalesView(apiClient: c.api)),
            ),
            _gap(8),
          ],
          ApprovedRow(
            title: l.appCustomers,
            subtitle: l.appCustomersDescription,
            icon: Icons.people_outline,
            onTap: () => _open(const CustomersView()),
          ),
        ],
      ],
    );
  }

  Widget _menu(
    List<(String, String, IconData, Widget)> entries,
    String context,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _label(context),
      _gap(),
      for (final e in entries) ...[
        ApprovedRow(
          title: e.$1,
          subtitle: e.$2,
          icon: e.$3,
          onTap: () => _open(e.$4),
        ),
        _gap(8),
      ],
    ],
  );
  Widget _inventory() {
    final l = context.l10n;
    return _menu([
      (
        l.appProducts,
        l.appProductsDescription,
        Icons.inventory_2_outlined,
        ProductsView(
          service: ProductService(client: c.api),
          inventoryService: InventoryService(client: c.api),
        ),
      ),
      (
        l.appPurchases,
        l.appPurchasesDescription,
        Icons.local_shipping_outlined,
        const PurchasesView(),
      ),
      (
        l.appBasketsAssembly,
        l.appBasketsDescription,
        Icons.shopping_basket_outlined,
        const BasketTypesView(),
      ),
      (
        l.appMovements,
        l.appMovementsDescription,
        Icons.history,
        const InventoryMovementsView(),
      ),
    ], l.appInventoryContext);
  }

  Widget _more() {
    final l = context.l10n;
    return _menu([
      (
        l.appReports,
        l.appReportsDescription,
        Icons.bar_chart,
        const ReportsView(),
      ),
      (
        l.appPrinting,
        l.appPrintingDescription,
        Icons.print_outlined,
        const BlankFormsView(),
      ),
      (
        l.appSettingsConnection,
        l.appSettingsDescription,
        Icons.settings_outlined,
        const AppSettingsMenuView(),
      ),
      (
        l.appBackup,
        l.appBackupDescription,
        Icons.backup_outlined,
        const SettingsView(),
      ),
    ], l.appMoreContext);
  }

  Widget _areaRoot(int area) {
    final l = context.l10n;
    return ApprovedPage(
      title: [
        l.appOverview,
        l.appFinance,
        l.appBusiness,
        l.appInventory,
        l.appMore,
      ][area],
      compact: area == 0,
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: SingleChildScrollView(
          controller: _scroll[area],
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width > 550 ? 22 : 18,
            0,
            MediaQuery.sizeOf(context).width > 550 ? 22 : 18,
            area == 0
                ? 14
                : MediaQuery.sizeOf(context).width > 550
                ? 28
                : 24,
          ),
          child: switch (area) {
            0 => _home(),
            1 => AppFinanceView(
              controller: c,
              tab: _financeTab,
              onTab: (tab) => setState(() => _financeTab = tab),
              onAccount: (a) => _payment(a.payable, a.id),
              onPending: _payment,
              onPayableTools: () => _open(
                PayablesView(
                  service: c.payables,
                  paymentCoordinator: c.payCoordinator,
                ),
              ),
              onReceivableTools: () => _open(
                ReceivablesView(
                  service: c.receivables,
                  paymentCoordinator: c.receiveCoordinator,
                ),
              ),
            ),
            2 => _business(),
            3 => _inventory(),
            _ => _more(),
          },
        ),
      ),
    );
  }

  Widget _navigation(bool wide) {
    final l = context.l10n,
        p = AppPalette.of(context),
        names = [
          l.appHome,
          l.appFinance,
          l.appBusiness,
          l.appInventory,
          l.appMore,
        ];
    final icons = [
      Icons.home_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.shopping_bag_outlined,
      Icons.inventory_2_outlined,
      Icons.more_horiz,
    ];
    Widget entry(int i) {
      final selected = i == _area,
          icon = approvedRoleIcon(
            icons[i],
            size: 16,
            color: selected ? p.accent : p.sub,
          );
      final label = Text(
        names[i],
        style: TextStyle(
          fontFamily: selected ? 'Segoe UI Semibold' : 'Segoe UI',
          fontSize: wide ? 13 : 11,
          color: selected ? p.accent : p.sub,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
        ),
        textAlign: wide ? TextAlign.left : TextAlign.center,
      );
      return Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? p.soft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('area-$i'),
            borderRadius: BorderRadius.circular(12),
            onTap: _operationLock.locked ? null : () => _selectArea(i),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: wide ? 48 : 60),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 10 : 2,
                  vertical: 6,
                ),
                child: wide
                    ? Row(
                        children: [
                          icon,
                          const SizedBox(width: 10),
                          Expanded(child: label),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [icon, const SizedBox(height: 6), label],
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: wide
            ? Border(right: BorderSide(color: p.line))
            : Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: wide
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 18)
              : const EdgeInsets.fromLTRB(6, 9, 6, 12),
          child: wide
              ? Column(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      entry(i),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(child: entry(i)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth > 550;
      final content = IndexedStack(
        index: _area,
        children: [
          for (var area = 0; area < 5; area++)
            Navigator(
              key: _navigators[area],
              pages: [
                MaterialPage<void>(
                  key: ValueKey('root-$area'),
                  child: _areaRoot(area),
                ),
              ],
              onDidRemovePage: (_) {},
            ),
        ],
      );
      return AppOperationScope(
        lock: _operationLock,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop && !_operationLock.locked) {
              await _navigators[_area].currentState!.maybePop();
            }
          },
          child: Scaffold(
            backgroundColor: AppPalette.of(context).page,
            body: ApprovedBackdrop(
              child: wide
                  ? Row(
                      children: [
                        SizedBox(width: 140, child: _navigation(true)),
                        Expanded(child: content),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: content),
                        _navigation(false),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}

class _ResultPage extends StatelessWidget {
  final AppOverviewController controller;
  final String range;
  const _ResultPage({required this.controller, required this.range});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, f = controller.summary!.financial;
    final lines = [
      (l.appConfirmedSales, f.salesRevenueCents),
      (l.appSoldCosts, f.soldBasketsCostCents),
      (l.appGrossProfit, f.grossProfitCents),
      (l.appPaidExpenses, f.operatingExpensesPaidCents),
      (l.appResult, f.operatingResultCents),
    ];
    return ApprovedPage(
      title: l.appUnderstandResult,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: ApprovedSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appBusinessResult(range),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                l.appResultHow,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(lines[i].$1),
                      Text(AppFormatters.formatCurrency(lines[i].$2)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (f.salesWithoutCostCount > 0) ...[
                const SizedBox(height: 20),
                ApprovedWarningBox(
                  text: l.appIncompleteCost(f.salesWithoutCostCount),
                ),
              ],
              const SizedBox(height: 20),
              Text(l.appResultNotBank),
              const SizedBox(height: 20),
              ApprovedSecondaryButton(
                text: 'Voltar ao contexto',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

