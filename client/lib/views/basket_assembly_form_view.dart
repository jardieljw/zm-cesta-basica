import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/basket_type.dart';
import '../services/basket_assembly_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/scroll_layout.dart';
import '../widgets/shared/animated_content_size.dart';
import '../widgets/shared/assembly_composition_editor.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/basket_service.dart';

class BasketAssemblyFormView extends StatefulWidget {
  final BasketType basketType;
  final ApiClient? apiClient;
  const BasketAssemblyFormView(
      {super.key, required this.basketType, this.apiClient});
  @override
  State<BasketAssemblyFormView> createState() => _BasketAssemblyFormViewState();
}

class _BasketAssemblyFormViewState extends State<BasketAssemblyFormView> {
  late final BasketAssemblyService _service;
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  final _customDescription = TextEditingController();
  bool _custom = false;
  List<Map<String, dynamic>> _customItems = [];
  List<Product> _products = [];
  DateTime _occurredAt = DateTime.now();
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _pendingPayload;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _service = BasketAssemblyService(client: widget.apiClient);
    _restorePending();
  }

  Future<void> _restorePending() async {
    try {
      final pending = await _service.pending(widget.basketType.id);
      if (!mounted) return;
      if (pending != null) {
        _pendingPayload = Map<String, dynamic>.from(pending['payload'] as Map);
        _quantity.text = _pendingPayload!['quantity_produced'].toString();
        _notes.text = _pendingPayload!['notes'] as String? ?? '';
        _occurredAt =
            DateTime.parse(_pendingPayload!['occurred_at'] as String).toLocal();
        _custom = _pendingPayload!['is_custom'] == true;
        _customDescription.text =
            _pendingPayload!['custom_description'] as String? ?? '';
        _customItems = (_pendingPayload!['custom_items'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (_custom) {
          _products = await ProductService(client: widget.apiClient)
              .getProducts(isActive: true);
          if (!mounted) return;
          _customItems = _withProductDetails(_customItems);
        }
      }
    } catch (error) {
      if (!mounted) return;
      _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    _customDescription.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
        _preview = null;
        _error = null;
      });

  List<Map<String, dynamic>> get _customInput => _customItems
      .map((item) => {
            'product_id': item['product_id'],
            'quantity_in_base_units': item['quantity_in_base_units'],
            'section': item['section'] ?? 'PERSONALIZADO',
          })
      .toList();

  List<Map<String, dynamic>> _withProductDetails(
          List<Map<String, dynamic>> items) =>
      items.map((item) {
        final index = _products.indexWhere((p) => p.id == item['product_id']);
        return index < 0
            ? item
            : {
                ...item,
                'product_name': _products[index].name,
                'product_base_unit': _products[index].baseUnit,
              };
      }).toList();

  Future<void> _toggleCustom(bool value) async {
    if (!value) {
      setState(() {
        _custom = false;
        _preview = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final results = await Future.wait<Object>([
        ProductService(client: widget.apiClient).getProducts(isActive: true),
        BasketService(client: widget.apiClient)
            .getBasketType(widget.basketType.id),
      ]);
      final basket = results[1] as BasketType;
      if (!basket.allowsCustomization) {
        throw ApiException(
            statusCode: 409, message: '', errorCode: 'CUSTOMIZATION_DISABLED');
      }
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        if (_customItems.isEmpty) {
          _customItems = (basket.activeRecipe?.items ?? [])
              .map((item) => {
                    'product_id': item.productId,
                    'product_name': item.productName,
                    'product_base_unit': item.productBaseUnit,
                    'quantity_in_base_units': item.quantityInBaseUnits,
                    'section': item.section,
                  })
              .toList();
        }
        _customItems = _withProductDetails(_customItems);
        _custom = true;
      });
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _occurredAt,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
    if (time == null || !mounted) return;
    setState(() {
      _occurredAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _preview = null;
    });
  }

  Future<void> _reviewOrConfirm() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_custom && _customItems.isEmpty && _pendingPayload == null) {
      setState(() => _error = context.l10n.assemblyCustomItemsRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_preview == null && _pendingPayload == null) {
        final preview = await _service.preview(
            widget.basketType.id, int.parse(_quantity.text.trim()),
            customDescription: _custom ? _customDescription.text.trim() : null,
            customItems: _custom ? _customInput : null);
        if (mounted) setState(() => _preview = preview);
      } else {
        if (_pendingPayload == null && _preview!['can_produce'] != true) return;
        final payload = _pendingPayload ??
            {
              'basket_type_id': widget.basketType.id,
              'quantity_produced': int.parse(_quantity.text.trim()),
              'is_custom': _custom,
              if (_custom) 'custom_description': _customDescription.text.trim(),
              if (_custom) 'custom_items': _customInput,
              'is_direct_sale': false,
              'occurred_at': _occurredAt.toUtc().toIso8601String(),
              'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              if (!_custom)
                'expected_recipe_version_number':
                    _preview!['recipe_version_number'],
            };
        await _service.create(payload);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      final pending = await _service.pending(widget.basketType.id);
      if (mounted) {
        setState(() {
          _pendingPayload = pending == null
              ? null
              : Map<String, dynamic>.from(pending['payload'] as Map);
          _preview = null;
          _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locked = _busy || _pendingPayload != null;
    final enough = _preview == null || _preview!['can_produce'] == true;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assemblyRegister)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || !enough ? null : _reviewOrConfirm,
        icon: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.check),
        label: Text(_pendingPayload != null
            ? l10n.assemblyRetry
            : _preview == null
                ? l10n.assemblyReview
                : l10n.assemblyConfirm),
      ),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: fabScrollPadding(context, horizontal: 20, top: 20),
          child: AnimatedContentSize(
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.basketType.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(l10n.assemblyRegisterHelp),
                        const SizedBox(height: 20),
                        if (_pendingPayload != null) ...[
                          Text(l10n.assemblyPendingHelp),
                          const SizedBox(height: 16)
                        ],
                        TextFormField(
                            controller: _quantity,
                            enabled: !locked,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: l10n.saleQuantity,
                                border: const OutlineInputBorder()),
                            validator: (value) =>
                                (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                                    ? null
                                    : l10n.saleQuantityMustBePositive,
                            onChanged: (_) => _changed()),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: locked ? null : _pickDateTime,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                                '${l10n.assemblyOccurredAt}: ${AppFormatters.formatDateTime(_occurredAt)}')),
                        const SizedBox(height: 16),
                        if (widget.basketType.allowsCustomization ||
                            _custom) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.assemblyCustomize),
                            subtitle: Text(l10n.assemblyCustomizeHelp),
                            value: _custom,
                            onChanged: locked ? null : _toggleCustom,
                          ),
                          if (_custom) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customDescription,
                              enabled: !locked,
                              maxLength: 500,
                              decoration: InputDecoration(
                                  labelText: l10n.assemblyCustomDescription,
                                  border: const OutlineInputBorder()),
                              validator: (value) =>
                                  value?.trim().isNotEmpty == true
                                      ? null
                                      : l10n.assemblyCustomDescriptionRequired,
                              onChanged: (_) => _changed(),
                            ),
                            const SizedBox(height: 12),
                            AssemblyCompositionEditor(
                              items: _customItems,
                              products: _products,
                              enabled: !locked,
                              onChanged: (items) => setState(() {
                                _customItems = items;
                                _preview = null;
                                _error = null;
                              }),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                            controller: _notes,
                            enabled: !locked,
                            maxLines: 3,
                            decoration: InputDecoration(
                                labelText: l10n.commonNotes,
                                border: const OutlineInputBorder()),
                            onChanged: (_) => _changed()),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))
                        ],
                        if (_preview != null) ...[
                          const SizedBox(height: 24),
                          Text(l10n.assemblyComposition,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(l10n.assemblyEstimatedCost(
                              AppFormatters.formatCurrency(
                                  _preview!['estimated_total_cost_cents']
                                      as num))),
                          for (final raw in _preview!['items'] as List)
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(raw['product_name'] as String,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(l10n.assemblyRequiredAvailable(
                                              AppFormatters.formatQuantity(
                                                  raw['quantity_required']
                                                      as num,
                                                  raw['product_base_unit']
                                                      as String),
                                              AppFormatters.formatQuantity(
                                                  raw['current_stock'] as num,
                                                  raw['product_base_unit']
                                                      as String))),
                                          if (raw['is_sufficient'] != true)
                                            Text(
                                                l10n.assemblyMissing(
                                                    AppFormatters.formatQuantity(
                                                        raw['missing_quantity']
                                                            as num,
                                                        raw['product_base_unit']
                                                            as String)),
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error)),
                                        ]))),
                          if (!enough)
                            Text(l10n.assemblyInsufficientHelp,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          if (!enough)
                            TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        _changed();
                                        _reviewOrConfirm();
                                      },
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.commonRefresh)),
                        ],
                      ]))),
        ),
      )),
    );
  }
}
