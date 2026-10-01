import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.receipts = const Section.empty(),
    this.movements = const Section.empty(),
  });

  final InventoryMaterial material;
  final Section<InventoryReceipt> receipts;
  final Section<InventoryMovement> movements;

  @override
  List<Object?> get props => [material, receipts, movements];
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
    required GetInventoryMaterials getMaterials,
    required GetMaterialReceipts getReceipts,
    required GetInventoryMovements getMovements,
    required LaboratoryId Function() laboratoryId,
  }) : _getMaterials = getMaterials,
       _getReceipts = getReceipts,
       _getMovements = getMovements,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<MaterialDetailRequested>(_onRequested);
  }

  final int materialId;
  final GetInventoryMaterials _getMaterials;
  final GetMaterialReceipts _getReceipts;
  final GetInventoryMovements _getMovements;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(
    MaterialDetailRequested event,
    Emitter<RemoteState<MaterialDetail>> emit,
  ) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      // There is no GET-by-id endpoint for inventory materials.
      final materials = await _getMaterials(lab);
      final material = materials.where((m) => m.id == materialId).firstOrNull;
      if (material == null) throw const NotFoundFailure(code: 'RAW_MATERIAL_NOT_FOUND');
      final sections = await Future.wait<Object>([
        Section.load(() => _getReceipts(lab, materialId)),
        Section.load(() => _getMovements(lab, materialId)),
      ]);
      emit(state.success(MaterialDetail(
        material: material,
        receipts: sections[0] as Section<InventoryReceipt>,
        movements: sections[1] as Section<InventoryMovement>,
      )));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }
}
