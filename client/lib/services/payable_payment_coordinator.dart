import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../models/account_payable.dart';
import '../utils/business_dates.dart';
import 'payable_service.dart';
import 'reviewed_payment_coordinator.dart';

const payablePaymentMethods = {
  'DINHEIRO',
  'PIX',
  'BOLETO',
  'TRANSFERENCIA',
  'CHEQUE',
  'CARTAO_CREDITO',
  'OUTRO',
};

class PayablePaymentAttempt implements ReviewedPaymentAttempt {
  @override
  final ApiOrigin origin;
  final String payableId, beneficiary, description;
  @override
  final String key;
  final int payableNumber;
  final Map<String, dynamic> payload;
  final PayablePayment? confirmation;

  PayablePaymentAttempt({
    required this.origin,
    required this.payableId,
    required this.key,
    required this.beneficiary,
    required this.description,
    required this.payableNumber,
    required Map<String, dynamic> payload,
    this.confirmation,
  }) : payload = Map.unmodifiable(payload) {
    final amount = payload['amount_cents'],
        balance = payload['expected_balance_cents'];
    if (key.isEmpty ||
        payableId.isEmpty ||
        amount is! int ||
        amount <= 0 ||
        balance is! int ||
        amount > balance ||
        !payablePaymentMethods.contains(payload['payment_method']) ||
        payload['payment_business_date'] is! String ||
        payload['account_id'] != null ||
        payload.keys.any(
          (k) => !{
            'amount_cents',
            'account_id',
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
  String get titleId => payableId;
  @override
  bool get hasConfirmation => confirmation != null;

  bool matches(PayablePayment result) =>
      result.id.isNotEmpty &&
      result.payableId == payableId &&
      result.amountCents == payload['amount_cents'] &&
      result.paymentMethod == payload['payment_method'] &&
      result.status == 'CONFIRMED' &&
      (result.notes ?? '') == (payload['notes'] ?? '') &&
      BusinessDates.iso(BusinessDates.dayOf(result.paymentDate)) ==
          payload['payment_business_date'];

  PayablePaymentCreate get command => PayablePaymentCreate(
    amountCents: payload['amount_cents'] as int,
    paymentMethod: payload['payment_method'] as String,
    notes: payload['notes'] as String?,
    expectedBalanceCents: payload['expected_balance_cents'] as int,
    paymentBusinessDate: payload['payment_business_date'] as String,
  );

  PayablePaymentAttempt confirmed(PayablePayment result) =>
      PayablePaymentAttempt(
        origin: origin,
        payableId: payableId,
        key: key,
        beneficiary: beneficiary,
        description: description,
        payableNumber: payableNumber,
        payload: payload,
        confirmation: result,
      );

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'origin': origin.toJson(),
    'payable_id': payableId,
    'key': key,
    'beneficiary': beneficiary,
    'description': description,
    'payable_number': payableNumber,
    'payload': payload,
    if (confirmation != null) 'confirmation': confirmation!.toJson(),
  };

  factory PayablePaymentAttempt.fromJson(Map<String, dynamic> value) {
    if (value['version'] != 1) {
      throw const FormatException('Unsupported payment attempt');
    }
    return PayablePaymentAttempt(
      origin: ApiOrigin.fromJson(
        Map<String, dynamic>.from(value['origin'] as Map),
      ),
      payableId: value['payable_id'] as String,
      key: value['key'] as String,
      beneficiary: value['beneficiary'] as String,
      description: value['description'] as String,
      payableNumber: value['payable_number'] as int,
      payload: Map<String, dynamic>.from(value['payload'] as Map),
      confirmation: value['confirmation'] == null
          ? null
          : PayablePayment.fromJson(
              Map<String, dynamic>.from(value['confirmation'] as Map),
            ),
    );
  }
}

class PayablePaymentAttemptStore
    extends ReviewedPaymentAttemptStore<PayablePaymentAttempt> {
  PayablePaymentAttemptStore()
    : super(
        namespace: 'payable_payment_v1',
        decode: PayablePaymentAttempt.fromJson,
      );
}

/// Payable-specific adapter; recovery mechanics do not own ledger rules.
class PayablePaymentCoordinator {
  final PayableService service;
  final PayablePaymentAttemptStore store;
  late final _engine =
      ReviewedPaymentEngine<
        PayablePaymentAttempt,
        PayableService,
        PayablePayment
      >(
        store: store,
        readOrigin: service.readOrigin,
        connect: service.bindOrigin,
        closeConnection: (connection) => connection.close(),
        reviewVersion: (connection, id) async =>
            (await connection.getPayable(id)).paymentReviewVersion,
        record: (connection, attempt) => connection.recordPayment(
          attempt.payableId,
          attempt.command,
          idempotencyKey: attempt.key,
        ),
        matches: (attempt, result) => attempt.matches(result),
        confirmed: (attempt, result) => attempt.confirmed(result),
        refusalCodes: const {
          'PAYABLE_BALANCE_CHANGED',
          'PAYABLE_NOT_OPEN',
          'PAYABLE_AMOUNT_EXCEEDS_BALANCE',
          'PAYABLE_NOT_FOUND',
          'PAYABLE_PAYMENT_METHOD_INVALID',
        },
      );

  PayablePaymentCoordinator({
    required this.service,
    PayablePaymentAttemptStore? store,
  }) : store = store ?? PayablePaymentAttemptStore();

  PayableService serviceFor(ApiOrigin origin) => _engine.serviceFor(origin);
  void dispose() => _engine.dispose();
  Future<List<PayablePaymentAttempt>> pending() => _engine.pending();
  Future<PayablePaymentAttempt?> attemptFor(String id, ApiOrigin origin) =>
      _engine.attemptFor(id, origin);

  Future<PayablePaymentAttempt> submit(
    AccountPayable title,
    PayablePaymentCreate command,
    ApiOrigin origin,
  ) => _engine.submit(
    capability: title.paymentReviewVersion,
    createAttempt: () => PayablePaymentAttempt(
      origin: origin,
      payableId: title.id,
      key: const Uuid().v4(),
      beneficiary: title.beneficiary,
      description: title.description,
      payableNumber: title.payableNumber,
      payload: command.toJson(),
    ),
  );

  Future<PayablePaymentAttempt> resume(PayablePaymentAttempt attempt) =>
      _engine.resume(attempt);
  Future<void> acknowledge(PayablePaymentAttempt attempt) =>
      _engine.acknowledge(attempt);
}
