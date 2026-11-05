/// This file exposes the public API (Entry Point) for the Reporting Bounded Context.
///
/// Other modules in the application (such as [Equipment] or [Batch]) should
/// interact with this context by importing only this file, avoiding coupling
/// to the infrastructure or internal domain logic.
///
library;

import '../../common/domain/value_objects.dart';
import '../application/reporting_queries.dart';
import '../domain/entities/audit_entities.dart';

/// Public API for the Reporting context.
///
/// It groups the use cases (queries) that are relevant to external modules.
class ReportingApi {
  const ReportingApi({
    required this.getKpiDashboard,
    required this.getDeviationTrends,
    required this.getReportHistory,
    required this.getEquipmentAuditLogs,
    required this.getBatchAuditLogs,
  });

  final GetKpiDashboard getKpiDashboard;
  final GetDeviationTrends getDeviationTrends;
  final GetReportHistory getReportHistory;
  final GetEquipmentAuditLogs getEquipmentAuditLogs;
  final GetBatchAuditLogs getBatchAuditLogs;

  /// Retrieves the audit logs for a specific equipment.
  ///
  /// Useful if the Equipment module needs to display this data in its detail screen.
  ///
  /// @param labId The laboratory identifier.
  /// @param equipmentId The equipment identifier.
  /// @return A [Future] containing a list of [AuditLogEntry].
  Future<List<AuditLogEntry>> fetchEquipmentAuditLogs(LaboratoryId labId, int equipmentId) {
    return getEquipmentAuditLogs(labId, equipmentId);
  }

  /// Retrieves the audit logs for a specific batch.
  ///
  /// Useful for the Batch module.
  ///
  /// @param batchId The batch identifier.
  /// @return A [Future] containing a list of [AuditLogEntry].
  Future<List<AuditLogEntry>> fetchBatchAuditLogs(int batchId) {
    return getBatchAuditLogs(batchId);
  }

  /// Retrieves the history of generated reports.
  ///
  /// @param labId The laboratory identifier.
  /// @return A [Future] containing a list of [AuditReport].
  Future<List<AuditReport>> fetchReportHistory(LaboratoryId labId) {
    return getReportHistory(labId);
  }
}