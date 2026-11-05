/// This file contains the Remote Data Source for the Reporting context.
///
/// It is responsible for making HTTP requests to the backend API
/// and returning raw DTOs.
///
import '../../../shared/infrastructure/http/api_client.dart';
import '../../../shared/infrastructure/http/json_utils.dart';
import '../dtos/reporting_dtos.dart';

/// Data Source for fetching reporting data from a remote server (REST API).
class ReportingRemoteDataSource {
  const ReportingRemoteDataSource(this._client);

  final ApiClient _client;

  /// Fetches the KPI Dashboard from the API.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/kpi-dashboards`
  Future<KpiDashboardDto> getKpiDashboard(
      int labId, {
        required String from,
        required String to,
        int? environmentId,
      }) async {
    final queryParams = <String, dynamic>{
      'from': from,
      'to': to,
    };

    if (environmentId != null) {
      queryParams['environmentId'] = environmentId;
    }

    return KpiDashboardDto(Json.asMap(await _client.get(
      '/laboratories/$labId/kpi-dashboards',
      query: queryParams,
    )));
  }

  /// Fetches the history of generated reports for a laboratory.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/reports`
  Future<List<AuditReportDto>> getLaboratoryReports(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/reports'))
          .map(AuditReportDto.new)
          .toList();

  /// Fetches the deviation trends for a specific environment.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/environments/{environmentId}/deviation-trends`
  Future<List<DeviationTrendDto>> getTrends(
      int labId,
      int environmentId, {
        required String from,
        required String to,
      }) async =>
      Json.asList(await _client.get(
        '/laboratories/$labId/environments/$environmentId/deviation-trends',
        query: {'from': from, 'to': to},
      )).map(DeviationTrendDto.new).toList();

  /// Fetches the audit logs for a specific equipment.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/equipments/{equipmentId}/audit-logs`
  Future<List<AuditLogEntryDto>> getEquipmentAuditLogs(int labId, int equipmentId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments/$equipmentId/audit-logs'))
          .map(AuditLogEntryDto.new)
          .toList();

  /// Fetches the audit logs for a specific batch.
  ///
  /// **Endpoint:** `GET /batches/{batchId}/audit-logs`
  Future<List<AuditLogEntryDto>> getBatchAuditLogs(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/audit-logs'))
          .map(AuditLogEntryDto.new)
          .toList();
}