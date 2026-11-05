/// This file contains the Data Transfer Objects (DTOs) for KPI data.
/// DTOs are responsible for mapping raw JSON data from the API
/// into domain entities.
///

import '../../../../shared/infrastructure/http/json_utils.dart';
import '../../domain/entities/kpi_entities.dart';
import '../../domain/entities/reporting_enums.dart';

/// DTO for the KPI Dashboard response.
class KpiDashboardDto {
  const KpiDashboardDto(this.json);

  final Map<String, dynamic> json;

  /// Converts the raw JSON map into a [KpiDashboard] domain entity.
  KpiDashboard toDomain() => KpiDashboard(
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    overallHealthScore: Json.optDouble(json, 'overallHealthScore'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    metrics: [for (final m in _list('metrics')) _metric(m)],
    measurementSummaries: [
      for (final s in _list('measurementSummaries'))
        MeasurementSummary(
          environmentId: Json.requireInt(s, 'environmentId'),
          deviceId: Json.requireInt(s, 'deviceId'),
          metric: Json.requireString(s, 'metric'),
          unit: Json.optString(s, 'unit'),
          readings: Json.optInt(s, 'readings') ?? 0,
          average: Json.optDouble(s, 'average'),
          minimum: Json.optDouble(s, 'minimum'),
          maximum: Json.optDouble(s, 'maximum'),
          lastMeasuredAt: Json.optDateTime(s, 'lastMeasuredAt'),
        ),
    ],
  );

  /// Helper method to safely extract a list of maps from the JSON.
  List<Map<String, dynamic>> _list(String key) =>
      json[key] == null ? const [] : Json.asList(json[key]);

  /// Helper method to map a single KpiMetric.
  static KpiMetric _metric(Map<String, dynamic> m) => KpiMetric(
    id: Json.optInt(m, 'id'),
    name: Json.requireString(m, 'name'),
    value: Json.optDouble(m, 'value'),
    unit: Json.optString(m, 'unit'),
    targetValue: Json.optDouble(m, 'targetValue'),
    status: KpiMetricStatus.fromCode(Json.optString(m, 'status')),
    recordedAt: Json.optDateTime(m, 'recordedAt'),
  );
}