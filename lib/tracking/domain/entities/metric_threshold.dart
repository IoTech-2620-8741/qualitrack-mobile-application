import 'package:equatable/equatable.dart';

import 'monitored_metric.dart';

/// Normal and critical range of one metric. Readings outside the normal range
/// are warnings; outside the critical range, critical.
class MetricThreshold extends Equatable {
  const MetricThreshold({
    required this.metric,
    this.unit,
    this.normalMin,
    this.normalMax,
    this.criticalMin,
    this.criticalMax,
  });

  final MonitoredMetric metric;
  final String? unit;
  final double? normalMin;
  final double? normalMax;
  final double? criticalMin;
  final double? criticalMax;

  @override
  List<Object?> get props => [metric, unit, normalMin, normalMax, criticalMin, criticalMax];
}
