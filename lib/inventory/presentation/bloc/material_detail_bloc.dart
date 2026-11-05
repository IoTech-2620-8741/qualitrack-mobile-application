import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/api/index.dart';
import '../../../common/domain/failure.dart';
import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/application/section.dart';
import '../../application/inventory_facade_service.dart';
import '../../domain/entities/inventory_material.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/inventory_receipt.dart';
import '../../domain/entities/material_usage.dart';

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
    required LaboratoryApi laboratoryApi,
    required InventoryFacadeService inventoryService,
    required LaboratoryId Function() laboratoryId,
  }) : _laboratoryApi = laboratoryApi,
       _inventoryService = inventoryService,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<MaterialDetailRequested>(_onRequested);
  }

  final int materialId;

  /// Environment of the material when it is known (from the list); otherwise
  /// the material is looked up in every environment.
  final int? environmentId;
  final LaboratoryApi _laboratoryApi;
  final InventoryFacadeService _inventoryService;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(MaterialDetailRequested event, Emitter<RemoteState<MaterialDetail>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      final environments = await _laboratoryApi.getEnvironments(lab);
      final material = await _find(lab, environments);
      final sections = await Future.wait<Object>([
        Section.load(() => _inventoryService.getReceipts(lab, material)),
        Section.load(() => _inventoryService.getMovements(lab, material)),
        Section.load(() => _inventoryService.getUsages(lab, material)),
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
      emit(state.failed(Failure.from(error)));
    }
  }

  Future<InventoryMaterial> _find(LaboratoryId lab, List<LabEnvironment> environments) async {
    final known = environmentId;
    if (known != null) return _inventoryService.getMaterial(lab, known, materialId);
    final materials = await _inventoryService.getMaterials(lab, environments.map((e) => e.id));
    for (final material in materials) {
      if (material.id == materialId) return material;
    }
    throw const NotFoundFailure(code: 'RAW_MATERIAL_NOT_FOUND');
  }
}
