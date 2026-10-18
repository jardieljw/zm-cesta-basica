import '../utils/adaptive_ui_color.dart';
import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/basket_type.dart';
import '../models/customer.dart';
import '../services/sale_service.dart';
import '../services/basket_service.dart';
import '../services/customer_service.dart';
import '../services/inventory_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import '../core/api_client.dart';
import '../widgets/shared/animated_reveal.dart';

class _SaleItemRow {
  BasketType? basketType;
  bool assembleOnDemand = false;
  int quantity = 1;
  int unitPriceCents = 0;
  int discountCents = 0;
  int availableStock = 0;
  bool isLoadingStock = false;
  bool stockQueryFailed = false;
  int stockRequestVersion = 0;

  int get subtotalCents => (quantity * unitPriceCents) - discountCents;
}

class SaleFormView extends StatefulWidget {
  final ApiClient? apiClient;

  const SaleFormView({super.key, this.apiClient});

  @override
  State<SaleFormView> createState() => _SaleFormViewState();
}

class _SaleFormViewState extends State<SaleFormView> {
  late final SaleService _saleService;
  late final BasketService _basketService;
  late final CustomerService _customerService;
  late final InventoryService _inventoryService;

  List<BasketType> _basketTypes = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  String _paymentMode = 'CASH_IMMEDIATE';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _anonymousCustomerController =
      TextEditingController();

  final List<_SaleItemRow> _items = [];

  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _saleService = SaleService(client: widget.apiClient);
    _basketService = BasketService(client: widget.apiClient);
    _customerService = CustomerService(client: widget.apiClient);
    _inventoryService = InventoryService(client: widget.apiClient);
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _anonymousCustomerController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      final baskets = await _basketService.getBasketTypes(isActive: true);
      final custs = await _customerService.getCustomers(isActive: true);
      setState(() {
        _basketTypes = baskets;
        _customers = custs;
        _isLoadingInitial = false;
      });

      if (_basketTypes.isNotEmpty && _items.isEmpty) {
        _addItem();
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoadingInitial = false;
      });
    }
  }

  void _addItem() {
    final row = _SaleItemRow();
    if (_basketTypes.isNotEmpty) {
      row.basketType = _basketTypes.first;
      row.unitPriceCents = _basketTypes.first.defaultPriceCents;
      row.assembleOnDemand = !_basketTypes.first.tracksFinishedStock;
      if (!row.assembleOnDemand) _fetchStockForRow(row);
    }
    setState(() {
      _items.add(row);
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _fetchStockForRow(_SaleItemRow row) async {
    if (row.basketType == null) return;
    final basketId = row.basketType!.id;
    final requestVersion = ++row.stockRequestVersion;
    setState(() {
      row.isLoadingStock = true;
      row.stockQueryFailed = false;
    });
    try {
      final res = await _inventoryService.getBasketStock(basketId);
      final currentStock = (res['current_stock'] as num).toInt();
      if (mounted &&
          _items.contains(row) &&
          row.basketType?.id == basketId &&
          row.stockRequestVersion == requestVersion) {
        setState(() {
          row.availableStock = currentStock;
          row.isLoadingStock = false;
        });
      }
    } catch (_) {
      if (mounted &&
          _items.contains(row) &&
          row.basketType?.id == basketId &&
          row.stockRequestVersion == requestVersion) {
        setState(() {
          row.isLoadingStock = false;
          row.stockQueryFailed = true;
        });
      }
    }
  }

  int get _grossTotalCents {
    int sum = 0;
    for (final it in _items) {
      sum += (it.quantity * it.unitPriceCents);
    }
    return sum;
  }

  int get _totalDiscountCents {
    int sum = 0;
    for (final it in _items) {
      sum += it.discountCents;
    }
    return sum;
  }

  int get _netTotalCents => _grossTotalCents - _totalDiscountCents;

  Future<void> _submitSale({bool allowCreditOverride = false}) async {
    final l10n = context.l10n;

    if (_paymentMode == 'CREDIT_TERM' && _selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saleCreditCustomerRequired)));
      return;
    }

    if (_items.isEmpty) return;

    for (final it in _items) {
      if (it.basketType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleSelectBasketTypeRequired)),
        );
        return;
      }
      if (it.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleQuantityMustBePositive)),
        );
        return;
      }
      if (!it.assembleOnDemand && (it.isLoadingStock || it.stockQueryFailed)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              it.isLoadingStock
                  ? l10n.saleStockLoading
                  : l10n.saleStockQueryFailed,
            ),
          ),
        );
        return;
      }
      if (!it.assembleOnDemand && it.availableStock < it.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.saleInsufficientStockAlert(
                it.basketType!.name,
                it.availableStock,
                it.quantity,
              ),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final saleItems = _items.map((it) {
      return SaleItemCreate(
        basketTypeId: it.basketType!.id,
        quantity: it.quantity,
        unitPriceCents: it.unitPriceCents,
        discountCents: it.discountCents,
        assembleOnDemand: it.assembleOnDemand,
      );
    }).toList();

    final saleCreate = SaleCreate(
      customerId: _selectedCustomer?.id,
      customerName:
          _selectedCustomer == null &&
              _anonymousCustomerController.text.trim().isNotEmpty
          ? _anonymousCustomerController.text.trim()
          : null,
      saleMode: 'DIRECT_STORE',
      paymentMode: _paymentMode,
      dueDate: _paymentMode == 'CREDIT_TERM' ? _dueDate : null,
      allowCreditOverride: allowCreditOverride,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      items: saleItems,
    );

    try {
      await _saleService.createSale(saleCreate);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saleCreatedSuccess)));
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (e.errorCode == 'CREDIT_LIMIT_EXCEEDED') {
        setState(() => _isSubmitting = false);
        final details = e.details as Map<String, dynamic>?;
        final exceededCents = details?['exceeded_by_cents'] ?? 0;
        final exceededFormatted = AppFormatters.formatCurrency(exceededCents);

        if (mounted) {
          final confirmOverride = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.saleCreditLimitAlertTitle),
              content: Text(
                l10n.saleCreditLimitAlertMessage(exceededFormatted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                  ),
                  child: Text(
                    l10n.saleCreditLimitAuthorize,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (confirmOverride == true) {
            _submitSale(allowCreditOverride: true);
          }
        }
      } else {
        setState(() {
          _errorMessage = ApiErrorMapper.toLocalizedMessage(e, l10n);
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, l10n);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.saleNew)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.saleNew)),
      bottomNavigationBar: _buildBottomSummaryBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adaptiveUiSurface(context, Colors.red.shade50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: adaptiveUiSurface(context, Colors.red.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildCustomerSection(context),
            const SizedBox(height: 16),
            _buildPaymentSection(context),
            const SizedBox(height: 24),
            _buildItemsSection(context),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.commonNotes,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.saleCustomer,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Customer?>(
              isExpanded: true,
              initialValue: _selectedCustomer,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                labelText: _paymentMode == 'CREDIT_TERM'
                    ? '${l10n.saleCustomer} *'
                    : l10n.saleCustomer,
              ),
              items: [
                DropdownMenuItem<Customer?>(
                  value: null,
                  child: Text(
                    l10n.saleCustomerAnonymous,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ..._customers.map(
                  (c) => DropdownMenuItem<Customer?>(
                    value: c,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedCustomer = val);
              },
            ),
            if (_selectedCustomer == null && _paymentMode != 'CREDIT_TERM') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _anonymousCustomerController,
                decoration: InputDecoration(
                  labelText: l10n.saleAnonymousCustomerHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
            ],
            if (_selectedCustomer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adaptiveUiSurface(context, Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.customerCreditLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _selectedCustomer!.creditLimitCents > 0
                              ? AppFormatters.formatCurrency(
                                  _selectedCustomer!.creditLimitCents,
                                )
                              : l10n.customerCreditLimitUnlimited,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.customerCurrentDebt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(
                            _selectedCustomer!.currentDebtCents,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedCustomer!.currentDebtCents > 0
                                ? adaptiveUiText(context, Colors.red.shade700)
                                : adaptiveUiText(
                                    context,
                                    Colors.green.shade700,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.salePaymentMode,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _paymentMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: [
                DropdownMenuItem(
                  value: 'CASH_IMMEDIATE',
                  child: Text(l10n.salePaymentModeCash),
                ),
                DropdownMenuItem(
                  value: 'PIX',
                  child: Text(l10n.salePaymentModePix),
                ),
                DropdownMenuItem(
                  value: 'CARD',
                  child: Text(l10n.salePaymentModeCard),
                ),
                DropdownMenuItem(
                  value: 'CREDIT_TERM',
                  child: Text(l10n.salePaymentModeCredit),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _paymentMode = val);
                }
              },
            ),
            if (_paymentMode == 'CREDIT_TERM') ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: Colors.orange),
                title: Text(l10n.saleDueDate),
                subtitle: Text(
                  '${AppFormatters.formatDate(_dueDate)} (${l10n.saleDueDateSuggested})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: TextButton(
                  child: Text(l10n.commonEdit),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.saleItemsSection,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: Text(l10n.saleAddItem),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _buildItemCard(context, index, row);
        }),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, int index, _SaleItemRow row) {
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<BasketType>(
                    initialValue: row.basketType,
                    decoration: InputDecoration(
                      labelText: l10n.saleBasketType,
                      border: const OutlineInputBorder(),
                    ),
                    items: _basketTypes
                        .map(
                          (bt) =>
                              DropdownMenuItem(value: bt, child: Text(bt.name)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          row.basketType = val;
                          row.unitPriceCents = val.defaultPriceCents;
                          row.assembleOnDemand = !val.tracksFinishedStock;
                        });
                        if (!row.assembleOnDemand) _fetchStockForRow(row);
                      }
                    },
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (row.basketType?.tracksFinishedStock != false)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l10n.saleAssemblyModeStock,
                      style: TextStyle(
                        fontWeight: !row.assembleOnDemand
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: !row.assembleOnDemand
                            ? adaptiveUiText(context, Colors.green.shade800)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: l10n.saleAssemblyMode,
                    value: row.assembleOnDemand
                        ? l10n.saleAssemblyModeDemand
                        : l10n.saleAssemblyModeStock,
                    child: Switch(
                      value: row.assembleOnDemand,
                      thumbColor: const WidgetStatePropertyAll(Colors.white),
                      trackColor: WidgetStatePropertyAll(
                        row.assembleOnDemand
                            ? Colors.orange.shade800
                            : Colors.green.shade700,
                      ),
                      trackOutlineColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      onChanged: (val) {
                        setState(() => row.assembleOnDemand = val);
                        if (!val) _fetchStockForRow(row);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.saleAssemblyModeDemand,
                      style: TextStyle(
                        fontWeight: row.assembleOnDemand
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: row.assembleOnDemand
                            ? adaptiveUiText(context, Colors.orange.shade900)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            if (row.basketType?.tracksFinishedStock == false)
              Text(
                l10n.saleAssemblyAutomatic,
                style: TextStyle(
                  color: adaptiveUiText(context, Colors.orange.shade900),
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            if (MediaQuery.disableAnimationsOf(context))
              Text(
                row.assembleOnDemand
                    ? l10n.saleAssemblyDemandHelp
                    : l10n.saleAssemblyStockHelp,
              )
            else
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: Text(
                  row.assembleOnDemand
                      ? l10n.saleAssemblyDemandHelp
                      : l10n.saleAssemblyStockHelp,
                ),
              ),
            AnimatedReveal(
              visible: !row.assembleOnDemand,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    if (row.isLoadingStock)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        row.stockQueryFailed
                            ? Icons.error_outline
                            : Icons.inventory_2_outlined,
                        size: 18,
                        color: adaptiveUiText(context, Colors.green.shade800),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.basketType == null
                            ? l10n.saleStockSelectBasket
                            : row.isLoadingStock
                            ? l10n.saleStockLoading
                            : row.stockQueryFailed
                            ? l10n.saleStockQueryFailed
                            : l10n.saleStockAvailable(row.availableStock),
                      ),
                    ),
                    if (row.stockQueryFailed)
                      IconButton(
                        onPressed: () => _fetchStockForRow(row),
                        icon: const Icon(Icons.refresh),
                        tooltip: l10n.commonRefresh,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: row.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.saleQuantity,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final q = int.tryParse(val) ?? 1;
                      setState(() => row.quantity = q > 0 ? q : 1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: (row.unitPriceCents / 100.0)
                        .toStringAsFixed(2)
                        .replaceAll('.', ','),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.saleUnitPrice,
                      prefixText: 'R\$ ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final cleaned = val
                          .replaceAll('.', '')
                          .replaceAll(',', '.')
                          .trim();
                      final p = double.tryParse(cleaned) ?? 0.0;
                      setState(() => row.unitPriceCents = (p * 100).round());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: (row.discountCents / 100.0)
                        .toStringAsFixed(2)
                        .replaceAll('.', ','),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.saleDiscount,
                      prefixText: 'R\$ ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final cleaned = val
                          .replaceAll('.', '')
                          .replaceAll(',', '.')
                          .trim();
                      final d = double.tryParse(cleaned) ?? 0.0;
                      setState(() => row.discountCents = (d * 100).round());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${l10n.saleSubtotal}: ${AppFormatters.formatCurrency(row.subtotalCents)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummaryBar(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_totalDiscountCents > 0)
                    Text(
                      '${l10n.saleGrossTotal}: ${AppFormatters.formatCurrency(_grossTotalCents)} | ${l10n.saleDiscount}: ${AppFormatters.formatCurrency(_totalDiscountCents)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    '${l10n.saleNetTotal}: ${AppFormatters.formatCurrency(_netTotalCents)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitSale(allowCreditOverride: false),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(l10n.commonConfirm),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
