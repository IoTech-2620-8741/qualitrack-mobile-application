import '../../../common/domain/value_objects.dart';
import '../entities/bpm_parameter_config.dart';
import '../entities/equipment.dart';
import '../entities/maintenance_record.dart';

/// Contract of the equipment repository: what can be read about the equipment
/// of a laboratory, not how. Implemented by the infrastructure layer.
abstract interface class EquipmentInterface {
  Future<List<Equipment>> getByLaboratory(LaboratoryId laboratoryId);
  Future<Equipment> getById(LaboratoryId laboratoryId, int equipmentId);
  Future<List<MaintenanceRecord>> getMaintenance(LaboratoryId laboratoryId, int environmentId, int equipmentId);
  Future<List<BpmParameterConfig>> getBpmConfigs(LaboratoryId laboratoryId, int equipmentId);
}
