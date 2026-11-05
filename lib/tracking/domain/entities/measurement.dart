import 'package:equatable/equatable.dart';

import 'environmental_state.dart';
import 'monitored_metric.dart';

/// `MeasurementResource`: a reading evaluated in Cloud.
class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.deviceId,
    required this.environmentId,
    required this.metric,
    required this.rawMetric,
    required this.state,
    this.value,
    this.textValue,
    this.unit,
    this.measuredAt,
    this.thresholdValue,
    this.profileVersion,
  });

  final int id;
  final int deviceId;
  final int environmentId;
  final MonitoredMetric metric;

  /// Metric code as sent by the backend (kept for metrics unknown to the app).
  final String rawMetric;
  final double? value;
  final String? textValue;
  final String? unit;
  final DateTime? measuredAt;
  final EnvironmentalState state;

  /// Limit that was exceeded, when the reading is a deviation.
  final double? thresholdValue;
  final int? profileVersion;

  bool get isNumeric => metric.isNumeric && value != null && value!.isFinite;

  @override
  List<Object?> get props => [
    id,
    deviceId,
    environmentId,
    metric,
    rawMetric,
    value,
    textValue,
    unit,
    measuredAt,
    state,
    thresholdValue,
    profileVersion,
  ];
}
