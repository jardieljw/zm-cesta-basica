import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';
import '../services/catalog_action_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/catalog_blockers.dart';

class BasketDisassemblyView extends StatefulWidget {
  final Map<String, dynamic> batch;
  final ApiClient? apiClient;
  const BasketDisassemblyView({super.key, required this.batch, this.apiClient});
  @override
  State<BasketDisassemblyView> createState() => _BasketDisassemblyViewState();
}

class _BasketDisassemblyViewState extends State<BasketDisassemblyView> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  late final CatalogActionService _actions;
  bool _intact = false, _busy = true, _pending = false;
  String? _error;
  Map<String, dynamic>? _review;
  List<Map<String, dynamic>> _blockers = [];
  String get _resource => 'disassemble_${widget.batch['id']}';
  @override
  void initState() {
    super.initState();
    _actions = CatalogActionService(client: widget.apiClient);
    _quantity.text = '${widget.batch['current_batch_stock']}';
    _restore();
  }

  Future<void> _restore() async {
    try {
      final old = await _actions.pending(_resource);
      if (old != null) {
        final payload = old['payload'] as Map;
        _quantity.text = '${payload['quantity_to_disassemble']}';
        _reason.text = payload['reason'] as String;
        _intact = true;
        _pending = true;
      }
    } catch (error) {
      if (mounted) {
        _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirm() async {
    final qty = int.tryParse(_quantity.text);
    if (!_pending && (qty == null || qty < 1 || !_intact)) {
      setState(() => _error = context.l10n.catalogInvalidQuantity);
      return;
    }
    if (!_pending && _reason.text.trim().length < 3) {
      setState(() => _error = context.l10n.catalogReasonRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_pending && _review == null) {
        final review = await _actions.client.post(
          '/api/v1/production/batches/${widget.batch['id']}/disassembly-preview',
          body: {'quantity_to_disassemble': qty, 'reason': _reason.text.trim()},
          isMutation: false,
        );
        if (mounted) {
          setState(() => _review = Map<String, dynamic>.from(review as Map));
        }
        return;
      }
      await _actions.run(
        _resource,
        '/api/v1/production/batches/${widget.batch['id']}/disassemble',
        'POST',
        {'quantity_to_disassemble': qty, 'reason': _reason.text.trim()},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      final pending = await _actions.pending(_resource);
      final detail = error is ApiException && error.details is Map
          ? error.details['detail']
          : null;
      if (mounted) {
        setState(() {
          _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n);
          _pending = pending != null;
          _blockers = detail is Map
              ? (detail['blockers'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ApprovedPage(
      title: l.catalogDisassemble,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.assemblyBatch(
                    widget.batch['batch_number'] as int,
                    widget.batch['quantity_produced'] as int,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(l.catalogDisassemblyHelp),
                for (final item in widget.batch['items'] as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['product_name'] as String),
                    subtitle: Text(
                      AppFormatters.formatQuantity(
                        item['quantity_consumed_base_units'] as num,
                        item['product_base_unit'] as String,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantity,
                  enabled: !_busy && !_pending,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _review = null),
                  decoration: InputDecoration(
                    labelText: l.catalogDisassemblyQuantity,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  enabled: !_busy && !_pending,
                  maxLines: 3,
                  onChanged: (_) => setState(() => _review = null),
                  decoration: InputDecoration(
                    labelText: l.catalogDisassemblyReason,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _intact,
                  title: Text(l.catalogDisassemblyIntact),
                  onChanged: _busy || _pending
                      ? null
                      : (v) => setState(() {
                          _intact = v ?? false;
                          _review = null;
                        }),
                ),
                if (_review != null) ...[
                  const SizedBox(height: 12),
                  Text(l.catalogDisassemblyReturns),
                  for (final item in _review!['items'] as List)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['product_name'] as String),
                      subtitle: Text(
                        AppFormatters.formatQuantity(
                          item['quantity_returned_base_units'] as num,
                          item['product_base_unit'] as String,
                        ),
                      ),
                    ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_blockers.isNotEmpty)
                  CatalogBlockers(
                    blockers: _blockers,
                    apiClient: widget.apiClient,
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _confirm,
                  icon: const Icon(Icons.undo),
                  label: Text(
                    _pending
                        ? l.catalogRetryAction
                        : _review == null
                        ? l.catalogReviewDisassembly
                        : l.catalogDisassemble,
                  ),
                ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
