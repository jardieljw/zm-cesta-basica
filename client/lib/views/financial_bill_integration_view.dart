import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/financial_import_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/scroll_layout.dart';
import '../widgets/shared/approved_app_style.dart';
import '../widgets/shared/app_operation_scope.dart';
import 'financial_header_review_view.dart';
import 'financial_installment_agenda_view.dart';
import 'financial_import_removal_view.dart';
import 'payable_payment_view.dart';
import '../services/payable_service.dart';
import '../services/payable_payment_coordinator.dart';

/// One final command stages evidence and integrates the bill atomically.
class FinancialBillIntegrationView extends StatefulWidget {
  final FinancialImportService service;
  final FinancialJson preview;
  const FinancialBillIntegrationView({
    super.key,
    required this.service,
    required this.preview,
  });
  @override
  State<FinancialBillIntegrationView> createState() =>
      _FinancialBillIntegrationViewState();
}

class _FinancialBillIntegrationViewState
    extends State<FinancialBillIntegrationView> {
  FinancialJson? draft, result, frozenCommand;
  Map<String, dynamic> header = {};
  String destination = 'PENDING';
  bool busy = false, acknowledged = false, detailAccepted = false;
  bool dueResolved = false, contentAccepted = false;
  bool estimateInstallmentDay = true;
  bool editingSaved = false;
  String? controlPreviewId;
  final replacements = <String, FinancialJson>{};
  final purposes = <int, String>{};
  final _targetKeys = <String, GlobalKey>{
    'dates': GlobalKey(),
    'header': GlobalKey(),
    'original': GlobalKey(),
    'content': GlobalKey(),
    'obligations': GlobalKey(),
    'destination': GlobalKey(),
    'details': GlobalKey(),
    'controls': GlobalKey(),
    'readErrors': GlobalKey(),
  };
  String? _highlightedTarget;
  Object? error;
  AppOperationLock? lock;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lock = AppOperationScope.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firstLoad = draft == null;
    setState(() => busy = true);
    try {
      final value = await widget.service.billIntegrationDraft(
        widget.preview['id'] as String,
        reference: (header['due_on'] as String?)?.substring(0, 7),
        context: FinancialImportService.lifecycleContext(widget.preview),
      );
      if (mounted) {
        setState(() {
          draft = value;
          header = {
            ...header,
            ...Map<String, dynamic>.from(value['header'] as Map? ?? {}),
          };
          if (value['cycle'] is Map) {
            final existing = value['cycle'] as Map;
            if (firstLoad &&
                existing['import_withdrawn'] == true &&
                existing['preview_id'] == widget.preview['id']) {
              header = {
                ...header,
                'due_on': existing['due_on'],
                'total_amount_cents': existing['total_amount_cents'],
              };
              dueResolved = true;
            }
            if (firstLoad) {
              destination = existing['import_withdrawn'] == true
                  ? 'PENDING'
                  : existing['destination'] == 'CREDIT'
                  ? 'OPEN'
                  : existing['destination'] as String;
            }
            if (existing['preview_id'] == widget.preview['id'] &&
                !editingSaved &&
                existing['import_withdrawn'] != true) {
              result = Map<String, dynamic>.from(existing);
              header = {
                ...header,
                'due_on': existing['due_on'],
                'total_amount_cents': existing['total_amount_cents'],
              };
              dueResolved = true;
              for (final item in existing['items'] as List? ?? []) {
                if (item['position'] is int && item['purpose'] is String) {
                  purposes[item['position'] as int] = item['purpose'] as String;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showFailure(e, canHighlight: draft != null);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _header() async {
    final value = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            FinancialHeaderReviewView(isCard: true, extractedHeader: header),
      ),
    );
    if (value != null && mounted) {
      setState(() {
        header = value;
        acknowledged = false;
        error = null;
        _highlightedTarget = null;
      });
      await _load();
    }
  }

  Future<void> _confirm() async {
    if (draft == null ||
        header['due_on'] == null ||
        header['total_amount_cents'] == null) {
      return;
    }
    // A lost response retries this exact body/key, without a fresh decision.
    frozenCommand ??= {
      ...FinancialImportService.lifecycleContext(widget.preview),
      'version': 1,
      'expected_source_id': widget.preview['source_id'],
      'expected_result_sha256': widget.preview['result_sha256'],
      'expected_revision': draft!['expected_revision'],
      'reference': (header['due_on'] as String).substring(0, 7),
      'due_on': header['due_on'],
      'total_amount_cents': header['total_amount_cents'],
      'destination': destination,
      'controls_confirmed': true,
      'accept_details_pending': detailAccepted,
      'estimate_installment_day': estimateInstallmentDay,
      'due_conflict_resolved': dueResolved,
      'accept_content_change': contentAccepted,
      if (controlPreviewId != null) 'control_preview_id': controlPreviewId,
      'replacements': replacements.values
          .map(
            (r) => {
              'payable_id': r['payable_id'],
              'expected_balance_cents': r['expected_balance_cents'],
              'kind': r['kind'],
              if (r['position'] != null) 'position': r['position'],
              'reason': context.l10n.financialReplacementReason,
            },
          )
          .toList(),
      'items': purposes.entries
          .map((entry) => {'position': entry.key, 'purpose': entry.value})
          .toList(),
      'reason': context.l10n.billIntegrationReason,
    };
    lock?.setActive(this, true);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await widget.service.integrateBill(
        widget.preview['id'] as String,
        frozenCommand!,
      );
      if (mounted) {
        setState(() => result = value);
        if (_scroll.hasClients) _scroll.jumpTo(0);
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode >= 400 && e.statusCode < 500) {
          frozenCommand = null;
        }
        _showFailure(e);
      }
      if (e is ApiException &&
          e.errorCode == 'FINANCIAL_BILL_REVISION_CONFLICT' &&
          mounted) {
        acknowledged = false;
        await _load();
      }
    } finally {
      lock?.setActive(this, false);
      if (mounted) setState(() => busy = false);
    }
  }

  String? _targetForFailure(Object failure) {
    if (failure is! ApiException) return null;
    return switch (failure.errorCode) {
      'FINANCIAL_BILL_DETAILS_PENDING' => 'details',
      'FINANCIAL_BILL_CONTENT_CONFLICT' => 'content',
      'FINANCIAL_BILL_REPLACEMENT_CONFLICT' ||
      'FINANCIAL_BILL_LEGACY_REVIEW' ||
      'FINANCIAL_BILL_LEGACY_PAYMENT_REVIEW' ||
      'FINANCIAL_BILL_PREVIOUS_BALANCE_LINK' ||
      'FINANCIAL_PURCHASE_ALLOCATION_REQUIRED' => 'obligations',
      'FINANCIAL_BILL_ACTIVE_DESTINATION' => 'destination',
      'FINANCIAL_BILL_CYCLE_REQUIRED' => 'header',
      'FINANCIAL_BILL_PREVIOUS_BALANCE_CONFLICT' ||
      'FINANCIAL_BILL_ROLE_CONFLICT' => 'original',
      'FINANCIAL_BILL_REVISION_CONFLICT' => 'controls',
      _ => null,
    };
  }

  bool _shouldReturnToDocuments(Object failure) =>
      failure is ApiException &&
      const {
        'FINANCIAL_BILL_CYCLE_CONFLICT',
        'FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED',
        'FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT',
      }.contains(failure.errorCode);

  String _failureMessage(Object failure, AppLocalizations l) {
    if (failure is ApiException) {
      switch (failure.errorCode) {
        case 'FINANCIAL_BILL_DETAILS_PENDING':
          return l.billIntegrationErrorDetails;
        case 'FINANCIAL_BILL_CONTENT_CONFLICT':
          return l.billIntegrationErrorContent;
        case 'FINANCIAL_BILL_REPLACEMENT_CONFLICT':
        case 'FINANCIAL_BILL_LEGACY_REVIEW':
        case 'FINANCIAL_BILL_LEGACY_PAYMENT_REVIEW':
        case 'FINANCIAL_BILL_PREVIOUS_BALANCE_LINK':
        case 'FINANCIAL_PURCHASE_ALLOCATION_REQUIRED':
          return l.billIntegrationErrorObligations;
        case 'FINANCIAL_BILL_ACTIVE_DESTINATION':
          return l.billIntegrationErrorDestination;
        case 'FINANCIAL_BILL_CYCLE_REQUIRED':
          return l.billIntegrationErrorHeader;
        case 'FINANCIAL_BILL_PREVIOUS_BALANCE_CONFLICT':
          return l.billIntegrationErrorPreviousBalance;
        case 'FINANCIAL_BILL_CYCLE_CONFLICT':
          return l.billIntegrationErrorCycle;
        case 'FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED':
          return l.billIntegrationErrorSingleCycle;
        case 'FINANCIAL_BILL_ROLE_CONFLICT':
          return l.billIntegrationErrorRole;
        case 'FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT':
          return l.billIntegrationErrorPaid;
        case 'FINANCIAL_BILL_REVISION_CONFLICT':
          return l.billIntegrationErrorRevision;
      }
    }
    return ApiErrorMapper.toLocalizedMessage(failure, l);
  }

  void _showFailure(Object failure, {bool canHighlight = true}) {
    final target = canHighlight ? _targetForFailure(failure) : null;
    setState(() {
      error = failure;
      _highlightedTarget = target;
    });
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTarget(target);
      });
    }
  }

  Future<void> _scrollToTarget(String target) async {
    final targetContext = _targetKeys[target]?.currentContext;
    if (targetContext == null) return;
    final duration = AppPalette.of(context).reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    await Scrollable.ensureVisible(
      targetContext,
      duration: duration,
      alignment: 0.22,
    );
  }

  Widget _targetFrame(String target, Widget child) {
    final highlighted = _highlightedTarget == target;
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: _targetKeys[target],
      padding: highlighted ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: highlighted
          ? ShapeDecoration(
              color: colors.errorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.error, width: 1.5),
              ),
            )
          : null,
      child: child,
    );
  }

  String? _nextRequiredTarget({
    required bool hasHeader,
    required bool dueConflict,
    required bool dueResolved,
    required bool needsDetailsAck,
    required bool requiresContentDecision,
    required bool readErrorsPresent,
  }) {
    if (readErrorsPresent) return 'readErrors';
    if (dueConflict && !dueResolved) return 'dates';
    if (!hasHeader) return 'header';
    if (needsDetailsAck && !detailAccepted) return 'details';
    if (requiresContentDecision && !contentAccepted) return 'content';
    if (!acknowledged) return 'controls';
    return null;
  }

  String _requiredTargetLabel(String target, AppLocalizations l) =>
      switch (target) {
        'dates' => l.financialDueQuestion,
        'header' => l.billIntegrationHeader,
        'details' => l.billIntegrationDetailAck,
        'content' => l.financialContentChangeAck,
        'obligations' => l.financialExistingObligations,
        'destination' => l.billIntegrationDestination,
        'readErrors' => l.financialReadProblem,
        _ => l.billIntegrationControlsAck,
      };

  Widget _feedbackNotice({
    required String message,
    String? actionLabel,
    VoidCallback? onPressed,
    required bool isError,
  }) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final color = isError ? colors.error : palette.warn;
    final fill = isError ? colors.errorContainer : palette.warnFill;
    final foreground = isError ? colors.onErrorContainer : palette.warn;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
          if (actionLabel != null && onPressed != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_downward),
                label: Text(actionLabel),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openPayable() async {
    final service = PayableService(
      client: await widget.service.forkConnection(),
    );
    if (!mounted) {
      service.close();
      return;
    }
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PayablePaymentView(
            payableId: result!['payable_id'] as String,
            coordinator: PayablePaymentCoordinator(service: service),
          ),
        ),
      );
    } finally {
      service.close();
    }
  }

  Future<void> _removeImport() async {
    final removed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FinancialImportRemovalView(
          service: widget.service,
          documentId: widget.preview['document_id'] as String,
          importContext: FinancialImportService.lifecycleContext(
            widget.preview,
          ),
        ),
      ),
    );
    if (mounted && removed == true) Navigator.pop(context);
  }

  Future<void> _original() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final document = await widget.service.get(
        '${FinancialImportService.root}/documents/${widget.preview['document_id']}',
      );
      final bytes = await widget.service.original(
        widget.preview['document_id'] as String,
      );
      if (!mounted) return;
      final pdf = (document['filename'] as String? ?? '')
          .toLowerCase()
          .endsWith('.pdf');
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ApprovedPage(
            title: context.l10n.pdfImportOriginalTitle,
            body: pdf
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
                    ),
                  ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _agenda() async {
    final service = PayableService(
      client: await widget.service.forkConnection(),
    );
    if (!mounted) {
      service.close();
      return;
    }
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FinancialInstallmentAgendaView(
            service: service,
            filters: {'source_id': widget.preview['source_id'] as String},
          ),
        ),
      );
    } finally {
      service.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasHeader =
        header['due_on'] != null && header['total_amount_cents'] != null;
    final unresolved = frozenCommand != null && result == null;
    final readErrors = {
      for (final e in draft?['read_errors'] as List? ?? []) e['code'] as String,
    };
    final dueCandidates =
        ((draft?['header_candidates'] as Map?)?['due_on'] as List? ?? [])
            .cast<Map>();
    final groupedDates = <String, Set<int>>{};
    for (final candidate in dueCandidates) {
      final pages = groupedDates.putIfAbsent(
        candidate['value'] as String,
        () => <int>{},
      );
      if (candidate['page_number'] is int) {
        pages.add(candidate['page_number'] as int);
      }
    }
    final dueConflict = dueCandidates.map((c) => c['value']).toSet().length > 1;
    final comparison = draft?['comparison'] as Map?;
    final requiresContentDecision = comparison?['requires_decision'] == true;
    final needsDetailsAck =
        draft?['readiness'] != null &&
        (draft?['readiness'] as Map?)?['details_status'] != 'RECONCILED';
    final difference =
        result?['difference_cents'] ??
        (draft?['readiness'] as Map?)?['difference_cents'];
    final nextRequiredTarget = _nextRequiredTarget(
      hasHeader: hasHeader,
      dueConflict: dueConflict,
      dueResolved: dueResolved,
      needsDetailsAck: needsDetailsAck,
      requiresContentDecision: requiresContentDecision,
      readErrorsPresent: readErrors.isNotEmpty,
    );
    return PopScope(
      canPop: !busy,
      child: ApprovedPage(
        title: l.billIntegrationTitle,
        actions: [
          IconButton(
            key: const ValueKey('remove-current-import'),
            onPressed: busy || unresolved ? null : _removeImport,
            tooltip: l.importRemovalTitle,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
        floatingActionButton: draft == null || result != null
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('bill-integrate-confirm'),
                onPressed:
                    busy ||
                        !acknowledged ||
                        readErrors.isNotEmpty ||
                        !hasHeader ||
                        (needsDetailsAck && !detailAccepted) ||
                        (dueConflict && !dueResolved) ||
                        (requiresContentDecision && !contentAccepted)
                    ? null
                    : _confirm,
                icon: const Icon(Icons.check),
                label: Text(
                  unresolved
                      ? l.billIntegrationRetry
                      : l.billIntegrationConfirm,
                ),
              ),
        body: ListView(
          controller: _scroll,
          padding: fabScrollPadding(context, horizontal: 20),
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              _feedbackNotice(
                message: _failureMessage(error!, l),
                actionLabel: _highlightedTarget != null
                    ? l.billIntegrationGoToMarkedArea
                    : _shouldReturnToDocuments(error!)
                    ? l.billIntegrationReturnToDocuments
                    : null,
                onPressed: _highlightedTarget != null
                    ? () => _scrollToTarget(_highlightedTarget!)
                    : _shouldReturnToDocuments(error!)
                    ? () {
                        Navigator.of(context).maybePop();
                      }
                    : null,
                isError: true,
              ),
            if (error == null &&
                draft != null &&
                !busy &&
                result == null &&
                nextRequiredTarget != null)
              _feedbackNotice(
                message:
                    '${l.billIntegrationRequiredStep} ${_requiredTargetLabel(nextRequiredTarget, l)}',
                actionLabel: l.billIntegrationGoToRequiredStep,
                onPressed: () => _scrollToTarget(nextRequiredTarget),
                isError: false,
              ),
            if (draft != null) ...[
              ApprovedSectionHeader(
                result == null
                    ? l.financialReadSummary
                    : l.financialRecordedResult,
              ),
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${draft!['financial_source']['name']} · ${draft!['financial_source']['institution']}',
                    ),
                    const SizedBox(height: 12),
                    if (result == null &&
                        (draft?['cycle'] as Map?)?['import_withdrawn'] == true)
                      Text(l.financialRestoredReview),
                    if (result == null && readErrors.isNotEmpty)
                      _targetFrame(
                        'readErrors',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.financialReadProblem),
                            Text(l.financialReadProblemHelp),
                            for (final code in readErrors)
                              Text(
                                ApiErrorMapper.toLocalizedMessage(
                                  ApiException(
                                    statusCode: 422,
                                    message: '',
                                    errorCode: code,
                                  ),
                                  l,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (result == null)
                      Text(
                        dueConflict && !dueResolved
                            ? l.financialDocumentDueReview
                            : !hasHeader
                            ? l.financialHeaderMissingHelp
                            : needsDetailsAck && !detailAccepted
                            ? l.financialDetailsDecisionHelp
                            : l.financialFinalDecisionHelp,
                      ),
                    if (result != null) Text(l.financialSavedReview),
                    Text(
                      l.financialReadCount(
                        (result?['items'] as List? ??
                                draft?['items'] as List? ??
                                [])
                            .length,
                      ),
                    ),
                    _targetFrame(
                      'original',
                      OutlinedButton.icon(
                        onPressed: busy ? null : _original,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(l.pdfImportOriginal),
                      ),
                    ),
                    if (result == null) ...[
                      const SizedBox(height: 12),
                      ApprovedSectionHeader(l.financialReviewQuestions),
                      Text(l.financialConfirmHelp),
                    ],
                    if (widget.preview['compiled'] == true ||
                        (draft?['control_candidates'] as List? ?? []).any(
                          (candidate) =>
                              candidate['preview_id'] == controlPreviewId &&
                              candidate['compiled'] == true,
                        ))
                      Text(l.financialCompiledControlsHelp),
                    if (widget.preview['content_type'] == 'SUMMARY_ONLY')
                      Text(l.financialSummaryOnlyHelp),
                    if (dueConflict && result == null)
                      _targetFrame(
                        'dates',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              dueResolved
                                  ? l.financialDueChosen
                                  : l.financialDueQuestion,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              dueResolved
                                  ? l.financialDueChosenHelp
                                  : l.financialDueQuestionHelp,
                            ),
                            for (final entry in groupedDates.entries)
                              OutlinedButton.icon(
                                key: ValueKey('bill-due-${entry.key}'),
                                icon: Icon(
                                  dueResolved && header['due_on'] == entry.key
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                label: Text(
                                  '${AppFormatters.formatDate(DateTime.parse(entry.key))}${entry.value.isEmpty ? '' : ' · ${l.financialPages}: ${(entry.value.toList()..sort()).join(', ')}'}',
                                ),
                                onPressed: busy || unresolved
                                    ? null
                                    : () async {
                                        setState(() {
                                          header['due_on'] = entry.key;
                                          dueResolved = true;
                                          acknowledged = false;
                                          error = null;
                                          _highlightedTarget = null;
                                        });
                                        await _load();
                                      },
                              ),
                          ],
                        ),
                      ),
                    if (requiresContentDecision && result == null) ...[
                      Text(l.financialContentConflict),
                      for (final item
                          in ((draft?['cycle'] as Map?)?['items'] as List? ??
                              []))
                        Text(
                          '${item['description']} · ${AppFormatters.formatCurrency(item['amount_cents'] as int)}',
                        ),
                      _targetFrame(
                        'content',
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: contentAccepted,
                          title: Text(l.financialContentChangeAck),
                          onChanged: busy || unresolved
                              ? null
                              : (v) => setState(() {
                                  contentAccepted = v!;
                                  acknowledged = false;
                                  error = null;
                                  _highlightedTarget = null;
                                }),
                        ),
                      ),
                    ],
                    if (difference is int && difference != 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        l.billDetailsPending,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(l.financialDifferenceHelp),
                      Text(
                        '${l.billDetailDifference}: ${AppFormatters.formatCurrency(difference)}',
                      ),
                    ],
                    if (header['total_amount_cents'] != null) ...[
                      Text(l.pdfImportTotal),
                      Text(
                        AppFormatters.formatCurrency(
                          header['total_amount_cents'] as int,
                        ),
                      ),
                      if (header['due_on'] != null &&
                          (!dueConflict || dueResolved))
                        Text(
                          '${l.pdfImportDue}: ${AppFormatters.formatDate(DateTime.parse(header['due_on'] as String))}',
                        ),
                    ],
                    if (result == null) ...[
                      if ((draft?['replacement_candidates'] as List? ?? [])
                              .isNotEmpty ||
                          _highlightedTarget == 'obligations')
                        _targetFrame(
                          'obligations',
                          (draft?['replacement_candidates'] as List? ?? [])
                                  .isNotEmpty
                              ? ExpansionTile(
                                  key: ValueKey(
                                    'financial-existing-obligations-${_highlightedTarget == 'obligations'}',
                                  ),
                                  tilePadding: EdgeInsets.zero,
                                  initiallyExpanded:
                                      _highlightedTarget == 'obligations',
                                  title: Text(l.financialExistingObligations),
                                  children: [
                                    Text(l.financialExistingObligationsHelp),
                                    for (final candidate
                                        in (draft!['replacement_candidates']
                                            as List))
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        value:
                                            replacements[candidate['payable_id']]?['position'] ==
                                                candidate['position'] &&
                                            replacements.containsKey(
                                              candidate['payable_id'],
                                            ),
                                        title: Text(
                                          '${candidate['description']} · ${AppFormatters.formatCurrency(candidate['expected_balance_cents'] as int)}',
                                        ),
                                        subtitle: Text(
                                          '${candidate['position'] == null ? l.financialPreviousObligation : l.financialPurchaseObligation} · ${candidate['due_on']}',
                                        ),
                                        onChanged: busy || unresolved
                                            ? null
                                            : (selected) => setState(() {
                                                if (selected!) {
                                                  replacements[candidate['payable_id']
                                                          as String] =
                                                      Map<String, dynamic>.from(
                                                        candidate as Map,
                                                      );
                                                } else {
                                                  replacements.remove(
                                                    candidate['payable_id'],
                                                  );
                                                }
                                                acknowledged = false;
                                                error = null;
                                                _highlightedTarget = null;
                                              }),
                                      ),
                                  ],
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.financialExistingObligations,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(l.billIntegrationErrorObligations),
                                    ],
                                  ),
                                ),
                        ),
                      if (!hasHeader &&
                          (draft?['control_candidates'] as List? ?? [])
                              .isNotEmpty) ...[
                        Text(l.financialControlChoose),
                        for (final candidate
                            in (draft!['control_candidates'] as List))
                          TextButton(
                            onPressed: busy || unresolved
                                ? null
                                : () async {
                                    setState(() {
                                      header = {
                                        ...header,
                                        'due_on': candidate['due_on'],
                                        'total_amount_cents':
                                            candidate['total_amount_cents'],
                                      };
                                      controlPreviewId =
                                          candidate['preview_id'] as String;
                                      acknowledged = false;
                                      error = null;
                                      _highlightedTarget = null;
                                    });
                                    await _load();
                                  },
                            child: Text(
                              '${AppFormatters.formatDate(DateTime.parse(candidate['due_on'] as String))} · ${AppFormatters.formatCurrency(candidate['total_amount_cents'] as int)}',
                            ),
                          ),
                      ],
                      if (!hasHeader &&
                          !(dueConflict &&
                              header['total_amount_cents'] != null))
                        Text(l.financialHeaderMissingHelp),
                      if (!dueConflict ||
                          dueResolved ||
                          header['total_amount_cents'] == null)
                        _targetFrame(
                          'header',
                          TextButton(
                            onPressed: busy || unresolved ? null : _header,
                            child: Text(l.billIntegrationHeader),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(l.financialDestinationHelp),
                      _targetFrame(
                        'destination',
                        DropdownButtonFormField<String>(
                          initialValue: destination,
                          isExpanded: true,
                          isDense: false,
                          decoration: InputDecoration(
                            labelText: l.billIntegrationDestination,
                          ),
                          itemHeight: null,
                          items: [
                            DropdownMenuItem(
                              value: 'PENDING',
                              child: Text(l.billIntegrationPending),
                            ),
                            DropdownMenuItem(
                              value: 'HISTORY',
                              child: Text(l.billIntegrationHistory),
                            ),
                            DropdownMenuItem(
                              value: 'OPEN',
                              child: Text(l.billIntegrationOpen),
                            ),
                          ],
                          onChanged: busy || unresolved
                              ? null
                              : (value) => setState(() {
                                  destination = value!;
                                  acknowledged = false;
                                  error = null;
                                  _highlightedTarget = null;
                                }),
                        ),
                      ),
                      if ((draft?['items'] as List? ?? []).any(
                        (i) =>
                            i['installment_number'] != null &&
                            (i['installment_number'] as int) <
                                (i['total_installments'] as int),
                      ))
                        CheckboxListTile(
                          value: estimateInstallmentDay,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.installmentUseDay),
                          subtitle: Text(l.installmentUseDayHelp),
                          onChanged: busy || unresolved
                              ? null
                              : (v) =>
                                    setState(() => estimateInstallmentDay = v!),
                        ),
                      if (needsDetailsAck)
                        _targetFrame(
                          'details',
                          CheckboxListTile(
                            key: const ValueKey('bill-details-ack'),
                            value: detailAccepted,
                            contentPadding: EdgeInsets.zero,
                            title: Text(l.billIntegrationDetailAck),
                            onChanged: busy || unresolved
                                ? null
                                : (v) => setState(() {
                                    detailAccepted = v!;
                                    acknowledged = false;
                                    error = null;
                                    _highlightedTarget = null;
                                  }),
                          ),
                        ),
                      _targetFrame(
                        'controls',
                        CheckboxListTile(
                          value: acknowledged,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.billIntegrationControlsAck),
                          onChanged: busy || unresolved
                              ? null
                              : (v) => setState(() {
                                  acknowledged = v!;
                                  error = null;
                                  _highlightedTarget = null;
                                }),
                        ),
                      ),
                    ],
                    if (result != null) ...[
                      const SizedBox(height: 12),
                      if (result!['payable_id'] != null &&
                          result!['balance_cents'] is int)
                        Text(
                          '${l.payableBalance}: ${AppFormatters.formatCurrency(result!['balance_cents'] as int)}',
                        ),
                      Text(
                        result!['destination'] == 'OPEN'
                            ? l.billIntegrationSuccess
                            : result!['destination'] == 'CREDIT'
                            ? l.financialCreditSaved
                            : result!['destination'] == 'PENDING'
                            ? l.financialPendingSaved
                            : l.billIntegrationEvidenceSaved,
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : _agenda,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(l.installmentAgendaTitle),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                editingSaved = true;
                                if (result!['payable_id'] == null &&
                                    (header['total_amount_cents'] as int? ??
                                            0) >
                                        0) {
                                  destination = 'OPEN';
                                }
                                draft!['expected_revision'] =
                                    result!['revision'];
                                result = null;
                                frozenCommand = null;
                                acknowledged = false;
                                detailAccepted = false;
                              }),
                        child: Text(
                          result!['payable_id'] == null &&
                                  (header['total_amount_cents'] as int? ?? 0) >
                                      0
                              ? l.financialAddSavedBill
                              : l.financialEditSavedReview,
                        ),
                      ),
                      if (result!['payable_id'] != null)
                        FilledButton.icon(
                          onPressed: _openPayable,
                          icon: const Icon(Icons.receipt_long),
                          label: Text(l.billIntegrationOpenPayable),
                        ),
                    ],
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(l.financialImportHowItWorks),
                      children: [Text(l.billIntegrationHelp)],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ApprovedSectionHeader(l.billItemsTitle),
              Text(l.financialItemsHelp),
            ],
            for (final item
                in (result?['items'] as List? ??
                    draft?['items'] as List? ??
                    [])) ...[
              const SizedBox(height: 12),
              ApprovedSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['description'] as String),
                    if (item['transaction_date'] is String)
                      Text(
                        AppFormatters.formatDate(
                          DateTime.parse(item['transaction_date'] as String),
                        ),
                      ),
                    if (item['observation'] is String)
                      Text(item['observation'] as String),
                    Text(
                      AppFormatters.formatCurrency(item['amount_cents'] as int),
                    ),
                    if (item['installment_number'] != null)
                      Text(
                        l.pdfImportInstallments(
                          item['installment_number'] as int,
                          item['total_installments'] as int,
                        ),
                      ),
                    if (result == null && item['position'] is int)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(l.financialPurposeOptional),
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue:
                                purposes[item['position']] ?? 'UNSPECIFIED',
                            items: [
                              DropdownMenuItem(
                                value: 'UNSPECIFIED',
                                child: Text(l.billPurposeUnknown),
                              ),
                              DropdownMenuItem(
                                value: 'BUSINESS',
                                child: Text(l.payableNatureBusiness),
                              ),
                              DropdownMenuItem(
                                value: 'PERSONAL_WITHDRAWAL',
                                child: Text(l.payableNaturePersonal),
                              ),
                            ],
                            onChanged: busy || unresolved
                                ? null
                                : (v) => setState(() {
                                    purposes[item['position'] as int] = v!;
                                    acknowledged = false;
                                  }),
                          ),
                        ],
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
