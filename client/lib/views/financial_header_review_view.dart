import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../utils/formatters.dart';
import '../utils/money_input.dart';
import '../widgets/shared/approved_app_style.dart';

/// Explicit operator transcription. Nothing is initialized from transaction sums
/// or from today's date; the date picker's initial focus is not a saved value.
class FinancialHeaderReviewView extends StatefulWidget {
  final bool isCard;
  final Map<String, dynamic> extractedHeader;
  const FinancialHeaderReviewView({
    super.key,
    required this.isCard,
    this.extractedHeader = const {},
  });
  @override
  State<FinancialHeaderReviewView> createState() =>
      _FinancialHeaderReviewViewState();
}

class _FinancialHeaderReviewViewState extends State<FinancialHeaderReviewView> {
  final form = GlobalKey<FormState>();
  final dates = <String, DateTime>{};
  final money = <String, TextEditingController>{};
  bool acknowledged = false;
  @override
  void initState() {
    super.initState();
    for (final field in ['due_on', 'period_start', 'period_end']) {
      final value = widget.extractedHeader[field];
      if (value is String) dates[field] = DateTime.parse(value);
    }
    for (final field in [
      'total_amount_cents',
      'minimum_payment_cents',
      'opening_balance_cents',
      'closing_balance_cents',
      'total_inflows_cents',
      'total_outflows_cents',
    ]) {
      final value = widget.extractedHeader[field];
      if (value is int) {
        final absolute = value.abs();
        money[field] = TextEditingController(
          text:
              '${value < 0 ? '-' : ''}${absolute ~/ 100},${(absolute % 100).toString().padLeft(2, '0')}',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in money.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _amount(String text) {
    final negative = text.trim().startsWith('-');
    final value = MoneyInput.cents(negative ? text.trim().substring(1) : text);
    return value != null && value <= 9000000000000000
        ? (negative ? -value : value)
        : null;
  }

  Widget _date(String field, String label) => FormField<DateTime>(
    validator: (_) =>
        dates[field] == null ? context.l10n.importHeaderDateRequired : null,
    builder: (state) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            key: ValueKey('import-header-$field'),
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: dates[field] ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (chosen != null && mounted) {
                setState(() {
                  dates[field] = chosen;
                  state.didChange(chosen);
                });
              }
            },
            child: Text(
              '$label${dates[field] == null ? '' : ' · ${AppFormatters.formatDate(dates[field]!)}'}',
            ),
          ),
          if (state.hasError)
            Text(
              state.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
  Widget _money(
    String field,
    String label, {
    bool required = false,
    bool signed = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('import-header-$field'),
      controller: money.putIfAbsent(field, TextEditingController.new),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorMaxLines: 3,
        helperText: required
            ? context.l10n.importHeaderSignedMoney
            : context.l10n.importOptional,
        helperMaxLines: 4,
      ),
      validator: (v) {
        if (!required && (v ?? '').trim().isEmpty) return null;
        final value = _amount(v ?? '');
        return value == null || (!signed && value < 0)
            ? context.l10n.importHeaderMoneyRequired
            : null;
      },
    ),
  );
  void _submit() {
    if (!acknowledged || !form.currentState!.validate()) return;
    if (!widget.isCard &&
        dates['period_end']!.isBefore(dates['period_start']!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.importHeaderPeriodInvalid)),
      );
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'statement_type': widget.isCard ? 'CARD_BILL' : 'BANK_STATEMENT',
      for (final e in dates.entries)
        e.key: e.value.toIso8601String().substring(0, 10),
      for (final e in money.entries)
        if (e.value.text.trim().isNotEmpty) e.key: _amount(e.value.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ApprovedPage(
      title: l.importHeaderTitle,
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ApprovedSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.importHeaderHelp),
                  const SizedBox(height: 20),
                  if (widget.isCard) ...[
                    _date('due_on', l.pdfImportDue),
                    _money(
                      'total_amount_cents',
                      l.pdfImportTotal,
                      required: true,
                      signed: true,
                    ),
                    _money('minimum_payment_cents', l.pdfImportMinimum),
                  ] else ...[
                    _date('period_start', l.pdfImportPeriodStart),
                    _date('period_end', l.pdfImportPeriodEnd),
                    _money(
                      'opening_balance_cents',
                      l.pdfImportOpeningBalance,
                      signed: true,
                    ),
                    _money(
                      'closing_balance_cents',
                      l.pdfImportClosingBalance,
                      signed: true,
                    ),
                    _money('total_inflows_cents', l.pdfImportInflows),
                    _money('total_outflows_cents', l.pdfImportOutflows),
                  ],
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledged,
                    onChanged: (v) => setState(() => acknowledged = v!),
                    title: Text(l.importHeaderAck),
                  ),
                  const SizedBox(height: 16),
                  ApprovedPrimaryButton(
                    text: l.importHeaderContinue,
                    icon: Icons.check,
                    onPressed: acknowledged ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
