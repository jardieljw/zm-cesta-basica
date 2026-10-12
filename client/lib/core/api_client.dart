import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:uuid/uuid.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message [Code: $errorCode]';
}

class ApiClient {
  final SecureStorageService _storage;
  http.Client? _customHttpClient;
  String? _lastPinnedFingerprint;

  ApiClient({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  Future<http.Client> _getClient() async {
    final pinnedFingerprint = await _storage.getFingerprint();

    if (_customHttpClient == null || pinnedFingerprint != _lastPinnedFingerprint) {
      _lastPinnedFingerprint = pinnedFingerprint;
      final ioClient = HttpClient();
      ioClient.connectionTimeout = const Duration(seconds: 10);

      // Local TLS certificate pinning based on SHA-256 fingerprint
      ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (pinnedFingerprint == null || pinnedFingerprint.isEmpty) {
          // Allow certificate check during initial pre-pairing discovery
          return true;
        }

        final certSha256 = sha256.convert(cert.der).bytes;
        final hexParts = certSha256
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .toList();
        final serverFingerprint = hexParts.join(':');

        return serverFingerprint == pinnedFingerprint;
      };

      _customHttpClient = IOClient(ioClient);
    }

    return _customHttpClient!;
  }

  Future<String> _getBaseUrl() async {
    final url = await _storage.getServerUrl();
    if (url == null || url.isEmpty) {
      return 'https://127.0.0.1:8000';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<Map<String, String>> _buildHeaders({bool isMutation = false, String? customIdempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _storage.getDeviceToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (isMutation) {
      final key = customIdempotencyKey ?? const Uuid().v4();
      headers['X-Idempotency-Key'] = key;
    }

    return headers;
  }

  Future<dynamic> get(String path) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(isMutation: false);

    try {
      final response = await client.get(uri, headers: headers);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Falha de conexao com o servidor local: ${e.message}',
      );
    }
  }

  Future<List<int>> getBytes(String path) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(isMutation: false);

    try {
      final response = await client.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Falha ao baixar arquivo (${response.statusCode})',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Falha de conexao com o servidor local: ${e.message}',
      );
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(
      isMutation: isMutation,
      customIdempotencyKey: idempotencyKey,
    );

    final encodedBody = body != null ? json.encode(body) : null;

    try {
      final response = await client.post(uri, headers: headers, body: encodedBody);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Nao foi possivel conectar ao servidor local: ${e.message}',
      );
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(
      isMutation: isMutation,
      customIdempotencyKey: idempotencyKey,
    );

    final encodedBody = body != null ? json.encode(body) : null;

    try {
      final response = await client.put(uri, headers: headers, body: encodedBody);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Nao foi possivel conectar ao servidor local: ${e.message}',
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(
      isMutation: isMutation,
      customIdempotencyKey: idempotencyKey,
    );

    final encodedBody = body != null ? json.encode(body) : null;

    try {
      final response = await client.patch(uri, headers: headers, body: encodedBody);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Nao foi possivel conectar ao servidor local: ${e.message}',
      );
    }
  }

  Future<dynamic> delete(String path, {bool isMutation = true}) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(isMutation: isMutation);

    try {
      final response = await client.delete(uri, headers: headers);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Nao foi possivel conectar ao servidor local: ${e.message}',
      );
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = utf8.decode(response.bodyBytes);

    dynamic decodedJson;
    try {
      decodedJson = json.decode(bodyString);
    } catch (_) {
      decodedJson = bodyString;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedJson;
    }

    String message = 'Erro na requisicao';
    String? errorCode;

    if (decodedJson is Map) {
      if (decodedJson.containsKey('detail')) {
        final detail = decodedJson['detail'];
        if (detail is Map) {
          errorCode = detail['error_code'];
          message = detail['message'] ?? message;
        } else if (detail is String) {
          message = detail;
        } else if (detail is List) {
          message = detail
              .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
              .join('; ');
        }
      }
    }

    throw ApiException(
      statusCode: statusCode,
      message: message,
      errorCode: errorCode,
      details: decodedJson,
    );
  }
}
