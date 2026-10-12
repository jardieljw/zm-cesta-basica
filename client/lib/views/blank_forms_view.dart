import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/report.dart';
import '../services/reports_service.dart';
import '../utils/report_pdf_builder.dart';
import '../utils/api_error_mapper.dart';
import '../l10n/l10n_extension.dart';
import 'pdf_viewer_screen.dart';

class BlankFormsView extends StatefulWidget {
  const BlankFormsView({super.key});

  @override
  State<BlankFormsView> createState() => _BlankFormsViewState();
}

class _BlankFormsViewState extends State<BlankFormsView> {
  final ReportsService _reportsService = ReportsService();

  String _selectedFormType = 'payments';
  bool _isBlankMode = true; // true: Blank for handwriting, false: Pre-filled for audit
  int _blankRowCount = 16;
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  ReportResponse? _loadedReport;

  final List<Map<String, String>> _formTypes = [
    {
      'id': 'payments',
      'title': 'Tabela de Pagamentos de Cestas (Fiados / Quitações)',
      'filledReportType': 'receivables',
      'description': 'Controle de pagamentos na rota ou balcão, identificação do cliente e valores recebidos à vista ou a prazo.',
    },
    {
      'id': 'payables',
      'title': 'Tabela de Contas a Pagar e Vencimentos',
      'filledReportType': 'payables',
      'description': 'Conferência física de despesas, boletos, fornecedores e controle manual de baixas.',
    },
    {
      'id': 'dispatch_conference',
      'title': 'Folha de Conferência de Saídas e Custódia',
      'filledReportType': 'dispatch-settlements',
      'description': 'Conferência de carregamento, saída do galpão, termo de custódia e prestação de contas do responsável.',
    },
    {
      'id': 'physical_inventory',
      'title': 'Folha de Contagem Física (Auditoria / Balanço)',
      'filledReportType': 'physical-inventory',
      'description': 'Folha de inventário para contagem em prancheta, verificação de validades e auditoria física de estoque.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Map<String, String> get _currentFormConfig {
    return _formTypes.firstWhere(
      (f) => f['id'] == _selectedFormType,
      orElse: () => _formTypes.first,
    );
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _reportsService.getBlankTemplate(_selectedFormType, filled: !_isBlankMode);
      setState(() {
        _loadedReport = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ApiErrorMapper.toLocalizedMessage(e, context.l10n);
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadXlsx() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _reportsService.downloadBlankTemplateXlsx(_selectedFormType, filled: !_isBlankMode);
      final filename = _isBlankMode
          ? 'modelo_vazio_$_selectedFormType.xlsx'
          : 'auditoria_preenchida_$_selectedFormType.xlsx';

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Planilha XLSX baixada com sucesso: $filename'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar planilha: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _openPrintPreview() {
    if (_loadedReport == null) return;
    final rep = _loadedReport!;

    if (_isBlankMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            title: rep.metadata.title,
            fileName: 'formulario_em_branco_$_selectedFormType.pdf',
            buildPdf: (format) => ReportPdfBuilder.buildBlankFormPdf(
              rep,
              isLandscape: true,
              blankRowCount: _blankRowCount,
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            title: rep.metadata.title,
            fileName: 'auditoria_preenchida_$_selectedFormType.pdf',
            buildPdf: (format) => ReportPdfBuilder.buildReportPdf(
              rep,
              isLandscape: rep.columns.length > 5,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blankFormsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Dados',
            onPressed: _loadFormData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(theme),
            const SizedBox(height: 16),
            _buildFormSelector(theme),
            const SizedBox(height: 16),
            if (_isBlankMode) _buildBlankConfigCard(theme),
            const SizedBox(height: 16),
            _buildActionButtons(theme),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loadedReport != null) ...[
              _buildFormPreviewCard(theme, _loadedReport!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    final l10n = context.l10n;

    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.edit_note),
          label: Text(l10n.formModeBlank),
        ),
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.fact_check),
          label: Text(l10n.formModeFilled),
        ),
      ],
      selected: {_isBlankMode},
      onSelectionChanged: (set) {
        setState(() {
          _isBlankMode = set.first;
        });
        _loadFormData();
      },
    );
  }

  Widget _buildFormSelector(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modelo de Formulário / Tabela:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedFormType,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _formTypes.map((f) {
                return DropdownMenuItem(
                  value: f['id']!,
                  child: Text(f['title']!, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && val != _selectedFormType) {
                  setState(() => _selectedFormType = val);
                  _loadFormData();
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _currentFormConfig['description']!,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankConfigCard(ThemeData theme) {
    final l10n = context.l10n;

    return Card(
      elevation: 1,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ergonomia de Preenchimento Manual em Prancheta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.formBlankNotice,
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quantidade de Linhas em Branco: $_blankRowCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Expanded(
                  child: Slider(
                    value: _blankRowCount.toDouble(),
                    min: 10,
                    max: 25,
                    divisions: 15,
                    label: '$_blankRowCount linhas',
                    onChanged: (v) {
                      setState(() => _blankRowCount = v.round());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          icon: const Icon(Icons.print),
          label: Text(l10n.formActionPrint),
          onPressed: _loadedReport == null || _isLoading ? null : _openPrintPreview,
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          icon: const Icon(Icons.table_chart, color: Colors.green),
          label: Text(_isDownloading ? 'Baixando...' : l10n.formActionDownloadXlsx),
          onPressed: _loadedReport == null || _isLoading || _isDownloading ? null : _downloadXlsx,
        ),
      ],
    );
  }

  Widget _buildFormPreviewCard(ThemeData theme, ReportResponse report) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report.metadata.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  backgroundColor: _isBlankMode ? Colors.purple.shade50 : Colors.blue.shade50,
                  label: Text(
                    _isBlankMode ? 'Modo Caneta (Linhas Vazias)' : 'Modo Auditoria (${report.metadata.totalRows} registros)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isBlankMode ? Colors.purple.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Colunas do Formulário A4:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: report.headers.map((h) {
                return Chip(
                  label: Text(h, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
            if (!_isBlankMode && report.rows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Amostra dos Dados a Serem Impressos (Primeiras 5 linhas):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: report.headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                  rows: report.rows.take(5).map((r) {
                    return DataRow(
                      cells: report.columns.map((c) => DataCell(Text(r[c]?.toString() ?? '', style: const TextStyle(fontSize: 11)))).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
