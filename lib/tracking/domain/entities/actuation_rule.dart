import 'package:equatable/equatable.dart';

import 'environmental_state.dart';
import 'monitored_metric.dart';

/// Automatic response of a container: the action executed when a metric
/// reaches a state.
class ActuationRule extends Equatable {
  const ActuationRule({required this.metric, required this.state, required this.action});

  final MonitoredMetric metric;
  final EnvironmentalState state;
  final String action;

  @override
  List<Object?> get props => [metric, state, action];
}
