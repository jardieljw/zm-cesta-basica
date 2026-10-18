import 'dart:convert';
import 'dart:async';
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
  final ApiOrigin? _fixedOrigin;
  http.Client? _customHttpClient;
  String? _lastPinnedFingerprint;

  ApiClient({SecureStorageService? storage})
    : _storage = storage ?? SecureStorageService(),
      _fixedOrigin = null;

  ApiClient._bound(this._storage, this._fixedOrigin);

  Future<ApiOrigin> readOrigin() async => ApiOrigin(
    url: await _storage.getServerUrl() ?? 'https://127.0.0.1:8000',
    fingerprint: await _storage.getFingerprint() ?? '',
  );

  ApiClient bindOrigin(ApiOrigin origin) => ApiClient._bound(_storage, origin);

  void _resetClient() {
    _customHttpClient?.close();
    _customHttpClient = null;
    _lastPinnedFingerprint = null;
  }

  void close() => _resetClient();

  Future<http.Response> _bounded(Future<http.Response> request) async {
    if (_fixedOrigin == null) return request;
    try {
      return await request.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // The server may still complete a POST. The coordinator retains its key.
      throw ApiException(
        statusCode: 0,
        message: 'Resposta não recebida a tempo.',
      );
    }
  }

  Future<void> _assertFixedOrigin() async {
    if (_fixedOrigin != null) {
      final current = await readOrigin();
      if (current != _fixedOrigin ||
          _fixedOrigin.fingerprint.isEmpty ||
          Uri.parse(_fixedOrigin.url).scheme != 'https') {
        throw ApiException(
          statusCode: 0,
          message: 'A conexão desta tentativa foi alterada.',
          errorCode: 'PAYMENT_CONNECTION_CHANGED',
        );
      }
    }
  }

  Future<http.Client> _getClient() async {
    await _assertFixedOrigin();
    final pinnedFingerprint =
        _fixedOrigin?.fingerprint ?? await _storage.getFingerprint();

    if (_customHttpClient == null ||
        pinnedFingerprint != _lastPinnedFingerprint) {
      _lastPinnedFingerprint = pinnedFingerprint;
      final ioClient = HttpClient();
      ioClient.connectionTimeout = const Duration(seconds: 10);
      ioClient.idleTimeout = const Duration(seconds: 4);

      // Local TLS certificate pinning based on SHA-256 fingerprint
      ioClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
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
    if (_fixedOrigin != null) return _fixedOrigin.url;
    final url = await _storage.getServerUrl();
    if (url == null || url.isEmpty) {
      return 'https://127.0.0.1:8000';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<Map<String, String>> _buildHeaders({
    bool isMutation = false,
    String? customIdempotencyKey,
  }) async {
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

    await _assertFixedOrigin();
    return headers;
  }

  Future<dynamic> get(String path) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(isMutation: false);

    for (var attempt = 0; attempt < 2; attempt++) {
      final client = await _getClient();
      try {
        final response = await _bounded(client.get(uri, headers: headers));
        return _processResponse(response);
      } catch (e) {
        final isConnError =
            e is SocketException || e is http.ClientException || e is HttpException;
        if (isConnError && attempt == 0) {
          _resetClient();
          continue;
        }
        if (isConnError) {
          _resetClient();
          throw ApiException(
            statusCode: 0,
            message: 'Falha de conexao com o servidor local: $e',
          );
        }
        rethrow;
      }
    }
  }

  Future<List<int>> getBytes(String path) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(isMutation: false);

    for (var attempt = 0; attempt < 2; attempt++) {
      final client = await _getClient();
      try {
        final response = await client.get(uri, headers: headers);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.bodyBytes;
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Falha ao baixar arquivo (${response.statusCode})',
        );
      } catch (e) {
        final isConnError =
            e is SocketException || e is http.ClientException || e is HttpException;
        if (isConnError && attempt == 0) {
          _resetClient();
          continue;
        }
        if (isConnError) {
          _resetClient();
          throw ApiException(
            statusCode: 0,
            message: 'Falha de conexao com o servidor local: $e',
          );
        }
        rethrow;
      }
    }
    throw StateError('Unreachable');
  }

  /// Read-only binary rendering request, using the same authentication and TLS client.
  Future<List<int>> postBytes(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl$path'),
        headers: await _buildHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      _processResponse(response);
      throw StateError('Unexpected export response');
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(statusCode: 0, message: 'Falha de conexao com o servidor local: $e');
      }
      rethrow;
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
      final response = await _bounded(
        client.post(uri, headers: headers, body: encodedBody),
      );
      return _processResponse(response);
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(
          statusCode: 0,
          message: 'Nao foi possivel conectar ao servidor local: $e',
        );
      }
      rethrow;
    }
  }

  /// Upload original document bytes through the authenticated, pinned transport.
  Future<dynamic> uploadBytes(
    String path, {
    required List<int> bytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    final client = await _getClient();
    final baseUrl = await _getBaseUrl();
    final headers = await _buildHeaders(
      isMutation: true,
      customIdempotencyKey: idempotencyKey,
    );
    headers['Content-Type'] = contentType;
    try {
      final response = await client
          .post(Uri.parse('$baseUrl$path'), headers: headers, body: bytes)
          .timeout(const Duration(seconds: 40));
      return _processResponse(response);
    } on TimeoutException {
      _resetClient();
      throw ApiException(statusCode: 0, message: 'Upload timeout');
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(statusCode: 0, message: 'Upload connection failed: $e');
      }
      rethrow;
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
      final response = await client.put(
        uri,
        headers: headers,
        body: encodedBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(
          statusCode: 0,
          message: 'Nao foi possivel conectar ao servidor local: $e',
        );
      }
      rethrow;
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
      final response = await client.patch(
        uri,
        headers: headers,
        body: encodedBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(
          statusCode: 0,
          message: 'Nao foi possivel conectar ao servidor local: $e',
        );
      }
      rethrow;
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
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is HttpException) {
        _resetClient();
        throw ApiException(
          statusCode: 0,
          message: 'Nao foi possivel conectar ao servidor local: $e',
        );
      }
      rethrow;
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

/// Public connection identity only; credentials are never persisted in commands.
class ApiOrigin {
  final String url;
  final String fingerprint;
  ApiOrigin({required String url, required String fingerprint})
    : url = url.trim().replaceFirst(RegExp(r'/+$'), ''),
      fingerprint = fingerprint.trim().toUpperCase();

  String get storageId =>
      sha256.convert(utf8.encode('$url\n$fingerprint')).toString();
  Map<String, dynamic> toJson() => {'url': url, 'fingerprint': fingerprint};
  factory ApiOrigin.fromJson(Map<String, dynamic> value) => ApiOrigin(
    url: value['url'] as String,
    fingerprint: value['fingerprint'] as String,
  );
  @override
  bool operator ==(Object other) =>
      other is ApiOrigin &&
      other.url == url &&
      other.fingerprint == fingerprint;
  @override
  int get hashCode => Object.hash(url, fingerprint);
}
