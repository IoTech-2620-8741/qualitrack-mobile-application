import '../entities/lab_environment.dart';
import '../entities/pharmaceutical_product.dart';
import '../entities/staff_member.dart';

/// Business rules of Laboratory Management. Pure Dart: the facade applies them
/// on top of the repository.
mixin LaboratoryLogic {
  /// Environments ordered by code.
  List<LabEnvironment> sortByCode(List<LabEnvironment> environments) =>
      [...environments]..sort(LabEnvironment.compare);

  /// Products ordered by name.
  List<PharmaceuticalProduct> sortByName(List<PharmaceuticalProduct> products) =>
      [...products]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Names of the people of the laboratory by user account, used to show who
  /// acknowledged an alert or registered an action instead of a bare id.
  Map<int, String> userDirectoryOf(List<StaffMember> staff) => {
    for (final member in staff)
      if (member.userId != null) member.userId!: member.fullName,
  };
}
