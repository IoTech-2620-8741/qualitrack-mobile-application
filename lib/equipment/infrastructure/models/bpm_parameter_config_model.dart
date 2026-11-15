import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/bpm_parameter_config.dart';

/// `BpmParameterConfigResource`.
class BpmParameterConfigModel extends BpmParameterConfig {
  const BpmParameterConfigModel({
    required super.id,
    required super.equipmentId,
    required super.parameterName,
    super.minValue,
    super.maxValue,
    super.unit,
  });

  factory BpmParameterConfigModel.fromJson(Map<String, dynamic> json) => BpmParameterConfigModel(
    id: Json.requireInt(json, 'id'),
    equipmentId: Json.requireInt(json, 'equipmentId'),
    parameterName: Json.requireString(json, 'parameterName'),
    minValue: Json.optDouble(json, 'minValue'),
    maxValue: Json.optDouble(json, 'maxValue'),
    unit: Json.optString(json, 'unit'),
  );
}
