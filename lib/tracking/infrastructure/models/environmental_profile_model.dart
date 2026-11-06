import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/actuation_rule.dart';
import '../../domain/entities/environmental_profile.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/metric_threshold.dart';
import '../../domain/entities/monitored_metric.dart';

/// `EnvironmentalProfileResource {version, thresholds[], actuationRules[], updatedAt}`.
class EnvironmentalProfileModel extends EnvironmentalProfile {
  const EnvironmentalProfileModel({required super.version, super.thresholds, super.actuationRules, super.updatedAt});

  factory EnvironmentalProfileModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) => json[key] == null ? const [] : Json.asList(json[key]);
    return EnvironmentalProfileModel(
      version: Json.requireInt(json, 'version'),
      updatedAt: Json.optDateTime(json, 'updatedAt'),
      thresholds: [
        for (final item in list('thresholds'))
          MetricThreshold(
            metric: MonitoredMetric.fromCode(Json.optString(item, 'metric')),
            unit: Json.optString(item, 'unit'),
            normalMin: Json.optDouble(item, 'normalMin'),
            normalMax: Json.optDouble(item, 'normalMax'),
            criticalMin: Json.optDouble(item, 'criticalMin'),
            criticalMax: Json.optDouble(item, 'criticalMax'),
          ),
      ],
      actuationRules: [
        for (final item in list('actuationRules'))
          ActuationRule(
            metric: MonitoredMetric.fromCode(Json.optString(item, 'metric')),
            state: EnvironmentalState.fromCode(Json.optString(item, 'state')),
            action: Json.requireString(item, 'action'),
          ),
      ],
    );
  }
}
