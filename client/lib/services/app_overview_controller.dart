import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/dashboard.dart';
import '../utils/business_dates.dart';
import 'dashboard_service.dart';
import 'payable_service.dart';
import 'receivable_service.dart';
import 'payable_payment_coordinator.dart';
import 'receivable_payment_coordinator.dart';

enum OverviewPeriod { day, week, month }

enum DueScope { week, today, month, overdue, next, open }

/// Read-only presentation snapshot. Balances, sold cost, result and stock are
/// supplied by the existing domain endpoints; no ledger rule lives here.
class OverviewAccount {
  final String id, name, status;
  final bool payable;
  final int number, original, paid, balance;
  final DateTime due;
  const OverviewAccount({
    required this.id,
    required this.name,
    required this.status,
    required this.payable,
    required this.number,
    required this.original,
    required this.paid,
    required this.balance,
    required this.due,
  });
}

class AppOverviewController extends ChangeNotifier {
  final ApiClient api;
  late final DashboardService dashboard;
  final bool _ownsApi;
  late final payables = PayableService(client: api);
  late final receivables = ReceivableService(client: api);
  late final payCoordinator = PayablePaymentCoordinator(service: payables);
  late final receiveCoordinator = ReceivablePaymentCoordinator(
    service: receivables,
  );
  OverviewPeriod period = OverviewPeriod.week;
  DueScope payScope = DueScope.week, receiveScope = DueScope.week;
  DashboardSummary? summary, today;
  Object? error;
  bool loading = true, _disposed = false;
  int _generation = 0;
  List<PayablePaymentAttempt> payPending = [];
  List<ReceivablePaymentAttempt> receivePending = [];
  bool pendingUnavailable = false;

  AppOverviewController({ApiClient? client, DashboardService? service})
    : api = client ?? ApiClient(),
      _ownsApi = client == null {
    dashboard = service ?? DashboardService(client: api);
  }

  DateTime get businessDay => today?.filterInfo.startDate == null
      ? BusinessDates.today()
      : BusinessDates.dayOf(today!.filterInfo.startDate!);
  (DateTime, DateTime) bounds(OverviewPeriod selected) {
    final day = businessDay;
    return switch (selected) {
      OverviewPeriod.day => (day, day),
      OverviewPeriod.week => (
        day.subtract(Duration(days: day.weekday - 1)),
        day.add(Duration(days: 7 - day.weekday)),
      ),
      OverviewPeriod.month => (
        DateTime(day.year, day.month),
        DateTime(day.year, day.month + 1, 0),
      ),
    };
  }

  Future<void> selectPeriod(OverviewPeriod selected) async {
    if (selected == period && summary != null) return;
    period = selected;
    await refresh();
  }

  void selectScope(bool payable, DueScope scope) {
    if (payable) {
      payScope = scope;
    } else {
      receiveScope = scope;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    final pending = _loadPending(generation);
    try {
      final day = await dashboard.getDashboardSummary(filterType: 'today');
      if (_disposed || generation != _generation) return;
      today = day;
      final range = bounds(period);
      final data = period == OverviewPeriod.day
          ? day
          : await dashboard.getDashboardSummary(
              filterType: 'range',
              startDate: BusinessDates.iso(range.$1),
              endDate: BusinessDates.iso(range.$2),
            );
      if (_disposed || generation != _generation) return;
      summary = data;
    } catch (failure) {
      if (!_disposed && generation == _generation) error = failure;
    } finally {
      await pending;
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadPending(int generation) async {
    try {
      final pay = await payCoordinator.pending();
      final receive = await receiveCoordinator.pending();
      if (_disposed || generation != _generation) return;
      payPending = pay;
      receivePending = receive;
      pendingUnavailable = false;
    } catch (_) {
      if (!_disposed && generation == _generation) pendingUnavailable = true;
    }
  }

  List<OverviewAccount> accounts(bool payable, [DueScope? requested]) {
    final data = summary;
    if (data == null) return [];
    final records = payable
        ? data.financial.payablesRecords.map(
            (r) => OverviewAccount(
              id: r.id,
              name: r.beneficiary,
              status: r.status,
              payable: true,
              number: r.payableNumber,
              original: r.originalAmountCents,
              paid: r.paidAmountCents,
              balance: r.balanceCents,
              due: BusinessDates.dayOf(r.dueDate),
            ),
          )
        : data.financial.receivablesRecords.map(
            (r) => OverviewAccount(
              id: r.id,
              name: r.customerName,
              status: r.status,
              payable: false,
              number: r.saleNumber,
              original: r.originalAmountCents,
              paid: r.paidAmountCents,
              balance: r.balanceCents,
              due: BusinessDates.dayOf(r.dueDate),
            ),
          );
    final scope = requested ?? (payable ? payScope : receiveScope);
    final day = businessDay,
        week = bounds(OverviewPeriod.week),
        month = bounds(OverviewPeriod.month);
    bool between(DateTime date, DateTime start, DateTime end) =>
        !date.isBefore(start) && !date.isAfter(end);
    return records
        .where((r) => r.balance > 0 && {'OPEN', 'PARTIAL'}.contains(r.status))
        .where(
          (r) => switch (scope) {
            DueScope.open => true,
            DueScope.today => r.due == day,
            DueScope.overdue => r.due.isBefore(day),
            DueScope.week => between(r.due, week.$1, week.$2),
            DueScope.month => between(r.due, month.$1, month.$2),
            DueScope.next => between(
              r.due,
              day.add(const Duration(days: 1)),
              day.add(const Duration(days: 3)),
            ),
          },
        )
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    payCoordinator.dispose();
    receiveCoordinator.dispose();
    if (_ownsApi) api.close();
    super.dispose();
  }
}
