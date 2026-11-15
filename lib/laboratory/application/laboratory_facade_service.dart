import '../../common/application/bounded_concurrency.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/lab_environment.dart';
import '../domain/entities/laboratory.dart';
import '../domain/entities/product_catalog.dart';
import '../domain/interfaces/laboratory_interface.dart';
import '../domain/logic/laboratory_logic.dart';

/// Use cases of Laboratory Management exposed to the presentation layer. It
/// only orchestrates: the rules live in [LaboratoryLogic] and the data access
/// behind [LaboratoryInterface].
class LaboratoryFacadeService with LaboratoryLogic {
  const LaboratoryFacadeService({required LaboratoryInterface repository}) : _repository = repository;

  final LaboratoryInterface _repository;

  Future<Laboratory> getLaboratory(LaboratoryId id) => _repository.getLaboratory(id);

  /// Environments of the laboratory ordered by code.
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id) async =>
      sortByCode(await _repository.getEnvironments(id));

  /// Products of every environment of the laboratory, ordered by name.
  Future<ProductCatalog> getProductCatalog(LaboratoryId id) async {
    final environments = await getEnvironments(id);
    final products = await loadAll(
      environments.map((environment) => environment.id),
      (environmentId) => _repository.getProducts(id, environmentId),
    );
    return ProductCatalog(environments: environments, products: sortByName(products));
  }

  Future<Map<int, String>> getUserDirectory(LaboratoryId id) async => userDirectoryOf(await _repository.getStaff(id));
}
