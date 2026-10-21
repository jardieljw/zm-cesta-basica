import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/services/payable_payment_coordinator.dart';
import 'package:zm_cesta_basica_client/views/payable_payment_view.dart';
import 'package:zm_cesta_basica_client/views/payables_view.dart';
import 'helpers/payable_payment_fake.dart';

class PagedPayments extends FakePaymentService {
  final List<int> offsets = [];
  @override
  Future<List<AccountPayable>> getPayables({
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? month,
    int? year,
    String? category,
    String? beneficiary,
    String? bankCard,
    String? merchant,
    String? status,
    String? nature,
    bool overdueOnly = false,
    int limit = 100,
    int offset = 0,
  }) async {
    offsets.add(offset);
    return List.generate(
      offset == 0 ? 100 : 1,
      (i) => paymentTitle(id: 'page-${offset + i}'),
    );
  }
}

Future<void> mount(
  WidgetTester tester,
  FakePaymentService service, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  bool list = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final flow = PayablePaymentCoordinator(service: service);
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
          key: const ValueKey('payment-capture'),
          child: child!,
        ),
      ),
      home: list
          ? PayablesView(service: service, paymentCoordinator: flow)
          : PayablePaymentView(payableId: service.title.id, coordinator: flow),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> click(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> start(WidgetTester tester) =>
    click(tester, find.byKey(const ValueKey('payment-start')));
Future<void> method(WidgetTester tester) async {
  await click(tester, find.byKey(const ValueKey('payment-method')));
  await tester.tap(find.text('PIX').last);
  await tester.pumpAndSettle();
}

Future<void> review(WidgetTester tester) =>
    click(tester, find.byKey(const ValueKey('payment-review')));
Future<void> confirm(WidgetTester tester) =>
    click(tester, find.byKey(const ValueKey('payment-confirm')));
Future<void> shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('payment-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/fe-053-preview').create(recursive: true);
    await File(
      'build/fe-053-preview/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
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
    'integral ignores hidden partial value; review/edit preserve draft and no early POST',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService();
      await mount(tester, service);
      await start(tester);
      await click(tester, find.text('Parcial'));
      await tester.enterText(
        find.byKey(const ValueKey('payment-amount')),
        '200',
      );
      await method(tester);
      await tester.enterText(
        find.byKey(const ValueKey('payment-notes')),
        'Manter referência',
      );
      await review(tester);
      expect(service.calls, isEmpty);
      await click(tester, find.text('Editar'));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-notes')))
            .controller!
            .text,
        'Manter referência',
      );
      await click(tester, find.text('Integral'));
      await review(tester);
      await shot(tester, 'review-mobile');
      await confirm(tester);
      expect(service.calls.length, 1);
      expect(service.title.balanceCents, 0);
      expect(find.text('Pagamento registrado'), findsWidgets);
      expect(service.recorded.values.single.amountCents, 68000);
      expect(service.recorded.values.single.notes, 'Manter referência');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lost reply returns after restart with same command; resume does not duplicate',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService()..dropReply = true;
      await mount(tester, service);
      await start(tester);
      await method(tester);
      await review(tester);
      await confirm(tester);
      expect(find.byKey(const ValueKey('payment-resume')), findsOneWidget);
      await mount(tester, service, list: true);
      expect(service.title.balanceCents, 0);
      expect(find.text('Registros para acompanhar'), findsOneWidget);
      await click(tester, find.text('Fornecedor de teste · conta #208'));
      await shot(tester, 'pending-mobile');
      await click(tester, find.byKey(const ValueKey('payment-resume')));
      expect(service.recorded.length, 1);
      expect(service.calls.length, 2);
      expect(service.calls[0], service.calls[1]);
      expect(find.text('Pagamento registrado'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmed POST followed by failed GET stays confirmed; refresh only queries',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService()..failReadsAfterCommit = true;
      await mount(tester, service);
      await start(tester);
      await method(tester);
      await review(tester);
      await confirm(tester);
      expect(
        find.text(
          'O pagamento está registrado. Falta atualizar a consulta da conta.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('payment-resume')), findsNothing);
      await click(tester, find.text('Atualizar'));
      expect(service.calls.length, 1);
      await shot(tester, 'confirmed-refresh-failed');
      service.failReadsAfterCommit = false;
      await click(tester, find.text('Atualizar'));
      expect(find.text('Saldo atual consultado'), findsOneWidget);
      expect(service.calls.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'balance changed before review preserves inputs and asks to review again',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService();
      await mount(tester, service);
      await start(tester);
      await method(tester);
      service.title = paymentTitle(balance: 48000);
      await review(tester);
      expect(
        find.text(
          'O saldo mudou. Confira o valor atualizado e revise novamente.',
        ),
        findsOneWidget,
      );
      expect(service.calls, isEmpty);
      await review(tester);
      await confirm(tester);
      expect(service.recorded.values.single.amountCents, 48000);
    },
  );

  testWidgets(
    'method must be selected and chosen civil date survives review and send',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService();
      await mount(tester, service);
      await start(tester);
      await review(tester);
      expect(service.calls, isEmpty);
      expect(find.text('Selecione a forma de pagamento'), findsWidgets);
      await click(tester, find.byKey(const ValueKey('payment-date')));
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
      await method(tester);
      await review(tester);
      await confirm(tester);
      expect(service.calls.single.payload, contains('payment_business_date'));
      expect(service.recorded.values.single.paymentDate.day, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a balance change after review refuses the frozen command and preserves edit data',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService();
      await mount(tester, service);
      await start(tester);
      await method(tester);
      await tester.enterText(
        find.byKey(const ValueKey('payment-notes')),
        'Preservar após mudança',
      );
      await review(tester);
      service.title = paymentTitle(balance: 48000);
      await confirm(tester);
      expect(service.recorded, isEmpty);
      expect(find.byKey(const ValueKey('payment-review')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('payment-notes')))
            .controller!
            .text,
        'Preservar após mudança',
      );
      await review(tester);
      await confirm(tester);
      expect(service.recorded.length, 1);
      expect(service.calls[0].key, isNot(service.calls[1].key));
      expect(service.recorded.values.single.amountCents, 48000);
    },
  );

  testWidgets(
    'accounts beyond first hundred can be loaded without replacing the filter',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = PagedPayments();
      await mount(tester, service, list: true);
      await tester.scrollUntilVisible(
        find.text('Carregar mais contas'),
        1000,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 120,
      );
      await click(tester, find.text('Carregar mais contas'));
      expect(service.offsets, [0, 100]);
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
    testWidgets('flow reflows at ${spec.$1} scale ${spec.$2} dark ${spec.$3}', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePaymentService();
      await mount(
        tester,
        service,
        size: spec.$1,
        scale: spec.$2,
        dark: spec.$3,
      );
      expect(tester.takeException(), isNull);
      await start(tester);
      expect(tester.takeException(), isNull);
      await click(tester, find.text('Parcial'));
      await tester.enterText(
        find.byKey(const ValueKey('payment-amount')),
        '200',
      );
      await method(tester);
      expect(tester.takeException(), isNull);
      await review(tester);
      expect(tester.takeException(), isNull);
      await shot(tester, 'review-${spec.$1.width.toInt()}-${spec.$2}');
      await confirm(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
