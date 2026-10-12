import 'package:flutter/material.dart';
import '../models/financial_account.dart';
import '../models/cash_flow_entry.dart';
import '../services/treasury_service.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/api_error_mapper.dart';

class TreasuryView extends StatefulWidget {
  const TreasuryView({super.key});

  @override
  State<TreasuryView> createState() => _TreasuryViewState();
}

class _TreasuryViewState extends State<TreasuryView> with SingleTickerProviderStateMixin {
  final TreasuryService _treasuryService = TreasuryService();
  late TabController _tabController;

  TreasurySummary? _summary;
  List<FinancialAccount> _accounts = [];
  List<CashFlowEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Ledger filters
  String? _selectedAccountId;
  String? _selectedEntryType;
  String? _selectedNature;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _treasuryService.getSummary();
      final accounts = await _treasuryService.getAccounts();
      final entries = await _treasuryService.getEntries(
        accountId: _selectedAccountId,
        entryType: _selectedEntryType,
        nature: _selectedNature,
        category: _selectedCategory,
      );

      setState(() {
        _summary = summary;
        _accounts = accounts;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  int _parseToCents(String text) {
    final cleaned = text.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.').trim();
    final val = double.tryParse(cleaned) ?? 0.0;
    return (val * 100).round();
  }

  // ==================== ACCOUNT DIALOGS ====================

  Future<void> _showCreateAccountDialog() async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final bankNameController = TextEditingController();
    final accNumController = TextEditingController();
    final initialBalController = TextEditingController(text: '0,00');
    final notesController = TextEditingController();
    String accountType = 'BANK';
    bool isDefault = false;
    bool isSaving = false;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.treasuryNewAccount),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (formError != null) ...[
                        Text(formError!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.treasuryAccountName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: accountType,
                        decoration: InputDecoration(
                          labelText: l10n.treasuryAccountType,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'CASH', child: Text(l10n.treasuryTypeCash)),
                          DropdownMenuItem(value: 'BANK', child: Text(l10n.treasuryTypeBank)),
                          DropdownMenuItem(value: 'OTHER', child: Text(l10n.treasuryTypeOther)),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => accountType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (accountType == 'BANK') ...[
                        TextField(
                          controller: bankNameController,
                          decoration: InputDecoration(
                            labelText: l10n.treasuryBankName,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: accNumController,
                          decoration: InputDecoration(
                            labelText: l10n.treasuryAccountNumber,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: initialBalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.treasuryInitialBalance,
                          prefixText: 'R\$ ',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.treasuryIsDefault),
                        value: isDefault,
                        onChanged: (val) => setDialogState(() => isDefault = val ?? false),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: l10n.commonNotes,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() => formError = 'Informe o nome da conta.');
                            return;
                          }
                          final cents = _parseToCents(initialBalController.text);

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });

                          try {
                            await _treasuryService.createAccount(
                              FinancialAccountCreate(
                                name: nameController.text.trim(),
                                accountType: accountType,
                                bankName: bankNameController.text.trim().isNotEmpty ? bankNameController.text.trim() : null,
                                accountNumber: accNumController.text.trim().isNotEmpty ? accNumController.text.trim() : null,
                                initialBalanceCents: cents,
                                isDefault: isDefault,
                                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                              ),
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.commonSuccess)),
                              );
                              _loadAll();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              formError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== TRANSFER DIALOG ====================

  Future<void> _showTransferDialog() async {
    final l10n = context.l10n;
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('São necessárias ao menos 2 contas para realizar transferências.')),
      );
      return;
    }

    String sourceAccountId = _accounts.first.id;
    String destinationAccountId = _accounts[1].id;
    final amountController = TextEditingController();
    final descController = TextEditingController(text: 'Transferência entre contas');
    bool isSaving = false;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.treasuryTransferTitle),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (formError != null) ...[
                      Text(formError!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: sourceAccountId,
                      decoration: InputDecoration(
                        labelText: l10n.treasurySourceAccount,
                        border: const OutlineInputBorder(),
                      ),
                      items: _accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} (${AppFormatters.formatCurrency(a.currentBalanceCents)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => sourceAccountId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: destinationAccountId,
                      decoration: InputDecoration(
                        labelText: l10n.treasuryDestinationAccount,
                        border: const OutlineInputBorder(),
                      ),
                      items: _accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} (${AppFormatters.formatCurrency(a.currentBalanceCents)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => destinationAccountId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.treasuryTransferAmount,
                        prefixText: 'R\$ ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: l10n.payableDescription,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (sourceAccountId == destinationAccountId) {
                            setDialogState(() => formError = 'A conta de origem e destino devem ser diferentes.');
                            return;
                          }
                          final cents = _parseToCents(amountController.text);
                          if (cents <= 0) {
                            setDialogState(() => formError = 'O valor da transferência deve ser maior que zero.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });

                          try {
                            await _treasuryService.createTransfer(
                              FinancialTransferCreate(
                                sourceAccountId: sourceAccountId,
                                destinationAccountId: destinationAccountId,
                                amountCents: cents,
                                description: descController.text.trim(),
                              ),
                            );

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.treasuryTransferSuccess)),
                              );
                              _loadAll();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              formError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.commonConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== MANUAL ENTRY DIALOG ====================

  Future<void> _showManualEntryDialog() async {
    final l10n = context.l10n;
    if (_accounts.isEmpty) return;

    String selectedAccountId = _accounts.first.id;
    String entryType = 'CREDIT';
    String category = 'APORTE';
    String nature = 'BUSINESS';
    String paymentMethod = 'PIX';
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final notesController = TextEditingController();
    bool isSaving = false;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.treasuryManualEntryTitle),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (formError != null) ...[
                        Text(formError!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Conta Financeira',
                          border: OutlineInputBorder(),
                        ),
                        items: _accounts.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${AppFormatters.formatCurrency(a.currentBalanceCents)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedAccountId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: entryType,
                              decoration: InputDecoration(
                                labelText: l10n.treasuryEntryType,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: 'CREDIT', child: Text(l10n.treasuryEntryCredit, style: const TextStyle(color: Colors.green))),
                                DropdownMenuItem(value: 'DEBIT', child: Text(l10n.treasuryEntryDebit, style: const TextStyle(color: Colors.red))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    entryType = val;
                                    category = val == 'CREDIT' ? 'APORTE' : 'OUTROS';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: nature,
                              decoration: InputDecoration(
                                labelText: l10n.payableNature,
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: 'BUSINESS', child: Text(l10n.payableNatureBusiness)),
                                DropdownMenuItem(value: 'PERSONAL_WITHDRAWAL', child: Text(l10n.payableNaturePersonal)),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => nature = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('cat_$entryType'),
                        initialValue: category,
                        decoration: InputDecoration(
                          labelText: l10n.treasuryEntryCategory,
                          border: const OutlineInputBorder(),
                        ),
                        items: entryType == 'CREDIT'
                            ? const [
                                DropdownMenuItem(value: 'APORTE', child: Text('Aporte de Capital')),
                                DropdownMenuItem(value: 'VENDAS', child: Text('Receita de Vendas')),
                                DropdownMenuItem(value: 'RECEBIMENTO_CLIENTE', child: Text('Recebimento de Cliente')),
                                DropdownMenuItem(value: 'OUTROS', child: Text('Outros Créditos')),
                              ]
                            : const [
                                DropdownMenuItem(value: 'RETIRADA_SOCIO', child: Text('Retirada de Sócios / Pró-labore')),
                                DropdownMenuItem(value: 'FORNECEDOR', child: Text('Pagamento Fornecedor')),
                                DropdownMenuItem(value: 'ENERGIA', child: Text('Energia Elétrica')),
                                DropdownMenuItem(value: 'ALUGUEL', child: Text('Aluguel')),
                                DropdownMenuItem(value: 'FRETE', child: Text('Frete / Combustível')),
                                DropdownMenuItem(value: 'MANUTENCAO', child: Text('Manutenção')),
                                DropdownMenuItem(value: 'OUTROS', child: Text('Outras Despesas')),
                              ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: l10n.treasuryEntryAmount,
                                prefixText: 'R\$ ',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentMethod,
                              decoration: InputDecoration(
                                labelText: l10n.payablePaymentMethod,
                                border: const OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                                DropdownMenuItem(value: 'CASH', child: Text('Dinheiro')),
                                DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Transferência')),
                                DropdownMenuItem(value: 'CARD', child: Text('Cartão')),
                                DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => paymentMethod = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: l10n.treasuryEntryDescription,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: l10n.commonNotes,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (descController.text.trim().isEmpty) {
                            setDialogState(() => formError = 'Informe a descrição do lançamento.');
                            return;
                          }
                          final cents = _parseToCents(amountController.text);
                          if (cents <= 0) {
                            setDialogState(() => formError = 'O valor deve ser maior que zero.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });

                          try {
                            await _treasuryService.createEntry(
                              CashFlowEntryCreate(
                                accountId: selectedAccountId,
                                entryType: entryType,
                                amountCents: cents,
                                category: category,
                                nature: nature,
                                description: descController.text.trim(),
                                paymentMethod: paymentMethod,
                                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                              ),
                            );

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.treasuryEntrySuccess)),
                              );
                              _loadAll();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              formError = ApiErrorMapper.toLocalizedMessage(e, l10n);
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== TAB BUILDERS ====================

  Widget _buildAccountsTab() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.treasuryTransferTitle),
                onPressed: _showTransferDialog,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.treasuryNewAccount),
                onPressed: _showCreateAccountDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_accounts.isEmpty)
            Center(child: Text(l10n.treasuryNoAccounts))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = _accounts[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: a.accountType == 'CASH'
                              ? Colors.green.shade100
                              : a.accountType == 'BANK'
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                          child: Icon(
                            a.accountType == 'CASH'
                                ? Icons.payments
                                : a.accountType == 'BANK'
                                    ? Icons.account_balance
                                    : Icons.savings,
                            color: a.accountType == 'CASH'
                                ? Colors.green.shade800
                                : a.accountType == 'BANK'
                                    ? Colors.blue.shade800
                                    : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (a.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l10n.treasuryIsDefault,
                                        style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (a.bankName != null || a.accountNumber != null)
                                Text(
                                  '${a.bankName ?? ''}${a.accountNumber != null ? ' - ${a.accountNumber}' : ''}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              Text(
                                'Saldo Inicial: ${AppFormatters.formatCurrency(a.initialBalanceCents)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(a.currentBalanceCents),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: a.currentBalanceCents >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.accountType == 'CASH' ? l10n.treasuryTypeCash : l10n.treasuryTypeBank,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab() {
    final l10n = context.l10n;
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Conta',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                    ..._accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedAccountId = val);
                    _loadAll();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedEntryType,
                  decoration: InputDecoration(
                    labelText: l10n.treasuryEntryType,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                    DropdownMenuItem(value: 'CREDIT', child: Text(l10n.treasuryEntryCredit)),
                    DropdownMenuItem(value: 'DEBIT', child: Text(l10n.treasuryEntryDebit)),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedEntryType = val);
                    _loadAll();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedNature,
                  decoration: InputDecoration(
                    labelText: l10n.payableNature,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                    DropdownMenuItem(value: 'BUSINESS', child: Text(l10n.payableNatureBusiness)),
                    DropdownMenuItem(value: 'PERSONAL_WITHDRAWAL', child: Text(l10n.payableNaturePersonal)),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedNature = val);
                    _loadAll();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Lançamento'),
                onPressed: _showManualEntryDialog,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.treasuryImmutableNote,
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? Center(child: Text(l10n.treasuryNoEntries))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = _entries[index];
                    final isCredit = e.entryType == 'CREDIT';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.description,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (e.isReversal)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text(l10n.treasuryReversalBadge, style: TextStyle(fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppFormatters.formatDateTime(e.occurredAt)} • ${e.accountName ?? 'Conta'} • ${e.category} • ${e.paymentMethod}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          if (e.nature == 'PERSONAL_WITHDRAWAL')
                            Text(
                              l10n.payableNaturePersonal,
                              style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold),
                            ),
                          if (e.notes != null)
                            Text('Obs: ${e.notes}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                      trailing: Text(
                        '${isCredit ? '+' : '-'} ${AppFormatters.formatCurrency(e.amountCents)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isCredit ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    final l10n = context.l10n;
    if (_summary == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Saldo Disponível vs Compromissos Futuros
          Text('Posição Consolidada da Empresa', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryTotalAvailable, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.formatCurrency(_summary!.totalAvailableCents),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text('Caixa Físico: ${AppFormatters.formatCurrency(_summary!.cashBalanceCents)}', style: const TextStyle(fontSize: 12)),
                        Text('Bancos: ${AppFormatters.formatCurrency(_summary!.bankBalanceCents)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryProjectedNet, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.formatCurrency(_summary!.projectedNetCents),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _summary!.projectedNetCents >= 0 ? Colors.indigo.shade800 : Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Fórmula: Disponível + A Receber - A Pagar', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Section 2: Compromissos Futuros
          Text('Compromissos Futuros & Fiados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryOpenReceivables, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(_summary!.openReceivablesCents),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vencidos: ${AppFormatters.formatCurrency(_summary!.overdueReceivablesCents)}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryOpenPayables, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(_summary!.openPayablesCents),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vencidos: ${AppFormatters.formatCurrency(_summary!.overduePayablesCents)}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryRouteCashPending, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(_summary!.routeCashPendingCents),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        const SizedBox(height: 4),
                        const Text('Em custódia de entregadores', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Section 3: Segregação Operacional vs Particular
          Text('Segregação de Despesas (Mês)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryBusinessExpenses, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(_summary!.periodBusinessExpensesCents),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 4),
                        const Text('Gastos operacionais da atividade', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.purple.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.treasuryPersonalWithdrawals, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(_summary!.periodPersonalWithdrawalsCents),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                        ),
                        const SizedBox(height: 4),
                        const Text('Não misturar com contas da empresa', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treasuryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.treasuryTabAccounts, icon: const Icon(Icons.account_balance)),
            Tab(text: l10n.treasuryTabLedger, icon: const Icon(Icons.receipt_long)),
            Tab(text: l10n.treasuryTabSummary, icon: const Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadAll, child: Text(l10n.commonRefresh)),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAccountsTab(),
                    _buildLedgerTab(),
                    _buildSummaryTab(),
                  ],
                ),
    );
  }
}
