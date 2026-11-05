/// This file contains the entities related to the KPI Dashboard.
///

import 'package:equatable/equatable.dart';
import 'reporting_enums.dart';

/// Represents an individual Key Performance Indicator (KPI).
final class KpiMetric extends Equatable {
  const KpiMetric({
    required this.name,
    required this.status,
    this.id,
    this.value,
    this.unit,
    this.targetValue,
    this.recordedAt,
  });

  final int? id;
  final String name;
  final double? value;
  final String? unit;
  final double? targetValue;
  final KpiMetricStatus status;
  final DateTime? recordedAt;

  @override
  List<Object?> get props => [id, name, value, unit, targetValue, status, recordedAt];
}

/// Statistical summary of the readings of a variable on a device.
final class MeasurementSummary extends Equatable {
  const MeasurementSummary({
    required this.environmentId,
    required this.deviceId,
    required this.metric,
    required this.readings,
    this.unit,
    this.average,
    this.minimum,
    this.maximum,
    this.lastMeasuredAt,
  });

  final int environmentId;
  final int deviceId;
  final String metric;
  final String? unit;
  final int readings;
  final double? average;
  final double? minimum;
  final double? maximum;
  final DateTime? lastMeasuredAt;

  @override
  List<Object?> get props => [environmentId, deviceId, metric, unit, readings, average, minimum, maximum, lastMeasuredAt];
}

/// Represents the complete KPI dashboard for a laboratory.
final class KpiDashboard extends Equatable {
  const KpiDashboard({
    required this.laboratoryId,
    this.metrics = const [],
    this.measurementSummaries = const [],
    this.overallHealthScore,
    this.timestamp,
  });

  final int laboratoryId;
  final double? overallHealthScore;
  final DateTime? timestamp;
  final List<KpiMetric> metrics;
  final List<MeasurementSummary> measurementSummaries;

  @override
  List<Object?> get props => [laboratoryId, overallHealthScore, timestamp, metrics, measurementSummaries];
}