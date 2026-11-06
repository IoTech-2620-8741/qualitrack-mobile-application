import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/laboratory.dart';

/// `LaboratoryResource`.
class LaboratoryModel extends Laboratory {
  const LaboratoryModel({
    required super.id,
    required super.name,
    super.ruc,
    super.phone,
    super.address,
    super.status,
    super.applicableRegulations,
  });

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) => LaboratoryModel(
    id: Json.requireInt(json, 'id'),
    name: Json.requireString(json, 'name'),
    ruc: Json.optString(json, 'ruc'),
    phone: Json.optString(json, 'phone'),
    address: Json.optString(json, 'address'),
    status: Json.optString(json, 'status'),
    applicableRegulations: Json.stringList(json, 'applicableRegulations'),
  );
}
