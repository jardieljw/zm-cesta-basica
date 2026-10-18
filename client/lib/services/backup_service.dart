import '../core/api_client.dart';
import '../models/backup.dart';
import '../core/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BackupService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  BackupService({ApiClient? apiClient, SecureStorageService? storage})
      : _apiClient = apiClient ?? ApiClient(storage: storage),
        _storage = storage ?? SecureStorageService();

  Future<NewDatabaseResult> createNewDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final url = await _storage.getServerUrl() ?? 'https://127.0.0.1:8000';
    final pendingKey = 'zm_new_database_request_$url';
    final key = prefs.getString(pendingKey) ?? const Uuid().v4();
    await prefs.setString(pendingKey, key);
    final res = await _apiClient.post('/api/v1/backup/new-database',
        body: {'confirmation': 'NOVO BANCO'}, idempotencyKey: key);
    final data = Map<String, dynamic>.from(res as Map);
    if (data['integrity_ok'] != true) {
      throw StateError('Database verification failed');
    }
    final result = NewDatabaseResult.fromJson(data);
    await prefs.remove(pendingKey);
    return result;
  }

  Future<List<BackupItemModel>> listBackups() async {
    final res = await _apiClient.get('/api/v1/backup/list');
    if (res is List) {
      return res
          .map((e) =>
              BackupItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<BackupCreateResult> createBackup() async {
    final res = await _apiClient.post(
      '/api/v1/backup/create',
      body: {},
      isMutation: true,
    );
    if (res is Map) {
      return BackupCreateResult.fromJson(Map<String, dynamic>.from(res));
    }
    throw Exception('Resposta inválida ao criar backup');
  }

  Future<BackupRestoreResult> restoreBackup(String filename) async {
    final res = await _apiClient.post(
      '/api/v1/backup/restore',
      body: {'backup_filename': filename},
      isMutation: true,
    );
    if (res is Map) {
      return BackupRestoreResult.fromJson(Map<String, dynamic>.from(res));
    }
    throw Exception('Resposta inválida ao restaurar backup');
  }
}
