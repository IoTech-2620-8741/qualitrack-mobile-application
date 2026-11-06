/// JSON model of an audit log entry (`AuditLogResource`).
library;

import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/audit_entities.dart';

/// An [AuditLogEntry] read from the REST API.
class AuditLogEntryModel extends AuditLogEntry {
  const AuditLogEntryModel({
    required super.id,
    required super.action,
    super.entityType,
    super.entityId,
    super.performedBy,
    super.timestamp,
    super.rawTimestamp,
    super.details,
  });

  factory AuditLogEntryModel.fromJson(Map<String, dynamic> json) => AuditLogEntryModel(
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
