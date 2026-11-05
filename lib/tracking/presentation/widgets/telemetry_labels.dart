import 'package:flutter/material.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/telemetry.dart';

extension MonitoredMetricPresentation on MonitoredMetric {
  String label(AppLocalizations i18n, {String? raw}) => metricLabel(i18n, code, raw: raw);

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

  String label(AppLocalizations i18n) => switch (this) {
    EnvironmentalState.normal => i18n.stateNormal,
    EnvironmentalState.warning => i18n.stateWarning,
    EnvironmentalState.critical => i18n.stateCritical,
    EnvironmentalState.unknown => i18n.notEvaluated,
  };
}

class StateBadge extends StatelessWidget {
  const StateBadge({super.key, required this.state});

  final EnvironmentalState state;

  @override
  Widget build(BuildContext context) => StatusBadge(label: state.label(context.i18n), tone: state.tone);
}
