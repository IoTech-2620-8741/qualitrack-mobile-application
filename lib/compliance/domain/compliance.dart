import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

enum AlertStatus {
  unresolved('UNRESOLVED'),
  acknowledged('ACKNOWLEDGED'),
  resolved('RESOLVED'),
  unknown('UNKNOWN');

  const AlertStatus(this.code);

  final String code;

  static AlertStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertStatus.unknown;
  }
}

enum AlertSeverity {
  low('LOW'),
  warning('WARNING'),
  critical('CRITICAL'),
  unknown('UNKNOWN');

  const AlertSeverity(this.code);

  final String code;

  static AlertSeverity fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertSeverity.unknown;
  }
}

/// Where the deviation was detected: the environmental device of an
/// environment or a container monitor.
enum AlertOrigin {
  environment('ENVIRONMENT'),
  container('CONTAINER'),
  unknown('UNKNOWN');

  const AlertOrigin(this.code);

  final String code;

  static AlertOrigin fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return AlertOrigin.unknown;
  }
}

/// Automatic action of the container related to the alert.
final class RelatedActuation extends Equatable {
  const RelatedActuation({required this.id, required this.action, required this.result, this.triggerState, this.occurredAt});

  final int id;
  final String action;
  final String result;
  final String? triggerState;
  final DateTime? occurredAt;

  @override
  List<Object?> get props => [id, action, result, triggerState, occurredAt];
}

/// `DeviationAlertResource`. There is one alert per incident: new deviations
/// of the same device and variable join the open alert and its severity only
/// rises. A return to normal is noted, but the alert stays open until a
/// person resolves it.
final class DeviationAlert extends Equatable {
  const DeviationAlert({
    required this.id,
    required this.equipmentId,
    required this.parameterName,
    required this.status,
    required this.severity,
    this.environmentId,
    this.origin = AlertOrigin.unknown,
    this.batchId,
    this.recordedValue,
    this.thresholdValue,
    this.unit,
    this.timestamp,
    this.deviationCount = 1,
    this.lastDetectedAt,
    this.normalizedAt,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.relatedActuations = const [],
  });

  final int id;
  final int? environmentId;
  final AlertOrigin origin;

  /// IoT device that detected the deviation.
  final int equipmentId;
  final int? batchId;

  /// Metric code of Tracking (e.g. `TEMPERATURE`).
  final String parameterName;
  final double? recordedValue;
  final double? thresholdValue;
  final String? unit;
  final DateTime? timestamp;
  final AlertSeverity severity;
  final AlertStatus status;
  final int deviationCount;
  final DateTime? lastDetectedAt;
  final DateTime? normalizedAt;
  final int? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final int? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final List<RelatedActuation> relatedActuations;

  bool get isOpen => status != AlertStatus.resolved;
  bool get isCritical => severity == AlertSeverity.critical;

  /// Lifecycle offered by the backend: UNRESOLVED → ACKNOWLEDGED → RESOLVED
  /// (RESOLVED may also be reached directly from UNRESOLVED).
  bool get canAcknowledge => status == AlertStatus.unresolved;
  bool get canResolve => status == AlertStatus.unresolved || status == AlertStatus.acknowledged;

  /// Open critical alerts first, then newest first (same order as Web).
  static int compareByPriority(DeviationAlert a, DeviationAlert b) {
    final open = (b.isOpen ? 1 : 0).compareTo(a.isOpen ? 1 : 0);
    if (open != 0) return open;
    final critical = (b.isCritical ? 1 : 0).compareTo(a.isCritical ? 1 : 0);
    if (critical != 0) return critical;
    final left = a.lastDetectedAt ?? a.timestamp;
    final right = b.lastDetectedAt ?? b.timestamp;
    if (left == null && right == null) return b.id.compareTo(a.id);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  @override
  List<Object?> get props => [
    id,
    environmentId,
    origin,
    equipmentId,
    batchId,
    parameterName,
    recordedValue,
    thresholdValue,
    unit,
    timestamp,
    severity,
    status,
    deviationCount,
    lastDetectedAt,
    normalizedAt,
    acknowledgedBy,
    acknowledgedAt,
    resolvedBy,
    resolvedAt,
    resolutionNotes,
    relatedActuations,
  ];
}

/// Aggregated counters for the alerts screen.
final class AlertSummary extends Equatable {
  const AlertSummary({
    required this.total,
    required this.unresolved,
    required this.acknowledged,
    required this.resolved,
    required this.critical,
  });

  factory AlertSummary.of(List<DeviationAlert> alerts) => AlertSummary(
    total: alerts.length,
    unresolved: alerts.where((a) => a.status == AlertStatus.unresolved).length,
    acknowledged: alerts.where((a) => a.status == AlertStatus.acknowledged).length,
    resolved: alerts.where((a) => a.status == AlertStatus.resolved).length,
    critical: alerts.where((a) => a.isCritical && a.isOpen).length,
  );

  final int total;
  final int unresolved;
  final int acknowledged;
  final int resolved;

  /// Critical alerts that are still open.
  final int critical;

  int get open => unresolved + acknowledged;

  @override
  List<Object?> get props => [total, unresolved, acknowledged, resolved, critical];
}

/// `ComplianceEventResource`.
final class ComplianceEvent extends Equatable {
  const ComplianceEvent({
    required this.id,
    required this.eventType,
    this.relatedEntityId,
    this.description,
    this.timestamp,
    this.rawTimestamp,
    this.resolvedBy,
  });

  final int id;
  final String eventType;
  final int? relatedEntityId;
  final String? description;
  final DateTime? timestamp;
  final String? rawTimestamp;
  final int? resolvedBy;

  @override
  List<Object?> get props => [id, eventType, relatedEntityId, description, timestamp, rawTimestamp, resolvedBy];
}

/// `NotificationType` of the in-app notifications (the bell).
enum NotificationType {
  alertOpened('ALERT_OPENED'),
  alertEscalated('ALERT_ESCALATED'),
  alertAcknowledged('ALERT_ACKNOWLEDGED'),
  alertResolved('ALERT_RESOLVED'),
  batchReleased('BATCH_RELEASED'),
  batchRejected('BATCH_REJECTED'),
  unknown('UNKNOWN');

  const NotificationType(this.code);

  final String code;

  static NotificationType fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return NotificationType.unknown;
  }
}

/// `NotificationResource`: a notice for the signed-in user about an alert or
/// a batch.
final class AppNotification extends Equatable {
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

/// How the signed-in user wants to be notified about alerts. Batch notices
/// ignore the minimum severity.
final class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.minimumSeverity,
  });

  final bool inAppEnabled;
  final bool emailEnabled;
  final AlertSeverity minimumSeverity;

  NotificationPreferences copyWith({bool? inAppEnabled, bool? emailEnabled, AlertSeverity? minimumSeverity}) =>
      NotificationPreferences(
        inAppEnabled: inAppEnabled ?? this.inAppEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
        minimumSeverity: minimumSeverity ?? this.minimumSeverity,
      );

  @override
  List<Object?> get props => [inAppEnabled, emailEnabled, minimumSeverity];
}

abstract interface class ComplianceRepository {
  Future<List<DeviationAlert>> getEnvironmentAlerts(LaboratoryId laboratoryId, int environmentId);
  Future<DeviationAlert> getAlert(int alertId);
  Future<DeviationAlert> acknowledge(int alertId);
  Future<DeviationAlert> resolve(int alertId, String resolutionNotes);
  Future<List<ComplianceEvent>> getEquipmentEvents(LaboratoryId laboratoryId, int equipmentId);
  Future<List<ComplianceEvent>> getBatchEvents(int batchId);
}

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false, int limit = 50});
  Future<int> getUnreadCount();
  Future<void> markRead(int notificationId);
  Future<void> markAllRead();
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences);
}
