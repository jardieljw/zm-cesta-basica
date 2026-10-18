import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/core/secure_storage.dart';

class ConnectionStorage extends SecureStorageService {
  String url = 'https://server.invalid:8000';
  String fingerprint = 'AA:BB';
  @override
  Future<String?> getServerUrl() async => url;
  @override
  Future<String?> getFingerprint() async => fingerprint;
  @override
  Future<String?> getDeviceToken() async => 'fixture-token';
}

void main() {
  test(
    'origin stores public identity only, normalized without a token',
    () async {
      final origin = ApiOrigin(
        url: 'https://server.invalid:8000/',
        fingerprint: ' aa:bb ',
      );
      expect(origin.url, 'https://server.invalid:8000');
      expect(origin.fingerprint, 'AA:BB');
      expect(origin.toJson().keys, unorderedEquals(['url', 'fingerprint']));
      expect(ApiOrigin.fromJson(origin.toJson()), origin);
    },
  );
  for (final changed in ['url', 'fingerprint', 'missing-pin', 'http']) {
    test('bound client refuses $changed before issuing HTTP', () async {
      final storage = ConnectionStorage();
      final client = ApiClient(storage: storage);
      final origin = await client.readOrigin();
      if (changed == 'url') storage.url = 'https://different.invalid';
      if (changed == 'fingerprint') storage.fingerprint = 'CC:DD';
      if (changed == 'missing-pin') storage.fingerprint = '';
      if (changed == 'http') storage.url = 'http://server.invalid';
      final bound = client.bindOrigin(
        changed == 'missing-pin' || changed == 'http'
            ? await client.readOrigin()
            : origin,
      );
      await expectLater(
        bound.post(
          '/api/v1/payables/id/payments',
          body: {},
          idempotencyKey: 'fixture',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'code',
            'PAYMENT_CONNECTION_CHANGED',
          ),
        ),
      );
      bound.close();
      client.close();
    });
  }
}
