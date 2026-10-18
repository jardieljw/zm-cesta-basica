import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

class DocumentFileService {
  static Future<bool> save(Uint8List bytes, String filename) async {
    final dot = filename.lastIndexOf('.');
    final extension = filename.substring(dot + 1);
    final path = await FileSaver.instance.saveAs(
        name: filename.substring(0, dot),
        bytes: bytes,
        fileExtension: extension,
        mimeType: MimeType.custom,
        customMimeType: extension == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    return path != null && path.isNotEmpty;
  }
}
