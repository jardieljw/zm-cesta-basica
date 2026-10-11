import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Centralized formatting helpers respecting pt_BR locale and project business conventions.
class AppFormatters {
  static const String defaultLocale = 'pt_BR';
  static const String defaultCurrencySymbol = 'R\$';

  /// Ensures locale data is loaded for date formatting
  static Future<void> initialize([String locale = defaultLocale]) async {
    try {
      await initializeDateFormatting(locale, null);
    } catch (_) {
      // Ignore if already initialized or in test environment without locale assets
    }
  }

  /// Formats value given in integer cents (e.g. 1500 -> 'R$ 15,00')
  static String formatCurrency(num valueInCents, {String locale = defaultLocale, String symbol = defaultCurrencySymbol}) {
    final format = NumberFormat.currency(locale: locale, symbol: symbol);
    return format.format(valueInCents / 100.0);
  }

  /// Formats value given in microcents (1 cent = 10,000 microcents)
  static String formatCurrencyFromMicrocents(int microcents, {String locale = defaultLocale, String symbol = defaultCurrencySymbol}) {
    final format = NumberFormat.currency(locale: locale, symbol: symbol);
    return format.format(microcents / 1000000.0);
  }

  /// Formats date to 'dd/MM/yyyy'
  static String formatDate(DateTime date, {String? locale, String pattern = 'dd/MM/yyyy'}) {
    final targetLocale = locale ?? defaultLocale;
    try {
      return DateFormat(pattern, targetLocale).format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }

  /// Formats date and time to 'dd/MM/yyyy HH:mm'
  static String formatDateTime(DateTime date, {String? locale, String pattern = 'dd/MM/yyyy HH:mm'}) {
    final targetLocale = locale ?? defaultLocale;
    try {
      return DateFormat(pattern, targetLocale).format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }

  /// Formats integer or decimal numbers respecting locale separators
  static String formatNumber(num value, {String locale = defaultLocale, int decimalDigits = 0}) {
    final format = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimalDigits);
    return format.format(value);
  }

  /// Formats physical quantity with its unit (e.g. 5000 + 'G' -> '5.000 G')
  static String formatQuantity(num quantity, String unit, {String locale = defaultLocale}) {
    final formattedQty = formatNumber(quantity, locale: locale);
    return '$formattedQty $unit';
  }
}
