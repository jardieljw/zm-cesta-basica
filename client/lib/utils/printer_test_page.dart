import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrinterTestPage {
  static Future<Uint8List> build(
      {required String title,
      required String instructions,
      required String characters,
      required String scaleLabel,
      required List<String> lineLabels,
      required String footer}) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15 * PdfPageFormat.mm),
        build: (_) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ZM Cesta Básica',
                      style: const pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text(title,
                      style: const pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Text(instructions,
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 20),
                  pw.Text(characters, style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Text('0123456789   R\$ 123,45   14/10/2026',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 22),
                  pw.Text(scaleLabel, style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                      width: 100 * PdfPageFormat.mm,
                      height: 20 * PdfPageFormat.mm,
                      decoration:
                          pw.BoxDecoration(border: pw.Border.all(width: 1)),
                      child: pw.Center(child: pw.Text('100 mm x 20 mm'))),
                  pw.SizedBox(height: 20),
                  for (var i = 0; i < lineLabels.length; i++)
                    pw.Container(
                        height: (8 + i) * PdfPageFormat.mm,
                        width: double.infinity,
                        alignment: pw.Alignment.centerLeft,
                        decoration: const pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(width: 0.5))),
                        child: pw.Text(lineLabels[i],
                            style: const pw.TextStyle(fontSize: 10))),
                  pw.Spacer(),
                  pw.Text(footer, style: const pw.TextStyle(fontSize: 9)),
                ])));
    return doc.save();
  }
}
