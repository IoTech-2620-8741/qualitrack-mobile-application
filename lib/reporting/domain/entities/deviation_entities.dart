/// This file contains the entities related to Deviation Trends.
///
library;


import 'package:equatable/equatable.dart';
import 'reporting_enums.dart';

/// Represents the deviation trend of a specific variable on an equipment.
class DeviationTrend extends Equatable {
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
    parameterName, equipmentId, environmentId, unit, direction,
    evaluatedReadings, timeInRangePercent, deviationCount, criticalDeviationCount,
  ];
}

/// Extension to calculate the severity of a [DeviationTrend] based on its counts.
extension DeviationTrendSeverity on DeviationTrend {
  /// Calculates the severity level based on the evaluated readings and deviation counts.
  DeviationSeverity get severity {
    if (evaluatedReadings == 0) return DeviationSeverity.noData;
    if (criticalDeviationCount > 0) return DeviationSeverity.critical;
    if (deviationCount > 0) return DeviationSeverity.warning;
    return DeviationSeverity.onTrack;
  }
}