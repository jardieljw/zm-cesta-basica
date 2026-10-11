import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';
import 'customer_form_view.dart';
import 'customer_statement_dialog.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final CustomerService _customerService = CustomerService();

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter = true;

  @override
  void initState() {
    super.initState();
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
              child: Text(l10n.commonConfirm, style: const TextStyle(color: Colors.white)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.customerSavedSuccess)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormView()),
          );
          if (res == true) _loadCustomers();
        },
        icon: const Icon(Icons.person_add),
        label: Text(l10n.customerNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '${l10n.commonSearch}...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _loadCustomers();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.customerActive),
                      selected: _activeFilter == true,
                      onSelected: (sel) {
                        setState(() => _activeFilter = sel ? true : null);
                        _loadCustomers();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.customerInactive),
                      selected: _activeFilter == false,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadCustomers,
                              child: Text(l10n.commonRefresh),
                            ),
                          ],
                        ),
                      )
                    : _customers.isEmpty
                        ? Center(
                            child: Text(
                              l10n.customersEmpty,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
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
    final hasDebt = customer.currentDebtCents > 0;

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
                CircleAvatar(
                  backgroundColor: customer.isActive ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: customer.isActive ? Colors.blue.shade800 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (customer.documentCpfCnpj != null)
                        Text(
                          customer.documentCpfCnpj!,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
                if (!customer.isActive)
                  Chip(
                    label: Text(l10n.customerInactive, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey.shade200,
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.customerCurrentDebt, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                    Text(l10n.customerCreditLimit, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(
                      customer.creditLimitCents > 0
                          ? AppFormatters.formatCurrency(customer.creditLimitCents)
                          : l10n.customerCreditLimitUnlimited,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CustomerStatementDialog(customer: customer),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text(l10n.customerStatement),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.customerEdit,
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerFormView(customer: customer)),
                    );
                    if (res == true) _loadCustomers();
                  },
                ),
                IconButton(
                  tooltip: customer.isActive ? l10n.customerInactivate : l10n.customerActive,
                  icon: Icon(
                    customer.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 20,
                    color: customer.isActive ? Colors.red.shade400 : Colors.green.shade600,
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
