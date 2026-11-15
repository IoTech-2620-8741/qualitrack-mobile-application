/// Public entry point of the Equipment Management context. Other bounded
/// contexts read the equipment through [EquipmentApi] and never import the
/// domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/equipment_facade_service.dart';
import '../domain/entities/equipment.dart';

export '../domain/entities/equipment.dart';
export '../domain/entities/equipment_status.dart';
export '../domain/entities/iot_device_type.dart';

class EquipmentApi {
  const EquipmentApi(this._equipmentService);

  final EquipmentFacadeService _equipmentService;

  /// Equipment of the laboratory ordered by name.
  Future<List<Equipment>> getEquipments(LaboratoryId laboratoryId) => _equipmentService.getEquipments(laboratoryId);

  Future<Equipment> getEquipment(LaboratoryId laboratoryId, int equipmentId) =>
      _equipmentService.getEquipment(laboratoryId, equipmentId);
}
