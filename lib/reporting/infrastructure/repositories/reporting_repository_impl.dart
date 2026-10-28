import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/json_utils.dart'; // Asegúrate de tener toIsoMillis aquí
import '../../domain/entities/reporting_entities.dart';
import '../../domain/repositories/reporting_repository.dart';
import '../data_sources/reporting_remote_data_source.dart';

class ReportingRepositoryImpl implements ReportingRepository {
  const ReportingRepositoryImpl(this._remote);

  final ReportingRemoteDataSource _remote;

  @override
  Future<KpiDashboard> getKpiDashboard(
      LaboratoryId laboratoryId, {
        required DateTime from,
        required DateTime to,
        int? environmentId,
      }) async => (await _remote.getKpiDashboard(
    laboratoryId.value,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
    environmentId: environmentId,
  )).toDomain();

  @override
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId) async =>
      (await _remote.getLaboratoryReports(laboratoryId.value)).map((d) => d.toDomain()).toList();

  @override
  Future<List<DeviationTrend>> getDeviationTrends(
      LaboratoryId laboratoryId,
      int environmentId, {
        required DateTime from,
        required DateTime to,
      }) async => (await _remote.getTrends(
    laboratoryId.value,
    environmentId,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
  )).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) async =>
      (await _remote.getEquipmentAuditLogs(laboratoryId.value, equipmentId)).map((d) => d.toDomain()).toList();

  @override
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) async =>
      (await _remote.getBatchAuditLogs(batchId)).map((d) => d.toDomain()).toList();
}