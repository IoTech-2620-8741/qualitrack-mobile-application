import '../../../common/domain/value_objects.dart';
import '../../domain/entities/bpm_parameter_config.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/maintenance_record.dart';
import '../../domain/interfaces/equipment_interface.dart';
import '../data_sources/equipment_remote_data_provider.dart';

/// Implements [EquipmentInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider.
class EquipmentRepository implements EquipmentInterface {
  const EquipmentRepository({required EquipmentRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final EquipmentRemoteDataProvider _remote;

  @override
  Future<List<Equipment>> getByLaboratory(LaboratoryId laboratoryId) async =>
      // Same defensive filter as the Web DashboardStore.
      List<Equipment>.of(
        (await _remote.getByLaboratory(laboratoryId.value)).where((e) => e.laboratoryId == laboratoryId.value),
        growable: false,
      );

  @override
  Future<Equipment> getById(LaboratoryId laboratoryId, int equipmentId) =>
      _remote.getById(laboratoryId.value, equipmentId);

  @override
  Future<List<MaintenanceRecord>> getMaintenance(LaboratoryId laboratoryId, int environmentId, int equipmentId) =>
      _remote.getMaintenance(laboratoryId.value, environmentId, equipmentId);

  @override
  Future<List<BpmParameterConfig>> getBpmConfigs(LaboratoryId laboratoryId, int equipmentId) =>
      _remote.getBpmConfigs(laboratoryId.value, equipmentId);
}
