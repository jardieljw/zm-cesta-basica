/// Parse Brazilian currency without floating point or silently rounding decimals.
class MoneyInput {
  static int? cents(String value) {
    final text = value.trim().replaceFirst(RegExp(r'^R\$\s*'), '');
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$').hasMatch(text)) {
      return null;
    }
    final parts = text.replaceAll('.', '').split(',');
    final amount =
        BigInt.parse(parts[0]) * BigInt.from(100) +
        BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
    return amount <= BigInt.parse('9223372036854775807')
        ? amount.toInt()
        : null;
  }
}
