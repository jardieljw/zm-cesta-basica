import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> saveDeviceToken(String token) async {
    try {
      await _secureStorage.write(key: ApiConstants.storageKeyToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.storageKeyToken, token);
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      final token = await _secureStorage.read(key: ApiConstants.storageKeyToken);
      if (token != null) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.storageKeyToken);
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.storageKeyServerUrl, url);
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.storageKeyServerUrl);
  }

  Future<void> saveFingerprint(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.storageKeyFingerprint, fingerprint);
  }

  Future<String?> getFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.storageKeyFingerprint);
  }

  Future<void> saveDeviceIdentity({required String devicePublicId, required String deviceName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.storageKeyPublicId, devicePublicId);
    await prefs.setString(ApiConstants.storageKeyDeviceName, deviceName);
  }

  Future<String?> getDevicePublicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.storageKeyPublicId);
  }

  Future<String?> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.storageKeyDeviceName);
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.storageKeyToken);
    await prefs.remove(ApiConstants.storageKeyPublicId);
    await prefs.remove(ApiConstants.storageKeyDeviceName);
    await prefs.remove(ApiConstants.storageKeyFingerprint);
  }
}
