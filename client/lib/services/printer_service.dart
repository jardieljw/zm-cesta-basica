import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PrinterBusyException implements Exception {}

/// Delegates discovery and transport to the OS print service/driver.
class PrinterService extends ChangeNotifier {
  static const setupChannel = MethodChannel('zm_cesta_basica/printing_setup');
  final Duration discoveryTimeout;
  bool _printing = false;
  bool _disposed = false;
  PrinterService({this.discoveryTimeout = const Duration(seconds: 10)});

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get canOpenSettings => isAndroid;
  bool get isPrinting => _printing;
  bool canList(PrintingInfo info) => !isAndroid && info.canListPrinters;
  bool canPrintDirect(PrintingInfo info) =>
      info.canPrint && canList(info) && info.directPrint;

  void _setPrinting(bool value) {
    _printing = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<PrintingInfo> capabilities() async {
    final info = await Printing.info().timeout(discoveryTimeout);
    if (isAndroid && info.canPrint) {
      final supported = await setupChannel
          .invokeMethod<bool>('supportsPrinting')
          .timeout(discoveryTimeout);
      if (supported == false) {
        return PrintingInfo(canShare: info.canShare, canRaster: info.canRaster);
      }
    }
    return info;
  }

  Future<List<Printer>> installedPrinters(PrintingInfo info) async {
    if (!canList(info)) return [];
    final printers = [
      ...await Printing.listPrinters().timeout(discoveryTimeout)
    ];
    printers.sort((a, b) => a.isDefault != b.isDefault
        ? (a.isDefault ? -1 : 1)
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return printers;
  }

  Future<bool> printDocument(
      {required Future<Uint8List> Function(PdfPageFormat) buildPdf,
      required String name,
      required PdfPageFormat format,
      Printer? printer,
      bool dynamicLayout = true}) async {
    if (_printing) throw PrinterBusyException();
    _setPrinting(true);
    try {
      // Validate generation before handing a job to the native service.
      final initialBytes = await buildPdf(format);
      if (initialBytes.length < 5 ||
          String.fromCharCodes(initialBytes.take(5)) != '%PDF-') {
        throw const FormatException('Invalid PDF');
      }
      Future<Uint8List> layout(PdfPageFormat selected) async {
        if (!dynamicLayout ||
            (selected.width == format.width &&
                selected.height == format.height &&
                selected.marginLeft == format.marginLeft &&
                selected.marginRight == format.marginRight &&
                selected.marginTop == format.marginTop &&
                selected.marginBottom == format.marginBottom)) {
          return initialBytes;
        }
        return buildPdf(selected);
      }

      if (printer != null) {
        final info = await capabilities();
        if (!canPrintDirect(info) || !printer.isAvailable) {
          throw UnsupportedError('Direct printing unavailable');
        }
        return await Printing.directPrintPdf(
            printer: printer,
            onLayout: layout,
            name: name,
            format: format,
            dynamicLayout: dynamicLayout);
      }
      return await Printing.layoutPdf(
          onLayout: layout,
          name: name,
          format: format,
          dynamicLayout: dynamicLayout);
    } finally {
      _setPrinting(false);
    }
  }

  Future<bool> openSettings() async {
    if (!canOpenSettings) return false;
    return await setupChannel.invokeMethod<bool>('openPrintSettings') ?? false;
  }
}
