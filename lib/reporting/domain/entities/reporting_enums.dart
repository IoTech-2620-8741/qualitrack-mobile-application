/// This file contains all the enumerations used across the Reporting domain.
///
library;

/// Defines the predefined time periods used to calculate indicators.
enum ReportPeriod {
  last24Hours(Duration(hours: 24)),
  last7Days(Duration(days: 7)),
  last31Days(Duration(days: 31));

  const ReportPeriod(this.duration);

  /// The exact duration of the period.
  final Duration duration;
}

/// Defines the health status of a KPI metric.
enum KpiMetricStatus {
  onTrack('ON_TRACK'),
  atRisk('AT_RISK'),
  critical('CRITICAL'),
  unknown('UNKNOWN');

  const KpiMetricStatus(this.code);

  /// The raw code coming from the backend.
  final String code;

  /// Converts a string code into its corresponding enum value.
  static KpiMetricStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return KpiMetricStatus.unknown;
  }
}

/// Defines the direction of a statistical trend.
enum TrendDirection {
  increasing('INCREASING'),
  decreasing('DECREASING'),
  stable('STABLE'),
  unknown('UNKNOWN');

  const TrendDirection(this.code);

  /// The raw code coming from the backend.
  final String code;

  /// Converts a string code into its corresponding enum value.
  static TrendDirection fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return TrendDirection.unknown;
  }
}

/// Defines the severity levels based on the deviation metrics.
enum DeviationSeverity { critical, warning, onTrack, noData }