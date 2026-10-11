import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/api_error_mapper.dart';

class CustomerFormView extends StatefulWidget {
  final Customer? customer;

  const CustomerFormView({super.key, this.customer});

  @override
  State<CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends State<CustomerFormView> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  late TextEditingController _nameController;
  late TextEditingController _documentController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _documentController = TextEditingController(text: c?.documentCpfCnpj ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    final initialLimit = c != null ? (c.creditLimitCents / 100.0).toStringAsFixed(2).replaceAll('.', ',') : '0,00';
    _creditLimitController = TextEditingController(text: initialLimit);
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseCurrencyToCents(String text) {
    final cleaned = text.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.').trim();
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * 100).round();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final document = _documentController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final creditLimitCents = _parseCurrencyToCents(_creditLimitController.text);
    final notes = _notesController.text.trim();

    final payload = <String, dynamic>{
      'name': name,
      'document_cpf_cnpj': document.isNotEmpty ? document : null,
      'phone': phone.isNotEmpty ? phone : null,
      'address': address.isNotEmpty ? address : null,
      'credit_limit_cents': creditLimitCents,
      'notes': notes.isNotEmpty ? notes : null,
    };

    try {
      if (widget.customer == null) {
        await _customerService.createCustomer(payload);
      } else {
        await _customerService.updateCustomer(widget.customer!.id, payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.customerSavedSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.customerEdit : l10n.customerNew),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.customerName} *',
                  hintText: l10n.customerNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return l10n.commonRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentController,
                decoration: InputDecoration(
                  labelText: l10n.customerDocument,
                  hintText: l10n.customerDocumentHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.customerPhone,
                        hintText: l10n.customerPhoneHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _creditLimitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.customerCreditLimit,
                        helperText: l10n.customerCreditLimitUnlimited,
                        prefixText: 'R\$ ',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.customerAddress,
                  hintText: l10n.customerAddressHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.commonNotes,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCustomer,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(l10n.commonSave),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
