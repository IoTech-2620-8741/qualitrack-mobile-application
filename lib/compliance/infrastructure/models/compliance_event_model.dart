import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/compliance_event.dart';

/// `ComplianceEventResource`.
class ComplianceEventModel extends ComplianceEvent {
  const ComplianceEventModel({
    required super.id,
    required super.eventType,
    super.relatedEntityId,
    super.description,
    super.timestamp,
    super.rawTimestamp,
    super.resolvedBy,
  });

  factory ComplianceEventModel.fromJson(Map<String, dynamic> json) => ComplianceEventModel(
    id: Json.requireInt(json, 'id'),
    eventType: Json.requireString(json, 'eventType'),
    relatedEntityId: Json.optInt(json, 'relatedEntityId'),
    description: Json.optString(json, 'description'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    rawTimestamp: Json.optString(json, 'timestamp'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
  );
}
