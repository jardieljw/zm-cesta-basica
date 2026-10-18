/// Current company day convention, shared with the server: UTC minus three.
/// Civil dates are not converted through the device's timezone.
class BusinessDates {
  static DateTime today([DateTime? now]) =>
      dayOf((now ?? DateTime.now()).toUtc());
  static DateTime dayOf(DateTime instant) {
    final business = instant.toUtc().subtract(const Duration(hours: 3));
    return DateTime(business.year, business.month, business.day);
  }

  static String iso(DateTime day) => DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).toIso8601String().split('T').first;
  static DateTime parse(String day) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw const FormatException('Invalid civil date');
    }
    final value = DateTime.parse(day);
    if (iso(value) != day || value.year < 1900) {
      throw const FormatException('Invalid civil date');
    }
    return value;
  }
}
