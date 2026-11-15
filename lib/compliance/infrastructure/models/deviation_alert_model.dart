import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/alert_origin.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/deviation_alert.dart';
import '../../domain/entities/related_actuation.dart';

/// `DeviationAlertResource`.
class DeviationAlertModel extends DeviationAlert {
  const DeviationAlertModel({
    required super.id,
    required super.equipmentId,
    required super.parameterName,
    required super.status,
    required super.severity,
    super.environmentId,
    super.origin,
    super.batchId,
    super.recordedValue,
    super.thresholdValue,
    super.unit,
    super.timestamp,
    super.deviationCount,
    super.lastDetectedAt,
    super.normalizedAt,
    super.acknowledgedBy,
    super.acknowledgedAt,
    super.resolvedBy,
    super.resolvedAt,
    super.resolutionNotes,
    super.relatedActuations,
  });

  factory DeviationAlertModel.fromJson(Map<String, dynamic> json) => DeviationAlertModel(
    id: Json.requireInt(json, 'id'),
    environmentId: Json.optInt(json, 'environmentId'),
    origin: AlertOrigin.fromCode(Json.optString(json, 'origin')),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    batchId: Json.optInt(json, 'batchId'),
    parameterName: Json.requireString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    thresholdValue: Json.optDouble(json, 'thresholdValue'),
    unit: Json.optString(json, 'unit'),
    timestamp: Json.optDateTime(json, 'timestamp'),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    status: AlertStatus.fromCode(Json.optString(json, 'status')),
    deviationCount: Json.optInt(json, 'deviationCount') ?? 1,
    lastDetectedAt: Json.optDateTime(json, 'lastDetectedAt'),
    normalizedAt: Json.optDateTime(json, 'normalizedAt'),
    acknowledgedBy: Json.optInt(json, 'acknowledgedBy'),
    acknowledgedAt: Json.optDateTime(json, 'acknowledgedAt'),
    resolvedBy: Json.optInt(json, 'resolvedBy'),
    resolvedAt: Json.optDateTime(json, 'resolvedAt'),
    resolutionNotes: Json.optString(json, 'resolutionNotes'),
    relatedActuations: [
      if (json['relatedActuations'] != null)
        for (final item in Json.asList(json['relatedActuations']))
          RelatedActuation(
            id: Json.requireInt(item, 'id'),
            action: Json.requireString(item, 'action'),
            result: Json.requireString(item, 'result'),
            triggerState: Json.optString(item, 'triggerState'),
            occurredAt: Json.optDateTime(item, 'occurredAt'),
          ),
    ],
  );
}
