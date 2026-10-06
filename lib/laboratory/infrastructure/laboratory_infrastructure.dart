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

/// `EnvironmentResource {id, laboratoryId, code, name, description, usage, ...}`.
class EnvironmentDto {
  const EnvironmentDto(this.json);

  final Map<String, dynamic> json;

  int get laboratoryId => Json.requireInt(json, 'laboratoryId');

  LabEnvironment toDomain() => LabEnvironment(
    id: Json.requireInt(json, 'id'),
    code: Json.requireString(json, 'code'),
    name: Json.requireString(json, 'name'),
    description: Json.optString(json, 'description'),
    usage: EnvironmentUsage.fromCode(Json.optString(json, 'usage')),
  );
}

/// `PharmaceuticalProductResource {id, laboratoryId, environmentId, code, name, ...}`.
class ProductDto {
  const ProductDto(this.json);

  final Map<String, dynamic> json;

  PharmaceuticalProduct toDomain() => PharmaceuticalProduct(
    id: Json.requireInt(json, 'id'),
    environmentId: Json.requireInt(json, 'environmentId'),
    code: Json.requireString(json, 'code'),
    name: Json.requireString(json, 'name'),
    description: Json.optString(json, 'description'),
    specifications: Json.optString(json, 'specifications'),
    active: Json.optBool(json, 'active') ?? true,
  );
}

/// `StaffMemberResource {id, laboratoryId, fullName, role, email, active, accessRole, userId}`.
class StaffMemberDto {
  const StaffMemberDto(this.json);

  final Map<String, dynamic> json;

  int get laboratoryId => Json.requireInt(json, 'laboratoryId');

  StaffMember toDomain() => StaffMember(
    id: Json.requireInt(json, 'id'),
    fullName: Json.requireString(json, 'fullName'),
    position: Json.optString(json, 'role'),
    email: Json.optString(json, 'email'),
    active: Json.optBool(json, 'active') ?? true,
    accessRole: Json.optString(json, 'accessRole'),
    userId: Json.optInt(json, 'userId'),
  );
}

class LaboratoryRemoteDataSource {
  const LaboratoryRemoteDataSource(this._client);

  final ApiClient _client;

  Future<LaboratoryDto> getLaboratory(int id) async =>
      LaboratoryDto(Json.asMap(await _client.get('/laboratories/$id')));

  Future<List<EnvironmentDto>> getEnvironments(int id) async =>
      Json.asList(await _client.get('/laboratories/$id/environments')).map(EnvironmentDto.new).toList();

  Future<List<ProductDto>> getProducts(int id, int environmentId) async => Json.asList(
    await _client.get('/laboratories/$id/environments/$environmentId/products'),
  ).map(ProductDto.new).toList();

  Future<List<StaffMemberDto>> getStaff(int id) async =>
      Json.asList(await _client.get('/laboratories/$id/staff')).map(StaffMemberDto.new).toList();
}

class LaboratoryRepositoryImpl implements LaboratoryRepository {
  const LaboratoryRepositoryImpl(this._remote);

  final LaboratoryRemoteDataSource _remote;

  @override
  Future<Laboratory> getLaboratory(LaboratoryId id) async =>
      (await _remote.getLaboratory(id.value)).toDomain();

  @override
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id) async =>
      (await _remote.getEnvironments(id.value))
          .where((dto) => dto.laboratoryId == id.value)
          .map((dto) => dto.toDomain())
          .toList(growable: false);

  @override
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id, int environmentId) async =>
      (await _remote.getProducts(id.value, environmentId))
          .map((dto) => dto.toDomain())
          .where((product) => product.environmentId == environmentId)
          .toList(growable: false);

  @override
  Future<List<StaffMember>> getStaff(LaboratoryId id) async => (await _remote.getStaff(id.value))
      .where((dto) => dto.laboratoryId == id.value)
      .map((dto) => dto.toDomain())
      .toList(growable: false);
}
