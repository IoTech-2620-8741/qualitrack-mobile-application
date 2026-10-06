import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/application/laboratory_queries.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/inventory_queries.dart';
import '../../domain/inventory.dart';

enum InventoryFilter { all, belowMinimum, blockedStock }

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryRequested extends InventoryEvent {
  const InventoryRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class InventoryQueryChanged extends InventoryEvent {
  const InventoryQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class InventoryFilterChanged extends InventoryEvent {
  const InventoryFilterChanged(this.filter);

  final InventoryFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class InventoryState extends Equatable {
  const InventoryState({
    this.remote = const RemoteState(),
    this.query = '',
    this.filter = InventoryFilter.all,
    this.environmentNames = const {},
  });

  final RemoteState<List<InventoryMaterial>> remote;
  final Map<int, String> environmentNames;
  final String query;
  final InventoryFilter filter;

  int get belowMinimumCount =>
      (remote.data ?? const <InventoryMaterial>[]).where((m) => m.isBelowMinimum).length;

  List<InventoryMaterial> get visible => (remote.data ?? const <InventoryMaterial>[])
      .where((m) => m.matches(query))
      .where((m) => switch (filter) {
        InventoryFilter.all => true,
        InventoryFilter.belowMinimum => m.isBelowMinimum,
        InventoryFilter.blockedStock => m.hasBlockedStock,
      })
      .toList(growable: false);

  InventoryMaterial? byId(int id) {
    for (final m in remote.data ?? const <InventoryMaterial>[]) {
      if (m.id == id) return m;
    }
    return null;
  }

  InventoryState copyWith({
    RemoteState<List<InventoryMaterial>>? remote,
    String? query,
    InventoryFilter? filter,
    Map<int, String>? environmentNames,
  }) => InventoryState(
    remote: remote ?? this.remote,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    environmentNames: environmentNames ?? this.environmentNames,
  );

  @override
  List<Object?> get props => [remote, query, filter, environmentNames];
}

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({
    required GetEnvironments getEnvironments,
    required GetInventoryMaterials getMaterials,
    required LaboratoryId Function() laboratoryId,
  }) : _getEnvironments = getEnvironments,
       _getMaterials = getMaterials,
       _laboratoryId = laboratoryId,
       super(const InventoryState()) {
    on<InventoryRequested>(_onRequested);
    on<InventoryQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<InventoryFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
  }

  final GetEnvironments _getEnvironments;
  final GetInventoryMaterials _getMaterials;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(InventoryRequested event, Emitter<InventoryState> emit) async {
    final current = state.remote;
    emit(state.copyWith(
      remote: event.refresh && current.hasData ? current.refreshingState() : current.loading(),
    ));
    try {
      final lab = _laboratoryId();
      final environments = await _getEnvironments(lab);
      final materials = await _getMaterials(lab, environments.map((e) => e.id));
      emit(state.copyWith(
        remote: state.remote.success(materials, empty: materials.isEmpty),
        environmentNames: {for (final e in environments) e.id: e.name},
      ));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}
