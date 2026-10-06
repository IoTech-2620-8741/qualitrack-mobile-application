import '../../shared/application/bounded_concurrency.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/laboratory.dart';

class GetLaboratory {
  const GetLaboratory(this._repository);

  final LaboratoryRepository _repository;

  Future<Laboratory> call(LaboratoryId id) => _repository.getLaboratory(id);
}

/// Environments of the laboratory ordered by code.
class GetEnvironments {
  const GetEnvironments(this._repository);

  final LaboratoryRepository _repository;

  Future<List<LabEnvironment>> call(LaboratoryId id) async =>
      [...await _repository.getEnvironments(id)]..sort(LabEnvironment.compare);
}

/// Products of every environment of the laboratory, ordered by name.
class GetProductCatalog {
  const GetProductCatalog(this._repository);

  final LaboratoryRepository _repository;

  Future<ProductCatalog> call(LaboratoryId id) async {
    final environments = [...await _repository.getEnvironments(id)]..sort(LabEnvironment.compare);
    final products = await loadAll(
      environments.map((environment) => environment.id),
      (environmentId) => _repository.getProducts(id, environmentId),
    );
    products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ProductCatalog(environments: environments, products: products);
  }
}

/// Names of the people of the laboratory by user account, used to show who
/// acknowledged an alert or registered an action instead of a bare id.
class GetUserDirectory {
  const GetUserDirectory(this._repository);

  final LaboratoryRepository _repository;

  Future<Map<int, String>> call(LaboratoryId id) async => {
    for (final member in await _repository.getStaff(id))
      if (member.userId != null) member.userId!: member.fullName,
  };
}
