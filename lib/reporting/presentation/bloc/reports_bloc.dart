import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../application/reporting_queries.dart';
import '../../domain/reporting.dart';

final class ReportsData extends Equatable {
  const ReportsData({required this.kpi, required this.reports, this.kpiFailure});

  /// Null when no KPI dashboard has been calculated in Web yet (HTTP 404).
  final KpiDashboard? kpi;

  /// Set when the KPI dashboard could not be read; the report history is still
  /// displayed.
  final Failure? kpiFailure;
  final Section<AuditReport> reports;

  bool get everythingFailed => kpiFailure != null && reports.failure != null;

  @override
  List<Object?> get props => [kpi, kpiFailure, reports];
}

final class ReportsRequested extends Equatable {
  const ReportsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Read-only: it never triggers report or KPI generation.
class ReportsBloc extends Bloc<ReportsRequested, RemoteState<ReportsData>> {
  ReportsBloc({
    required GetKpiDashboard getKpiDashboard,
    required GetReportHistory getReportHistory,
    required LaboratoryId Function() laboratoryId,
  }) : _getKpi = getKpiDashboard,
       _getReports = getReportHistory,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<ReportsRequested>(_onRequested);
  }

  final GetKpiDashboard _getKpi;
  final GetReportHistory _getReports;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(ReportsRequested event, Emitter<RemoteState<ReportsData>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      // Both parts load independently: a failing KPI dashboard must not hide
      // the report history, and vice versa.
      KpiDashboard? kpi;
      Failure? kpiFailure;
      try {
        kpi = await _getKpi(lab);
      } on UnauthorizedFailure {
        rethrow;
      } on OnboardingRequiredFailure {
        rethrow;
      } on Failure catch (failure) {
        kpiFailure = failure;
      }
      final reports = await Section.load(() => _getReports(lab));
      final data = ReportsData(kpi: kpi, kpiFailure: kpiFailure, reports: reports);
      if (data.everythingFailed) {
        emit(state.failed(kpiFailure!));
        return;
      }
      final empty = kpi == null && kpiFailure == null && reports.failure == null && reports.items.isEmpty;
      emit(state.success(data, empty: empty));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }
}
