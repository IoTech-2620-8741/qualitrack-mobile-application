import '../../equipment/application/equipment_queries.dart';
import '../../equipment/domain/equipment.dart';
import '../../laboratory/application/laboratory_queries.dart';
import '../../laboratory/domain/laboratory.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../../shared/presentation/section.dart';
import '../domain/entities/reporting_entities.dart';
import 'reporting_queries.dart';
import 'package:equatable/equatable.dart';

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

  bool get everythingFailed => kpiFailure != null && trends.failed && reports.failed;

  @override
  List<Object?> get props => [kpi, kpiFailure, trends, reports, environmentNames, deviceNames];
}

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

  Future<ReportsData> loadReportsData(LaboratoryId lab, ReportPeriod period) async {
    final results = await Future.wait<Object>([getEnvironments(lab), getEquipments(lab)]);
    final environments = results[0] as List<LabEnvironment>;
    final equipments = results[1] as List<Equipment>;

    KpiDashboard? kpi;
    Failure? kpiFailure;
    try {
      kpi = await getKpiDashboard(lab, period);
    } catch (e) {
      if (e is UnauthorizedFailure || e is OnboardingRequiredFailure) rethrow;
      kpiFailure = e as Failure;
    }

    final sections = await Future.wait<Object>([
      Section.load(() => getDeviationTrends(lab, environments.map((e) => e.id), period)),
      Section.load(() => getReportHistory(lab)),
    ]);

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