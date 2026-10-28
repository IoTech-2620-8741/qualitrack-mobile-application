import '../../../shared/infrastructure/http/api_client.dart';
import '../../../shared/infrastructure/http/json_utils.dart';
import '../dtos/reporting_dtos.dart';

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

  Future<List<AuditLogEntryDto>> getEquipmentAuditLogs(int labId, int equipmentId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments/$equipmentId/audit-logs'))
          .map(AuditLogEntryDto.new).toList();

  Future<List<AuditLogEntryDto>> getBatchAuditLogs(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/audit-logs')).map(AuditLogEntryDto.new).toList();
}