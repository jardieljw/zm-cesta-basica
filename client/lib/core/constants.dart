class ApiConstants {
  static const int defaultPort = 8000;
  static const String apiPrefix = '/api/v1';

  static const String healthPath = '$apiPrefix/health';
  static const String pingPath = '$apiPrefix/ping';
  static const String pairingInitiatePath = '$apiPrefix/pairing/initiate';
  static const String pairingConfirmPath = '$apiPrefix/pairing/confirm';
  static const String pairingLocalMasterPath = '$apiPrefix/pairing/local-master';
  static const String devicesListPath = '$apiPrefix/devices';
  static const String devicesRevokePath = '$apiPrefix/devices/revoke';
  static const String backupPath = '$apiPrefix/backup';
  static const String testOpsPath = '$apiPrefix/test-ops/stock-simulation';

  static const String storageKeyToken = 'zm_device_token';
  static const String storageKeyPublicId = 'zm_device_public_id';
  static const String storageKeyDeviceName = 'zm_device_name';
  static const String storageKeyServerUrl = 'zm_server_url';
  static const String storageKeyFingerprint = 'zm_tls_fingerprint';
}
