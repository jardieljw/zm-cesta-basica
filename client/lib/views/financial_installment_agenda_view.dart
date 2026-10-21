import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/l10n_extension.dart';
import '../services/payable_service.dart';
import '../core/api_client.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';

class FinancialInstallmentAgendaView extends StatefulWidget {
  const FinancialInstallmentAgendaView({
    super.key,
    required this.service,
    required this.filters,
  });
  final PayableService service;
  final Map<String, String> filters;
  @override
  State<FinancialInstallmentAgendaView> createState() => _AgendaState();
}

class _AgendaState extends State<FinancialInstallmentAgendaView> {
  Map<String, dynamic>? _agenda, _attempt;
  final List<Map<String, dynamic>> _items = [];
  String? _error, _key;
  bool _busy = false;
  int _version = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    final version = ++_version;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.service.getInstallmentAgenda(
        widget.filters,
        offset: more ? _items.length : 0,
      );
      if (!mounted || version != _version) return;
      // A changed snapshot invalidates pagination; refresh the whole query.
      if (more && result['snapshot'] != _agenda?['snapshot']) {
        await _load();
        return;
      }
      setState(() {
        if (!more) _items.clear();
        _items.addAll(
          (result['items'] as List).map(
            (i) => Map<String, dynamic>.from(i as Map),
          ),
        );
        _agenda = result;
      });
    } catch (e) {
      if (mounted && version == _version) {
        setState(
          () => _error = ApiErrorMapper.toLocalizedMessage(e, context.l10n),
        );
      }
    } finally {
      if (mounted && version == _version) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.resolveInstallment(_attempt!, _key!);
      if (!mounted) return;
      _attempt = null;
      _key = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.installmentConfirmed)),
      );
      await _load();
    } catch (e) {
      if (mounted &&
          e is ApiException &&
          e.statusCode >= 400 &&
          e.statusCode < 500) {
        _attempt = null;
        _key = null;
        await _load();
      }
      if (mounted) {
        setState(
          () => _error = ApiErrorMapper.toLocalizedMessage(e, context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decision(Map row, {Map? candidate, bool cancel = false}) async {
    final l = context.l10n;
    var reason = '';
    var from = '${row['number']}';
    String? evidence;
    final credits = (_agenda?['cancellation_evidence'] as List? ?? [])
        .where((c) => c['source_id'] == row['financial_source']?['id'])
        .toList();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(
            cancel
                ? l.installmentCancelSeries
                : candidate == null
                ? l.installmentDistinct
                : l.installmentLink,
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    cancel ? l.installmentCancelHelp : l.installmentLinkHelp,
                  ),
                  Text(
                    '${row['description']} · ${row['number']}/${row['total']} · ${AppFormatters.formatCurrency(row['amount_cents'] as int)}',
                  ),
                  if (candidate != null) ...[
                    Text(
                      '${candidate['description']} · ${AppFormatters.formatCurrency(candidate['amount_cents'] as int)}',
                    ),
                    Text(
                      '${l.installmentOrigin}: ${_month(candidate['origin_reference'])} · ${candidate['origin_number']}/${row['total']} · #${candidate['origin_position']} · ${_date(candidate['purchase_date'])}',
                    ),
                    Text(_date(candidate['estimated_due_on'])),
                    Text(_date(row['due_on'])),
                  ],
                  if (cancel) ...[
                    TextFormField(
                      initialValue: from,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.installmentCancelFrom,
                      ),
                      onChanged: (v) => change(() => from = v),
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.installmentCancelEvidence,
                      ),
                      items: [
                        for (final c in credits)
                          DropdownMenuItem(
                            value: c['item_id'] as String,
                            child: Text(
                              '${c['description']} · ${AppFormatters.formatCurrency(c['amount_cents'] as int)}',
                            ),
                          ),
                      ],
                      onChanged: (v) => change(() => evidence = v),
                    ),
                  ],
                  TextFormField(
                    initialValue: reason,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(labelText: l.installmentReason),
                    onChanged: (v) => change(() => reason = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed:
                  reason.trim().length < 3 ||
                      cancel &&
                          (evidence == null ||
                              (int.tryParse(from) ?? 0) < 1 ||
                              (int.tryParse(from) ?? 1001) >
                                  (row['total'] as int))
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l.installmentConfirm),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      final provenance = cancel
          ? credits
                .where(
                  (item) =>
                      item['item_id'] == evidence || item['id'] == evidence,
                )
                .firstOrNull
          : row;
      _attempt = {
        'action': cancel
            ? 'CANCEL'
            : candidate == null
            ? 'DISTINCT'
            : 'LINK',
        if (provenance?['import_id'] != null)
          'import_id': provenance!['import_id'],
        if (provenance?['generation'] != null)
          'expected_generation': provenance!['generation'],
        'expected_snapshot': _agenda!['snapshot'],
        'expected_revision': row['expected_revision'] ?? 0,
        'reason': reason.trim(),
        if (!cancel) 'occurrence_id': row['occurrence_id'],
        if (candidate != null || cancel)
          'series_id': cancel ? row['series_id'] : candidate!['series_id'],
        if (cancel) 'evidence_item_id': evidence,
        if (cancel) 'from_number': int.parse(from),
      };
      _key = const Uuid().v4();
      await _send();
    }
  }

  String _date(dynamic value) => value == null
      ? context.l10n.installmentMonthOnly
      : AppFormatters.formatDate(DateTime.parse(value as String));

  String _month(dynamic value) {
    final parts = (value as String).split('-');
    return '${parts[1]}/${parts[0]}';
  }

  String _state(String state) => switch (state) {
    'REPLACED' => context.l10n.installmentReplacedState,
    'CANCELED' => context.l10n.installmentCanceledState,
    'PENDING_LINK' => context.l10n.installmentPendingState,
    _ => context.l10n.installmentEstimatedState,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pending = _agenda?['pending_links'] as List? ?? [];
    return ApprovedPage(
      title: l.installmentAgendaTitle,
      actions: [
        IconButton(
          onPressed: _busy ? null : () => _load(),
          tooltip: l.commonRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.installmentEstimateHelp),
          if (_agenda != null) ...[
            Text(
              '${l.installmentEstimated}: ${AppFormatters.formatCurrency(_agenda!['estimated_cents'] as int)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${l.installmentPending}: ${AppFormatters.formatCurrency(_agenda!['pending_cents'] as int)}',
            ),
          ],
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_attempt != null) ...[
            Text(l.installmentDecisionUncertain),
            TextButton(
              onPressed: _busy ? null : _send,
              child: Text(l.installmentRetry),
            ),
          ],
          for (final row in pending)
            ApprovedSurface(
              padding: const EdgeInsets.all(16),
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.installmentPendingState,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${row['description']} · ${row['number']}/${row['total']} · ${AppFormatters.formatCurrency(row['amount_cents'] as int)} · ${_date(row['due_on'])}',
                  ),
                  Text(l.installmentLinkHelp),
                  for (final candidate in row['candidates'] as List)
                    OutlinedButton(
                      onPressed: _busy || _attempt != null
                          ? null
                          : () => _decision(
                              row as Map,
                              candidate: candidate as Map,
                            ),
                      child: Text(
                        '${l.installmentLink}: ${candidate['description']} · ${AppFormatters.formatCurrency(candidate['amount_cents'] as int)} · ${_date(candidate['estimated_due_on'])} · ${_month(candidate['origin_reference'])} · ${candidate['origin_number']}/${row['total']} · #${candidate['origin_position']} · ${_date(candidate['purchase_date'])}',
                      ),
                    ),
                  TextButton(
                    onPressed: _busy || _attempt != null
                        ? null
                        : () => _decision(row as Map),
                    child: Text(l.installmentDistinct),
                  ),
                ],
              ),
            ),
          if (_agenda != null && _items.isEmpty) Text(l.installmentEmpty),
          for (final row in _items)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ApprovedSurface(
                padding: const EdgeInsets.all(16),
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${row['description']} · ${row['number']}/${row['total']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${row['financial_source']['name']} · ${_month(row['reference'])}',
                    ),
                    Text(
                      '${_state(row['state'] as String)} · ${AppFormatters.formatCurrency(row['amount_cents'] as int)}',
                    ),
                    Text(_date(row['estimated_due_on'])),
                    if (row['state'] == 'ESTIMATED' &&
                        (_agenda?['cancellation_evidence'] as List? ?? []).any(
                          (c) =>
                              c['source_id'] == row['financial_source']['id'],
                        ))
                      TextButton(
                        onPressed: _busy || _attempt != null
                            ? null
                            : () => _decision(row, cancel: true),
                        child: Text(l.installmentCancelSeries),
                      ),
                  ],
                ),
              ),
            ),
          if (_agenda != null && _items.length < (_agenda!['count'] as int))
            TextButton(
              onPressed: _busy ? null : () => _load(more: true),
              child: Text(l.pdfImportMore),
            ),
        ],
      ),
    );
  }
}
