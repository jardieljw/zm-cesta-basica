import 'dart:async';
import 'dart:convert';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/models/sale.dart';
import 'package:zm_cesta_basica_client/services/receivable_service.dart';

SalesReceivable uiReceivableTitle({
  String id = 'receivable-ui',
  int balance = 68000,
  int version = 1,
  List<ReceivablePayment> payments = const [],
}) => SalesReceivable(
  id: id,
  saleId: 'sale-ui',
  saleNumber: 73,
  customerId: 'customer-ui',
  customerName: 'Ana Souza',
  dueDate: DateTime.utc(2026, 10, 17),
  originalAmountCents: 105000,
  paidAmountCents: 105000 - balance,
  balanceCents: balance,
  status: balance == 0 ? 'PAID' : 'PARTIAL',
  basketTypesSummary: 'Cesta Básica',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 17),
  paymentReviewVersion: version,
  payments: payments,
  paymentsCount: payments.length,
  saleDate: DateTime.utc(2026, 10, 1, 15),
);

class UIReceivablePaymentService extends ReceivableService {
  ApiOrigin origin = ApiOrigin(
    url: 'https://ui-test.invalid:8000',
    fingerprint: 'AA:BB',
  );
  SalesReceivable title = uiReceivableTitle();
  final Sale originSale = Sale(
    id: 'sale-ui',
    saleNumber: 73,
    customerId: 'customer-ui',
    customerName: 'Ana Souza',
    status: 'CONFIRMED',
    saleMode: 'DIRECT_STORE',
    paymentMode: 'CREDIT_TERM',
    paymentStatus: 'PARTIAL',
    saleDate: DateTime.utc(2026, 10, 1, 15),
    totalAmountCents: 105000,
    totalCostCents: 70000,
    grossMarginCents: 35000,
    items: [
      SaleItem(
        id: 'sale-item-ui',
        basketTypeId: 'basket-ui',
        basketTypeName: 'Cesta Básica',
        quantity: 7,
        unitPriceCents: 15000,
        discountCents: 0,
        totalCents: 105000,
        unitCostCents: 10000,
        totalCostCents: 70000,
      ),
    ],
  );
  final Map<String, ReceivablePayment> recorded = {};
  final List<({String? key, String payload})> calls = [];
  final List<({bool openOnly, String? status, int offset})> listQueries = [];
  int detailReads = 0;
  int originReads = 0;
  bool failOriginReads = false;
  bool dropReply = false, failReadsAfterCommit = false, failReads = false;
  ApiException? refusal;
  Completer<void>? gate;

  @override
  Future<ApiOrigin> readOrigin() async => origin;

  @override
  ReceivableService bindOrigin(ApiOrigin origin) => this;

  @override
  Future<Sale> getOriginSale(String saleId) async {
    originReads++;
    if (failOriginReads) {
      throw ApiException(statusCode: 0, message: 'Origin unavailable');
    }
    if (saleId != originSale.id) {
      throw StateError('Unexpected sale ID in the UI fixture');
    }
    return originSale;
  }

  @override
  Future<SalesReceivable> getReceivable(String id) async {
    detailReads++;
    if (failReads || (failReadsAfterCommit && recorded.isNotEmpty)) {
      throw ApiException(statusCode: 0, message: 'Offline');
    }
    return title;
  }

  @override
  Future<List<SalesReceivable>> getReceivables({
    String? customerId,
    String? status,
    bool openOnly = false,
    bool overdueOnly = false,
    DateTime? saleDateFrom,
    DateTime? saleDateTo,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    String? basketTypeId,
    int? minAmountCents,
    int? maxAmountCents,
    int limit = 100,
    int offset = 0,
  }) async {
    listQueries.add((openOnly: openOnly, status: status, offset: offset));
    if (openOnly && !['OPEN', 'PARTIAL'].contains(title.status)) return [];
    if (status != null && title.status != status) return [];
    return [title];
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
      receivableId: receivableId,
      accountId: 'internal',
      paymentDate: DateTime.parse('${data.paymentBusinessDate}T03:00:00Z'),
      amountCents: data.amountCents,
      paymentMethod: data.paymentMethod,
      status: 'CONFIRMED',
      notes: data.notes,
      createdAt: DateTime.utc(2026, 10, 17, 15),
    );
    recorded[idempotencyKey!] = payment;
    title = uiReceivableTitle(
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
