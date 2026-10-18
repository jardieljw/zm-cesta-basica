import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../models/account_payable.dart';
import '../services/payable_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/money_input.dart';
import '../widgets/shared/approved_app_style.dart';

class PayableFormDialog extends StatefulWidget {
  final PayableService service;
  const PayableFormDialog({super.key, required this.service});

  @override
  State<PayableFormDialog> createState() => _PayableFormDialogState();
}

class _PayableFormDialogState extends State<PayableFormDialog> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _beneficiary = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  String _category = 'OPERACIONAL';
  String _nature = 'BUSINESS';
  String _method = 'BOLETO';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    _beneficiary.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final cents = MoneyInput.cents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Informe um valor válido maior que zero.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final req = AccountPayableCreate(
        description: _desc.text.trim(),
        beneficiary: _beneficiary.text.trim(),
        category: _category,
        nature: _nature,
        originalAmountCents: cents,
        dueDate: _dueDate,
        paymentMethod: _method,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      final created = await widget.service.createPayable(req);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ApprovedSurface(
          padding: const EdgeInsets.all(22),
          radius: 32,
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nova conta a pagar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cadastre despesas operacionais, aluguel, contas de consumo ou fornecedores.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _desc,
                    enabled: !_saving,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Descrição da despesa',
                      hintText: 'Ex.: Energia elétrica, Internet, Embalagens',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Informe uma descrição'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _beneficiary,
                    enabled: !_saving,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Favorecido / Fornecedor',
                      hintText: 'Ex.: Companhia Elétrica, Fornecedor X',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Informe o favorecido'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amount,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor total',
                      prefixText: 'R\$ ',
                    ),
                    validator: (v) {
                      final c = MoneyInput.cents(v ?? '');
                      return c == null || c <= 0 ? 'Informe um valor válido' : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  ApprovedDateButton(
                    label: 'Vencimento',
                    date: _dueDate,
                    enabled: !_saving,
                    onDateSelected: (d) => setState(() => _dueDate = d),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(
                        value: 'OPERACIONAL',
                        child: Text('Operacional / Despesa Geral'),
                      ),
                      DropdownMenuItem(
                        value: 'FORNECEDOR',
                        child: Text('Fornecedor de Mercadoria'),
                      ),
                      DropdownMenuItem(
                        value: 'ALUGUEL',
                        child: Text('Aluguel / Imóvel'),
                      ),
                      DropdownMenuItem(
                        value: 'IMPOSTOS',
                        child: Text('Impostos / Taxas'),
                      ),
                      DropdownMenuItem(
                        value: 'OUTROS',
                        child: Text('Outros'),
                      ),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _nature,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Natureza da obrigação'),
                    items: const [
                      DropdownMenuItem(
                        value: 'BUSINESS',
                        child: Text('Operacional do negócio'),
                      ),
                      DropdownMenuItem(
                        value: 'PERSONAL_WITHDRAWAL',
                        child: Text('Retirada de sócio / Particular'),
                      ),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _nature = v!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Forma prevista'),
                    items: const [
                      DropdownMenuItem(value: 'BOLETO', child: Text('Boleto Bancário')),
                      DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                      DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferência')),
                      DropdownMenuItem(value: 'CARTAO_CREDITO', child: Text('Cartão de Crédito')),
                      DropdownMenuItem(value: 'DINHEIRO', child: Text('Dinheiro')),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _method = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    enabled: !_saving,
                    maxLength: 200,
                    decoration: InputDecoration(labelText: l.commonNotes),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ApprovedSecondaryButton(
                          text: l.commonCancel,
                          onPressed: _saving ? null : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ApprovedPrimaryButton(
                          text: l.commonSave,
                          busy: _saving,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
