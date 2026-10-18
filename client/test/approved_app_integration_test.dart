import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/app_overview_controller.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/home_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';
import 'helpers/approved_overview_fake.dart';

Future<void> mountApproved(
  WidgetTester tester,
  ApprovedOverviewApi api, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      theme: approvedAppTheme(dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('approved-capture'),
          child: child!,
        ),
      ),
      home: HomeView(apiClient: api),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> clickApproved(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> captureApproved(WidgetTester tester, String name) async {
  for (final element in find.byType(Scrollable).evaluate()) {
    final state = (element as StatefulElement).state as ScrollableState;
    if (state.position.hasContentDimensions) state.position.jumpTo(0);
  }
  final disabled = debugDisableShadows;
  debugDisableShadows = false;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('approved-capture')),
  );
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final bitmap = await boundary.toImage(pixelRatio: 1);
      final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/fe-055-preview').create(recursive: true);
      await File(
        'build/fe-055-preview/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      bitmap.dispose();
    });
  } finally {
    debugDisableShadows = disabled;
    boundary.markNeedsPaint();
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  setUpAll(() async {
    await AppFormatters.initialize();
    if (Platform.isWindows) {
      for (final entry in {
        'Segoe UI': 'C:/Windows/Fonts/segoeui.ttf',
        'Segoe UI Semibold': 'C:/Windows/Fonts/seguisb.ttf',
        'Roboto':
            'C:/dev/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
        'MaterialIcons':
            'C:/dev/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      }.entries) {
        final font = File(entry.value);
        final loader = FontLoader(entry.key)
          ..addFont(font.readAsBytes().then(ByteData.sublistView));
        await loader.load();
      }
    }
  });
  test(
    'period and current deadline scopes use server business calendar and complete records',
    () async {
      final api = ApprovedOverviewApi()..extraReceivables = 120;
      final c = AppOverviewController(client: api);
      await c.refresh();
      expect(c.businessDay, DateTime(2026, 10, 17));
      expect(api.requests.last, contains('start_date=2026-10-12'));
      expect(api.requests.last, contains('end_date=2026-10-18'));
      expect(c.accounts(true, DueScope.today).single.id, 'pay-one');
      expect(c.accounts(true, DueScope.overdue).single.id, 'pay-late');
      expect(c.accounts(false, DueScope.next).length, 121);
      expect(c.accounts(false, DueScope.open).length, 122);
      await c.selectPeriod(OverviewPeriod.month);
      expect(api.requests.last, contains('start_date=2026-10-01'));
      expect(c.accounts(true, DueScope.overdue).single.id, 'pay-late');
      c.dispose();
    },
  );
  testWidgets('reference fixture uses the same viewport, theme and account', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountApproved(
      tester,
      ApprovedOverviewApi()..comparisonFixture = true,
      size: const Size(418, 815.578125),
      dark: true,
    );
    await clickApproved(tester, find.byKey(const ValueKey('area-1')));
    await clickApproved(tester, find.byKey(const ValueKey('finance-tab-2')));
    await captureApproved(tester, 'reference-receive-matched-fixture');
    expect(
      tester.getSize(find.byKey(const ValueKey('finance-tab-0'))).height,
      44,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('approved-finance-filter')))
          .height,
      48,
    );
    expect(find.text('Ana Souza'), findsNothing);
    expect(find.text('Bruno Lima'), findsOneWidget);
    final bounds = tester.getRect(
      find.byKey(const ValueKey('finance-balance')),
    );
    final measured = <String, dynamic>{};
    for (final entry in {
      'header': find.byType(ApprovedHeader),
      'context': find.text('Pagar, receber e acompanhar vencimentos'),
      'tab': find.byKey(const ValueKey('finance-tab-0')),
      'filter': find.byKey(const ValueKey('approved-finance-filter')),
      'label': find.text('Saldo a receber'),
      'money': find.text(AppFormatters.formatCurrency(70000)).first,
      'range': find.text('Nesta semana · 12 a 18 de outubro'),
      'count': find.text('1 conta em aberto'),
      'section': find.text('Contas'),
    }.entries) {
      final r = tester.getRect(entry.value);
      measured[entry.key] = {
        'x': r.left,
        'y': r.top,
        'width': r.width,
        'height': r.height,
      };
    }
    await tester.runAsync(
      () => File('build/fe-055-preview/native-reference-measures.json')
          .writeAsString(
            jsonEncode({
              'balanceX': bounds.left,
              'balanceY': bounds.top,
              'balanceWidth': bounds.width,
              'balanceHeight': bounds.height,
              'items': measured,
            }),
          ),
    );
  });
  testWidgets(
    'approved navigation keeps financial scope and detail across areas',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApprovedOverviewApi();
      await mountApproved(tester, api);
      expect(find.text('Seu financeiro nesta semana'), findsOneWidget);
      await clickApproved(tester, find.byKey(const ValueKey('area-1')));
      await clickApproved(tester, find.byKey(const ValueKey('finance-tab-2')));
      expect(find.text('Saldo a receber'), findsOneWidget);
      await captureApproved(tester, 'finance-receive-light');
      await clickApproved(
        tester,
        find.byKey(const ValueKey('approved-finance-filter')),
      );
      await clickApproved(tester, find.text('Próximos 3 dias').last);
      expect(find.text('Ana Souza'), findsNothing);
      await clickApproved(tester, find.text('Bruno Lima'));
      expect(api.requests.last, '/api/v1/receivables/bruno');
      expect(find.byKey(const ValueKey('area-1')), findsOneWidget);
      await clickApproved(tester, find.byKey(const ValueKey('area-3')));
      expect(find.text('Produtos, compras e cestas'), findsOneWidget);
      await clickApproved(tester, find.byKey(const ValueKey('area-1')));
      expect(find.text('Bruno Lima'), findsOneWidget);
      await clickApproved(tester, find.byType(BackButton).first);
      expect(find.text('Saldo a receber'), findsOneWidget);
      expect(find.text('Ana Souza'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('area navigation waits for financial review request', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApprovedOverviewApi();
    await mountApproved(tester, api);
    await clickApproved(tester, find.byKey(const ValueKey('area-1')));
    await clickApproved(tester, find.byKey(const ValueKey('finance-tab-2')));
    await clickApproved(tester, find.text('Bruno Lima'));
    await clickApproved(tester, find.byKey(const ValueKey('payment-start')));
    await clickApproved(tester, find.byKey(const ValueKey('payment-method')));
    await clickApproved(tester, find.text('PIX').last);
    api.detailGate = Completer<void>();
    await tester.ensureVisible(find.byKey(const ValueKey('payment-review')));
    await tester.tap(find.byKey(const ValueKey('payment-review')));
    await tester.pump();
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('area-3'))).onTap,
      isNull,
    );
    api.detailGate!.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('area-3'))).onTap,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('payment-confirm')), findsOneWidget);
    await captureApproved(tester, 'receive-review-integrated');
    expect(tester.takeException(), isNull);
  });
  testWidgets('summary opens its own period after another list scope', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountApproved(tester, ApprovedOverviewApi());
    await clickApproved(tester, find.byKey(const ValueKey('area-1')));
    await clickApproved(tester, find.byKey(const ValueKey('finance-tab-2')));
    await clickApproved(
      tester,
      find.byKey(const ValueKey('approved-finance-filter')),
    );
    await clickApproved(tester, find.text('Próximos 3 dias').last);
    expect(find.text('Ana Souza'), findsNothing);
    await clickApproved(tester, find.byKey(const ValueKey('finance-tab-0')));
    await clickApproved(tester, find.text('A receber').first);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
  });
  testWidgets('result belongs to Negocio and never becomes bank balance', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountApproved(tester, ApprovedOverviewApi());
    await clickApproved(tester, find.byKey(const ValueKey('area-2')));
    expect(find.textContaining('Resultado do negócio'), findsOneWidget);
    expect(find.textContaining('1 venda com custo incompleto'), findsOneWidget);
    await clickApproved(tester, find.text('Entender o resultado'));
    expect(find.text('Custos registrados nas vendas'), findsOneWidget);
    expect(
      find.textContaining('não representa saldo bancário'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed query does not present false zero or all-clear', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountApproved(tester, ApprovedOverviewApi()..offline = true);
    expect(find.text('R\$ 0,00'), findsNothing);
    expect(find.text('Nenhum produto abaixo do mínimo'), findsNothing);
    expect(find.text('Atualizar'), findsWidgets);
  });
  for (final spec in [
    (const Size(390, 844), 1.0, false),
    (const Size(390, 844), 1.0, true),
    (const Size(1100, 900), 1.0, true),
    (const Size(320, 740), 2.0, false),
  ]) {
    testWidgets(
      'approved five areas reflow ${spec.$1} ${spec.$2} dark ${spec.$3}',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mountApproved(
          tester,
          ApprovedOverviewApi(),
          size: spec.$1,
          scale: spec.$2,
          dark: spec.$3,
        );
        expect(tester.takeException(), isNull);
        await captureApproved(
          tester,
          'home-${spec.$1.width.toInt()}-${spec.$2}-${spec.$3}',
        );
        for (var area = 1; area < 5; area++) {
          await clickApproved(tester, find.byKey(ValueKey('area-$area')));
          expect(tester.takeException(), isNull, reason: 'area $area');
          if (area == 1) {
            await clickApproved(
              tester,
              find.byKey(const ValueKey('finance-tab-2')),
            );
            await captureApproved(
              tester,
              'receive-${spec.$1.width.toInt()}-${spec.$2}-${spec.$3}',
            );
          }
          if (area == 2) {
            await captureApproved(
              tester,
              'business-${spec.$1.width.toInt()}-${spec.$2}-${spec.$3}',
            );
          }
        }
      },
    );
  }
}
