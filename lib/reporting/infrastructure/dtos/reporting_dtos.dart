import '../../../../shared/infrastructure/http/json_utils.dart';
import '../../domain/entities/reporting_entities.dart';

class KpiDashboardDto {
  const KpiDashboardDto(this.json);
  final Map<String, dynamic> json;

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

  List<Map<String, dynamic>> _list(String key) => json[key] == null ? const [] : Json.asList(json[key]);

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

class AuditReportDto {
  const AuditReportDto(this.json);
  final Map<String, dynamic> json;

  AuditReport toDomain() => AuditReport(
    id: Json.requireInt(json, 'id'),
    reportType: Json.optString(json, 'reportType') ?? 'UNKNOWN',
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    batchId: Json.optInt(json, 'batchId'),
    equipmentId: Json.optInt(json, 'equipmentId'),
    generatedByName: Json.optString(json, 'generatedByName'),
    dateRangeFrom: Json.optString(json, 'dateRangeFrom'),
    dateRangeTo: Json.optString(json, 'dateRangeTo'),
    generatedAt: Json.optDateTime(json, 'generatedAt'),
    checksum: Json.optString(json, 'checksum'),
  );
}

class DeviationTrendDto {
  const DeviationTrendDto(this.json);
  final Map<String, dynamic> json;

  DeviationTrend toDomain() => DeviationTrend(
    parameterName: Json.requireString(json, 'parameterName'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    environmentId: Json.optInt(json, 'environmentId'),
    unit: Json.optString(json, 'unit'),
    direction: TrendDirection.fromCode(Json.optString(json, 'trendDirection')),
    evaluatedReadings: Json.optInt(json, 'evaluatedReadings') ?? 0,
    timeInRangePercent: Json.optDouble(json, 'timeInRangePercent'),
    deviationCount: Json.optInt(json, 'deviationCount') ?? 0,
    criticalDeviationCount: Json.optInt(json, 'criticalDeviationCount') ?? 0,
  );
}

class AuditLogEntryDto {
  const AuditLogEntryDto(this.json);
  final Map<String, dynamic> json;

  AuditLogEntry toDomain() => AuditLogEntry(
    id: Json.requireInt(json, 'id'),
    action: Json.optString(json, 'action') ?? 'UNKNOWN',
    entityType: Json.optString(json, 'entityType'),
    entityId: Json.optInt(json, 'entityId'),
    performedBy: Json.optInt(json, 'performedBy'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    details: Json.optString(json, 'details'),
  );
}