import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_extension.dart';
import '../models/form_print_options.dart';
import '../models/report.dart';
import '../services/document_file_service.dart';
import '../services/reports_service.dart';
import '../utils/api_error_mapper.dart';
import '../utils/form_pdf_builder.dart';
import 'pdf_viewer_screen.dart';

class BlankFormsView extends StatefulWidget {
  final ReportsService? service;
  final Future<bool> Function(Uint8List bytes, String filename)? saveFile;
  const BlankFormsView({super.key, this.service, this.saveFile});
  @override
  State<BlankFormsView> createState() => _BlankFormsViewState();
}

class _BlankFormsViewState extends State<BlankFormsView> {
  late final ReportsService _service = widget.service ?? ReportsService();
  String _type = 'payments';
  bool _blank = true, _loading = true, _exporting = false, _showPreview = false;
  String? _error;
  ReportResponse? _report;
  FormPrintOptions _options = const FormPrintOptions();
  Future<FormPdfResult>? _pdf;
  Timer? _debounce;
  int _request = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _request++;
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final type = _type;
    final blank = _blank;
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
      _pdf = null;
    });
    try {
      final report = await _service.getBlankTemplate(type, filled: !blank);
      final prefs = await SharedPreferences.getInstance();
      var options = const FormPrintOptions();
      final saved = prefs.getString('form_print_v1_$type');
      if (saved != null) {
        try {
          options = FormPrintOptions.fromJson(
              jsonDecode(saved) as Map<String, dynamic>);
        } catch (_) {/* Invalid preferences use defaults. */}
      }
      final columns = options.columns?.where(report.columns.contains).toList();
      options = options.copyWith(
          columns:
              columns == null || columns.isEmpty ? report.columns : columns);
      if (!mounted || request != _request) return;
      setState(() {
        _report = report;
        _options = options;
        _loading = false;
      });
      _rebuildPdf();
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = ApiErrorMapper.toLocalizedMessage(error, context.l10n);
      });
    }
  }

  void _change(FormPrintOptions options) {
    setState(() {
      _options = options;
      _pdf = null;
    });
    unawaited(_store(_type, options));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _rebuildPdf);
  }

  void _moveColumn(String column, int offset) {
    final columns = [...?_options.columns];
    final from = columns.indexOf(column);
    final to = from + offset;
    if (_exporting || from < 0 || to < 0 || to >= columns.length) return;
    columns.removeAt(from);
    columns.insert(to, column);
    _change(_options.copyWith(columns: columns));
  }

  Future<void> _store(String type, FormPrintOptions options) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'form_print_v1_$type', jsonEncode(options.toJson()));
    } catch (_) {/* Preferences must not prevent printing. */}
  }

  void _rebuildPdf() {
    if (!mounted || _report == null) return;
    final report = _report!;
    final options = _options;
    final blank = _blank;
    setState(() {
      _pdf = FormPdfBuilder.build(report, options, blank: blank);
    });
  }

  String _filename(String extension) =>
      '${_blank ? 'formulario' : 'conferencia'}_$_type.$extension';

  Future<void> _export(String extension) async {
    if (_report == null || _exporting || _loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final report = _report!;
    final options = _options;
    final type = _type;
    final blank = _blank;
    final filename = _filename(extension);
    setState(() => _exporting = true);
    try {
      final Uint8List bytes;
      if (extension == 'pdf') {
        bytes = (await (_pdf ??
                FormPdfBuilder.build(report, options, blank: blank)))
            .bytes;
      } else {
        final resolved = blank && options.blankRowCount == null
            ? options.copyWith(
                blankRowCount: (await (_pdf ??
                        FormPdfBuilder.build(report, options, blank: true)))
                    .rows)
            : options;
        bytes = Uint8List.fromList(
            await _service.exportConfiguredForm(type, report, resolved));
      }
      final saved =
          await (widget.saveFile ?? DocumentFileService.save)(bytes, filename);
      if (mounted && saved) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.formFileSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.formExportFailure)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openPreview() async {
    if (_report == null || _exporting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final report = _report!;
    final options = _options;
    final blank = _blank;
    final filename = _filename('pdf');
    setState(() => _exporting = true);
    try {
      final result =
          await (_pdf ?? FormPdfBuilder.build(report, options, blank: blank));
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                    title: report.metadata.title,
                    fileName: filename,
                    buildPdf: (_) async => result.bytes,
                    canChangeOrientation: false,
                    initialPageFormat: options.landscape(
                            (options.columns ?? report.columns).length)
                        ? PdfPageFormat.a4.landscape
                        : PdfPageFormat.a4,
                  )));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.formExportFailure)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = _report;
    final columns = _options.columns ?? report?.columns ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(l.blankFormsTitle), actions: [
        IconButton(
            tooltip: l.commonRefresh,
            onPressed: _exporting ? null : _load,
            icon: const Icon(Icons.refresh))
      ]),
      body: Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                          key: const ValueKey('form-type'),
                          initialValue: _type,
                          isExpanded: true,
                          decoration: InputDecoration(
                              labelText: l.formDocumentType,
                              border: const OutlineInputBorder()),
                          items: [
                            DropdownMenuItem(
                                value: 'payments',
                                child: Text(l.formTypePayments,
                                    overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(
                                value: 'payables',
                                child: Text(l.formTypePayables,
                                    overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(
                                value: 'physical_inventory',
                                child: Text(l.formTypeInventory,
                                    overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: _exporting
                              ? null
                              : (value) {
                                  if (value != null && value != _type) {
                                    setState(() => _type = value);
                                    _load();
                                  }
                                }),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ChoiceChip(
                            label: Text(l.formModeBlank),
                            selected: _blank,
                            onSelected: _exporting
                                ? null
                                : (_) {
                                    if (!_blank) {
                                      setState(() => _blank = true);
                                      _load();
                                    }
                                  }),
                        ChoiceChip(
                            label: Text(l.formModeFilled),
                            selected: !_blank,
                            onSelected: _exporting
                                ? null
                                : (_) {
                                    if (_blank) {
                                      setState(() => _blank = false);
                                      _load();
                                    }
                                  }),
                      ]),
                      const SizedBox(height: 8),
                      Text(_type == 'payments'
                          ? l.formPaymentsHelp
                          : _type == 'payables'
                              ? l.formPayablesHelp
                              : l.formInventoryHelp),
                      const SizedBox(height: 8),
                      Text(l.formPaperOnly,
                          style: Theme.of(context).textTheme.bodySmall),
                      if (_loading)
                        const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()))
                      else if (_error != null)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(_error!),
                              TextButton(
                                  onPressed: _load,
                                  child: Text(l.commonRefresh))
                            ]))
                      else if (report != null) ...[
                        const SizedBox(height: 16),
                        _card(l.formSelectColumns, [
                          Text(l.formColumnsHelp),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            for (var i = 0; i < report.columns.length; i++)
                              FilterChip(
                                  key: ValueKey('column-${report.columns[i]}'),
                                  label: Text(report.headers[i]),
                                  selected: columns.contains(report.columns[i]),
                                  onSelected: _exporting
                                      ? null
                                      : (selected) {
                                          final next = [...columns];
                                          if (selected) {
                                            next.add(report.columns[i]);
                                          } else {
                                            if (next.length == 1) return;
                                            next.remove(report.columns[i]);
                                          }
                                          _change(
                                              _options.copyWith(columns: next));
                                        }),
                          ]),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                  onPressed: _exporting
                                      ? null
                                      : () => _change(_options.copyWith(
                                              columns: [
                                                ...columns,
                                                ...report.columns.where(
                                                    (c) => !columns.contains(c))
                                              ])),
                                  child: Text(l.formAllColumns))),
                          ExpansionTile(
                            key: const ValueKey('form-column-order'),
                            tilePadding: EdgeInsets.zero,
                            title: Text(l.formColumnOrder),
                            subtitle: Text(l.formColumnOrderHelp),
                            children: [
                              for (var i = 0; i < columns.length; i++)
                                Padding(
                                  key: ValueKey('ordered-column-${columns[i]}'),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 30, child: Text('${i + 1}.')),
                                    Expanded(
                                        child: Text(report.headers[report
                                            .columns
                                            .indexOf(columns[i])])),
                                    IconButton(
                                      key: ValueKey('column-up-${columns[i]}'),
                                      tooltip: l.formColumnMoveUp,
                                      onPressed: _exporting || i == 0
                                          ? null
                                          : () => _moveColumn(columns[i], -1),
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      key:
                                          ValueKey('column-down-${columns[i]}'),
                                      tooltip: l.formColumnMoveDown,
                                      onPressed: _exporting ||
                                              i == columns.length - 1
                                          ? null
                                          : () => _moveColumn(columns[i], 1),
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                  ]),
                                ),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    key: const ValueKey('restore-column-order'),
                                    onPressed: _exporting
                                        ? null
                                        : () => _change(_options.copyWith(
                                            columns: report.columns
                                                .where(columns.contains)
                                                .toList())),
                                    child: Text(l.formColumnOrderReset),
                                  )),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _card(l.formPrintSettings, [
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                    key: ValueKey(
                                        'orientation-${_options.orientation}'),
                                    initialValue: _options.orientation,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                        labelText: l.formOrientation,
                                        border: const OutlineInputBorder()),
                                    items: [
                                      DropdownMenuItem(
                                          value: 'auto',
                                          child: Text(l.formOrientationAuto)),
                                      DropdownMenuItem(
                                          value: 'portrait',
                                          child: Text(l.formPortrait)),
                                      DropdownMenuItem(
                                          value: 'landscape',
                                          child: Text(l.formLandscape))
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        _change(
                                            _options.copyWith(orientation: v));
                                      }
                                    })),
                            _number(
                                'row-height',
                                l.formRowHeight,
                                _options.rowHeightMm,
                                6,
                                30,
                                (v) =>
                                    _change(_options.copyWith(rowHeightMm: v))),
                            _number(
                                'font-size',
                                l.formFontSize,
                                _options.fontSize,
                                8,
                                16,
                                (v) => _change(_options.copyWith(fontSize: v))),
                          ]),
                          const SizedBox(height: 12),
                          Text(l.formPageMargins),
                          const SizedBox(height: 8),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            _number(
                                'margin-top',
                                l.formMarginTop,
                                _options.marginTopMm,
                                5,
                                40,
                                (v) =>
                                    _change(_options.copyWith(marginTopMm: v))),
                            _number(
                                'margin-bottom',
                                l.formMarginBottom,
                                _options.marginBottomMm,
                                5,
                                40,
                                (v) => _change(
                                    _options.copyWith(marginBottomMm: v))),
                            _number(
                                'margin-left',
                                l.formMarginLeft,
                                _options.marginLeftMm,
                                5,
                                40,
                                (v) => _change(
                                    _options.copyWith(marginLeftMm: v))),
                            _number(
                                'margin-right',
                                l.formMarginRight,
                                _options.marginRightMm,
                                5,
                                40,
                                (v) => _change(
                                    _options.copyWith(marginRightMm: v))),
                          ]),
                          const SizedBox(height: 8),
                          Text(l.formMarginHelp,
                              style: Theme.of(context).textTheme.bodySmall),
                          if (_blank) ...[
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.formAutoRows),
                                value: _options.blankRowCount == null,
                                onChanged: (v) => _change(_options.copyWith(
                                    automaticRows: v,
                                    blankRowCount: v
                                        ? null
                                        : _options
                                            .automaticRows(columns.length)))),
                            if (_options.blankRowCount != null)
                              _number(
                                  'blank-rows',
                                  l.formBlankRows,
                                  _options.blankRowCount!.toDouble(),
                                  1,
                                  500,
                                  (v) => _change(_options.copyWith(
                                      blankRowCount: v.round()))),
                          ],
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l.formShowSignatures),
                              value: _options.showSignatures,
                              onChanged: (v) => _change(
                                  _options.copyWith(showSignatures: v))),
                          ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(l.formColumnWidths),
                              subtitle: Text(l.formColumnWidthHelp),
                              children: [
                                Wrap(spacing: 12, runSpacing: 12, children: [
                                  for (final col in columns)
                                    _number(
                                        'weight-$col',
                                        report.headers[
                                            report.columns.indexOf(col)],
                                        _options.weight(col),
                                        0.5,
                                        8,
                                        (v) => _change(_options.copyWith(
                                                columnWeights: {
                                                  ..._options.columnWeights,
                                                  col: v
                                                }))),
                                ]),
                                const SizedBox(height: 12),
                              ]),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                  icon: const Icon(Icons.restore),
                                  label: Text(l.formResetDefaults),
                                  onPressed: () => _change(FormPrintOptions(
                                      columns: report.columns)))),
                        ]),
                        const SizedBox(height: 12),
                        if (!_blank && report.rows.isEmpty)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(l.formNoRecords)),
                        FutureBuilder<FormPdfResult>(
                            future: _pdf,
                            builder: (context, snapshot) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(snapshot.hasError
                                    ? l.formExportFailure
                                    : snapshot.hasData
                                        ? l.formDocumentSummary(
                                            columns.length,
                                            snapshot.data!.rows,
                                            snapshot.data!.pages)
                                        : l.formPreparing))),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          FilledButton.icon(
                              onPressed: _exporting ? null : _openPreview,
                              icon: const Icon(Icons.print),
                              label: Text(l.formActionPrint)),
                          OutlinedButton.icon(
                              onPressed:
                                  _exporting ? null : () => _export('pdf'),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text(l.formSavePdf)),
                          OutlinedButton.icon(
                              onPressed:
                                  _exporting ? null : () => _export('xlsx'),
                              icon: const Icon(Icons.table_chart),
                              label: Text(l.formSaveXlsx)),
                          if (_exporting)
                            const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                        ]),
                        const SizedBox(height: 12),
                        ExpansionTile(
                            title: Text(l.formPreview),
                            onExpansionChanged: (v) =>
                                setState(() => _showPreview = v),
                            children: [
                              if (_showPreview && _pdf != null)
                                SizedBox(
                                    height: 520,
                                    child: FutureBuilder<FormPdfResult>(
                                        future: _pdf,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return Center(
                                                child:
                                                    Text(l.formExportFailure));
                                          }
                                          if (!snapshot.hasData) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          final bytes = snapshot.data!.bytes;
                                          return PdfPreview(
                                              key: ValueKey(bytes),
                                              build: (_) async => bytes,
                                              canChangeOrientation: false,
                                              canChangePageFormat: false,
                                              allowPrinting: false,
                                              allowSharing: false,
                                              canDebug: false,
                                              initialPageFormat: _options
                                                      .landscape(columns.length)
                                                  ? PdfPageFormat.a4.landscape
                                                  : PdfPageFormat.a4);
                                        })),
                            ]),
                      ],
                    ]),
              )))),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children
          ])));

  Widget _number(String id, String label, double value, double min, double max,
          ValueChanged<double> onChanged) =>
      SizedBox(
          width: 220,
          child: _PrintNumberField(
              key: ValueKey(id),
              label: label,
              value: value,
              min: min,
              max: max,
              onChanged: onChanged));
}

class _PrintNumberField extends StatefulWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _PrintNumberField(
      {super.key,
      required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});
  @override
  State<_PrintNumberField> createState() => _PrintNumberFieldState();
}

class _PrintNumberFieldState extends State<_PrintNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value));
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);
  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  double? get _number => double.tryParse(_controller.text.replaceAll(',', '.'));
  bool get _valid =>
      _number != null &&
      _number!.isFinite &&
      _number! >= widget.min &&
      _number! <= widget.max;
  void _commit() {
    if (_valid && _number != widget.value) widget.onChanged(_number!);
  }

  void _onFocus() {
    if (!_focus.hasFocus) _commit();
  }

  @override
  void didUpdateWidget(covariant _PrintNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: _controller,
        focusNode: _focus,
        decoration: InputDecoration(
            labelText: widget.label,
            helperText: '${_format(widget.min)} - ${_format(widget.max)}',
            border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (_) => _valid ? null : context.l10n.formInvalidNumber,
        onFieldSubmitted: (_) => _commit(),
        onChanged: (_) {
          if (_valid) _commit();
        },
        onTapOutside: (_) => _focus.unfocus(),
      );
}
