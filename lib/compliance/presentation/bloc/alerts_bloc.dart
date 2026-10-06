import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/compliance_queries.dart';
import '../../domain/compliance.dart';

enum AlertFilter { open, all, unresolved, acknowledged, resolved, critical }

/// Alerts of the laboratory plus device and environment names for display.
final class AlertsData extends Equatable {
  const AlertsData({required this.alerts, required this.deviceNames, required this.environmentNames});

  final List<DeviationAlert> alerts;
  final Map<int, String> deviceNames;
  final Map<int, String> environmentNames;

  AlertSummary get summary => AlertSummary.of(alerts);

  @override
  List<Object?> get props => [alerts, deviceNames, environmentNames];
}

sealed class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

final class AlertsRequested extends AlertsEvent {
  const AlertsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class AlertsFilterChanged extends AlertsEvent {
  const AlertsFilterChanged(this.filter);

  final AlertFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class AlertsState extends Equatable {
  const AlertsState({this.remote = const RemoteState(), this.filter = AlertFilter.open});

  final RemoteState<AlertsData> remote;
  final AlertFilter filter;

  List<DeviationAlert> get visible {
    final alerts = remote.data?.alerts ?? const <DeviationAlert>[];
    return alerts
        .where(
          (a) => switch (filter) {
            AlertFilter.open => a.isOpen,
            AlertFilter.all => true,
            AlertFilter.unresolved => a.status == AlertStatus.unresolved,
            AlertFilter.acknowledged => a.status == AlertStatus.acknowledged,
            AlertFilter.resolved => a.status == AlertStatus.resolved,
            AlertFilter.critical => a.isCritical && a.isOpen,
          },
        )
        .toList(growable: false);
  }

  AlertsState copyWith({RemoteState<AlertsData>? remote, AlertFilter? filter}) =>
      AlertsState(remote: remote ?? this.remote, filter: filter ?? this.filter);

  @override
  List<Object?> get props => [remote, filter];
}

/// Alerts of the areas and containers of the laboratory (US: consult alerts
/// from the mobile app).
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({
    required GetEnvironments getEnvironments,
    required GetEquipments getEquipments,
    required GetLaboratoryAlerts getAlerts,
    required LaboratoryId Function() laboratoryId,
  }) : _getEnvironments = getEnvironments,
       _getEquipments = getEquipments,
       _getAlerts = getAlerts,
       _laboratoryId = laboratoryId,
       super(const AlertsState()) {
    on<AlertsRequested>(_onRequested);
    on<AlertsFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
  }

  final GetEnvironments _getEnvironments;
  final GetEquipments _getEquipments;
  final GetLaboratoryAlerts _getAlerts;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(AlertsRequested event, Emitter<AlertsState> emit) async {
    final current = state.remote;
    emit(state.copyWith(remote: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final laboratoryId = _laboratoryId();
      final results = await Future.wait<Object>([_getEnvironments(laboratoryId), _getEquipments(laboratoryId)]);
      final environments = results[0] as List<LabEnvironment>;
      final equipments = results[1] as List<Equipment>;
      final alerts = await _getAlerts(laboratoryId, environments.map((e) => e.id));
      final data = AlertsData(
        alerts: alerts,
        deviceNames: {for (final e in equipments) e.id: e.name},
        environmentNames: {for (final e in environments) e.id: e.name},
      );
      emit(state.copyWith(remote: state.remote.success(data, empty: alerts.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}
