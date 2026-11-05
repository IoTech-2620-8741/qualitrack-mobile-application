import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/monitored_metric.dart';

/// `MeasurementResource {id, deviceId, environmentId, metric, value, textValue,
/// unit, measuredAt, state, thresholdValue, profileVersion}`.
class MeasurementModel extends Measurement {
  const MeasurementModel({
    required super.id,
    required super.deviceId,
    required super.environmentId,
    required super.metric,
    required super.rawMetric,
    required super.state,
    super.value,
    super.textValue,
    super.unit,
    super.measuredAt,
    super.thresholdValue,
    super.profileVersion,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    final metric = Json.requireString(json, 'metric');
    return MeasurementModel(
      id: Json.requireInt(json, 'id'),
      deviceId: Json.requireInt(json, 'deviceId'),
      environmentId: Json.requireInt(json, 'environmentId'),
      metric: MonitoredMetric.fromCode(metric),
      rawMetric: metric,
      value: Json.optDouble(json, 'value'),
      textValue: Json.optString(json, 'textValue'),
      unit: Json.optString(json, 'unit'),
      measuredAt: Json.optDateTime(json, 'measuredAt'),
      state: EnvironmentalState.fromCode(Json.optString(json, 'state')),
      thresholdValue: Json.optDouble(json, 'thresholdValue'),
      profileVersion: Json.optInt(json, 'profileVersion'),
    );
  }
}
