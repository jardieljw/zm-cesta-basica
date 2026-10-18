import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/services/payable_payment_coordinator.dart';
import 'package:zm_cesta_basica_client/services/receivable_payment_coordinator.dart';
import 'package:zm_cesta_basica_client/services/receivable_service.dart';
import 'helpers/payable_payment_fake.dart' as payable;
import 'helpers/receivable_payment_fake.dart';

ReceivablePaymentCreate command({
  int amount = 20000,
  int balance = 68000,
  String method = 'PIX',
}) => ReceivablePaymentCreate(
  amountCents: amount,
  expectedBalanceCents: balance,
  paymentMethod: method,
  paymentBusinessDate: '2026-10-15',
  notes: 'Referência conservada',
);

Matcher code(String value) =>
    isA<ApiException>().having((e) => e.errorCode, 'code', value);

class ReceiptWriteFailsOnce extends ReceivablePaymentAttemptStore {
  int writes = 0;
  @override
  Future<void> write(ReceivablePaymentAttempt attempt) async {
    if (++writes == 2) {
      throw ApiException(
        statusCode: 0,
        message: 'Storage',
        errorCode: 'PAYMENT_LOCAL_STORAGE',
      );
    }
    return super.write(attempt);
  }
}

class AllWritesFail extends ReceivablePaymentAttemptStore {
  @override
  Future<void> write(ReceivablePaymentAttempt attempt) async =>
      throw ApiException(
        statusCode: 0,
        message: 'Storage',
        errorCode: 'PAYMENT_LOCAL_STORAGE',
      );
}

class SaleReadClient extends ApiClient {
  final paths = <String>[];
  @override
  Future<dynamic> get(String path) async {
    paths.add(path);
    return {
      'id': 'sale-test',
      'sale_number': 57,
      'status': 'CONFIRMED',
      'payment_mode': 'CREDIT',
      'payment_status': 'PARTIAL',
      'sale_date': '2026-10-01T15:00:00Z',
      'total_amount_cents': 68000,
      'items': <dynamic>[],
    };
  }
}

class ReceivableListClient extends ApiClient {
  final paths = <String>[];

  @override
  Future<dynamic> get(String path) async {
    paths.add(path);
    return <dynamic>[];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'lost reply survives restart with exact frozen key, body and date',
    () async {
      final service = FakeReceivablePaymentService()..dropReply = true;
      var flow = ReceivablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final original = (await flow.pending()).single;
      flow = ReceivablePaymentCoordinator(service: service);
      final saved = (await flow.pending()).single;
      expect(saved.key, original.key);
      expect(saved.payload, original.payload);
      expect(saved.customerName, 'Cliente de teste');
      expect(saved.saleNumber, 57);
      expect(saved.saleId, 'sale-test');
      final result = await flow.resume(saved);
      expect(service.recorded.length, 1);
      expect(service.calls[0], service.calls[1]);
      expect(result.confirmation!.amountCents, 20000);
      expect(service.title.balanceCents, 48000);
      await flow.acknowledge(result);
      expect(await flow.pending(), isEmpty);
    },
  );

  test('persisted confirmation does not POST on restart', () async {
    final service = FakeReceivablePaymentService();
    await ReceivablePaymentCoordinator(
      service: service,
    ).submit(service.title, command(), service.origin);
    final restarted = ReceivablePaymentCoordinator(service: service);
    final saved = (await restarted.pending()).single;
    expect(saved.confirmation, isNotNull);
    service.readError = ApiException(statusCode: 503, message: 'Offline');
    await restarted.resume(saved);
    expect(service.calls.length, 1);
  });

  test(
    'unresolved receipt blocks a fresh key and cannot be discarded',
    () async {
      final service = FakeReceivablePaymentService()..dropReply = true;
      final flow = ReceivablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final saved = (await flow.pending()).single;
      await expectLater(flow.acknowledge(saved), throwsStateError);
      await expectLater(
        flow.submit(
          service.title,
          command(amount: 10000, balance: 48000),
          service.origin,
        ),
        throwsA(code('PAYMENT_ATTEMPT_PENDING')),
      );
      expect(service.calls.length, 1);
    },
  );

  test('failed local command persistence prevents POST', () async {
    final service = FakeReceivablePaymentService();
    final flow = ReceivablePaymentCoordinator(
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
    'failed receipt persistence keeps confirmation known and replay safe',
    () async {
      final service = FakeReceivablePaymentService();
      final flow = ReceivablePaymentCoordinator(
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
      expect((await flow.resume(pending)).confirmation, isNotNull);
      expect(service.recorded.length, 1);
    },
  );

  test('callback balance refusal releases only the rejected command', () async {
    final service = FakeReceivablePaymentService()
      ..refusal = ApiException(
        statusCode: 409,
        message: 'Changed',
        errorCode: 'RECEIVABLE_BALANCE_CHANGED',
      );
    final flow = ReceivablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(code('RECEIVABLE_BALANCE_CHANGED')),
    );
    expect(await flow.pending(), isEmpty);
    expect(service.recorded, isEmpty);
  });

  for (final error in [
    ApiException(statusCode: 0, message: 'Offline'),
    ApiException(statusCode: 401, message: 'Unauthorized'),
    ApiException(statusCode: 422, message: 'Validation'),
    ApiException(statusCode: 503, message: 'Unavailable'),
    ApiException(
      statusCode: 409,
      message: 'In progress',
      errorCode: 'REQUEST_IN_PROGRESS',
    ),
    ApiException(
      statusCode: 409,
      message: 'Mismatch',
      errorCode: 'IDEMPOTENCY_PAYLOAD_MISMATCH',
    ),
  ]) {
    test(
      'uncertain ${error.errorCode ?? error.statusCode} preserves identity',
      () async {
        final service = FakeReceivablePaymentService()..refusal = error;
        final flow = ReceivablePaymentCoordinator(service: service);
        await expectLater(
          flow.submit(service.title, command(), service.origin),
          throwsA(isA<ApiException>()),
        );
        expect((await flow.pending()).single.confirmation, isNull);
      },
    );
  }

  test('GET refusal code cannot release an earlier unknown command', () async {
    final service = FakeReceivablePaymentService()..dropReply = true;
    final flow = ReceivablePaymentCoordinator(service: service);
    await expectLater(
      flow.submit(service.title, command(), service.origin),
      throwsA(isA<ApiException>()),
    );
    final saved = (await flow.pending()).single;
    service.readError = ApiException(
      statusCode: 404,
      message: 'Not found during query',
      errorCode: 'RECEIVABLE_NOT_FOUND',
    );
    await expectLater(
      flow.resume(saved),
      throwsA(code('RECEIVABLE_NOT_FOUND')),
    );
    expect((await flow.pending()).single.key, saved.key);
    expect(service.calls.length, 1);
  });

  for (final invalidRoute in [false, true]) {
    test(
      'wrong ${invalidRoute ? 'route' : 'title'} confirmation stays uncertain',
      () async {
        final service = FakeReceivablePaymentService()
          ..invalidReply = !invalidRoute
          ..routeReply = invalidRoute;
        final flow = ReceivablePaymentCoordinator(service: service);
        await expectLater(
          flow.submit(service.title, command(), service.origin),
          throwsA(code('PAYMENT_CONFIRMATION_INVALID')),
        );
        expect((await flow.pending()).single.confirmation, isNull);
      },
    );
  }

  test(
    'switching server or fingerprint never redirects a frozen command',
    () async {
      final service = FakeReceivablePaymentService()..dropReply = true;
      final flow = ReceivablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final saved = (await flow.pending()).single;
      for (final origin in [
        ApiOrigin(url: 'https://another.invalid', fingerprint: 'AA:BB'),
        ApiOrigin(url: saved.origin.url, fingerprint: 'CC:DD'),
      ]) {
        service.origin = origin;
        await expectLater(
          flow.resume(saved),
          throwsA(code('PAYMENT_CONNECTION_CHANGED')),
        );
        expect(await flow.pending(), isEmpty);
        expect(
          await flow.attemptFor(saved.receivableId, saved.origin),
          isNotNull,
        );
      }
      expect(service.calls.length, 1);
    },
  );

  test(
    'old server is gated before submit and keeps previously sent attempts',
    () async {
      final service = FakeReceivablePaymentService()
        ..title = receivablePaymentTitle(version: 0);
      final flow = ReceivablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(code('PAYMENT_SERVER_UPDATE_REQUIRED')),
      );
      expect(await flow.pending(), isEmpty);
      expect(service.calls, isEmpty);
      service.title = receivablePaymentTitle();
      service.dropReply = true;
      await expectLater(
        flow.submit(service.title, command(), service.origin),
        throwsA(isA<ApiException>()),
      );
      final saved = (await flow.pending()).single;
      service.title = receivablePaymentTitle(balance: 48000, version: 0);
      await expectLater(
        flow.resume(saved),
        throwsA(code('PAYMENT_SERVER_UPDATE_REQUIRED')),
      );
      expect((await flow.pending()).single.key, saved.key);
      expect(service.calls.length, 1);
    },
  );

  test('two coordinators share the in-flight lock', () async {
    final service = FakeReceivablePaymentService()..gate = Completer<void>();
    final first = ReceivablePaymentCoordinator(service: service);
    final second = ReceivablePaymentCoordinator(service: service);
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

  test('corrupt stored attempt blocks a fresh command', () async {
    final service = FakeReceivablePaymentService()..dropReply = true;
    final flow = ReceivablePaymentCoordinator(service: service);
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
    'Receber keeps its method codes and rejects payable codes or route fields',
    () async {
      for (final method in ['CASH', 'PIX', 'CARD', 'OTHER']) {
        final service = FakeReceivablePaymentService()
          ..title = receivablePaymentTitle(id: method);
        final flow = ReceivablePaymentCoordinator(service: service);
        final result = await flow.submit(
          service.title,
          command(method: method),
          service.origin,
        );
        expect(result.confirmation!.paymentMethod, method);
        expect(result.payload.containsKey('account_id'), isFalse);
        expect(result.payload.containsKey('dispatch_id'), isFalse);
      }
      final service = FakeReceivablePaymentService();
      final flow = ReceivablePaymentCoordinator(service: service);
      await expectLater(
        flow.submit(service.title, command(method: 'DINHEIRO'), service.origin),
        throwsFormatException,
      );
      await expectLater(
        flow.submit(
          service.title,
          ReceivablePaymentCreate(
            amountCents: 20000,
            expectedBalanceCents: 68000,
            paymentBusinessDate: '2026-10-15',
            dispatchId: 'archived-route',
          ),
          service.origin,
        ),
        throwsFormatException,
      );
      expect(service.calls, isEmpty);
    },
  );

  test(
    'model preserves legacy requests and parses naive receipt timestamps as UTC',
    () {
      expect(ReceivablePaymentCreate(amountCents: 1).toJson(), {
        'amount_cents': 1,
        'payment_method': 'CASH',
        'payment_date': null,
        'notes': null,
      });
      final reviewed = ReceivablePaymentCreate(
        amountCents: 20000,
        expectedBalanceCents: 68000,
        paymentBusinessDate: '2026-10-15',
        notes: '  Referência  ',
      ).toJson();
      expect(reviewed.containsKey('payment_date'), isFalse);
      expect(reviewed['notes'], 'Referência');
      final receipt = ReceivablePayment.fromJson({
        'id': 'receipt',
        'receivable_id': 'title',
        'amount_cents': 20000,
        'payment_date': '2026-10-15T03:00:00',
        'created_at': '2026-10-15T15:00:00',
      });
      expect(receipt.paymentDate, DateTime.utc(2026, 10, 15, 3));
      expect(receipt.createdAt.isUtc, isTrue);
      expect(
        ReceivablePayment.fromJson(receipt.toJson()).paymentDate,
        receipt.paymentDate,
      );
    },
  );

  test(
    'shared recovery reads an existing payable journal without changing its key/body',
    () async {
      final service = payable.FakePaymentService();
      final payload = {
        'amount_cents': 20000,
        'account_id': null,
        'payment_method': 'PIX',
        'notes': 'Referência conservada',
        'expected_balance_cents': 68000,
        'payment_business_date': '2026-10-15',
      };
      final key =
          'payable_payment_v1_${service.origin.storageId}_${service.title.id}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'version': 1,
          'origin': service.origin.toJson(),
          'payable_id': service.title.id,
          'key': 'key-before-shared-extraction',
          'beneficiary': service.title.beneficiary,
          'description': service.title.description,
          'payable_number': service.title.payableNumber,
          'payload': payload,
        }),
      );
      final flow = PayablePaymentCoordinator(service: service);
      final saved = (await flow.pending()).single;
      expect(saved.payload, payload);
      await flow.resume(saved);
      expect(service.calls.single.key, 'key-before-shared-extraction');
      expect(jsonDecode(service.calls.single.payload), payload);
      expect(prefs.getKeys(), {key});
      final receiving = ReceivablePaymentCoordinator(
        service: FakeReceivablePaymentService(),
      );
      expect(await receiving.pending(), isEmpty);
    },
  );

  test(
    'viewing the origin sale reuses the injected secure client and only GETs sale',
    () async {
      final client = SaleReadClient();
      final sale = await ReceivableService(
        client: client,
      ).getOriginSale('sale-test');
      expect(sale.saleNumber, 57);
      expect(sale.totalAmountCents, 68000);
      expect(client.paths, ['/api/v1/sales/sale-test']);
    },
  );

  test(
    'open-only collection includes partial titles without narrowing status',
    () async {
      final client = ReceivableListClient();
      final service = ReceivableService(client: client);
      await service.getReceivables(openOnly: true, limit: 100, offset: 100);
      final query = Uri.parse(client.paths.single).queryParameters;
      expect(query['open_only'], 'true');
      expect(query['status'], isNull);
      expect(query['limit'], '100');
      expect(query['offset'], '100');
      await service.getReceivables();
      expect(Uri.parse(client.paths.last).queryParameters['open_only'], isNull);
    },
  );
}
