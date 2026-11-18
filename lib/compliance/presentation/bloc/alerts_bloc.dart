import '../../../common/domain/failure.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/api/index.dart';
import '../../../laboratory/api/index.dart';
import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../tracking/api/index.dart' show MetricThreshold, MonitoredMetric, TelemetryApi;
import '../../application/alert_thresholds.dart';
import '../../application/compliance_facade_service.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/alert_summary.dart';
import '../../domain/entities/deviation_alert.dart';

enum AlertFilter { open, all, unresolved, acknowledged, resolved, critical }

/// Alerts of the laboratory plus device and environment names for display.
final class AlertsData extends Equatable {
  const AlertsData({
    required this.alerts,
    required this.deviceNames,
    required this.environmentNames,
    this.thresholds = const {},
  });

  final List<DeviationAlert> alerts;
  final Map<int, String> deviceNames;
  final Map<int, String> environmentNames;

  /// The range of each alert's metric in its device's profile, by alert id.
  final Map<int, MetricThreshold> thresholds;

  AlertSummary get summary => AlertSummary.of(alerts);

  @override
  List<Object?> get props => [alerts, deviceNames, environmentNames, thresholds];
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

/// Free-text search over the alerts (variable, device, area).
final class AlertsQueryChanged extends AlertsEvent {
  const AlertsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Only the alerts of one variable (temperature, humidity…); null shows the
/// alerts of every variable.
final class AlertsVariableChanged extends AlertsEvent {
  const AlertsVariableChanged(this.variable);

  final MonitoredMetric? variable;

  @override
  List<Object?> get props => [variable];
}

final class AlertsState extends Equatable {
  const AlertsState({
    this.remote = const RemoteState(),
    this.filter = AlertFilter.open,
    this.query = '',
    this.variable,
  });

  final RemoteState<AlertsData> remote;
  final AlertFilter filter;

  /// Search text; the screen matches it against the displayed names, since
  /// variable labels depend on the language.
  final String query;

  /// The variable the list is narrowed to; null for every variable.
  final MonitoredMetric? variable;

  /// The alerts of the chosen variable, whatever their status.
  List<DeviationAlert> get ofVariable {
    final alerts = remote.data?.alerts ?? const <DeviationAlert>[];
    final only = variable;
    if (only == null) return alerts;
    return alerts.where((a) => MonitoredMetric.fromCode(a.parameterName) == only).toList(growable: false);
  }

  /// How many alerts of the chosen variable each status has, for the filter
  /// menu and the summary card.
  AlertSummary get summary => AlertSummary.of(ofVariable);

  List<DeviationAlert> get visible {
    return ofVariable
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

  /// [everyVariable] clears the variable, which a null [variable] keeps.
  AlertsState copyWith({
    RemoteState<AlertsData>? remote,
    AlertFilter? filter,
    String? query,
    MonitoredMetric? variable,
    bool everyVariable = false,
  }) => AlertsState(
    remote: remote ?? this.remote,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    variable: everyVariable ? null : variable ?? this.variable,
  );

  @override
  List<Object?> get props => [remote, filter, query, variable];
}

/// Alerts of the areas and containers of the laboratory (US: consult alerts
/// from the mobile app).
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({
    required LaboratoryApi laboratoryApi,
    required EquipmentApi equipmentApi,
    required TelemetryApi telemetryApi,
    required ComplianceFacadeService complianceService,
    required LaboratoryId Function() laboratoryId,
  }) : _laboratoryApi = laboratoryApi,
       _equipmentApi = equipmentApi,
       _telemetryApi = telemetryApi,
       _complianceService = complianceService,
       _laboratoryId = laboratoryId,
       super(const AlertsState()) {
    on<AlertsRequested>(_onRequested);
    on<AlertsFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));
    on<AlertsQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<AlertsVariableChanged>(
      (e, emit) => emit(state.copyWith(variable: e.variable, everyVariable: e.variable == null)),
    );
  }

  final LaboratoryApi _laboratoryApi;
  final EquipmentApi _equipmentApi;
  final TelemetryApi _telemetryApi;
  final ComplianceFacadeService _complianceService;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(AlertsRequested event, Emitter<AlertsState> emit) async {
    final current = state.remote;
    emit(state.copyWith(remote: event.refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final laboratoryId = _laboratoryId();
      final results = await Future.wait<Object>([_laboratoryApi.getEnvironments(laboratoryId), _equipmentApi.getEquipments(laboratoryId)]);
      final environments = results[0] as List<LabEnvironment>;
      final equipments = results[1] as List<Equipment>;
      final alerts = await _complianceService.getLaboratoryAlerts(laboratoryId, environments.map((e) => e.id));
      final data = AlertsData(
        alerts: alerts,
        deviceNames: {for (final e in equipments) e.id: e.name},
        environmentNames: {for (final e in environments) e.id: e.name},
        thresholds: await loadAlertThresholds(_telemetryApi, laboratoryId, alerts),
      );
      emit(state.copyWith(remote: state.remote.success(data, empty: alerts.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }
}
