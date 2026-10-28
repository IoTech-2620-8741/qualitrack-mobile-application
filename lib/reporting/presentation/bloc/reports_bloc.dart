import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/reporting_entities.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

final class ReportsRequested extends ReportsEvent {
  const ReportsRequested({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

final class ReportsPeriodChanged extends ReportsEvent {
  const ReportsPeriodChanged(this.period);
  final ReportPeriod period;
  @override
  List<Object?> get props => [period];
}

class ReportsState extends Equatable {
  const ReportsState({
    this.remote = const RemoteState(),
    this.period = ReportPeriod.last24Hours
  });

  final RemoteState<ReportsData> remote;
  final ReportPeriod period;

  ReportsState copyWith({RemoteState<ReportsData>? remote, ReportPeriod? period}) =>
      ReportsState(remote: remote ?? this.remote, period: period ?? this.period);

  @override
  List<Object?> get props => [remote, period];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required this.reportingFacade,
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

  final ReportingFacadeService reportingFacade;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _load(Emitter<ReportsState> emit, {required bool refresh}) async {
    final current = state.remote;
    // Mostramos estado de carga o refresco
    emit(state.copyWith(remote: refresh && current.hasData ? current.refreshingState() : current.loading()));

    try {
      final data = await reportingFacade.loadReportsData(_laboratoryId(), state.period);
      if (data.everythingFailed) {
        emit(state.copyWith(remote: state.remote.failed(data.kpiFailure!)));
        return;
      }
      emit(state.copyWith(remote: state.remote.success(data)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}