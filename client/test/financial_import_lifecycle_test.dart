import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/services/financial_import_service.dart';
import 'package:zm_cesta_basica_client/views/financial_imports_view.dart';
import 'financial_pdf_import_test.dart' as harness;

class LifecycleApi extends harness.ImportApi {
  int generation = 2;
  bool active = false, failStatements = false, failReaders = false;
  bool withObligation = false, failObligations = false, paginated = false;
  final pageOffsets = <int>[];
  int stateReads = 0;
  @override
  FinancialJson get preview => {
    ...super.preview,
    'import_id': 'entry-$generation',
    'generation': generation,
    'filename': 'Arquivo completo da conferência.pdf',
    if (withObligation) ...{
      'financial_status': 'CONFIRMED',
      'statement_id': 'st1',
      'recorded_payables_count': 1,
      'recorded_destination': 'OPEN',
    },
  };
  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    if (uri.path.endsWith('/import-state')) {
      stateReads++;
      return {
        'lifecycle_version': 1,
        'current_generation': generation,
        'active_import': active
            ? {
                'id': 'entry-$generation',
                'generation': generation,
                'state': 'ACTIVE',
              }
            : null,
        'root_preview_id': active ? 'p1' : null,
      };
    }
    if ((failStatements && uri.path.endsWith('/statements')) ||
        (failReaders && uri.path.endsWith('/readers'))) {
      throw ApiException(statusCode: 503, message: 'Consulta indisponível');
    }
    if (withObligation && uri.path.endsWith('/statements')) {
      return [
        {
          'id': 'st1',
          'statement_type': 'CARD_BILL',
          'import_id': 'entry-$generation',
          'generation': generation,
        },
      ];
    }
    if (uri.path.endsWith('/st1/obligations')) {
      if (failObligations) {
        throw ApiException(statusCode: 503, message: 'Consulta indisponível');
      }
      return [
        {'id': 'pay1', 'status': 'OPEN'},
      ];
    }
    if (paginated && uri.path == '${FinancialImportService.root}/previews') {
      final offset = int.parse(uri.queryParameters['offset'] ?? '0');
      pageOffsets.add(offset);
      return [
        for (var i = offset; i < 51 && i < offset + 50; i++)
          {
            ...preview,
            'id': 'p$i',
            'document_id': 'd$i',
            'import_id': 'entry$i',
            'filename': 'Documento $i.pdf',
            'generation': 1,
            'bill_cycle_version': 1,
            'content_type': 'DETAILED_CARD_BILL',
          },
      ];
    }
    return super.get(path);
  }
}

void main() {
  test(
    'upload replay reads current generation; active entry resumes with GET',
    () async {
      final api = LifecycleApi();
      final service = FinancialImportService(apiClient: api);
      await service.importDocument(harness.sampleFile(), 's1');
      final first = api.writes.singleWhere((w) => w.path.endsWith('/previews'));
      expect((first.body as Map)['expected_generation'], 2);
      api.generation = 3;
      await service.importDocument(harness.sampleFile(), 's1');
      final attempts = api.writes
          .where((w) => w.path.endsWith('/previews'))
          .toList();
      expect((attempts.last.body as Map)['expected_generation'], 3);
      expect(attempts.last.key, isNot(first.key));
      api.active = true;
      final count = api.writes.length;
      final resumed = await service.importDocument(harness.sampleFile(), 's1');
      expect(api.stateReads, 3);
      expect(api.writes.length, count + 1); // The binary upload is allowed.
      expect(resumed['import_id'], 'entry-3');
      expect(api.gets, contains('${FinancialImportService.root}/previews/p1'));
    },
  );

  test(
    'explicit reprocessing carries frozen identity and root precondition',
    () async {
      final api = LifecycleApi();
      final service = FinancialImportService(apiClient: api);
      final context = FinancialImportService.lifecycleContext(api.preview);
      api.generation = 9;
      await service.createPreview(
        'd1',
        sourceId: 's1',
        context: context,
        expectedRootPreviewId: 'p1',
      );
      final body = api.writes.single.body as Map;
      expect(body['explicit_reprocess'], true);
      expect(body['expected_root_preview_id'], 'p1');
      expect(body['import_id'], 'entry-2');
      expect(body['expected_generation'], 2);
      expect(api.stateReads, 0);
    },
  );

  testWidgets(
    'obligation query failure preserves previous facts and explains uncertainty',
    (tester) async {
      final api = LifecycleApi()..withObligation = true;
      await harness.mount(
        tester,
        FinancialImportsView(apiClient: api),
        size: const Size(1100, 1400),
      );
      expect(find.textContaining('Obrigações abertas: 1'), findsOneWidget);
      api.failObligations = true;
      await tester.tap(find.byKey(const ValueKey('refresh-imports')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Obrigações abertas: 1'), findsOneWidget);
      expect(
        find.textContaining(
          'Isso não significa que ele esteja sem contas ou pago',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('situação das contas precisa de nova consulta'),
        findsOneWidget,
      );
      expect(api.writes, isEmpty);
    },
  );

  testWidgets(
    'pagination appends active entries once and refresh starts at zero without writes',
    (tester) async {
      final api = LifecycleApi()..paginated = true;
      await harness.mount(
        tester,
        FinancialImportsView(apiClient: api),
        size: const Size(1100, 1400),
      );
      await tester.scrollUntilVisible(
        find.text('Carregar mais'),
        3000,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 100,
      );
      await harness.click(tester, find.text('Carregar mais'));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('import-entry50')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('import-entry50')), findsOneWidget);
      expect(api.pageOffsets, [0, 50]);
      await tester.tap(find.byKey(const ValueKey('refresh-imports')));
      await tester.pumpAndSettle();
      expect(api.pageOffsets, [0, 50, 0]);
      expect(find.byKey(const ValueKey('import-entry50')), findsNothing);
      expect(api.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opening and returning never reprocesses; partial refresh preserves entry',
    (tester) async {
      final api = LifecycleApi()..active = true;
      await harness.mount(
        tester,
        FinancialImportsView(apiClient: api),
        size: const Size(1100, 1200),
      );
      expect(find.text('Arquivo completo da conferência.pdf'), findsOneWidget);
      expect(
        find.textContaining('nenhuma conta foi criada nesta importação'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('open-document-entry-2')));
      await tester.pumpAndSettle();
      expect(api.writes, isEmpty);
      Navigator.of(tester.element(find.byType(FinancialPdfPreviewView))).pop();
      await tester.pumpAndSettle();
      api.failStatements = true;
      api.failReaders = true;
      await tester.tap(find.byKey(const ValueKey('refresh-imports')));
      await tester.pumpAndSettle();
      expect(find.text('Arquivo completo da conferência.pdf'), findsOneWidget);
      expect(
        find.textContaining(
          'Não foi possível atualizar os documentos confirmados',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Não foi possível consultar os formatos de leitura',
        ),
        findsOneWidget,
      );
      expect(api.writes, isEmpty);
    },
  );
}
