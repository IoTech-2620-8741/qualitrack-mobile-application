import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/laboratory.dart';

class LaboratoryDto {
  const LaboratoryDto(this.json);

  final Map<String, dynamic> json;

  Laboratory toDomain() => Laboratory(
    id: Json.requireInt(json, 'id'),
    name: Json.requireString(json, 'name'),
    ruc: Json.optString(json, 'ruc'),
    phone: Json.optString(json, 'phone'),
    address: Json.optString(json, 'address'),
    status: Json.optString(json, 'status'),
    applicableRegulations: Json.stringList(json, 'applicableRegulations'),
  );
}

class ProductDto {
  const ProductDto(this.json);

  final Map<String, dynamic> json;

  PharmaceuticalProduct toDomain() => PharmaceuticalProduct(
    id: Json.requireInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    code: Json.requireString(json, 'code'),
    name: Json.requireString(json, 'name'),
    description: Json.optString(json, 'description'),
    specifications: Json.optString(json, 'specifications'),
    active: Json.optBool(json, 'active') ?? true,
  );
}

class LaboratoryRemoteDataSource {
  const LaboratoryRemoteDataSource(this._client);

  final ApiClient _client;

  Future<LaboratoryDto> getLaboratory(int id) async =>
      LaboratoryDto(Json.asMap(await _client.get('/laboratories/$id')));

  Future<List<ProductDto>> getProducts(int id) async =>
      Json.asList(await _client.get('/laboratories/$id/products')).map(ProductDto.new).toList();
}

class LaboratoryRepositoryImpl implements LaboratoryRepository {
  const LaboratoryRepositoryImpl(this._remote);

  final LaboratoryRemoteDataSource _remote;

  @override
  Future<Laboratory> getLaboratory(LaboratoryId id) async =>
      (await _remote.getLaboratory(id.value)).toDomain();

  @override
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id) async {
    final dtos = await _remote.getProducts(id.value);
    return dtos
        .map((dto) => dto.toDomain())
        .where((product) => product.laboratoryId == id.value)
        .toList(growable: false);
  }
}
