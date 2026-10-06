import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../application/inventory_queries.dart';
import '../../domain/inventory.dart';

final class MaterialDetail extends Equatable {
  const MaterialDetail({
    required this.material,
    this.environmentName,
    this.receipts = const Section.empty(),
    this.movements = const Section.empty(),
    this.usages = const Section.empty(),
  });

  final InventoryMaterial material;
  final String? environmentName;
  final Section<InventoryReceipt> receipts;
  final Section<InventoryMovement> movements;
  final Section<MaterialUsage> usages;

  @override
  List<Object?> get props => [material, environmentName, receipts, movements, usages];
}

final class MaterialDetailRequested extends Equatable {
  const MaterialDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class MaterialDetailBloc extends Bloc<MaterialDetailRequested, RemoteState<MaterialDetail>> {
  MaterialDetailBloc({
    required this.materialId,
    required this.environmentId,
    required GetEnvironments getEnvironments,
    required GetInventoryMaterials getMaterials,
    required GetInventoryMaterial getMaterial,
    required GetMaterialReceipts getReceipts,
    required GetInventoryMovements getMovements,
    required GetMaterialUsages getUsages,
    required LaboratoryId Function() laboratoryId,
  }) : _getEnvironments = getEnvironments,
       _getMaterials = getMaterials,
       _getMaterial = getMaterial,
       _getReceipts = getReceipts,
       _getMovements = getMovements,
       _getUsages = getUsages,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<MaterialDetailRequested>(_onRequested);
  }

  final int materialId;

  /// Environment of the material when it is known (from the list); otherwise
  /// the material is looked up in every environment.
  final int? environmentId;
  final GetEnvironments _getEnvironments;
  final GetInventoryMaterials _getMaterials;
  final GetInventoryMaterial _getMaterial;
  final GetMaterialReceipts _getReceipts;
  final GetInventoryMovements _getMovements;
  final GetMaterialUsages _getUsages;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(MaterialDetailRequested event, Emitter<RemoteState<MaterialDetail>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      final environments = await _getEnvironments(lab);
      final material = await _find(lab, environments);
      final sections = await Future.wait<Object>([
        Section.load(() => _getReceipts(lab, material)),
        Section.load(() => _getMovements(lab, material)),
        Section.load(() => _getUsages(lab, material)),
      ]);
      String? environmentName;
      for (final environment in environments) {
        if (environment.id == material.environmentId) environmentName = environment.displayName;
      }
      emit(state.success(MaterialDetail(
        material: material,
        environmentName: environmentName,
        receipts: sections[0] as Section<InventoryReceipt>,
        movements: sections[1] as Section<InventoryMovement>,
        usages: sections[2] as Section<MaterialUsage>,
      )));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }

  Future<InventoryMaterial> _find(LaboratoryId lab, List<LabEnvironment> environments) async {
    final known = environmentId;
    if (known != null) return _getMaterial(lab, known, materialId);
    final materials = await _getMaterials(lab, environments.map((e) => e.id));
    for (final material in materials) {
      if (material.id == materialId) return material;
    }
    throw const NotFoundFailure(code: 'RAW_MATERIAL_NOT_FOUND');
  }
}
