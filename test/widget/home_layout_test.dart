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

CommandCenterSummary _summary({bool openAlerts = true}) {
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
    alerts:
        !openAlerts
            ? const Part.ok(
              AlertOverview(
                summary: AlertSummary(total: 2, unresolved: 0, acknowledged: 0, resolved: 2, critical: 0),
                open: [],
              ),
            )
            : Part.ok(
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
    fetchedAt: now.subtract(const Duration(minutes: 5)),
  );
}

CommandCenterViews _views() => CommandCenterViews(
  notificationBell: const SizedBox.square(dimension: 48),
  profileButton: const SizedBox.square(dimension: 48),
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
      // A sober header: the laboratory, the role and how current the figures are.
      expect(find.text('QualiLab Lima'), findsOneWidget);
      expect(find.text('QA Manager · Updated 5 min ago'), findsOneWidget);
      // Every card says it opens a screen.
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
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
      expect(find.text('of 9 batches'), full ? findsOneWidget : findsNothing);
      expect(find.text('of 2 materials'), full ? findsOneWidget : findsNothing);
      // One line of context instead of a full legend.
      expect(find.text('3 unattended'), full ? findsOneWidget : findsNothing);
      expect(find.textContaining('Acknowledged'), findsNothing);
      // Touch targets of at least 48 dp (Report: operators with gloves).
      for (final title in ['Alerts', 'Telemetry', 'Batches', 'Inventory']) {
        final card = find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('the cards keep their own height and the latest alerts fill the rest', (tester) async {
    await pumpHome(tester, const Size(412, 915));

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), 0);
    // Not stretched to share the whole screen: a card is as tall as its content.
    final alertsCard = find.ancestor(of: find.text('Alerts'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(alertsCard).height, lessThan(260));
    // The latest alerts, most urgent first (critical and most recent), only
    // whole cards and all of them above the navigation bar.
    expect(find.text('Latest alerts'), findsOneWidget);
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

  testWidgets('without open alerts the latest alerts are left out, not repeated', (tester) async {
    whenListen(
      bloc,
      const Stream<RemoteState<CommandCenterSummary>>.empty(),
      initialState: const RemoteState<CommandCenterSummary>().success(_summary(openAlerts: false)),
    );
    await pumpHome(tester, const Size(412, 915));

    expect(tester.takeException(), isNull);
    expect(find.text('No open alerts'), findsOneWidget);
    expect(find.text('Latest alerts'), findsNothing);
    expect(find.text('View all'), findsNothing);
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

  testWidgets('while loading, Home shows the shape of its cards instead of a spinner', (tester) async {
    whenListen(
      bloc,
      const Stream<RemoteState<CommandCenterSummary>>.empty(),
      initialState: const RemoteState<CommandCenterSummary>().loading(),
    );
    await pumpHome(tester, const Size(360, 800));

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    // Without the figures yet, the title falls back to the section name.
    expect(find.text('Home'), findsWidgets);
  });

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
