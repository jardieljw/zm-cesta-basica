import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/printer_service.dart';
import 'package:zm_cesta_basica_client/views/pdf_viewer_screen.dart';
import 'package:zm_cesta_basica_client/widgets/shared/printer_selection_dialog.dart';
import 'helpers/fake_printing_platform.dart';

class _DialogPrinterService extends PrinterService {
  bool android = true;
  @override
  bool get isAndroid => android;
}

void main() {
  late PrintingPlatform previous;
  late FakePrintingPlatform platform;
  late _DialogPrinterService service;
  var supportsPrinting = true;
  var settingsOpened = true;
  Future<Uint8List> pdf(PdfPageFormat format) async =>
      Uint8List.fromList('%PDF-fixture'.codeUnits);
  Widget app({double scale = 1, Widget? home}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: home ??
            Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        key: const ValueKey('open'),
                        child: const Text('open'),
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => PrinterSelectionDialog(
                                service: service,
                                buildPdf: pdf,
                                fileName: 'fixture.pdf',
                                format: PdfPageFormat.a4.landscape))))),
      );
  setUp(() {
    previous = PrintingPlatform.instance;
    platform = FakePrintingPlatform();
    PrintingPlatform.instance = platform;
    service = _DialogPrinterService();
    supportsPrinting = true;
    settingsOpened = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            PrinterService.setupChannel,
            (call) async => call.method == 'supportsPrinting'
                ? supportsPrinting
                : settingsOpened);
  });
  tearDown(() {
    service.dispose();
    PrintingPlatform.instance = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PrinterService.setupChannel, null);
  });
  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(app(scale: scale));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 560.0, 1200.0]) {
    testWidgets('Android native discovery and help fit at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(tester, scale: 1.3);
      expect(platform.listCalls, 0);
      expect(platform.printCalls, 0);
      expect(find.text('Impressoras cadastradas no sistema'), findsNothing);
      final settings = find.byKey(const ValueKey('printer-settings'));
      await tester.ensureVisible(settings);
      expect(settings.hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('A impressora não apareceu?'));
      await tester.tap(find.text('A impressora não apareceu?'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Android system action preserves landscape and cancellation is explicit',
      (tester) async {
    platform.result = false;
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('printer-system-print')));
    await tester.pumpAndSettle();
    expect(platform.printCalls, 1);
    expect(platform.lastPrinter, isNull);
    expect(
        platform.lastFormat!.width, greaterThan(platform.lastFormat!.height));
    expect(find.text('Impressão cancelada.'), findsOneWidget);
    expect(find.textContaining('conclusão do trabalho'), findsNothing);
  });
  testWidgets('test page generates real A4 PDF without business data',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('printer-test-page')));
    await tester.pumpAndSettle();
    expect(platform.printCalls, 1);
    expect(platform.lastName, 'ZM_teste_A4.pdf');
    expect(platform.lastBytes!.length, greaterThan(1000));
    expect(String.fromCharCodes(platform.lastBytes!.take(5)), '%PDF-');
    expect(platform.lastFormat!.width, lessThan(platform.lastFormat!.height));
    expect(platform.lastDynamic, isFalse);
  });
  testWidgets(
      'missing print feature disables printing and settings failure explains fallback',
      (tester) async {
    supportsPrinting = false;
    settingsOpened = false;
    await open(tester);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('printer-system-print')))
            .onPressed,
        isNull);
    expect(find.textContaining('serviço de impressão não está disponível'),
        findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('printer-settings')));
    await tester.tap(find.byKey(const ValueKey('printer-settings')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível abrir as configurações'),
        findsOneWidget);
    expect(platform.printCalls, 0);
  });
  testWidgets('Windows list failure leaves native dialog path available',
      (tester) async {
    service.android = false;
    platform.capabilities = const PrintingInfo(
        canPrint: true, canListPrinters: true, directPrint: true);
    platform.listError = true;
    await open(tester);
    expect(platform.listCalls, 1);
    expect(find.textContaining('Não foi possível consultar as impressoras'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('printer-system-print')));
    await tester.pumpAndSettle();
    expect(platform.printCalls, 1);
    expect(platform.lastPrinter, isNull);
  });
  testWidgets(
      'Windows direct path uses selected printer and disables unavailable devices',
      (tester) async {
    service.android = false;
    platform.capabilities = const PrintingInfo(
        canPrint: true, canListPrinters: true, directPrint: true);
    platform.printers = [
      const Printer(url: 'canon', name: 'Canon'),
      const Printer(url: 'epson', name: 'Epson', isAvailable: false)
    ];
    await open(tester);
    final offline = find.byKey(const ValueKey('printer-direct-epson'));
    await tester.ensureVisible(offline);
    expect(tester.widget<TextButton>(offline).onPressed, isNull);
    final available = find.byKey(const ValueKey('printer-direct-canon'));
    await tester.ensureVisible(available);
    await tester.tap(available);
    await tester.pumpAndSettle();
    expect(platform.lastPrinter!.url, 'canon');
  });
  testWidgets(
      'closing and reopening pending job keeps duplicate submission disabled',
      (tester) async {
    platform.pending = Completer<bool>();
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('printer-system-print')));
    await tester.pump();
    expect(service.isPrinting, isTrue);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('printer-system-print')))
            .onPressed,
        isNull);
    platform.pending!.complete(false);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('printer-system-print')))
            .onPressed,
        isNotNull);
    expect(platform.printCalls, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'PDF viewer has one controlled print entry and follows changed orientation',
      (tester) async {
    await tester.pumpWidget(app(
        home: PdfViewerScreen(
            title: 'fixture',
            fileName: 'fixture.pdf',
            buildPdf: pdf,
            printerService: service)));
    await tester.pumpAndSettle();
    final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
    expect(preview.allowPrinting, isFalse);
    expect(preview.allowSharing, isFalse);
    preview.onPageFormatChanged!(PdfPageFormat.a4.landscape);
    await tester.tap(find.byKey(const ValueKey('pdf-select-printer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('printer-system-print')));
    await tester.pumpAndSettle();
    expect(
        platform.lastFormat!.width, greaterThan(platform.lastFormat!.height));
  });
}
