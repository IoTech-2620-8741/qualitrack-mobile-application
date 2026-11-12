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
  // An alert card of a fixed height, named after its alert and its device.
  alertCard: (alert, {deviceName, environmentName, onTap}) =>
      SizedBox(height: 90, child: Text('alert ${alert.id} · $deviceName')),
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

  // A status strip and four rows read by importance top to bottom; the Home
  // never scrolls nor shrinks at the normal text size.
  for (final (name, size) in [
    ('common phone', const Size(360, 800)),
    ('large phone', const Size(412, 915)),
    ('small phone', const Size(360, 640)),
  ]) {
    testWidgets('Home shows the status and the four rows on a $name without scrolling', (tester) async {
      await pumpHome(tester, size);

      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), 0);
      // The first name greets; the full name stays in the profile.
      expect(find.text('Hello, Ana'), findsOneWidget);
      expect(find.text('Needs attention: 2 critical alerts'), findsOneWidget);
      final alerts = tester.getTopLeft(find.text('Open alerts'));
      final telemetry = tester.getTopLeft(find.text('devices online'));
      final batches = tester.getTopLeft(find.text('Awaiting QA release'));
      final inventory = tester.getTopLeft(find.text('Below minimum'));
      expect(telemetry.dy, greaterThan(alerts.dy));
      expect(batches.dy, greaterThan(telemetry.dy));
      expect(inventory.dy, greaterThan(batches.dy));
      // The figures and the critical badge stay in every size.
      expect(find.text('6/9'), findsOneWidget);
      expect(find.text('2 critical'), findsOneWidget);
      // Severity (the badge) and status (the detail) are told apart; the
      // rows are short enough to keep their detail even on a small phone.
      expect(find.text('3 unresolved · 1 acknowledged'), findsOneWidget);
      expect(find.text('2 pending · 3 in progress'), findsOneWidget);
      expect(find.text('of 2 materials'), findsOneWidget);
      // No breakdown of released or rejected batches on Home.
      expect(find.textContaining('Released'), findsNothing);
      // Touch targets of at least 48 dp (Report: operators with gloves).
      for (final label in ['Open alerts', 'devices online', 'Awaiting QA release', 'Below minimum']) {
        final row = find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('the rows keep their own height and the most urgent alerts fill the rest', (tester) async {
    await pumpHome(tester, const Size(412, 915));

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), 0);
    // Not stretched to share the whole screen: a row is as tall as its content.
    final alertsRow = find.ancestor(of: find.text('Open alerts'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(alertsRow).height, lessThan(120));
    // The most urgent alerts (critical and most recent first), only whole
    // cards and all of them above the navigation bar.
    expect(find.text('Most urgent'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    final shown = [
      for (final id in [1, 2, 3])
        if (find.text('alert $id · Device $id').hitTestable().evaluate().isNotEmpty) id,
    ];
    expect(shown, isNotEmpty);
    expect(shown, [for (var id = 1; id <= shown.length; id++) id]);
    final barTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    for (final id in shown) {
      final card = find.ancestor(of: find.text('alert $id · Device $id'), matching: find.byType(SizedBox)).first;
      expect(tester.getRect(card).height, 90);
      expect(tester.getRect(card).bottom, lessThanOrEqualTo(barTop));
    }
  });

  testWidgets('a short screen shows fewer latest alerts, never half a card', (tester) async {
    await pumpHome(tester, const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), 0);
    final barTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    for (final id in [1, 2, 3]) {
      final card = find.text('alert $id · Device $id');
      if (card.hitTestable().evaluate().isEmpty) continue;
      expect(tester.getRect(find.ancestor(of: card, matching: find.byType(SizedBox)).first).bottom, lessThanOrEqualTo(barTop));
    }
  });

  testWidgets('Home keeps the text size the user chose', (tester) async {
    await pumpHome(tester, const Size(360, 800));
    final normal = tester.getRect(find.text('Hello, Ana')).height;

    await pumpHome(tester, const Size(360, 800), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('Hello, Ana')).height / normal, closeTo(1.3, 0.05));
    // The rows fit 130% text (the Report supports up to sp × 1.3).
    expect(scrollExtent(tester), 0);
  });

  testWidgets('Home scrolls instead of shrinking when even the compact rows do not fit', (tester) async {
    await pumpHome(tester, const Size(360, 640), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), greaterThan(0));
  });
}
