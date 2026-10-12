import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/connection_status.dart';

class ConnectivityService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  ConnectivityService({ApiClient? apiClient, SecureStorageService? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<ServerStatus> checkConnection() async {
    try {
      final res = await _apiClient.get(ApiConstants.healthPath);
      if (res is Map) {
        return ServerStatus(
          isOnline: true,
          version: res['version'] as String?,
          databaseStatus: res['database_status'] as String?,
          tlsFingerprint: res['tls_fingerprint_sha256'] as String?,
        );
      }
      return ServerStatus(isOnline: false, errorMessage: 'Resposta inesperada');
    } on ApiException catch (e) {
      return ServerStatus(isOnline: false, errorMessage: e.message);
    } catch (e) {
      return ServerStatus(isOnline: false, errorMessage: e.toString());
    }
  }

  Future<bool> isPaired() async {
    var token = await _storage.getDeviceToken();
    if (token != null && token.isNotEmpty) {
      return true;
    }

    // No Windows rodando com localhost, auto-autentica como terminal master do caixa
    try {
      final serverUrl = await _storage.getServerUrl() ?? 'https://127.0.0.1:8000';
      if (serverUrl.contains('127.0.0.1') || serverUrl.contains('localhost')) {
        final res = await _apiClient.post(
          ApiConstants.pairingLocalMasterPath,
          body: {},
          isMutation: false,
        );
        if (res is Map && res['device_token'] != null) {
          final newToken = res['device_token'] as String;
          await _storage.saveDeviceToken(newToken);
          await _storage.saveDeviceIdentity(
            devicePublicId: res['device_public_id'] as String? ?? 'windows-local-master',
            deviceName: res['device_name'] as String? ?? 'Terminal Caixa Windows (Local)',
          );
          return true;
        }
      }
    } catch (_) {}

    return false;
  }
}
