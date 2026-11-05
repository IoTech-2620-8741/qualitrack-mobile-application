/// This file contains the Events, State, and BLoC for the Reports screen.
///
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
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
  /// (Si es true, muestra el indicador de "recargando" en lugar de la pantalla de carga completa).
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Event triggered when the user changes the time period filter.
/// (Se dispara cuando el usuario toca los botones de "24 horas", "7 días", "31 días").
final class ReportsPeriodChanged extends ReportsEvent {
  const ReportsPeriodChanged(this.period);

  /// El nuevo periodo seleccionado (last24Hours, last7Days, last31Days).
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

  /// Contiene los datos de Reportes (KPI, Tendencias, Historial)
  /// y el estado de la petición (cargando, éxito, error).
  final RemoteState<ReportsData> remote;

  /// El filtro de tiempo actualmente seleccionado.
  final ReportPeriod period;

  /// Método para crear una copia del estado actual con cambios específicos.
  /// (Patrón inmutable muy usado en BLoC para evitar bugs).
  ReportsState copyWith({RemoteState<ReportsData>? remote, ReportPeriod? period}) =>
      ReportsState(remote: remote ?? this.remote, period: period ?? this.period);

  @override
  List<Object?> get props => [remote, period];
}

/// BLoC that manages the state of the Reports screen.
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

  /// Dependencias inyectadas: La fachada que orquesta las peticiones.
  final ReportingFacadeService reportingFacade;

  /// Función para obtener el ID del laboratorio actual (viene de la sesión del usuario).
  final LaboratoryId Function() _laboratoryId;

  /// Internal method to load the reports data.
  /// (Método privado que hace la magia de cargar los datos y emitir los estados).
  Future<void> _load(Emitter<ReportsState> emit, {required bool refresh}) async {
    final current = state.remote;

    emit(state.copyWith(
      remote: refresh && current.hasData
          ? current.refreshingState()
          : current.loading(),
    ));

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