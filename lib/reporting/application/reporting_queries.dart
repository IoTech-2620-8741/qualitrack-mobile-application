import '../../shared/domain/value_objects.dart';
import '../domain/reporting.dart';

class GetKpiDashboard {
  const GetKpiDashboard(this._repository);

  final ReportingRepository _repository;

  Future<KpiDashboard?> call(LaboratoryId laboratoryId) => _repository.getKpiDashboard(laboratoryId);
}

class GetReportHistory {
  const GetReportHistory(this._repository);

  final ReportingRepository _repository;

  Future<List<AuditReport>> call(LaboratoryId laboratoryId) async {
    final reports = await _repository.getLaboratoryReports(laboratoryId);
    return [...reports]..sort((a, b) {
      final left = a.generatedAt;
      final right = b.generatedAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

class GetDeviationTrends {
  const GetDeviationTrends(this._repository);

  final ReportingRepository _repository;

  Future<List<DeviationTrend>> call(int equipmentId) => _repository.getDeviationTrends(equipmentId);
}

class GetEquipmentAuditLogs {
  const GetEquipmentAuditLogs(this._repository);

  final ReportingRepository _repository;

  Future<List<AuditLogEntry>> call(int equipmentId) async =>
      _newestFirst(await _repository.getEquipmentAuditLogs(equipmentId));
}

class GetBatchAuditLogs {
  const GetBatchAuditLogs(this._repository);

  final ReportingRepository _repository;

  Future<List<AuditLogEntry>> call(int batchId) async =>
      _newestFirst(await _repository.getBatchAuditLogs(batchId));
}

List<AuditLogEntry> _newestFirst(List<AuditLogEntry> entries) => [...entries]
  ..sort((a, b) {
    final left = a.timestamp;
    final right = b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
