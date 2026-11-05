import 'package:equatable/equatable.dart';

import 'alert_origin.dart';
import 'alert_severity.dart';
import 'alert_status.dart';
import 'related_actuation.dart';

/// `DeviationAlertResource`. There is one alert per incident: new deviations
/// of the same device and variable join the open alert and its severity only
/// rises. A return to normal is noted, but the alert stays open until a
/// person resolves it.
class DeviationAlert extends Equatable {
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
