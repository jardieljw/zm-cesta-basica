import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/services/receivable_payment_coordinator.dart';
import 'package:zm_cesta_basica_client/views/receivable_payment_view.dart';
import 'package:zm_cesta_basica_client/views/receivables_view.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'helpers/receivable_payment_ui_fake.dart';

class PagedReceivables extends UIReceivablePaymentService {
  final List<int> offsets = [];
  @override
  Future<List<SalesReceivable>> getReceivables({
    String? customerId,
    String? status,
    bool openOnly = false,
    bool overdueOnly = false,
    DateTime? saleDateFrom,
    DateTime? saleDateTo,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    String? basketTypeId,
    int? minAmountCents,
    int? maxAmountCents,
    int limit = 100,
    int offset = 0,
  }) async {
    offsets.add(offset);
    listQueries.add((openOnly: openOnly, status: status, offset: offset));
    return List.generate(
      offset == 0 ? 100 : 1,
      (i) => uiReceivableTitle(id: 'receivable-${offset + i}'),
    );
  }
}

Future<void> mountReceipt(
  WidgetTester tester,
  UIReceivablePaymentService service, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  bool list = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final flow = ReceivablePaymentCoordinator(service: service);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('receipt-capture'),
          child: child!,
        ),
      ),
      home: list
          ? ReceivablesView(service: service, paymentCoordinator: flow)
          : ReceivablePaymentView(
              receivableId: service.title.id,
              coordinator: flow,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> clickReceipt(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> startReceipt(WidgetTester tester) =>
    clickReceipt(tester, find.byKey(const ValueKey('payment-start')));
Future<void> receiptMethod(WidgetTester tester, [String label = 'PIX']) async {
  await clickReceipt(tester, find.byKey(const ValueKey('payment-method')));
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> reviewReceipt(WidgetTester tester) =>
    clickReceipt(tester, find.byKey(const ValueKey('payment-review')));
Future<void> confirmReceipt(WidgetTester tester) =>
    clickReceipt(tester, find.byKey(const ValueKey('payment-confirm')));
Future<void> openReceiptFilter(WidgetTester tester) => clickReceipt(
  tester,
  find.descendant(
    of: find.byKey(const ValueKey('receipt-filters')),
    matching: find.text('Filtros'),
  ),
);
Future<void> selectOpenReceipts(WidgetTester tester) async {
  await openReceiptFilter(tester);
  await clickReceipt(
    tester,
    find.byType(DropdownButtonFormField<String?>).first,
  );
  await clickReceipt(tester, find.text('Em aberto, incluindo parciais').last);
  await openReceiptFilter(tester);
}

Future<void> receiptShot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('receipt-capture')),
  );
  final disabled = debugDisableShadows;
  debugDisableShadows = false;
  try {
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/fe-054-preview').create(recursive: true);
      await File(
        'build/fe-054-preview/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = disabled;
    boundary.markNeedsPaint();
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    if (Platform.isWindows) {
      final segoe = FontLoader('Segoe UI')
        ..addFont(
          File(
            'C:/Windows/Fonts/segoeui.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await segoe.load();
      final semibold = FontLoader('Segoe UI Semibold')
        ..addFont(
          File(
            'C:/Windows/Fonts/seguisb.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await semibold.load();
      for (final entry in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final file = File(
          'C:/dev/flutter/bin/cache/artifacts/material_fonts/${entry.value}',
        );
        if (await file.exists()) {
          final loader = FontLoader(entry.key)
            ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
          await loader.load();
        }
      }
    }
  });

  testWidgets(
    'integral starts selected and registers remaining balance, not original sale amount',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      final kind = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(kind.selected, {false});
      expect(
        find.byKey(const ValueKey('payment-amount')).hitTestable(),
        findsNothing,
      );
      await receiptMethod(tester);
      await reviewReceipt(tester);
      expect(service.calls, isEmpty);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Venda #73'), findsOneWidget);
      await receiptShot(tester, 'review-mobile');
      await confirmReceipt(tester);
      expect(service.recorded.values.single.amountCents, 68000);
      expect(service.title.balanceCents, 0);
      expect(find.text('Recebimento registrado'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hidden partial input is ignored and editing retains notes before confirmation',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await clickReceipt(tester, find.text('Parcial'));
      await tester.enterText(
        find.byKey(const ValueKey('payment-amount')),
        '200',
      );
      await receiptMethod(tester);
      await tester.enterText(
        find.byKey(const ValueKey('payment-notes')),
        'Referência do cliente',
      );
      await reviewReceipt(tester);
      expect(service.calls, isEmpty);
      await clickReceipt(tester, find.text('Editar'));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-notes')))
            .controller!
            .text,
        'Referência do cliente',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-amount')))
            .controller!
            .text,
        '200',
      );
      await clickReceipt(tester, find.text('Integral'));
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(service.calls.length, 1);
      expect(service.recorded.values.single.amountCents, 68000);
      expect(service.recorded.values.single.notes, 'Referência do cliente');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lost reply remains available after reentry even when paid title leaves open list',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService()..dropReply = true;
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await receiptMethod(tester);
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(find.byKey(const ValueKey('payment-resume')), findsOneWidget);
      await mountReceipt(tester, service, list: true);
      await selectOpenReceipts(tester);
      expect(service.title.balanceCents, 0);
      expect(service.listQueries.last.openOnly, isTrue);
      expect(service.listQueries.last.status, isNull);
      expect(find.text('Registros para acompanhar'), findsOneWidget);
      await clickReceipt(tester, find.text('Ana Souza · venda #73'));
      await receiptShot(tester, 'pending-mobile');
      await clickReceipt(tester, find.byKey(const ValueKey('payment-resume')));
      expect(service.recorded.length, 1);
      expect(service.calls.length, 2);
      expect(service.calls[0], service.calls[1]);
      expect(find.text('Recebimento registrado'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sale origin is read-only and receiving preserves the original sale',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await clickReceipt(tester, find.byKey(const ValueKey('payment-origin')));
      expect(service.originReads, 1);
      expect(service.calls, isEmpty);
      expect(find.text('Valor original da venda'), findsOneWidget);
      expect(find.text('7 × Cesta Básica'), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(105000)), findsNWidgets(2));
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      await receiptShot(tester, 'sale-origin-mobile');
      await clickReceipt(tester, find.byType(BackButton));
      await startReceipt(tester);
      await receiptMethod(tester);
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(service.title.balanceCents, 0);
      expect(service.originSale.totalAmountCents, 105000);
      expect(service.originSale.items.single.quantity, 7);
      expect(service.originSale.items.single.totalCents, 105000);
      expect(service.recorded.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unavailable sale origin retries the query without recording money',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService()..failOriginReads = true;
      await mountReceipt(tester, service);
      await clickReceipt(tester, find.byKey(const ValueKey('payment-origin')));
      expect(
        find.text(
          'Não foi possível conferir a venda de origem. Atualize a consulta.',
        ),
        findsOneWidget,
      );
      service.failOriginReads = false;
      await clickReceipt(tester, find.text('Atualizar'));
      expect(service.originReads, 2);
      expect(find.text('Valor original da venda'), findsOneWidget);
      expect(service.calls, isEmpty);
      expect(service.title.balanceCents, 68000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact open scope includes partial balances and stays visible closed',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service, list: true);
      expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
      await selectOpenReceipts(tester);
      expect(service.listQueries.last.openOnly, isTrue);
      expect(service.listQueries.last.status, isNull);
      expect(
        find.textContaining('Em aberto, incluindo parciais'),
        findsWidgets,
      );
      expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
      expect(find.text('Ana Souza'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      await receiptShot(tester, 'list-compact-filters');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'receipt history retains reversed payment and explains its reason',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService()
        ..title = uiReceivableTitle(
          payments: [
            ReceivablePayment(
              id: 'reversed-ui',
              receivableId: 'receivable-ui',
              paymentDate: DateTime.utc(2026, 10, 16, 3),
              amountCents: 17000,
              paymentMethod: 'PIX',
              status: 'REVERSED',
              reversalReason: 'Corrigir recebimento duplicado',
              notes: 'Referência preservada',
              createdAt: DateTime.utc(2026, 10, 16, 15),
            ),
          ],
        );
      await mountReceipt(tester, service, size: const Size(320, 740), scale: 2);
      await tester.ensureVisible(find.text('Referência preservada'));
      await tester.pumpAndSettle();
      expect(
        find.text('Motivo do estorno: Corrigir recebimento duplicado'),
        findsOneWidget,
      );
      expect(find.text('Estornado'), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(17000)), findsOneWidget);
      expect(service.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmed receipt with failed GET stays confirmed and refresh only queries',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService()..failReadsAfterCommit = true;
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await receiptMethod(tester);
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(find.text('Recebimento registrado'), findsWidgets);
      expect(find.byKey(const ValueKey('payment-resume')), findsNothing);
      final reads = service.detailReads;
      await clickReceipt(tester, find.text('Atualizar'));
      expect(service.detailReads, reads + 1);
      expect(service.calls.length, 1);
      await receiptShot(tester, 'confirmed-refresh-failed');
      service.failReadsAfterCommit = false;
      await clickReceipt(tester, find.text('Atualizar'));
      expect(find.text('Saldo atual consultado'), findsOneWidget);
      expect(service.calls.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'balance change before review preserves draft and requires another review',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await receiptMethod(tester);
      await tester.enterText(
        find.byKey(const ValueKey('payment-notes')),
        'Conservar referência',
      );
      service.title = uiReceivableTitle(balance: 48000);
      await reviewReceipt(tester);
      expect(
        find.text(
          'O saldo mudou. Confira o valor atualizado e revise novamente.',
        ),
        findsOneWidget,
      );
      expect(service.calls, isEmpty);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-notes')))
            .controller!
            .text,
        'Conservar referência',
      );
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(service.recorded.values.single.amountCents, 48000);
    },
  );

  testWidgets(
    'method is required and selected civil date survives review and sending',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await reviewReceipt(tester);
      expect(service.calls, isEmpty);
      expect(find.byKey(const ValueKey('payment-confirm')), findsNothing);
      await clickReceipt(tester, find.byKey(const ValueKey('payment-date')));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.text('1'),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      await receiptMethod(tester);
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(service.recorded.values.single.paymentDate.day, 1);
      expect(service.recorded.values.single.paymentDate.hour, 3);
      expect(service.calls.single.payload, contains('payment_business_date'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CARD keeps Receber method code and never asks operator for account or dispatch',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await receiptMethod(tester, 'Cartão');
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      final payload =
          jsonDecode(service.calls.single.payload) as Map<String, dynamic>;
      expect(payload['payment_method'], 'CARD');
      expect(payload.containsKey('account_id'), isFalse);
      expect(payload.containsKey('dispatch_id'), isFalse);
      expect(service.recorded.values.single.isRouteCollection, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'balance changes after review refuse frozen command and retain editable draft',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = UIReceivablePaymentService();
      await mountReceipt(tester, service);
      await startReceipt(tester);
      await receiptMethod(tester);
      await tester.enterText(
        find.byKey(const ValueKey('payment-notes')),
        'Preservar após mudança',
      );
      await reviewReceipt(tester);
      service.title = uiReceivableTitle(balance: 48000);
      await confirmReceipt(tester);
      expect(service.recorded, isEmpty);
      expect(find.byKey(const ValueKey('payment-review')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-notes')))
            .controller!
            .text,
        'Preservar após mudança',
      );
      await reviewReceipt(tester);
      await confirmReceipt(tester);
      expect(service.recorded.length, 1);
      expect(service.calls[0].key, isNot(service.calls[1].key));
      expect(service.recorded.values.single.amountCents, 48000);
    },
  );

  testWidgets(
    'receivables beyond first hundred load while retaining list context',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = PagedReceivables();
      await mountReceipt(tester, service, list: true);
      await selectOpenReceipts(tester);
      await tester.scrollUntilVisible(
        find.text('Carregar mais contas'),
        1000,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 120,
      );
      await clickReceipt(tester, find.text('Carregar mais contas'));
      expect(service.offsets, [0, 0, 100]);
      expect(service.listQueries.last.openOnly, isTrue);
      expect(service.listQueries.last.status, isNull);
      expect(find.text('Carregar mais contas'), findsNothing);
      expect(service.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final spec in [
    (const Size(320, 740), 1.0, false),
    (const Size(320, 740), 2.0, false),
    (const Size(390, 844), 2.0, true),
    (const Size(1100, 900), 1.0, false),
  ]) {
    testWidgets(
      'Receber reflows at ${spec.$1} scale ${spec.$2} dark ${spec.$3}',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = UIReceivablePaymentService();
        await mountReceipt(
          tester,
          service,
          size: spec.$1,
          scale: spec.$2,
          dark: spec.$3,
        );
        expect(tester.takeException(), isNull);
        await startReceipt(tester);
        expect(tester.takeException(), isNull);
        await clickReceipt(tester, find.text('Parcial'));
        await tester.enterText(
          find.byKey(const ValueKey('payment-amount')),
          '200',
        );
        await receiptMethod(tester);
        expect(tester.takeException(), isNull);
        await reviewReceipt(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Ana Souza').hitTestable(), findsOneWidget);
        await receiptShot(tester, 'review-${spec.$1.width.toInt()}-${spec.$2}');
        await confirmReceipt(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Receber list filters reflow at ${spec.$1} scale ${spec.$2} dark ${spec.$3}',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = UIReceivablePaymentService();
        await mountReceipt(
          tester,
          service,
          size: spec.$1,
          scale: spec.$2,
          dark: spec.$3,
          list: true,
        );
        expect(tester.takeException(), isNull);
        await selectOpenReceipts(tester);
        expect(service.listQueries.last.openOnly, isTrue);
        expect(tester.takeException(), isNull);
        await openReceiptFilter(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
