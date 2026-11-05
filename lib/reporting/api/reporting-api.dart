
import '../../shared/domain/value_objects.dart';
import '../application/reporting_queries.dart';
import '../domain/entities/reporting_entities.dart';

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

  Future<List<AuditLogEntry>> fetchEquipmentAuditLogs(LaboratoryId labId, int equipmentId) {
    return getEquipmentAuditLogs(labId, equipmentId);
  }

  Future<List<AuditLogEntry>> fetchBatchAuditLogs(int batchId) {
    return getBatchAuditLogs(batchId);
  }

  Future<List<AuditReport>> fetchReportHistory(LaboratoryId labId) {
    return getReportHistory(labId);
  }
}