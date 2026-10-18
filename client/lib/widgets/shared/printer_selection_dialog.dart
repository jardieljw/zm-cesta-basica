import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../l10n/l10n_extension.dart';
import '../../services/printer_service.dart';
import '../../utils/printer_test_page.dart';

class PrinterSelectionDialog extends StatefulWidget {
  final PrinterService service;
  final Future<Uint8List> Function(PdfPageFormat)? buildPdf;
  final String fileName;
  final PdfPageFormat format;
  final bool dynamicLayout;
  const PrinterSelectionDialog(
      {super.key,
      required this.service,
      this.buildPdf,
      this.fileName = 'ZM_documento.pdf',
      this.format = PdfPageFormat.a4,
      this.dynamicLayout = true});
  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog>
    with WidgetsBindingObserver {
  PrintingInfo? _info;
  List<Printer> _printers = [];
  bool _loading = true,
      _discoveryError = false,
      _printing = false,
      _openingSettings = false;
  String? _message;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.addListener(_serviceChanged);
    _load();
  }

  @override
  void dispose() {
    _request++;
    WidgetsBinding.instance.removeObserver(this);
    widget.service.removeListener(_serviceChanged);
    super.dispose();
  }

  void _serviceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_printing && !_loading) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _discoveryError = false;
      _info = null;
      _printers = [];
    });
    try {
      final info = await widget.service.capabilities();
      if (!mounted || request != _request) return;
      setState(() => _info = info);
      final printers = await widget.service.installedPrinters(info);
      if (!mounted || request != _request) return;
      setState(() {
        _printers = printers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _discoveryError = true;
        _loading = false;
      });
    }
  }

  Future<void> _print({Printer? printer, bool testPage = false}) async {
    if (!testPage && widget.buildPdf == null) return;
    if (_printing || widget.service.isPrinting) {
      setState(() => _message = context.l10n.printerJobBusy);
      return;
    }
    final l = context.l10n;
    setState(() {
      _printing = true;
      _message = null;
    });
    try {
      final completed = await widget.service.printDocument(
        buildPdf: testPage
            ? (_) => PrinterTestPage.build(
                title: l.printerTestTitle,
                instructions: l.printerTestInstructions,
                characters: l.printerTestCharacters,
                scaleLabel: l.printerTestScale,
                lineLabels: [
                  for (final height in [8, 9, 10]) l.printerTestLine(height)
                ],
                footer: l.printerTestFooter)
            : widget.buildPdf!,
        name: testPage ? 'ZM_teste_A4.pdf' : widget.fileName,
        format: testPage ? PdfPageFormat.a4 : widget.format,
        printer: printer,
        dynamicLayout: testPage ? false : widget.dynamicLayout,
      );
      if (mounted) {
        setState(() => _message =
            completed ? l.printerJobSubmitted : l.printerJobCanceled);
      }
    } on PrinterBusyException {
      if (mounted) setState(() => _message = l.printerJobBusy);
    } catch (_) {
      if (mounted) setState(() => _message = l.printerJobError);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _settings() async {
    final l = context.l10n;
    setState(() => _openingSettings = true);
    try {
      final opened = await widget.service.openSettings();
      if (mounted) {
        setState(() => _message =
            opened ? l.printerSettingsHelp : l.printerSettingsUnavailable);
      }
    } catch (_) {
      if (mounted) setState(() => _message = l.printerSettingsUnavailable);
    } finally {
      if (mounted) setState(() => _openingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canPrint = _info?.canPrint ?? _discoveryError;
    return Dialog(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                        child: Text(l.printerDialogTitle,
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                        tooltip: l.commonClose,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ]),
                  const SizedBox(height: 8),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                        Text(widget.service.isAndroid
                            ? l.printerAndroidDiscovery
                            : l.printerDesktopDiscovery),
                        const SizedBox(height: 12),
                        if (widget.buildPdf != null)
                          FilledButton.icon(
                              key: const ValueKey('printer-system-print'),
                              onPressed: !canPrint ||
                                      _printing ||
                                      widget.service.isPrinting
                                  ? null
                                  : () => _print(),
                              icon: const Icon(Icons.print),
                              label: Text(l.printerSystemPrint)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          OutlinedButton.icon(
                              key: const ValueKey('printer-test-page'),
                              onPressed: !canPrint ||
                                      _printing ||
                                      widget.service.isPrinting
                                  ? null
                                  : () => _print(testPage: true),
                              icon: const Icon(Icons.description_outlined),
                              label: Text(l.printerTestAction)),
                          if (widget.service.canOpenSettings)
                            OutlinedButton.icon(
                                key: const ValueKey('printer-settings'),
                                onPressed: _openingSettings ? null : _settings,
                                icon: const Icon(Icons.settings),
                                label: Text(l.printerOpenSettings)),
                          TextButton.icon(
                              key: const ValueKey('printer-refresh'),
                              onPressed: _loading || _printing ? null : _load,
                              icon: const Icon(Icons.refresh),
                              label: Text(l.commonRefresh)),
                        ]),
                        if (_printing)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(children: [
                                const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(l.printerWaiting)),
                              ])),
                        if (widget.service.isPrinting && !_printing)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(l.printerJobBusy)),
                        if (_message != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_message!,
                                  key: const ValueKey('printer-result'))),
                        if (_loading)
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: LinearProgressIndicator()),
                        if (_info?.canPrint == false)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(l.printerUnsupported)),
                        if (_discoveryError)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(l.printerDiscoveryError)),
                        if (_info != null &&
                            widget.service.canList(_info!)) ...[
                          const Divider(),
                          Text(l.printerInstalledTitle,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (!_loading &&
                              !_discoveryError &&
                              _printers.isEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(l.printerNoInstalled)),
                          for (final printer in _printers)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(printer.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall),
                                      if (printer.model != null &&
                                          printer.model!.isNotEmpty)
                                        Text(printer.model!),
                                      if (printer.isDefault)
                                        Text(l.printerSystemDefault),
                                      if (!printer.isAvailable)
                                        Text(l.printerNotAvailable),
                                      if (widget.buildPdf != null &&
                                          widget.service.canPrintDirect(_info!))
                                        TextButton.icon(
                                            key: ValueKey(
                                                'printer-direct-${printer.url}'),
                                            onPressed: !printer.isAvailable ||
                                                    widget.buildPdf == null ||
                                                    _printing ||
                                                    widget.service.isPrinting
                                                ? null
                                                : () =>
                                                    _print(printer: printer),
                                            icon: const Icon(
                                                Icons.print_outlined),
                                            label: Text(l.printerActionPrint)),
                                    ])),
                        ],
                        const Divider(),
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(l.printerHelpTitle),
                            children: [
                              Text(l.printerHelpNetwork),
                              const SizedBox(height: 8),
                              Text(widget.service.isAndroid
                                  ? l.printerHelpAndroid
                                  : l.printerHelpWindows),
                              const SizedBox(height: 8),
                              Text(l.printerHelpIp),
                              const SizedBox(height: 8),
                              Text(l.printerHelpDirect),
                              const SizedBox(height: 8),
                              Text(l.printerHelpQueue),
                              const SizedBox(height: 8),
                              Text(l.printerCompatibility),
                              const SizedBox(height: 12),
                            ]),
                      ]))),
                ]))));
  }
}
