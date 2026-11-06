/// JSON model of a generated audit report (`ReportResource`).
library;

import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/audit_entities.dart';

/// An [AuditReport] read from the REST API.
class AuditReportModel extends AuditReport {
  const AuditReportModel({
    required super.id,
    required super.reportType,
    super.laboratoryId,
    super.batchId,
    super.equipmentId,
    super.generatedByName,
    super.dateRangeFrom,
    super.dateRangeTo,
    super.generatedAt,
    super.checksum,
  });

  factory AuditReportModel.fromJson(Map<String, dynamic> json) => AuditReportModel(
    id: Json.requireInt(json, 'id'),
    reportType: Json.optString(json, 'reportType') ?? 'UNKNOWN',
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    batchId: Json.optInt(json, 'batchId'),
    equipmentId: Json.optInt(json, 'equipmentId'),
    generatedByName: Json.optString(json, 'generatedByName'),
    dateRangeFrom: Json.optString(json, 'dateRangeFrom'),
    dateRangeTo: Json.optString(json, 'dateRangeTo'),
    generatedAt: Json.optDateTime(json, 'generatedAt'),
    checksum: Json.optString(json, 'checksum'),
  );
}
