/// This file contains the Events, State, and BLoC for the Reports screen.
///
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/domain/failure.dart';
import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/reporting_enums.dart';

/// Base class for all Reports events.
sealed class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

/// Event triggered when the user requests to load or refresh the reports data.
final class ReportsRequested extends ReportsEvent {
  const ReportsRequested({this.refresh = false});

  /// If true, shows a refreshing indicator instead of a full loading screen.
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Event triggered when the user picks another period (24 hours, 7 days or
/// 31 days).
final class ReportsPeriodChanged extends ReportsEvent {
  const ReportsPeriodChanged(this.period);

  /// The period the user picked.
  final ReportPeriod period;

  @override
  List<Object?> get props => [period];
}

/// Represents the current state of the Reports screen.
class ReportsState extends Equatable {
  const ReportsState({
    this.remote = const RemoteState(),
    this.period = ReportPeriod.last24Hours,
  });

  /// The reports data (indicators, trends, history) and the state of its request.
  final RemoteState<ReportsData> remote;

  /// The period currently selected.
  final ReportPeriod period;

  ReportsState copyWith({RemoteState<ReportsData>? remote, ReportPeriod? period}) =>
      ReportsState(remote: remote ?? this.remote, period: period ?? this.period);

  @override
  List<Object?> get props => [remote, period];
}

/// BLoC that manages the state of the Reports screen.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required this.reportingService,
    required LaboratoryId Function() laboratoryId,
  }) : _laboratoryId = laboratoryId,
        super(const ReportsState()) {

    on<ReportsRequested>((event, emit) => _load(emit, refresh: event.refresh));

    on<ReportsPeriodChanged>((event, emit) async {
      if (event.period == state.period) return;

      emit(state.copyWith(period: event.period));

      await _load(emit, refresh: true);
    });
  }

  /// The facade that gathers the reports data.
  final ReportingFacadeService reportingService;

  /// The laboratory of the session.
  final LaboratoryId Function() _laboratoryId;

  /// Number of the latest request: the answer of an earlier one (another
  /// period, or a refresh that took longer) is ignored, so a slow answer never
  /// replaces the data of the period on screen.
  int _latestRequest = 0;

  /// Loads the reports data of the selected period.
  Future<void> _load(Emitter<ReportsState> emit, {required bool refresh}) async {
    final request = ++_latestRequest;
    final current = state.remote;

    emit(state.copyWith(
      remote: refresh && current.hasData
          ? current.refreshingState()
          : current.loading(),
    ));

    try {
      final data = await reportingService.loadReportsData(_laboratoryId(), state.period);
      if (request != _latestRequest) return;

      if (data.everythingFailed) {
        emit(state.copyWith(remote: state.remote.failed(data.kpiFailure!)));
        return;
      }

      emit(state.copyWith(remote: state.remote.success(data)));
    } catch (error) {
      if (request != _latestRequest) return;
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }
}
