import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/view_status.dart';
import '../../application/telemetry_queries.dart';
import '../../domain/telemetry.dart';

/// Telemetry of one equipment at a point in time.
final class TelemetrySnapshot extends Equatable {
  const TelemetrySnapshot({
    required this.equipmentId,
    required this.status,
    required this.readings,
    required this.history,
    required this.limits,
    required this.fetchedAt,
    this.historyFailure,
  });

  final int equipmentId;
  final EquipmentTelemetryStatus status;
  final List<ParameterReading> readings;
  final List<TelemetryHistoryPoint> history;
  final List<BpmParameterConfig> limits;
  final DateTime fetchedAt;
  final Failure? historyFailure;

  List<TelemetryHistoryPoint> get anomalies => TelemetryAnalysis.anomalies(history);

  List<String> get chartParameters {
    final fromHistory = TelemetryAnalysis.parameters(history);
    return fromHistory;
  }

  BpmParameterConfig? limitFor(String parameter) {
    for (final limit in limits) {
      if (limit.appliesTo(parameter)) return limit;
    }
    return null;
  }

  String? unitFor(String parameter) {
    for (final r in readings) {
      if (r.latest.parameterName == parameter) return r.latest.unit;
    }
    return limitFor(parameter)?.unit;
  }

  TelemetrySnapshot copyWith({
    EquipmentTelemetryStatus? status,
    List<ParameterReading>? readings,
    List<TelemetryHistoryPoint>? history,
    DateTime? fetchedAt,
    Failure? historyFailure,
    bool clearHistoryFailure = false,
  }) => TelemetrySnapshot(
    equipmentId: equipmentId,
    status: status ?? this.status,
    readings: readings ?? this.readings,
    history: history ?? this.history,
    limits: limits,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    historyFailure: clearHistoryFailure ? null : (historyFailure ?? this.historyFailure),
  );

  @override
  List<Object?> get props => [equipmentId, status, readings, history, limits, fetchedAt, historyFailure];
}

sealed class TelemetryEvent extends Equatable {
  const TelemetryEvent();

  @override
  List<Object?> get props => [];
}

final class TelemetryStarted extends TelemetryEvent {
  const TelemetryStarted({this.equipmentId});

  final int? equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class TelemetryEquipmentSelected extends TelemetryEvent {
  const TelemetryEquipmentSelected(this.equipmentId);

  final int equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class TelemetryRefreshRequested extends TelemetryEvent {
  const TelemetryRefreshRequested();
}

final class TelemetryPollTicked extends TelemetryEvent {
  const TelemetryPollTicked();
}

final class TelemetryPollingPaused extends TelemetryEvent {
  const TelemetryPollingPaused();
}

final class TelemetryPollingResumed extends TelemetryEvent {
  const TelemetryPollingResumed();
}

final class TelemetryParameterSelected extends TelemetryEvent {
  const TelemetryParameterSelected(this.parameter);

  final String parameter;

  @override
  List<Object?> get props => [parameter];
}

final class TelemetryWindowSelected extends TelemetryEvent {
  const TelemetryWindowSelected(this.window);

  final TelemetryWindow window;

  @override
  List<Object?> get props => [window];
}

final class TelemetryState extends Equatable {
  const TelemetryState({
    this.equipments = const RemoteState(),
    this.selectedEquipmentId,
    this.snapshot = const RemoteState(),
    this.selectedParameter,
    this.window = TelemetryWindow.oneHour,
    this.polling = false,
  });

  final RemoteState<List<Equipment>> equipments;
  final int? selectedEquipmentId;
  final RemoteState<TelemetrySnapshot> snapshot;
  final String? selectedParameter;
  final TelemetryWindow window;
  final bool polling;

  Equipment? get selectedEquipment {
    for (final e in equipments.data ?? const <Equipment>[]) {
      if (e.id == selectedEquipmentId) return e;
    }
    return null;
  }

  /// Parameter shown in the chart (explicit selection or the first available).
  String? get chartParameter {
    final params = snapshot.data?.chartParameters ?? const <String>[];
    if (params.isEmpty) return null;
    return params.contains(selectedParameter) ? selectedParameter : params.first;
  }

  List<TelemetryWindow> get availableWindows {
    final data = snapshot.data;
    final parameter = chartParameter;
    if (data == null || parameter == null) return const [];
    return TelemetryAnalysis.availableWindows(data.history, parameter);
  }

  TelemetryWindow? get effectiveWindow {
    final windows = availableWindows;
    if (windows.isEmpty) return null;
    return windows.contains(window) ? window : windows.last;
  }

  List<TelemetryHistoryPoint> get chartSeries {
    final data = snapshot.data;
    final parameter = chartParameter;
    final w = effectiveWindow;
    if (data == null || parameter == null || w == null) return const [];
    return TelemetryAnalysis.series(data.history, parameter, w);
  }

  TelemetryState copyWith({
    RemoteState<List<Equipment>>? equipments,
    int? selectedEquipmentId,
    RemoteState<TelemetrySnapshot>? snapshot,
    String? selectedParameter,
    TelemetryWindow? window,
    bool? polling,
  }) => TelemetryState(
    equipments: equipments ?? this.equipments,
    selectedEquipmentId: selectedEquipmentId ?? this.selectedEquipmentId,
    snapshot: snapshot ?? this.snapshot,
    selectedParameter: selectedParameter ?? this.selectedParameter,
    window: window ?? this.window,
    polling: polling ?? this.polling,
  );

  @override
  List<Object?> get props => [equipments, selectedEquipmentId, snapshot, selectedParameter, window, polling];
}

/// Live telemetry with responsible polling: status and latest measurements
/// every [pollInterval]; history every [historyEveryTicks] ticks. The timer is
/// cancelled when the BLoC is closed or polling is paused.
class TelemetryDashboardBloc extends Bloc<TelemetryEvent, TelemetryState> {
  TelemetryDashboardBloc({
    required GetEquipments getEquipments,
    required GetTelemetryStatus getStatus,
    required GetLatestTelemetry getLatest,
    required GetTelemetryHistory getHistory,
    required GetBpmConfigs getBpmConfigs,
    required LaboratoryId Function() laboratoryId,
    DateTime Function()? clock,
    this.pollInterval = const Duration(seconds: 15),
    this.historyEveryTicks = 4,
    this.historyLookback = const Duration(hours: 24),
  }) : _getEquipments = getEquipments,
       _getStatus = getStatus,
       _getLatest = getLatest,
       _getHistory = getHistory,
       _getBpmConfigs = getBpmConfigs,
       _laboratoryId = laboratoryId,
       _clock = clock ?? DateTime.now,
       super(const TelemetryState()) {
    on<TelemetryStarted>(_onStarted);
    on<TelemetryEquipmentSelected>(_onEquipmentSelected);
    on<TelemetryRefreshRequested>((event, emit) => _refresh(emit, includeHistory: true));
    on<TelemetryPollTicked>(_onTick);
    on<TelemetryPollingPaused>((event, emit) {
      _paused = true;
      _stopTimer();
      emit(state.copyWith(polling: false));
    });
    on<TelemetryPollingResumed>((event, emit) async {
      _paused = false;
      if (state.selectedEquipmentId == null) return;
      _startTimer();
      emit(state.copyWith(polling: true));
      await _refresh(emit, includeHistory: true);
    });
    on<TelemetryParameterSelected>((e, emit) => emit(state.copyWith(selectedParameter: e.parameter)));
    on<TelemetryWindowSelected>((e, emit) => emit(state.copyWith(window: e.window)));
  }

  final GetEquipments _getEquipments;
  final GetTelemetryStatus _getStatus;
  final GetLatestTelemetry _getLatest;
  final GetTelemetryHistory _getHistory;
  final GetBpmConfigs _getBpmConfigs;
  final LaboratoryId Function() _laboratoryId;
  final DateTime Function() _clock;
  final Duration pollInterval;
  final int historyEveryTicks;
  final Duration historyLookback;

  Timer? _timer;
  int _ticks = 0;
  bool _paused = false;
  bool _busy = false;

  Future<void> _onStarted(TelemetryStarted event, Emitter<TelemetryState> emit) async {
    emit(state.copyWith(equipments: state.equipments.loading()));
    try {
      final equipments = await _getEquipments(_laboratoryId());
      emit(state.copyWith(equipments: state.equipments.success(equipments, empty: equipments.isEmpty)));
      if (equipments.isEmpty) return;
      final requested = event.equipmentId;
      final initial = equipments.any((e) => e.id == requested) ? requested! : equipments.first.id;
      await _select(initial, emit);
    } catch (error) {
      emit(state.copyWith(equipments: state.equipments.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onEquipmentSelected(TelemetryEquipmentSelected event, Emitter<TelemetryState> emit) async {
    final known = state.equipments.data?.any((e) => e.id == event.equipmentId) ?? false;
    if (!known || event.equipmentId == state.selectedEquipmentId) return;
    await _select(event.equipmentId, emit);
  }

  Future<void> _select(int equipmentId, Emitter<TelemetryState> emit) async {
    _stopTimer();
    emit(TelemetryState(
      equipments: state.equipments,
      selectedEquipmentId: equipmentId,
      snapshot: const RemoteState<TelemetrySnapshot>().loading(),
      window: state.window,
    ));
    try {
      final now = _clock();
      final results = await Future.wait<Object>([
        _getStatus(equipmentId),
        _getLatest(equipmentId),
        _getBpmConfigs(equipmentId),
      ]);
      Failure? historyFailure;
      var history = const <TelemetryHistoryPoint>[];
      try {
        history = await _getHistory(equipmentId, from: now.subtract(historyLookback), to: now);
      } on UnauthorizedFailure {
        rethrow;
      } on Failure catch (failure) {
        historyFailure = failure;
      }
      if (state.selectedEquipmentId != equipmentId) return;
      final snapshot = TelemetrySnapshot(
        equipmentId: equipmentId,
        status: results[0] as EquipmentTelemetryStatus,
        readings: results[1] as List<ParameterReading>,
        limits: results[2] as List<BpmParameterConfig>,
        history: history,
        historyFailure: historyFailure,
        fetchedAt: now,
      );
      final empty = snapshot.readings.isEmpty && snapshot.history.isEmpty;
      emit(state.copyWith(snapshot: state.snapshot.success(snapshot, empty: empty), polling: !_paused));
      if (!_paused) _startTimer();
    } catch (error) {
      if (state.selectedEquipmentId != equipmentId) return;
      emit(state.copyWith(snapshot: state.snapshot.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onTick(TelemetryPollTicked event, Emitter<TelemetryState> emit) async {
    _ticks++;
    await _refresh(emit, includeHistory: _ticks % historyEveryTicks == 0, silent: true);
  }

  Future<void> _refresh(
    Emitter<TelemetryState> emit, {
    required bool includeHistory,
    bool silent = false,
  }) async {
    final equipmentId = state.selectedEquipmentId;
    final current = state.snapshot.data;
    if (equipmentId == null || _busy || state.snapshot.status.isLoading) return;
    if (current == null) {
      await _select(equipmentId, emit);
      return;
    }
    _busy = true;
    if (!silent) emit(state.copyWith(snapshot: state.snapshot.refreshingState()));
    try {
      final now = _clock();
      final status = await _getStatus(equipmentId);
      final readings = await _getLatest(equipmentId);
      var next = current.copyWith(status: status, readings: readings, fetchedAt: now);
      if (includeHistory) {
        try {
          final history = await _getHistory(equipmentId, from: now.subtract(historyLookback), to: now);
          next = next.copyWith(history: history, clearHistoryFailure: true);
        } on UnauthorizedFailure {
          rethrow;
        } on Failure catch (failure) {
          next = next.copyWith(historyFailure: failure);
        }
      }
      if (state.selectedEquipmentId != equipmentId) return;
      final empty = next.readings.isEmpty && next.history.isEmpty;
      emit(state.copyWith(snapshot: const RemoteState<TelemetrySnapshot>().success(next, empty: empty)));
    } catch (error) {
      if (state.selectedEquipmentId != equipmentId) return;
      emit(state.copyWith(snapshot: state.snapshot.failed(ApiExceptionMapper.map(error))));
      if (error is UnauthorizedFailure) _stopTimer();
    } finally {
      _busy = false;
    }
  }

  void _startTimer() {
    _stopTimer();
    _ticks = 0;
    _timer = Timer.periodic(pollInterval, (_) {
      if (!isClosed) add(const TelemetryPollTicked());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
