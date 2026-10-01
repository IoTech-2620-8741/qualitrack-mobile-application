import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/application/equipment_queries.dart';
import '../../../equipment/domain/equipment.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/telemetry_queries.dart';
import '../../domain/telemetry.dart';

/// Inclusive date range applied by the backend (`from`/`to`).
final class HistoryRange extends Equatable {
  const HistoryRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

sealed class TelemetryHistoryEvent extends Equatable {
  const TelemetryHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class TelemetryHistoryStarted extends TelemetryHistoryEvent {
  const TelemetryHistoryStarted({this.equipmentId});

  final int? equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class TelemetryHistoryEquipmentSelected extends TelemetryHistoryEvent {
  const TelemetryHistoryEquipmentSelected(this.equipmentId);

  final int equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class TelemetryHistoryRangeChanged extends TelemetryHistoryEvent {
  const TelemetryHistoryRangeChanged(this.range);

  final HistoryRange? range;

  @override
  List<Object?> get props => [range];
}

final class TelemetryHistorySearchRequested extends TelemetryHistoryEvent {
  const TelemetryHistorySearchRequested();
}

final class TelemetryHistoryFiltersCleared extends TelemetryHistoryEvent {
  const TelemetryHistoryFiltersCleared();
}

final class TelemetryHistoryAnomaliesToggled extends TelemetryHistoryEvent {
  const TelemetryHistoryAnomaliesToggled(this.onlyAnomalies);

  final bool onlyAnomalies;

  @override
  List<Object?> get props => [onlyAnomalies];
}

final class TelemetryHistoryPageChanged extends TelemetryHistoryEvent {
  const TelemetryHistoryPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

final class TelemetryHistoryState extends Equatable {
  const TelemetryHistoryState({
    this.equipments = const RemoteState(),
    this.selectedEquipmentId,
    this.range,
    this.onlyAnomalies = false,
    this.points = const RemoteState(),
    this.page = 0,
  });

  static const int pageSize = 20;

  final RemoteState<List<Equipment>> equipments;
  final int? selectedEquipmentId;
  final HistoryRange? range;
  final bool onlyAnomalies;
  final RemoteState<List<TelemetryHistoryPoint>> points;
  final int page;

  List<TelemetryHistoryPoint> get filtered => (points.data ?? const <TelemetryHistoryPoint>[])
      .where((p) => !onlyAnomalies || p.isAnomaly)
      .toList(growable: false);

  int get pageCount {
    final total = filtered.length;
    return total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
  }

  List<TelemetryHistoryPoint> get pageItems {
    final all = filtered;
    final start = page * pageSize;
    if (start >= all.length) return const [];
    final end = (start + pageSize) > all.length ? all.length : start + pageSize;
    return all.sublist(start, end);
  }

  TelemetryHistoryState copyWith({
    RemoteState<List<Equipment>>? equipments,
    int? selectedEquipmentId,
    HistoryRange? range,
    bool clearRange = false,
    bool? onlyAnomalies,
    RemoteState<List<TelemetryHistoryPoint>>? points,
    int? page,
  }) => TelemetryHistoryState(
    equipments: equipments ?? this.equipments,
    selectedEquipmentId: selectedEquipmentId ?? this.selectedEquipmentId,
    range: clearRange ? null : (range ?? this.range),
    onlyAnomalies: onlyAnomalies ?? this.onlyAnomalies,
    points: points ?? this.points,
    page: page ?? this.page,
  );

  @override
  List<Object?> get props => [equipments, selectedEquipmentId, range, onlyAnomalies, points, page];
}

class TelemetryHistoryBloc extends Bloc<TelemetryHistoryEvent, TelemetryHistoryState> {
  TelemetryHistoryBloc({
    required GetEquipments getEquipments,
    required GetTelemetryHistory getHistory,
    required LaboratoryId Function() laboratoryId,
  }) : _getEquipments = getEquipments,
       _getHistory = getHistory,
       _laboratoryId = laboratoryId,
       super(const TelemetryHistoryState()) {
    on<TelemetryHistoryStarted>(_onStarted);
    on<TelemetryHistoryEquipmentSelected>((e, emit) async {
      emit(state.copyWith(selectedEquipmentId: e.equipmentId, page: 0));
      await _load(emit);
    });
    on<TelemetryHistoryRangeChanged>((e, emit) {
      emit(e.range == null ? state.copyWith(clearRange: true) : state.copyWith(range: e.range));
    });
    on<TelemetryHistorySearchRequested>((e, emit) => _load(emit));
    on<TelemetryHistoryFiltersCleared>((e, emit) async {
      emit(state.copyWith(clearRange: true, onlyAnomalies: false, page: 0));
      await _load(emit);
    });
    on<TelemetryHistoryAnomaliesToggled>(
      (e, emit) => emit(state.copyWith(onlyAnomalies: e.onlyAnomalies, page: 0)),
    );
    on<TelemetryHistoryPageChanged>((e, emit) {
      if (e.page < 0 || e.page >= state.pageCount) return;
      emit(state.copyWith(page: e.page));
    });
  }

  final GetEquipments _getEquipments;
  final GetTelemetryHistory _getHistory;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onStarted(TelemetryHistoryStarted event, Emitter<TelemetryHistoryState> emit) async {
    emit(state.copyWith(equipments: state.equipments.loading()));
    try {
      final equipments = await _getEquipments(_laboratoryId());
      emit(state.copyWith(equipments: state.equipments.success(equipments, empty: equipments.isEmpty)));
      if (equipments.isEmpty) return;
      final requested = event.equipmentId;
      final id = equipments.any((e) => e.id == requested) ? requested! : equipments.first.id;
      emit(state.copyWith(selectedEquipmentId: id));
      await _load(emit);
    } catch (error) {
      emit(state.copyWith(equipments: state.equipments.failed(ApiExceptionMapper.map(error))));
    }
  }

  Future<void> _load(Emitter<TelemetryHistoryState> emit) async {
    final equipmentId = state.selectedEquipmentId;
    if (equipmentId == null) return;
    emit(state.copyWith(points: state.points.loading(), page: 0));
    try {
      final range = state.range;
      final points = await _getHistory(equipmentId, from: range?.from, to: range?.to);
      if (state.selectedEquipmentId != equipmentId) return;
      emit(state.copyWith(points: state.points.success(points, empty: points.isEmpty)));
    } catch (error) {
      emit(state.copyWith(points: state.points.failed(ApiExceptionMapper.map(error))));
    }
  }
}
