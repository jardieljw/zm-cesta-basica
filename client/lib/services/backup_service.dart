import '../core/api_client.dart';
import '../models/backup.dart';

class BackupService {
  final ApiClient _apiClient;

  BackupService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<BackupItemModel>> listBackups() async {
    final res = await _apiClient.get('/api/v1/backup/list');
    if (res is List) {
      return res.map((e) => BackupItemModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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
