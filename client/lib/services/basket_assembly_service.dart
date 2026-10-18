import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';

/// Small interface to the existing production engine, scoped to basket types.
class BasketAssemblyService {
  final ApiClient _client;
  BasketAssemblyService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> history(String basketId, int page) async => Map<
      String, dynamic>.from(await _client.get(
          '/api/v1/production/batches?basket_type_id=${Uri.encodeComponent(basketId)}&page=$page&page_size=25')
      as Map);

  Future<Map<String, dynamic>> preview(String basketId, int quantity,
          {String? customDescription,
          List<Map<String, dynamic>>? customItems}) async =>
      Map<String, dynamic>.from(await _client.post('/api/v1/production/preview',
          body: {
            'basket_type_id': basketId,
            'quantity_produced': quantity,
            'is_custom': customItems != null,
            if (customItems != null) 'custom_items': customItems,
            if (customItems != null) 'custom_description': customDescription,
            'is_direct_sale': false
          },
          isMutation: false) as Map);

  Future<String> _pendingKey(String basketId) async {
    final server =
        await SecureStorageService().getServerUrl() ?? 'https://127.0.0.1:8000';
    return 'basket_assembly_pending_${server}_$basketId';
  }

  Future<Map<String, dynamic>?> pending(String basketId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _pendingKey(basketId));
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _clearPending(String basketId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _pendingKey(basketId));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final basketId = payload['basket_type_id'] as String;
    final prefs = await SharedPreferences.getInstance();
    final previous = await pending(basketId);
    if (previous != null &&
        jsonEncode(previous['payload']) != jsonEncode(payload)) {
      throw ApiException(
          statusCode: 409,
          message: 'Pending assembly',
          errorCode: 'ASSEMBLY_PENDING');
    }
    final key = previous?['key'] as String? ?? const Uuid().v4();
    if (!await prefs.setString(await _pendingKey(basketId),
        jsonEncode({'key': key, 'payload': payload}))) {
      throw StateError('Could not persist request identity');
    }
    try {
      final response = Map<String, dynamic>.from(await _client.post(
          '/api/v1/production/batches',
          body: payload,
          idempotencyKey: key) as Map);
      if (response['id'] is! String || response['basket_type_id'] != basketId) {
        throw StateError('Invalid assembly confirmation');
      }
      await _clearPending(basketId);
      return response;
    } on ApiException catch (error) {
      // Keep the same payload/key after an uncertain response, including app restart.
      if (error.statusCode == 400 ||
          error.statusCode == 404 ||
          error.statusCode == 422 ||
          [
            'INSUFFICIENT_STOCK',
            'BASKET_STOCK_DISABLED',
            'CUSTOMIZATION_DISABLED',
            'RECIPE_CHANGED'
          ].contains(error.errorCode)) {
        await _clearPending(basketId);
      }
      rethrow;
    }
  }
}
