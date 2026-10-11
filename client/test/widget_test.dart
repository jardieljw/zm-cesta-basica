import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:zm_cesta_basica_client/models/pairing_session.dart';
import 'package:zm_cesta_basica_client/models/device_auth.dart';

void main() {
  group('Model Deserialization Tests', () {
    test('PairingInitData fromJson parses valid payload', () {
      final jsonMap = {
        'pin_code': '482910',
        'expires_at': '2026-10-11T12:00:00Z',
        'server_url': 'https://192.168.1.50:8000',
        'tls_fingerprint_sha256': 'E3:4A:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB',
        'qr_payload': '{"server_url":"https://192.168.1.50:8000"}',
      };

      final data = PairingInitData.fromJson(jsonMap);
      expect(data.pinCode, equals('482910'));
      expect(data.serverUrl, equals('https://192.168.1.50:8000'));
      expect(data.tlsFingerprintSha256.startsWith('E3:4A'), isTrue);
    });

    test('QrPayloadData fromJson parses QR code scan output', () {
      final jsonMap = {
        'server_url': 'https://192.168.1.50:8000',
        'tls_fingerprint_sha256': 'AA:BB:CC:DD',
        'pin_code': '654321',
        'expires_at': '2026-10-11T15:30:00Z',
      };

      final qrData = QrPayloadData.fromJson(jsonMap);
      expect(qrData.pinCode, equals('654321'));
      expect(qrData.serverUrl, equals('https://192.168.1.50:8000'));
    });

    test('DeviceAuthCredentials fromJson correctly captures device token', () {
      final jsonMap = {
        'device_id': 'uuid-1234',
        'device_name': 'Balcao 01',
        'device_public_id': 'android-pub-5678',
        'device_token': 'secret_random_token_val_999',
        'message': 'Pareamento realizado com sucesso.',
      };

      final creds = DeviceAuthCredentials.fromJson(jsonMap);
      expect(creds.deviceToken, equals('secret_random_token_val_999'));
      expect(creds.devicePublicId, equals('android-pub-5678'));
    });
  });

  group('Cryptographic Fingerprint Formatter Tests', () {
    test('SHA-256 fingerprint formatting matches colon notation', () {
      final sampleBytes = utf8.encode('TEST_CERTIFICATE_BYTES');
      final digest = sha256.convert(sampleBytes);
      final hexParts = digest.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .toList();
      final formattedFingerprint = hexParts.join(':');

      expect(formattedFingerprint.split(':').length, equals(32));
      expect(formattedFingerprint.contains(':'), isTrue);
    });

    test('Uuid generates RFC4122 v4 keys', () {
      final key1 = const Uuid().v4();
      final key2 = const Uuid().v4();
      expect(key1, isNot(equals(key2)));
      expect(key1.length, equals(36));
    });
  });
}
