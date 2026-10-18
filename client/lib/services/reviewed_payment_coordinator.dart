import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

/// Persisted command identity. Domain modules own payload and receipt validation.
abstract interface class ReviewedPaymentAttempt {
  ApiOrigin get origin;
  String get titleId;
  String get key;
  bool get hasConfirmation;
  Map<String, dynamic> toJson();
}

class ReviewedPaymentAttemptStore<A extends ReviewedPaymentAttempt> {
  final String namespace;
  final A Function(Map<String, dynamic>) decode;

  ReviewedPaymentAttemptStore({required this.namespace, required this.decode});

  String _prefix(ApiOrigin origin) => '${namespace}_${origin.storageId}_';
  String _key(A attempt) => '${_prefix(attempt.origin)}${attempt.titleId}';

  Future<List<A>> list(ApiOrigin origin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <A>[];
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith(_prefix(origin)),
      )) {
        final attempt = decode(
          Map<String, dynamic>.from(jsonDecode(prefs.getString(key)!) as Map),
        );
        if (attempt.origin != origin || key != _key(attempt)) {
          throw const FormatException('Wrong origin');
        }
        result.add(attempt);
      }
      return result;
    } catch (_) {
      throw _storageError();
    }
  }

  Future<void> write(A attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key(attempt), jsonEncode(attempt.toJson()))) {
        throw _storageError();
      }
    } catch (_) {
      throw _storageError();
    }
  }

  Future<void> remove(A attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.remove(_key(attempt))) throw _storageError();
    } catch (_) {
      throw _storageError();
    }
  }

  ApiException _storageError() => ApiException(
    statusCode: 0,
    message: 'Local payment storage failed',
    errorCode: 'PAYMENT_LOCAL_STORAGE',
  );
}

/// Shares recovery mechanics without knowing payment methods or ledger rules.
class ReviewedPaymentEngine<A extends ReviewedPaymentAttempt, S, R> {
  final ReviewedPaymentAttemptStore<A> store;
  final Future<ApiOrigin> Function() readOrigin;
  final S Function(ApiOrigin) connect;
  final void Function(S) closeConnection;
  final Future<int> Function(S, String) reviewVersion;
  final Future<R> Function(S, A) record;
  final bool Function(A, R) matches;
  final A Function(A, R) confirmed;
  final Set<String> refusalCodes;
  final Map<ApiOrigin, S> _connections = {};
  static final Set<String> _active = {};

  ReviewedPaymentEngine({
    required this.store,
    required this.readOrigin,
    required this.connect,
    required this.closeConnection,
    required this.reviewVersion,
    required this.record,
    required this.matches,
    required this.confirmed,
    required this.refusalCodes,
  });

  S serviceFor(ApiOrigin origin) =>
      _connections.putIfAbsent(origin, () => connect(origin));

  void dispose() {
    for (final connection in _connections.values.toSet()) {
      closeConnection(connection);
    }
    _connections.clear();
  }

  Future<List<A>> pending() async => store.list(await readOrigin());

  Future<A?> attemptFor(String id, ApiOrigin origin) async {
    for (final attempt in await store.list(origin)) {
      if (attempt.titleId == id) return attempt;
    }
    return null;
  }

  Future<A> submit({
    required int capability,
    required A Function() createAttempt,
  }) async {
    if (capability < 1) throw _serverUpdateRequired();
    final attempt = createAttempt();
    return _locked(attempt, () async {
      if (await attemptFor(attempt.titleId, attempt.origin) != null) {
        throw _pending('Pending payment');
      }
      await store.write(attempt); // Freeze before the first POST.
      return _send(attempt);
    });
  }

  Future<A> resume(A attempt) => _locked(attempt, () async {
    final saved = await attemptFor(attempt.titleId, attempt.origin);
    if (saved == null || saved.key != attempt.key) {
      throw _pending('Attempt changed');
    }
    if (saved.hasConfirmation) return saved;
    return _send(saved);
  });

  Future<A> _send(A attempt) async {
    if (await readOrigin() != attempt.origin) {
      throw ApiException(
        statusCode: 0,
        message: 'Connection changed',
        errorCode: 'PAYMENT_CONNECTION_CHANGED',
      );
    }
    final bound = serviceFor(attempt.origin);
    // GET failures never prove rejection of a command already sent earlier.
    if (await reviewVersion(bound, attempt.titleId) < 1) {
      throw _serverUpdateRequired();
    }
    try {
      final result = await record(bound, attempt);
      if (!matches(attempt, result)) {
        throw ApiException(
          statusCode: 0,
          message: 'Invalid payment confirmation',
          errorCode: 'PAYMENT_CONFIRMATION_INVALID',
        );
      }
      final receipt = confirmed(attempt, result);
      // Losing local receipt storage does not undo a known confirmation. The
      // original persisted command remains safe to replay after a restart.
      try {
        await store.write(receipt);
      } catch (_) {}
      return receipt;
    } on ApiException catch (error) {
      // Only callback refusals after server replay lookup prove no write.
      // Transport/auth/422/5xx/in-progress/mismatch retain command identity.
      if (refusalCodes.contains(error.errorCode)) await store.remove(attempt);
      rethrow;
    }
  }

  Future<void> acknowledge(A attempt) async {
    if (!attempt.hasConfirmation) {
      throw StateError('Unresolved payment cannot be discarded');
    }
    await _locked(attempt, () async {
      final saved = await attemptFor(attempt.titleId, attempt.origin);
      if (saved != null && saved.key != attempt.key) {
        throw _pending('Attempt changed');
      }
      if (saved != null) await store.remove(saved);
      return attempt;
    });
  }

  Future<A> _locked(A attempt, Future<A> Function() action) async {
    final lock =
        '${store.namespace}/${attempt.origin.storageId}/${attempt.titleId}';
    if (!_active.add(lock)) throw _pending('Payment in progress');
    try {
      return await action();
    } finally {
      _active.remove(lock);
    }
  }

  ApiException _pending(String message) => ApiException(
    statusCode: 409,
    message: message,
    errorCode: 'PAYMENT_ATTEMPT_PENDING',
  );
  ApiException _serverUpdateRequired() => ApiException(
    statusCode: 0,
    message: 'Server update required',
    errorCode: 'PAYMENT_SERVER_UPDATE_REQUIRED',
  );
}
