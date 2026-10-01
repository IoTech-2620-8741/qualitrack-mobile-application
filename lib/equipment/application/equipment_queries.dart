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

  Future<Equipment> call(int equipmentId) => _repository.getById(equipmentId);
}

class GetMaintenanceHistory {
  const GetMaintenanceHistory(this._repository);

  final EquipmentRepository _repository;

  Future<List<MaintenanceRecord>> call(int equipmentId) async {
    final records = await _repository.getMaintenance(equipmentId);
    return [...records]..sort((a, b) {
      final left = a.maintenanceDate;
      final right = b.maintenanceDate;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }
}

class GetBpmConfigs {
  const GetBpmConfigs(this._repository);

  final EquipmentRepository _repository;

  Future<List<BpmParameterConfig>> call(int equipmentId) => _repository.getBpmConfigs(equipmentId);
}
