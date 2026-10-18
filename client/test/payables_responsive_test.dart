import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/views/payables_view.dart';

class FakePayables extends PayableService {
  final queries = <String?>[];
  final overdueQueries = <bool>[];
  final searches = <String?>[];
  bool fail = false;
  bool empty = false;
  @override
  Future<List<AccountPayable>> getPayables(
      {DateTime? dueDateFrom,
      DateTime? dueDateTo,
      int? month,
      int? year,
      String? category,
      String? beneficiary,
      String? status,
      String? nature,
      bool overdueOnly = false,
      int limit = 100,
      int offset = 0}) async {
    queries.add(status);
    searches.add(beneficiary);
    overdueQueries.add(overdueOnly);
    if (fail) throw Exception('offline');
    if (empty) return [];
    return List.generate(
        12,
        (i) => AccountPayable(
            id: '$i',
            payableNumber: i + 1,
            description: 'Compra de insumos e materiais para cestas',
            beneficiary: 'Fornecedor de alimentos',
            category: 'FORNECEDOR',
            nature: 'BUSINESS',
            originalAmountCents: 195000,
            paidAmountCents: 50000,
            balanceCents: 145000,
            dueDate: DateTime(2026, 10, 20),
            paymentMethod: 'DINHEIRO',
            status: 'PARTIAL',
            isRecurrent: true,
            paymentsCount: 1,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026)));
  }
}

Future<void> mount(WidgetTester tester, FakePayables service, Size size,
    {double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(
          key: const ValueKey('capture'),
          child: PayablesView(service: service))));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    if (Platform.isWindows) {
      for (final entry in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf'
      }.entries) {
        final file = File(
            'C:/dev/flutter/bin/cache/artifacts/material_fonts/${entry.value}');
        if (await file.exists()) {
          final loader = FontLoader(entry.key)
            ..addFont(file
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)));
          await loader.load();
        }
      }
    }
  });
  for (final size in [
    const Size(360, 740),
    const Size(412, 860),
    const Size(1200, 800)
  ]) {
    testWidgets(
        'headers scroll away and last account clears round FAB at $size',
        (tester) async {
      await mount(tester, FakePayables(), size);
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      final button = tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(button.shape, isA<CircleBorder>());
      expect(button.tooltip, 'Criar conta a pagar');
      if (size.width == 360) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/layout-preview').create(recursive: true);
          await File('build/layout-preview/payables_mobile.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final scroll =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find.text('Resumo das contas exibidas').hitTestable(), findsNothing);
      // Check the actual last card action rather than depending on its translated label.
      final last = find.byIcon(Icons.payment).last;
      expect(tester.getBottomRight(last).dy,
          lessThan(tester.getTopLeft(find.byType(FloatingActionButton)).dy));
    });
  }
  testWidgets(
      'filter draft cancel, apply and removable chip query only on confirmation',
      (tester) async {
    final service = FakePayables();
    await mount(tester, service, const Size(360, 740));
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitado').last);
    await tester.pumpAndSettle();
    expect(service.queries.length, 1);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.queries.length, 1);
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitado').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar Filtros'));
    await tester.pumpAndSettle();
    expect(service.queries, [null, 'PAID']);
    final chip = find.widgetWithText(InputChip, 'Quitado');
    await tester
        .tap(find.descendant(of: chip, matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(service.queries, [null, 'PAID', null]);
  });
  testWidgets('large text, empty and failed states do not overflow',
      (tester) async {
    final service = FakePayables();
    await mount(tester, service, const Size(360, 800), scale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Cancelar'));
    await tester.pumpAndSettle();
    service.empty = true;
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    service.fail = true;
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'desktop filter dialog clear is a draft and search icon applies typed text',
      (tester) async {
    final service = FakePayables();
    await mount(tester, service, const Size(1200, 800));
    await tester.enterText(find.byType(TextField), 'Fornecedor AAA');
    await tester.tap(find.byTooltip('Buscar favorecido'));
    await tester.pumpAndSettle();
    expect(service.searches.last, 'Fornecedor AAA');
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitado').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar Filtros'));
    await tester.pumpAndSettle();
    expect(service.queries.last, 'PAID');
    final requests = service.queries.length;
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar Filtros').last);
    await tester.pumpAndSettle();
    expect(service.queries.length, requests);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.queries.last, 'PAID');
  });
  testWidgets(
      'mobile keyboard and empty message remain clear of the creation button',
      (tester) async {
    final service = FakePayables()..empty = true;
    await mount(tester, service, const Size(360, 740));
    final message = find.text('Nenhuma obrigação a pagar encontrada.');
    expect(tester.getBottomRight(message).dy,
        lessThan(tester.getTopLeft(find.byType(FloatingActionButton)).dy));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
