import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/view_status.dart';
import '../../application/telemetry_queries.dart';
import '../../domain/telemetry.dart';

/// IoT devices of the laboratory with the environments where they are located.
final class DeviceCatalog extends Equatable {
  const DeviceCatalog({required this.devices, required this.environments});

  final List<Equipment> devices;
  final List<LabEnvironment> environments;

  LabEnvironment? environmentOf(Equipment device) {
    for (final environment in environments) {
      if (environment.id == device.environmentId) return environment;
    }
    return null;
  }

  @override
  List<Object?> get props => [devices, environments];
}

/// Telemetry of one device: connection, readings of the last 24 hours, the
/// profile in force and, for container monitors, the automatic actions.
final class TelemetrySnapshot extends Equatable {
  const TelemetrySnapshot({
    required this.target,
    required this.connection,
    required this.history,
    required this.fetchedAt,
    this.profile,
    this.actuations = const [],
    this.actuationsFailure,
  });

  final TelemetryTarget target;
  final DeviceConnection connection;
  final List<Measurement> history;
  final EnvironmentalProfile? profile;
  final List<ActuationEvent> actuations;
  final Failure? actuationsFailure;
  final DateTime fetchedAt;

  List<MetricReading> get readings => TelemetryAnalysis.latestByMetric(history);

  List<Measurement> get deviations => TelemetryAnalysis.deviations(history);

  List<MonitoredMetric> get chartMetrics => TelemetryAnalysis.chartMetrics(history);

  MetricThreshold? thresholdFor(MonitoredMetric metric) => profile?.thresholdFor(metric);

  String? unitFor(MonitoredMetric metric) {
    for (final reading in readings) {
      if (reading.latest.metric == metric) return reading.latest.unit;
    }
    return thresholdFor(metric)?.unit;
  }

  TelemetrySnapshot copyWith({
    DeviceConnection? connection,
    List<Measurement>? history,
    List<ActuationEvent>? actuations,
    Failure? actuationsFailure,
    bool clearActuationsFailure = false,
    DateTime? fetchedAt,
  }) => TelemetrySnapshot(
    target: target,
    connection: connection ?? this.connection,
    history: history ?? this.history,
    profile: profile,
    actuations: actuations ?? this.actuations,
    actuationsFailure: clearActuationsFailure ? null : (actuationsFailure ?? this.actuationsFailure),
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );

  @override
  List<Object?> get props => [target, connection, history, profile, actuations, actuationsFailure, fetchedAt];
}

sealed class TelemetryEvent extends Equatable {
  const TelemetryEvent();

  @override
  List<Object?> get props => [];
}

final class TelemetryStarted extends TelemetryEvent {
  const TelemetryStarted({this.deviceId});

  final int? deviceId;

  @override
  List<Object?> get props => [deviceId];
}

final class TelemetryDeviceSelected extends TelemetryEvent {
  const TelemetryDeviceSelected(this.deviceId);

  final int deviceId;

  @override
  List<Object?> get props => [deviceId];
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

final class TelemetryMetricSelected extends TelemetryEvent {
  const TelemetryMetricSelected(this.metric);

  final MonitoredMetric metric;

  @override
  List<Object?> get props => [metric];
}

final class TelemetryWindowSelected extends TelemetryEvent {
  const TelemetryWindowSelected(this.window);

  final TelemetryWindow window;

  @override
  List<Object?> get props => [window];
}

final class TelemetryState extends Equatable {
  const TelemetryState({
    this.catalog = const RemoteState(),
    this.selectedDeviceId,
    this.snapshot = const RemoteState(),
    this.selectedMetric,
    this.window = TelemetryWindow.oneHour,
    this.polling = false,
  });

  final RemoteState<DeviceCatalog> catalog;
  final int? selectedDeviceId;
  final RemoteState<TelemetrySnapshot> snapshot;
  final MonitoredMetric? selectedMetric;
  final TelemetryWindow window;
  final bool polling;

  Equipment? get selectedDevice {
    for (final device in catalog.data?.devices ?? const <Equipment>[]) {
      if (device.id == selectedDeviceId) return device;
    }
    return null;
  }

  /// Metric shown in the chart (explicit selection or the first available).
  MonitoredMetric? get chartMetric {
    final metrics = snapshot.data?.chartMetrics ?? const <MonitoredMetric>[];
    if (metrics.isEmpty) return null;
    return metrics.contains(selectedMetric) ? selectedMetric : metrics.first;
  }

  List<TelemetryWindow> get availableWindows {
    final data = snapshot.data;
    final metric = chartMetric;
    if (data == null || metric == null) return const [];
    return TelemetryAnalysis.availableWindows(data.history, metric);
  }

  TelemetryWindow? get effectiveWindow {
    final windows = availableWindows;
    if (windows.isEmpty) return null;
    return windows.contains(window) ? window : windows.last;
  }

  List<Measurement> get chartSeries {
    final data = snapshot.data;
    final metric = chartMetric;
    final w = effectiveWindow;
    if (data == null || metric == null || w == null) return const [];
    return TelemetryAnalysis.series(data.history, metric, w);
  }

  TelemetryState copyWith({
    RemoteState<DeviceCatalog>? catalog,
    int? selectedDeviceId,
    RemoteState<TelemetrySnapshot>? snapshot,
    MonitoredMetric? selectedMetric,
    TelemetryWindow? window,
    bool? polling,
  }) => TelemetryState(
    catalog: catalog ?? this.catalog,
    selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    snapshot: snapshot ?? this.snapshot,
    selectedMetric: selectedMetric ?? this.selectedMetric,
    window: window ?? this.window,
    polling: polling ?? this.polling,
  );

  @override
  List<Object?> get props => [catalog, selectedDeviceId, snapshot, selectedMetric, window, polling];
}

/// Live telemetry with responsible polling: the first load reads the last
/// [lookback]; every [pollInterval] only the connection and the readings of
/// the last [pollOverlap] are downloaded and merged. Automatic actions are
/// refreshed every [actuationsEveryTicks] ticks. The timer is cancelled when
/// the BLoC is closed or polling is paused (app in background).
class TelemetryDashboardBloc extends Bloc<TelemetryEvent, TelemetryState> {
  TelemetryDashboardBloc({
    required GetEquipments getEquipments,
    required GetEnvironments getEnvironments,
    required GetDeviceConnection getConnection,
    required GetMeasurements getMeasurements,
    required GetEnvironmentalProfile getProfile,
    required GetActuationEvents getActuations,
    required LaboratoryId Function() laboratoryId,
    DateTime Function()? clock,
    this.pollInterval = const Duration(seconds: 15),
    this.pollOverlap = const Duration(minutes: 5),
    this.actuationsEveryTicks = 4,
    this.lookback = const Duration(hours: 24),
  }) : _getEquipments = getEquipments,
       _getEnvironments = getEnvironments,
       _getConnection = getConnection,
       _getMeasurements = getMeasurements,
       _getProfile = getProfile,
       _getActuations = getActuations,
       _laboratoryId = laboratoryId,
       _clock = clock ?? DateTime.now,
       super(const TelemetryState()) {
    on<TelemetryStarted>(_onStarted);
    on<TelemetryDeviceSelected>(_onDeviceSelected);
    on<TelemetryRefreshRequested>((event, emit) async {
      final deviceId = state.selectedDeviceId;
      if (deviceId != null && !state.snapshot.status.isLoading) await _select(deviceId, emit, keepData: true);
    });
    on<TelemetryPollTicked>(_onTick);
    on<TelemetryPollingPaused>((event, emit) {
      _paused = true;
      _stopTimer();
      emit(state.copyWith(polling: false));
    });
    on<TelemetryPollingResumed>((event, emit) async {
      _paused = false;
      final deviceId = state.selectedDeviceId;
      if (deviceId == null) return;
      await _select(deviceId, emit, keepData: true);
    });
    on<TelemetryMetricSelected>((e, emit) => emit(state.copyWith(selectedMetric: e.metric)));
    on<TelemetryWindowSelected>((e, emit) => emit(state.copyWith(window: e.window)));
  }

  final GetEquipments _getEquipments;
  final GetEnvironments _getEnvironments;
  final GetDeviceConnection _getConnection;
  final GetMeasurements _getMeasurements;
  final GetEnvironmentalProfile _getProfile;
  final GetActuationEvents _getActuations;
  final LaboratoryId Function() _laboratoryId;
  final DateTime Function() _clock;
  final Duration pollInterval;
  final Duration pollOverlap;
  final int actuationsEveryTicks;
  final Duration lookback;

  Timer? _timer;
  int _ticks = 0;
  bool _paused = false;
  bool _busy = false;

  Future<void> _onStarted(TelemetryStarted event, Emitter<TelemetryState> emit) async {
    emit(state.copyWith(catalog: state.catalog.loading()));
    try {
      final laboratoryId = _laboratoryId();
      final results = await Future.wait<Object>([_getEquipments(laboratoryId), _getEnvironments(laboratoryId)]);
      final catalog = DeviceCatalog(
        devices: telemetryDevices(results[0] as List<Equipment>),
        environments: results[1] as List<LabEnvironment>,
      );
      emit(state.copyWith(catalog: state.catalog.success(catalog, empty: catalog.devices.isEmpty)));
      if (catalog.devices.isEmpty) return;
      final requested = event.deviceId;
      final initial = catalog.devices.any((e) => e.id == requested) ? requested! : catalog.devices.first.id;
      await _select(initial, emit);
    } catch (error) {
      emit(state.copyWith(catalog: state.catalog.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onDeviceSelected(TelemetryDeviceSelected event, Emitter<TelemetryState> emit) async {
    final known = state.catalog.data?.devices.any((e) => e.id == event.deviceId) ?? false;
    if (!known || event.deviceId == state.selectedDeviceId) return;
    await _select(event.deviceId, emit);
  }

  Future<void> _select(int deviceId, Emitter<TelemetryState> emit, {bool keepData = false}) async {
    TelemetryTarget? target;
    for (final device in state.catalog.data?.devices ?? const <Equipment>[]) {
      if (device.id == deviceId) target = targetOf(device);
    }
    if (target == null) return;
    _stopTimer();
    if (keepData && state.snapshot.hasData && state.selectedDeviceId == deviceId) {
      emit(state.copyWith(snapshot: state.snapshot.refreshingState()));
    } else {
      emit(TelemetryState(
        catalog: state.catalog,
        selectedDeviceId: deviceId,
        snapshot: const RemoteState<TelemetrySnapshot>().loading(),
        window: state.window,
      ));
    }
    try {
      final laboratoryId = _laboratoryId();
      final now = _clock();
      final from = now.subtract(lookback);
      final results = await Future.wait<Object?>([
        _getConnection(laboratoryId, target),
        _getMeasurements(laboratoryId, target, from: from, to: now),
        _getProfile(laboratoryId, target),
      ]);
      Failure? actuationsFailure;
      var actuations = const <ActuationEvent>[];
      try {
        actuations = await _getActuations(laboratoryId, target, from: from, to: now);
      } on UnauthorizedFailure {
        rethrow;
      } on Failure catch (failure) {
        actuationsFailure = failure;
      }
      if (state.selectedDeviceId != deviceId) return;
      final snapshot = TelemetrySnapshot(
        target: target,
        connection: results[0]! as DeviceConnection,
        history: results[1]! as List<Measurement>,
        profile: results[2] as EnvironmentalProfile?,
        actuations: actuations,
        actuationsFailure: actuationsFailure,
        fetchedAt: now,
      );
      emit(state.copyWith(
        snapshot: const RemoteState<TelemetrySnapshot>().success(snapshot, empty: snapshot.history.isEmpty),
        polling: !_paused,
      ));
      if (!_paused) _startTimer();
    } catch (error) {
      if (state.selectedDeviceId != deviceId) return;
      emit(state.copyWith(snapshot: state.snapshot.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _onTick(TelemetryPollTicked event, Emitter<TelemetryState> emit) async {
    final current = state.snapshot.data;
    final deviceId = state.selectedDeviceId;
    if (current == null || deviceId == null || _busy || state.snapshot.status.isLoading) return;
    _ticks++;
    _busy = true;
    try {
      final laboratoryId = _laboratoryId();
      final now = _clock();
      final target = current.target;
      final connection = await _getConnection(laboratoryId, target);
      final recent = await _getMeasurements(laboratoryId, target, from: now.subtract(pollOverlap), to: now);
      var next = current.copyWith(
        connection: connection,
        history: TelemetryAnalysis.merge(current.history, recent, now.subtract(lookback)),
        fetchedAt: now,
      );
      if (target.containerMonitor && _ticks % actuationsEveryTicks == 0) {
        try {
          final actuations = await _getActuations(laboratoryId, target, from: now.subtract(lookback), to: now);
          next = next.copyWith(actuations: actuations, clearActuationsFailure: true);
        } on UnauthorizedFailure {
          rethrow;
        } on Failure catch (failure) {
          next = next.copyWith(actuationsFailure: failure);
        }
      }
      if (state.selectedDeviceId != deviceId) return;
      emit(state.copyWith(
        snapshot: const RemoteState<TelemetrySnapshot>().success(next, empty: next.history.isEmpty),
      ));
    } catch (error) {
      if (state.selectedDeviceId != deviceId) return;
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
