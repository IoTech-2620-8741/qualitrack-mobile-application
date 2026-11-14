import 'package:flutter/material.dart';

import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../compliance/api/index.dart';
import '../../../tracking/api/index.dart';
import 'range_bar.dart';

/// How far [value] lies outside [low]..[high] (a null side is open), or null inside.
({double amount, bool above})? outOfLimit(double? value, {double? low, double? high}) {
  if (value == null) return null;
  if (high != null && value > high) return (amount: value - high, above: true);
  if (low != null && value < low) return (amount: low - value, above: false);
  return null;
}

/// A reading with its unit ("38.6 °C"), or a dash without one.
String _reading(double? value, String? unit, String locale) =>
    value == null ? '—' : '${Formatters.number(value, locale)} ${unit ?? ''}'.trim();

/// The tone, the edge color and the name of a severity, as the Alerts tab shows
/// them (compliance keeps its presentation out of its API).
(BadgeTone, Color, String) _severity(AlertSeverity severity, AppLocalizations i18n) => switch (severity) {
  AlertSeverity.critical => (BadgeTone.critical, AppColors.criticalBase, i18n.severityCritical),
  AlertSeverity.warning => (BadgeTone.warning, AppColors.warningBase, i18n.severityWarning),
  AlertSeverity.low => (BadgeTone.info, AppColors.neutralContainer, i18n.severityLow),
  AlertSeverity.unknown => (BadgeTone.neutral, AppColors.neutralContainer, i18n.unknown),
};

/// An open alert on the dashboard, as the style guide's reading card: a 4 dp
/// edge in the color of its severity, the metric over its severity, area and
/// time, its value, and under them its limit and how far past it the value is.
/// With the normal range of the device's profile, the card draws the range and
/// the value on a bar and measures the value against the range instead.
class HomeAlertCard extends StatelessWidget {
  const HomeAlertCard({super.key, required this.alert, this.environmentName, this.threshold, required this.onTap});

  final DeviationAlert alert;
  final String? environmentName;

  /// The range of the alert's metric in its device's profile, when it was read.
  final MetricThreshold? threshold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final text = Theme.of(context).textTheme;
    final (tone, edge, severity) = _severity(alert.severity, i18n);
    final variable = alertVariable(i18n, alert.parameterName);
    final unit = alert.unit ?? threshold?.unit;
    final value = _reading(alert.recordedValue, unit, locale);
    final normalMin = threshold?.normalMin;
    final normalMax = threshold?.normalMax;
    final ranged = normalMin != null || normalMax != null;
    final limit =
        ranged
            ? i18n.normalRangeValue(Formatters.range(normalMin, normalMax, unit, locale))
            : alert.thresholdValue == null
            ? null
            : i18n.alertLimitValue(_reading(alert.thresholdValue, unit, locale));
    final out =
        ranged
            ? outOfLimit(alert.recordedValue, low: normalMin, high: normalMax)
            : outOfLimit(alert.recordedValue, low: alert.thresholdValue, high: alert.thresholdValue);
    final distance = switch (out) {
      null => null,
      (amount: final amount, above: true) => i18n.homeAboveLimit(_reading(amount, unit, locale)),
      (amount: final amount, above: false) => i18n.homeBelowLimit(_reading(amount, unit, locale)),
    };
    final when = relativeTime(context, alert.lastDetectedAt ?? alert.timestamp);
    final status = alert.status == AlertStatus.unresolved ? i18n.alertUnresolved : i18n.unknown;
    return Semantics(
      button: true,
      // One sentence, in the order the card is read.
      label: [
        severity,
        variable,
        value,
        if (limit != null) limit,
        if (distance != null) distance,
        if (environmentName != null) environmentName,
        status,
        when,
      ].join(', '),
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: edge, width: 4))),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
                        child: Icon(tone.icon, size: 20, color: tone.foreground),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variable,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              [severity, if (environmentName != null) environmentName, when].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        value,
                        style: text.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: tone.foreground,
                        ),
                      ),
                    ],
                  ),
                  if (ranged && alert.recordedValue != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    RangeBar(
                      normalMin: normalMin,
                      normalMax: normalMax,
                      value: alert.recordedValue!,
                      color: tone.foreground,
                    ),
                  ],
                  if (limit != null || distance != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    // The limit on the left, the distance on the right; on a
                    // narrow phone the distance drops to the next line.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpacing.sm,
                      children: [
                        if (limit != null) Text(limit, style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
                        if (distance != null)
                          Text(
                            distance,
                            style: text.bodySmall?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An acknowledged alert on the dashboard, in grey and one line where it fits:
/// someone is already on it, so it reads under the unresolved ones.
class HomeAcknowledgedAlertRow extends StatelessWidget {
  const HomeAcknowledgedAlertRow({super.key, required this.alert, required this.onTap});

  final DeviationAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final variable = alertVariable(i18n, alert.parameterName);
    final value = _reading(alert.recordedValue, alert.unit, context.localeName);
    final when = relativeTime(context, alert.lastDetectedAt ?? alert.timestamp);
    return Semantics(
      button: true,
      label: [variable, value, i18n.alertAcknowledged, when].join(', '),
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: AppColors.neutralContainer, shape: BoxShape.circle),
                    child: Icon(BadgeTone.neutral.icon, size: 16, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // The status and time drop under the metric when both do not fit.
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                          '$variable $value',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          '${i18n.alertAcknowledged} · $when',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
