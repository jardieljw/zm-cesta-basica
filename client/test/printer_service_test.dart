import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:zm_cesta_basica_client/services/printer_service.dart';
import 'helpers/fake_printing_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PrintingPlatform previous;
  late FakePrintingPlatform platform;
  late PrinterService service;
  var nativeSupported = true;
  var settingsOpened = true;
  final calls = <String>[];
  Future<Uint8List> pdf(PdfPageFormat format) async =>
      Uint8List.fromList('%PDF-test'.codeUnits);
  setUp(() {
    previous = PrintingPlatform.instance;
    platform = FakePrintingPlatform();
    PrintingPlatform.instance = platform;
    service = PrinterService();
    nativeSupported = true;
    settingsOpened = true;
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PrinterService.setupChannel, (call) async {
      calls.add(call.method);
      return call.method == 'supportsPrinting'
          ? nativeSupported
          : settingsOpened;
    });
  });
  tearDown(() {
    service.dispose();
    PrintingPlatform.instance = previous;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PrinterService.setupChannel, null);
  });
  test(
      'Android never enumerates or prints directly even if plugin flags incorrectly claim support',
      () async {
    platform.capabilities = const PrintingInfo(
        canPrint: true, canListPrinters: true, directPrint: true);
    final info = await service.capabilities();
    expect(calls, ['supportsPrinting']);
    expect(await service.installedPrinters(info), isEmpty);
    expect(platform.listCalls, 0);
    expect(service.canPrintDirect(info), isFalse);
    expect(
        await service.printDocument(
            buildPdf: pdf, name: 'report.pdf', format: PdfPageFormat.a4),
        isTrue);
    expect(platform.lastPrinter, isNull);
  });
  test('Android feature check can disable printing while retaining sharing',
      () async {
    nativeSupported = false;
    final info = await service.capabilities();
    expect(info.canPrint, isFalse);
    expect(info.canShare, isTrue);
  });
  test(
      'Windows enumeration uses actual capability and default printer ordering',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    platform.capabilities = const PrintingInfo(
        canPrint: true, canListPrinters: true, directPrint: true);
    platform.printers = [
      const Printer(url: 'z', name: 'Zebra'),
      const Printer(url: 'a', name: 'Brother'),
      const Printer(url: 'd', name: 'Canon', isDefault: true)
    ];
    final info = await service.capabilities();
    final printers = await service.installedPrinters(info);
    expect(printers.map((p) => p.name), ['Canon', 'Brother', 'Zebra']);
    expect(
        await service.printDocument(
            buildPdf: pdf,
            name: 'report.pdf',
            format: PdfPageFormat.a4.landscape,
            printer: printers.first),
        isTrue);
    expect(platform.lastPrinter!.url, 'd');
    expect(
        platform.lastFormat!.width, greaterThan(platform.lastFormat!.height));
    expect(calls, isEmpty);
  });
  test(
      'cancellation and errors release busy state and invalid PDFs never start jobs',
      () async {
    platform.result = false;
    expect(
        await service.printDocument(
            buildPdf: pdf, name: 'report.pdf', format: PdfPageFormat.a4),
        isFalse);
    platform.printError = true;
    await expectLater(
        service.printDocument(
            buildPdf: pdf, name: 'report.pdf', format: PdfPageFormat.a4),
        throwsStateError);
    expect(service.isPrinting, isFalse);
    final before = platform.printCalls;
    await expectLater(
        service.printDocument(
            buildPdf: (_) async => Uint8List(0),
            name: 'bad.pdf',
            format: PdfPageFormat.a4),
        throwsFormatException);
    expect(platform.printCalls, before);
    expect(service.isPrinting, isFalse);
  });
  test(
      'pending job prevents duplicate jobs and can complete after owner disposal',
      () async {
    platform.pending = Completer<bool>();
    final first = service.printDocument(
        buildPdf: pdf, name: 'report.pdf', format: PdfPageFormat.a4);
    await Future<void>.delayed(Duration.zero);
    expect(service.isPrinting, isTrue);
    await expectLater(
        service.printDocument(
            buildPdf: pdf, name: 'duplicate.pdf', format: PdfPageFormat.a4),
        throwsA(isA<PrinterBusyException>()));
    expect(platform.printCalls, 1);
    service.dispose();
    platform.pending!.complete(false);
    expect(await first, isFalse);
    expect(service.isPrinting, isFalse);
    // Avoid disposing twice in tearDown.
    service = PrinterService();
  });
  test(
      'layout follows orientation changes while fixed forms preserve prepared bytes',
      () async {
    platform.requestedLayout = PdfPageFormat.a4.landscape;
    var builds = 0;
    Future<Uint8List> build(PdfPageFormat format) async {
      builds++;
      return Uint8List.fromList('%PDF-${format.width}'.codeUnits);
    }

    await service.printDocument(
        buildPdf: build, name: 'report.pdf', format: PdfPageFormat.a4);
    expect(builds, 2);
    builds = 0;
    await service.printDocument(
        buildPdf: build,
        name: 'fixed.pdf',
        format: PdfPageFormat.a4,
        dynamicLayout: false);
    expect(builds, 1);
    expect(platform.lastDynamic, isFalse);
  });
  test('printing settings use native intent result and discovery has a timeout',
      () async {
    expect(await service.openSettings(), isTrue);
    settingsOpened = false;
    expect(await service.openSettings(), isFalse);
    platform.pendingCapabilities = Completer<PrintingInfo>();
    final short =
        PrinterService(discoveryTimeout: const Duration(milliseconds: 10));
    await expectLater(short.capabilities(), throwsA(isA<TimeoutException>()));
    short.dispose();
  });
}
