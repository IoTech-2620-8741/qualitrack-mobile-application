import 'package:equatable/equatable.dart';

import 'actuation_rule.dart';
import 'metric_threshold.dart';
import 'monitored_metric.dart';

/// `EnvironmentalProfileResource`: versioned thresholds (and rules for
/// container monitors) configured in QualiTrack Web.
class EnvironmentalProfile extends Equatable {
  const EnvironmentalProfile({
    required this.version,
    this.thresholds = const [],
    this.actuationRules = const [],
    this.updatedAt,
  });

  final int version;
  final List<MetricThreshold> thresholds;
  final List<ActuationRule> actuationRules;
  final DateTime? updatedAt;

  MetricThreshold? thresholdFor(MonitoredMetric metric) {
    for (final threshold in thresholds) {
      if (threshold.metric == metric) return threshold;
    }
    return null;
  }

  @override
  List<Object?> get props => [version, thresholds, actuationRules, updatedAt];
}
