import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../tracking/application/telemetry_queries.dart';
import '../../../tracking/domain/telemetry.dart';
import '../../application/equipment_queries.dart';
import '../../domain/equipment.dart';

/// Equipment with its environment and, for IoT devices, the connection
/// status of Tracking (UI composition only).
final class EquipmentOverview extends Equatable {
  const EquipmentOverview({required this.equipment, this.environmentName, this.connection});

  final Equipment equipment;
  final String? environmentName;
  final DeviceConnection? connection;

  bool get needsAttention =>
      equipment.needsAttention || (connection != null && connection!.status == ConnectionStatus.requiresReview);

  @override
  List<Object?> get props => [equipment, environmentName, connection];
}

enum EquipmentFilter { all, attention, iotDevices, operational, maintenance, outOfService, inactive }

sealed class EquipmentListEvent extends Equatable {
  const EquipmentListEvent();

  @override
  List<Object?> get props => [];
}

final class EquipmentListRequested extends EquipmentListEvent {
  const EquipmentListRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class EquipmentQueryChanged extends EquipmentListEvent {
  const EquipmentQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class EquipmentFilterChanged extends EquipmentListEvent {
  const EquipmentFilterChanged(this.filter);

  final EquipmentFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class EquipmentListState extends Equatable {
  const EquipmentListState({this.remote = const RemoteState(), this.query = '', this.filter = EquipmentFilter.all});

  final RemoteState<List<EquipmentOverview>> remote;
  final String query;
  final EquipmentFilter filter;

  List<EquipmentOverview> get visible => (remote.data ?? const <EquipmentOverview>[])
      .where((item) => item.equipment.matches(query) && _passes(item))
      .toList(growable: false);

  bool _passes(EquipmentOverview item) => switch (filter) {
    EquipmentFilter.all => true,
    EquipmentFilter.attention => item.needsAttention,
    EquipmentFilter.iotDevices => item.equipment.isIotDevice,
    EquipmentFilter.operational => item.equipment.status == EquipmentStatus.operational,
    EquipmentFilter.maintenance => item.equipment.status == EquipmentStatus.maintenance,
    EquipmentFilter.outOfService => item.equipment.status == EquipmentStatus.outOfService,
    EquipmentFilter.inactive => item.equipment.status == EquipmentStatus.inactive,
  };

  EquipmentListState copyWith({RemoteState<List<EquipmentOverview>>? remote, String? query, EquipmentFilter? filter}) =>
      EquipmentListState(remote: remote ?? this.remote, query: query ?? this.query, filter: filter ?? this.filter);

  @override
  List<Object?> get props => [remote, query, filter];
}

class EquipmentListBloc extends Bloc<EquipmentListEvent, EquipmentListState> {
  EquipmentListBloc({
    required GetEquipments getEquipments,
    required GetEnvironments getEnvironments,
    required GetDeviceConnections getConnections,
    required LaboratoryId Function() laboratoryId,
  }) : _getEquipments = getEquipments,
       _getEnvironments = getEnvironments,
       _getConnections = getConnections,
       _laboratoryId = laboratoryId,
       super(const EquipmentListState()) {
    on<EquipmentListRequested>(_onRequested);
    on<EquipmentQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<EquipmentFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
  }

  final GetEquipments _getEquipments;
  final GetEnvironments _getEnvironments;
  final GetDeviceConnections _getConnections;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(EquipmentListRequested event, Emitter<EquipmentListState> emit) async {
    final current = state.remote;
    emit(state.copyWith(remote: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final lab = _laboratoryId();
      final results = await Future.wait<Object>([_getEquipments(lab), _getEnvironments(lab)]);
      final equipments = results[0] as List<Equipment>;
      final environments = {for (final e in results[1] as List<LabEnvironment>) e.id: e.name};
      final targets = equipments.map(targetOf).whereType<TelemetryTarget>().toList();
      final connections = await _getConnections(lab, targets);
      final items = [
        for (final e in equipments)
          EquipmentOverview(equipment: e, environmentName: environments[e.environmentId], connection: connections[e.id]),
      ];
      emit(state.copyWith(remote: state.remote.success(items, empty: items.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}
