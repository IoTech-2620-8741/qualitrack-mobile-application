import '../../common/domain/value_objects.dart';
import '../../tracking/api/index.dart';
import '../domain/entities/alert_origin.dart';
import '../domain/entities/deviation_alert.dart';

/// The range of the metric of each alert in the profile its device applies, by
/// alert id, to draw the recorded value against it. Each device's profile is
/// read once. Alerts without an environment are absent, and so are the ones
/// whose device has no profile, no range for the metric or a profile that
/// cannot be read.
Future<Map<int, MetricThreshold>> loadAlertThresholds(
  TelemetryApi telemetryApi,
  LaboratoryId laboratoryId,
  List<DeviationAlert> alerts,
) async {
  final located = alerts.where((a) => a.environmentId != null).toList();
  final targets = {
    for (final alert in located)
      TelemetryTarget(
        deviceId: alert.equipmentId,
        environmentId: alert.environmentId!,
        containerMonitor: alert.origin == AlertOrigin.container,
      ),
  };
  final profiles = await telemetryApi.getProfiles(laboratoryId, targets.toList());
  return {
    for (final alert in located)
      if (profiles[alert.equipmentId]?.thresholdFor(MonitoredMetric.fromCode(alert.parameterName)) case final range?)
        alert.id: range,
  };
}
