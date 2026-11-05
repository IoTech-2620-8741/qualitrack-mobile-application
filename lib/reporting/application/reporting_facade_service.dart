/// This file contains the Application Facade (Service) for the Reporting context.
///
/// It acts as an orchestrator that combines data from multiple contexts
/// (Laboratory, Equipment) and packages it into a single [ReportsData] object,
/// ready to be consumed by the Presentation layer (BLoC).
///
/// @author Vitaly Baca Camargo
///

import '../../equipment/application/equipment_queries.dart';
import '../../equipment/domain/equipment.dart';
import '../../laboratory/application/laboratory_queries.dart';
import '../../laboratory/domain/laboratory.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../../shared/presentation/section.dart';
import '../domain/entities/audit_entities.dart';
import '../domain/entities/deviation_entities.dart';
import '../domain/entities/kpi_entities.dart';
import '../domain/entities/reporting_enums.dart';
import '../domain/logic/reporting_logic.dart';
import 'reporting_queries.dart';
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

  /// Returns the list of deviation trends sorted by severity
  /// (Critical > Warning > On Track > No Data).
  List<DeviationTrend> get sortedTrends => sortTrendsBySeverity(trends.items);

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
/// This class simplifies the interaction between the Presentation layer (BLoC)
/// and the multiple use cases (Queries) needed to build the screen.
class ReportingFacadeService {
  const ReportingFacadeService({
    required this.getKpiDashboard,
    required this.getDeviationTrends,
    required this.getReportHistory,
    required this.getEnvironments,
    required this.getEquipments,
  });

  final GetKpiDashboard getKpiDashboard;
  final GetDeviationTrends getDeviationTrends;
  final GetReportHistory getReportHistory;
  final GetEnvironments getEnvironments;
  final GetEquipments getEquipments;

  /// Loads and consolidates all data needed for the reports screen.
  ///
  /// It fetches dependency data (environments and equipment) concurrently,
  /// handles partial failures (e.g., if KPIs fail, the rest is still shown),
  /// and returns a fully populated [ReportsData] object.
  ///
  /// @param lab The current laboratory identifier.
  /// @param period The selected time period.
  /// @return A [Future] containing the [ReportsData] ready for the UI.
  ///
  Future<ReportsData> loadReportsData(LaboratoryId lab, ReportPeriod period) async {
    // 1. Fetch data from other contexts concurrently
    final results = await Future.wait<Object>([getEnvironments(lab), getEquipments(lab)]);
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
      kpiFailure = e as Failure;
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