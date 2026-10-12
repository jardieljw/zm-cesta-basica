import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../l10n/l10n_extension.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.buildPdf,
    required this.fileName,
  });

  void _showPrinterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.print, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          const Text(
                            'Impressão Direta & Dispositivos',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    tileColor: Colors.blue.shade50,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.print_outlined, color: Colors.blue.shade900),
                    ),
                    title: const Text(
                      'Serviço de Impressão do Sistema',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Windows Spooler / Android PrintManager (compatível com Epson Wi-Fi, Mopria e impressoras de rede).',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Printing.layoutPdf(onLayout: buildPdf, name: fileName);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Impressoras Instaladas no Sistema:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<Printer>>(
                      future: Printing.listPrinters(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Localizando impressoras instaladas...', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }

                        final printers = snapshot.data ?? [];
                        if (printers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: Colors.black54, size: 36),
                                SizedBox(height: 12),
                                Text(
                                  'Nenhuma impressora listada via enumeração direta.',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'No Android ou em redes locais, utilize a opção "Serviço de Impressão do Sistema" acima para selecionar sua Epson Wi-Fi configurada no sistema operacional.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: printers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = printers[i];
                            final nameLower = p.name.toLowerCase();
                            final modelLower = (p.model ?? '').toLowerCase();
                            final isEpson = nameLower.contains('epson') || modelLower.contains('epson');
                            final isWifi = nameLower.contains('wi-fi') ||
                                nameLower.contains('wifi') ||
                                nameLower.contains('network') ||
                                (p.location?.toLowerCase().contains('wi-fi') ?? false);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isEpson ? Colors.blue.shade100 : Colors.grey.shade200,
                                child: Icon(
                                  Icons.print,
                                  color: isEpson ? Colors.blue.shade800 : Colors.black54,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: TextStyle(
                                        fontWeight: isEpson ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isEpson)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue.shade300),
                                      ),
                                      child: Text(
                                        isWifi ? 'Epson Wi-Fi' : 'Epson',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                [
                                  if (p.model != null && p.model!.isNotEmpty) p.model,
                                  if (p.isDefault) 'Padrão do Sistema',
                                  if (p.isAvailable) 'Disponível',
                                ].join(' • '),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.send, size: 14),
                                label: const Text('Imprimir', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEpson ? Colors.blue.shade700 : null,
                                  foregroundColor: isEpson ? Colors.white : null,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await Printing.directPrintPdf(
                                    printer: p,
                                    onLayout: buildPdf,
                                    name: fileName,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir / Selecionar Impressora (Epson Wi-Fi)',
            onPressed: () => _showPrinterSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar / Salvar PDF',
            onPressed: () async {
              final bytes = await buildPdf(PdfPageFormat.a4);
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: buildPdf,
        canChangeOrientation: true,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
        previewPageMargin: const EdgeInsets.all(16),
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.commonLoading),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices),
            tooltip: 'Dispositivos de Impressão (Epson Wi-Fi)',
            onPressed: () => _showPrinterSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar / Salvar PDF',
            onPressed: () async {
              final bytes = await buildPdf(PdfPageFormat.a4);
              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
          ),
        ],
      ),
    );
  }
}
