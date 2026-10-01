import '../../shared/domain/value_objects.dart';
import '../domain/laboratory.dart';

class GetLaboratory {
  const GetLaboratory(this._repository);

  final LaboratoryRepository _repository;

  Future<Laboratory> call(LaboratoryId id) => _repository.getLaboratory(id);
}

class GetProducts {
  const GetProducts(this._repository);

  final LaboratoryRepository _repository;

  Future<List<PharmaceuticalProduct>> call(LaboratoryId id) async {
    final products = await _repository.getProducts(id);
    return [...products]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
