import 'package:flutter/material.dart';

import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/telemetry.dart';

extension MonitoredMetricPresentation on MonitoredMetric {
  String label(AppLocalizations l10n, {String? raw}) => switch (this) {
    MonitoredMetric.airQuality => l10n.metricAirQuality,
    MonitoredMetric.motion => l10n.metricMotion,
    MonitoredMetric.temperature => l10n.metricTemperature,
    MonitoredMetric.humidity => l10n.metricHumidity,
    MonitoredMetric.luminosity => l10n.metricLuminosity,
    MonitoredMetric.rfidTag => l10n.metricRfidTag,
    MonitoredMetric.unknown => raw ?? l10n.unknown,
  };

  IconData get icon => switch (this) {
    MonitoredMetric.airQuality => Icons.air_outlined,
    MonitoredMetric.motion => Icons.directions_walk_outlined,
    MonitoredMetric.temperature => Icons.thermostat_outlined,
    MonitoredMetric.humidity => Icons.water_drop_outlined,
    MonitoredMetric.luminosity => Icons.light_mode_outlined,
    MonitoredMetric.rfidTag => Icons.nfc_outlined,
    MonitoredMetric.unknown => Icons.sensors_outlined,
  };
}

extension EnvironmentalStatePresentation on EnvironmentalState {
  BadgeTone get tone => switch (this) {
    EnvironmentalState.normal => BadgeTone.success,
    EnvironmentalState.warning => BadgeTone.warning,
    EnvironmentalState.critical => BadgeTone.critical,
    EnvironmentalState.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    EnvironmentalState.normal => l10n.stateNormal,
    EnvironmentalState.warning => l10n.stateWarning,
    EnvironmentalState.critical => l10n.stateCritical,
    EnvironmentalState.unknown => l10n.notEvaluated,
  };
}

/// Localized name of an `ActuationAction` (e.g. `COOLING_ON`).
String actuationLabel(AppLocalizations l10n, String action) => switch (action) {
  'VENTILATION_ON' => l10n.actionVentilationOn,
  'VENTILATION_OFF' => l10n.actionVentilationOff,
  'COOLING_ON' => l10n.actionCoolingOn,
  'COOLING_OFF' => l10n.actionCoolingOff,
  'SERVO_OPEN' => l10n.actionServoOpen,
  'SERVO_CLOSE' => l10n.actionServoClose,
  _ => action,
};

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key, required this.connection});

  final DeviceConnection? connection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = connection;
    if (value == null || value.status == ConnectionStatus.unknown) {
      return StatusBadge(
        label: l10n.telemetryUnavailable,
        tone: BadgeTone.neutral,
        icon: Icons.sensors_off_outlined,
      );
    }
    return value.isConnected
        ? StatusBadge(label: l10n.connected, tone: BadgeTone.success, icon: Icons.wifi_rounded)
        : StatusBadge(label: l10n.requiresReview, tone: BadgeTone.warning, icon: Icons.wifi_off_rounded);
  }
}

class StateBadge extends StatelessWidget {
  const StateBadge({super.key, required this.state});

  final EnvironmentalState state;

  @override
  Widget build(BuildContext context) => StatusBadge(label: state.label(context.l10n), tone: state.tone);
}
