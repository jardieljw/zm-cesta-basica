import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';

/// A resource keeps its exact action/key after a lost response, including restart.
class CatalogActionService {
  final ApiClient client;
  CatalogActionService({ApiClient? client}) : client = client ?? ApiClient();

  Future<String> _key(String resource) async =>
      'catalog_action_${await SecureStorageService().getServerUrl()}_$resource';

  Future<Map<String, dynamic>?> pending(String resource) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key(resource));
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<Map<String, dynamic>> run(
    // A command rejected definitively may still contain valuable form input.
    String resource,
    String path,
    String method,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _key(resource);
    final old = await pending(resource);
    if (old != null &&
        (old['path'] != path ||
            old['method'] != method ||
            jsonEncode(old['payload']) != jsonEncode(payload))) {
      throw ApiException(
        statusCode: 409,
        message:
            'Há uma confirmação pendente. Retome a operação original antes de iniciar outra.',
      );
    }
    final command =
        old ??
        {
          'path': path,
          'method': method,
          'payload': payload,
          'key': const Uuid().v4(),
        };
    if (!await prefs.setString(storageKey, jsonEncode(command))) {
      throw StateError('Could not persist catalog operation');
    }
    try {
      final savedPath = command['path'] as String;
      final key = command['key'] as String;
      final result = switch (command['method']) {
        'DELETE' => await client.delete(savedPath, idempotencyKey: key),
        'PUT' => await client.put(
          savedPath,
          body: command['payload'],
          idempotencyKey: key,
        ),
        _ => await client.post(
          savedPath,
          body: command['payload'],
          idempotencyKey: key,
        ),
      };
      if (result is! Map) throw StateError('Invalid catalog confirmation');
      await prefs.remove(storageKey);
      await prefs.remove('${storageKey}_draft');
      return Map<String, dynamic>.from(result);
    } on ApiException catch (error) {
      if ([400, 404, 409, 422].contains(error.statusCode)) {
        if (payload['items'] is List && (method == 'POST' || method == 'PUT')) {
          if (!await prefs.setString(
            '${storageKey}_draft',
            jsonEncode(command),
          )) {
            throw StateError('Could not preserve rejected recipe draft');
          }
        }
        await prefs.remove(storageKey);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> rejectedDraft(String resource) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${await _key(resource)}_draft');
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
}
