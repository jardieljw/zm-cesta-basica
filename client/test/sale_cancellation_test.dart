import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/sales_view.dart';

class _CancelApi extends ApiClient {
  Map<String, dynamic>? payload;
  final sale = <String, dynamic>{
    'id': 'sale',
    'sale_number': 1,
    'status': 'CONFIRMED',
    'sale_date': '2026-10-14T12:00:00Z',
    'total_amount_cents': 10000,
    'items': [
      {
        'id': 'item',
        'basket_type_id': 'basket',
        'basket_type_name': 'Cesta Básica',
        'quantity': 1,
        'unit_price_cents': 10000,
        'total_cents': 10000,
        'assembled_on_demand': true
      },
    ],
  };
  @override
  Future<dynamic> get(String path) async => [sale];
  @override
  Future<dynamic> post(String path,
      {dynamic body, String? idempotencyKey, bool isMutation = true}) async {
    expect(path, '/api/v1/sales/sale/cancel');
    payload = Map<String, dynamic>.from(body as Map);
    return {...sale, 'status': 'CANCELED'};
  }
}

void main() {
  setUpAll(AppFormatters.initialize);
  for (final unassembled in [true, false]) {
    testWidgets('cancel requires a physical choice and sends it ($unassembled)',
        (tester) async {
      final api = _CancelApi();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: SalesView(apiClient: api),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'sales list');
      await tester.tap(find.text('Cancelar Venda'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'cancel dialog');
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'Venda incorreta');
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(ElevatedButton)));
      await tester.pumpAndSettle();
      expect(api.payload, isNull);
      expect(
          find.text(
              'Informe a situação de todas as montagens antes de cancelar.'),
          findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find
          .text(unassembled
              ? 'A montagem não aconteceu'
              : 'As cestas continuam montadas')
          .last);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(ElevatedButton)));
      await tester.pumpAndSettle();
      expect(api.payload!['unassembled_item_ids'], unassembled ? ['item'] : []);
      expect(tester.takeException(), isNull);
    });
  }
}
