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
    final token = await _storage.getDeviceToken();
    return token != null && token.isNotEmpty;
  }
}
