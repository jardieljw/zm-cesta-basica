import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/money_input.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_operation_scope.dart';

/// Explicit evidence decisions and reconciliation. This page never calls a cash
/// creation, payment or bulk posting endpoint.
class FinancialBankReviewView extends StatefulWidget {
  final FinancialImportService service;
  final String statementId;
  const FinancialBankReviewView({
    super.key,
    required this.service,
    required this.statementId,
  });
  @override
  State<FinancialBankReviewView> createState() =>
      _FinancialBankReviewViewState();
}

class _FinancialBankReviewViewState extends State<FinancialBankReviewView> {
  bool busy = false;
  Object? error;
  List<FinancialJson> items = [];
  FinancialJson? statement, source;
  AppOperationLock? operationLock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    operationLock = AppOperationScope.maybeOf(context);
  }

  @override
  void dispose() {
    operationLock?.setActive(this, false);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final st = await widget.service.getStatement(widget.statementId);
      final origins = await widget.service.sources();
      final result = await widget.service.allRows(
        '${FinancialImportService.root}/statements/${widget.statementId}/items',
      );
      if (mounted) {
        setState(() {
          statement = st;
          source = origins.where((s) => s['id'] == st['source_id']).firstOrNull;
          items = result;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _open(FinancialJson item) async {
    if (source == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BankOccurrenceView(
          service: widget.service,
          item: item,
          source: source!,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ApprovedPage(
      title: l.importReviewBank,
      actions: [
        IconButton(
          tooltip: l.commonRefresh,
          onPressed: busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ApprovedSurface(child: Text(l.importBankHelp)),
          const SizedBox(height: 20),
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(ApiErrorMapper.toLocalizedMessage(error, l)),
          for (final item in items) ...[
            ApprovedRow(
              title: item['normalized_data']['description'] as String,
              subtitle:
                  '${AppFormatters.formatDate(DateTime.parse(item['normalized_data']['transaction_date'] as String))} · ${AppFormatters.formatCurrency(item['normalized_data']['amount_cents'] as int)}\n${item['review_status'] == 'IGNORED'
                      ? l.importIgnored
                      : item['transaction_id'] == null
                      ? l.importEvidencePending
                      : l.importEvidenceReviewed}',
              onTap: busy ? () {} : () => _open(item),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BankOccurrenceView extends StatefulWidget {
  final FinancialImportService service;
  final FinancialJson item, source;
  const _BankOccurrenceView({
    required this.service,
    required this.item,
    required this.source,
  });
  @override
  State<_BankOccurrenceView> createState() => _BankOccurrenceViewState();
}

class _BankOccurrenceViewState extends State<_BankOccurrenceView> {
  late FinancialJson item = widget.item;
  List<FinancialJson> candidates = [], entries = [];
  FinancialJson? transaction;
  final reason = TextEditingController(), amount = TextEditingController();
  String? entryId;
  bool busy = false, distinct = false;
  Object? error;
  AppOperationLock? lock;
  String get base => FinancialImportService.root;
  bool get pending => item['review_status'] == 'PENDING';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lock = AppOperationScope.maybeOf(context);
  }

  @override
  void dispose() {
    lock?.setActive(this, false);
    reason.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    final current = await widget.service.get('$base/items/${item['id']}');
    final matches = await widget.service.rows(
      '$base/items/${item['id']}/candidates',
    );
    final cash = await widget.service.allRows(
      '/api/v1/treasury/entries?account_id=${widget.source['financial_account_id']}',
    );
    FinancialJson? tx;
    if (current['transaction_id'] != null) {
      final transactions = await widget.service.allRows(
        '$base/transactions?source_id=${widget.source['id']}',
      );
      tx = transactions
          .where((t) => t['id'] == current['transaction_id'])
          .firstOrNull;
    }
    final direction = (current['normalized_data']['amount_cents'] as int) > 0
        ? 'CREDIT'
        : 'DEBIT';
    if (mounted) {
      setState(() {
        item = current;
        candidates = matches;
        transaction = tx;
        entries = cash.where((e) => e['entry_type'] == direction).toList();
        if (!entries.any((e) => e['id'] == entryId)) entryId = null;
      });
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool mutation = false,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    if (mutation) lock?.setActive(this, true);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      lock?.setActive(this, false);
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _load() => _run(_read);
  bool _validReason() {
    if (reason.text.trim().length >= 3) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.importReasonRequired)));
    return false;
  }

  Future<void> _decide(String action, {String? transactionId}) async {
    if (!_validReason()) return;
    await _run(() async {
      await widget.service.post('$base/items/${item['id']}/review', {
        ...FinancialImportService.lifecycleContext(item),
        'action': action,
        'reason': reason.text.trim(),
        if (transactionId != null) 'transaction_id': transactionId,
      });
      await _read();
    }, mutation: true);
  }

  Future<void> _reconcile() async {
    if (!_validReason()) return;
    final cents = MoneyInput.cents(amount.text);
    if (cents == null || cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.importHeaderMoneyRequired)),
      );
      return;
    }
    await _run(() async {
      await widget.service.post('$base/reconciliations', {
        ...FinancialImportService.lifecycleContext(item),
        'transaction_id': transaction!['id'],
        'cash_flow_entry_id': entryId,
        'amount_cents': cents,
        'reason': reason.text.trim(),
      });
      await _read();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.importReconciled)));
      }
    }, mutation: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.importBankItem,
        actions: [
          IconButton(
            tooltip: l.commonRefresh,
            onPressed: busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(ApiErrorMapper.toLocalizedMessage(error, l)),
              ),
            ApprovedSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item['normalized_data']['description'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    AppFormatters.formatCurrency(
                      item['normalized_data']['amount_cents'] as int,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l.importBankHelp),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reason,
                    enabled: !busy,
                    maxLength: 1000,
                    decoration: InputDecoration(labelText: l.importReason),
                  ),
                  if (item['review_status'] == 'IGNORED')
                    Text(l.importIgnored)
                  else if (pending) ...[
                    if (candidates.isNotEmpty) ...[
                      Text(l.importCandidates),
                      for (final candidate in candidates)
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _decide(
                                  'LINK',
                                  transactionId:
                                      candidate['transaction']['id'] as String,
                                ),
                          child: Text(
                            '${l.importLinkEvidence} · ${candidate['transaction']['description']}',
                          ),
                        ),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: distinct,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => distinct = v!),
                      title: Text(l.importNewEvidenceAck),
                    ),
                    FilledButton(
                      onPressed: busy || !distinct
                          ? null
                          : () => _decide('NEW'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l.importNewEvidence,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => _decide('IGNORE'),
                      child: Text(l.importIgnore),
                    ),
                  ] else if (transaction != null) ...[
                    Text(l.importRemaining),
                    Text(
                      transaction!['unreconciled_amount_cents'] == null
                          ? l.homeNotAvailable
                          : AppFormatters.formatCurrency(
                              transaction!['unreconciled_amount_cents'] as int,
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      Text(l.importNoCash)
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('cash-entry-$entryId'),
                        initialValue: entryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l.importChooseCash,
                        ),
                        items: entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['id'] as String,
                                child: Text(
                                  '${AppFormatters.formatCurrency(e['amount_cents'] as int)} · ${e['description']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => entryId = v),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amount,
                      enabled: !busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l.importRemaining,
                        helperText: l.importBankPartialHelp,
                        helperMaxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          busy ||
                              entryId == null ||
                              (transaction!['unreconciled_amount_cents']
                                          as int? ??
                                      0) <=
                                  0
                          ? null
                          : _reconcile,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l.importReconcile,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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
