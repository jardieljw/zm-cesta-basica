import 'package:flutter/material.dart';
import '../services/financial_import_service.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';
import 'payables_view.dart';

class FinancialBillReviewView extends StatefulWidget {
  final FinancialImportService service;
  final String statementId;
  final FinancialJson? initialStatement;

  const FinancialBillReviewView({
    super.key,
    required this.service,
    required this.statementId,
    this.initialStatement,
  });

  @override
  State<FinancialBillReviewView> createState() => _FinancialBillReviewViewState();
}

class _FinancialBillReviewViewState extends State<FinancialBillReviewView> {
  bool _busy = false;
  String? _errorMessage;
  FinancialJson? _statement;
  FinancialJson? _review;
  List<FinancialJson> _items = [];
  List<FinancialJson> _obligations = [];
  final Map<String, String> _categorizations = {};
  final Map<String, String> _linkedPurchases = {};
  int _reportedPreviousBalance = 0;

  static const List<Map<String, String>> _categories = [
    {'code': 'PURCHASE_BUSINESS', 'label': 'Compra Empresa'},
    {'code': 'PURCHASE_PERSONAL', 'label': 'Gasto Sócio (Retirada)'},
    {'code': 'BILL_PAYMENT', 'label': 'Pagamento Fatura (-)'},
    {'code': 'PREVIOUS_BALANCE', 'label': 'Saldo Anterior (+)'},
    {'code': 'FINANCIAL_CHARGES', 'label': 'Encargos / Juros (+)'},
    {'code': 'REFUND_CREDIT', 'label': 'Estorno / Crédito (-)'},
    {'code': 'CONTEXT_ONLY', 'label': 'Informativo (Neutro)'},
  ];

  @override
  void initState() {
    super.initState();
    _statement = widget.initialStatement;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final st = _statement ?? await widget.service.get(
        '${FinancialImportService.root}/statements/${widget.statementId}',
      );
      final rawItems = await widget.service.rows(
        '${FinancialImportService.root}/statements/${widget.statementId}/items?limit=500',
      );
      final currentReview = await widget.service.getSemanticReview(widget.statementId);
      final currentObligations = await widget.service.getObligations(widget.statementId);

      int reportedPrevious = 0;
      final previewId = st['preview_id'] as String?;
      if (previewId != null) {
        try {
          final prev = await widget.service.get('${FinancialImportService.root}/previews/$previewId');
          final summary = prev['reported_summary'] as Map? ?? prev['result']?['reported_summary'] as Map?;
          if (summary != null && summary['previous'] != null) {
            reportedPrevious = (summary['previous'] as num).abs().toInt();
          }
        } catch (_) {}
      }

      _categorizations.clear();
      _linkedPurchases.clear();

      if (currentReview != null && currentReview['items'] != null) {
        for (final it in currentReview['items'] as List) {
          final id = it['item_id'] as String;
          _categorizations[id] = it['semantic_category'] as String;
          if (it['purchase_id'] != null) {
            _linkedPurchases[id] = it['purchase_id'] as String;
          }
        }
      } else {
        // Initial smart guess based on raw description keywords and signs
        for (final it in rawItems) {
          final id = it['id'] as String;
          final desc = (it['normalized_data']?['description'] ?? '').toString().toLowerCase();
          final amt = (it['normalized_data']?['amount_cents'] ?? 0) as int;

          if (desc.contains('pagamento') || desc.contains('pgto')) {
            _categorizations[id] = 'BILL_PAYMENT';
          } else if (amt < 0 || desc.contains('estorno') || desc.contains('crédito') || desc.contains('credito')) {
            _categorizations[id] = 'REFUND_CREDIT';
          } else if (desc.contains('juros') || desc.contains('multa') || desc.contains('iof') || desc.contains('anuidade') || desc.contains('tarifa') || desc.contains('saldo em atraso') || desc.contains('encerramento')) {
            _categorizations[id] = 'FINANCIAL_CHARGES';
          } else if (desc.contains('saldo anterior') && reportedPrevious == 0) {
            _categorizations[id] = 'PREVIOUS_BALANCE';
          } else if (desc.contains('retirada') || desc.contains('particular') || desc.contains('socio')) {
            _categorizations[id] = 'PURCHASE_PERSONAL';
          } else {
            _categorizations[id] = 'PURCHASE_BUSINESS';
          }
        }
      }

      if (mounted) {
        setState(() {
          _statement = st;
          _items = rawItems;
          _review = currentReview;
          _obligations = currentObligations;
          _reportedPreviousBalance = reportedPrevious;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _busy = false;
        });
      }
    }
  }

  int get _declaredTotal => (_statement?['total_amount_cents'] as int?) ?? 0;

  int _computeSum(String category) {
    var total = 0;
    for (final it in _items) {
      final id = it['id'] as String;
      if (_categorizations[id] == category) {
        final amt = (it['normalized_data']?['amount_cents'] as int?) ?? 0;
        total += amt;
      }
    }
    return total;
  }

  int get _previousBalance {
    final fromItems = _computeSum('PREVIOUS_BALANCE');
    if (fromItems == 0 && _reportedPreviousBalance > 0) {
      return _reportedPreviousBalance;
    }
    return fromItems;
  }
  int get _purchasesBusiness => _computeSum('PURCHASE_BUSINESS');
  int get _purchasesPersonal => _computeSum('PURCHASE_PERSONAL');
  int get _financialCharges => _computeSum('FINANCIAL_CHARGES');
  int get _payments => _computeSum('BILL_PAYMENT').abs();
  int get _refunds => _computeSum('REFUND_CREDIT').abs();

  int get _calculatedTotal =>
      _previousBalance +
      _purchasesBusiness +
      _purchasesPersonal +
      _financialCharges -
      _payments -
      _refunds;

  int get _difference => _declaredTotal - _calculatedTotal;
  bool get _isBalanced => _difference == 0 || _difference.abs() <= 10;

  Future<void> _saveReview() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final reviewItems = _items.map((it) {
        final id = it['id'] as String;
        return {
          'item_id': id,
          'semantic_category': _categorizations[id] ?? 'PURCHASE_BUSINESS',
          if (_linkedPurchases[id] != null) 'purchase_id': _linkedPurchases[id],
        };
      }).toList();

      final res = await widget.service.saveSemanticReview(
        widget.statementId,
        expectedRevision: (_review?['revision'] as int?) ?? 0,
        items: reviewItems,
        notes: 'Revisão conferida pelo operador',
      );

      final updatedReview = res.containsKey('review') ? res['review'] : res;
      if (mounted) {
        setState(() {
          _review = Map<String, dynamic>.from(updatedReview as Map);
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBalanced
                  ? 'Revisão semântica salva e APROVADA!'
                  : 'Revisão semântica salva como RASCUNHO (equação não balanceada).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _generateObligations() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      if (_review == null || _review!['id'] == null) {
        final reviewItems = _items.map((it) {
          final id = it['id'] as String;
          return {
            'item_id': id,
            'semantic_category': _categorizations[id] ?? 'PURCHASE_BUSINESS',
            if (_linkedPurchases[id] != null) 'purchase_id': _linkedPurchases[id],
          };
        }).toList();

        final res = await widget.service.saveSemanticReview(
          widget.statementId,
          expectedRevision: (_review?['revision'] as int?) ?? 0,
          items: reviewItems,
          notes: 'Revisão conferida pelo operador',
        );
        final updatedReview = res.containsKey('review') ? res['review'] : res;
        _review = Map<String, dynamic>.from(updatedReview as Map);
      }

      final obligations = await widget.service.generateObligations(
        widget.statementId,
        reviewId: _review?['id'] as String?,
      );
      if (mounted) {
        setState(() {
          _obligations = obligations;
          _busy = false;
        });
        final pal = AppPalette.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${obligations.length} obrigações geradas com sucesso em Contas a Pagar!',
            ),
            backgroundColor: pal.accent,
            action: SnackBarAction(
              label: 'Abrir Contas a Pagar',
              textColor: pal.accentInk,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PayablesView()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Scaffold(
      backgroundColor: pal.page,
      appBar: AppBar(
        backgroundColor: pal.page,
        foregroundColor: pal.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Revisão Semântica da Fatura',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: pal.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: pal.warn),
              ),
            ),
          _buildStatementSummaryCard(),
          const SizedBox(height: 16),
          _buildEquationCard(),
          const SizedBox(height: 16),
          if (_obligations.isEmpty && _isBalanced) ...[
            ApprovedSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: pal.accent, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Equação balanceada! Pronto para lançar.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pal.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clique no botão abaixo para gerar automaticamente todas as parcelas e compras em Contas a Pagar.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('top-generate-obligations-btn'),
                    onPressed: _busy ? null : _generateObligations,
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: const Text('Lançar em Contas a Pagar Agora'),
                    style: FilledButton.styleFrom(
                      backgroundColor: pal.accent,
                      foregroundColor: pal.accentInk,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_obligations.isNotEmpty) ...[
            _buildObligationsCard(),
            const SizedBox(height: 16),
          ],
          ApprovedSectionHeader('Classificação Linha a Linha (${_items.length} itens)'),
          const SizedBox(height: 8),
          ..._items.map(_buildItemCard),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('save-semantic-review-button'),
                  onPressed: _busy ? null : _saveReview,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar Classificação'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: pal.ink,
                    side: BorderSide(color: pal.line),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('generate-obligations-button'),
                  onPressed: _busy || !_isBalanced ? null : _generateObligations,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Gerar Obrigações a Pagar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: pal.accent,
                    foregroundColor: pal.accentInk,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatementSummaryCard() {
    final due = _statement?['due_on'] != null
        ? AppFormatters.formatDate(DateTime.parse(_statement!['due_on'] as String))
        : 'Não informada';
    return ApprovedSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fatura de Cartão de Crédito',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Vencimento: $due'),
          Text('Total Declarado: ${AppFormatters.formatCurrency(_declaredTotal)}'),
          if (_review != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Revisão Atual: #${_review!['revision']} (${_review!['status']})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEquationCard() {
    final pal = AppPalette.of(context);
    final isExact = _difference == 0;
    final isTolerated = !isExact && _difference.abs() <= 10;
    final isOk = _isBalanced;
    final color = isOk ? pal.accent : pal.warn;
    final statusText = isExact
        ? 'BALANCEADA (0 diff)'
        : isTolerated
            ? 'BALANCEADA (arredondamento: ${AppFormatters.formatCurrency(_difference)})'
            : 'DIFERENÇA: ${AppFormatters.formatCurrency(_difference)}';

    return ApprovedSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Equação de Fechamento da Fatura',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Chip(
                backgroundColor: isOk ? pal.soft : pal.warnFill,
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                avatar: Icon(
                  isOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: color,
                  size: 18,
                ),
                label: Text(
                  statusText,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (isTolerated)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Pequena diferença de centavos do resumo do banco é absorvida automaticamente em Encargos Financeiros ao aprovar.',
                style: TextStyle(fontSize: 12, color: pal.sub),
              ),
            ),
          const Divider(),
          _equationRow('Saldo Anterior (+)', _previousBalance),
          _equationRow('Compras Operacionais Empresa (+)', _purchasesBusiness),
          _equationRow('Compras Pessoais Sócio (+)', _purchasesPersonal),
          _equationRow('Encargos e Juros (+)', _financialCharges),
          _equationRow('Pagamentos Fatura (-)', -_payments),
          _equationRow('Estornos e Créditos (-)', -_refunds),
          const Divider(),
          _equationRow('Total Calculado', _calculatedTotal, bold: true),
          _equationRow('Total Declarado', _declaredTotal, bold: true),
        ],
      ),
    );
  }

  Widget _equationRow(String label, int amountCents, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(AppFormatters.formatCurrency(amountCents), style: style),
        ],
      ),
    );
  }

  Widget _buildObligationsCard() {
    final pal = AppPalette.of(context);
    return ApprovedSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Obrigações Geradas em Contas a Pagar (${_obligations.length} títulos)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: pal.accent),
          ),
          const SizedBox(height: 8),
          ..._obligations.map((ob) {
            final num = ob['payable_number'] != null ? '#${ob['payable_number']}' : '';
            final desc = ob['description'] ?? 'Obrigação';
            final amt = ob['amount_cents'] as int? ?? 0;
            final nature = ob['nature'] ?? 'BUSINESS';
            final status = ob['status'] ?? 'OPEN';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$num $desc [$nature · $status]',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(amt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('open-payables-from-review-button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PayablesView()),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Abrir em Contas a Pagar'),
            style: FilledButton.styleFrom(
              backgroundColor: pal.soft,
              foregroundColor: pal.accent,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(FinancialJson item) {
    final pal = AppPalette.of(context);
    final id = item['id'] as String;
    final data = item['normalized_data'] as Map? ?? {};
    final desc = data['description']?.toString() ?? '';
    final date = data['transaction_date']?.toString() ?? '';
    final amt = (data['amount_cents'] as int?) ?? 0;
    final currentCat = _categorizations[id] ?? 'PURCHASE_BUSINESS';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApprovedSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    desc,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(amt),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: amt < 0 ? pal.accent : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('category-dropdown-$id'),
              initialValue: currentCat,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Categoria Semântica',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c['code'],
                  child: Text(c['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _categorizations[id] = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
