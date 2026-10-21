import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'package:zm_cesta_basica_client/views/financial_import_removal_view.dart';
import 'package:zm_cesta_basica_client/views/financial_bill_integration_view.dart';
import 'financial_pdf_import_test.dart' as harness;
import 'financial_bill_cycle_integration_test.dart' as cycles;

class RemovalApi extends cycles.CycleApi {
  bool removed = false, lostReply = false, blocked = false;
  int removalCapability = 1;
  @override
  FinancialJson get preview => {
    ...super.preview,
    'content_type': 'DETAILED_CARD_BILL',
  };
  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    if (uri.path.endsWith('/capabilities')) {
      return {
        ...await super.get(path) as Map,
        'import_removal_version': removalCapability,
      };
    }
    if (uri.path.endsWith('/removal')) {
      return {
        'filename': 'Fatura de teste.pdf',
        'snapshot': 'b' * 64,
        'already_removed': removed,
        'can_remove': !blocked,
        'blocked': blocked
            ? [
                {
                  'code': 'PAYMENT_EXISTS',
                  'message':
                      'Esta conta tem pagamento registrado. Abra a conta e estorne o pagamento incorreto.',
                  'payable_id': 'net-title',
                  'payable_number': 7,
                },
              ]
            : [],
        'payables': [
          {'id': 'net-title', 'number': 7, 'balance_cents': 13000},
        ],
        'series_count': 1,
      };
    }
    if (uri.path == '${FinancialImportService.root}/previews' && removed) {
      return [];
    }
    return super.get(path);
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    if (path.endsWith('/remove')) {
      writes.add((path: path, body: body, key: idempotencyKey));
      removed = true;
      if (lostReply) {
        lostReply = false;
        throw ApiException(statusCode: 0, message: 'Lost response');
      }
      return {'removed': true};
    }
    return super.post(
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      isMutation: isMutation,
    );
  }
}

class SavedApi extends RemovalApi {
  SavedApi({required this.withdrawn});
  final bool withdrawn;
  @override
  Future<dynamic> get(String path) async {
    final data = await super.get(path);
    if (Uri.parse(path).path.endsWith('/bill-integration')) {
      return {
        ...data as Map,
        'expected_revision': 1,
        'readiness': {'details_status': 'RECONCILED'},
        'cycle': {
          ...cycle,
          'preview_id': 'p1',
          'revision': 1,
          'import_withdrawn': withdrawn,
          'due_on': '2026-10-24',
          'total_amount_cents': 13000,
          'destination': withdrawn ? 'OPEN' : 'HISTORY',
          'payable_id': withdrawn ? 'net-title' : null,
        },
      };
    }
    return data;
  }
}

class RestoredDueApi extends SavedApi {
  RestoredDueApi() : super(withdrawn: true);
  @override
  FinancialJson get preview => {
    ...super.preview,
    'extracted_header': {
      'statement_type': 'CARD_BILL',
      'total_amount_cents': 13000,
    },
    'header_candidates': {
      'due_on': [
        {'value': '2026-10-24', 'page_number': 2},
        {'value': '2026-10-26', 'page_number': 1},
      ],
    },
  };
  @override
  Future<dynamic> get(String path) async {
    final data = await super.get(path);
    if (Uri.parse(path).path.endsWith('/bill-integration')) {
      return {
        ...data as Map,
        'header_candidates': preview['header_candidates'],
        'cycle': {...data['cycle'] as Map, 'due_on': '2026-10-26'},
      };
    }
    return data;
  }
}

void main() {
  setUpAll(harness.loadImportFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [const Size(320, 780), const Size(1200, 900)]) {
    testWidgets('Exclusão é revisada e retira documento da lista $size', (
      tester,
    ) async {
      final api = RemovalApi();
      await harness.mount(
        tester,
        FinancialImportsView(service: FinancialImportService(apiClient: api)),
        size: size,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('remove-import-p1')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Ver documento'), findsOneWidget);
      await harness.click(
        tester,
        find.byKey(const ValueKey('remove-import-p1')),
      );
      expect(find.byType(FinancialImportRemovalView), findsOneWidget);
      expect(api.writes, isEmpty);
      expect(
        find.text('#7 · ${AppFormatters.formatCurrency(13000)}'),
        findsOneWidget,
      );
      await harness.capture(tester, 'e57-excluir-${size.width.toInt()}');
      await harness.click(
        tester,
        find.byKey(const ValueKey('confirm-import-removal')),
      );
      expect(find.byType(FinancialImportRemovalView), findsNothing);
      expect(find.byKey(const ValueKey('remove-import-p1')), findsNothing);
      expect(api.writes.single.path, endsWith('/documents/d1/remove'));
      expect(api.writes.single.key, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Resposta perdida retoma exatamente o mesmo comando', (
    tester,
  ) async {
    final api = RemovalApi()..lostReply = true;
    await harness.mount(
      tester,
      FinancialImportsView(service: FinancialImportService(apiClient: api)),
    );
    await harness.click(tester, find.byKey(const ValueKey('remove-import-p1')));
    await harness.click(
      tester,
      find.byKey(const ValueKey('confirm-import-removal')),
    );
    expect(find.text('Retomar exclusão'), findsOneWidget);
    await harness.click(
      tester,
      find.byKey(const ValueKey('confirm-import-removal')),
    );
    expect(api.writes.length, 2);
    expect(api.writes.first.body, api.writes.last.body);
    expect(api.writes.first.key, api.writes.last.key);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Pagamento impede exclusão e oferece acesso à conta', (
    tester,
  ) async {
    final api = RemovalApi()..blocked = true;
    await harness.mount(
      tester,
      FinancialImportsView(service: FinancialImportService(apiClient: api)),
    );
    await harness.click(tester, find.byKey(const ValueKey('remove-import-p1')));
    expect(find.byKey(const ValueKey('confirm-import-removal')), findsNothing);
    expect(find.text('Ver conta e pagamentos'), findsOneWidget);
    expect(
      find.textContaining('Esta conta tem pagamento registrado.'),
      findsOneWidget,
    );
    expect(api.writes, isEmpty);
  });
  testWidgets(
    'Fatura guardada explica ausência no financeiro e oferece adicionar',
    (tester) async {
      final api = SavedApi(withdrawn: false);
      await harness.mount(
        tester,
        FinancialBillIntegrationView(
          service: FinancialImportService(apiClient: api),
          preview: api.preview,
        ),
      );
      expect(
        find.text(
          'Esta fatura está guardada para consulta. Ela não foi adicionada a Contas a Pagar.',
        ),
        findsOneWidget,
      );
      await harness.click(
        tester,
        find.text('Adicionar esta fatura a Contas a Pagar'),
      );
      expect(
        find.byKey(const ValueKey('bill-integrate-confirm')),
        findsOneWidget,
      );
      expect(api.writes, isEmpty);
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const ValueKey('bill-integrate-confirm')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'Arquivo reimportado exige confirmação antes de restabelecer conta',
    (tester) async {
      final api = SavedApi(withdrawn: true);
      await harness.mount(
        tester,
        FinancialBillIntegrationView(
          service: FinancialImportService(apiClient: api),
          preview: api.preview,
        ),
      );
      expect(
        find.textContaining('Você importou este arquivo novamente.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Esta conferência já está salva.'),
        findsNothing,
      );
      expect(api.writes, isEmpty);
      await cycles.chooseOpen(tester);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect((api.writes.single.body as Map)['expected_revision'], 1);
    },
  );
  testWidgets(
    'Reimportação conserva a correção de data e o destino escolhidos nesta revisão',
    (tester) async {
      final api = RestoredDueApi();
      await harness.mount(
        tester,
        FinancialBillIntegrationView(
          service: FinancialImportService(apiClient: api),
          preview: api.preview,
        ),
      );
      await cycles.chooseOpen(tester);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-due-2026-10-24')),
      );
      await harness.click(tester, find.byType(CheckboxListTile).last);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      final command = api.writes.single.body as Map;
      expect(command['due_on'], '2026-10-24');
      expect(command['destination'], 'OPEN');
      expect(command['due_conflict_resolved'], isTrue);
    },
  );
}
