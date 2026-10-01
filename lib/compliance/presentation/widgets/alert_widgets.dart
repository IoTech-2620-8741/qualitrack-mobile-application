import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/compliance.dart';

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

  String label(AppLocalizations l10n) => switch (this) {
    AlertStatus.unresolved => l10n.alertUnresolved,
    AlertStatus.acknowledged => l10n.alertAcknowledged,
    AlertStatus.resolved => l10n.alertResolved,
    AlertStatus.unknown => l10n.unknown,
  };
}

extension AlertSeverityPresentation on AlertSeverity {
  BadgeTone get tone => switch (this) {
    AlertSeverity.low => BadgeTone.info,
    AlertSeverity.warning => BadgeTone.warning,
    AlertSeverity.critical => BadgeTone.critical,
    AlertSeverity.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AlertSeverity.low => l10n.severityLow,
    AlertSeverity.warning => l10n.severityWarning,
    AlertSeverity.critical => l10n.severityCritical,
    AlertSeverity.unknown => l10n.unknown,
  };
}

String formatAlertValue(double? value, String? unit, String locale) {
  if (value == null) return '—';
  return '${Formatters.number(value, locale)} ${unit ?? ''}'.trim();
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.equipmentName, this.onTap});

  final DeviationAlert alert;
  final String? equipmentName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                        Text(l10n.parameter.toUpperCase(), style: AppTypography.overline),
                        Text(alert.parameterName, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  StatusBadge(label: alert.severity.label(l10n), tone: alert.severity.tone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge(
                    label: alert.status.label(l10n),
                    tone: alert.status.tone,
                    icon: alert.status.icon,
                  ),
                  StatusBadge(
                    label: equipmentName ?? l10n.equipmentNumber(alert.equipmentId),
                    tone: BadgeTone.neutral,
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                  if (alert.batchId != null)
                    StatusBadge(
                      label: l10n.batchNumberShort(alert.batchId!),
                      tone: BadgeTone.neutral,
                      icon: Icons.inventory_2_outlined,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      alert.timestamp != null
                          ? Formatters.dateTime(alert.timestamp, locale)
                          : (alert.rawTimestamp ?? '—'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.recordedValue, style: theme.textTheme.bodySmall),
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
