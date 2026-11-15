import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/alert_severity.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

/// `NotificationResource`.
class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.subjectType,
    required super.subjectId,
    super.severity,
    super.environmentName,
    super.subjectName,
    super.parameterName,
    super.recordedValue,
    super.unit,
    super.actorName,
    super.note,
    super.occurredAt,
    super.readAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) => AppNotificationModel(
    id: Json.requireInt(json, 'id'),
    type: NotificationType.fromCode(Json.optString(json, 'type')),
    severity: AlertSeverity.fromCode(Json.optString(json, 'severity')),
    subjectType: Json.requireString(json, 'subjectType'),
    subjectId: Json.requireInt(json, 'subjectId'),
    environmentName: Json.optString(json, 'environmentName'),
    subjectName: Json.optString(json, 'subjectName'),
    parameterName: Json.optString(json, 'parameterName'),
    recordedValue: Json.optDouble(json, 'recordedValue'),
    unit: Json.optString(json, 'unit'),
    actorName: Json.optString(json, 'actorName'),
    note: Json.optString(json, 'note'),
    occurredAt: Json.optDateTime(json, 'occurredAt'),
    readAt: Json.optDateTime(json, 'readAt'),
  );
}
