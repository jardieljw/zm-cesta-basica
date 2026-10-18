import '../core/api_client.dart';
import '../models/basket_type.dart';

class BasketService {
  final ApiClient _client;

  BasketService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<BasketType>> getBasketTypes({
    String? category,
    bool? isActive,
    String? search,
  }) async {
    final queryParams = <String>[];
    if (category != null && category.isNotEmpty) {
      queryParams.add('category=${Uri.encodeComponent(category)}');
    }
    if (isActive != null) {
      queryParams.add('is_active=$isActive');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _client.get('/api/v1/basket-types$query');

    if (response is List) {
      return response
          .map((json) => BasketType.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BasketType> getBasketType(String id) async {
    final response = await _client.get('/api/v1/basket-types/$id');
    return BasketType.fromJson(response as Map<String, dynamic>);
  }

  Future<BasketType> createBasketType(Map<String, dynamic> data) async {
    final response = await _client.post('/api/v1/basket-types', body: data);
    return BasketType.fromJson(response as Map<String, dynamic>);
  }

  Future<BasketType> updateBasketType(
      String id, Map<String, dynamic> data) async {
    final response = await _client.put('/api/v1/basket-types/$id', body: data);
    return BasketType.fromJson(response as Map<String, dynamic>);
  }

  Future<void> inactivateBasketType(String id) async {
    await _client.delete('/api/v1/basket-types/$id');
  }

  Future<Map<String, dynamic>> checkDeletion(String id) async =>
      Map<String, dynamic>.from(
          await _client.get('/api/v1/basket-types/$id/deletion-check') as Map);

  Future<Map<String, dynamic>> deleteFromCatalog(String id) async =>
      Map<String, dynamic>.from(
          await _client.delete('/api/v1/basket-types/$id/catalog') as Map);

  // --- RECEITAS VERSIONADAS ---

  Future<List<RecipeVersion>> getRecipeVersions(String basketTypeId) async {
    final response =
        await _client.get('/api/v1/basket-types/$basketTypeId/recipes');
    if (response is List) {
      return response
          .map((json) => RecipeVersion.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<RecipeVersion?> getActiveRecipe(String basketTypeId) async {
    try {
      final response = await _client
          .get('/api/v1/basket-types/$basketTypeId/recipes/active');
      return RecipeVersion.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<RecipeVersion> createRecipeVersion(
      String basketTypeId, Map<String, dynamic> data) async {
    final response = await _client
        .post('/api/v1/basket-types/$basketTypeId/recipes', body: data);
    return RecipeVersion.fromJson(response as Map<String, dynamic>);
  }
}
