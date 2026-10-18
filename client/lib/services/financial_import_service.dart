import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import '../core/api_client.dart';

typedef FinancialJson = Map<String, dynamic>;

class FinancialImportFile {
  final String name;
  final Uint8List bytes;
  final String mediaType;
  FinancialImportFile(this.name, this.bytes, {String? mediaType})
      : mediaType = mediaType ??
            (name.toLowerCase().endsWith('.csv')
                ? 'text/csv'
                : 'application/pdf');

  bool get isPdf =>
      mediaType == 'application/pdf' || name.toLowerCase().endsWith('.pdf');
  bool get isCsv =>
      mediaType == 'text/csv' || name.toLowerCase().endsWith('.csv');

  static Future<FinancialImportFile?> pick({bool onlyPdf = false}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        if (onlyPdf)
          const XTypeGroup(
            label: 'PDF',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
            uniformTypeIdentifiers: ['com.adobe.pdf'],
          )
        else
          const XTypeGroup(
            label: 'Documentos financeiros (PDF, CSV)',
            extensions: ['pdf', 'csv'],
            mimeTypes: ['application/pdf', 'text/csv'],
            uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.comma-separated-values-text',
            ],
          ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 10 * 1024 * 1024) {
      throw ApiException(
        statusCode: 413,
        message: 'File size',
        errorCode: 'FINANCIAL_DOCUMENT_SIZE',
      );
    }
    final result = FinancialImportFile(
      file.name,
      await file.readAsBytes(),
    );
    result.validate();
    return result;
  }

  void validate() {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ApiException(
        statusCode: 413,
        message: 'File size',
        errorCode: 'FINANCIAL_DOCUMENT_SIZE',
      );
    }
    if (isPdf) {
      if (bytes.length < 5 ||
          ascii.decode(bytes.take(5).toList(), allowInvalid: true) != '%PDF-') {
        throw ApiException(
          statusCode: 422,
          message: 'PDF signature',
          errorCode: 'FINANCIAL_DOCUMENT_FORMAT',
        );
      }
    }
  }
}

class FinancialPdfFile extends FinancialImportFile {
  FinancialPdfFile(super.name, super.bytes, {super.mediaType});

  static Future<FinancialPdfFile?> pick() async {
    final f = await FinancialImportFile.pick(onlyPdf: true);
    if (f == null) return null;
    return FinancialPdfFile(f.name, f.bytes, mediaType: f.mediaType);
  }
}

/// Import evidence only. The backend owns parsing, controls and staging rules.
/// Connections are bound for the lifetime of the page. Keys are reproducible
/// from origin + exact request, including after process restart; no PDF/text is
/// copied to local preferences. Account/source retries reuse the same command.
class FinancialImportService {
  static const root = '/api/v1/financial-imports';
  final ApiClient api;
  ApiClient? _bound;
  ApiOrigin? _origin;
  FinancialImportService({ApiClient? apiClient})
    : api = apiClient ?? ApiClient();

  Future<ApiClient> _client() async {
    if (_bound == null) {
      _origin = await api.readOrigin();
      _bound = api.bindOrigin(_origin!);
    }
    return _bound!;
  }

  void close() => _bound?.close();

  String _key(String path, Object body) =>
      'fin-ui-v1:${sha256.convert(utf8.encode('${_origin!.storageId}\n$path\n${jsonEncode(body)}'))}';

  Future<FinancialJson> _post(String path, FinancialJson body) async {
    final client = await _client();
    return Map<String, dynamic>.from(
      await client.post(path, body: body, idempotencyKey: _key(path, body))
          as Map,
    );
  }

  Future<List<FinancialJson>> rows(String path) async {
    final client = await _client();
    return (await client.get(path) as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<FinancialJson> get(String path) async =>
      Map<String, dynamic>.from(await (await _client()).get(path) as Map);

  Future<List<FinancialJson>> sources() async {
    final result = <FinancialJson>[];
    for (var offset = 0; ; offset += 100) {
      final page = await rows('$root/sources?limit=100&offset=$offset');
      result.addAll(page);
      if (page.length < 100) return result;
    }
  }

  Future<List<FinancialJson>> bankAccounts() =>
      rows('/api/v1/treasury/accounts?is_active=true&account_type=BANK');

  Future<FinancialJson> createSource({
    required String name,
    required String institution,
    required String sourceType,
    required String holderType,
    String? accountId,
  }) async {
    if (sourceType == 'BANK_ACCOUNT' && accountId == null) {
      final account = await _post('/api/v1/treasury/accounts', {
        'name': name,
        'account_type': 'BANK',
        'bank_name': institution,
        'initial_balance_cents': 0,
        'is_default': false,
      });
      accountId = account['id'] as String;
    }
    return _post('$root/sources', {
      'name': name,
      'institution': institution,
      'source_type': sourceType,
      'holder_type': holderType,
      'currency': 'BRL',
      if (accountId != null) 'financial_account_id': accountId,
    });
  }

  Future<List<FinancialJson>> readers() => rows('$root/readers');

  Future<FinancialJson> importDocument(
    FinancialImportFile file,
    String sourceId, {
    String? readerId,
    String? password,
    Map<String, dynamic>? options,
  }) async {
    file.validate();
    final client = await _client();
    final path =
        '$root/documents?filename=${Uri.encodeQueryComponent(file.name)}';
    final doc = Map<String, dynamic>.from(
      await client.uploadBytes(
            path,
            bytes: file.bytes,
            contentType: file.mediaType,
            idempotencyKey: _key(path, sha256.convert(file.bytes).toString()),
          )
          as Map,
    );
    final chosenReader = readerId ?? (file.isPdf ? 'pdf_auto' : 'generic_csv');
    final payload = <String, dynamic>{
      'source_id': sourceId,
      'currency': 'BRL',
      'reader_id': chosenReader,
      if (password != null && password.isNotEmpty) 'password': password,
      if (options != null) 'options': options,
    };
    final docId = doc['id'] as String? ??
        (doc['document'] as Map?)?['id'] as String? ??
        (throw ApiException(statusCode: 500, message: 'ID do documento ausente'));
    final result = await _post('$root/documents/$docId/previews', payload);
    return Map<String, dynamic>.from(result['preview'] as Map);
  }

  Future<FinancialJson> post(String path, FinancialJson body) => _post(path, body);

  Future<FinancialJson> createPreview(
    String documentId, {
    required String sourceId,
    String? readerId,
    String? password,
    Map<String, dynamic>? options,
  }) async {
    final payload = <String, dynamic>{
      'source_id': sourceId,
      'currency': 'BRL',
      'reader_id': readerId ?? 'pdf_auto',
      if (password != null && password.isNotEmpty) 'password': password,
      if (options != null) 'options': options,
    };
    final result = await _post('$root/documents/$documentId/previews', payload);
    return Map<String, dynamic>.from(result['preview'] as Map);
  }

  Future<FinancialJson> importPdf(
    FinancialImportFile file,
    String sourceId, {
    String? password,
    String? readerId,
  }) =>
      importDocument(
        file,
        sourceId,
        readerId: readerId ?? 'pdf_auto',
        password: password,
      );

  Future<FinancialJson> confirm(
    FinancialJson preview, {
    Map<String, dynamic>? confirmationHeader,
  }) async {
    if (preview['status'] != 'READY') {
      throw ApiException(
        statusCode: 409,
        message: 'Blocked preview',
        errorCode: 'FINANCIAL_PREVIEW_INVALID',
      );
    }
    final header = Map<String, dynamic>.from(
      preview['extracted_header'] as Map? ?? {},
    );
    final statementType = header['statement_type'] ??
        (preview['reader_id'].toString().contains('card')
            ? 'CARD_BILL'
            : 'BANK_STATEMENT');
    final result = await _post('$root/previews/${preview['id']}/confirm', {
      'expected_source_id': preview['source_id'],
      'expected_result_sha256': preview['result_sha256'],
      'statement_type': statementType,
      if (confirmationHeader != null) ...confirmationHeader,
    });
    return Map<String, dynamic>.from(result['statement'] as Map);
  }

  Future<Uint8List> original(String documentId) async => Uint8List.fromList(
    await (await _client()).getBytes('$root/documents/$documentId/content'),
  );

  Future<FinancialJson?> getSemanticReview(String statementId) async {
    try {
      final res = await get('$root/statements/$statementId/semantic-reviews/current');
      return res;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<FinancialJson> saveSemanticReview(
    String statementId, {
    required int expectedRevision,
    required List<FinancialJson> items,
    String? notes,
  }) async {
    return _post('$root/statements/$statementId/semantic-reviews', {
      'expected_revision': expectedRevision,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<List<FinancialJson>> generateObligations(
    String statementId, {
    String? reviewId,
    String? notes,
  }) async {
    final res = await _post('$root/statements/$statementId/generate-obligations', {
      if (reviewId != null) 'review_id': reviewId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return (res['obligations'] as List? ?? [])
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<List<FinancialJson>> getObligations(String statementId) async {
    final res = await rows('$root/statements/$statementId/obligations');
    return res;
  }

  Future<FinancialJson> postStatementToTreasury(String statementId) async {
    return _post('$root/statements/$statementId/post-to-treasury', {});
  }

  Future<List<FinancialJson>> getStatements({String? sourceId}) async {
    final path = sourceId != null ? '$root/statements?source_id=$sourceId' : '$root/statements';
    return rows(path);
  }

  Future<FinancialJson> getStatement(String statementId) async {
    return get('$root/statements/$statementId');
  }
}
