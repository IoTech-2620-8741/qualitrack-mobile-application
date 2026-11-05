/// This file contains the implementation of the [ReportingRepository].
///
/// It acts as a bridge between the Domain layer (which uses Entities and DateTime)
/// and the Infrastructure layer (which uses DTOs and String timestamps).
///
library;

import '../../../common/domain/value_objects.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../domain/repositories/reporting_repository.dart';
import '../data_sources/reporting_remote_data_source.dart';

/// Implementation of the [ReportingRepository] using a remote data source (API).
class ReportingRepositoryImpl implements ReportingRepository {
  const ReportingRepositoryImpl(this._remote);

  final ReportingRemoteDataSource _remote;

  /// Fetches the KPI dashboard, converting DateTime to String and DTO to Domain.
  @override
  Future<KpiDashboard> getKpiDashboard(
      LaboratoryId laboratoryId, {
        required DateTime from,
        required DateTime to,
        int? environmentId,
      }) async {
    final dto = await _remote.getKpiDashboard(
      laboratoryId.value,
      from: toIsoMillis(from),
      to: toIsoMillis(to),
      environmentId: environmentId,
    );
    return dto.toDomain();
  }

  /// Fetches the laboratory reports, mapping the list of DTOs to Domain entities.
  @override
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId) async {
    final dtos = await _remote.getLaboratoryReports(laboratoryId.value);
    return dtos.map((d) => d.toDomain()).toList();
  }

  /// Fetches the deviation trends, converting DateTime to String and mapping DTOs.
  @override
  Future<List<DeviationTrend>> getDeviationTrends(
      LaboratoryId laboratoryId,
      int environmentId, {
        required DateTime from,
        required DateTime to,
      }) async {
    final dtos = await _remote.getTrends(
      laboratoryId.value,
      environmentId,
      from: toIsoMillis(from),
      to: toIsoMillis(to),
    );
    return dtos.map((d) => d.toDomain()).toList();
  }

  /// Fetches the equipment audit logs, mapping the list of DTOs to Domain entities.
  @override
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) async {
    final dtos = await _remote.getEquipmentAuditLogs(laboratoryId.value, equipmentId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  /// Fetches the batch audit logs, mapping the list of DTOs to Domain entities.
  @override
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) async {
    final dtos = await _remote.getBatchAuditLogs(batchId);
    return dtos.map((d) => d.toDomain()).toList();
  }
}