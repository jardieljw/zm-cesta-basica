import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/device_auth.dart';
import '../models/pairing_session.dart';

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthService({ApiClient? apiClient, SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService(),
        _apiClient = apiClient ?? ApiClient();

  Future<String> _getOrCreateDevicePublicId() async {
    String? id = await _storage.getDevicePublicId();
    if (id == null || id.isEmpty) {
      final prefix = Platform.isAndroid ? 'android' : 'windows';
      id = '$prefix-${const Uuid().v4().substring(0, 8)}';
    }
    return id;
  }

  Future<DeviceAuthCredentials> pairWithPin({
    required String pinCode,
    required String serverUrl,
    required String tlsFingerprint,
    String? customDeviceName,
  }) async {
    await _storage.saveServerUrl(serverUrl);
    await _storage.saveFingerprint(tlsFingerprint);

    final devicePublicId = await _getOrCreateDevicePublicId();
    final deviceName = customDeviceName ?? (Platform.isAndroid ? 'Tablet Android' : 'Terminal Windows');

    final body = {
      'pin_code': pinCode,
      'device_name': deviceName,
      'device_public_id': devicePublicId,
    };

    final res = await _apiClient.post(
      ApiConstants.pairingConfirmPath,
      body: body,
      isMutation: false,
    );

    if (res is Map) {
      final map = Map<String, dynamic>.from(res);
      final creds = DeviceAuthCredentials.fromJson(map);
      await _storage.saveDeviceToken(creds.deviceToken);
      await _storage.saveDeviceIdentity(
        devicePublicId: creds.devicePublicId,
        deviceName: creds.deviceName,
      );
      return creds;
    }

    throw ApiException(
      statusCode: 500,
      message: 'Falha ao processar resposta de pareamento do servidor',
    );
  }

  Future<DeviceAuthCredentials> pairWithQrPayload(String qrPayloadString) async {
    final Map<String, dynamic> data = json.decode(qrPayloadString);
    final qrData = QrPayloadData.fromJson(data);

    return pairWithPin(
      pinCode: qrData.pinCode,
      serverUrl: qrData.serverUrl,
      tlsFingerprint: qrData.tlsFingerprintSha256,
    );
  }

  Future<void> disconnect() async {
    await _storage.clearAll();
  }
}
