import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/dashboard.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/services/dashboard_service.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/dashboard_view.dart';

class _BusinessApi extends ApiClient {
  String? requestedPath;
  @override
  Future<dynamic> get(String path) async {
    requestedPath = path;
    return {
      'filter_info': {'filter_type': 'all', 'label': 'Todo o período'},
      'sales': {'sold_count': 1, 'total_sold_cents': 30000},
      'inventory': {'total_products_count': 4, 'low_stock_products_count': 0},
      'financial': {
        'sales_revenue_cents': 30000,
        'sold_baskets_cost_cents': 20000,
        'gross_profit_cents': 10000,
        'operating_expenses_paid_cents': 3000,
        'operating_result_cents': 7000,
        'effective_received_cents': 15000,
        'effective_paid_cents': 23000,
        'payment_difference_cents': -8000,
        'receivables_open_cents': 15000,
        'received_records': [
          {
            'id': 'received',
            'description': 'Parcela recebida da Venda #1',
            'amount_cents': 15000,
            'occurred_at': '2026-10-14T01:28:00Z',
            'payment_method': 'PIX',
            'is_reversal': false,
          }
        ],
      },
    };
  }
}

void main() {
  setUpAll(AppFormatters.initialize);
  for (final width in [360.0, 1280.0]) {
    testWidgets(
        'business dashboard at width $width explains payments without treasury balances',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _BusinessApi();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: DashboardView(service: DashboardService(client: api)),
      ));
      await tester.pumpAndSettle();
      expect(
          api.requestedPath, startsWith('/api/v1/dashboard/business-summary'));
      expect(find.text('Lucro bruto das vendas'), findsOneWidget);
      expect(find.text('Recebimentos confirmados'), findsOneWidget);
      expect(find.text('Resultado gerencial do período'), findsOneWidget);
      expect(find.textContaining('Saldo de Caixa'), findsNothing);
      expect(find.textContaining('Tesouraria'), findsNothing);
      expect(find.textContaining('Livro-Caixa'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Recebimentos confirmados'));
      await tester.tap(find.text('Recebimentos confirmados'));
      await tester.pumpAndSettle();
      expect(find.text('Parcela recebida da Venda #1'), findsOneWidget);
      expect(find.textContaining('BUSINESS'), findsNothing);
      expect(find.textContaining('Saldo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  test(
      'financial model parses corrected totals and payment commands need no account',
      () {
    final financial = DashboardFinancialSummary.fromJson({
      'effective_received_cents': 15000,
      'effective_paid_cents': 23000,
      'payment_difference_cents': -8000,
      'gross_profit_cents': 10000,
      'operating_result_cents': 7000,
    });
    expect(financial.paymentDifferenceCents, -8000);
    expect(financial.operatingResultCents, 7000);
    final payment =
        PayablePaymentCreate(amountCents: 3000, paymentMethod: 'PIX');
    expect(payment.toJson()['account_id'], isNull);
  });
}
