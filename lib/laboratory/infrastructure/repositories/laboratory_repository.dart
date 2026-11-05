import '../../../common/domain/value_objects.dart';
import '../../domain/entities/lab_environment.dart';
import '../../domain/entities/laboratory.dart';
import '../../domain/entities/pharmaceutical_product.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/interfaces/laboratory_interface.dart';
import '../data_sources/laboratory_remote_data_provider.dart';

/// Implements [LaboratoryInterface] with the REST API. There is no offline
/// cache: every read goes to the remote data provider. Rows of another
/// laboratory are dropped.
class LaboratoryRepository implements LaboratoryInterface {
  const LaboratoryRepository({required LaboratoryRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final LaboratoryRemoteDataProvider _remote;

  @override
  Future<Laboratory> getLaboratory(LaboratoryId id) => _remote.getLaboratory(id.value);

  @override
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id) async => List<LabEnvironment>.of(
    (await _remote.getEnvironments(id.value)).where((e) => e.laboratoryId == id.value),
    growable: false,
  );

  @override
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id, int environmentId) async =>
      List<PharmaceuticalProduct>.of(
        (await _remote.getProducts(id.value, environmentId)).where((p) => p.environmentId == environmentId),
        growable: false,
      );

  @override
  Future<List<StaffMember>> getStaff(LaboratoryId id) async => List<StaffMember>.of(
    (await _remote.getStaff(id.value)).where((s) => s.laboratoryId == id.value),
    growable: false,
  );
}
