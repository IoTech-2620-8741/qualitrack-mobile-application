import 'package:equatable/equatable.dart';

import 'alert_status.dart';
import 'deviation_alert.dart';

/// Aggregated counters for the alerts screen.
class AlertSummary extends Equatable {
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
