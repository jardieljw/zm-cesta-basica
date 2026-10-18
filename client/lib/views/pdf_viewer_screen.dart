import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../l10n/l10n_extension.dart';
import '../services/document_file_service.dart';
import '../services/printer_service.dart';
import '../widgets/shared/printer_selection_dialog.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final String fileName;
  final bool canChangeOrientation;
  final PdfPageFormat initialPageFormat;
  final PrinterService? printerService;

  const PdfViewerScreen(
      {super.key,
      required this.title,
      required this.buildPdf,
      required this.fileName,
      this.canChangeOrientation = true,
      this.initialPageFormat = PdfPageFormat.a4,
      this.printerService});
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PrinterService _printers =
      widget.printerService ?? PrinterService();
  late PdfPageFormat _format = widget.initialPageFormat;
  bool _busy = false;

  @override
  void dispose() {
    if (widget.printerService == null) _printers.dispose();
    super.dispose();
  }

  Future<void> _saveOrShare({required bool save}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.buildPdf(_format);
      final saved = save
          ? await DocumentFileService.save(bytes, widget.fileName)
          : await Printing.sharePdf(bytes: bytes, filename: widget.fileName);
      if (save && saved && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.formFileSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.formExportFailure)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPrinters() {
    showDialog<void>(
        context: context,
        builder: (_) => PrinterSelectionDialog(
            service: _printers,
            buildPdf: widget.buildPdf,
            fileName: widget.fileName,
            format: _format,
            dynamicLayout: widget.canChangeOrientation));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: l.formSavePdf,
                onPressed: _busy ? null : () => _saveOrShare(save: true)),
            IconButton(
                key: const ValueKey('pdf-select-printer'),
                icon: const Icon(Icons.print),
                tooltip: l.tooltipPrintSelectPrinter,
                onPressed: _busy ? null : _showPrinters),
            IconButton(
                icon: const Icon(Icons.share),
                tooltip: l.tooltipShareSavePdf,
                onPressed: _busy ? null : () => _saveOrShare(save: false)),
          ]),
      body: PdfPreview(
        build: widget.buildPdf,
        initialPageFormat: widget.initialPageFormat,
        canChangeOrientation: widget.canChangeOrientation,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: widget.fileName,
        onPageFormatChanged: (format) => _format = format,
        onError: (context, error) => Center(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.printerPreviewError))),
        previewPageMargin: const EdgeInsets.all(16),
        loadingWidget: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l.commonLoading),
        ])),
      ),
    );
  }
}
