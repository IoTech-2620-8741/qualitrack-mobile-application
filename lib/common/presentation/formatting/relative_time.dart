import 'package:flutter/widgets.dart';

import '../i18n/app_localizations.dart';
import 'context_locale.dart';
import 'formatters.dart';

/// "Just now", "5 min ago", "3 h ago" for the last 24 hours, the date and
/// time after that. Answers "is this current?" at a glance; the exact moment
/// is still one long press away where it is shown in a tooltip.
String relativeTime(BuildContext context, DateTime? value, {DateTime? now}) {
  if (value == null) return '—';
  final i18n = context.i18n;
  final elapsed = (now ?? DateTime.now()).difference(value);
  // A clock slightly ahead on the device reads as "just now", not negative.
  if (elapsed.inMinutes < 1) return i18n.timeJustNow;
  if (elapsed.inHours < 1) return i18n.timeMinutesAgo(elapsed.inMinutes);
  if (elapsed.inHours < 24) return i18n.timeHoursAgo(elapsed.inHours);
  return Formatters.dateTime(value, context.localeName);
}
