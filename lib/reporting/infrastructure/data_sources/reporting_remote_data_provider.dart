/// This file contains the Remote Data Provider for the Reporting context.
///
/// It is responsible for making HTTP requests to the backend API
/// and returning the models.
///
library;

import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/audit_log_entry_model.dart';
import '../models/audit_report_model.dart';
import '../models/deviation_trend_model.dart';
import '../models/kpi_dashboard_model.dart';

/// Data provider for fetching reporting data from a remote server (REST API).
class ReportingRemoteDataProvider {
  const ReportingRemoteDataProvider(this._client);

  final ApiClient _client;

  /// Fetches the KPI Dashboard from the API.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/kpi-dashboards`
  Future<KpiDashboardModel> getKpiDashboard(
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

    return KpiDashboardModel.fromJson(Json.asMap(await _client.get(
      '/laboratories/$labId/kpi-dashboards',
      query: queryParams,
    )));
  }

  /// Fetches the history of generated reports for a laboratory.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/reports`
  Future<List<AuditReportModel>> getLaboratoryReports(int labId) async =>
      Json.asList(await _client.get('/laboratories/$labId/reports'))
          .map(AuditReportModel.fromJson)
          .toList();

  /// Fetches the deviation trends for a specific environment.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/environments/{environmentId}/deviation-trends`
  Future<List<DeviationTrendModel>> getTrends(
      int labId,
      int environmentId, {
        required String from,
        required String to,
      }) async =>
      Json.asList(await _client.get(
        '/laboratories/$labId/environments/$environmentId/deviation-trends',
        query: {'from': from, 'to': to},
      )).map(DeviationTrendModel.fromJson).toList();

  /// Fetches the audit logs for a specific equipment.
  ///
  /// **Endpoint:** `GET /laboratories/{labId}/equipments/{equipmentId}/audit-logs`
  Future<List<AuditLogEntryModel>> getEquipmentAuditLogs(int labId, int equipmentId) async =>
      Json.asList(await _client.get('/laboratories/$labId/equipments/$equipmentId/audit-logs'))
          .map(AuditLogEntryModel.fromJson)
          .toList();

  /// Fetches the audit logs for a specific batch.
  ///
  /// **Endpoint:** `GET /batches/{batchId}/audit-logs`
  Future<List<AuditLogEntryModel>> getBatchAuditLogs(int batchId) async =>
      Json.asList(await _client.get('/batches/$batchId/audit-logs'))
          .map(AuditLogEntryModel.fromJson)
          .toList();
}