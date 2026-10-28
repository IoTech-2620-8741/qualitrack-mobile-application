import '../../../shared/domain/value_objects.dart';
import '../entities/reporting_entities.dart';

abstract interface class ReportingRepository {
  Future<KpiDashboard> getKpiDashboard(
      LaboratoryId laboratoryId, {
        required DateTime from,
        required DateTime to,
        int? environmentId,
      });

  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId);

  Future<List<DeviationTrend>> getDeviationTrends(
      LaboratoryId laboratoryId,
      int environmentId, {
        required DateTime from,
        required DateTime to,
      });

  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId);

  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId);
}