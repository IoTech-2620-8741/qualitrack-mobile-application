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

  /// The Home as the app shows it: under the status bar and above the
  /// navigation bar of the shell.
  Future<void> pumpHome(WidgetTester tester, Size size, {double textScale = 1}) async {
    await tester.pumpLocalized(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(
          body: BlocProvider<CommandCenterBloc>.value(
            value: bloc,
            child: CommandCenterScreen(session: sessionFixture(), views: _views()),
          ),
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.space_dashboard), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
            ],
          ),
        ),
      ),
      size: size,
    );
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pump();
  }

  double scrollExtent(WidgetTester tester) =>
      tester
          .state<ScrollableState>(
            find.descendant(of: find.byType(CommandCenterScreen), matching: find.byType(Scrollable)).first,
          )
          .position
          .maxScrollExtent;

  // Four cards, two per row, read by importance top to bottom and left to
  // right; the Home never scrolls nor shrinks at the normal text size.
  for (final (name, size, full) in [
    ('common phone', const Size(360, 800), true),
    ('large phone', const Size(412, 915), true),
    ('small phone', const Size(360, 640), false),
  ]) {
    testWidgets('Home shows the four cards on a $name without scrolling', (tester) async {
      await pumpHome(tester, size);

      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), 0);
      expect(find.text('Hello, Ana Torres'), findsOneWidget);
      final alerts = tester.getTopLeft(find.text('Alerts'));
      final telemetry = tester.getTopLeft(find.text('Telemetry'));
      final batches = tester.getTopLeft(find.text('Batches'));
      final inventory = tester.getTopLeft(find.text('Inventory'));
      expect(telemetry.dy, alerts.dy);
      expect(telemetry.dx, greaterThan(alerts.dx));
      expect(batches.dx, alerts.dx);
      expect(batches.dy, greaterThan(alerts.dy));
      expect(inventory.dy, batches.dy);
      expect(inventory.dx, telemetry.dx);
      // The figures stay in every size.
      expect(find.text('2 critical'), findsOneWidget);
      expect(find.text('Awaiting QA release'), findsOneWidget);
      expect(find.text('Below minimum'), findsOneWidget);
      // A short screen leaves the detail out instead of shrinking the cards.
      expect(find.text('Released 4'), full ? findsOneWidget : findsNothing);
      expect(find.text('2 materials'), full ? findsOneWidget : findsNothing);
      // Touch targets of at least 48 dp (Report: operators with gloves).
      for (final card in find.byType(InkWell).evaluate()) {
        expect(tester.getRect(find.byWidget(card.widget)).height, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('Home keeps the text size the user chose', (tester) async {
    await pumpHome(tester, const Size(360, 800));
    final normal = tester.getRect(find.text('Alerts')).height;

    await pumpHome(tester, const Size(360, 800), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('Alerts')).height / normal, closeTo(1.3, 0.05));
    // Compact cards fit 130% text (the Report supports up to sp × 1.3).
    expect(scrollExtent(tester), 0);
  });

  testWidgets('Home scrolls instead of shrinking when even the compact cards do not fit', (tester) async {
    await pumpHome(tester, const Size(360, 640), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), greaterThan(0));
  });
}
