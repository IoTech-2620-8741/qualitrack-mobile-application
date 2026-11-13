import 'package:flutter/widgets.dart';

import '../i18n/app_localizations.dart';
import 'context_locale.dart';
import 'formatters.dart';

/// How long ago [value] was, in the buckets the app shows: under a minute,
/// minutes, hours, or older than a day (null).
({int? minutes, int? hours})? _elapsed(DateTime value, DateTime now) {
  final elapsed = now.difference(value);
  // A clock slightly ahead on the device reads as "just now", not negative.
  if (elapsed.inMinutes < 1) return (minutes: null, hours: null);
  if (elapsed.inHours < 1) return (minutes: elapsed.inMinutes, hours: null);
  if (elapsed.inHours < 24) return (minutes: null, hours: elapsed.inHours);
  return null;
}

/// "Just now", "5 min ago", "3 h ago" for the last 24 hours, the date and
/// time after that. Answers "is this current?" at a glance; the exact moment
/// is still one long press away where it is shown in a tooltip.
String relativeTime(BuildContext context, DateTime? value, {DateTime? now}) {
  if (value == null) return '—';
  final i18n = context.i18n;
  return switch (_elapsed(value, now ?? DateTime.now())) {
    null => Formatters.dateTime(value, context.localeName),
    (minutes: final int m, hours: _) => i18n.timeMinutesAgo(m),
    (minutes: _, hours: final int h) => i18n.timeHoursAgo(h),
    _ => i18n.timeJustNow,
  };
}

/// "Updated 5 min ago": when the data on screen was loaded.
String updatedText(BuildContext context, DateTime value, {DateTime? now}) {
  final i18n = context.i18n;
  return switch (_elapsed(value, now ?? DateTime.now())) {
    null => i18n.updatedOn(Formatters.dateTime(value, context.localeName)),
    (minutes: final int m, hours: _) => i18n.updatedMinutesAgo(m),
    (minutes: _, hours: final int h) => i18n.updatedHoursAgo(h),
    _ => i18n.updatedJustNow,
  };
}
