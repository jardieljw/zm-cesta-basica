import 'dart:async';
import 'package:zm_cesta_basica_client/core/api_client.dart';

/// Synthetic REST fixture for the approved app composition, never a company DB.
class ApprovedOverviewApi extends ApiClient {
  final List<String> requests = [];
  bool offline = false;
  int extraReceivables = 0;
  bool comparisonFixture = false;
  Completer<void>? detailGate;
  @override
  Future<ApiOrigin> readOrigin() async => ApiOrigin(
    url: 'https://overview-test.invalid:8000',
    fingerprint: 'AA:BB',
  );
  @override
  ApiClient bindOrigin(ApiOrigin origin) => this;
  @override
  void close() {}
  @override
  Future<dynamic> get(String path) async {
    requests.add(path);
    if (offline) throw ApiException(statusCode: 0, message: 'Offline');
    if (path.startsWith('/api/v1/dashboard/business-summary')) {
      final today = Uri.parse(path).queryParameters['filter_type'] == 'today';
      return {
        'filter_info': {
          'filter_type': today ? 'today' : 'range',
          'label': today ? 'Hoje' : 'Período',
          'start_date': today
              ? (comparisonFixture
                    ? '2026-10-16T03:00:00Z'
                    : '2026-10-17T03:00:00Z')
              : '2026-10-12T03:00:00Z',
          'end_date': today ? '2026-10-18T02:59:59Z' : '2026-10-19T02:59:59Z',
        },
        'sales': {
          'sold_count': today ? 8 : 32,
          'total_sold_cents': today ? 86000 : 344000,
          'sales': [],
        },
        'inventory': {
          'total_products_count': 3,
          'low_stock_products_count': 1,
          'low_stock_items': [
            {
              'id': 'rice',
              'name': 'Arroz',
              'base_unit': 'pacotes',
              'current_stock': 12,
              'min_stock': 15,
              'difference': 3,
            },
          ],
        },
        'financial': {
          'sales_revenue_cents': today ? 86000 : 344000,
          'sold_baskets_cost_cents': today ? 50000 : 205000,
          'gross_profit_cents': today ? 36000 : 139000,
          'operating_expenses_paid_cents': today ? 6000 : 45000,
          'operating_result_cents': today ? 30000 : 94000,
          'sales_without_cost_count': today ? 0 : 1,
          'payables_due_in_period_cents': 128000,
          'receivables_due_in_period_cents': 195000,
          'payables_records': [
            {
              'id': 'pay-one',
              'payable_number': 208,
              'beneficiary': 'Fornecedor de alimentos',
              'category': 'FORNECEDOR',
              'nature': 'BUSINESS',
              'due_date': '2026-10-17T00:00:00-03:00',
              'original_amount_cents': 68000,
              'paid_amount_cents': 0,
              'balance_cents': 68000,
              'status': 'OPEN',
            },
            {
              'id': 'pay-late',
              'payable_number': 207,
              'beneficiary': 'Conta atrasada',
              'category': 'FORNECEDOR',
              'nature': 'BUSINESS',
              'due_date': '2026-10-16T00:00:00-03:00',
              'original_amount_cents': 60000,
              'paid_amount_cents': 0,
              'balance_cents': 60000,
              'status': 'OPEN',
            },
          ],
          'receivables_records': [
            if (!comparisonFixture)
              {
                'id': 'ana',
                'sale_number': 1042,
                'customer_name': 'Ana Souza',
                'due_date': '2026-10-17T00:00:00-03:00',
                'original_amount_cents': 125000,
                'paid_amount_cents': 0,
                'balance_cents': 125000,
                'status': 'OPEN',
              },
            {
              'id': 'bruno',
              'sale_number': 1043,
              'customer_name': 'Bruno Lima',
              'due_date': '2026-10-18T00:00:00-03:00',
              'original_amount_cents': 90000,
              'paid_amount_cents': 20000,
              'balance_cents': 70000,
              'status': 'PARTIAL',
            },
            for (var i = 0; i < extraReceivables; i++)
              {
                'id': 'extra-$i',
                'sale_number': 2000 + i,
                'customer_name': 'Cliente $i',
                'due_date': '2026-10-20T00:00:00-03:00',
                'original_amount_cents': 100,
                'paid_amount_cents': 0,
                'balance_cents': 100,
                'status': 'OPEN',
              },
          ],
        },
      };
    }
    if (path == '/api/v1/receivables/bruno') await detailGate?.future;
    if (path == '/api/v1/receivables/bruno') {
      return {
        'id': 'bruno',
        'sale_id': 'sale-bruno',
        'sale_number': 1043,
        'customer_id': 'customer-bruno',
        'customer_name': 'Bruno Lima',
        'due_date': '2026-10-18T00:00:00',
        'original_amount_cents': 90000,
        'paid_amount_cents': 20000,
        'balance_cents': 70000,
        'status': 'PARTIAL',
        'sale_date': '2026-10-16T15:00:00Z',
        'created_at': '2026-10-16T15:00:00Z',
        'updated_at': '2026-10-17T15:00:00Z',
        'payment_review_version': 1,
        'payments': [],
      };
    }
    throw StateError('Unexpected test request $path');
  }
}
