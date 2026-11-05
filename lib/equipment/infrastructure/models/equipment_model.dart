import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_status.dart';
import '../../domain/entities/iot_device_type.dart';

/// `EquipmentResource {id, laboratoryId, environmentId, name, type, model,
/// serialNumber, status, deviceType, sensorExternalId, firmwareVersion}`.
class EquipmentModel extends Equipment {
  const EquipmentModel({
    required super.id,
    required super.laboratoryId,
    required super.name,
    required super.status,
    super.environmentId,
    super.rawStatus,
    super.type,
    super.model,
    super.serialNumber,
    super.deviceType,
    super.sensorExternalId,
    super.firmwareVersion,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    final status = Json.optString(json, 'status');
    return EquipmentModel(
      id: Json.requireInt(json, 'id'),
      laboratoryId: Json.requireInt(json, 'laboratoryId'),
      environmentId: Json.optInt(json, 'environmentId'),
      name: Json.requireString(json, 'name'),
      type: Json.optString(json, 'type'),
      model: Json.optString(json, 'model'),
      serialNumber: Json.optString(json, 'serialNumber'),
      status: EquipmentStatus.fromCode(status),
      rawStatus: status,
      deviceType: IotDeviceType.fromCode(Json.optString(json, 'deviceType')),
      sensorExternalId: Json.optString(json, 'sensorExternalId'),
      firmwareVersion: Json.optString(json, 'firmwareVersion'),
    );
  }
}
