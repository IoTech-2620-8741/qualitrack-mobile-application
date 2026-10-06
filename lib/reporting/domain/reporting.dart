import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// Periods offered for indicators, as in QualiTrack Web (24 hours, 7 or 31 days).
enum ReportPeriod {
  last24Hours(Duration(hours: 24)),
  last7Days(Duration(days: 7)),
  last31Days(Duration(days: 31));

  const ReportPeriod(this.duration);

  final Duration duration;
}

enum KpiMetricStatus {
  onTrack('ON_TRACK'),
  atRisk('AT_RISK'),
  critical('CRITICAL'),
  unknown('UNKNOWN');

  const KpiMetricStatus(this.code);

  final String code;

  static KpiMetricStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return KpiMetricStatus.unknown;
  }
}

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

/// Average, minimum and maximum of the readings of one variable of one device
/// in the period (US: consult a summary of environmental measurements).
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

  /// Metric code of Tracking (e.g. `TEMPERATURE`).
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

/// `KpiDashboardResource`: indicators calculated on request for a period.
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

/// `AuditReportResource`: a generated report (PDF or CSV) kept for download.
final class AuditReport extends Equatable {
  const AuditReport({
    required this.id,
    required this.reportType,
    this.laboratoryId,
    this.batchId,
    this.equipmentId,
    this.generatedByName,
    this.dateRangeFrom,
    this.dateRangeTo,
    this.generatedAt,
    this.checksum,
  });

  final int id;
  final String reportType;
  final int? laboratoryId;
  final int? batchId;
  final int? equipmentId;
  final String? generatedByName;
  final String? dateRangeFrom;
  final String? dateRangeTo;
  final DateTime? generatedAt;
  final String? checksum;

  @override
  List<Object?> get props => [
    id,
    reportType,
    laboratoryId,
    batchId,
    equipmentId,
    generatedByName,
    dateRangeFrom,
    dateRangeTo,
    generatedAt,
    checksum,
  ];
}

enum TrendDirection {
  increasing('INCREASING'),
  decreasing('DECREASING'),
  stable('STABLE'),
  unknown('UNKNOWN');

  const TrendDirection(this.code);

  final String code;

  static TrendDirection fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return TrendDirection.unknown;
  }
}

/// `DeviationTrendResource`: time in range and deviations of one variable of
/// one device in the period (US: consult deviation indicators). The time in
/// range is weighted by the time between evaluated readings.
final class DeviationTrend extends Equatable {
  const DeviationTrend({
    required this.parameterName,
    required this.equipmentId,
    required this.direction,
    this.environmentId,
    this.unit,
    this.evaluatedReadings = 0,
    this.timeInRangePercent,
    this.deviationCount = 0,
    this.criticalDeviationCount = 0,
  });

  final String parameterName;
  final int equipmentId;
  final int? environmentId;
  final String? unit;
  final TrendDirection direction;
  final int evaluatedReadings;
  final double? timeInRangePercent;
  final int deviationCount;
  final int criticalDeviationCount;

  @override
  List<Object?> get props => [
    parameterName,
    equipmentId,
    environmentId,
    unit,
    direction,
    evaluatedReadings,
    timeInRangePercent,
    deviationCount,
    criticalDeviationCount,
  ];
}

/// `AuditLogEntryResource`.
final class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.action,
    this.entityType,
    this.entityId,
    this.performedBy,
    this.timestamp,
    this.rawTimestamp,
    this.details,
  });

  final int id;
  final String action;
  final String? entityType;
  final int? entityId;
  final int? performedBy;
  final DateTime? timestamp;
  final String? rawTimestamp;
  final String? details;

  @override
  List<Object?> get props => [id, action, entityType, entityId, performedBy, timestamp, rawTimestamp, details];
}

abstract interface class ReportingRepository {
  Future<KpiDashboard> getKpiDashboard(
    LaboratoryId laboratoryId, {
    required DateTime from,
    required DateTime to,
    int? environmentId,
  });
  Future<List<AuditReport>> getLaboratoryReports(LaboratoryId laboratoryId);
  Future<List<DeviationTrend>> getDeviationTrends(
    LaboratoryId laboratoryId,
    int environmentId, {
    required DateTime from,
    required DateTime to,
  });
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId);
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId);
}
