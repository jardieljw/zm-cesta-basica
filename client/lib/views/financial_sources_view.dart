import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';

class FinancialSourcesView extends StatefulWidget {
  final ApiClient? apiClient;
  final FinancialImportService? service;

  const FinancialSourcesView({
    super.key,
    this.apiClient,
    this.service,
  });

  @override
  State<FinancialSourcesView> createState() => _FinancialSourcesViewState();
}

class _FinancialSourcesViewState extends State<FinancialSourcesView> {
  late final FinancialImportService _service;
  List<FinancialJson> _sources = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ?? FinancialImportService(apiClient: widget.apiClient);
    _load();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.sources();
      if (!mounted) return;
      setState(() {
        _sources = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _loading = false;
      });
    }
  }

  Future<void> _addSource() async {
    final result = await showDialog<FinancialJson>(
      context: context,
      builder: (dialogCtx) => _NewFinancialSourceDialog(service: _service),
    );
    if (result != null && mounted) {
      _load();
    }
  }

  void _showDetails(FinancialJson s) {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ApprovedSurface(
            padding: const EdgeInsets.all(22),
            radius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      s['source_type'] == 'CREDIT_CARD'
                          ? Icons.credit_card_outlined
                          : Icons.account_balance_outlined,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s['name'] as String? ?? 'Fonte financeira',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ApprovedRow(
                  compact: true,
                  title: 'Instituição emissora',
                  subtitle: s['institution'] as String? ?? '—',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 8),
                ApprovedRow(
                  compact: true,
                  title: 'Tipo de fonte',
                  subtitle: s['source_type'] == 'CREDIT_CARD'
                      ? l.pdfImportCard
                      : l.pdfImportBank,
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 8),
                ApprovedRow(
                  compact: true,
                  title: 'Titularidade',
                  subtitle: s['holder_type'] == 'PJ'
                      ? l.pdfImportPJ
                      : l.pdfImportPF,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 8),
                ApprovedRow(
                  compact: true,
                  title: 'Moeda corrente',
                  subtitle: s['currency'] as String? ?? 'BRL',
                  icon: Icons.attach_money,
                ),
                if (s['current_balance_cents'] != null) ...[
                  const SizedBox(height: 8),
                  ApprovedRow(
                    compact: true,
                    title: 'Saldo atual na Tesouraria',
                    subtitle: AppFormatters.formatCurrency(s['current_balance_cents'] as int),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
                const SizedBox(height: 20),
                ApprovedSecondaryButton(
                  text: l.commonClose,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = AppPalette.of(context);

    return ApprovedPage(
      title: l.appAccountsCards,
      actions: [
        IconButton(
          tooltip: l.commonRefresh,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _addSource,
        icon: const Icon(Icons.add),
        label: Text(l.pdfImportNewSource),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ApprovedSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Fontes financeiras registradas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contas bancárias e cartões de crédito configurados para importação de extratos e conciliação.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  ApprovedSurface(
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _load,
                          child: Text(l.commonRefresh),
                        ),
                      ],
                    ),
                  )
                else if (_sources.isEmpty)
                  ApprovedSurface(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 48,
                              color: p.sub,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.pdfImportNoSources,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ApprovedPrimaryButton(
                              text: l.pdfImportNewSource,
                              icon: Icons.add,
                              onPressed: _addSource,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  for (final s in _sources) ...[
                    () {
                      final hasBalance = s['source_type'] != 'CREDIT_CARD' &&
                          s['current_balance_cents'] != null;
                      final balanceText = hasBalance
                          ? ' · Saldo: ${AppFormatters.formatCurrency(s['current_balance_cents'] as int)}'
                          : '';
                      return ApprovedRow(
                        title: s['name'] as String? ?? 'Conta / Cartão',
                        subtitle:
                            '${s['institution'] ?? 'Instituição'} · ${s['holder_type'] == 'PJ' ? l.pdfImportPJ : l.pdfImportPF} · ${s['source_type'] == 'CREDIT_CARD' ? l.pdfImportCard : l.pdfImportBank}$balanceText',
                        icon: s['source_type'] == 'CREDIT_CARD'
                            ? Icons.credit_card_outlined
                            : Icons.account_balance_outlined,
                        onTap: () => _showDetails(s),
                      );
                    }(),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewFinancialSourceDialog extends StatefulWidget {
  final FinancialImportService service;
  const _NewFinancialSourceDialog({required this.service});

  @override
  State<_NewFinancialSourceDialog> createState() =>
      _NewFinancialSourceDialogState();
}

class _NewFinancialSourceDialogState extends State<_NewFinancialSourceDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _institution = TextEditingController();
  String _type = 'BANK_ACCOUNT';
  String _holder = 'PJ';
  String _account = '';
  List<FinancialJson> _banks = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await widget.service.bankAccounts();
      final sources = await widget.service.sources();
      if (!mounted) return;
      setState(() {
        _banks = banks
            .where((b) =>
                !sources.any((s) => s['financial_account_id'] == b['id']))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.service.createSource(
        name: _name.text.trim(),
        institution: _institution.text.trim(),
        sourceType: _type,
        holderType: _holder,
        accountId: _type == 'BANK_ACCOUNT' && _account.isNotEmpty
            ? _account
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop(created);
      }
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                    l.pdfImportNewSource,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.pdfImportSource),
                    items: [
                      DropdownMenuItem(
                        value: 'BANK_ACCOUNT',
                        child: Text(l.pdfImportBank),
                      ),
                      DropdownMenuItem(
                        value: 'CREDIT_CARD',
                        child: Text(l.pdfImportCard),
                      ),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l.pdfImportSourceName,
                      hintText: 'Ex.: Conta Principal, Cartão Nubank PJ',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? l.pdfImportRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _institution,
                    enabled: !_saving,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l.pdfImportInstitution,
                      hintText: 'Ex.: Nubank, Itaú, Bradesco',
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? l.pdfImportRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _holder,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.pdfImportHolder),
                    items: [
                      DropdownMenuItem(value: 'PJ', child: Text(l.pdfImportPJ)),
                      DropdownMenuItem(value: 'PF', child: Text(l.pdfImportPF)),
                    ],
                    onChanged:
                        _saving ? null : (v) => setState(() => _holder = v!),
                  ),
                  if (_type == 'BANK_ACCOUNT') ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _account,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.pdfImportBankLink,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l.pdfImportNewBank),
                        ),
                        ..._banks.map(
                          (b) => DropdownMenuItem(
                            value: b['id'] as String,
                            child: Text(b['name'] as String),
                          ),
                        ),
                      ],
                      onChanged:
                          _saving ? null : (v) => setState(() => _account = v!),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ApprovedSecondaryButton(
                          text: l.commonCancel,
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
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
