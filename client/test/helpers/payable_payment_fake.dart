import 'dart:async';
import 'dart:convert';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';

AccountPayable paymentTitle({
  String id = 'title-test',
  int balance = 68000,
  int version = 1,
  List<PayablePayment> payments = const [],
}) => AccountPayable(
  id: id,
  payableNumber: 208,
  description: 'Compra de alimentos',
  beneficiary: 'Fornecedor de teste',
  category: 'FORNECEDOR',
  nature: 'BUSINESS',
  originalAmountCents: 68000,
  paidAmountCents: 68000 - balance,
  balanceCents: balance,
  dueDate: DateTime.utc(2026, 10, 16),
  paymentMethod: 'BOLETO',
  status: balance == 0
      ? 'PAID'
      : balance < 68000
      ? 'PARTIAL'
      : 'OPEN',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 16),
  paymentReviewVersion: version,
  payments: payments,
  paymentsCount: payments.length,
);

class FakePaymentService extends PayableService {
  ApiOrigin origin = ApiOrigin(
    url: 'https://test.invalid:8000',
    fingerprint: 'AA:BB',
  );
  AccountPayable title = paymentTitle();
  final Map<String, PayablePayment> recorded = {};
  final List<({String? key, String payload})> calls = [];
  bool dropReply = false,
      failReadsAfterCommit = false,
      failReads = false,
      invalidReply = false;
  ApiException? refusal;
  Completer<void>? gate;
  @override
  Future<ApiOrigin> readOrigin() async => origin;
  @override
  PayableService bindOrigin(ApiOrigin origin) => this;
  @override
  Future<AccountPayable> getPayable(String id) async {
    if (failReads || (failReadsAfterCommit && recorded.isNotEmpty)) {
      throw ApiException(statusCode: 0, message: 'Offline');
    }
    return title;
  }

  @override
  Future<Map<String, dynamic>> getPayableSummary({
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? month,
    int? year,
    String? category,
    String? beneficiary,
    String? bankCard,
    String? merchant,
    String? status,
    String? nature,
    bool overdueOnly = false,
    int limit = 100,
    int offset = 0,
  }) async => {
    'count': 1,
    'open_cents': title.balanceCents,
    'overdue_cents': 0,
    'paid_cents': title.paidAmountCents,
  };
  @override
  Future<List<AccountPayable>> getPayables({
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? month,
    int? year,
    String? category,
    String? beneficiary,
    String? bankCard,
    String? merchant,
    String? status,
    String? nature,
    bool overdueOnly = false,
    int limit = 100,
    int offset = 0,
  }) async => title.balanceCents == 0 ? [] : [title];
  @override
  Future<PayablePayment> recordPayment(
    String payableId,
    PayablePaymentCreate data, {
    String? idempotencyKey,
  }) async {
    calls.add((key: idempotencyKey, payload: jsonEncode(data.toJson())));
    if (gate != null) await gate!.future;
    if (recorded.containsKey(idempotencyKey)) return recorded[idempotencyKey]!;
    if (refusal != null) throw refusal!;
    if (data.expectedBalanceCents != title.balanceCents) {
      throw ApiException(
        statusCode: 409,
        message: 'Balance changed',
        errorCode: 'PAYABLE_BALANCE_CHANGED',
      );
    }
    final date = DateTime.parse('${data.paymentBusinessDate}T03:00:00Z');
    final payment = PayablePayment(
      id: 'payment-${recorded.length + 1}',
      payableId: invalidReply ? 'wrong-title' : payableId,
      accountId: 'internal',
      paymentDate: date,
      amountCents: data.amountCents,
      paymentMethod: data.paymentMethod,
      status: 'CONFIRMED',
      notes: data.notes,
      createdAt: DateTime.utc(2026, 10, 16, 15),
    );
    recorded[idempotencyKey!] = payment;
    title = paymentTitle(
      balance: title.balanceCents - data.amountCents,
      version: title.paymentReviewVersion,
      payments: [...title.payments, payment],
    );
    if (dropReply) {
      dropReply = false;
      throw ApiException(statusCode: 0, message: 'Response lost');
    }
    return payment;
  }
}
