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
          case 'FINANCIAL_CLIENT_UPDATE_REQUIRED':
            return l10n.pdfImportServerUpdate;
          case 'FINANCIAL_IMPORT_GENERATION_CONFLICT':
          case 'FINANCIAL_IMPORT_HISTORICAL_READ_ONLY':
            return l10n.financialImportGenerationConflict;
          case 'FINANCIAL_IMPORT_ACTIVE':
            return l10n.financialImportAlreadyActive;
          case 'FINANCIAL_IMPORT_CONFIRMED':
            return l10n.financialImportConfirmedRead;
          case 'FINANCIAL_IMPORT_LEGACY_REVIEW_REQUIRED':
            return l10n.financialImportLegacyReviewRequired;
          case 'FINANCIAL_IMPORT_REINSTATEMENT_CONFLICT':
            return l10n.financialImportReinstatementConflict;
          case 'ASSEMBLY_HAS_ACTIVE_SALE':
          case 'ASSEMBLY_RECIPE_STOCK_UNCERTAIN':
          case 'RECIPE_IN_USE':
          case 'PRODUCT_REMOVED':
            return error.message;
          case 'FINANCIAL_IMPORT_REMOVAL_CHANGED':
            return l10n.importRemovalChanged;
          case 'FINANCIAL_IMPORT_REMOVED':
            return l10n.importRemovalRemoved;
          case 'FINANCIAL_IMPORT_REMOVAL_BLOCKED':
            return l10n.importRemovalBlockedError;
          case 'FINANCIAL_IMPORT_CONTROL_MISMATCH':
            return l10n.importControlMismatch;
          case 'FINANCIAL_BILL_PREVIOUS_BALANCE_CONFLICT':
            return l10n.importPreviousBalanceConflict;
          case 'FINANCIAL_CASH_REVIEW_REQUIRED':
            return l10n.importCashReviewRequired;
          case 'FINANCIAL_BILL_ALLOCATION_REQUIRED':
            return l10n.importAllocationRequired;
          case 'FINANCIAL_REIMPORT_REQUIRED':
            return l10n.importReimportRequired;
          case 'FINANCIAL_BILL_CYCLE_ALREADY_REPRESENTED':
            return l10n.importCycleRepresented;
          case 'FINANCIAL_PURCHASE_ALLOCATION_REQUIRED':
          case 'FINANCIAL_PURCHASE_LINK_INVALID':
            return l10n.importPurchaseAllocation;
          case 'FINANCIAL_BILL_CATEGORY_SIGN':
            return l10n.importInvalidSign;
          case 'FINANCIAL_BILL_REVISION_CONFLICT':
            return l10n.importReviewLatest;
          case 'FINANCIAL_BILL_CONTENT_CONFLICT':
            return l10n.financialContentConflictError;
          case 'FINANCIAL_SEGMENT_NOT_FOUND':
          case 'SEGMENT_SELECTION_REQUIRED':
            return l10n.financialSegmentsHelp;
          case 'FINANCIAL_SUMMARY_FIELD_INVALID':
          case 'FINANCIAL_COMPILED_ROW_INVALID':
            return l10n.pdfImportHeader;
          case 'FINANCIAL_BILL_REVIEW_REQUIRED':
            return l10n.importEvidenceInvalid;
          case 'BILL_REVIEW_NOT_BALANCED':
            return l10n.importExactRequired;
          case 'CSV_DIRECTION_MAPPING_REQUIRED':
          case 'CSV_AMBIGUOUS_COLUMNS':
            return l10n.importCsvDirection;
          case 'PDF_COMPILED_DOCUMENT_REVIEW_REQUIRED':
          case 'PDF_MULTIPLE_BILLING_CYCLES':
            return l10n.importPdfCompilation;
          case 'FINANCIAL_SCHEMA_NOT_READY':
            return l10n.pdfImportServerUpdate;
          case 'PDF_RUNTIME_UNAVAILABLE':
            return l10n.pdfImportRuntime;
          case 'PDF_PROCESSING_BUSY':
          case 'PDF_PROCESSING_FAILED':
          case 'PDF_PROCESSING_TIMEOUT':
            return l10n.pdfImportProcessing;
          case 'FINANCIAL_AUTH_REQUIRED':
            return l10n.errorUnauthorized;
          case 'FINANCIAL_DOCUMENT_SIZE':
            return l10n.pdfImportSize;
          case 'FINANCIAL_DOCUMENT_FORMAT':
          case 'FINANCIAL_DOCUMENT_TYPE':
          case 'PDF_INVALID_OR_UNREADABLE':
            return l10n.pdfImportInvalidFile;
          case 'PDF_PASSWORD_REQUIRED':
            return l10n.pdfImportPassword;
          case 'PDF_OCR_OR_TEXT_REQUIRED':
            return l10n.pdfImportOcr;
          case 'PDF_LAYOUT_UNSUPPORTED':
          case 'PDF_LAYOUT_AMBIGUOUS':
            return l10n.pdfImportUnsupported;
          case 'FINANCIAL_SUMMARY_ONLY':
          case 'FINANCIAL_COMPILED_DOCUMENT':
            return l10n.financialImportSummaryOnly;
          case 'FINANCIAL_READER_AMBIGUOUS':
          case 'CSV_LAYOUT_MISMATCH':
            return l10n.financialImportReaderAmbiguous;
          case 'FINANCIAL_DUE_DATE_CONFLICT':
            return l10n.financialDueResolutionHelp;
          case 'PDF_SUMMARY_DETAIL_MISMATCH':
          case 'PDF_BANK_TOTAL_MISMATCH':
            return l10n.pdfImportMismatch;
          case 'PDF_UNPARSED_DATED_ROW':
          case 'PDF_UNPARSED_MONEY_ROW':
          case 'PDF_AMOUNT_SIGN_AMBIGUOUS':
            return l10n.pdfImportUnknownRow;
          case 'PDF_SOURCE_TYPE_MISMATCH':
          case 'FINANCIAL_INSTITUTION_MISMATCH':
          case 'FINANCIAL_IMPORT_SOURCE_MISMATCH':
            return l10n.pdfImportWrongSource;
          case 'PDF_PAGE_LIMIT':
          case 'PDF_CONTENT_LIMIT':
            return l10n.pdfImportLimit;
          case 'PDF_CONFLICTING_HEADER':
          case 'FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE':
          case 'FINANCIAL_BILL_CONTROLS_REQUIRED':
          case 'PDF_BILL_HEADER_REQUIRED':
          case 'PDF_SUMMARY_CONTROLS_REQUIRED':
          case 'PDF_BANK_PERIOD_REQUIRED':
          case 'PDF_BANK_CONTEXT_REQUIRED':
          case 'PDF_BANK_CONTROLS_REQUIRED':
          case 'PDF_INVALID_HEADER_OR_ITEMS':
          case 'PDF_INVALID_TRANSACTION':
          case 'PDF_NO_TRANSACTIONS':
          case 'FINANCIAL_PDF_HEADER_CONFLICT':
          case 'FINANCIAL_IMPORT_HEADER_INVALID':
            return l10n.pdfImportHeader;
          case 'FINANCIAL_BILL_DETAILS_PENDING':
          case 'FINANCIAL_INSTALLMENT_REVISION_CONFLICT':
          case 'FINANCIAL_INSTALLMENT_LINK_CONFLICT':
          case 'FINANCIAL_INSTALLMENT_CANCELLATION_EVIDENCE':
          case 'FINANCIAL_INSTALLMENT_DATE_LIMIT':
          case 'FINANCIAL_BILL_LEGACY_REVIEW':
          case 'FINANCIAL_BILL_PREVIOUS_BALANCE_LINK':
          case 'FINANCIAL_BILL_REPLACEMENT_CONFLICT':
          case 'FINANCIAL_BILL_PAID_COMPOSITION_CONFLICT':
          case 'FINANCIAL_BILL_LEGACY_PAYMENT_REVIEW':
          case 'FINANCIAL_BILL_ROLE_CONFLICT':
          case 'FINANCIAL_BILL_ACTIVE_DESTINATION':
          case 'FINANCIAL_BILL_CYCLE_CONFLICT':
          case 'FINANCIAL_BILL_CYCLE_REQUIRED':
          case 'FINANCIAL_BILL_SINGLE_CYCLE_REQUIRED':
            return l10n.billIntegrationConflict;
          case 'FINANCIAL_PREVIEW_INVALID':
          case 'FINANCIAL_PREVIEW_CHANGED':
            return l10n.pdfImportBlockedHelp;
          case 'FINANCIAL_SOURCE_EXISTS':
            return l10n.pdfImportSourceExists;
          case 'FINANCIAL_BANK_ACCOUNT_REQUIRED':
          case 'FINANCIAL_IMPORT_CURRENCY_MISMATCH':
          case 'INVALID_FINANCIAL_DATA':
            return l10n.pdfImportInvalidSource;
          case 'RECEIVABLE_BALANCE_CHANGED':
            return l10n.paymentFlowBalanceChanged;
          case 'RECEIVABLE_NOT_OPEN':
            return l10n.receiptFlowNotOpen;
          case 'RECEIVABLE_NOT_FOUND':
            return l10n.errorNotFound;
          case 'RECEIVABLE_AMOUNT_EXCEEDS_BALANCE':
            return l10n.receivablePaymentAmountExceedsBalance;
          case 'RECEIVABLE_PAYMENT_METHOD_INVALID':
            return l10n.receiptFlowSelectMethod;
          case 'PAYABLE_BALANCE_CHANGED':
            return l10n.paymentFlowBalanceChanged;
          case 'PAYABLE_NOT_OPEN':
            return l10n.paymentFlowNotOpen;
          case 'PAYABLE_NOT_FOUND':
            return l10n.errorNotFound;
          case 'PAYABLE_AMOUNT_EXCEEDS_BALANCE':
            return l10n.payablePaymentAmountExceedsBalance;
          case 'PAYABLE_PAYMENT_METHOD_INVALID':
            return l10n.paymentFlowSelectMethod;
          case 'PAYMENT_LOCAL_STORAGE':
            return l10n.paymentFlowLocalStorage;
          case 'PAYMENT_CONNECTION_CHANGED':
            return l10n.paymentFlowConnectionChanged;
          case 'PAYMENT_ATTEMPT_PENDING':
            return l10n.paymentFlowUncertain;
          case 'PAYMENT_CONFIRMATION_INVALID':
            return l10n.paymentFlowInvalidConfirmation;
          case 'PAYMENT_SERVER_UPDATE_REQUIRED':
            return l10n.paymentFlowServerUpdate;
          case 'INSUFFICIENT_STOCK':
            return l10n.errorInsufficientStock;
          case 'BASKET_STOCK_DISABLED':
            return l10n.basketStockDisabledError;
          case 'BASKET_DELETE_BLOCKED':
            return l10n.basketDeleteBlockedHelp;
          case 'BASKET_REMOVED':
            return l10n.basketRemovedError;
          case 'CUSTOMIZATION_DISABLED':
            return l10n.assemblyCustomizationDisabled;
          case 'BASKET_STOCK_REMAINS':
            return l10n.basketStockRemainsError;
          case 'RECIPE_CHANGED':
            return l10n.assemblyRecipeChanged;
          case 'ASSEMBLY_PENDING':
            return l10n.assemblyPendingHelp;
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
          case 'CUSTOMER_DOCUMENT_CONFLICT':
            return l10n.errorCustomerDocumentConflict;
          case 'CREDIT_LIMIT_EXCEEDED':
            return l10n.errorCreditLimitExceeded;
          case 'PRODUCT_HAS_HISTORY':
            return l10n.productDeleteHistoryError;
          case 'NEW_DATABASE_FAILED':
            return l10n.newDatabaseFailed;
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
    if (str.isNotEmpty &&
        !str.contains('SocketException') &&
        !str.contains('ClientException')) {
      return str;
    }

    return l10n.errorUnexpected;
  }
}
