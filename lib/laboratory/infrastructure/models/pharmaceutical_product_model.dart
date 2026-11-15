import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/pharmaceutical_product.dart';

/// `PharmaceuticalProductResource {id, laboratoryId, environmentId, code, name, ...}`.
class PharmaceuticalProductModel extends PharmaceuticalProduct {
  const PharmaceuticalProductModel({
    required super.id,
    required super.environmentId,
    required super.code,
    required super.name,
    required super.active,
    super.description,
    super.specifications,
  });

  factory PharmaceuticalProductModel.fromJson(Map<String, dynamic> json) => PharmaceuticalProductModel(
    id: Json.requireInt(json, 'id'),
    environmentId: Json.requireInt(json, 'environmentId'),
    code: Json.requireString(json, 'code'),
    name: Json.requireString(json, 'name'),
    description: Json.optString(json, 'description'),
    specifications: Json.optString(json, 'specifications'),
    active: Json.optBool(json, 'active') ?? true,
  );
}
