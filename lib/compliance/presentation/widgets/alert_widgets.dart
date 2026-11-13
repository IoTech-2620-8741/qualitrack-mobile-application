import 'package:flutter/material.dart';

import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/deviation_alert.dart';

extension AlertStatusPresentation on AlertStatus {
  BadgeTone get tone => switch (this) {
    AlertStatus.unresolved => BadgeTone.critical,
    AlertStatus.acknowledged => BadgeTone.info,
    AlertStatus.resolved => BadgeTone.success,
    AlertStatus.unknown => BadgeTone.neutral,
  };

  IconData get icon => switch (this) {
    AlertStatus.unresolved => Icons.report_gmailerrorred_outlined,
    AlertStatus.acknowledged => Icons.visibility_outlined,
    AlertStatus.resolved => Icons.task_alt,
    AlertStatus.unknown => Icons.help_outline,
  };

  String label(AppLocalizations i18n) => switch (this) {
    AlertStatus.unresolved => i18n.alertUnresolved,
    AlertStatus.acknowledged => i18n.alertAcknowledged,
    AlertStatus.resolved => i18n.alertResolved,
    AlertStatus.unknown => i18n.unknown,
  };
}

extension AlertSeverityPresentation on AlertSeverity {
  BadgeTone get tone => switch (this) {
    AlertSeverity.low => BadgeTone.info,
    AlertSeverity.warning => BadgeTone.warning,
    AlertSeverity.critical => BadgeTone.critical,
    AlertSeverity.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations i18n) => switch (this) {
    AlertSeverity.low => i18n.severityLow,
    AlertSeverity.warning => i18n.severityWarning,
    AlertSeverity.critical => i18n.severityCritical,
    AlertSeverity.unknown => i18n.unknown,
  };
}

String formatAlertValue(double? value, String? unit, String locale) {
  if (value == null) return '—';
  return '${Formatters.number(value, locale)} ${unit ?? ''}'.trim();
}

/// An alert as a mobile list item: severity icon, variable and recorded value
/// on the first line, device · area below, then status and time.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.deviceName, this.environmentName, this.onTap});

  final DeviationAlert alert;
  final String? deviceName;
  final String? environmentName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final text = Theme.of(context).textTheme;
    final severity = alert.severity.tone;
    final where = [
      deviceName ?? i18n.equipmentNumber(alert.equipmentId),
      environmentName,
    ].whereType<String>().join(' · ');
    final at = alert.lastDetectedAt ?? alert.timestamp;
    // Elapsed time on the card ("5 min ago"); the exact moment in a tooltip.
    final when = relativeTime(context, at);
    // One label for screen readers, in the order the card is read visually.
    final semanticLabel = [
      alert.severity.label(i18n),
      alertVariable(i18n, alert.parameterName),
      formatAlertValue(alert.recordedValue, alert.unit, locale),
      where,
      alert.status.label(i18n),
      if (alert.deviationCount > 1) i18n.deviationsCount(alert.deviationCount),
      when,
    ].where((part) => part.isNotEmpty).join(', ');
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: severity.background, shape: BoxShape.circle),
                  child: Icon(severity.icon, size: 22, color: severity.foreground, semanticLabel: alert.severity.label(i18n)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              alertVariable(i18n, alert.parameterName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatAlertValue(alert.recordedValue, alert.unit, locale),
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: alert.isOpen ? severity.foreground : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(where, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      // Status on the left, time on the right; on narrow screens
                      // or long translations the time drops to the next line.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(
                                label: alert.status.label(i18n),
                                tone: alert.status.tone,
                                icon: alert.status.icon,
                              ),
                              if (alert.deviationCount > 1) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(Icons.repeat, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.xxs),
                                Text('${alert.deviationCount}', style: text.bodySmall),
                              ],
                            ],
                          ),
                          Tooltip(message: Formatters.dateTime(at, locale), child: Text(when, style: text.bodySmall)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null) const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.sm),
                  child: Icon(Icons.chevron_right, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
    ),
    );
  }
}
