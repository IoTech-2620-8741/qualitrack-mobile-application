import '../../shared/domain/value_objects.dart';
import '../domain/equipment.dart';

class GetEquipments {
  const GetEquipments(this._repository);

  final EquipmentRepository _repository;

  Future<List<Equipment>> call(LaboratoryId laboratoryId) async {
    final items = await _repository.getByLaboratory(laboratoryId);
    return [...items]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

class GetEquipment {
  const GetEquipment(this._repository);

  final EquipmentRepository _repository;

  Future<Equipment> call(LaboratoryId laboratoryId, int equipmentId) =>
      _repository.getById(laboratoryId, equipmentId);
}

/// Maintenance is registered per environment; equipment that was never
/// located in an environment has no maintenance history.
class GetMaintenanceHistory {
  const GetMaintenanceHistory(this._repository);

  final EquipmentRepository _repository;

  Future<List<MaintenanceRecord>> call(LaboratoryId laboratoryId, Equipment equipment) async {
    final environmentId = equipment.environmentId;
    if (environmentId == null) return const [];
    final records = await _repository.getMaintenance(laboratoryId, environmentId, equipment.id);
    return [...records]..sort((a, b) {
      final left = a.maintenanceDate;
      final right = b.maintenanceDate;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

class GetBpmConfigs {
  const GetBpmConfigs(this._repository);

  final EquipmentRepository _repository;

  Future<List<BpmParameterConfig>> call(LaboratoryId laboratoryId, int equipmentId) =>
      _repository.getBpmConfigs(laboratoryId, equipmentId);
}
