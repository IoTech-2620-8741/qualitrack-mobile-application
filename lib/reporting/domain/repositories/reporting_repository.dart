/// This file defines the contract (Interface) for the Reporting Repository.
///
/// The infrastructure layer is the only one responsible for implementing
/// this interface (e.g., by calling a REST API or a local database).
///
library;

import '../../../common/domain/value_objects.dart';
import '../entities/audit_entities.dart';
import '../entities/deviation_entities.dart';
import '../entities/kpi_entities.dart';

/// Repository contract for the Reporting context.
///
/// Defines the allowed operations to fetch audit and KPI data.
///
/// @see [KpiDashboard]
/// @see [AuditReport]
abstract interface class ReportingRepository {
  /// Retrieves the KPI Dashboard for a laboratory within a date range.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param from The start date of the period to query.
  /// @param to The end date of the period to query.
  /// @param environmentId (Optional) Filter by a specific environment.
  /// @return A [Future] containing the calculated [KpiDashboard].
  Future<KpiDashboard> getKpiDashboard(
      LaboratoryId laboratoryId, {
        required DateTime from,
        required DateTime to,
        int? environmentId,
      });

  /// Retrieves the history of generated reports for a laboratory.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @return A [Future] containing a list of [AuditReport].
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId);

  /// Retrieves deviation trends for a specific environment and equipment.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param environmentId The environment identifier.
  /// @param from The start date of the period to query.
  /// @param to The end date of the period to query.
  /// @return A [Future] containing a list of [DeviationTrend].
  Future<List<DeviationTrend>> getDeviationTrends(
      LaboratoryId laboratoryId,
      int environmentId, {
        required DateTime from,
        required DateTime to,
      });

  /// Retrieves the audit log for a specific equipment.
  ///
  /// @param laboratoryId The laboratory identifier.
  /// @param equipmentId The equipment identifier.
  /// @return A [Future] containing a list of [AuditLogEntry].
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId);

  /// Retrieves the audit log for a specific batch.
  ///
  /// @param batchId The batch identifier.
  /// @return A [Future] containing a list of [AuditLogEntry].
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId);
}