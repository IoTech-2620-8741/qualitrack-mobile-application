import 'package:equatable/equatable.dart';

import 'alert_severity.dart';
import 'notification_type.dart';

/// `NotificationResource`: a notice for the signed-in user about an alert or
/// a batch.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.subjectType,
    required this.subjectId,
    this.severity = AlertSeverity.unknown,
    this.environmentName,
    this.subjectName,
    this.parameterName,
    this.recordedValue,
    this.unit,
    this.actorName,
    this.note,
    this.occurredAt,
    this.readAt,
  });

  final int id;
  final NotificationType type;
  final AlertSeverity severity;

  /// `ALERT` or `BATCH`.
  final String subjectType;
  final int subjectId;
  final String? environmentName;
  final String? subjectName;
  final String? parameterName;
  final double? recordedValue;
  final String? unit;
  final String? actorName;
  final String? note;
  final DateTime? occurredAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// This notice read at [at] (unchanged if it was already read).
  AppNotification readNow(DateTime at) => isRead
      ? this
      : AppNotification(
          id: id,
          type: type,
          subjectType: subjectType,
          subjectId: subjectId,
          severity: severity,
          environmentName: environmentName,
          subjectName: subjectName,
          parameterName: parameterName,
          recordedValue: recordedValue,
          unit: unit,
          actorName: actorName,
          note: note,
          occurredAt: occurredAt,
          readAt: at,
        );
  bool get isAboutAlert => subjectType == 'ALERT';
  bool get isAboutBatch => subjectType == 'BATCH';

  @override
  List<Object?> get props => [
    id,
    type,
    severity,
    subjectType,
    subjectId,
    environmentName,
    subjectName,
    parameterName,
    recordedValue,
    unit,
    actorName,
    note,
    occurredAt,
    readAt,
  ];
}
