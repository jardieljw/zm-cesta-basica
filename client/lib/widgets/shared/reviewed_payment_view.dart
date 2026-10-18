import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_extension.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/api_error_mapper.dart';
import '../../utils/business_dates.dart';
import '../../utils/formatters.dart';
import '../../utils/money_input.dart';
import 'animated_reveal.dart';
import 'financial_surface.dart';
import 'approved_app_style.dart';
import 'app_operation_scope.dart';
import 'reviewed_payment_contract.dart';

enum _PaymentStep { detail, form, review, pending, confirmed }

/// One interaction state machine for reviewed financial records. Adapters own
/// the module's identifiers, methods, wording and server coordinator.
class ReviewedPaymentView<T, C, A> extends StatefulWidget {
  final String titleId;
  final ReviewedPaymentAdapter<T, C, A> adapter;
  const ReviewedPaymentView({
    super.key,
    required this.titleId,
    required this.adapter,
  });
  @override
  State<ReviewedPaymentView<T, C, A>> createState() =>
      _ReviewedPaymentViewState<T, C, A>();
}

class _ReviewedPaymentViewState<T, C, A>
    extends State<ReviewedPaymentView<T, C, A>> {
  ReviewedPaymentAdapter<T, C, A> get adapter => widget.adapter;
  ReviewedPaymentLabels get words => adapter.labels(context.l10n);
  ReviewedPaymentTitle get current =>
      adapter.describeTitle(_title as T, context.l10n);
  ReviewedPaymentAttempt<C> get attempt =>
      adapter.describeAttempt(_attempt as A, context.l10n);
  final _amount = TextEditingController(), _notes = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _amountFocus = FocusNode();
  final _methodFocus = FocusNode();
  _PaymentStep _step = _PaymentStep.detail;
  T? _title;
  ApiOrigin? _origin;
  A? _attempt;
  C? _review;
  bool _loading = true,
      _busyValue = false,
      _partial = false,
      _refreshing = false;
  AppOperationLock? _operationLock;
  bool get _busy => _busyValue;
  set _busy(bool value) {
    _busyValue = value;
    _operationLock?.setActive(this, value);
  }

  String? _error, _message, _queryError, _method;
  DateTime _day = BusinessDates.today();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lock = AppOperationScope.maybeOf(context);
    if (_operationLock != lock) {
      _operationLock?.setActive(this, false);
      _operationLock = lock;
      lock?.setActive(this, _busy);
    }
  }

  @override
  void dispose() {
    _operationLock?.setActive(this, false);
    _amount.dispose();
    _notes.dispose();
    _amountFocus.dispose();
    _methodFocus.dispose();
    super.dispose();
  }

  String _friendly(Object e) => e is ApiException
      ? ApiErrorMapper.toLocalizedMessage(e, context.l10n)
      : context.l10n.paymentFlowUnexpected;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
      _title = null;
      _queryError = null;
    });
    try {
      final origin = await adapter.readOrigin();
      final attempt = await adapter.attemptFor(widget.titleId, origin);
      if (!mounted) return;
      setState(() {
        _origin = origin;
        _attempt = attempt;
        _step = attempt == null
            ? _PaymentStep.detail
            : adapter.describeAttempt(attempt, context.l10n).confirmationId ==
                  null
            ? _PaymentStep.pending
            : _PaymentStep.confirmed;
      });
      await _refreshDetail();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDetail() async {
    if (_origin == null) return;
    setState(() {
      _refreshing = true;
      _queryError = null;
    });
    try {
      final title = await adapter.getTitle(widget.titleId, _origin!);
      if (!mounted) return;
      setState(() => _title = title);
    } catch (e) {
      if (mounted) setState(() => _queryError = _friendly(e));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool get _open =>
      _title != null &&
      {'OPEN', 'PARTIAL'}.contains(current.status) &&
      current.balanceCents > 0;
  int? get _value => _partial
      ? MoneyInput.cents(_amount.text)
      : (_title == null ? null : current.balanceCents);
  String _methodName(String code, AppLocalizations l) =>
      adapter.methodName(code, l);
  String _statusName(String code, AppLocalizations l) =>
      adapter.statusName(code, l);

  Future<void> _prepareReview() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) {
      final value = _value;
      final focus =
          _partial &&
              (value == null || value <= 0 || value > current.balanceCents)
          ? _amountFocus
          : _methodFocus;
      focus.requestFocus();
      if (focus.context != null) {
        await Scrollable.ensureVisible(
          focus.context!,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final previous = current;
      final latest = await adapter.getTitle(widget.titleId, _origin!);
      if (!mounted) return;
      final latestView = adapter.describeTitle(latest, context.l10n);
      if (latestView.reviewVersion < 1) {
        throw ApiException(
          statusCode: 0,
          message: 'Server update required',
          errorCode: 'PAYMENT_SERVER_UPDATE_REQUIRED',
        );
      }
      if (latestView.balanceCents != previous.balanceCents ||
          latestView.status != previous.status) {
        setState(() {
          _title = latest;
          _message = context.l10n.paymentFlowBalanceChanged;
          if (!_open) _step = _PaymentStep.detail;
        });
        return;
      }
      setState(() {
        _title = latest;
        _review = adapter.createCommand(
          amountCents: _value!,
          method: _method!,
          businessDate: BusinessDates.iso(_day),
          expectedBalanceCents: latestView.balanceCents,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
        _step = _PaymentStep.review;
      });
    } catch (e) {
      if (mounted) setState(() => _message = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send({bool resume = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final receipt = resume
          ? await adapter.resume(_attempt as A)
          : await adapter.submit(_title as T, _review as C, _origin!);
      if (!mounted) return;
      setState(() {
        _attempt = receipt;
        _step = _PaymentStep.confirmed;
      });
      await _refreshDetail();
    } catch (e) {
      if (!mounted) return;
      final message = _friendly(e);
      try {
        final pending = await adapter.attemptFor(widget.titleId, _origin!);
        if (!mounted) return;
        setState(() {
          _attempt = pending;
          _review = null;
          _message = message;
          _step = pending == null
              ? _PaymentStep.form
              : adapter.describeAttempt(pending, context.l10n).confirmationId ==
                    null
              ? _PaymentStep.pending
              : _PaymentStep.confirmed;
        });
        if (pending == null) {
          await _refreshDetail();
          if (mounted && !_open) setState(() => _step = _PaymentStep.detail);
        }
      } catch (readError) {
        if (mounted) setState(() => _error = _friendly(readError));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await adapter.acknowledge(_attempt as A);
      if (mounted) {
        _busy = false;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = _friendly(e);
        });
      }
    }
  }

  Widget _line(String label, String value, {bool amount = false}) => Padding(
    padding: EdgeInsets.symmetric(vertical: amount ? 8 : 13),
    child: LayoutBuilder(
      builder: (context, box) {
        final caption = Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        );
        final content = Text(
          value,
          style: amount ? Theme.of(context).textTheme.headlineMedium : null,
        );
        if (amount ||
            box.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(15) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [caption, const SizedBox(height: 4), content],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: caption),
            const SizedBox(width: 16),
            Flexible(child: content),
          ],
        );
      },
    ),
  );

  Widget _context(String name, {String? reference, String? description}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.bodySmall),
            if (description?.isNotEmpty == true)
              Text(description!, style: Theme.of(context).textTheme.bodySmall),
            if (reference != null)
              Text(reference, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  Widget _action(String text, VoidCallback? callback, {Key? key}) =>
      FilledButton(
        key: key,
        onPressed: _busy ? null : callback,
        child: Text(text, textAlign: TextAlign.center),
      );

  Widget _notice(String text) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );

  Widget _detail(AppLocalizations l) {
    if (_title == null || _queryError != null) return _queryFailure(l);
    final title = current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _context(
          title.name,
          reference: title.reference,
          description: title.description,
        ),
        FinancialSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line(
                l.paymentFlowBalance,
                AppFormatters.formatCurrency(title.balanceCents),
                amount: true,
              ),
              _line(
                words.originalAmount,
                AppFormatters.formatCurrency(title.originalAmountCents),
              ),
              const Divider(),
              _line(
                words.paidAmount,
                AppFormatters.formatCurrency(title.paidAmountCents),
              ),
              const Divider(),
              _line(words.dueDate, AppFormatters.formatDate(title.dueDate)),
              const Divider(),
              _line(l.paymentFlowSituation, _statusName(title.status, l)),
              if (adapter.originAction(context, _title as T, _origin!)
                  case final action?)
                action,
              if (_open)
                _action(
                  words.register,
                  title.reviewVersion < 1
                      ? null
                      : () => setState(() {
                          _step = _PaymentStep.form;
                          _message = null;
                        }),
                  key: const ValueKey('payment-start'),
                ),
              if (_open && title.reviewVersion < 1) _notice(words.serverUpdate),
              if (!_open) Text(words.notOpen),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FinancialSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                words.history,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (title.payments.isEmpty) Text(words.noHistory),
              for (final payment in title.payments) ...[
                const Divider(),
                _line(
                  AppFormatters.formatDate(BusinessDates.dayOf(payment.date)),
                  AppFormatters.formatCurrency(payment.amountCents),
                ),
                Text(_methodName(payment.method, l)),
                if (payment.status == 'REVERSED') Text(l.paymentFlowReversed),
                if (payment.reversalReason?.isNotEmpty == true)
                  Text(l.receiptFlowReversalReason(payment.reversalReason!)),
                if (payment.notes?.isNotEmpty == true) Text(payment.notes!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _formContent(AppLocalizations l) {
    final title = current;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _context(title.name),
          FinancialSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(
                  l.paymentFlowBalance,
                  AppFormatters.formatCurrency(title.balanceCents),
                  amount: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FinancialSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(words.kind),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l.paymentFlowFull)),
                    ButtonSegment(
                      value: true,
                      label: Text(l.paymentFlowPartial),
                    ),
                  ],
                  selected: {_partial},
                  onSelectionChanged: _busy
                      ? null
                      : (value) => setState(() => _partial = value.single),
                ),
                AnimatedReveal(
                  visible: _partial,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: TextFormField(
                      key: const ValueKey('payment-amount'),
                      controller: _amount,
                      focusNode: _amountFocus,
                      enabled: _partial && !_busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: words.amount,
                        prefixText: '${AppFormatters.defaultCurrencySymbol} ',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (text) {
                        if (!_partial) return null;
                        final value = MoneyInput.cents(text ?? '');
                        return value == null ||
                                value <= 0 ||
                                value > title.balanceCents
                            ? l.paymentFlowAmountLimit(
                                AppFormatters.formatCurrency(
                                  title.balanceCents,
                                ),
                              )
                            : null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const ValueKey('payment-date'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _day,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(9999, 12, 31),
                          );
                          if (picked != null && mounted) {
                            setState(() => _day = picked);
                          }
                        },
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '${words.date}: ${AppFormatters.formatDate(_day)}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: const ValueKey('payment-method'),
                  focusNode: _methodFocus,
                  initialValue: _method,
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  decoration: InputDecoration(labelText: words.method),
                  hint: Text(words.selectMethod),
                  items: adapter.methods
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_methodName(value, l)),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _method = value),
                  validator: (value) =>
                      value == null ? words.selectMethod : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const ValueKey('payment-notes'),
                  controller: _notes,
                  enabled: !_busy,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l.commonNotes),
                ),
                const SizedBox(height: 20),
                _line(
                  l.paymentFlowRemaining,
                  _value != null && _value! > 0 && _value! <= title.balanceCents
                      ? AppFormatters.formatCurrency(
                          title.balanceCents - _value!,
                        )
                      : '—',
                ),
                _action(
                  words.review,
                  _prepareReview,
                  key: const ValueKey('payment-review'),
                ),
                const SizedBox(height: 12),
                Text(
                  words.recordedOnly,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _command(
    C source,
    String name,
    AppLocalizations l, {
    bool confirmed = false,
    String? description,
    required String reference,
    List<Widget> actions = const [],
  }) {
    final command = adapter.describeCommand(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _context(name, reference: reference, description: description),
        FinancialSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line(
                l.paymentFlowValue,
                AppFormatters.formatCurrency(command.amountCents),
                amount: true,
              ),
              _line(
                l.appReviewType,
                command.amountCents == command.expectedBalanceCents
                    ? l.appReviewFull
                    : l.paymentFlowPartial,
              ),
              const Divider(),
              _line(
                words.date,
                AppFormatters.formatDate(
                  BusinessDates.parse(command.businessDate),
                ),
              ),
              const Divider(),
              _line(words.method, _methodName(command.method, l)),
              const Divider(),
              _line(l.commonNotes, command.notes ?? l.appReviewNoNote),
              const Divider(),
              _line(
                confirmed
                    ? l.paymentFlowRecordedRemaining
                    : l.appReviewExpectedBalance,
                AppFormatters.formatCurrency(
                  command.expectedBalanceCents - command.amountCents,
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...actions,
                const SizedBox(height: 12),
                Text(
                  l.appReviewHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewContent(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _command(
        _review as C,
        current.name,
        l,
        description: current.description,
        reference: current.reference,
        actions: [
          _action(
            _busy ? l.paymentFlowSending : l.commonConfirm,
            () => _send(),
            key: const ValueKey('payment-confirm'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _step = _PaymentStep.form),
            child: Text(l.commonEdit),
          ),
        ],
      ),
    ],
  );

  Widget _pendingContent(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        l.paymentFlowUncertain,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Text(words.resumeHelp),
      const SizedBox(height: 20),
      _command(
        attempt.command,
        attempt.name,
        l,
        description: attempt.description,
        reference: attempt.reference,
      ),
      const SizedBox(height: 20),
      _action(
        _busy ? l.paymentFlowSending : l.paymentFlowResume,
        () => _send(resume: true),
        key: const ValueKey('payment-resume'),
      ),
    ],
  );

  Widget _confirmedContent(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          words.confirmed,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 20),
      _command(
        attempt.command,
        attempt.name,
        l,
        confirmed: true,
        description: attempt.description,
        reference: attempt.reference,
      ),
      _line(l.paymentFlowReference, attempt.confirmationId!),
      if (_refreshing) Text(words.refreshing),
      if (_queryError != null) ...[
        Text(words.confirmedRefreshFailed),
        _queryFailure(l),
      ],
      if (!_refreshing && _queryError == null && _title != null)
        _line(
          l.paymentFlowCurrentBalance,
          AppFormatters.formatCurrency(current.balanceCents),
          amount: true,
        ),
      const SizedBox(height: 20),
      _action(
        l.paymentFlowFinish,
        _finish,
        key: const ValueKey('payment-finish'),
      ),
    ],
  );

  Widget _queryFailure(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_queryError ?? l.paymentFlowUnexpected),
      TextButton(
        onPressed: _refreshing ? null : _refreshDetail,
        child: Text(l.commonRefresh),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (_step) {
      _PaymentStep.form => words.register,
      _PaymentStep.review => words.review,
      _PaymentStep.pending => l.paymentFlowResume,
      _PaymentStep.confirmed => words.confirmed,
      _ => words.detail,
    };
    return FinancialJourneyTheme(
      child: PopScope(
        canPop:
            !_busy && !{_PaymentStep.form, _PaymentStep.review}.contains(_step),
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _busy) return;
          setState(() {
            _step = _step == _PaymentStep.review
                ? _PaymentStep.form
                : _PaymentStep.detail;
            _message = null;
          });
        },
        child: ApprovedPage(
          title: title,
          body: SafeArea(
            top: false,
            child: SizedBox.expand(
              child: _loading
                  ? Center(
                      child: Semantics(
                        label: l.commonLoading,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_busy || _refreshing)
                                const LinearProgressIndicator(),
                              if (_error != null) ...[
                                _notice(_error!),
                                _action(l.commonRefresh, _load),
                              ] else ...[
                                if (_message != null) _notice(_message!),
                                switch (_step) {
                                  _PaymentStep.detail => _detail(l),
                                  _PaymentStep.form => _formContent(l),
                                  _PaymentStep.review => _reviewContent(l),
                                  _PaymentStep.pending => _pendingContent(l),
                                  _PaymentStep.confirmed => _confirmedContent(
                                    l,
                                  ),
                                },
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
