/// This file contains the Data Transfer Objects (DTOs) for Audit data.
///
import '../../../../shared/infrastructure/http/json_utils.dart';
import '../../domain/entities/audit_entities.dart';

/// DTO for the Audit Report response.
class AuditReportDto {
  const AuditReportDto(this.json);

  final Map<String, dynamic> json;

  /// Converts the raw JSON map into an [AuditReport] domain entity.
  AuditReport toDomain() => AuditReport(
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

/// DTO for the Audit Log Entry response.
class AuditLogEntryDto {
  const AuditLogEntryDto(this.json);

  final Map<String, dynamic> json;

  /// Converts the raw JSON map into an [AuditLogEntry] domain entity.
  AuditLogEntry toDomain() => AuditLogEntry(
    id: Json.requireInt(json, 'id'),
    action: Json.optString(json, 'action') ?? 'UNKNOWN',
    entityType: Json.optString(json, 'entityType'),
    entityId: Json.optInt(json, 'entityId'),
    performedBy: Json.optInt(json, 'performedBy'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    details: Json.optString(json, 'details'),
  );
}