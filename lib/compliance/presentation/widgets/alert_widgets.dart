import 'package:flutter/material.dart';

import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/alert_origin.dart';
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
    final theme = Theme.of(context);
    final highlight = alert.isOpen && alert.isCritical;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: highlight ? AppColors.criticalContainer.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: highlight ? AppColors.critical.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i18n.parameter.toUpperCase(), style: AppTypography.overline),
                        Text(alertVariable(i18n, alert.parameterName), style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  StatusBadge(label: alert.severity.label(i18n), tone: alert.severity.tone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge(
                    label: alert.status.label(i18n),
                    tone: alert.status.tone,
                    icon: alert.status.icon,
                  ),
                  if (environmentName != null)
                    StatusBadge(label: environmentName!, tone: BadgeTone.neutral, icon: Icons.meeting_room_outlined),
                  StatusBadge(
                    label: deviceName ?? i18n.equipmentNumber(alert.equipmentId),
                    tone: BadgeTone.neutral,
                    icon: alert.origin == AlertOrigin.container ? Icons.kitchen_outlined : Icons.sensors_outlined,
                  ),
                  if (alert.deviationCount > 1)
                    StatusBadge(
                      label: i18n.deviationsCount(alert.deviationCount),
                      tone: BadgeTone.neutral,
                      icon: Icons.repeat,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      Formatters.dateTime(alert.lastDetectedAt ?? alert.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(i18n.recordedValue, style: theme.textTheme.bodySmall),
                      Text(
                        formatAlertValue(alert.recordedValue, alert.unit, locale),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: alert.isOpen ? AppColors.critical : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
