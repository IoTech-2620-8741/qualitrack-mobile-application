import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/environment_usage.dart';
import '../../domain/entities/lab_environment.dart';

/// `EnvironmentResource {id, laboratoryId, code, name, description, usage, ...}`.
class LabEnvironmentModel extends LabEnvironment {
  const LabEnvironmentModel({
    required super.id,
    required this.laboratoryId,
    required super.code,
    required super.name,
    super.description,
    super.usage,
  });

  factory LabEnvironmentModel.fromJson(Map<String, dynamic> json) => LabEnvironmentModel(
    id: Json.requireInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    code: Json.requireString(json, 'code'),
    name: Json.requireString(json, 'name'),
    description: Json.optString(json, 'description'),
    usage: EnvironmentUsage.fromCode(Json.optString(json, 'usage')),
  );

  /// Laboratory the backend says the environment belongs to.
  final int laboratoryId;
}
