import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';

/// Presentation data only. Financial validation and persistence stay in domain
/// services; typed adapters keep payable and receivable contracts separate.
class ReviewedPaymentTitle {
  final String name, reference, status;
  final String? description;
  final int balanceCents, originalAmountCents, paidAmountCents, reviewVersion;
  final DateTime dueDate;
  final List<ReviewedPaymentHistory> payments;
  const ReviewedPaymentTitle({
    required this.name,
    required this.reference,
    required this.status,
    this.description,
    required this.balanceCents,
    required this.originalAmountCents,
    required this.paidAmountCents,
    required this.reviewVersion,
    required this.dueDate,
    required this.payments,
  });
}

class ReviewedPaymentHistory {
  final DateTime date;
  final int amountCents;
  final String method, status;
  final String? notes, reversalReason;
  const ReviewedPaymentHistory({
    required this.date,
    required this.amountCents,
    required this.method,
    required this.status,
    this.notes,
    this.reversalReason,
  });
}

class ReviewedPaymentCommand {
  final int amountCents, expectedBalanceCents;
  final String method, businessDate;
  final String? notes;
  const ReviewedPaymentCommand({
    required this.amountCents,
    required this.expectedBalanceCents,
    required this.method,
    required this.businessDate,
    this.notes,
  });
}

class ReviewedPaymentAttempt<C> {
  final C command;
  final String name, reference;
  final String? description, confirmationId;
  const ReviewedPaymentAttempt({
    required this.command,
    required this.name,
    required this.reference,
    this.description,
    this.confirmationId,
  });
}

class ReviewedPaymentLabels {
  final String detail, register, review, confirmed, noHistory, notOpen, kind;
  final String amount, date, method, selectMethod, recordedOnly, resumeHelp;
  final String refreshing, confirmedRefreshFailed, originalAmount, paidAmount;
  final String dueDate, history, serverUpdate;
  const ReviewedPaymentLabels({
    required this.detail,
    required this.register,
    required this.review,
    required this.confirmed,
    required this.noHistory,
    required this.notOpen,
    required this.kind,
    required this.amount,
    required this.date,
    required this.method,
    required this.selectMethod,
    required this.recordedOnly,
    required this.resumeHelp,
    required this.refreshing,
    required this.confirmedRefreshFailed,
    required this.originalAmount,
    required this.paidAmount,
    required this.dueDate,
    required this.history,
    required this.serverUpdate,
  });
}

abstract class ReviewedPaymentAdapter<T, C, A> {
  Future<ApiOrigin> readOrigin();
  Future<A?> attemptFor(String id, ApiOrigin origin);
  Future<T> getTitle(String id, ApiOrigin origin);
  ReviewedPaymentTitle describeTitle(T title, AppLocalizations l);
  ReviewedPaymentCommand describeCommand(C command);
  ReviewedPaymentAttempt<C> describeAttempt(A attempt, AppLocalizations l);
  C createCommand({
    required int amountCents,
    required String method,
    required String businessDate,
    required int expectedBalanceCents,
    String? notes,
  });
  Future<A> submit(T title, C command, ApiOrigin origin);
  Future<A> resume(A attempt);
  Future<void> acknowledge(A attempt);
  Set<String> get methods;
  String methodName(String method, AppLocalizations l);
  String statusName(String status, AppLocalizations l);
  ReviewedPaymentLabels labels(AppLocalizations l);
  Widget? originAction(BuildContext context, T title, ApiOrigin origin) => null;
}
