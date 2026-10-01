import 'package:flutter/material.dart';

import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/telemetry.dart';

extension TelemetryStatusPresentation on TelemetryStatus {
  BadgeTone get tone => switch (this) {
    TelemetryStatus.operational => BadgeTone.success,
    TelemetryStatus.warning => BadgeTone.warning,
    TelemetryStatus.critical => BadgeTone.critical,
    TelemetryStatus.offline => BadgeTone.neutral,
    TelemetryStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    TelemetryStatus.operational => l10n.telemetryOperational,
    TelemetryStatus.warning => l10n.telemetryWarning,
    TelemetryStatus.critical => l10n.telemetryCritical,
    TelemetryStatus.offline => l10n.telemetryOffline,
    TelemetryStatus.unknown => l10n.unknown,
  };
}

class TelemetryStatusBadge extends StatelessWidget {
  const TelemetryStatusBadge({super.key, required this.status});

  final EquipmentTelemetryStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = status;
    if (value == null) {
      return StatusBadge(
        label: l10n.telemetryUnavailable,
        tone: BadgeTone.neutral,
        icon: Icons.sensors_off_outlined,
      );
    }
    return StatusBadge(label: value.currentStatus.label(l10n), tone: value.currentStatus.tone);
  }
}

class OnlineBadge extends StatelessWidget {
  const OnlineBadge({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatusBadge(
      label: online ? l10n.online : l10n.offline,
      tone: online ? BadgeTone.success : BadgeTone.neutral,
      icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
    );
  }
}

/// Icon used for a telemetry parameter card; falls back to a generic sensor.
IconData parameterIcon(String parameter) {
  final p = parameter.toLowerCase();
  if (p.contains('temp')) return Icons.thermostat_outlined;
  if (p.contains('hum')) return Icons.water_drop_outlined;
  if (p.contains('air') || p.contains('aire') || p.contains('co2') || p.contains('aqi')) {
    return Icons.air_outlined;
  }
  if (p.contains('press')) return Icons.speed_outlined;
  if (p.contains('volt')) return Icons.bolt_outlined;
  if (p.contains('rpm')) return Icons.rotate_right_outlined;
  return Icons.sensors_outlined;
}
