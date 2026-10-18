import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/app_localizations.dart';
import '../models/sales_receivable.dart';
import '../services/receivable_payment_coordinator.dart';
import '../widgets/shared/reviewed_payment_contract.dart';
import '../widgets/shared/reviewed_payment_view.dart';
import '../l10n/l10n_extension.dart';
import 'sale_origin_view.dart';

class ReceivablePaymentView extends StatelessWidget {
  final String receivableId;
  final ReceivablePaymentCoordinator coordinator;
  const ReceivablePaymentView({
    super.key,
    required this.receivableId,
    required this.coordinator,
  });
  @override
  Widget build(BuildContext context) =>
      ReviewedPaymentView<
        SalesReceivable,
        ReceivablePaymentCreate,
        ReceivablePaymentAttempt
      >(titleId: receivableId, adapter: _ReceivableAdapter(coordinator));
}

class _ReceivableAdapter
    extends
        ReviewedPaymentAdapter<
          SalesReceivable,
          ReceivablePaymentCreate,
          ReceivablePaymentAttempt
        > {
  final ReceivablePaymentCoordinator coordinator;
  _ReceivableAdapter(this.coordinator);
  @override
  Future<ApiOrigin> readOrigin() => coordinator.service.readOrigin();
  @override
  Future<ReceivablePaymentAttempt?> attemptFor(String id, ApiOrigin origin) =>
      coordinator.attemptFor(id, origin);
  @override
  Future<SalesReceivable> getTitle(String id, ApiOrigin origin) =>
      coordinator.serviceFor(origin).getReceivable(id);
  @override
  ReviewedPaymentTitle describeTitle(
    SalesReceivable title,
    AppLocalizations l,
  ) => ReviewedPaymentTitle(
    name: title.customerName,
    description: title.basketTypesSummary,
    reference: l.receiptFlowSaleRef(title.saleNumber),
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
            reversalReason: p.reversalReason,
          ),
        )
        .toList(),
  );
  @override
  ReviewedPaymentCommand describeCommand(ReceivablePaymentCreate command) =>
      ReviewedPaymentCommand(
        amountCents: command.amountCents,
        expectedBalanceCents: command.expectedBalanceCents!,
        method: command.paymentMethod,
        businessDate: command.paymentBusinessDate!,
        notes: command.notes,
      );
  @override
  ReviewedPaymentAttempt<ReceivablePaymentCreate> describeAttempt(
    ReceivablePaymentAttempt attempt,
    AppLocalizations l,
  ) => ReviewedPaymentAttempt(
    command: attempt.command,
    name: attempt.customerName,
    description: null,
    reference: l.receiptFlowSaleRef(attempt.saleNumber),
    confirmationId: attempt.confirmation?.id,
  );
  @override
  ReceivablePaymentCreate createCommand({
    required int amountCents,
    required String method,
    required String businessDate,
    required int expectedBalanceCents,
    String? notes,
  }) => ReceivablePaymentCreate(
    amountCents: amountCents,
    paymentMethod: method,
    paymentBusinessDate: businessDate,
    expectedBalanceCents: expectedBalanceCents,
    notes: notes,
  );
  @override
  Future<ReceivablePaymentAttempt> submit(
    SalesReceivable title,
    ReceivablePaymentCreate command,
    ApiOrigin origin,
  ) => coordinator.submit(title, command, origin);
  @override
  Future<ReceivablePaymentAttempt> resume(ReceivablePaymentAttempt attempt) =>
      coordinator.resume(attempt);
  @override
  Future<void> acknowledge(ReceivablePaymentAttempt attempt) =>
      coordinator.acknowledge(attempt);
  @override
  Set<String> get methods => receivablePaymentMethods;
  @override
  String statusName(String status, AppLocalizations l) => switch (status) {
    'OPEN' => l.receivableStatusOpen,
    'PARTIAL' => l.receivableStatusPartial,
    'PAID' => l.receivableStatusPaid,
    _ => l.receivableStatusCanceled,
  };
  @override
  String methodName(String method, AppLocalizations l) => switch (method) {
    'CASH' => l.receiptFlowCash,
    'PIX' => l.salePaymentModePix,
    'CARD' => l.salePaymentModeCard,
    _ => l.payablePaymentMethodOther,
  };
  @override
  ReviewedPaymentLabels labels(AppLocalizations l) => ReviewedPaymentLabels(
    detail: l.receiptFlowDetail,
    register: l.receiptFlowRegister,
    review: l.receiptFlowReview,
    confirmed: l.receiptFlowConfirmed,
    noHistory: l.receiptFlowNoHistory,
    notOpen: l.receiptFlowNotOpen,
    kind: l.receiptFlowKind,
    amount: l.receiptFlowAmount,
    date: l.receiptFlowDate,
    method: l.receiptFlowMethod,
    selectMethod: l.receiptFlowSelectMethod,
    recordedOnly: l.receiptFlowRecordedOnly,
    resumeHelp: l.receiptFlowResumeHelp,
    refreshing: l.receiptFlowRefreshing,
    confirmedRefreshFailed: l.receiptFlowConfirmedRefreshFailed,
    serverUpdate: l.receiptFlowServerUpdate,
    originalAmount: l.receivableOriginalAmount,
    paidAmount: l.receivablePaidAmount,
    dueDate: l.saleDueDate,
    history: l.receivablePaymentsHistory,
  );
  @override
  Widget originAction(
    BuildContext context,
    SalesReceivable title,
    ApiOrigin origin,
  ) => TextButton.icon(
    key: const ValueKey('payment-origin'),
    icon: const Icon(Icons.receipt_long_outlined),
    label: Text(context.l10n.receiptFlowOrigin),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SaleOriginView(
          saleId: title.saleId,
          saleNumber: title.saleNumber,
          load: () =>
              coordinator.serviceFor(origin).getOriginSale(title.saleId),
        ),
      ),
    ),
  );
}
