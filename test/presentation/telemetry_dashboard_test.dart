import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/equipment.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/iot_device_type.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/connection_status.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/device_connection.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_profile.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_state.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/measurement.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/metric_threshold.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/monitored_metric.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/telemetry_target.dart';
import 'package:qualitrack_mobile/tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import 'package:qualitrack_mobile/tracking/presentation/screens/telemetry_dashboard_screen.dart';
import 'package:qualitrack_mobile/tracking/presentation/widgets/reading_range_bar.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockTelemetryDashboardBloc extends MockBloc<TelemetryEvent, TelemetryState> implements TelemetryDashboardBloc {}

/// The screen with [devices] loaded and the telemetry of the first one.
TelemetryState telemetryState(
  List<Equipment> devices, {
  List<Measurement>? history,
  EnvironmentalProfile? profile,
}) => TelemetryState(
  catalog: RemoteState(
    status: ViewStatus.success,
    data: DeviceCatalog(devices: devices, environments: const [storage, production]),
  ),
  selectedDeviceId: devices.first.id,
  snapshot: RemoteState(
    status: ViewStatus.success,
    data: TelemetrySnapshot(
      target: TelemetryTarget(deviceId: devices.first.id, environmentId: 3, containerMonitor: true),
      connection: DeviceConnection(deviceId: devices.first.id, status: ConnectionStatus.connected),
      history: history ?? [measurementFixture()],
      profile: profile,
      fetchedAt: DateTime.now(),
    ),
  ),
);

Measurement reading(MonitoredMetric metric, double value, String unit, EnvironmentalState state, DateTime at) =>
    Measurement(
      id: metric.index,
      deviceId: 10,
      environmentId: 3,
      metric: metric,
      rawMetric: metric.code,
      value: value,
      unit: unit,
      state: state,
      measuredAt: at,
    );

void main() {
  testWidgets('counts a single deviation and a single charted reading in the singular', (tester) async {
    final bloc = MockTelemetryDashboardBloc();
    final device = equipmentFixture();
    when(() => bloc.state).thenReturn(
      TelemetryState(
        catalog: RemoteState(
          status: ViewStatus.success,
          data: DeviceCatalog(devices: [device], environments: const [storage]),
        ),
        selectedDeviceId: device.id,
        snapshot: RemoteState(
          status: ViewStatus.success,
          data: TelemetrySnapshot(
            target: const TelemetryTarget(deviceId: 10, environmentId: 3, containerMonitor: true),
            connection: const DeviceConnection(deviceId: 10, status: ConnectionStatus.connected),
            history: [measurementFixture(state: EnvironmentalState.critical)],
            fetchedAt: DateTime.now(),
          ),
        ),
      ),
    );
    final screen = BlocProvider<TelemetryDashboardBloc>.value(value: bloc, child: const TelemetryDashboardScreen());
    // Tall enough to build the chart, which sits below the readings.
    const tall = Size(360, 1600);

    // The axis labels of the chart are merged into its label, after the first line.
    Finder chartLabel(String firstLine) =>
        find.bySemanticsLabel(RegExp('^${RegExp.escape(firstLine)}\$', multiLine: true));

    await tester.pumpLocalized(screen, size: tall);
    expect(find.text('1 event'), findsOneWidget);
    expect(chartLabel('Telemetry chart with 1 reading °C'), findsOneWidget);

    await tester.pumpLocalized(screen, locale: const Locale('es'), size: tall);
    expect(find.text('1 evento'), findsOneWidget);
    expect(chartLabel('Gráfico de telemetría con 1 lectura °C'), findsOneWidget);
  });

  testWidgets('shows the device in a card and changes it from a sheet grouped by environment', (tester) async {
    final bloc = MockTelemetryDashboardBloc();
    final chamber = equipmentFixture();
    final monitor = equipmentFixture(
      id: 11,
      name: 'Line monitor',
      environmentId: 4,
      deviceType: IotDeviceType.environmentalDevice,
    );
    when(() => bloc.state).thenReturn(telemetryState([chamber, monitor]));

    await tester.pumpLocalized(
      BlocProvider<TelemetryDashboardBloc>.value(value: bloc, child: const TelemetryDashboardScreen()),
    );
    final card = find.byKey(const Key('telemetry.deviceSelector'));
    expect(find.descendant(of: card, matching: find.text('Stability Chamber')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Cold storage')), findsOneWidget);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Choose a device'), findsOneWidget);
    expect(find.text('COLD STORAGE'), findsOneWidget);
    expect(find.text('PRODUCTION LINE'), findsOneWidget);
    expect(find.text('Container monitor'), findsOneWidget);
    expect(find.text('Environmental device'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('telemetry.device.11')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => bloc.add(const TelemetryDeviceSelected(11))).called(1);
    expect(find.text('Choose a device'), findsNothing);
  });

  testWidgets('lists every reading with its state, a bar of its zones and its ranges', (tester) async {
    final bloc = MockTelemetryDashboardBloc();
    final at = DateTime.now().subtract(const Duration(hours: 14, minutes: 5));
    when(() => bloc.state).thenReturn(
      telemetryState(
        [equipmentFixture()],
        history: [
          reading(MonitoredMetric.temperature, 20.5, '°C', EnvironmentalState.normal, at),
          reading(MonitoredMetric.humidity, 64.8, '%RH', EnvironmentalState.warning, at),
        ],
        profile: const EnvironmentalProfile(
          version: 1,
          thresholds: [
            MetricThreshold(
              metric: MonitoredMetric.temperature,
              unit: '°C',
              normalMin: 15,
              normalMax: 30,
              criticalMin: 10,
              criticalMax: 36,
            ),
            MetricThreshold(
              metric: MonitoredMetric.humidity,
              unit: '%RH',
              normalMin: 35,
              normalMax: 60,
              criticalMin: 25,
              criticalMax: 70,
            ),
          ],
        ),
      ),
    );

    await tester.pumpLocalized(
      BlocProvider<TelemetryDashboardBloc>.value(value: bloc, child: const TelemetryDashboardScreen()),
      size: const Size(360, 1600),
    );

    expect(find.byType(ReadingRangeBar), findsNWidgets(2));
    expect(find.text('normal 15–30 °C · critical 10–36 °C'), findsOneWidget);
    expect(find.text('normal 35–60 %RH · critical 25–70 %RH'), findsOneWidget);
    // Both were taken at the same time, written once next to the title.
    expect(find.text('14 h ago'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Temperature, 20.5 °C, Normal, normal 15–30 °C · critical 10–36 °C'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Humidity, 64.8 %RH, Warning, normal 35–60 %RH · critical 25–70 %RH'),
      findsOneWidget,
    );
  });
}
