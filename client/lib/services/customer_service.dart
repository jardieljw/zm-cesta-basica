import '../core/api_client.dart';
import '../models/customer.dart';

class CustomerService {
  final ApiClient _client;

  CustomerService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Customer>> getCustomers({
    String? search,
    bool? isActive,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String>[
      'limit=$limit',
      'offset=$offset',
    ];
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }
    if (isActive != null) {
      queryParams.add('is_active=$isActive');
    }

    final query = '?${queryParams.join('&')}';
    final response = await _client.get('/api/v1/customers$query');

    final rawList = response as List<dynamic>? ?? [];
    return rawList
        .map((j) => Customer.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> getCustomer(String id) async {
    final response = await _client.get('/api/v1/customers/$id');
    return Customer.fromJson(response as Map<String, dynamic>);
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await _client.post('/api/v1/customers', body: data);
    return Customer.fromJson(response as Map<String, dynamic>);
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/api/v1/customers/$id', body: data);
    return Customer.fromJson(response as Map<String, dynamic>);
  }

  Future<Customer> deleteCustomer(String id) async {
    final response = await _client.delete('/api/v1/customers/$id');
    return Customer.fromJson(response as Map<String, dynamic>);
  }

  Future<CustomerStatementResponse> getCustomerStatement(String id) async {
    final response = await _client.get('/api/v1/customers/$id/statement');
    return CustomerStatementResponse.fromJson(response as Map<String, dynamic>);
  }
}
