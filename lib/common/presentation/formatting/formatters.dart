import 'package:intl/intl.dart';

/// Locale aware formatting helpers used by presentation widgets.
abstract final class Formatters {
  static String dateTime(DateTime? value, String locale) {
    if (value == null) return '—';
    return DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());
  }

  static String date(DateTime? value, String locale) {
    if (value == null) return '—';
    return DateFormat.yMMMd(locale).format(value.toLocal());
  }

  static String time(DateTime? value, String locale) {
    if (value == null) return '—';
    return DateFormat.Hms(locale).format(value.toLocal());
  }

  /// Shows a parsed date when possible, otherwise the raw backend string.
  static String rawDateTime(String? raw, String locale) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : dateTime(parsed, locale);
  }

  static String rawDate(String? raw, String locale) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : date(parsed, locale);
  }

  static String number(num? value, String locale, {int maxDecimals = 2}) {
    if (value == null) return '—';
    final format = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = maxDecimals;
    return format.format(value);
  }

  /// "2–8 °C"; an open bound reads as "≤ 800 ppm" or "≥ 2 °C" instead of an infinity.
  static String range(double? min, double? max, String? unit, String locale) {
    final low = min == null ? null : number(min, locale);
    final high = max == null ? null : number(max, locale);
    final text = low == null ? '≤ $high' : (high == null ? '≥ $low' : '$low–$high');
    return '$text ${unit ?? ''}'.trim();
  }

  static String money(num? value, String? currency, String locale) {
    if (value == null) return '—';
    final code = (currency == null || currency.isEmpty) ? '' : currency.toUpperCase();
    return NumberFormat.currency(locale: locale, name: code, symbol: code.isEmpty ? '' : '$code ')
        .format(value);
  }

  /// `PENDING_PAYMENT` -> `Pending payment` (fallback for unknown enum values).
  static String humanize(String? value) {
    if (value == null || value.isEmpty) return '—';
    final lower = value.replaceAll('_', ' ').toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
