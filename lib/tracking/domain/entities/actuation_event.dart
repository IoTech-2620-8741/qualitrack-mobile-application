import 'package:equatable/equatable.dart';

import 'environmental_state.dart';
import 'monitored_metric.dart';

/// `ActuationEventResource`: an action executed by a container monitor.
class ActuationEvent extends Equatable {
  const ActuationEvent({
    required this.id,
    required this.deviceId,
    required this.action,
    required this.result,
    this.triggerMetric,
    this.triggerState,
    this.occurredAt,
  });

  final int id;
  final int deviceId;
  final String action;
  final String result;
  final MonitoredMetric? triggerMetric;
  final EnvironmentalState? triggerState;
  final DateTime? occurredAt;

  bool get executed => result == 'EXECUTED';

  @override
  List<Object?> get props => [id, deviceId, action, result, triggerMetric, triggerState, occurredAt];
}
