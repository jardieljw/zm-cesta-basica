import '../core/api_client.dart';
import '../models/product.dart';

class ProductService {
  final ApiClient _client;

  ProductService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Product>> getProducts({
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
    final response = await _client.get('/api/v1/products$query');

    if (response is List) {
      return response.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Product> getProduct(String id) async {
    final response = await _client.get('/api/v1/products/$id');
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await _client.post('/api/v1/products', body: data);
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/api/v1/products/$id', body: data);
    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<void> inactivateProduct(String id) async {
    await _client.delete('/api/v1/products/$id');
  }

  // --- EMBALAGENS ---

  Future<List<ProductPackaging>> getPackagings(String productId) async {
    final response = await _client.get('/api/v1/products/$productId/packagings');
    if (response is List) {
      return response.map((json) => ProductPackaging.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ProductPackaging> createPackaging(String productId, Map<String, dynamic> data) async {
    final response = await _client.post('/api/v1/products/$productId/packagings', body: data);
    return ProductPackaging.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductPackaging> updatePackaging(String packagingId, Map<String, dynamic> data) async {
    final response = await _client.put('/api/v1/packagings/$packagingId', body: data);
    return ProductPackaging.fromJson(response as Map<String, dynamic>);
  }

  Future<void> inactivatePackaging(String packagingId) async {
    await _client.delete('/api/v1/packagings/$packagingId');
  }
}
