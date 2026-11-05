/// This file contains the Data Transfer Objects (DTOs) for Deviation data.
///
///
library;


import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/deviation_entities.dart';
import '../../domain/entities/reporting_enums.dart';

/// DTO for the Deviation Trend response.
class DeviationTrendDto {
  const DeviationTrendDto(this.json);

  final Map<String, dynamic> json;

  /// Converts the raw JSON map into a [DeviationTrend] domain entity.
  DeviationTrend toDomain() => DeviationTrend(
    parameterName: Json.requireString(json, 'parameterName'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    environmentId: Json.optInt(json, 'environmentId'),
    unit: Json.optString(json, 'unit'),
    direction: TrendDirection.fromCode(Json.optString(json, 'trendDirection')),
    evaluatedReadings: Json.optInt(json, 'evaluatedReadings') ?? 0,
    timeInRangePercent: Json.optDouble(json, 'timeInRangePercent'),
    deviationCount: Json.optInt(json, 'deviationCount') ?? 0,
    criticalDeviationCount: Json.optInt(json, 'criticalDeviationCount') ?? 0,
  );
}