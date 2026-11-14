import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qualitrack_mobile/batch/api/index.dart';
import 'package:qualitrack_mobile/command_center/application/get_command_center_summary.dart';
import 'package:qualitrack_mobile/compliance/api/index.dart';
import 'package:qualitrack_mobile/command_center/presentation/bloc/command_center_bloc.dart';
import 'package:qualitrack_mobile/command_center/presentation/command_center_views.dart';
import 'package:qualitrack_mobile/command_center/presentation/screens/command_center_screen.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/status_badge.dart';
import 'package:qualitrack_mobile/iam/api/index.dart';
import 'package:qualitrack_mobile/inventory/api/index.dart';
import 'package:qualitrack_mobile/laboratory/api/index.dart';
import 'package:qualitrack_mobile/tracking/api/index.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class _MockHomeBloc extends MockBloc<CommandCenterRequested, RemoteState<CommandCenterSummary>>
    implements CommandCenterBloc {}

CommandCenterSummary _summary({
  bool openAlerts = true,
  List<DeviationAlert>? open,
  int pending = 2,
  int inProgress = 3,
  List<InventoryMaterial>? materials,
}) {
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
        summary: BatchSummary(
          total: 4 + pending + inProgress,
          pending: pending,
          inProgress: inProgress,
          released: 4,
          rejected: 0,
        ),
        recent: [batchFixture(id: 9, batchNumber: 'LOT-2026-0009')],
      ),
    ),
    alerts:
        open != null
            ? Part.ok(AlertOverview(summary: AlertSummary.of(open), open: open))
            : !openAlerts
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
    materials: Part.ok(materials ?? [materialFixture(), materialFixture(id: 2, usable: 9, stockStatus: 'OK')]),
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

  /// The bloc holding [summary], as after a successful load.
  void stubSummary(CommandCenterSummary summary) => whenListen(
    bloc,
    const Stream<RemoteState<CommandCenterSummary>>.empty(),
    initialState: const RemoteState<CommandCenterSummary>().success(summary),
  );

  // Whether the Home fits depends on real text widths: lay it out with the app's
  // font, Rubik, not with the test font, whose glyphs are much wider.
  setUpAll(() async {
    final rubik = FontLoader('Rubik')..addFont(rootBundle.load('assets/fonts/rubik/Rubik-VariableFont_wght.ttf'));
    await rubik.load();
  });

  setUp(() {
    bloc = _MockHomeBloc();
    stubSummary(_summary());
  });

  /// The Home inside the navigation bar of the shell.
  Widget home({UserSession? session}) => Scaffold(
    body: BlocProvider<CommandCenterBloc>.value(
      value: bloc,
      child: CommandCenterScreen(session: session ?? sessionFixture(), views: _views()),
    ),
    bottomNavigationBar: NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.space_dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
      ],
    ),
  );

  /// The Home as the app shows it: under the status bar and above the
  /// navigation bar of the shell.
  Future<void> pumpHome(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
    UserSession? session,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpLocalized(
      MediaQuery.withClampedTextScaling(minScaleFactor: textScale, maxScaleFactor: textScale, child: home(session: session)),
      size: size,
      locale: locale,
    );
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pump();
  }

  /// The Home with [summary] inside a router, to follow where it leads: each
  /// detail screen is a text with its name and id.
  Future<GoRouter> pumpHomeWithRouter(WidgetTester tester, CommandCenterSummary summary, {UserSession? session}) async {
    stubSummary(summary);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => home(session: session)),
        for (final (path, name) in [('alerts', 'alert'), ('batches', 'batch'), ('equipment', 'equipment')])
          GoRoute(path: '/$path/:id', builder: (context, state) => Text('$name ${state.pathParameters['id']}')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpLocalizedRouter(router, size: const Size(360, 800));
    return router;
  }

  /// A text as the user reads it: a non-breaking space looks like a space.
  Finder readsAs(String text) =>
      find.byWidgetPredicate((widget) => widget is Text && widget.data?.replaceAll(' ', ' ') == text);

  /// The lines [text] takes on screen.
  int lineCount(WidgetTester tester, Finder text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
    final whole = TextSelection(baseOffset: 0, extentOffset: paragraph.text.toPlainText().length);
    return paragraph.getBoxesForSelection(whole).map((box) => box.top).toSet().length;
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
      // A sober header: the laboratory, the role and how current the figures are.
      expect(find.text('QualiLab Lima'), findsOneWidget);
      expect(find.text('QA Manager'), findsOneWidget);
      expect(find.text('Updated 5 min ago'), findsOneWidget);
      expect(find.text('Needs attention: 2 critical alerts'), findsOneWidget);
      final alerts = tester.getTopLeft(find.text('Open alerts'));
      final telemetry = tester.getTopLeft(find.text('Devices online'));
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
      expect(readsAs('3 unresolved · 1 acknowledged'), findsOneWidget);
      expect(readsAs('2 pending · 3 in progress'), findsOneWidget);
      expect(find.text('of 2 materials'), findsOneWidget);
      // No breakdown of released or rejected batches on Home.
      expect(find.textContaining('Released'), findsNothing);
      // Touch targets of at least 48 dp (Report: operators with gloves).
      for (final label in ['Open alerts', 'Devices online', 'Awaiting QA release', 'Below minimum']) {
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

  testWidgets('without open alerts the latest alerts are left out, not repeated', (tester) async {
    stubSummary(_summary(openAlerts: false));
    await pumpHome(tester, const Size(412, 915));

    expect(tester.takeException(), isNull);
    expect(find.text('No open alerts'), findsOneWidget);
    expect(find.text('Most urgent'), findsNothing);
    expect(find.text('View all'), findsNothing);
  });

  testWidgets('devices without data show as to review, in grey', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    expect(find.text('3 to review'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.signal_wifi_off)).color, BadgeTone.neutral.foreground);
  });

  testWidgets('the row figures take the H2 size of the style guide, 18 sp', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    for (final figure in ['4', '6/9', '5', '1']) {
      expect(tester.widget<Text>(find.text(figure)).style?.fontSize, 18, reason: figure);
    }
  });

  testWidgets('the devices online keep the figure size and their total goes smaller, in the body size', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    final figure = tester.widget<Text>(find.text('6/9'));
    final total = (figure.textSpan! as TextSpan).children!.single as TextSpan;
    expect(figure.style?.fontSize, 18);
    expect(total.text, '/9');
    expect(total.style?.fontSize, 14);
  });

  testWidgets('the critical banner opens the most urgent unattended critical alert', (tester) async {
    final now = DateTime.now();
    await pumpHomeWithRouter(
      tester,
      _summary(
        open: [
          alertFixture(id: 7, status: AlertStatus.acknowledged, timestamp: now.subtract(const Duration(minutes: 5))),
          alertFixture(id: 8, timestamp: now.subtract(const Duration(hours: 3))),
        ],
      ),
    );

    await tester.tap(find.text('View detail'));
    await tester.pumpAndSettle();

    expect(find.text('alert 8'), findsOneWidget);
  });

  testWidgets('without critical alerts the strip offers no detail', (tester) async {
    await pumpHomeWithRouter(tester, _summary(openAlerts: false));

    expect(find.text('View detail'), findsNothing);
  });

  testWidgets('the critical banner keeps its message on one line, with View detail under it', (tester) async {
    // Beside the button, the Spanish message was cut into three lines at 360 dp.
    stubSummary(_summary(open: [alertFixture(id: 1)]));
    await pumpHome(tester, const Size(360, 800), locale: const Locale('es'));

    final message = find.text('Requiere atención: 1 alerta crítica');
    final button = find.widgetWithText(OutlinedButton, 'Ver detalle');
    expect(lineCount(tester, message), 1);
    expect(tester.getRect(button).top, greaterThanOrEqualTo(tester.getRect(message).bottom));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  });

  testWidgets('a body as tall as fullHeight fits the full panel without scrolling', (tester) async {
    for (final (locale, detail) in const [(Locale('en'), 'of 2 materials'), (Locale('es'), 'de 2 materiales')]) {
      await pumpHome(tester, const Size(360, 800), locale: locale);
      final chrome = 800 - tester.getSize(find.byType(CustomScrollView)).height;

      await pumpHome(tester, Size(360, CommandCenterScreen.fullHeight + chrome), locale: locale);

      expect(tester.takeException(), isNull);
      expect(find.text(detail), findsOneWidget, reason: 'full rows in $locale');
      expect(scrollExtent(tester), 0, reason: '$locale');
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

  testWidgets('while loading, Home shows the shape of its rows instead of a spinner', (tester) async {
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
    final normal = tester.getRect(readsAs('3 unresolved · 1 acknowledged')).height;

    await pumpHome(tester, const Size(360, 800), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(tester.getRect(readsAs('3 unresolved · 1 acknowledged')).height / normal, closeTo(1.3, 0.05));
    // The rows fit 130% text (the Report supports up to sp × 1.3).
    expect(scrollExtent(tester), 0);
  });

  testWidgets('Home scrolls instead of shrinking when even the compact rows do not fit', (tester) async {
    await pumpHome(tester, const Size(360, 640), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(scrollExtent(tester), greaterThan(0));
  });

  testWidgets('the header gives the role and the update time a line each, inside the bar', (tester) async {
    // In Spanish a long role and the update time do not fit one line at 360 dp.
    for (final scale in [1.0, 1.3]) {
      await pumpHome(tester, const Size(360, 800), textScale: scale);

      expect(find.text('Updated 5 min ago'), findsOneWidget);
      final bar = tester.getRect(find.byType(AppBar));
      final role = tester.getRect(find.text('QA Manager'));
      final updated = tester.getRect(find.text('Updated 5 min ago'));
      expect(updated.top, greaterThanOrEqualTo(role.bottom));
      expect(updated.bottom, lessThanOrEqualTo(bar.bottom));
    }
  });

  testWidgets('a long detail wraps between its parts, never inside one', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: readsAs('3 unresolved · 1 acknowledged'), matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    // "1 acknowledged" starts the second line: the break falls after the separator.
    final acknowledged = paragraph.getOffsetForCaret(
      TextPosition(offset: paragraph.text.toPlainText().indexOf('1')),
      Rect.zero,
    );
    expect(acknowledged.dx, lessThan(1));
    expect(acknowledged.dy, greaterThan(0));
  });

  testWidgets('one acknowledged alert reads in the singular', (tester) async {
    await pumpHome(tester, const Size(360, 800), locale: const Locale('es'));

    expect(readsAs('3 sin resolver · 1 reconocida'), findsOneWidget);
  });

  testWidgets('a count of one reads in the singular', (tester) async {
    stubSummary(_summary(open: [alertFixture(id: 1)], pending: 1, materials: [materialFixture()]));
    await pumpHome(tester, const Size(360, 800), locale: const Locale('es'));

    expect(find.text('Requiere atención: 1 alerta crítica'), findsOneWidget);
    expect(find.text('1 crítica'), findsOneWidget);
    expect(readsAs('1 pendiente · 3 en proceso'), findsOneWidget);
    expect(find.text('de 1 material'), findsOneWidget);

    await pumpHome(tester, const Size(360, 800));

    expect(find.text('Needs attention: 1 critical alert'), findsOneWidget);
    expect(find.text('of 1 material'), findsOneWidget);
  });

  // Each role sees its own Home (style guide §7).
  testWidgets('an operator sees open alerts and batches in progress only', (tester) async {
    await pumpHome(tester, const Size(360, 800), session: sessionFixture(roles: [UserRole.labOperator]));

    expect(find.text('Batches in progress'), findsOneWidget);
    expect(find.text('Awaiting QA release'), findsNothing);
    expect(find.byIcon(Icons.signal_wifi_off), findsNothing);
    expect(find.textContaining(RegExp('material', caseSensitive: false)), findsNothing);
  });

  testWidgets('the operator strip counts only alerts and batches in progress', (tester) async {
    stubSummary(_summary(openAlerts: false, inProgress: 0));
    await pumpHome(tester, const Size(360, 800), session: sessionFixture(roles: [UserRole.labOperator]));

    expect(find.text('All in order'), findsOneWidget);
  });

  testWidgets('an auditor sees the full panel marked read only', (tester) async {
    await pumpHome(tester, const Size(360, 800), session: sessionFixture(roles: [UserRole.auditor]));

    expect(find.textContaining('Read only'), findsOneWidget);
    expect(find.text('Awaiting QA release'), findsOneWidget);
  });

  testWidgets('with several roles the highest one decides the Home', (tester) async {
    await pumpHome(
      tester,
      const Size(360, 800),
      session: sessionFixture(roles: [UserRole.labOperator, UserRole.auditor]),
    );

    expect(find.text('Batches in progress'), findsOneWidget);
    expect(find.textContaining('Read only'), findsNothing);
  });
}
