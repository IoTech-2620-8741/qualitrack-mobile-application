/// This file contains the Use Cases (Queries) for the Reporting context.
///
/// Queries orchestrate calls to the repository and apply the necessary
/// domain logic (such as sorting or date calculation) before returning the data.
///

import '../../shared/application/bounded_concurrency.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/entities/audit_entities.dart';
import '../domain/entities/deviation_entities.dart';
import '../domain/entities/kpi_entities.dart';
import '../domain/entities/reporting_enums.dart';
import '../domain/logic/reporting_logic.dart';
import '../domain/repositories/reporting_repository.dart';

/// Use case to retrieve the KPI Dashboard for a specific laboratory.
class GetKpiDashboard {
  const GetKpiDashboard(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ReportingRepository _repository;
  final DateTime Function() _clock;

  /// Executes the use case, calculating the exact dates based on the [period].
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param period The time period (24h, 7d, 31d).
  /// @param environmentId (Optional) Filter by a specific environment.
  /// @return A [Future] containing the [KpiDashboard].
  Future<KpiDashboard> call(LaboratoryId laboratoryId, ReportPeriod period, {int? environmentId}) {
    final to = _clock();
    return _repository.getKpiDashboard(
      laboratoryId,
      from: to.subtract(period.duration),
      to: to,
      environmentId: environmentId,
    );
  }
}

/// Use case to retrieve the history of generated reports.
class GetReportHistory {
  const GetReportHistory(this._repository);

  final ReportingRepository _repository;

  /// Fetches the reports and sorts them from newest to oldest.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @return A [Future] containing a sorted list of [AuditReport].
  Future<List<AuditReport>> call(LaboratoryId laboratoryId) async {
    final reports = await _repository.getLaboratoryReports(laboratoryId);
    return sortReportsNewestFirst(reports);
  }
}

/// Use case to retrieve deviation trends for multiple environments.
class GetDeviationTrends {
  const GetDeviationTrends(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ReportingRepository _repository;
  final DateTime Function() _clock;

  /// Fetches trends for the given environments concurrently and
  /// sorts them by severity.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param environmentIds List of environment IDs to query.
  /// @param period The time period to query.
  /// @return A [Future] containing a sorted list of [DeviationTrend].
  Future<List<DeviationTrend>> call(LaboratoryId laboratoryId, Iterable<int> environmentIds, ReportPeriod period) async {
    final to = _clock();
    final from = to.subtract(period.duration);
    final trends = await loadAll(
        environmentIds, (environmentId) => _repository.getDeviationTrends(laboratoryId, environmentId, from: from, to: to)
    );
    return sortTrendsBySeverity(trends);
  }
}

/// Use case to retrieve the audit log for a specific equipment.
class GetEquipmentAuditLogs {
  const GetEquipmentAuditLogs(this._repository);

  final ReportingRepository _repository;

  /// Fetches the logs and sorts them from newest to oldest.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param equipmentId The equipment identifier.
  /// @return A [Future] containing a sorted list of [AuditLogEntry].
  Future<List<AuditLogEntry>> call(LaboratoryId laboratoryId, int equipmentId) async =>
      sortAuditLogsNewestFirst(await _repository.getEquipmentAuditLogs(laboratoryId, equipmentId));
}

/// Use case to retrieve the audit log for a specific batch.
class GetBatchAuditLogs {
  const GetBatchAuditLogs(this._repository);

  final ReportingRepository _repository;

  /// Fetches the logs and sorts them from newest to oldest.
  ///
  /// @param batchId The batch identifier.
  /// @return A [Future] containing a sorted list of [AuditLogEntry].
  Future<List<AuditLogEntry>> call(int batchId) async =>
      sortAuditLogsNewestFirst(await _repository.getBatchAuditLogs(batchId));
}