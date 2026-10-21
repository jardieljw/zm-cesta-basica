import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../widgets/shared/approved_app_style.dart';
import 'financial_bill_integration_view.dart';

/// Each chosen segment has its own durable, reproducible command and result.
class FinancialSegmentsView extends StatefulWidget {
  final FinancialImportService service;
  final FinancialJson preview;
  const FinancialSegmentsView({
    super.key,
    required this.service,
    required this.preview,
  });
  @override
  State<FinancialSegmentsView> createState() => _FinancialSegmentsViewState();
}

class _FinancialSegmentsViewState extends State<FinancialSegmentsView> {
  List<FinancialJson> sources = [];
  final choices = <String, String>{};
  final saved = <String>{};
  bool busy = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.service.sources();
      if (mounted) {
        setState(() {
          sources = value;
          String bank(String value) {
            final text = value
                .toUpperCase()
                .replaceAll('NU EMPRESAS', 'NUBANK')
                .replaceAll('NU PAGAMENTOS', 'NUBANK')
                .replaceAll('MERCADOPAGO', 'MERCADO PAGO');
            return [
                  'NUBANK',
                  'SANTANDER',
                  'INTER',
                  'PICPAY',
                  'MERCADO PAGO',
                  'ITAÚ',
                  'ITAU',
                ].where(text.contains).firstOrNull ??
                text;
          }

          for (final segment in (widget.preview['segments'] as List? ?? [])) {
            final institution = segment['institution'] as String? ?? '';
            final candidates = sources
                .where(
                  (source) =>
                      (segment['document_kind'] == 'BANK_STATEMENT_INDEX') ==
                          (source['source_type'] == 'BANK_ACCOUNT') &&
                      (institution.isEmpty
                          ? source['id'] == widget.preview['source_id']
                          : bank(institution) ==
                                bank(source['institution'] as String)) &&
                      (!institution.contains('(PF)') ||
                          source['holder_type'] == 'PF') &&
                      (!(institution.contains('(PJ)') ||
                              institution.toUpperCase().contains(
                                'NU EMPRESAS',
                              )) ||
                          source['holder_type'] == 'PJ'),
                )
                .toList();
            if (candidates.length == 1) {
              choices[segment['key'] as String] =
                  candidates.single['id'] as String;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _open(Map segment) async {
    final key = segment['key'] as String;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final child = await widget.service.selectSegment(
        widget.preview,
        key,
        choices[key]!,
      );
      if (!mounted) return;
      saved.add(key);
      if (![
        'BANK_STATEMENT_INDEX',
        'RENEGOTIATION',
        'UNKNOWN_INDEX',
      ].contains(child['content_type'])) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FinancialBillIntegrationView(
              service: widget.service,
              preview: child,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.financialSegmentsTitle,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(ApiErrorMapper.toLocalizedMessage(error!, l)),
            Text(l.financialSegmentsHelp),
            for (final segment
                in (widget.preview['segments'] as List? ?? [])) ...[
              const SizedBox(height: 12),
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${(segment['institution'] as String? ?? '').isEmpty ? l.pdfImportSource : segment['institution']} · ${segment['reference_label']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      segment['document_kind'] == 'BANK_STATEMENT_INDEX'
                          ? l.financialStatementIndexHelp
                          : segment['document_kind'] == 'RENEGOTIATION'
                          ? l.financialRenegotiationHelp
                          : segment['content_type'] == 'SUMMARY_ONLY'
                          ? l.financialSummaryOnlyHelp
                          : l.billIntegrationHelp,
                    ),
                    if (segment['extracted_header']?['total_amount_cents']
                        is int)
                      Text(
                        AppFormatters.formatCurrency(
                          segment['extracted_header']['total_amount_cents']
                              as int,
                        ),
                      ),
                    if (segment['extracted_header']?['due_on'] is String)
                      Text(
                        AppFormatters.formatDate(
                          DateTime.parse(
                            segment['extracted_header']['due_on'] as String,
                          ),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      key: ValueKey('segment-source-${segment['key']}'),
                      isExpanded: true,
                      isDense: false,
                      initialValue: choices[segment['key']],
                      decoration: InputDecoration(labelText: l.pdfImportSource),
                      items: sources
                          .where(
                            (s) =>
                                (segment['document_kind'] ==
                                    'BANK_STATEMENT_INDEX') ==
                                (s['source_type'] == 'BANK_ACCOUNT'),
                          )
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text('${s['name']} · ${s['institution']}'),
                            ),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (value) => setState(
                              () => choices[segment['key'] as String] = value!,
                            ),
                    ),
                    if (saved.contains(segment['key']))
                      Text(
                        [
                              'BANK_STATEMENT_INDEX',
                              'RENEGOTIATION',
                              'UNKNOWN_INDEX',
                            ].contains(segment['document_kind'])
                            ? l.financialEvidenceOnlySaved
                            : l.financialSegmentSaved,
                      ),
                    TextButton(
                      onPressed: busy || choices[segment['key']] == null
                          ? null
                          : () => _open(segment as Map),
                      child: Text(l.financialSegmentReview),
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
}
