import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/common/application/section.dart';
import 'package:qualitrack_mobile/reporting/application/reporting_facade_service.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/deviation_entities.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/kpi_entities.dart';
import 'package:qualitrack_mobile/reporting/domain/entities/reporting_enums.dart';
import 'package:qualitrack_mobile/reporting/presentation/tabs/deviations_tab.dart';
import 'package:qualitrack_mobile/reporting/presentation/tabs/measurements_tab.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('the deviations tab counts a single deviation in the singular', (tester) async {
    const data = ReportsData(
      kpi: null,
      trends: Section([
        DeviationTrend(
          parameterName: 'TEMPERATURE',
          equipmentId: 10,
          direction: TrendDirection.stable,
          evaluatedReadings: 12,
          deviationCount: 1,
          criticalDeviationCount: 1,
        ),
      ]),
      reports: Section.empty(),
      deviceNames: {10: 'Stability Chamber'},
    );
    final tab = Scaffold(body: DeviationsTab(data: data, onReload: () {}, onSeeLast31Days: null));

    await tester.pumpLocalized(tab);
    expect(find.text('Stability Chamber · 1 deviation · 1 critical'), findsOneWidget);

    await tester.pumpLocalized(tab, locale: const Locale('es'));
    expect(find.text('Stability Chamber · 1 desviación · 1 crítica'), findsOneWidget);
  });

  testWidgets('the measurements tab counts a single reading in the singular', (tester) async {
    const data = ReportsData(
      kpi: KpiDashboard(
        laboratoryId: 7,
        measurementSummaries: [
          MeasurementSummary(environmentId: 3, deviceId: 10, metric: 'TEMPERATURE', readings: 1, unit: '°C', average: 6.5),
        ],
      ),
      trends: Section.empty(),
      reports: Section.empty(),
      environmentNames: {3: 'Cold storage'},
    );
    final tab = Scaffold(body: MeasurementsTab(data: data, onReload: () {}, onSeeLast31Days: null));

    await tester.pumpLocalized(tab);
    expect(find.text('1 reading per variable'), findsOneWidget);

    await tester.pumpLocalized(tab, locale: const Locale('es'));
    expect(find.text('1 lectura por variable'), findsOneWidget);
  });
}
