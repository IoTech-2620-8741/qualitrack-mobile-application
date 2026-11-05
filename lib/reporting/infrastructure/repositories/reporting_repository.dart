/// Repository implementation of the Reporting context.
library;

import '../../../common/domain/value_objects.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../domain/interfaces/reporting_interface.dart';
import '../data_sources/reporting_remote_data_provider.dart';

/// Implements [ReportingInterface] with the REST API. There is no offline cache:
/// every read goes to the remote data provider.
class ReportingRepository implements ReportingInterface {
  const ReportingRepository({required ReportingRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final ReportingRemoteDataProvider _remote;

  /// Same wire format as Web: `Date.toISOString()` (UTC, milliseconds, `Z`).
  @override
  Future<KpiDashboard> getKpiDashboard(
    LaboratoryId laboratoryId, {
    required DateTime from,
    required DateTime to,
    int? environmentId,
  }) => _remote.getKpiDashboard(
    laboratoryId.value,
    from: toIsoMillis(from),
    to: toIsoMillis(to),
    environmentId: environmentId,
  );

  @override
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId) =>
      _remote.getLaboratoryReports(laboratoryId.value);

  @override
  Future<List<DeviationTrend>> getDeviationTrends(
    LaboratoryId laboratoryId,
    int environmentId, {
    required DateTime from,
    required DateTime to,
  }) => _remote.getTrends(laboratoryId.value, environmentId, from: toIsoMillis(from), to: toIsoMillis(to));

  @override
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) =>
      _remote.getEquipmentAuditLogs(laboratoryId.value, equipmentId);

  @override
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) => _remote.getBatchAuditLogs(batchId);
}
