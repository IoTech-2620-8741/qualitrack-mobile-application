/// JSON model of a deviation trend (`DeviationTrendResource`).
library;

import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/deviation_entities.dart';
import '../../domain/entities/reporting_enums.dart';

/// A [DeviationTrend] read from the REST API.
class DeviationTrendModel extends DeviationTrend {
  const DeviationTrendModel({
    required super.parameterName,
    required super.equipmentId,
    required super.direction,
    super.environmentId,
    super.unit,
    super.evaluatedReadings,
    super.timeInRangePercent,
    super.deviationCount,
    super.criticalDeviationCount,
  });

  factory DeviationTrendModel.fromJson(Map<String, dynamic> json) => DeviationTrendModel(
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
