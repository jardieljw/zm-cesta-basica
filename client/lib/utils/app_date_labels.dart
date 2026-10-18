import 'package:flutter/widgets.dart';
import '../l10n/l10n_extension.dart';
import 'formatters.dart';

/// Human-readable civil ranges shared by the overview and financial lists.
String appDateRange(BuildContext context, DateTime start, DateTime end) {
  String full(DateTime day, {bool year = false}) => AppFormatters.formatDate(
    day,
    pattern: year ? "d 'de' MMMM 'de' yyyy" : "d 'de' MMMM",
  );
  if (start == end) return full(start);
  if (start.year == end.year && start.month == end.month) {
    return context.l10n.appRangeSameMonth(
      start.day.toString(),
      end.day.toString(),
      AppFormatters.formatDate(start, pattern: 'MMMM'),
    );
  }
  return context.l10n.appRangeDifferentMonth(
    full(start, year: start.year != end.year),
    full(end, year: start.year != end.year),
  );
}
