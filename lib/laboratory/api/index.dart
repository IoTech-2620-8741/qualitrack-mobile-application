/// Public entry point of the Laboratory Management context. Other bounded
/// contexts read the laboratory through [LaboratoryApi] and never import the
/// domain or the infrastructure directly.
library;

import '../../common/domain/value_objects.dart';
import '../application/laboratory_facade_service.dart';
import '../domain/entities/lab_environment.dart';
import '../domain/entities/laboratory.dart';

export '../domain/entities/environment_usage.dart';
export '../domain/entities/lab_environment.dart';
export '../domain/entities/laboratory.dart';

class LaboratoryApi {
  const LaboratoryApi(this._laboratoryService);

  final LaboratoryFacadeService _laboratoryService;

  Future<Laboratory> getLaboratory(LaboratoryId id) => _laboratoryService.getLaboratory(id);

  /// Environments of the laboratory ordered by code.
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id) => _laboratoryService.getEnvironments(id);

  /// Names of the people of the laboratory by user account.
  Future<Map<int, String>> getUserDirectory(LaboratoryId id) => _laboratoryService.getUserDirectory(id);
}
