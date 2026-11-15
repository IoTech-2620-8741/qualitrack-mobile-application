import '../../common/domain/value_objects.dart';
import '../domain/entities/bpm_parameter_config.dart';
import '../domain/entities/equipment.dart';
import '../domain/entities/maintenance_record.dart';
import '../domain/interfaces/equipment_interface.dart';
import '../domain/logic/equipment_logic.dart';

/// Use cases of Equipment Management exposed to the presentation layer. It only
/// orchestrates: the rules live in [EquipmentLogic] and the data access behind
/// [EquipmentInterface].
class EquipmentFacadeService with EquipmentLogic {
  const EquipmentFacadeService({required EquipmentInterface repository}) : _repository = repository;

  final EquipmentInterface _repository;

  /// Equipment of the laboratory ordered by name.
  Future<List<Equipment>> getEquipments(LaboratoryId laboratoryId) async =>
      sortByName(await _repository.getByLaboratory(laboratoryId));

  Future<Equipment> getEquipment(LaboratoryId laboratoryId, int equipmentId) =>
      _repository.getById(laboratoryId, equipmentId);

  /// Maintenance is registered per environment; equipment that was never
  /// located in an environment has no maintenance history.
  Future<List<MaintenanceRecord>> getMaintenanceHistory(LaboratoryId laboratoryId, Equipment equipment) async {
    final environmentId = equipment.environmentId;
    if (environmentId == null) return const [];
    return sortMaintenanceNewestFirst(await _repository.getMaintenance(laboratoryId, environmentId, equipment.id));
  }

  Future<List<BpmParameterConfig>> getBpmConfigs(LaboratoryId laboratoryId, int equipmentId) =>
      _repository.getBpmConfigs(laboratoryId, equipmentId);
}
