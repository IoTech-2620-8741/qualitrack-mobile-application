import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/batch/api/index.dart';
import 'package:qualitrack_mobile/command_center/application/get_command_center_summary.dart';
import 'package:qualitrack_mobile/compliance/api/index.dart';
import 'package:qualitrack_mobile/command_center/presentation/bloc/command_center_bloc.dart';
import 'package:qualitrack_mobile/command_center/presentation/command_center_views.dart';
import 'package:qualitrack_mobile/command_center/presentation/screens/command_center_screen.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/laboratory/api/index.dart';
import 'package:qualitrack_mobile/tracking/api/index.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class _MockHomeBloc extends MockBloc<CommandCenterRequested, RemoteState<CommandCenterSummary>>
    implements CommandCenterBloc {}

CommandCenterSummary _summary() {
  final now = DateTime.now();
  final equipments = [for (var i = 1; i <= 9; i++) equipmentFixture(id: i, name: 'Device $i')];
  return CommandCenterSummary(
    laboratory: const Part.ok(Laboratory(id: 7, name: 'QualiLab Lima')),
    equipment: Part.ok(
      EquipmentSnapshot(
        equipments: equipments,
        connections: {
          for (var i = 1; i <= 6; i++) i: DeviceConnection(deviceId: i, status: ConnectionStatus.connected),
          7: const DeviceConnection(deviceId: 7, status: ConnectionStatus.requiresReview),
        },
      ),
    ),
    batches: Part.ok(
      BatchOverview(
        summary: const BatchSummary(total: 9, pending: 2, inProgress: 3, released: 4, rejected: 0),
        recent: [batchFixture(id: 9, batchNumber: 'LOT-2026-0009')],
      ),
    ),
    alerts: Part.ok(
      AlertOverview(
        summary: const AlertSummary(total: 4, unresolved: 3, acknowledged: 1, resolved: 0, critical: 2),
        open: [
          alertFixture(id: 1, equipmentId: 1, timestamp: now.subtract(const Duration(hours: 2))),
          alertFixture(id: 2, equipmentId: 2, timestamp: now.subtract(const Duration(days: 2))),
          alertFixture(
            id: 3,
            equipmentId: 3,
            severity: AlertSeverity.warning,
            timestamp: now.subtract(const Duration(days: 4)),
          ),
        ],
      ),
    ),
    materials: Part.ok([materialFixture(), materialFixture(id: 2, usable: 9, stockStatus: 'OK')]),
    subscription: null,
  );
}

CommandCenterViews _views() => CommandCenterViews(
  notificationBell: const SizedBox.square(dimension: 48),
  profileButton: const SizedBox.square(dimension: 48),
  profileChanges: ChangeNotifier(),
  displayName: () => 'Ana Torres',
  roleLabel: (role, i18n) => 'QA Manager',
  alertCard: (alert, {deviceName, environmentName, onTap}) => const SizedBox.shrink(),
  batchStatusBadge: (status) => const Text('Pending'),
);

void main() {
  late _MockHomeBloc bloc;

  setUp(() {
    bloc = _MockHomeBloc();
    whenListen(
      bloc,
      const Stream<RemoteState<CommandCenterSummary>>.empty(),
      initialState: const RemoteState<CommandCenterSummary>().success(_summary()),
    );
  });

  Future<void> pumpHome(WidgetTester tester, Size size, {double textScale = 1}) => tester.pumpLocalized(
    MediaQuery.withClampedTextScaling(
      minScaleFactor: textScale,
      maxScaleFactor: textScale,
      child: BlocProvider<CommandCenterBloc>.value(
        value: bloc,
        child: CommandCenterScreen(session: sessionFixture(), views: _views()),
      ),
    ),
    size: size,
  );

  // The Home must fit the viewport without overflowing and without scrolling.
  for (final (name, size, scale) in [
    ('small phone', const Size(360, 640), 1.0),
    ('large phone', const Size(412, 915), 1.0),
    ('landscape', const Size(800, 360), 1.0),
    ('large text', const Size(360, 740), 1.3),
  ]) {
    testWidgets('Home fits a $name without overflow', (tester) async {
      await pumpHome(tester, size, textScale: scale);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Hello, Ana Torres'), findsOneWidget);
      expect(find.text('Most urgent alert'), findsOneWidget);
      // One card per area, in the order of the Web menu.
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('Production batches'), lessThan(top('Equipment')));
      expect(top('Equipment'), equals(top('Telemetry')));
      expect(top('Telemetry'), lessThan(top('Most urgent alert')));
      expect(top('Most urgent alert'), lessThan(top('Inventory')));
      expect(find.text('2 critical'), findsOneWidget);
      expect(find.text('1 materials are below the minimum stock'), findsOneWidget);
    });
  }
}
