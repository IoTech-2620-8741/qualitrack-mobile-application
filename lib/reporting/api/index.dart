/// Public entry point of the Reporting and audit context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

import '../../common/domain/value_objects.dart';
import '../application/reporting_facade_service.dart';
import '../domain/entities/audit_entities.dart';
import '../domain/entities/deviation_entities.dart';
import '../domain/entities/reporting_enums.dart';

export '../domain/entities/reporting_entities.dart';

/// What other contexts read from Reporting & Audit: audit trails and deviation
/// trends, newest or most severe first.
class ReportingApi {
  const ReportingApi(this._reportingService);

  final ReportingFacadeService _reportingService;

  /// Deviation trends of the given environments, most severe first.
  Future<List<DeviationTrend>> getDeviationTrends(
    LaboratoryId laboratoryId,
    Iterable<int> environmentIds,
    ReportPeriod period,
  ) => _reportingService.getDeviationTrends(laboratoryId, environmentIds, period);

  /// Audit trail of one equipment, newest first.
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) =>
      _reportingService.getEquipmentAuditLogs(laboratoryId, equipmentId);

  /// Audit trail of one batch, newest first.
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) => _reportingService.getBatchAuditLogs(batchId);
}
