import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/connection_status.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/device_connection.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_state.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/telemetry_target.dart';
import 'package:qualitrack_mobile/tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import 'package:qualitrack_mobile/tracking/presentation/screens/telemetry_dashboard_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockTelemetryDashboardBloc extends MockBloc<TelemetryEvent, TelemetryState> implements TelemetryDashboardBloc {}

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
}
