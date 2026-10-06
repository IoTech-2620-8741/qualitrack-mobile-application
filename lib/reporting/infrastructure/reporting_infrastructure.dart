import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/reporting.dart';

/// `KpiDashboardResource {laboratoryId, timestamp, overallHealthScore, from, to,
/// metrics[], measurementSummaries[]}`.
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

/// `DeviationTrendResource {parameterName, equipmentId, environmentId, unit,
/// trendDirection, evaluatedReadings, timeInRangePercent, deviationCount,
/// criticalDeviationCount, dataPoints}`.
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

class ReportingRemoteDataSource {
  const ReportingRemoteDataSource(this._client);

  final ApiClient _client;

  Future<KpiDashboardDto> getKpiDashboard(int labId, {required String from, required String to, int? environmentId}) async =>
      KpiDashboardDto(Json.asMap(await _client.get(
        '/laboratories/$labId/kpi-dashboards',
        query: {'from': from, 'to': to, 'environmentId': environmentId},
      )));

  Future<List<AuditReportDto>> getLaboratoryReports(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/reports')).map(AuditReportDto.new).toList();

  Future<List<DeviationTrendDto>> getTrends(int labId, int environmentId, {required String from, required String to}) async =>
      Json.asList(await _client.get(
        '/laboratories/$labId/environments/$environmentId/deviation-trends',
        query: {'from': from, 'to': to},
      )).map(DeviationTrendDto.new).toList();

  Future<List<AuditLogEntryDto>> getEquipmentAuditLogs(int labId, int equipmentId) async => Json.asList(
    await _client.get('/laboratories/$labId/equipments/$equipmentId/audit-logs'),
  ).map(AuditLogEntryDto.new).toList();

  Future<List<AuditLogEntryDto>> getBatchAuditLogs(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/audit-logs')).map(AuditLogEntryDto.new).toList();
}

class ReportingRepositoryImpl implements ReportingRepository {
  const ReportingRepositoryImpl(this._remote);

  final ReportingRemoteDataSource _remote;

  @override
  Future<KpiDashboard> getKpiDashboard(
    LaboratoryId laboratoryId, {
    required DateTime from,
    required DateTime to,
    int? environmentId,
  }) async => (await _remote.getKpiDashboard(
    laboratoryId.value,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
    environmentId: environmentId,
  )).toDomain();

  @override
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId) async =>
      (await _remote.getLaboratoryReports(laboratoryId.value)).map((d) => d.toDomain()).toList();

  @override
  Future<List<DeviationTrend>> getDeviationTrends(
    LaboratoryId laboratoryId,
    int environmentId, {
    required DateTime from,
    required DateTime to,
  }) async => (await _remote.getTrends(
    laboratoryId.value,
    environmentId,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
  )).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) async =>
      (await _remote.getEquipmentAuditLogs(laboratoryId.value, equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) async =>
      (await _remote.getBatchAuditLogs(batchId)).map((d) => d.toDomain()).toList();
}
