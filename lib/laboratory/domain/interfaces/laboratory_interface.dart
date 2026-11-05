import '../../../common/domain/value_objects.dart';
import '../entities/lab_environment.dart';
import '../entities/laboratory.dart';
import '../entities/pharmaceutical_product.dart';
import '../entities/staff_member.dart';

/// Contract of the laboratory repository: what can be read about a laboratory,
/// not how. Implemented by the infrastructure layer.
abstract interface class LaboratoryInterface {
  Future<Laboratory> getLaboratory(LaboratoryId id);
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id);
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id, int environmentId);
  Future<List<StaffMember>> getStaff(LaboratoryId id);
}
