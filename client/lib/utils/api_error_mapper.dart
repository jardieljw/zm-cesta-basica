import 'dart:io';
import '../core/api_client.dart';
import '../l10n/app_localizations.dart';

/// Centralized mapper that converts backend API errors and technical exceptions
/// into user-friendly localized messages.
class ApiErrorMapper {
  /// Resolves an error object into a localized user-friendly message.
  static String toLocalizedMessage(dynamic error, AppLocalizations l10n) {
    if (error is ApiException) {
      // 1. Check stable backend error codes
      if (error.errorCode != null) {
        switch (error.errorCode) {
          case 'INSUFFICIENT_STOCK':
            return l10n.errorInsufficientStock;
          case 'IDEMPOTENCY_PAYLOAD_MISMATCH':
            return l10n.errorIdempotencyMismatch;
          case 'REQUEST_IN_PROGRESS':
            return l10n.errorRequestInProgress;
          case 'UNAUTHORIZED':
            return l10n.errorUnauthorized;
          case 'DEVICE_REVOKED':
            return l10n.errorDeviceRevoked;
          case 'FORBIDDEN':
            return l10n.errorForbidden;
          case 'NOT_FOUND':
            return l10n.errorNotFound;
          case 'CONFLICT':
            return l10n.errorConflict;
          case 'VALIDATION_ERROR':
            return l10n.errorValidationError;
        }
      }

      // 2. Fallback based on HTTP status codes
      switch (error.statusCode) {
        case 0:
          return l10n.errorConnectionFailed;
        case 401:
          return l10n.errorUnauthorized;
        case 403:
          return l10n.errorForbidden;
        case 404:
          return l10n.errorNotFound;
        case 409:
          return l10n.errorConflict;
        case 422:
          return l10n.errorValidationError;
        case 500:
        case 502:
        case 503:
        case 504:
          return l10n.errorServer;
      }

      // If message is present and non-technical, return it, else default
      if (error.message.isNotEmpty &&
          !error.message.startsWith('{') &&
          !error.message.startsWith('[') &&
          !error.message.contains('pydantic')) {
        return error.message;
      }

      return l10n.commonError;
    }

    if (error is SocketException) {
      return l10n.errorConnectionFailed;
    }

    final str = error.toString().replaceAll('Exception: ', '').trim();
    if (str.isNotEmpty && !str.contains('SocketException') && !str.contains('ClientException')) {
      return str;
    }

    return l10n.errorUnexpected;
  }
}
