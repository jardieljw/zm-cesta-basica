import '../core/api_client.dart';
import '../widgets/shared/responsive_filter_bar.dart';
import '../utils/scroll_layout.dart';
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'customer_form_view.dart';
import 'customer_statement_dialog.dart';
import '../widgets/shared/approved_app_style.dart';

class CustomersView extends StatefulWidget {
  final ApiClient? apiClient;
  const CustomersView({super.key, this.apiClient});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  late final CustomerService _customerService;

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter = true;

  @override
  void initState() {
    super.initState();
    _customerService = CustomerService(client: widget.apiClient);
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _customerService.getCustomers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _activeFilter,
      );
      setState(() {
        _customers = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCustomerActive(Customer customer) async {
    final l10n = context.l10n;
    if (customer.isActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.customerInactivate),
          content: Text(l10n.customerInactivateConfirm(customer.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                l10n.commonConfirm,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await _customerService.deleteCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.customerInactivatedSuccess)),
          );
          _loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
          );
        }
      }
    } else {
      try {
        await _customerService.updateCustomer(customer.id, {'is_active': true});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.customerSavedSuccess)));
          _loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorMapper.toLocalizedMessage(e, l10n))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);

    return ApprovedPage(
      title: l10n.customersTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
          onPressed: _loadCustomers,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        shape: const StadiumBorder(),
        backgroundColor: pColors.accent,
        foregroundColor: pColors.accentInk,
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormView()),
          );
          if (res == true) _loadCustomers();
        },
        tooltip: l10n.customerNew,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '${l10n.commonSearch}...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: pColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: pColors.line),
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _loadCustomers();
                  },
                ),
                const SizedBox(height: 10),
                ResponsiveFilterBar(
                  children: [
                    FilterChip(
                      label: Text(l10n.customerActive),
                      selected: _activeFilter == true,
                      selectedColor: pColors.soft,
                      backgroundColor: pColors.surface,
                      labelStyle: TextStyle(
                        color: _activeFilter == true
                            ? pColors.accent
                            : pColors.ink,
                        fontWeight: _activeFilter == true
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: _activeFilter == true
                              ? pColors.accent
                              : pColors.line,
                        ),
                      ),
                      onSelected: (sel) {
                        setState(() => _activeFilter = sel ? true : null);
                        _loadCustomers();
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.customerInactive),
                      selected: _activeFilter == false,
                      selectedColor: pColors.soft,
                      backgroundColor: pColors.surface,
                      labelStyle: TextStyle(
                        color: _activeFilter == false
                            ? pColors.accent
                            : pColors.ink,
                        fontWeight: _activeFilter == false
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: _activeFilter == false
                              ? pColors.accent
                              : pColors.line,
                        ),
                      ),
                      onSelected: (sel) {
                        setState(() => _activeFilter = sel ? false : null);
                        _loadCustomers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ApprovedSecondaryButton(
                            text: l10n.commonRefresh,
                            onPressed: _loadCustomers,
                          ),
                        ],
                      ),
                    ),
                  )
                : _customers.isEmpty
                ? Center(
                    child: Text(
                      l10n.customersEmpty,
                      style: TextStyle(
                        color: pColors.sub,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: fabScrollPadding(context, top: 0, extended: false),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return _buildCustomerCard(context, customer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final l10n = context.l10n;
    final pColors = AppPalette.of(context);
    final hasDebt = customer.currentDebtCents > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: pColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: pColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: customer.isActive ? pColors.soft : pColors.page,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: pColors.line),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: customer.isActive ? pColors.accent : pColors.sub,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: pColors.ink,
                        ),
                      ),
                      if (customer.documentCpfCnpj != null)
                        Text(
                          customer.documentCpfCnpj!,
                          style: TextStyle(
                            fontSize: 13,
                            color: pColors.sub,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!customer.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pColors.warnFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.customerInactive,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pColors.warn,
                      ),
                    ),
                  ),
              ],
            ),
            Divider(height: 24, color: pColors.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.customerCurrentDebt,
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(customer.currentDebtCents),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: hasDebt ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.customerCreditLimit,
                      style: TextStyle(
                        fontSize: 12,
                        color: pColors.sub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.creditLimitCents > 0
                          ? AppFormatters.formatCurrency(
                              customer.creditLimitCents,
                            )
                          : l10n.customerCreditLimitUnlimited,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: pColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: pColors.line),
                    foregroundColor: pColors.ink,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          CustomerStatementDialog(customer: customer),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(l10n.customerStatement),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.customerEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerFormView(customer: customer),
                      ),
                    );
                    if (res == true) _loadCustomers();
                  },
                ),
                IconButton(
                  tooltip: customer.isActive
                      ? l10n.customerInactivate
                      : l10n.customerActive,
                  icon: Icon(
                    customer.isActive
                        ? Icons.block
                        : Icons.check_circle_outline,
                    size: 20,
                    color: customer.isActive
                        ? Colors.red.shade400
                        : Colors.green.shade600,
                  ),
                  onPressed: () => _toggleCustomerActive(customer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
