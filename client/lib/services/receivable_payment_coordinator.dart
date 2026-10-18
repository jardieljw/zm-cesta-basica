import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../models/sales_receivable.dart';
import '../utils/business_dates.dart';
import 'receivable_service.dart';
import 'reviewed_payment_coordinator.dart';

const receivablePaymentMethods = {'CASH', 'PIX', 'CARD', 'OTHER'};

class ReceivablePaymentAttempt implements ReviewedPaymentAttempt {
  @override
  final ApiOrigin origin;
  final String receivableId, customerName, saleId;
  @override
  final String key;
  final int saleNumber;
  final Map<String, dynamic> payload;
  final ReceivablePayment? confirmation;

  ReceivablePaymentAttempt({
    required this.origin,
    required this.receivableId,
    required this.key,
    required this.customerName,
    required this.saleId,
    required this.saleNumber,
    required Map<String, dynamic> payload,
    this.confirmation,
  }) : payload = Map.unmodifiable(payload) {
    final amount = payload['amount_cents'],
        balance = payload['expected_balance_cents'];
    if (key.isEmpty ||
        receivableId.isEmpty ||
        amount is! int ||
        amount <= 0 ||
        balance is! int ||
        amount > balance ||
        !receivablePaymentMethods.contains(payload['payment_method']) ||
        payload['payment_business_date'] is! String ||
        payload.keys.any(
          (k) => !{
            'amount_cents',
            'payment_method',
            'payment_business_date',
            'expected_balance_cents',
            'notes',
          }.contains(k),
        ) ||
        (payload['notes'] != null && payload['notes'] is! String)) {
      throw const FormatException('Invalid payment attempt');
    }
    BusinessDates.parse(payload['payment_business_date'] as String);
    if (confirmation != null && !matches(confirmation!)) {
      throw const FormatException('Invalid stored confirmation');
    }
  }

  @override
  String get titleId => receivableId;
  @override
  bool get hasConfirmation => confirmation != null;

  bool matches(ReceivablePayment result) =>
      result.id.isNotEmpty &&
      result.receivableId == receivableId &&
      result.amountCents == payload['amount_cents'] &&
      result.paymentMethod == payload['payment_method'] &&
      result.status == 'CONFIRMED' &&
      result.dispatchId == null &&
      !result.isRouteCollection &&
      result.repassStatus == 'DIRECT_COMPANY' &&
      (result.notes ?? '') == (payload['notes'] ?? '') &&
      BusinessDates.iso(BusinessDates.dayOf(result.paymentDate)) ==
          payload['payment_business_date'];

  ReceivablePaymentCreate get command => ReceivablePaymentCreate(
    amountCents: payload['amount_cents'] as int,
    paymentMethod: payload['payment_method'] as String,
    notes: payload['notes'] as String?,
    expectedBalanceCents: payload['expected_balance_cents'] as int,
    paymentBusinessDate: payload['payment_business_date'] as String,
  );

  ReceivablePaymentAttempt confirmed(ReceivablePayment result) =>
      ReceivablePaymentAttempt(
        origin: origin,
        receivableId: receivableId,
        key: key,
        customerName: customerName,
        saleId: saleId,
        saleNumber: saleNumber,
        payload: payload,
        confirmation: result,
      );

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'origin': origin.toJson(),
    'receivable_id': receivableId,
    'key': key,
    'customer_name': customerName,
    'sale_id': saleId,
    'sale_number': saleNumber,
    'payload': payload,
    if (confirmation != null) 'confirmation': confirmation!.toJson(),
  };

  factory ReceivablePaymentAttempt.fromJson(Map<String, dynamic> value) {
    if (value['version'] != 1) {
      throw const FormatException('Unsupported payment attempt');
    }
    return ReceivablePaymentAttempt(
      origin: ApiOrigin.fromJson(
        Map<String, dynamic>.from(value['origin'] as Map),
      ),
      receivableId: value['receivable_id'] as String,
      key: value['key'] as String,
      customerName: value['customer_name'] as String,
      saleId: value['sale_id'] as String,
      saleNumber: value['sale_number'] as int,
      payload: Map<String, dynamic>.from(value['payload'] as Map),
      confirmation: value['confirmation'] == null
          ? null
          : ReceivablePayment.fromJson(
              Map<String, dynamic>.from(value['confirmation'] as Map),
            ),
    );
  }
}

class ReceivablePaymentAttemptStore
    extends ReviewedPaymentAttemptStore<ReceivablePaymentAttempt> {
  ReceivablePaymentAttemptStore()
    : super(
        namespace: 'receivable_payment_v1',
        decode: ReceivablePaymentAttempt.fromJson,
      );
}

/// Receivable-specific adapter; recovery mechanics do not own ledger rules.
class ReceivablePaymentCoordinator {
  final ReceivableService service;
  final ReceivablePaymentAttemptStore store;
  late final _engine =
      ReviewedPaymentEngine<
        ReceivablePaymentAttempt,
        ReceivableService,
        ReceivablePayment
      >(
        store: store,
        readOrigin: service.readOrigin,
        connect: service.bindOrigin,
        closeConnection: (connection) => connection.close(),
        reviewVersion: (connection, id) async =>
            (await connection.getReceivable(id)).paymentReviewVersion,
        record: (connection, attempt) => connection.recordPayment(
          attempt.receivableId,
          attempt.command,
          idempotencyKey: attempt.key,
        ),
        matches: (attempt, result) => attempt.matches(result),
        confirmed: (attempt, result) => attempt.confirmed(result),
        refusalCodes: const {
          'RECEIVABLE_BALANCE_CHANGED',
          'RECEIVABLE_NOT_OPEN',
          'RECEIVABLE_AMOUNT_EXCEEDS_BALANCE',
          'RECEIVABLE_NOT_FOUND',
          'RECEIVABLE_PAYMENT_METHOD_INVALID',
        },
      );

  ReceivablePaymentCoordinator({
    required this.service,
    ReceivablePaymentAttemptStore? store,
  }) : store = store ?? ReceivablePaymentAttemptStore();

  ReceivableService serviceFor(ApiOrigin origin) => _engine.serviceFor(origin);
  void dispose() => _engine.dispose();
  Future<List<ReceivablePaymentAttempt>> pending() => _engine.pending();
  Future<ReceivablePaymentAttempt?> attemptFor(String id, ApiOrigin origin) =>
      _engine.attemptFor(id, origin);

  Future<ReceivablePaymentAttempt> submit(
    SalesReceivable title,
    ReceivablePaymentCreate command,
    ApiOrigin origin,
  ) => _engine.submit(
    capability: title.paymentReviewVersion,
    createAttempt: () => ReceivablePaymentAttempt(
      origin: origin,
      receivableId: title.id,
      key: const Uuid().v4(),
      customerName: title.customerName,
      saleId: title.saleId,
      saleNumber: title.saleNumber,
      payload: command.toJson(),
    ),
  );

  Future<ReceivablePaymentAttempt> resume(ReceivablePaymentAttempt attempt) =>
      _engine.resume(attempt);
  Future<void> acknowledge(ReceivablePaymentAttempt attempt) =>
      _engine.acknowledge(attempt);
}
