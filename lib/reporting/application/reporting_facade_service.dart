/// This file contains the Application Facade (Service) for the Reporting context.
///
/// It acts as an orchestrator that combines data from multiple contexts
/// (Laboratory, Equipment) and packages it into a single [ReportsData] object,
/// ready to be consumed by the Presentation layer (BLoC).
///
/// @author Vitaly Baca Camargo
///
library;


import '../../equipment/api/index.dart';
import '../../laboratory/api/index.dart';
import '../../common/application/bounded_concurrency.dart';
import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../../common/application/section.dart';
import '../domain/entities/audit_entities.dart';
import '../domain/entities/deviation_entities.dart';
import '../domain/entities/kpi_entities.dart';
import '../domain/entities/reporting_enums.dart';
import '../domain/interfaces/reporting_interface.dart';
import '../domain/logic/reporting_logic.dart';
import 'package:equatable/equatable.dart';

/// Consolidated data container for the reports screen.
///
/// It includes KPIs, trends, reports, and the resolved names
/// for environments and equipment.
final class ReportsData extends Equatable {
  const ReportsData({
    required this.kpi,
    required this.trends,
    required this.reports,
    this.environmentNames = const {},
    this.deviceNames = const {},
    this.kpiFailure,
  });

  final KpiDashboard? kpi;
  final Failure? kpiFailure;
  final Section<DeviationTrend> trends;
  final Section<AuditReport> reports;
  final Map<int, String> environmentNames;
  final Map<int, String> deviceNames;

  /// The deviation trends, already sorted by severity by the facade
  /// (Critical > Warning > On Track > No Data).
  List<DeviationTrend> get sortedTrends => trends.items;

  /// Returns the count of deviation trends that are marked as critical.
  int get criticalTrendsCount => sortedTrends.where((t) => t.severity == DeviationSeverity.critical).length;

  /// Groups the measurement summaries by their environment ID.
  ///
  /// Useful for displaying data grouped by environment in the UI.
  Map<int, List<MeasurementSummary>> get measurementsByEnvironment {
    final summaries = kpi?.measurementSummaries ?? const <MeasurementSummary>[];
    final grouped = <int, List<MeasurementSummary>>{};
    for (final s in summaries) {
      grouped.putIfAbsent(s.environmentId, () => []).add(s);
    }
    return grouped;
  }

  /// Calculates the total sum of all readings across all measurement summaries.
  int get totalReadings =>
      (kpi?.measurementSummaries ?? const <MeasurementSummary>[])
          .fold(0, (sum, s) => sum + s.readings);

  /// Indicates if all data requests failed, used to show a global error state.
  bool get everythingFailed => kpiFailure != null && trends.failed && reports.failed;

  @override
  List<Object?> get props => [kpi, kpiFailure, trends, reports, environmentNames, deviceNames];
}

/// Facade service for the Reporting context.
///
/// It exposes the use cases of Reporting & Audit to the presentation layer and to
/// the other contexts (through `ReportingApi`). It only orchestrates: the rules
/// live in [ReportingLogic] and the data access behind [ReportingInterface].
class ReportingFacadeService with ReportingLogic {
  ReportingFacadeService({
    required ReportingInterface repository,
    required LaboratoryApi laboratoryApi,
    required EquipmentApi equipmentApi,
    DateTime Function()? clock,
  }) : _repository = repository,
       _laboratoryApi = laboratoryApi,
       _equipmentApi = equipmentApi,
       _clock = clock ?? DateTime.now;

  final ReportingInterface _repository;
  final LaboratoryApi _laboratoryApi;
  final EquipmentApi _equipmentApi;
  final DateTime Function() _clock;

  /// KPI dashboard of the laboratory for the selected [period].
  Future<KpiDashboard> getKpiDashboard(LaboratoryId laboratoryId, ReportPeriod period, {int? environmentId}) {
    final to = _clock();
    return _repository.getKpiDashboard(
      laboratoryId,
      from: to.subtract(period.duration),
      to: to,
      environmentId: environmentId,
    );
  }

  /// History of generated reports, newest first.
  Future<List<AuditReport>> getReportHistory(LaboratoryId laboratoryId) async =>
      sortReportsNewestFirst(await _repository.getLaboratoryReports(laboratoryId));

  /// Deviation trends of every given environment (the backend lists them per
  /// environment), most severe first.
  Future<List<DeviationTrend>> getDeviationTrends(
    LaboratoryId laboratoryId,
    Iterable<int> environmentIds,
    ReportPeriod period,
  ) async {
    final to = _clock();
    final from = to.subtract(period.duration);
    final trends = await loadAll(
      environmentIds,
      (environmentId) => _repository.getDeviationTrends(laboratoryId, environmentId, from: from, to: to),
    );
    return sortTrendsBySeverity(trends);
  }

  /// Audit trail of one equipment, newest first.
  Future<List<AuditLogEntry>> getEquipmentAuditLogs(LaboratoryId laboratoryId, int equipmentId) async =>
      sortAuditLogsNewestFirst(await _repository.getEquipmentAuditLogs(laboratoryId, equipmentId));

  /// Audit trail of one batch, newest first.
  Future<List<AuditLogEntry>> getBatchAuditLogs(int batchId) async =>
      sortAuditLogsNewestFirst(await _repository.getBatchAuditLogs(batchId));

  /// Loads and consolidates all data needed for the reports screen.
  ///
  /// It fetches dependency data (environments and equipment) concurrently,
  /// handles partial failures (e.g., if KPIs fail, the rest is still shown),
  /// and returns a fully populated [ReportsData] object.
  ///
  /// @param lab The current laboratory identifier.
  /// @param period The selected time period.
  /// @return A [Future] containing the [ReportsData] ready for the UI.
  Future<ReportsData> loadReportsData(LaboratoryId lab, ReportPeriod period) async {
    // 1. Fetch data from other contexts concurrently
    final results = await Future.wait<Object>([_laboratoryApi.getEnvironments(lab), _equipmentApi.getEquipments(lab)]);
    final environments = results[0] as List<LabEnvironment>;
    final equipments = results[1] as List<Equipment>;

    // 2. Fetch KPI data in isolation (if it fails, the rest of the screen loads)
    KpiDashboard? kpi;
    Failure? kpiFailure;
    try {
      kpi = await getKpiDashboard(lab, period);
    } catch (e) {
      // Rethrow critical auth errors that must be handled by the upper layers
      if (e is UnauthorizedFailure || e is OnboardingRequiredFailure) rethrow;
      kpiFailure = Failure.from(e);
    }

    // 3. Fetch secondary sections concurrently
    final sections = await Future.wait<Object>([
      Section.load(() => getDeviationTrends(lab, environments.map((e) => e.id), period)),
      Section.load(() => getReportHistory(lab)),
    ]);

    // 4. Return the packaged data
    return ReportsData(
      kpi: kpi,
      kpiFailure: kpiFailure,
      trends: sections[0] as Section<DeviationTrend>,
      reports: sections[1] as Section<AuditReport>,
      environmentNames: {for (final e in environments) e.id: e.name},
      deviceNames: {for (final e in equipments) e.id: e.name},
    );
  }
}
