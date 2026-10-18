import 'dart:async';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';

class FakePrintingPlatform extends PrintingPlatform {
  PrintingInfo capabilities =
      const PrintingInfo(canPrint: true, canShare: true);
  List<Printer> printers = [];
  int listCalls = 0, printCalls = 0;
  bool listError = false, printError = false, result = true;
  Completer<bool>? pending;
  Completer<PrintingInfo>? pendingCapabilities;
  PdfPageFormat? requestedLayout, lastFormat;
  Printer? lastPrinter;
  Uint8List? lastBytes;
  String? lastName;
  bool? lastDynamic;

  @override
  Future<PrintingInfo> info() async => pendingCapabilities != null
      ? await pendingCapabilities!.future
      : capabilities;
  @override
  Future<List<Printer>> listPrinters() async {
    listCalls++;
    if (listError) throw StateError('enumeration failed');
    return printers;
  }

  @override
  Future<bool> layoutPdf(
      Printer? printer,
      LayoutCallback onLayout,
      String name,
      PdfPageFormat format,
      bool dynamicLayout,
      bool usePrinterSettings,
      OutputType outputType,
      bool forceCustomPrintPaper,
      bool windowsModernDialog) async {
    printCalls++;
    lastPrinter = printer;
    lastName = name;
    lastFormat = format;
    lastDynamic = dynamicLayout;
    lastBytes = await onLayout(requestedLayout ?? format);
    if (printError) throw StateError('print failed');
    return pending != null ? await pending!.future : result;
  }

  @override
  Stream<PdfRaster> raster(
      Uint8List document, List<int>? pages, double dpi) async* {
    yield PdfRaster(1, 1, Uint8List.fromList([255, 255, 255, 255]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
