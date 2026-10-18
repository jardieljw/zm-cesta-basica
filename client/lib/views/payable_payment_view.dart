import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/app_localizations.dart';
import '../models/account_payable.dart';
import '../services/payable_payment_coordinator.dart';
import '../widgets/shared/reviewed_payment_contract.dart';
import '../widgets/shared/reviewed_payment_view.dart';

class PayablePaymentView extends StatelessWidget {
  final String payableId;
  final PayablePaymentCoordinator coordinator;
  const PayablePaymentView({
    super.key,
    required this.payableId,
    required this.coordinator,
  });
  @override
  Widget build(BuildContext context) =>
      ReviewedPaymentView<
        AccountPayable,
        PayablePaymentCreate,
        PayablePaymentAttempt
      >(titleId: payableId, adapter: _PayableAdapter(coordinator));
}

class _PayableAdapter
    extends
        ReviewedPaymentAdapter<
          AccountPayable,
          PayablePaymentCreate,
          PayablePaymentAttempt
        > {
  final PayablePaymentCoordinator coordinator;
  _PayableAdapter(this.coordinator);
  @override
  Future<ApiOrigin> readOrigin() => coordinator.service.readOrigin();
  @override
  Future<PayablePaymentAttempt?> attemptFor(String id, ApiOrigin origin) =>
      coordinator.attemptFor(id, origin);
  @override
  Future<AccountPayable> getTitle(String id, ApiOrigin origin) =>
      coordinator.serviceFor(origin).getPayable(id);
  @override
  ReviewedPaymentTitle describeTitle(
    AccountPayable title,
    AppLocalizations l,
  ) => ReviewedPaymentTitle(
    name: title.beneficiary,
    description: title.description,
    reference: l.paymentFlowTitleRef(title.payableNumber),
    status: title.status,
    balanceCents: title.balanceCents,
    originalAmountCents: title.originalAmountCents,
    paidAmountCents: title.paidAmountCents,
    dueDate: title.dueDate,
    reviewVersion: title.paymentReviewVersion,
    payments: title.payments
        .map(
          (p) => ReviewedPaymentHistory(
            date: p.paymentDate,
            amountCents: p.amountCents,
            method: p.paymentMethod,
            status: p.status,
            notes: p.notes,
          ),
        )
        .toList(),
  );
  @override
  ReviewedPaymentCommand describeCommand(PayablePaymentCreate command) =>
      ReviewedPaymentCommand(
        amountCents: command.amountCents,
        expectedBalanceCents: command.expectedBalanceCents!,
        method: command.paymentMethod,
        businessDate: command.paymentBusinessDate!,
        notes: command.notes,
      );
  @override
  ReviewedPaymentAttempt<PayablePaymentCreate> describeAttempt(
    PayablePaymentAttempt attempt,
    AppLocalizations l,
  ) => ReviewedPaymentAttempt(
    command: attempt.command,
    name: attempt.beneficiary,
    description: attempt.description,
    reference: l.paymentFlowTitleRef(attempt.payableNumber),
    confirmationId: attempt.confirmation?.id,
  );
  @override
  PayablePaymentCreate createCommand({
    required int amountCents,
    required String method,
    required String businessDate,
    required int expectedBalanceCents,
    String? notes,
  }) => PayablePaymentCreate(
    amountCents: amountCents,
    paymentMethod: method,
    paymentBusinessDate: businessDate,
    expectedBalanceCents: expectedBalanceCents,
    notes: notes,
  );
  @override
  Future<PayablePaymentAttempt> submit(
    AccountPayable title,
    PayablePaymentCreate command,
    ApiOrigin origin,
  ) => coordinator.submit(title, command, origin);
  @override
  Future<PayablePaymentAttempt> resume(PayablePaymentAttempt attempt) =>
      coordinator.resume(attempt);
  @override
  Future<void> acknowledge(PayablePaymentAttempt attempt) =>
      coordinator.acknowledge(attempt);
  @override
  Set<String> get methods => payablePaymentMethods;
  @override
  String statusName(String status, AppLocalizations l) => switch (status) {
    'OPEN' => l.payableStatusOpen,
    'PARTIAL' => l.payableStatusPartial,
    'PAID' => l.payableStatusPaid,
    _ => l.payableStatusCanceled,
  };
  @override
  String methodName(String method, AppLocalizations l) => switch (method) {
    'DINHEIRO' => l.payablePaymentMethodCash,
    'PIX' => l.payablePaymentMethodPix,
    'BOLETO' => l.payablePaymentMethodBoleto,
    'TRANSFERENCIA' => l.payablePaymentMethodTransfer,
    'CHEQUE' => l.payablePaymentMethodCheck,
    'CARTAO_CREDITO' => l.payablePaymentMethodCard,
    _ => l.payablePaymentMethodOther,
  };
  @override
  ReviewedPaymentLabels labels(AppLocalizations l) => ReviewedPaymentLabels(
    detail: l.paymentFlowDetail,
    register: l.paymentFlowRegister,
    review: l.paymentFlowReview,
    confirmed: l.paymentFlowConfirmed,
    noHistory: l.paymentFlowNoHistory,
    notOpen: l.paymentFlowNotOpen,
    kind: l.paymentFlowKind,
    amount: l.paymentFlowAmount,
    date: l.paymentFlowDate,
    method: l.paymentFlowMethod,
    selectMethod: l.paymentFlowSelectMethod,
    recordedOnly: l.paymentFlowRecordedOnly,
    resumeHelp: l.paymentFlowResumeHelp,
    refreshing: l.paymentFlowRefreshing,
    confirmedRefreshFailed: l.paymentFlowConfirmedRefreshFailed,
    serverUpdate: l.paymentFlowServerUpdate,
    originalAmount: l.payableOriginalAmount,
    paidAmount: l.payablePaidAmount,
    dueDate: l.payableDueDate,
    history: l.payableHistoryAction,
  );
}
