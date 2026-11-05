import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../equipment/api/index.dart';
import '../../../laboratory/api/index.dart';
import '../../../common/domain/failure.dart';
import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/section.dart';
import '../../application/reporting_queries.dart';
import '../../domain/reporting.dart';

final class ReportsData extends Equatable {
  const ReportsData({
    required this.kpi,
    required this.trends,
    required this.reports,
    this.environmentNames = const {},
    this.deviceNames = const {},
    this.kpiFailure,
  });

  /// Null when the indicators could not be calculated ([kpiFailure]).
  final KpiDashboard? kpi;
  final Failure? kpiFailure;
  final Section<DeviationTrend> trends;
  final Section<AuditReport> reports;
  final Map<int, String> environmentNames;
  final Map<int, String> deviceNames;

  bool get everythingFailed => kpiFailure != null && trends.failed && reports.failed;

  @override
  List<Object?> get props => [kpi, kpiFailure, trends, reports, environmentNames, deviceNames];
}

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

final class ReportsState extends Equatable {
  const ReportsState({this.remote = const RemoteState(), this.period = ReportPeriod.last24Hours});

  final RemoteState<ReportsData> remote;
  final ReportPeriod period;

  ReportsState copyWith({RemoteState<ReportsData>? remote, ReportPeriod? period}) =>
      ReportsState(remote: remote ?? this.remote, period: period ?? this.period);

  @override
  List<Object?> get props => [remote, period];
}

/// Indicators and report history. It is read-only: reports are generated in
/// QualiTrack Web.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required GetKpiDashboard getKpiDashboard,
    required GetDeviationTrends getDeviationTrends,
    required GetReportHistory getReportHistory,
    required LaboratoryApi laboratoryApi,
    required GetEquipments getEquipments,
    required LaboratoryId Function() laboratoryId,
  }) : _getKpi = getKpiDashboard,
       _getTrends = getDeviationTrends,
       _getReports = getReportHistory,
       _laboratoryApi = laboratoryApi,
       _getEquipments = getEquipments,
       _laboratoryId = laboratoryId,
       super(const ReportsState()) {
    on<ReportsRequested>((event, emit) => _load(emit, refresh: event.refresh));
    on<ReportsPeriodChanged>((event, emit) async {
      if (event.period == state.period) return;
      emit(state.copyWith(period: event.period));
      await _load(emit, refresh: true);
    });
  }

  final GetKpiDashboard _getKpi;
  final GetDeviationTrends _getTrends;
  final GetReportHistory _getReports;
  final LaboratoryApi _laboratoryApi;
  final GetEquipments _getEquipments;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _load(Emitter<ReportsState> emit, {required bool refresh}) async {
    final current = state.remote;
    emit(state.copyWith(remote: refresh && current.hasData ? current.refreshingState() : current.loading()));
    try {
      final lab = _laboratoryId();
      final period = state.period;
      final results = await Future.wait<Object>([_laboratoryApi.getEnvironments(lab), _getEquipments(lab)]);
      final environments = results[0] as List<LabEnvironment>;
      final equipments = results[1] as List<Equipment>;
      // Each part loads independently: one failing indicator must not hide the rest.
      KpiDashboard? kpi;
      Failure? kpiFailure;
      try {
        kpi = await _getKpi(lab, period);
      } on UnauthorizedFailure {
        rethrow;
      } on OnboardingRequiredFailure {
        rethrow;
      } on Failure catch (failure) {
        kpiFailure = failure;
      }
      final sections = await Future.wait<Object>([
        Section.load(() => _getTrends(lab, environments.map((e) => e.id), period)),
        Section.load(() => _getReports(lab)),
      ]);
      final data = ReportsData(
        kpi: kpi,
        kpiFailure: kpiFailure,
        trends: sections[0] as Section<DeviationTrend>,
        reports: sections[1] as Section<AuditReport>,
        environmentNames: {for (final e in environments) e.id: e.name},
        deviceNames: {for (final e in equipments) e.id: e.name},
      );
      if (data.everythingFailed) {
        emit(state.copyWith(remote: state.remote.failed(kpiFailure!)));
        return;
      }
      emit(state.copyWith(remote: state.remote.success(data)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(Failure.from(error))));
    }
  }
}
