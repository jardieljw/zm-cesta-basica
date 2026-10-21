import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/api_client.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/scroll_layout.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_operation_scope.dart';
import 'financial_bill_review_view.dart';
import 'payables_view.dart';
import 'financial_bank_review_view.dart';
import 'financial_header_review_view.dart';
import 'financial_bill_integration_view.dart';
import 'financial_segments_view.dart';
import 'financial_import_removal_view.dart';

/// Keeps page and area navigation stable while an import request is in flight.
mixin _ImportOperation<T extends StatefulWidget> on State<T> {
  bool busy = false;
  Object? error;
  bool uncertain = false;
  AppOperationLock? _lock;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lock = AppOperationScope.maybeOf(context);
  }

  Future<void> run(
    Future<void> Function() action, {
    bool mutation = false,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      uncertain = false;
    });
    _lock?.setActive(this, true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          uncertain = mutation && e is ApiException && e.statusCode == 0;
        });
      }
    } finally {
      _lock?.setActive(this, false);
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget errorMessage() => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            uncertain
                ? context.l10n.pdfImportUncertain
                : ApiErrorMapper.toLocalizedMessage(error, context.l10n),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
  @override
  void dispose() {
    _lock?.setActive(this, false);
    super.dispose();
  }
}

class FinancialImportsView extends StatefulWidget {
  final FinancialImportService? service;
  final ApiClient? apiClient;
  final Future<FinancialImportFile?> Function()? pickFile;
  const FinancialImportsView({
    super.key,
    this.service,
    this.apiClient,
    this.pickFile,
  });
  @override
  State<FinancialImportsView> createState() => _FinancialImportsViewState();
}

class _FinancialImportsViewState extends State<FinancialImportsView>
    with _ImportOperation<FinancialImportsView> {
  late final service =
      widget.service ?? FinancialImportService(apiClient: widget.apiClient);
  List<FinancialJson> sources = [],
      previews = [],
      readers = [],
      statements = [];
  Map<String, List<FinancialJson>> obligationsByStatement = {};
  String? sourceId, readerId;
  FinancialImportFile? file;
  bool loaded = false, more = false;
  int offset = 0;
  List<String> queryFailures = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    if (widget.service == null) service.close();
    super.dispose();
  }

  Future<void> _load({bool append = false}) => run(() async {
    final newSources = await service.sources();
    await service.requireLifecycle();
    final failures = <String>[];
    var newReaders = readers;
    try {
      newReaders = await service.readers();
    } catch (_) {
      failures.add(context.l10n.financialImportReadersQueryFailed);
    }
    var newStatements = statements;
    try {
      newStatements = await service.getStatements();
    } catch (_) {
      failures.add(context.l10n.financialImportStatementsQueryFailed);
    }
    final newObligations = Map<String, List<FinancialJson>>.from(
      obligationsByStatement,
    );
    for (final st in newStatements) {
      if (st['statement_type'] == 'CARD_BILL') {
        try {
          newObligations[st['id'] as String] = await service.getObligations(
            st['id'] as String,
          );
        } catch (_) {
          failures.add(context.l10n.financialImportObligationsQueryFailed);
        }
      }
    }
    final pageOffset = append ? offset : 0;
    final page = await service.rows(
      '${FinancialImportService.root}/previews?limit=50&offset=$pageOffset',
    );
    if (page.any(
      (entry) =>
          entry['import_id'] == null ||
          entry['generation'] == null ||
          entry['filename'] == null,
    )) {
      throw ApiException(
        statusCode: 503,
        message: 'A lista de importações precisa ser atualizada no serviço.',
        errorCode: 'FINANCIAL_SCHEMA_NOT_READY',
      );
    }
    if (!mounted) return;
    setState(() {
      queryFailures = failures.toSet().toList();
      sources = newSources.where((s) => s['currency'] == 'BRL').toList();
      readers = newReaders;
      statements = newStatements;
      obligationsByStatement = newObligations;
      if (!sources.any((s) => s['id'] == sourceId)) sourceId = null;
      previews = {
        for (final entry in [if (append) ...previews, ...page])
          entry['import_id']: entry,
      }.values.toList();
      offset = pageOffset + page.length;
      more = page.length == 50;
      loaded = true;
    });
  });

  bool _currentCard(FinancialJson p) =>
      p['bill_cycle_version'] == 1 &&
      sources.any(
        (s) => s['id'] == p['source_id'] && s['source_type'] == 'CREDIT_CARD',
      ) &&
      p['segments'] == null &&
      ['DETAILED_CARD_BILL', 'SUMMARY_ONLY'].contains(p['content_type']);

  Future<void> _preview(
    FinancialJson preview, {
    bool readingOnly = false,
  }) async {
    if (sourceId == null &&
        sources.any((s) => s['id'] == preview['source_id'])) {
      setState(() => sourceId = preview['source_id'] as String);
    }
    // Opening only reads the persisted root. Reprocessing is an explicit action.
    final current = preview;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => !readingOnly && _currentCard(current)
            ? FinancialBillIntegrationView(service: service, preview: current)
            : FinancialPdfPreviewView(
                service: service,
                previewId: current['id'] as String,
                importContext: FinancialImportService.lifecycleContext(current),
              ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _removeDocument(FinancialJson p) async {
    final removed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinancialImportRemovalView(
          service: service,
          documentId: p['document_id'] as String,
          importContext: FinancialImportService.lifecycleContext(p),
        ),
      ),
    );
    if (mounted && removed == true) await _load();
  }

  Future<void> _postToTreasuryDirect(String statementId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FinancialBankReviewView(service: service, statementId: statementId),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _launchStatementDirect(FinancialJson p) => _preview(p);

  Future<void> _reprocess(FinancialJson p, {String? password}) async {
    FinancialJson? updated;
    await run(() async {
      updated = await service.createPreview(
        p['document_id'] as String,
        sourceId: p['source_id'] as String,
        readerId: (p['filename'] as String).toLowerCase().endsWith('.csv')
            ? 'csv_auto'
            : 'pdf_auto',
        password: password,
        context: FinancialImportService.lifecycleContext(p),
        expectedRootPreviewId: p['id'] as String,
      );
    }, mutation: true);
    if (!mounted) return;
    if (error is ApiException &&
        (error as ApiException).errorCode == 'PDF_PASSWORD_REQUIRED') {
      final entered = await _promptPassword();
      if (entered != null && entered.isNotEmpty && mounted) {
        await _reprocess(p, password: entered);
      }
      return;
    }
    if (updated != null) await _preview(updated!);
  }

  Future<void> _launchCardBillDirect(FinancialJson p) async {
    if (_currentCard(p)) return _preview(p);
    final statement = statements
        .where(
          (s) =>
              s['id'] == p['statement_id'] && s['import_id'] == p['import_id'],
        )
        .firstOrNull;
    if (statement == null) return _preview(p);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinancialBillReviewView(
          service: service,
          statementId: statement['id'] as String,
          initialStatement: statement,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _reassignSource(FinancialJson p) async {
    final docId = p['document_id'] as String;
    final currentSourceId = p['source_id'] as String;
    final currentSource = sources
        .where((s) => s['id'] == currentSourceId)
        .firstOrNull;
    final isDetectedCard =
        (p['reader_id'] as String? ?? '').contains('card') ||
        (p['extracted_header']?['statement_type'] == 'CARD_BILL') ||
        ((p['result'] as Map?)?['extracted_header']?['statement_type'] ==
            'CARD_BILL') ||
        ((p['result'] as Map?)?['detected_source_type'] == 'CREDIT_CARD') ||
        (currentSource?['source_type'] == 'BANK_ACCOUNT');

    final targetType = isDetectedCard ? 'CREDIT_CARD' : 'BANK_ACCOUNT';
    final matchingSources = sources
        .where((s) => s['source_type'] == targetType)
        .toList();

    String? selectedSourceId = matchingSources.firstOrNull?['id'] as String?;
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isDetectedCard
                ? 'Corrigir para Cartão de Crédito'
                : 'Corrigir para Conta Bancária',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDetectedCard
                    ? context.l10n.importReassignCard
                    : context.l10n.importReassignBank,
              ),
              const SizedBox(height: 16),
              if (matchingSources.isEmpty) ...[
                Text(
                  'Nenhuma origem do tipo ${isDetectedCard ? "Cartão de Crédito" : "Conta Bancária"} cadastrada.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _newSource();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar Nova Origem'),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedSourceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Origem Correta',
                  ),
                  items: matchingSources
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(
                            _sourceLabel(s),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedSourceId = val),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            if (matchingSources.isNotEmpty)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selectedSourceId),
                child: const Text('Reavaliar Documento'),
              ),
          ],
        ),
      ),
    );

    if (chosen != null && chosen.isNotEmpty) {
      await run(() async {
        await service.createPreview(
          docId,
          sourceId: chosen,
          readerId: (p['filename'] as String).toLowerCase().endsWith('.csv')
              ? 'csv_auto'
              : 'pdf_auto',
          context: FinancialImportService.lifecycleContext(p),
          expectedRootPreviewId: p['id'] as String,
        );
      }, mutation: true);
      if (mounted && error == null) {
        final pal = AppPalette.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Documento reavaliado com sucesso com a nova origem!',
            ),
            backgroundColor: pal.accent,
          ),
        );
        await _load();
      }
    }
  }

  Future<void> _import({String? password}) async {
    FinancialJson? preview;
    await run(() async {
      final effectiveReader = file!.isPdf
          ? (readerId ?? 'pdf_auto')
          : (readerId ?? _suggestReader(file!, sourceId));
      preview = await service.importDocument(
        file!,
        sourceId!,
        readerId: effectiveReader,
        password: password,
      );
    }, mutation: true);
    if (!mounted) return;
    var passwordRequired =
        error is ApiException &&
        (error as ApiException).errorCode == 'PDF_PASSWORD_REQUIRED';
    if (preview != null && (preview!['errors_count'] as int? ?? 0) > 0) {
      try {
        final issues = await service.rows(
          '${FinancialImportService.root}/previews/${preview!['id']}/errors',
        );
        passwordRequired = issues.any(
          (e) => e['code'] == 'PDF_PASSWORD_REQUIRED',
        );
      } catch (_) {
        /* The preview remains consultable if the detail query fails. */
      }
    }
    if (!mounted) return;
    if (passwordRequired) {
      final entered = await _promptPassword();
      if (entered != null && entered.isNotEmpty && mounted) {
        await _import(password: entered);
      }
      return;
    }
    if (preview != null) await _preview(preview!);
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.importPasswordTitle),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: context.l10n.importPasswordLabel,
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        ),
      );
    } finally {
      // Wait for the dialog's exit transition before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      controller.clear();
      controller.dispose();
    }
  }

  String _suggestReader(FinancialImportFile f, String? currentSourceId) =>
      f.isPdf ? 'pdf_auto' : 'csv_auto';

  Future<void> _newSource() async {
    final source = await Navigator.of(context).push<FinancialJson>(
      MaterialPageRoute(builder: (_) => _FinancialSourceView(service: service)),
    );
    if (!mounted) return;
    await _load();
    if (mounted &&
        source != null &&
        sources.any((s) => s['id'] == source['id'])) {
      setState(() => sourceId = source['id'] as String);
    }
  }

  String _sourceLabel(FinancialJson s) {
    final base = '${s['name']} · ${s['institution']} · ${s['holder_type']}';
    final hasDuplicate = sources.any(
      (other) =>
          other['id'] != s['id'] &&
          '${other['name']} · ${other['institution']} · ${other['holder_type']}' ==
              base &&
          other['source_type'] != s['source_type'],
    );
    if (hasDuplicate) {
      final typeLabel = s['source_type'] == 'CREDIT_CARD' ? 'Cartão' : 'Conta';
      return '$base ($typeLabel)';
    }
    return base;
  }

  Future<void> _pickDocument() => run(() async {
    final selected = await (widget.pickFile ?? FinancialImportFile.pick)();
    if (selected != null) {
      selected.validate();
      if (mounted) {
        setState(() {
          file = selected;
          readerId = _suggestReader(selected, sourceId);
        });
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pColors = AppPalette.of(context);
    final primaryCardBtnStyle = FilledButton.styleFrom(
      backgroundColor: pColors.accent,
      foregroundColor: pColors.accentInk,
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final navCardBtnStyle = FilledButton.styleFrom(
      backgroundColor: pColors.soft,
      foregroundColor: pColors.accent,
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final outlinedCardBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: pColors.ink,
      side: BorderSide(color: pColors.line),
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.pdfImportTitle,
        actions: [
          IconButton(
            key: const ValueKey('refresh-imports'),
            tooltip: l.commonRefresh,
            onPressed: busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        floatingActionButton: loaded
            ? (file == null
                  ? FloatingActionButton.extended(
                      key: const ValueKey('pick-document-fab'),
                      backgroundColor: pColors.accent,
                      foregroundColor: pColors.accentInk,
                      onPressed: busy ? null : _pickDocument,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Selecionar documento'),
                    )
                  : FloatingActionButton.extended(
                      key: const ValueKey('read-document-fab'),
                      backgroundColor: pColors.accent,
                      foregroundColor: pColors.accentInk,
                      tooltip: sourceId == null
                          ? 'Selecione a conta ou cartão para ler o documento'
                          : l.pdfImportRead,
                      onPressed: busy || sourceId == null ? null : _import,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(l.pdfImportRead),
                    ))
            : null,
        body: ListView(
          padding: fabScrollPadding(context, horizontal: 20),
          children: [
            ApprovedSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.pdfImportHelp),
                  const SizedBox(height: 12),
                  Text(l.pdfImportEffect),
                  const SizedBox(height: 20),
                  if (loaded) ...[
                    if (sources.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.pdfImportNoSources,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: busy ? null : _newSource,
                              icon: const Icon(Icons.add),
                              label: Text(l.pdfImportNewSource),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey('pdf-source-$sourceId-${sources.length}'),
                        initialValue: sourceId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l.pdfImportSource,
                        ),
                        items: sources
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['id'] as String,
                                child: Text(
                                  _sourceLabel(s),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                sourceId = v;
                                if (file != null && file!.isCsv) {
                                  readerId = _suggestReader(file!, v);
                                }
                              }),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: busy ? null : _newSource,
                        icon: const Icon(Icons.add),
                        label: Text(l.pdfImportNewSource),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(l.pdfImportSourceCheck),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickDocument,
                      icon: Icon(
                        file?.isCsv == true
                            ? Icons.table_chart_outlined
                            : Icons.picture_as_pdf_outlined,
                      ),
                      label: Text(l.pdfImportChoose),
                    ),
                    if (file != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          file!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (sourceId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            sources.isEmpty
                                ? l.financialImportSourceRequiredEmpty
                                : l.financialImportSourceRequired,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                    if (file != null && file!.isCsv) ...[
                      const SizedBox(height: 16),
                      Text(l.financialImportAutoReaderHelp),
                    ],
                  ],
                  if (busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(l.pdfImportBusy),
                  ],
                  errorMessage(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ApprovedSectionHeader(l.pdfImportHistory),
            if (queryFailures.isNotEmpty)
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final failure in queryFailures)
                      Text(
                        failure,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: busy ? null : _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.financialImportRefreshQuery),
                    ),
                  ],
                ),
              ),
            if (loaded && previews.isEmpty)
              ApprovedSurface(child: Text(l.pdfImportEmpty)),
            for (final p in previews) ...[
              () {
                final stmt = statements
                    .where(
                      (s) =>
                          s['id'] == p['statement_id'] &&
                          s['import_id'] == p['import_id'],
                    )
                    .firstOrNull;
                final isCard = stmt != null
                    ? stmt['statement_type'] == 'CARD_BILL'
                    : (sources
                                  .where((s) => s['id'] == p['source_id'])
                                  .firstOrNull?['source_type'] ==
                              'CREDIT_CARD' ||
                          (p['reader_id'] as String? ?? '').contains('card'));
                final linked = stmt != null
                    ? (stmt['linked_count'] as int? ?? 0)
                    : 0;
                final ready =
                    p['status'] == 'READY' &&
                    p['segments'] == null &&
                    ![
                      'BANK_STATEMENT_INDEX',
                      'RENEGOTIATION',
                      'UNKNOWN_INDEX',
                    ].contains(p['content_type']);
                final errors = (p['errors'] as List? ?? []);
                final hasMismatch = errors.any(
                  (e) => e['code'] == 'PDF_SOURCE_TYPE_MISMATCH',
                );
                final currentSource = sources
                    .where((s) => s['id'] == p['source_id'])
                    .firstOrNull;
                final isSourceBank =
                    currentSource?['source_type'] == 'BANK_ACCOUNT';

                final obligations = stmt != null
                    ? (obligationsByStatement[stmt['id']] ?? [])
                    : <FinancialJson>[];
                final activeObligations = obligations
                    .where(
                      (o) => const {'OPEN', 'PARTIAL'}.contains(o['status']),
                    )
                    .length;

                Color badgeBg;
                Color badgeFg;
                String statusBadge;
                if (stmt != null) {
                  if (isCard) {
                    if (activeObligations > 0) {
                      statusBadge =
                          '${l.financialRegisteredBill} · '
                          '${l.financialBillOpenObligations(activeObligations)}';
                      badgeBg = pColors.soft;
                      badgeFg = pColors.accent;
                    } else if (obligations.isNotEmpty &&
                        obligations.every((o) => o['status'] == 'CANCELED')) {
                      statusBadge = l.financialSavedOnly;
                      badgeBg = pColors.soft;
                      badgeFg = pColors.accent;
                    } else {
                      statusBadge = l.importBillConfirmedReview;
                      badgeBg = pColors.warnFill;
                      badgeFg = pColors.warn;
                    }
                  } else {
                    if (linked > 0) {
                      statusBadge = l.importBankIdentitiesReviewed;
                      badgeBg = pColors.soft;
                      badgeFg = pColors.accent;
                    } else {
                      statusBadge = l.importBankConfirmedReview;
                      badgeBg = pColors.soft;
                      badgeFg = pColors.accent;
                    }
                  }
                } else {
                  if (ready) {
                    statusBadge = l.importReadyReview;
                    badgeBg = pColors.soft;
                    badgeFg = pColors.accent;
                  } else if (hasMismatch) {
                    statusBadge = l.financialImportSourceMismatch(
                      isSourceBank ? l.pdfImportCard : l.pdfImportBank,
                      isSourceBank ? l.pdfImportBank : l.pdfImportCard,
                    );
                    badgeBg = pColors.warnFill;
                    badgeFg = pColors.warn;
                  } else {
                    final dates =
                        ((p['header_candidates'] as Map?)?['due_on'] as List? ??
                                [])
                            .map((c) => (c as Map)['value'])
                            .toSet();
                    statusBadge = dates.length > 1
                        ? l.financialDocumentDueReview
                        : p['content_type'] == 'UNKNOWN' ||
                              p['complete'] == false ||
                              p['content_type'] == null
                        ? l.pdfImportBlocked
                        : l.financialDocumentPending;
                    badgeBg = pColors.warnFill;
                    badgeFg = pColors.warn;
                  }
                }

                final sourceTitle = currentSource != null
                    ? _sourceLabel(currentSource)
                    : l.pdfImportDocument;

                if (obligations.isNotEmpty &&
                    activeObligations == 0 &&
                    obligations.every((o) => o['status'] == 'CANCELED')) {
                  statusBadge = l.financialSavedOnly;
                } else if (p['recorded_payable_id'] != null ||
                    (p['recorded_payables_count'] as int? ?? 0) > 0) {
                  statusBadge = activeObligations > 0
                      ? '${l.financialRegisteredBill} · '
                            '${l.financialBillOpenObligations(activeObligations)}'
                      : l.financialRegisteredBill;
                } else if (p['recorded_destination'] != null) {
                  statusBadge = l.financialSavedOnly;
                } else if (stmt != null && !isCard) {
                  statusBadge = l.financialStatementSaved;
                }
                return Padding(
                  key: ValueKey('import-${p['import_id']}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ApprovedSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (p['reader_id'] as String? ?? '').contains(
                                        'csv',
                                      )
                                      ? Icons.table_chart_outlined
                                      : Icons.description_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Tooltip(
                                    message:
                                        p['filename'] as String? ??
                                        l.pdfImportDocument,
                                    child: Text(
                                      p['filename'] as String? ??
                                          l.pdfImportDocument,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: badgeFg.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                statusBadge,
                                style: TextStyle(
                                  color: badgeFg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(sourceTitle),
                        if (isCard &&
                            p['bill_cycle_version'] != 1 &&
                            p['segments'] == null) ...[
                          Text(l.financialImportLegacyReadHelp),
                          TextButton.icon(
                            key: ValueKey('reprocess-import-${p['import_id']}'),
                            onPressed: busy ? null : () => _reprocess(p),
                            icon: const Icon(Icons.refresh),
                            label: Text(l.financialImportUpdateRead),
                          ),
                        ],
                        if (p['financial_status'] == 'PENDING')
                          Text(l.financialImportPendingNoAccount),
                        if (queryFailures.isNotEmpty &&
                            p['financial_status'] != 'PENDING')
                          Text(l.financialImportPartialStatus),
                        Text(
                          l.pdfImportCounts(
                            p['items_count'] as int,
                            p['pages_count'] as int? ?? 0,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              key: ValueKey(
                                _currentCard(p)
                                    ? 'launch-card-btn-${p['import_id']}'
                                    : 'open-document-${p['import_id']}',
                              ),
                              onPressed: busy ? null : () => _preview(p),
                              icon: const Icon(Icons.description_outlined),
                              label: Text(l.financialOpenDocument),
                            ),
                            OutlinedButton.icon(
                              key: ValueKey('remove-import-${p['import_id']}'),
                              onPressed: busy ? null : () => _removeDocument(p),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l.importRemovalTitle),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(l.financialOtherDocumentOptions),
                          children: [
                            if (_currentCard(p))
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => _preview(p, readingOnly: true),
                                child: Text(l.financialReadingDetails),
                              )
                            else ...[
                              Text(l.financialLegacyOptionsHelp),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                  if (stmt != null && isCard) ...[
                                    if (obligations.isNotEmpty) ...[
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'open-payables-btn-${stmt['id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const PayablesView(),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l.financialImportOpenPayables,
                                        ),
                                        style: navCardBtnStyle,
                                      ),
                                      OutlinedButton.icon(
                                        key: ValueKey(
                                          'bill-review-btn-${stmt['id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                await Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        FinancialBillReviewView(
                                                          service: service,
                                                          statementId:
                                                              stmt['id']
                                                                  as String,
                                                          initialStatement:
                                                              stmt,
                                                        ),
                                                  ),
                                                );
                                                if (mounted) await _load();
                                              },
                                        icon: const Icon(
                                          Icons.assignment_turned_in_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Ver Classificação'),
                                        style: outlinedCardBtnStyle,
                                      ),
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: const Text('Ver Documento'),
                                      ),
                                    ] else ...[
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'launch-card-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _launchCardBillDirect(p),
                                        icon: const Icon(Icons.bolt, size: 16),
                                        label: Text(
                                          context.l10n.importReviewBill,
                                        ),
                                        style: primaryCardBtnStyle,
                                      ),
                                      OutlinedButton.icon(
                                        key: ValueKey(
                                          'bill-review-btn-${stmt['id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                await Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        FinancialBillReviewView(
                                                          service: service,
                                                          statementId:
                                                              stmt['id']
                                                                  as String,
                                                          initialStatement:
                                                              stmt,
                                                        ),
                                                  ),
                                                );
                                                if (mounted) await _load();
                                              },
                                        icon: const Icon(
                                          Icons.assignment_turned_in_outlined,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Revisar e Classificar',
                                        ),
                                        style: outlinedCardBtnStyle,
                                      ),
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: const Text('Ver Detalhes'),
                                      ),
                                    ],
                                  ] else if (stmt != null && !isCard) ...[
                                    FilledButton.icon(
                                      key: ValueKey(
                                        'post-treasury-btn-${stmt['id']}',
                                      ),
                                      onPressed: busy
                                          ? null
                                          : () => _postToTreasuryDirect(
                                              stmt['id'] as String,
                                            ),
                                      icon: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        linked > 0
                                            ? context.l10n.importReviewBank
                                            : context.l10n.importReviewBank,
                                      ),
                                      style: primaryCardBtnStyle,
                                    ),
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => _preview(p),
                                      style: outlinedCardBtnStyle,
                                      child: const Text('Ver Lançamentos'),
                                    ),
                                  ] else if (stmt == null) ...[
                                    if (ready && isCard) ...[
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'launch-card-direct-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _launchCardBillDirect(p),
                                        icon: const Icon(Icons.bolt, size: 16),
                                        label: Text(
                                          context.l10n.importReviewBill,
                                        ),
                                        style: primaryCardBtnStyle,
                                      ),
                                      OutlinedButton(
                                        key: ValueKey(
                                          'preview-confirm-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: const Text('Ver Prévia'),
                                      ),
                                    ] else if (ready && !isCard) ...[
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'launch-statement-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _launchStatementDirect(p),
                                        icon: const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          context.l10n.importReviewBank,
                                        ),
                                        style: primaryCardBtnStyle,
                                      ),
                                      OutlinedButton(
                                        key: ValueKey(
                                          'preview-confirm-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: const Text('Ver Prévia'),
                                      ),
                                    ] else if (hasMismatch) ...[
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'reassign-source-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _reassignSource(p),
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 16,
                                        ),
                                        label: Text(
                                          isSourceBank
                                              ? 'Trocar para Cartão de Crédito'
                                              : 'Trocar para Conta Bancária',
                                        ),
                                        style: primaryCardBtnStyle,
                                      ),
                                      OutlinedButton(
                                        key: ValueKey(
                                          'preview-confirm-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: Text(
                                          l.financialDocumentReviewAction,
                                        ),
                                      ),
                                    ] else ...[
                                      OutlinedButton(
                                        key: ValueKey(
                                          'preview-confirm-btn-${p['import_id']}',
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => _preview(p),
                                        style: outlinedCardBtnStyle,
                                        child: Text(
                                          l.financialDocumentReviewAction,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }(),
            ],
            if (more)
              TextButton(
                onPressed: busy ? null : () => _load(append: true),
                child: Text(l.pdfImportMore),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinancialSourceView extends StatefulWidget {
  final FinancialImportService service;
  const _FinancialSourceView({required this.service});
  @override
  State<_FinancialSourceView> createState() => _FinancialSourceViewState();
}

class _FinancialSourceViewState extends State<_FinancialSourceView>
    with _ImportOperation<_FinancialSourceView> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), institution = TextEditingController();
  String type = 'BANK_ACCOUNT', holder = 'PJ', account = '';
  List<FinancialJson> banks = [];
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanks());
  }

  Future<void> _loadBanks() => run(() async {
    List<FinancialJson> result = [];
    List<FinancialJson> sources = [];
    try {
      result = await widget.service.bankAccounts();
      sources = await widget.service.sources();
    } catch (_) {
      // Gracefully proceed so user can create a new linked bank account
    }
    if (mounted) {
      setState(() {
        banks = result
            .where(
              (b) => !sources.any((s) => s['financial_account_id'] == b['id']),
            )
            .toList();
        loaded = true;
      });
    }
  });
  @override
  void dispose() {
    name.dispose();
    institution.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    FinancialJson? result;
    await run(() async {
      result = await widget.service.createSource(
        name: name.text.trim(),
        institution: institution.text.trim(),
        sourceType: type,
        holderType: holder,
        accountId: type == 'BANK_ACCOUNT' && account.isNotEmpty
            ? account
            : null,
      );
    }, mutation: true);
    if (mounted && result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? validate(String? v) =>
        v == null || v.trim().length < 2 || v.trim().length > 100
        ? l.pdfImportRequired
        : null;
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.pdfImportNewSource,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: busy || !loaded ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(l.commonSave),
        ),
        body: Form(
          key: form,
          child: ListView(
            padding: fabScrollPadding(context, horizontal: 20),
            children: [
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      isExpanded: true,
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
                      onChanged: busy ? null : (v) => setState(() => type = v!),
                      decoration: InputDecoration(labelText: l.pdfImportSource),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      enabled: !busy,
                      maxLength: 100,
                      validator: validate,
                      decoration: InputDecoration(
                        labelText: l.pdfImportSourceName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: institution,
                      enabled: !busy,
                      maxLength: 100,
                      validator: validate,
                      decoration: InputDecoration(
                        labelText: l.pdfImportInstitution,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: holder,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.pdfImportHolder),
                      items: [
                        DropdownMenuItem(
                          value: 'PJ',
                          child: Text(l.pdfImportPJ),
                        ),
                        DropdownMenuItem(
                          value: 'PF',
                          child: Text(l.pdfImportPF),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => holder = v!),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: type != 'BANK_ACCOUNT'
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: account,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l.pdfImportBankLink,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text(l.pdfImportNewBank),
                                      ),
                                      ...banks.map(
                                        (b) => DropdownMenuItem(
                                          value: b['id'] as String,
                                          child: Text(b['name'] as String),
                                        ),
                                      ),
                                    ],
                                    onChanged: busy
                                        ? null
                                        : (v) => setState(() => account = v!),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(l.pdfImportBankHelp),
                                ],
                              ),
                            ),
                    ),
                    if (busy) const LinearProgressIndicator(),
                    errorMessage(),
                    if (!loaded && !busy)
                      TextButton(
                        onPressed: _loadBanks,
                        child: Text(l.pdfImportRetry),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialPdfPreviewView extends StatefulWidget {
  final FinancialImportService service;
  final String previewId;
  final FinancialJson? importContext;
  const FinancialPdfPreviewView({
    super.key,
    required this.service,
    required this.previewId,
    this.importContext,
  });
  @override
  State<FinancialPdfPreviewView> createState() =>
      _FinancialPdfPreviewViewState();
}

class _FinancialPdfPreviewViewState extends State<FinancialPdfPreviewView>
    with _ImportOperation<FinancialPdfPreviewView> {
  FinancialJson? preview, source, document, statement;
  FinancialJson? frozenContext;
  List<FinancialJson> items = [], issues = [], pages = [];
  bool acknowledged = false;
  String get base =>
      '${FinancialImportService.root}/previews/${widget.previewId}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => run(_loadData);

  Future<void> _loadData() async {
    final p = await widget.service.get(base);
    final expected = widget.importContext ?? frozenContext;
    if (expected != null &&
        (expected['import_id'] != p['import_id'] ||
            expected['expected_generation'] != p['generation'])) {
      throw ApiException(
        statusCode: 409,
        message:
            'Esta importação mudou. Volte à lista e atualize os documentos antes de continuar a conferência.',
        errorCode: 'FINANCIAL_IMPORT_GENERATION_CONFLICT',
      );
    }
    frozenContext ??= FinancialImportService.lifecycleContext(p);
    final s = await widget.service.sources();
    final d = await widget.service.get(
      '${FinancialImportService.root}/documents/${p['document_id']}',
    );
    final rows = await widget.service.rows('$base/items?offset=0&limit=50');
    final errors = await widget.service.rows('$base/errors?offset=0&limit=50');
    final text = await widget.service.rows('$base/pages?offset=0&limit=5');
    FinancialJson? confirmed;
    // A lost confirmation response can be recovered by reading server history.
    for (var offset = 0; ; offset += 100) {
      final statements = await widget.service.rows(
        '${FinancialImportService.root}/statements?source_id=${p['source_id']}&offset=$offset&limit=100',
      );
      confirmed = statements
          .where(
            (v) =>
                v['preview_id'] == widget.previewId &&
                v['import_id'] == p['import_id'] &&
                v['generation'] == p['generation'],
          )
          .firstOrNull;
      if (confirmed != null) {
        try {
          confirmed = await widget.service.getStatement(
            confirmed['id'] as String,
          );
        } catch (_) {}
        break;
      }
      if (statements.length < 100) break;
    }
    if (mounted) {
      setState(() {
        preview = p;
        source = s.where((v) => v['id'] == p['source_id']).firstOrNull;
        document = d;
        items = rows;
        issues = errors;
        pages = text;
        statement = confirmed;
        acknowledged = false;
      });
    }
  }

  Future<void> _postToTreasury() async {
    if (statement == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinancialBankReviewView(
          service: widget.service,
          statementId: statement!['id'] as String,
        ),
      ),
    );
    if (mounted) await _loadData();
  }

  Future<void> _confirm() async {
    final p = preview!;
    Map<String, dynamic>? extraHeader;
    if (p['reader_id'] != 'pdf_auto') {
      extraHeader = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => FinancialHeaderReviewView(
            isCard: source?['source_type'] == 'CREDIT_CARD',
            extractedHeader: Map<String, dynamic>.from(
              p['extracted_header'] as Map? ?? {},
            ),
          ),
        ),
      );
      if (extraHeader == null || !mounted) return;
    }
    await run(() async {
      final result = await widget.service.confirm(
        p,
        confirmationHeader: extraHeader,
      );
      if (!mounted) return;
      setState(() => statement = result);
      final full = await widget.service.getStatement(result['id'] as String);
      if (mounted) setState(() => statement = full);
    }, mutation: true);
  }

  Future<void> _integrateBill() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinancialBillIntegrationView(
          service: widget.service,
          preview: preview!,
        ),
      ),
    );
    if (mounted) await _loadData();
  }

  Future<void> _original() async {
    Widget? viewer;
    await run(() async {
      final bytes = await widget.service.original(
        preview!['document_id'] as String,
      );
      if (mounted) {
        final filename = (document?['filename'] as String? ?? '').toLowerCase();
        final isPdf =
            filename.endsWith('.pdf') || (preview?['reader_id'] == 'pdf_auto');
        viewer = ApprovedPage(
          title: context.l10n.pdfImportOriginalTitle,
          body: isPdf
              ? PdfPreview(
                  build: (_) async => bytes,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    utf8.decode(bytes, allowMalformed: true),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
        );
      }
    });
    if (mounted && viewer != null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => viewer!));
    }
  }

  String _date(Object value) =>
      AppFormatters.formatDate(DateTime.parse(value as String));
  Widget _field(String label, String value, {int? page}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value),
        if (page != null)
          Text(
            context.l10n.pdfImportPage(page),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, p = preview;
    final pal = AppPalette.of(context);
    final ready =
        p?['status'] == 'READY' &&
        p?['segments'] == null &&
        ![
          'BANK_STATEMENT_INDEX',
          'RENEGOTIATION',
          'UNKNOWN_INDEX',
        ].contains(p?['content_type']);
    final cycleFlow =
        p?['bill_cycle_version'] == 1 &&
        source?['source_type'] == 'CREDIT_CARD';
    final canIntegrate =
        cycleFlow &&
        p?['segments'] == null &&
        ![
          'UNKNOWN',
          'SUMMARY_INDEX',
          'MULTI_CYCLE_COMPILATION',
          'BANK_STATEMENT_INDEX',
          'RENEGOTIATION',
          'UNKNOWN_INDEX',
        ].contains(p?['content_type']);
    final header = Map<String, dynamic>.from(
      p?['extracted_header'] as Map? ?? {},
    );
    final fieldSources = Map<String, dynamic>.from(
      p?['field_sources'] as Map? ?? {},
    );
    final dueCandidates =
        ((p?['header_candidates'] as Map?)?['due_on'] as List? ?? [])
            .cast<Map>();
    final dueConflict = dueCandidates.map((c) => c['value']).toSet().length > 1;
    final candidateDates = <String, Set<int>>{};
    for (final c in dueCandidates) {
      final values = candidateDates.putIfAbsent(
        c['value'] as String,
        () => <int>{},
      );
      if (c['page_number'] is int) values.add(c['page_number'] as int);
    }

    final dates = {
      'period_start': l.pdfImportPeriodStart,
      'period_end': l.pdfImportPeriodEnd,
      'issued_on': l.pdfImportIssued,
      'closing_on': l.pdfImportClosing,
      'due_on': l.pdfImportDue,
    };
    final money = {
      'total_amount_cents': l.pdfImportTotal,
      'minimum_payment_cents': l.pdfImportMinimum,
      'opening_balance_cents': l.pdfImportOpeningBalance,
      'closing_balance_cents': l.pdfImportClosingBalance,
      'total_inflows_cents': l.pdfImportInflows,
      'total_outflows_cents': l.pdfImportOutflows,
    };
    final controls = {
      'PDF_SECTION_TOTAL': l.pdfImportSectionCheck,
      'PDF_REPORTED_BILL_EQUATION': l.pdfImportBillEquation,
      'PDF_SUMMARY_DETAILS': l.pdfImportDetailsCheck,
      'PDF_BALANCE_EQUATION': l.pdfImportBalanceCheck,
      'PDF_TOTAL_INFLOWS_CENTS': l.pdfImportInflowsCheck,
      'PDF_TOTAL_OUTFLOWS_CENTS': l.pdfImportOutflowsCheck,
    };
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.pdfImportReading,
        actions: [
          IconButton(
            tooltip: l.commonRefresh,
            onPressed: busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        floatingActionButton:
            p != null && ready && statement == null && !cycleFlow
            ? FloatingActionButton.extended(
                key: const ValueKey('pdf-confirm'),
                onPressed: busy || !acknowledged ? null : _confirm,
                icon: const Icon(Icons.check),
                label: Text(l.pdfImportConfirm),
              )
            : null,
        body: ListView(
          padding: fabScrollPadding(context, horizontal: 20),
          children: [
            if (busy) const LinearProgressIndicator(),
            errorMessage(),
            if (p != null) ...[
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      document?['filename'] as String? ?? l.pdfImportDocument,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statement != null
                          ? l.pdfImportConfirmed
                          : ready
                          ? l.pdfImportReady
                          : dueConflict
                          ? l.financialDocumentDueReview
                          : p['content_type'] == 'UNKNOWN' ||
                                p['complete'] == false ||
                                p['content_type'] == null
                          ? l.pdfImportBlocked
                          : l.financialDocumentPending,
                    ),
                    Text(
                      l.pdfImportCounts(
                        p['items_count'] as int,
                        p['pages_count'] as int? ?? 0,
                      ),
                    ),
                    if (source != null)
                      _field(
                        l.pdfImportSource,
                        '${source!['name']} · ${source!['institution']} · ${source!['holder_type']}',
                      ),
                    if (source?['source_type'] == 'BANK_ACCOUNT')
                      Text(l.financialBankDocumentHelp),
                    if (p['detected_institution'] != null)
                      _field(
                        l.pdfImportInstitution,
                        p['detected_institution'] as String,
                      ),
                    Text(l.pdfImportSourceCheck),
                    const SizedBox(height: 12),
                    Text(
                      header['statement_type'] == 'CARD_BILL'
                          ? l.pdfImportSignCard
                          : l.pdfImportSignBank,
                    ),
                    for (final field in {...dates, ...money}.entries)
                      if (header[field.key] != null)
                        _field(
                          field.value,
                          dates.containsKey(field.key)
                              ? _date(header[field.key])
                              : AppFormatters.formatCurrency(
                                  header[field.key] as int,
                                ),
                          page:
                              (fieldSources[field.key] as Map?)?['page_number']
                                  as int?,
                        ),
                    if (dueConflict) ...[
                      Text(l.financialImportDueConflict),
                      for (final entry in candidateDates.entries)
                        _field(
                          l.pdfImportDue,
                          '${_date(entry.key)}${entry.value.isEmpty ? '' : ' · ${l.financialPages}: ${(entry.value.toList()..sort()).join(', ')}'}',
                        ),
                    ],
                    OutlinedButton.icon(
                      onPressed: busy ? null : _original,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l.pdfImportOriginal),
                    ),
                    if (p['segments'] != null) ...[
                      Text(l.financialSegmentsHelp),
                      FilledButton.icon(
                        key: const ValueKey('review-segments'),
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FinancialSegmentsView(
                                    service: widget.service,
                                    preview: p,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.view_list_outlined),
                        label: Text(l.financialSegmentsTitle),
                      ),
                    ],
                    if (canIntegrate) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('bill-cycle-open'),
                        onPressed: busy ? null : _integrateBill,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(l.billIntegrationTitle),
                      ),
                    ],
                    if (ready && statement == null && !cycleFlow) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('top-confirm-launch-btn'),
                        onPressed: busy ? null : _confirm,
                        icon: Icon(
                          header['statement_type'] == 'CARD_BILL'
                              ? Icons.assignment_turned_in_outlined
                              : Icons.account_balance_wallet_outlined,
                        ),
                        label: Text(l.importConfirmReview),
                        style: FilledButton.styleFrom(
                          backgroundColor: pal.accent,
                          foregroundColor: pal.accentInk,
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (statement != null && !cycleFlow) ...[
                ApprovedSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: pal.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.pdfImportSuccess,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (header['statement_type'] == 'CARD_BILL' ||
                          statement!['statement_type'] == 'CARD_BILL') ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const ValueKey('open-bill-review-button'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => FinancialBillReviewView(
                                  service: widget.service,
                                  statementId: statement!['id'] as String,
                                  initialStatement: statement,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('Revisão Semântica e Obrigações'),
                          style: FilledButton.styleFrom(
                            backgroundColor: pal.soft,
                            foregroundColor: pal.accent,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const ValueKey('post-to-treasury-button'),
                          onPressed: busy ? null : _postToTreasury,
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: Text(l.importReviewBank),
                          style: FilledButton.styleFrom(
                            backgroundColor: pal.accent,
                            foregroundColor: pal.accentInk,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if ((statement!['linked_count'] ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            l.importBankIdentityNote,
                            style: TextStyle(
                              color: pal.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if ((p['checks'] as List? ?? []).isNotEmpty) ...[
                ApprovedSectionHeader(l.pdfImportControls),
                ApprovedSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in p['checks'] as List)
                        _field(
                          controls[c['code']] ?? l.pdfImportControls,
                          c['matches'] == true
                              ? l.pdfImportControlOk
                              : l.pdfImportControlFail,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ApprovedSectionHeader(l.pdfImportWarnings),
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      canIntegrate
                          ? l.financialReadSnapshotHelp
                          : l.pdfImportEffect,
                    ),
                    if (!ready && !canIntegrate)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(l.pdfImportBlockedHelp),
                      ),
                    for (final warning in p['warnings'] as List? ?? [])
                      if (warning['code'] ==
                          'PDF_PARTIAL_DATE_YEAR_FROM_BILL_CONTEXT')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(l.pdfImportPartialYear),
                        ),
                    for (final issue in {
                      for (final issue in issues)
                        if (!canIntegrate ||
                            ![
                              'PDF_CONFLICTING_HEADER',
                              'FINANCIAL_DUE_DATE_CONFLICT',
                            ].contains(issue['code']))
                          '${issue['code']}': issue,
                    }.values)
                      _field(
                        issue['page_number'] == null
                            ? l.pdfImportBlocked
                            : l.pdfImportPage(issue['page_number'] as int),
                        ApiErrorMapper.toLocalizedMessage(
                          ApiException(
                            statusCode: 422,
                            message: '',
                            errorCode: issue['code'] as String,
                          ),
                          l,
                        ),
                      ),
                    if (issues.length < (p['errors_count'] as int? ?? 0))
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                final next = await widget.service.rows(
                                  '$base/errors?offset=${issues.length}&limit=50',
                                );
                                if (mounted) {
                                  setState(() => issues.addAll(next));
                                }
                              }),
                        child: Text(l.pdfImportMore),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ApprovedSectionHeader(l.pdfImportItems),
              Text(
                l.pdfImportCoverage(
                  items.length,
                  p['items_count'] as int? ?? items.length,
                ),
              ),
              const SizedBox(height: 12),
              for (final item in items) ...[
                ApprovedSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item['data']['description'] as String,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(_date(item['data']['transaction_date'])),
                          Text(
                            AppFormatters.formatCurrency(
                              item['data']['amount_cents'] as int,
                            ),
                          ),
                          if (item['page_number'] != null)
                            Text(l.pdfImportPage(item['page_number'] as int)),
                        ],
                      ),
                      if (item['data']['installment_number'] != null &&
                          item['data']['total_installments'] != null)
                        Text(
                          l.pdfImportInstallments(
                            item['data']['installment_number'] as int,
                            item['data']['total_installments'] as int,
                          ),
                        ),
                      if ((item['candidates'] as List? ?? []).isNotEmpty)
                        Text(l.pdfImportCandidate),
                      if (item['raw_text'] != null)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(l.pdfImportOriginalTitle),
                          children: [
                            SelectableText(item['raw_text'] as String),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (items.length < (p['items_count'] as int))
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          final next = await widget.service.rows(
                            '$base/items?offset=${items.length}&limit=50',
                          );
                          if (mounted) setState(() => items.addAll(next));
                        }),
                  child: Text(l.pdfImportMore),
                ),
              const SizedBox(height: 20),
              ApprovedSectionHeader(l.pdfImportPages),
              for (final page in pages)
                ApprovedSurface(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.pdfImportPage(page['page_number'] as int)),
                    children: [
                      SelectableText(
                        (page['text'] as String?)?.isNotEmpty == true
                            ? page['text'] as String
                            : l.pdfImportNoText,
                      ),
                    ],
                  ),
                ),
              if (pages.length < (p['pages_count'] as int? ?? 0))
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          final next = await widget.service.rows(
                            '$base/pages?offset=${pages.length}&limit=5',
                          );
                          if (mounted) setState(() => pages.addAll(next));
                        }),
                  child: Text(l.pdfImportMore),
                ),
              if (ready && statement == null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acknowledged,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => acknowledged = v!),
                  title: Text(l.pdfImportAcknowledged),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
