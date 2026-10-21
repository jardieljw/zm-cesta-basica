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
    : mediaType =
          mediaType ??
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
    final result = FinancialImportFile(file.name, await file.readAsBytes());
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
  Future<ApiClient> forkConnection() async {
    await _client();
    return api.bindOrigin(_origin!);
  }

  String _key(String path, Object body) =>
      'fin-ui-v1:${sha256.convert(utf8.encode('${_origin!.storageId}\n$path\n${jsonEncode(body)}'))}';

  Future<FinancialJson> _post(String path, FinancialJson body) async {
    if (path.startsWith('$root/previews/') ||
        path.startsWith('$root/statements/') ||
        path.startsWith('$root/items/') ||
        path == '$root/reconciliations' ||
        (path.startsWith('$root/documents/') &&
            (path.endsWith('/previews') || path.endsWith('/remove')))) {
      await requireLifecycle();
    }
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

  Future<List<FinancialJson>> allRows(String path) async {
    final uri = Uri.parse(path);
    final result = <FinancialJson>[];
    for (var offset = 0; ; offset += 500) {
      final page = await rows(
        uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'limit': '500',
                'offset': '$offset',
              },
            )
            .toString(),
      );
      result.addAll(page);
      if (page.length < 500) return result;
    }
  }

  Future<FinancialJson> _versioned(FinancialJson payload) async {
    final readers = await rows('$root/readers');
    final reader = readers
        .where((r) => r['id'] == payload['reader_id'])
        .firstOrNull;
    if (reader == null) {
      throw ApiException(
        statusCode: 409,
        message: 'Reader unavailable',
        errorCode: 'FINANCIAL_REIMPORT_REQUIRED',
      );
    }
    return {...payload, 'expected_reader_version': reader['version']};
  }

  /// Identity comes from the data being reviewed, never from a retry lookup.
  static FinancialJson lifecycleContext(FinancialJson value) => {
    if (value['import_id'] != null) 'import_id': value['import_id'],
    if (value['generation'] != null) 'expected_generation': value['generation'],
  };

  Future<void> requireLifecycle() async {
    final capability = await get('$root/capabilities');
    if (capability['import_lifecycle_version'] != 1) {
      throw ApiException(
        statusCode: 503,
        message:
            'Atualize o serviço de importação para consultar e salvar estes documentos.',
        errorCode: 'FINANCIAL_SCHEMA_NOT_READY',
      );
    }
  }

  Future<FinancialJson> importState(String documentId) async {
    await requireLifecycle();
    final state = await get('$root/documents/$documentId/import-state');
    final active = state['active_import'];
    if (state['lifecycle_version'] != 1 ||
        state['current_generation'] is! int ||
        (state['current_generation'] as int) < 0 ||
        (active != null &&
            (active is! Map ||
                active['id'] is! String ||
                active['generation'] != state['current_generation'] ||
                active['state'] != 'ACTIVE' ||
                state['root_preview_id'] is! String))) {
      throw ApiException(
        statusCode: 503,
        message: 'Estado de importação incompatível',
        errorCode: 'FINANCIAL_SCHEMA_NOT_READY',
      );
    }
    return state;
  }

  FinancialJson _previewResult(FinancialJson response) => {
    ...Map<String, dynamic>.from(response['preview'] as Map),
    if (response['import_id'] != null) 'import_id': response['import_id'],
    if (response['generation'] != null) 'generation': response['generation'],
  };

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
    String? controlPreviewId,
    String? cycleDueOn,
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
    final chosenReader = readerId ?? (file.isPdf ? 'pdf_auto' : 'csv_auto');
    final payload = <String, dynamic>{
      'source_id': sourceId,
      'currency': 'BRL',
      'reader_id': chosenReader,
      if (password != null && password.isNotEmpty) 'password': password,
      if (options != null) 'options': options,
      if (controlPreviewId != null) 'control_preview_id': controlPreviewId,
      if (cycleDueOn != null) 'cycle_due_on': cycleDueOn,
    };
    final docId =
        doc['id'] as String? ??
        (doc['document'] as Map?)?['id'] as String? ??
        (throw ApiException(
          statusCode: 500,
          message: 'ID do documento ausente',
        ));
    // Upload responses may be idempotent replays; always read current state.
    final state = await importState(docId);
    if (state['active_import'] != null) {
      return get('$root/previews/${state['root_preview_id']}');
    }
    final result = await _post(
      '$root/documents/$docId/previews',
      await _versioned({
        ...payload,
        'expected_generation': state['current_generation'],
      }),
    );
    return _previewResult(result);
  }

  Future<FinancialJson> post(String path, FinancialJson body) =>
      _post(path, body);

  Future<FinancialJson> removalPlan(
    String documentId, {
    FinancialJson? context,
  }) async {
    final capabilities = await get('$root/capabilities');
    if (capabilities['import_removal_version'] != 1) {
      throw ApiException(
        statusCode: 503,
        message: 'Update required',
        errorCode: 'FINANCIAL_SCHEMA_NOT_READY',
      );
    }
    context ??= {};
    if (context.isEmpty) {
      final state = await importState(documentId);
      final active = state['active_import'] as Map?;
      if (active == null) {
        throw ApiException(
          statusCode: 409,
          message: 'Importação já retirada. Atualize a lista.',
          errorCode: 'FINANCIAL_IMPORT_GENERATION_CONFLICT',
        );
      }
      context = {
        'import_id': active['id'],
        'expected_generation': active['generation'],
      };
    }
    return get(
      Uri(
        path: '$root/documents/$documentId/removal',
        queryParameters: context.map((key, value) => MapEntry(key, '$value')),
      ).toString(),
    );
  }

  Future<FinancialJson> removeImport(
    String documentId,
    String snapshot, {
    FinancialJson? context,
  }) => _post('$root/documents/$documentId/remove', {
    ...?context,
    'expected_snapshot': snapshot,
  });

  Future<FinancialJson> billIntegrationDraft(
    String previewId, {
    String? reference,
    FinancialJson? context,
  }) async {
    final capabilities = await get('$root/capabilities');
    if (capabilities['bill_cycle_version'] != 1 ||
        capabilities['bill_review_version'] != 2 ||
        capabilities['installment_agenda_version'] != 1) {
      throw ApiException(
        statusCode: 409,
        message: 'Update required',
        errorCode: 'FINANCIAL_REIMPORT_REQUIRED',
      );
    }
    await requireLifecycle();
    final query = Uri(
      queryParameters: {
        if (reference != null) 'reference': reference,
        ...?context?.map((key, value) => MapEntry(key, '$value')),
      },
    ).query;
    return get('$root/previews/$previewId/bill-integration?$query');
  }

  Future<FinancialJson> integrateBill(
    String previewId,
    FinancialJson command,
  ) => _post('$root/previews/$previewId/integrate-bill', command);

  Future<FinancialJson> selectSegment(
    FinancialJson preview,
    String key,
    String sourceId,
  ) async {
    final capability = await get('$root/capabilities');
    if (capability['segments_version'] != 1) {
      throw ApiException(
        statusCode: 409,
        message: 'Update required',
        errorCode: 'FINANCIAL_REIMPORT_REQUIRED',
      );
    }
    final result =
        await _post('$root/previews/${preview['id']}/select-segment', {
          ...lifecycleContext(preview),
          'expected_result_sha256': preview['result_sha256'],
          'segment_key': key,
          'source_id': sourceId,
        });
    return _previewResult(result);
  }

  Future<FinancialJson> createPreview(
    String documentId, {
    required String sourceId,
    String? readerId,
    String? password,
    Map<String, dynamic>? options,
    required FinancialJson context,
    required String expectedRootPreviewId,
  }) async {
    final payload = <String, dynamic>{
      ...context,
      'explicit_reprocess': true,
      'expected_root_preview_id': expectedRootPreviewId,
      'source_id': sourceId,
      'currency': 'BRL',
      'reader_id': readerId ?? 'pdf_auto',
      if (password != null && password.isNotEmpty) 'password': password,
      if (options != null) 'options': options,
    };
    final result = await _post(
      '$root/documents/$documentId/previews',
      await _versioned(payload),
    );
    return _previewResult(result);
  }

  Future<FinancialJson> importPdf(
    FinancialImportFile file,
    String sourceId, {
    String? password,
    String? readerId,
  }) => importDocument(
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
    final statementType =
        header['statement_type'] ??
        (preview['reader_id'].toString().contains('card')
            ? 'CARD_BILL'
            : 'BANK_STATEMENT');
    final result = await _post('$root/previews/${preview['id']}/confirm', {
      ...lifecycleContext(preview),
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
      final res = await get(
        '$root/statements/$statementId/semantic-reviews/current',
      );
      return res;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<FinancialJson> saveSemanticReview(
    String statementId, {
    FinancialJson? context,
    required int expectedRevision,
    required List<FinancialJson> items,
    String? notes,
  }) async {
    return _post('$root/statements/$statementId/semantic-reviews', {
      ...?context,
      'expected_revision': expectedRevision,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<List<FinancialJson>> generateObligations(
    String statementId, {
    FinancialJson? context,
    String? reviewId,
    String? notes,
  }) async {
    final res =
        await _post('$root/statements/$statementId/generate-obligations', {
          ...?context,
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

  Future<FinancialJson> postStatementToTreasury(
    String statementId, {
    FinancialJson? context,
  }) async {
    return _post('$root/statements/$statementId/post-to-treasury', {
      ...?context,
    });
  }

  Future<List<FinancialJson>> getStatements({String? sourceId}) async {
    final path = sourceId != null
        ? '$root/statements?source_id=$sourceId'
        : '$root/statements';
    return allRows(path);
  }

  Future<FinancialJson> getStatement(String statementId) async {
    return get('$root/statements/$statementId');
  }
}
