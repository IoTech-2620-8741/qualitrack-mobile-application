/// JSON model of the KPI dashboard (`KpiDashboardResource`).
library;

import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/kpi_entities.dart';
import '../../domain/entities/reporting_enums.dart';

/// A [KpiDashboard] read from the REST API.
class KpiDashboardModel extends KpiDashboard {
  const KpiDashboardModel({
    required super.laboratoryId,
    super.metrics,
    super.measurementSummaries,
    super.overallHealthScore,
    super.timestamp,
  });

  factory KpiDashboardModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) => json[key] == null ? const [] : Json.asList(json[key]);
    return KpiDashboardModel(
      laboratoryId: Json.requireInt(json, 'laboratoryId'),
      overallHealthScore: Json.optDouble(json, 'overallHealthScore'),
      timestamp: Json.optDateTime(json, 'timestamp'),
      metrics: [
        for (final m in list('metrics'))
          KpiMetric(
            id: Json.optInt(m, 'id'),
            name: Json.requireString(m, 'name'),
            value: Json.optDouble(m, 'value'),
            unit: Json.optString(m, 'unit'),
            targetValue: Json.optDouble(m, 'targetValue'),
            status: KpiMetricStatus.fromCode(Json.optString(m, 'status')),
            recordedAt: Json.optDateTime(m, 'recordedAt'),
          ),
      ],
      measurementSummaries: [
        for (final s in list('measurementSummaries'))
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
  }
}
