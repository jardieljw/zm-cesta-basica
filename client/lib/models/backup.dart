class BackupRestoreResult {
  final String status;
  final String restoredFrom;
  final bool integrityOk;
  final String? safetyBackupFilename;

  BackupRestoreResult({
    required this.status,
    required this.restoredFrom,
    required this.integrityOk,
    this.safetyBackupFilename,
  });

  factory BackupRestoreResult.fromJson(Map<String, dynamic> json) {
    return BackupRestoreResult(
      status: json['status'] as String? ?? '',
      restoredFrom: json['restored_from'] as String? ?? '',
      integrityOk: json['integrity_ok'] as bool? ?? false,
      safetyBackupFilename: json['safety_backup_filename'] as String?,
    );
  }
}

class BackupItemModel {
  final String filename;
  final String path;
  final int sizeBytes;
  final String modifiedAt;

  BackupItemModel({
    required this.filename,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  factory BackupItemModel.fromJson(Map<String, dynamic> json) {
    return BackupItemModel(
      filename: json['filename'] as String? ?? '',
      path: json['path'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      modifiedAt: json['modified_at'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupCreateResult {
  final String status;
  final String backupFilename;
  final String backupPath;
  final int sizeBytes;
  final bool integrityOk;
  final String createdAt;

  BackupCreateResult({
    required this.status,
    required this.backupFilename,
    required this.backupPath,
    required this.sizeBytes,
    required this.integrityOk,
    required this.createdAt,
  });

  factory BackupCreateResult.fromJson(Map<String, dynamic> json) {
    return BackupCreateResult(
      status: json['status'] as String? ?? '',
      backupFilename: json['backup_filename'] as String? ?? '',
      backupPath: json['backup_path'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      integrityOk: json['integrity_ok'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NewDatabaseResult {
  final String safetyBackupFilename;
  final String activeDatabasePath;
  final bool operationReplayed;
  NewDatabaseResult(
      {required this.safetyBackupFilename,
      required this.activeDatabasePath,
      this.operationReplayed = false});
  factory NewDatabaseResult.fromJson(Map<String, dynamic> json) =>
      NewDatabaseResult(
          safetyBackupFilename: json['safety_backup_filename'] as String,
          activeDatabasePath: json['active_database_path'] as String,
          operationReplayed: json['operation_replayed'] == true);
}
