import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/views/financial_installment_agenda_view.dart';
import 'package:zm_cesta_basica_client/views/payables_view.dart';
import 'financial_pdf_import_test.dart' as harness;
import 'financial_e3_review_test.dart' as e3;

class AgendaApi extends e3.CompleteFilterApi {
  bool decided = false, failOnce = false, failRead = false;
  Map<String, dynamic> get agenda => {
    'version': 1,
    'snapshot': 'a' * 64,
    'estimated_cents': 10001,
    'pending_cents': decided ? 0 : 10001,
    'count': 3,
    'items': [
      for (final pair in [
        (1, 'ESTIMATED'),
        (2, decided ? 'REPLACED' : 'PENDING_LINK'),
        (3, 'CANCELED'),
      ])
        {
          'id': 'forecast-${pair.$1}',
          'series_id': 'series',
          'description': 'Loja de exemplo com descrição extensa',
          'number': pair.$1 + 3,
          'total': 10,
          'reference': '2026-11',
          'amount_cents': 10001,
          'estimated_due_on': pair.$1 == 1 ? null : '2026-11-24',
          'state': pair.$2,
          'financial_source': {'id': 's1', 'name': 'Banco · Cartão de teste'},
          'payable': false,
        },
    ],
    'pending_links': [
      if (!decided)
        {
          'occurrence_id': 'occurrence',
          'expected_revision': 1,
          'description': 'Loja de exemplo',
          'number': 4,
          'total': 10,
          'amount_cents': 10002,
          'due_on': '2026-11-26',
          'candidates': [
            {
              'series_id': 'series',
              'description': 'Loja de exemplo',
              'amount_cents': 10001,
              'estimated_due_on': '2026-11-24',
              'origin_reference': '2026-10',
              'origin_number': 3,
              'origin_position': 1,
              'purchase_date': '2026-10-01',
            },
          ],
        },
    ],
    'cancellation_evidence': [
      {
        'source_id': 's1',
        'item_id': 'credit',
        'description': 'Estorno comprovado',
        'amount_cents': -10001,
      },
    ],
  };
  @override
  Future<dynamic> get(String path) async {
    if (path.endsWith('/capabilities')) {
      return {'installment_agenda_version': 1, 'payable_filter_version': 1};
    }
    if (Uri.parse(path).path.endsWith('/installments')) {
      if (failRead) throw ApiException(statusCode: 503, message: 'Unavailable');
      queries.add(Uri.parse(path));
      return agenda;
    }
    final result = await super.get(path);
    if (Uri.parse(path).path == '/api/v1/payables/summary') {
      return {...result as Map, 'installments': agenda};
    }
    return result;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    if (path.endsWith('/installments/decisions')) {
      writes.add((path: path, body: body, key: idempotencyKey));
      if (failOnce) {
        failOnce = false;
        throw ApiException(statusCode: 0, message: 'Timeout');
      }
      decided = true;
      return {'action': body['action']};
    }
    return super.post(
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      isMutation: isMutation,
    );
  }
}

void main() {
  setUpAll(harness.loadImportFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final config in [
    (const Size(320, 780), 1.7),
    (const Size(390, 844), 1.0),
    (const Size(1200, 850), 1.0),
  ]) {
    testWidgets('E4 grouped agenda and decision ${config.$1.width}', (
      tester,
    ) async {
      final api = AgendaApi();
      await harness.mount(
        tester,
        FinancialInstallmentAgendaView(
          service: PayableService(client: api),
          filters: const {'month': '11', 'year': '2026'},
        ),
        size: config.$1,
        scale: config.$2,
      );
      expect(find.textContaining('Estimativas livres:'), findsOneWidget);
      expect(find.text('Pendente de vínculo'), findsWidgets);
      await harness.capture(tester, 'e4-agenda-${config.$1.width.toInt()}');
      await harness.click(tester, find.textContaining('Vincular à série:'));
      expect(find.textContaining('26/11/2026'), findsWidgets);
      expect(find.textContaining('24/11/2026'), findsWidgets);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Compra e divergências conferidas',
      );
      await tester.pumpAndSettle();
      await harness.capture(tester, 'e4-decision-${config.$1.width.toInt()}');
      await harness.click(tester, find.text('Confirmar decisão'));
      expect(api.writes.single.body, containsPair('action', 'LINK'));
      expect(find.text('Pendente de vínculo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'E4 unknown day and states; no payment action; cancellation with evidence',
    (tester) async {
      final api = AgendaApi()..decided = true;
      await harness.mount(
        tester,
        FinancialInstallmentAgendaView(
          service: PayableService(client: api),
          filters: const {},
        ),
      );
      expect(
        find.text('Dia desconhecido · somente mês previsto'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Substituída pela cobrança real'),
        findsOneWidget,
      );
      expect(find.textContaining('Cancelada com evidência'), findsOneWidget);
      expect(find.text('Pagar'), findsNothing);
      expect(find.text('24/11/2026'), findsWidgets);
      expect(find.text('2026-11-24'), findsNothing);
      await harness.click(
        tester,
        find.text('Registrar cancelamento comprovado'),
      );
      await tester.enterText(find.byType(TextFormField).first, '4');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Estorno comprovado').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Documento cancela as parcelas 4 a 10',
      );
      await tester.pumpAndSettle();
      await harness.click(tester, find.text('Confirmar decisão'));
      expect(api.writes.single.body, containsPair('action', 'CANCEL'));
      expect(
        api.writes.single.body,
        containsPair('evidence_item_id', 'credit'),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'E4 uncertain retry preserves body and key; query filters retained',
    (tester) async {
      final api = AgendaApi()..failOnce = true;
      await harness.mount(
        tester,
        FinancialInstallmentAgendaView(
          service: PayableService(client: api),
          filters: const {
            'source_query': 'Banco',
            'merchant': 'Loja',
            'month': '11',
          },
        ),
      );
      await harness.click(tester, find.text('É outra compra'));
      await tester.enterText(
        find.byType(TextFormField).last,
        'Outra compra comprovada',
      );
      await tester.pumpAndSettle();
      await harness.click(tester, find.text('Confirmar decisão'));
      await harness.click(tester, find.text('Reenviar a mesma decisão'));
      expect(api.writes.length, 2);
      expect(api.writes[0].key, api.writes[1].key);
      expect(api.writes[0].body, api.writes[1].body);
      expect(
        api.queries.last.queryParameters,
        containsPair('source_query', 'Banco'),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'E4 payable query keeps confirmed total separate and opens agenda',
    (tester) async {
      final api = AgendaApi();
      await harness.mount(
        tester,
        PayablesView(service: PayableService(client: api)),
        size: const Size(1200, 850),
      );
      await harness.click(tester, find.text('Consultar agenda e vínculos'));
      expect(find.text('Parcelas dos próximos meses'), findsOneWidget);
      expect(find.textContaining('Estimativas livres:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('E4 query failure is not empty or zero', (tester) async {
    final api = AgendaApi()..failRead = true;
    await harness.mount(
      tester,
      FinancialInstallmentAgendaView(
        service: PayableService(client: api),
        filters: const {},
      ),
    );
    expect(find.text('Nenhuma previsão neste filtro.'), findsNothing);
    expect(find.textContaining('Estimativas livres:'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
