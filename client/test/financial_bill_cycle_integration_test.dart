import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'financial_pdf_import_test.dart' as harness;

class CycleApi extends harness.ImportApi {
  bool loseReply = false, committed = false;
  bool conflictOnce = false;
  int currentRevision = 0;
  final requestedReferences = <String?>[];
  int capability = 1;
  FinancialJson? recordedPayment;
  @override
  FinancialJson get preview => {
    ...super.preview,
    'bill_cycle_version': 1,
    'extracted_header': {
      'statement_type': 'CARD_BILL',
      'due_on': '2026-10-24',
      'total_amount_cents': 13000,
    },
    'readiness': {'can_prepare_bill': true, 'details_status': 'RECONCILED'},
    'items_count': 3,
  };
  List<FinancialJson> get items => [
    {
      'description': 'Loja A - 3/10',
      'transaction_date': '2026-10-01',
      'amount_cents': 10000,
      'installment_number': 3,
      'total_installments': 10,
    },
    {
      'description': 'Loja B',
      'transaction_date': '2026-10-02',
      'amount_cents': 5000,
    },
    {
      'description': 'Estorno exemplo',
      'transaction_date': '2026-10-03',
      'amount_cents': -2000,
    },
  ];
  FinancialJson get cycle => {
    'version': 1,
    'payable_id': 'net-title',
    'reference': '2026-10',
    'revision': 1,
    'destination': 'OPEN',
    'composition': {
      'stock_cents': 0,
      'business_cents': 0,
      'personal_cents': 0,
      'unclassified_cents': 13000,
    },
    'financial_source': {
      'name': 'Cartão de teste',
      'institution': 'Banco de teste',
    },
    'details_status': 'RECONCILED',
    'items': items,
  };
  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    if (uri.path == '${FinancialImportService.root}/capabilities') {
      return {
        'import_lifecycle_version': 1,
        'bill_cycle_version': capability,
        'bill_review_version': 2,
        'installment_agenda_version': 1,
        'segments_version': 1,
        'payable_filter_version': 1,
      };
    }
    if (uri.path.endsWith('/bill-integration')) {
      requestedReferences.add(uri.queryParameters['reference']);
      return {
        'version': 1,
        'expected_revision': currentRevision,
        'header': preview['extracted_header'],
        'financial_source': source,
        'items': items,
        if (currentRevision > 0) 'cycle': cycle,
      };
    }
    if (uri.path == '/api/v1/payables/net-title') {
      return {
        'id': 'net-title',
        'payable_number': 7,
        'description': 'Fatura do cartão · 2026-10',
        'beneficiary': 'Banco de teste',
        'category': 'CARTAO_CREDITO',
        'nature': 'UNCLASSIFIED',
        'original_amount_cents': 13000,
        'paid_amount_cents': recordedPayment == null ? 0 : 13000,
        'balance_cents': recordedPayment == null ? 13000 : 0,
        'due_date': '2026-10-24T00:00:00',
        'status': recordedPayment == null ? 'OPEN' : 'PAID',
        'created_at': '2026-10-19T12:00:00Z',
        'updated_at': '2026-10-19T12:00:00Z',
        'payments': [if (recordedPayment != null) recordedPayment],
        'payment_review_version': 2,
        'financial_bill': cycle,
      };
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
    if (path == '/api/v1/payables/net-title/payments') {
      writes.add((path: path, body: body, key: idempotencyKey));
      recordedPayment = {
        'id': 'payment',
        'payable_id': 'net-title',
        'account_id': 'account',
        'payment_date': '${(body as Map)['payment_business_date']}T12:00:00Z',
        'created_at': '2026-10-19T12:00:00Z',
        'amount_cents': 13000,
        'payment_method': 'PIX',
        'status': 'CONFIRMED',
        'bill_revision_id': 'revision',
        'stock_cents': 0,
        'business_cents': 0,
        'personal_cents': 0,
        'unclassified_cents': 13000,
      };
      return recordedPayment;
    }
    if (path.endsWith('/integrate-bill')) {
      writes.add((path: path, body: body, key: idempotencyKey));
      if (conflictOnce) {
        conflictOnce = false;
        currentRevision = 1;
        throw ApiException(
          statusCode: 409,
          message: 'Changed revision',
          errorCode: 'FINANCIAL_BILL_REVISION_CONFLICT',
        );
      }
      committed = true;
      if (loseReply) {
        loseReply = false;
        throw ApiException(statusCode: 0, message: 'Timeout');
      }
      return {
        ...cycle,
        'destination': (body as Map)['destination'],
        'payable_id': body['destination'] == 'OPEN' ? 'net-title' : null,
      };
    }
    return super.post(
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      isMutation: isMutation,
    );
  }
}

Future<void> openDraft(
  WidgetTester tester,
  CycleApi api, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  await harness.mount(
    tester,
    FinancialPdfPreviewView(
      service: FinancialImportService(apiClient: api),
      previewId: 'p1',
    ),
    size: size,
    scale: scale,
  );
  await harness.click(tester, find.byKey(const ValueKey('bill-cycle-open')));
}

Future<void> chooseOpen(WidgetTester tester) async {
  await harness.click(tester, find.byType(DropdownButtonFormField<String>));
  await harness.click(
    tester,
    find
        .text('Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga')
        .last,
  );
  await harness.click(tester, find.byType(CheckboxListTile).last);
}

void main() {
  setUpAll(harness.loadImportFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'T10 single final confirmation opens payable with all signed items and installment',
    (tester) async {
      final api = CycleApi();
      await openDraft(tester, api);
      expect(api.writes, isEmpty);
      await chooseOpen(tester);
      final selected = tester.getRect(
        find
            .text(
              'Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga',
            )
            .first,
      );
      final selection = tester.getRect(find.byType(DropdownButton<String>));
      expect(selected.top, greaterThanOrEqualTo(selection.top));
      expect(selected.bottom, lessThanOrEqualTo(selection.bottom));
      await harness.capture(tester, 'e2-confirm-390');
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect(api.writes.length, 1);
      expect(api.writes.single.path, endsWith('/integrate-bill'));
      expect((api.writes.single.body as Map)['total_amount_cents'], 13000);
      expect((api.writes.single.body as Map).containsKey('purpose'), isFalse);
      await harness.click(tester, find.text('Ver conta e pagamentos'));
      await harness.click(tester, find.text('Itens da fatura'));
      expect(find.text('Loja A - 3/10'), findsOneWidget);
      expect(find.text('Estorno exemplo'), findsOneWidget);
      expect(find.textContaining('3 de 10'), findsWidgets);
      expect(find.text('Finalidade não informada'), findsOneWidget);
      await harness.capture(tester, 'e2-payable-items-390');
      await harness.click(tester, find.byKey(const ValueKey('payment-start')));
      await harness.click(tester, find.byKey(const ValueKey('payment-method')));
      await harness.click(tester, find.text('PIX').last);
      await harness.click(tester, find.byKey(const ValueKey('payment-review')));
      await harness.click(
        tester,
        find.byKey(const ValueKey('payment-confirm')),
      );
      expect((api.writes.last.body as Map)['expected_bill_revision'], 1);
      expect(find.text('Pagamento registrado'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('T15 lost integration response retries exact body and key', (
    tester,
  ) async {
    final api = CycleApi()..loseReply = true;
    await openDraft(tester, api);
    await chooseOpen(tester);
    await harness.click(
      tester,
      find.byKey(const ValueKey('bill-integrate-confirm')),
    );
    expect(api.committed, isTrue);
    await harness.click(tester, find.text('Retomar confirmação'));
    expect(api.writes.length, 2);
    expect(api.writes[1].key, api.writes[0].key);
    expect(api.writes[1].body, api.writes[0].body);
  });
  testWidgets(
    'T15 stale review reloads the declared month and requires a fresh acknowledgement',
    (tester) async {
      final api = CycleApi()..conflictOnce = true;
      await openDraft(tester, api);
      await chooseOpen(tester);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect(api.requestedReferences.last, '2026-10');
      expect(api.writes.length, 1);
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const ValueKey('bill-integrate-confirm')),
            )
            .onPressed,
        isNull,
      );
      await harness.click(tester, find.byType(CheckboxListTile).last);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect((api.writes.last.body as Map)['expected_revision'], 1);
      expect(api.writes.last.key, isNot(api.writes.first.key));
      expect(
        find.textContaining('Fatura adicionada a Contas a Pagar'),
        findsOneWidget,
      );
    },
  );
  for (final config in [
    (const Size(320, 780), 1.7),
    (const Size(1200, 900), 1.0),
  ]) {
    testWidgets('T05 no implicit debt or purpose; layout $config', (
      tester,
    ) async {
      final api = CycleApi();
      await openDraft(tester, api, size: config.$1, scale: config.$2);
      await tester.scrollUntilVisible(
        find.text('Guardar por enquanto; decidir depois'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final selected = tester.getRect(
        find.text('Guardar por enquanto; decidir depois').first,
      );
      final selection = tester.getRect(find.byType(DropdownButton<String>));
      expect(selected.bottom, lessThanOrEqualTo(selection.bottom));
      await harness.click(tester, find.byType(CheckboxListTile).last);
      await harness.click(
        tester,
        find.byKey(const ValueKey('bill-integrate-confirm')),
      );
      expect((api.writes.single.body as Map)['destination'], 'PENDING');
      expect(
        find.textContaining(
          'Você ainda não escolheu adicioná-lo a Contas a Pagar',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing server capability never falls back to old generation', (
    tester,
  ) async {
    final api = CycleApi()..capability = 0;
    await openDraft(tester, api);
    expect(api.writes, isEmpty);
    expect(find.byKey(const ValueKey('bill-integrate-confirm')), findsNothing);
  });
}
