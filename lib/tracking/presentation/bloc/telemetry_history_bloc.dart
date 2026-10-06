import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/telemetry_queries.dart';
import '../../domain/telemetry.dart';
import 'telemetry_dashboard_bloc.dart';

/// Period sent to the backend (`from`/`to`), at most 31 days.
final class HistoryRange extends Equatable {
  const HistoryRange({required this.from, required this.to});

  factory HistoryRange.last(Duration duration, DateTime now) => HistoryRange(from: now.subtract(duration), to: now);

  final DateTime from;
  final DateTime to;

  bool get isValid => from.isBefore(to) && to.difference(from) <= TelemetryAnalysis.maxPeriod;

  @override
  List<Object?> get props => [from, to];
}

sealed class TelemetryHistoryEvent extends Equatable {
  const TelemetryHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class TelemetryHistoryStarted extends TelemetryHistoryEvent {
  const TelemetryHistoryStarted({this.deviceId});

  final int? deviceId;

  @override
  List<Object?> get props => [deviceId];
}

final class TelemetryHistoryDeviceSelected extends TelemetryHistoryEvent {
  const TelemetryHistoryDeviceSelected(this.deviceId);

  final int deviceId;

  @override
  List<Object?> get props => [deviceId];
}

final class TelemetryHistoryRangeChanged extends TelemetryHistoryEvent {
  const TelemetryHistoryRangeChanged(this.range);

  final HistoryRange range;

  @override
  List<Object?> get props => [range];
}

final class TelemetryHistoryMetricChanged extends TelemetryHistoryEvent {
  const TelemetryHistoryMetricChanged(this.metric);

  /// Null shows every metric.
  final MonitoredMetric? metric;

  @override
  List<Object?> get props => [metric];
}

final class TelemetryHistorySearchRequested extends TelemetryHistoryEvent {
  const TelemetryHistorySearchRequested();
}

final class TelemetryHistoryDeviationsToggled extends TelemetryHistoryEvent {
  const TelemetryHistoryDeviationsToggled(this.onlyDeviations);

  final bool onlyDeviations;

  @override
  List<Object?> get props => [onlyDeviations];
}

final class TelemetryHistoryPageChanged extends TelemetryHistoryEvent {
  const TelemetryHistoryPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

final class TelemetryHistoryState extends Equatable {
  const TelemetryHistoryState({
    required this.range,
    this.catalog = const RemoteState(),
    this.selectedDeviceId,
    this.metric,
    this.onlyDeviations = false,
    this.points = const RemoteState(),
    this.page = 0,
  });

  static const int pageSize = 20;

  final RemoteState<DeviceCatalog> catalog;
  final int? selectedDeviceId;
  final HistoryRange range;
  final MonitoredMetric? metric;
  final bool onlyDeviations;
  final RemoteState<List<Measurement>> points;
  final int page;

  /// Metrics present in the loaded readings (for the metric filter).
  List<MonitoredMetric> get metrics =>
      (points.data ?? const <Measurement>[]).map((p) => p.metric).toSet().toList()
        ..sort((a, b) => a.index.compareTo(b.index));

  List<Measurement> get filtered => (points.data ?? const <Measurement>[])
      .where((p) => (metric == null || p.metric == metric) && (!onlyDeviations || p.state.isDeviation))
      .toList(growable: false);

  int get pageCount {
    final total = filtered.length;
    return total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
  }

  List<Measurement> get pageItems {
    final all = filtered;
    final start = page * pageSize;
    if (start >= all.length) return const [];
    final end = (start + pageSize) > all.length ? all.length : start + pageSize;
    return all.sublist(start, end);
  }

  TelemetryHistoryState copyWith({
    RemoteState<DeviceCatalog>? catalog,
    int? selectedDeviceId,
    HistoryRange? range,
    MonitoredMetric? metric,
    bool clearMetric = false,
    bool? onlyDeviations,
    RemoteState<List<Measurement>>? points,
    int? page,
  }) => TelemetryHistoryState(
    catalog: catalog ?? this.catalog,
    selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    range: range ?? this.range,
    metric: clearMetric ? null : (metric ?? this.metric),
    onlyDeviations: onlyDeviations ?? this.onlyDeviations,
    points: points ?? this.points,
    page: page ?? this.page,
  );

  @override
  List<Object?> get props => [catalog, selectedDeviceId, range, metric, onlyDeviations, points, page];
}

class TelemetryHistoryBloc extends Bloc<TelemetryHistoryEvent, TelemetryHistoryState> {
  TelemetryHistoryBloc({
    required GetEquipments getEquipments,
    required GetEnvironments getEnvironments,
    required GetMeasurements getMeasurements,
    required LaboratoryId Function() laboratoryId,
    DateTime Function()? clock,
  }) : _getEquipments = getEquipments,
       _getEnvironments = getEnvironments,
       _getMeasurements = getMeasurements,
       _laboratoryId = laboratoryId,
       super(TelemetryHistoryState(range: HistoryRange.last(const Duration(hours: 24), (clock ?? DateTime.now)()))) {
    on<TelemetryHistoryStarted>(_onStarted);
    on<TelemetryHistoryDeviceSelected>((e, emit) async {
      emit(state.copyWith(selectedDeviceId: e.deviceId, page: 0, clearMetric: true));
      await _load(emit);
    });
    on<TelemetryHistoryRangeChanged>((e, emit) => emit(state.copyWith(range: e.range)));
    on<TelemetryHistoryMetricChanged>((e, emit) {
      emit(e.metric == null ? state.copyWith(clearMetric: true, page: 0) : state.copyWith(metric: e.metric, page: 0));
    });
    on<TelemetryHistorySearchRequested>((e, emit) => _load(emit));
    on<TelemetryHistoryDeviationsToggled>(
      (e, emit) => emit(state.copyWith(onlyDeviations: e.onlyDeviations, page: 0)),
    );
    on<TelemetryHistoryPageChanged>((e, emit) {
      if (e.page < 0 || e.page >= state.pageCount) return;
      emit(state.copyWith(page: e.page));
    });
  }

  final GetEquipments _getEquipments;
  final GetEnvironments _getEnvironments;
  final GetMeasurements _getMeasurements;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onStarted(TelemetryHistoryStarted event, Emitter<TelemetryHistoryState> emit) async {
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
      final id = catalog.devices.any((e) => e.id == requested) ? requested! : catalog.devices.first.id;
      emit(state.copyWith(selectedDeviceId: id));
      await _load(emit);
    } catch (error) {
      emit(state.copyWith(catalog: state.catalog.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _load(Emitter<TelemetryHistoryState> emit) async {
    final deviceId = state.selectedDeviceId;
    TelemetryTarget? target;
    for (final device in state.catalog.data?.devices ?? const <Equipment>[]) {
      if (device.id == deviceId) target = targetOf(device);
    }
    if (target == null) return;
    emit(state.copyWith(points: state.points.loading(), page: 0));
    try {
      final range = state.range;
      final points = await _getMeasurements(_laboratoryId(), target, from: range.from, to: range.to);
      if (state.selectedDeviceId != deviceId) return;
      emit(state.copyWith(points: state.points.success(points, empty: points.isEmpty)));
    } catch (error) {
      emit(state.copyWith(points: state.points.failed(ApiExceptionMapper.map(error))));
    }
  }
}
