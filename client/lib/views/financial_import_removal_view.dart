import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../services/payable_service.dart';
import '../services/payable_payment_coordinator.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/scroll_layout.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_operation_scope.dart';
import 'payable_payment_view.dart';

class FinancialImportRemovalView extends StatefulWidget {
  const FinancialImportRemovalView({
    super.key,
    required this.service,
    required this.documentId,
    this.importContext,
  });
  final FinancialImportService service;
  final String documentId;
  final FinancialJson? importContext;
  @override
  State<FinancialImportRemovalView> createState() => _RemovalState();
}

class _RemovalState extends State<FinancialImportRemovalView> {
  FinancialJson? plan;
  Object? error;
  bool busy = false;
  String? frozenSnapshot;
  FinancialJson? frozenContext;
  AppOperationLock? lock;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lock = AppOperationScope.maybeOf(context);
  }

  @override
  void dispose() {
    lock?.setActive(this, false);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await widget.service.removalPlan(
        widget.documentId,
        context: widget.importContext ?? frozenContext,
      );
      if (!mounted) return;
      if (value['already_removed'] == true) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        plan = value;
        frozenContext ??=
            widget.importContext ??
            FinancialImportService.lifecycleContext(value);
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove() async {
    frozenSnapshot ??= plan!['snapshot'] as String;
    lock?.setActive(this, true);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.removeImport(
        widget.documentId,
        frozenSnapshot!,
        context: frozenContext,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (e is ApiException && e.statusCode >= 400 && e.statusCode < 500) {
        frozenSnapshot = null;
      }
      if (mounted) setState(() => error = e);
    } finally {
      lock?.setActive(this, false);
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _payable(String id) async {
    final service = PayableService(
      client: await widget.service.forkConnection(),
    );
    final coordinator = PayablePaymentCoordinator(service: service);
    if (!mounted) {
      coordinator.dispose();
      service.close();
      return;
    }
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PayablePaymentView(payableId: id, coordinator: coordinator),
        ),
      );
    } finally {
      coordinator.dispose();
      service.close();
    }
    if (mounted) await _load();
  }

  Future<void> _other(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) =>
            FinancialImportRemovalView(service: widget.service, documentId: id),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final blocked = plan?['blocked'] as List? ?? [];
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.importRemovalTitle,
        actions: [
          IconButton(
            onPressed: busy ? null : _load,
            tooltip: l.commonRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
        floatingActionButton: plan == null || plan!['can_remove'] != true
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('confirm-import-removal'),
                onPressed: busy ? null : _remove,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  frozenSnapshot == null
                      ? l.importRemovalConfirm
                      : l.importRemovalRetry,
                ),
              ),
        body: ListView(
          padding: fabScrollPadding(context, horizontal: 20),
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(ApiErrorMapper.toLocalizedMessage(error, l)),
            if (plan != null)
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(plan!['filename'] as String),
                    const SizedBox(height: 12),
                    Text(l.importRemovalHelp),
                    if ((plan!['payables'] as List).isEmpty)
                      Text(l.importRemovalNoBills)
                    else ...[
                      ApprovedSectionHeader(l.importRemovalBills),
                      for (final title in plan!['payables'] as List)
                        Text(
                          '#${title['number']} · ${AppFormatters.formatCurrency(title['balance_cents'] as int)}',
                        ),
                    ],
                    if ((plan!['restored_payables'] as List? ?? [])
                        .isNotEmpty) ...[
                      ApprovedSectionHeader(l.importRemovalRestoreBills),
                      for (final title in plan!['restored_payables'] as List)
                        Text(
                          '#${title['number']} · ${AppFormatters.formatCurrency(title['balance_cents'] as int)}',
                        ),
                    ],
                    if ((plan!['series_count'] as int) > 0)
                      Text(l.importRemovalForecasts),
                    if (blocked.isNotEmpty) ...[
                      ApprovedSectionHeader(l.importRemovalBlocked),
                      for (final issue in blocked) ...[
                        Text(issue['message'] as String),
                        if (issue['filename'] is String)
                          Text(issue['filename'] as String),
                        if (issue['payable_id'] is String)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _payable(issue['payable_id'] as String),
                            child: Text(l.importRemovalOpenPayable),
                          ),
                        if (issue['document_id'] is String)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _other(issue['document_id'] as String),
                            child: Text(l.importRemovalOtherDocument),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
