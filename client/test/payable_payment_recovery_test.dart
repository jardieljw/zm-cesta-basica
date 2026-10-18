import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/services/payable_payment_coordinator.dart';
import 'package:zm_cesta_basica_client/utils/business_dates.dart';
import 'package:zm_cesta_basica_client/utils/money_input.dart';
import 'helpers/payable_payment_fake.dart';

PayablePaymentCreate command({int amount = 20000, int balance = 68000}) =>
    PayablePaymentCreate(
      amountCents: amount,
      expectedBalanceCents: balance,
      paymentMethod: 'PIX',
      paymentBusinessDate: '2026-10-15',
      notes: 'Referência conservada',
    );
Matcher code(String value) =>
    isA<ApiException>().having((e) => e.errorCode, 'code', value);

class ReceiptWriteFailsOnce extends PayablePaymentAttemptStore {
  int writes = 0;
  @override
  Future<void> write(PayablePaymentAttempt attempt) async {
    writes++;
    if (writes == 2) {
      throw ApiException(
        statusCode: 0,
        message: 'Storage',
        errorCode: 'PAYMENT_LOCAL_STORAGE',
      );
    }
    return super.write(attempt);
  }
}

class AllWritesFail extends PayablePaymentAttemptStore {
  @override
  Future<void> write(PayablePaymentAttempt attempt) async => throw ApiException(
    statusCode: 0,
    message: 'Storage',
    errorCode: 'PAYMENT_LOCAL_STORAGE',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'lost response survives coordinator restart and reuses exact key/body/date',
    () async {
      final service = FakePaymentService()..dropReply = true;
      var flow = PayablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final original = (await flow.pending()).single;
      flow = PayablePaymentCoordinator(service: service);
      final saved = (await flow.pending()).single;
      expect(saved.key, original.key);
      expect(saved.payload, original.payload);
      final result = await flow.resume(saved);
      expect(service.recorded.length, 1);
      expect(service.calls[0], service.calls[1]);
      expect(result.confirmation!.amountCents, 20000);
      expect(service.title.balanceCents, 48000);
      await flow.acknowledge(result);
      expect(await flow.pending(), isEmpty);
    },
  );

  test('confirmed receipt after restart does not POST again', () async {
    final service = FakePaymentService();
    final flow = PayablePaymentCoordinator(service: service);
    await flow.submit(service.title, command(), service.origin);
    final restarted = PayablePaymentCoordinator(service: service);
    final saved = (await restarted.pending()).single;
    expect(saved.confirmation, isNotNull);
    await restarted.resume(saved);
    expect(service.calls.length, 1);
  });

  test(
    'unresolved command prevents a new key even with different requested amount',
    () async {
      final service = FakePaymentService()..dropReply = true;
      final flow = PayablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        flow.submit(
          service.title,
          command(amount: 10000, balance: 48000),
          service.origin,
        ),
        throwsA(code('PAYMENT_ATTEMPT_PENDING')),
      );
      expect(service.calls.length, 1);
      expect((await flow.pending()).length, 1);
    },
  );

  test('failure to persist identity prevents every POST', () async {
    final service = FakePaymentService();
    final flow = PayablePaymentCoordinator(
      service: service,
      store: AllWritesFail(),
    );
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('PAYMENT_LOCAL_STORAGE')),
    );
    expect(service.calls, isEmpty);
  });

  test(
    'receipt persistence failure keeps known confirmation and safe replay',
    () async {
      final service = FakePaymentService();
      final flow = PayablePaymentCoordinator(
        service: service,
        store: ReceiptWriteFailsOnce(),
      );
      final result = await flow.submit(
        service.title,
        command(),
        service.origin,
      );
      expect(result.confirmation, isNotNull);
      final pending = (await flow.pending()).single;
      expect(pending.confirmation, isNull);
      final replay = await flow.resume(pending);
      expect(replay.confirmation, isNotNull);
      expect(service.recorded.length, 1);
    },
  );

  test('callback refusal releases command for a new review', () async {
    final service = FakePaymentService()
      ..refusal = ApiException(
        statusCode: 409,
        message: 'Changed',
        errorCode: 'PAYABLE_BALANCE_CHANGED',
      );
    final flow = PayablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('PAYABLE_BALANCE_CHANGED')),
    );
    expect(await flow.pending(), isEmpty);
    expect(service.recorded, isEmpty);
  });

  for (final status in [0, 401, 403, 404, 422, 500, 503]) {
    test(
      'unknown refusal $status keeps identity instead of allowing another payment',
      () async {
        final service = FakePaymentService()
          ..refusal = ApiException(statusCode: status, message: 'Unknown');
        final flow = PayablePaymentCoordinator(service: service);
        await expectLater(
          flow.submit(service.title, command(), service.origin),
          throwsA(isA<ApiException>()),
        );
        expect((await flow.pending()).single.confirmation, isNull);
      },
    );
  }

  test('invalid response never clears the pending command', () async {
    final service = FakePaymentService()..invalidReply = true;
    final flow = PayablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('PAYMENT_CONFIRMATION_INVALID')),
    );
    expect((await flow.pending()).single.confirmation, isNull);
  });

  test(
    'switching origin never sends a pending command to the new server',
    () async {
      final service = FakePaymentService()..dropReply = true;
      final flow = PayablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final saved = (await flow.pending()).single;
      service.origin = ApiOrigin(
        url: 'https://another.invalid',
        fingerprint: 'CC:DD',
      );
      await expectLater(
        flow.resume(saved),
        throwsA(code('PAYMENT_CONNECTION_CHANGED')),
      );
      expect(service.calls.length, 1);
      expect(await flow.pending(), isEmpty);
      expect(await flow.attemptFor(saved.payableId, saved.origin), isNotNull);
    },
  );

  test('older server cannot silently ignore reviewed balance fields', () async {
    final service = FakePaymentService()..title = paymentTitle(version: 0);
    final flow = PayablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('PAYMENT_SERVER_UPDATE_REQUIRED')),
    );
    expect(service.calls, isEmpty);
    expect(await flow.pending(), isEmpty);
  });

  test('two callers share the local in-flight lock', () async {
    final service = FakePaymentService()..gate = Completer<void>();
    final first = PayablePaymentCoordinator(service: service),
        second = PayablePaymentCoordinator(service: service);
    final sending = first.submit(service.title, command(), service.origin);
    while (service.calls.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await expectLater(
      second.submit(service.title, command(), service.origin),
      throwsA(code('PAYMENT_ATTEMPT_PENDING')),
    );
    service.gate!.complete();
    await sending;
    expect(service.recorded.length, 1);
  });

  test('corrupt local attempt blocks another command', () async {
    final service = FakePaymentService()..dropReply = true;
    final flow = PayablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(isA<ApiException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefs.getKeys().single, 'corrupt');
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('PAYMENT_LOCAL_STORAGE')),
    );
    expect(service.calls.length, 1);
  });

  test(
    'civil day is independent of device timezone and switches at 03 UTC',
    () {
      expect(
        BusinessDates.iso(
          BusinessDates.today(DateTime.utc(2026, 10, 17, 2, 59)),
        ),
        '2026-10-16',
      );
      expect(
        BusinessDates.iso(BusinessDates.today(DateTime.utc(2026, 10, 17, 3))),
        '2026-10-17',
      );
      expect(
        BusinessDates.iso(BusinessDates.parse('2026-10-15')),
        '2026-10-15',
      );
      expect(() => BusinessDates.parse('2026-02-30'), throwsFormatException);
    },
  );

  test('money parsing rejects rounding and malformed grouping', () {
    expect(MoneyInput.cents('1.250,50'), 125050);
    expect(MoneyInput.cents('200'), 20000);
    for (final bad in [
      '12,345',
      '1.25',
      '-1',
      'abc',
      '99999999999999999999999',
    ]) {
      expect(MoneyInput.cents(bad), isNull);
    }
  });
}
