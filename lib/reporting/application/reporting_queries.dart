import '../../shared/application/bounded_concurrency.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/reporting.dart';

/// Indicators of the laboratory (or of one environment) in a period ending now.
class GetKpiDashboard {
  const GetKpiDashboard(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ReportingRepository _repository;
  final DateTime Function() _clock;

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

/// Deviation indicators of every given environment in a period ending now
/// (the backend calculates them per environment).
class GetDeviationTrends {
  const GetDeviationTrends(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ReportingRepository _repository;
  final DateTime Function() _clock;

  Future<List<DeviationTrend>> call(LaboratoryId laboratoryId, Iterable<int> environmentIds, ReportPeriod period) {
    final to = _clock();
    final from = to.subtract(period.duration);
    return loadAll(
      environmentIds,
      (environmentId) => _repository.getDeviationTrends(laboratoryId, environmentId, from: from, to: to),
    );
  }
}

class GetEquipmentAuditLogs {
  const GetEquipmentAuditLogs(this._repository);

  final ReportingRepository _repository;

  Future<List<AuditLogEntry>> call(LaboratoryId laboratoryId, int equipmentId) async =>
      _newestFirst(await _repository.getEquipmentAuditLogs(laboratoryId, equipmentId));
}

class GetBatchAuditLogs {
  const GetBatchAuditLogs(this._repository);

  final ReportingRepository _repository;

  Future<List<AuditLogEntry>> call(int batchId) async => _newestFirst(await _repository.getBatchAuditLogs(batchId));
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
