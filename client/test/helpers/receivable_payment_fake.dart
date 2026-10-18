import 'dart:async';
import 'dart:convert';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/services/receivable_service.dart';

SalesReceivable receivablePaymentTitle({
  String id = 'receivable-test',
  int balance = 68000,
  int version = 1,
  List<ReceivablePayment> payments = const [],
}) => SalesReceivable(
  id: id,
  saleId: 'sale-test',
  saleNumber: 57,
  customerId: 'customer-test',
  customerName: 'Cliente de teste',
  basketTypesSummary: 'Cesta Básica × 8',
  originalAmountCents: 68000,
  paidAmountCents: 68000 - balance,
  balanceCents: balance,
  dueDate: DateTime.utc(2026, 10, 17),
  saleDate: DateTime.utc(2026, 10, 1, 15),
  status: balance == 0
      ? 'PAID'
      : balance < 68000
      ? 'PARTIAL'
      : 'OPEN',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 17),
  paymentReviewVersion: version,
  payments: payments,
  paymentsCount: payments.length,
);

class FakeReceivablePaymentService extends ReceivableService {
  ApiOrigin origin = ApiOrigin(
    url: 'https://test.invalid:8000',
    fingerprint: 'AA:BB',
  );
  SalesReceivable title = receivablePaymentTitle();
  final Map<String, ReceivablePayment> recorded = {};
  final List<({String? key, String payload})> calls = [];
  bool dropReply = false, invalidReply = false, routeReply = false;
  ApiException? refusal, readError;
  Completer<void>? gate;

  @override
  Future<ApiOrigin> readOrigin() async => origin;
  @override
  ReceivableService bindOrigin(ApiOrigin origin) => this;
  @override
  Future<SalesReceivable> getReceivable(String id) async {
    if (readError != null) throw readError!;
    return title;
  }

  @override
  Future<ReceivablePayment> recordPayment(
    String receivableId,
    ReceivablePaymentCreate data, {
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
        errorCode: 'RECEIVABLE_BALANCE_CHANGED',
      );
    }
    final payment = ReceivablePayment(
      id: 'receipt-${recorded.length + 1}',
      receivableId: invalidReply ? 'wrong-title' : receivableId,
      accountId: 'internal',
      dispatchId: routeReply ? 'unexpected-dispatch' : null,
      isRouteCollection: routeReply,
      repassStatus: routeReply ? 'PENDING_REPASS' : 'DIRECT_COMPANY',
      paymentDate: DateTime.parse('${data.paymentBusinessDate}T03:00:00Z'),
      amountCents: data.amountCents,
      paymentMethod: data.paymentMethod,
      status: 'CONFIRMED',
      notes: data.notes,
      createdAt: DateTime.utc(2026, 10, 17, 15),
    );
    recorded[idempotencyKey!] = payment;
    title = receivablePaymentTitle(
      id: title.id,
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
