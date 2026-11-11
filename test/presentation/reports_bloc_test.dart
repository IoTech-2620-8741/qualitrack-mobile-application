import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/application/section.dart';
import 'package:qualitrack_mobile/common/domain/failure.dart';
import 'package:qualitrack_mobile/common/domain/value_objects.dart';
import 'package:qualitrack_mobile/equipment/api/index.dart';
import 'package:qualitrack_mobile/equipment/application/equipment_facade_service.dart';
import 'package:qualitrack_mobile/laboratory/api/index.dart';
import 'package:qualitrack_mobile/laboratory/application/laboratory_facade_service.dart';
import 'package:qualitrack_mobile/reporting/application/reporting_facade_service.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/audit_entities.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/deviation_entities.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/reporting_enums.dart';
import 'package:qualitrack_mobile/reporting/presentation/bloc/reports_bloc.dart';

import '../helpers/mocks.dart';

class _MockReportingFacade extends Mock implements ReportingFacadeService {}

const _lab = LaboratoryId(7);

/// Reports data told apart by the name of environment 1.
ReportsData _data(String marker) => ReportsData(
  kpi: null,
  trends: const Section<DeviationTrend>.empty(),
  reports: const Section<AuditReport>.empty(),
  environmentNames: {1: marker},
);

void main() {
  group('ReportsBloc', () {
    late _MockReportingFacade facade;
    late Completer<ReportsData> week;
    late Completer<ReportsData> month;

    setUp(() {
      facade = _MockReportingFacade();
      week = Completer();
      month = Completer();
      when(() => facade.loadReportsData(_lab, ReportPeriod.last7Days)).thenAnswer((_) => week.future);
      when(() => facade.loadReportsData(_lab, ReportPeriod.last31Days)).thenAnswer((_) => month.future);
    });

    Future<ReportsBloc> pickWeekThenMonth() async {
      final bloc = ReportsBloc(reportingService: facade, laboratoryId: () => _lab);
      bloc.add(const ReportsPeriodChanged(ReportPeriod.last7Days));
      await pumpEventQueue();
      bloc.add(const ReportsPeriodChanged(ReportPeriod.last31Days));
      await pumpEventQueue();
      return bloc;
    }

    test('a slow answer of the period picked before never replaces the period on screen', () async {
      final bloc = await pickWeekThenMonth();

      month.complete(_data('31 days'));
      await pumpEventQueue();
      week.complete(_data('7 days'));
      await pumpEventQueue();

      expect(bloc.state.period, ReportPeriod.last31Days);
      expect(bloc.state.remote.data?.environmentNames[1], '31 days');
      await bloc.close();
    });

    test('nor does its failure', () async {
      final bloc = await pickWeekThenMonth();

      month.complete(_data('31 days'));
      await pumpEventQueue();
      week.completeError(const ServerFailure());
      await pumpEventQueue();

      expect(bloc.state.remote.failure, isNull);
      expect(bloc.state.remote.data?.environmentNames[1], '31 days');
      await bloc.close();
    });

    test('the latest period is shown when its answer arrives last', () async {
      final bloc = await pickWeekThenMonth();

      week.complete(_data('7 days'));
      await pumpEventQueue();
      month.complete(_data('31 days'));
      await pumpEventQueue();

      expect(bloc.state.remote.data?.environmentNames[1], '31 days');
      await bloc.close();
    });
  });

  group('ReportingFacadeService', () {
    test('an unexpected error of the indicators leaves the rest of the screen', () async {
      final reporting = MockReportingRepository();
      final laboratories = MockLaboratoryRepository();
      final equipment = MockEquipmentRepository();
      when(() => laboratories.getEnvironments(_lab)).thenAnswer((_) async => const []);
      when(() => equipment.getByLaboratory(_lab)).thenAnswer((_) async => const []);
      when(
        () => reporting.getKpiDashboard(
          _lab,
          from: any(named: 'from'),
          to: any(named: 'to'),
          environmentId: any(named: 'environmentId'),
        ),
      )
          .thenThrow(StateError('not a failure'));
      when(() => reporting.getLaboratoryReports(_lab)).thenAnswer((_) async => const []);
      final service = ReportingFacadeService(
        repository: reporting,
        laboratoryApi: LaboratoryApi(LaboratoryFacadeService(repository: laboratories)),
        equipmentApi: EquipmentApi(EquipmentFacadeService(repository: equipment)),
      );

      final data = await service.loadReportsData(_lab, ReportPeriod.last24Hours);

      expect(data.kpiFailure, isA<UnexpectedFailure>());
      expect(data.reports.failed, isFalse);
      expect(data.everythingFailed, isFalse);
    });
  });
}
