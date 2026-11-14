import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qualitrack_mobile/app/home_layout_preference.dart';
import 'package:qualitrack_mobile/batch/api/index.dart';
import 'package:qualitrack_mobile/command_center/application/get_command_center_summary.dart';
import 'package:qualitrack_mobile/compliance/api/index.dart';
import 'package:qualitrack_mobile/command_center/presentation/bloc/command_center_bloc.dart';
import 'package:qualitrack_mobile/command_center/presentation/command_center_views.dart';
import 'package:qualitrack_mobile/command_center/presentation/screens/command_center_screen.dart';
import 'package:qualitrack_mobile/command_center/presentation/widgets/home_alert_card.dart';
import 'package:qualitrack_mobile/command_center/presentation/widgets/proportion_bar.dart';
import 'package:qualitrack_mobile/command_center/presentation/widgets/range_bar.dart';
import 'package:qualitrack_mobile/common/infrastructure/storage/secure_key_value_store.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_colors.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_spacing.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/status_badge.dart';
import 'package:qualitrack_mobile/iam/api/index.dart';
import 'package:qualitrack_mobile/inventory/api/index.dart';
import 'package:qualitrack_mobile/laboratory/api/index.dart';
import 'package:qualitrack_mobile/tracking/api/index.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

/// A keystore that cannot be read, as after the app's data is restored on another phone.
class _UnreadableStore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) async => throw PlatformException(code: 'read');

  @override
  Future<void> write(String key, String value) async => throw PlatformException(code: 'write');

  @override
  Future<void> delete(String key) async => throw PlatformException(code: 'delete');
}

class _MockHomeBloc extends MockBloc<CommandCenterRequested, RemoteState<CommandCenterSummary>>
    implements CommandCenterBloc {}

CommandCenterSummary _summary({
  bool openAlerts = true,
  List<DeviationAlert>? open,
  int pending = 2,
  int inProgress = 3,
  List<InventoryMaterial>? materials,
  String deviceName = 'Device',
  Map<int, MetricThreshold> thresholds = const {},
}) {
  final now = DateTime.now();
  final equipments = [for (var i = 1; i <= 9; i++) equipmentFixture(id: i, name: '$deviceName $i')];
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
            ? Part.ok(AlertOverview(summary: AlertSummary.of(open), open: open, thresholds: thresholds))
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
  late ValueNotifier<HomeLayout> layout;

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
    layout = ValueNotifier(HomeLayout.list);
  });

  /// The Home inside the navigation bar of the shell.
  Widget home({UserSession? session}) => Scaffold(
    body: BlocProvider<CommandCenterBloc>.value(
      value: bloc,
      child: CommandCenterScreen(session: session ?? sessionFixture(), views: _views(), layout: layout),
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
      MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: home(session: session),
      ),
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
      find.byWidgetPredicate((widget) => widget is Text && widget.data?.replaceAll('\u00a0', ' ') == text);

  /// The lines [text] takes on screen.
  int lineCount(WidgetTester tester, Finder text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
    final whole = TextSelection(baseOffset: 0, extentOffset: paragraph.text.toPlainText().length);
    return paragraph.getBoxesForSelection(whole).map((box) => box.top).toSet().length;
  }

  /// Whether [text] is cut short, with an ellipsis.
  bool isCut(WidgetTester tester, Finder text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
    return paragraph.didExceedMaxLines;
  }

  /// Whether [part] of [text] starts a line under its first one.
  bool startsLaterLine(WidgetTester tester, Finder text, String part) {
    final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
    final offset = paragraph.text.toPlainText().indexOf(part);
    final start = paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero);
    return start.dx < 1 && start.dy > 0;
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
      expect(readsAs('Needs attention: 2 critical alerts'), findsOneWidget);
      final alerts = tester.getTopLeft(find.text('Open alerts'));
      final telemetry = tester.getTopLeft(find.text('Devices online'));
      final batches = tester.getTopLeft(find.text('Awaiting QA release'));
      final inventory = tester.getTopLeft(find.text('Below minimum'));
      expect(telemetry.dy, greaterThan(alerts.dy));
      expect(batches.dy, greaterThan(telemetry.dy));
      expect(inventory.dy, greaterThan(batches.dy));
      // The figures stay in every size.
      expect(find.text('6/9'), findsOneWidget);
      // Severity is the banner's and status the detail's; the rows are short
      // enough to keep their detail even on a small phone.
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

  testWidgets('the open alerts row leaves the critical count to the red banner', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    expect(readsAs('Needs attention: 2 critical alerts'), findsOneWidget);
    expect(find.text('2 critical'), findsNothing);
  });

  testWidgets('devices without data show as to review, in grey', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    expect(find.text('3 to review'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.signal_wifi_off)).color, BadgeTone.neutral.foreground);
  });

  testWidgets('the row figures take 22 sp, the top of the style guide scale, to compare at a glance', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    for (final figure in ['4', '6/9', '5', '1']) {
      expect(tester.widget<Text>(find.text(figure)).style?.fontSize, 22, reason: figure);
    }
  });

  testWidgets('the devices online keep the figure size and their total goes smaller, in the body size', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    final figure = tester.widget<Text>(find.text('6/9'));
    final total = (figure.textSpan! as TextSpan).children!.single as TextSpan;
    expect(figure.style?.fontSize, 22);
    expect(total.text, '/9');
    expect(total.style?.fontSize, 14);
  });

  testWidgets('each row shows the share of its parts in a thin bar', (tester) async {
    await pumpHome(tester, const Size(360, 800));

    final bars = tester.widgetList<ProportionBar>(find.byType(ProportionBar)).toList();
    expect([for (final bar in bars) bar.height], [4, 4, 4, 4]);
    // Top to bottom: open alerts, devices, batches and materials.
    expect([for (final bar in bars) bar.segments], [
      [(3, AppColors.criticalBase), (1, AppColors.neutralContainer)],
      [(6, AppColors.successBase), (1, AppColors.warningBase), (2, AppColors.neutralContainer)],
      [(5, AppColors.primary), (4, AppColors.neutralContainer)],
      [(1, AppColors.warningBase), (1, AppColors.successBase)],
    ]);
  });

  testWidgets('TalkBack reads the devices online as "6 of 9", in words', (tester) async {
    for (final (locale, label) in const [
      (Locale('en'), '6 of 9, Devices online'),
      (Locale('es'), '6 de 9, Dispositivos en línea'),
    ]) {
      await pumpHome(tester, const Size(360, 800), locale: locale);

      expect(find.bySemanticsLabel(RegExp('^$label, ')), findsOneWidget, reason: '$locale');
    }
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

  // Beside the button the message takes two lines, broken after the colon: the count keeps its noun.
  for (final (locale, count, message, action) in const [
    (Locale('es'), 1, 'Requiere atención: 1 alerta crítica', 'Ver detalle'),
    (Locale('en'), 2, 'Needs attention: 2 critical alerts', 'View detail'),
  ]) {
    testWidgets('the critical banner shows View detail beside its message in two lines, in $locale', (tester) async {
      stubSummary(_summary(open: [for (var id = 1; id <= count; id++) alertFixture(id: id)]));
      await pumpHome(tester, const Size(360, 800), locale: locale);

      final text = readsAs(message);
      final button = find.widgetWithText(OutlinedButton, action);
      expect(lineCount(tester, text), 2);
      expect(startsLaterLine(tester, text, '$count'), isTrue);
      expect(tester.getRect(button).left, greaterThanOrEqualTo(tester.getRect(text).right));
      expect(tester.getCenter(button).dy, moreOrLessEquals(tester.getCenter(text).dy, epsilon: 1));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    });
  }

  // A smaller text has lines shorter than the 20 dp icon: three of them still do not go beside the button.
  for (final (locale, message, action, count) in const [
    (Locale('es'), 'Requiere atención: 1 alerta crítica', 'Ver detalle', 1),
    (Locale('en'), 'Needs attention: 2 critical alerts', 'View detail', 2),
  ]) {
    testWidgets('the banner keeps two lines at most beside View detail with a small text, in $locale', (tester) async {
      stubSummary(_summary(open: [for (var id = 1; id <= count; id++) alertFixture(id: id)]));
      for (var width = 290.0; width <= 340; width += 2) {
        await pumpHome(tester, Size(width, 800), locale: locale, textScale: 0.8);

        final text = readsAs(message);
        final button = find.widgetWithText(OutlinedButton, action);
        if (tester.getRect(button).top < tester.getRect(text).bottom) {
          expect(lineCount(tester, text), lessThanOrEqualTo(2), reason: 'at $width dp');
        }
      }
    });
  }

  // An IntrinsicHeight, a baseline-aligned row or a dry layout around it get the size it really takes.
  testWidgets('the critical banner answers the sizes and baseline other layouts ask for', (tester) async {
    // Flutter then checks each box's intrinsic sizes and dry baseline against its real layout.
    debugCheckIntrinsicSizes = true;
    try {
      stubSummary(_summary(open: [alertFixture(id: 1)]));
      for (final width in [320.0, 360.0]) {
        await pumpHome(tester, Size(width, 800), locale: const Locale('es'));

        expect(tester.takeException(), isNull, reason: 'at $width dp');
        final banner = tester.renderObject<RenderBox>(
          find.ancestor(
            of: readsAs('Requiere atención: 1 alerta crítica'),
            matching: find.byWidgetPredicate((widget) => '${widget.runtimeType}' == '_BannerLayout'),
          ),
        );
        expect(banner.getDryLayout(BoxConstraints(maxWidth: banner.size.width)), banner.size, reason: 'at $width dp');
        expect(banner.getMinIntrinsicHeight(banner.size.width), banner.size.height);
        expect(banner.getMaxIntrinsicHeight(banner.size.width), banner.size.height);
        // At its widest the message takes one line beside the button, as tall as the button.
        final button = tester.getSize(find.widgetWithText(OutlinedButton, 'Ver detalle'));
        expect(banner.getMinIntrinsicHeight(banner.getMaxIntrinsicWidth(double.infinity)), button.height);
      }
    } finally {
      debugCheckIntrinsicSizes = false;
    }
  });

  // On a narrower phone or with larger text two lines beside the button are not enough: it goes under.
  for (final (width, scale) in const [(320.0, 1.0), (360.0, 1.3)]) {
    testWidgets('the critical banner puts View detail under the message at $width dp, text x$scale', (tester) async {
      stubSummary(_summary(open: [alertFixture(id: 1)]));
      await pumpHome(tester, Size(width, 800), locale: const Locale('es'), textScale: scale);

      final text = readsAs('Requiere atención: 1 alerta crítica');
      final button = find.widgetWithText(OutlinedButton, 'Ver detalle');
      expect(tester.takeException(), isNull);
      expect(startsLaterLine(tester, text, '1'), isTrue);
      expect(tester.getRect(button).top, greaterThanOrEqualTo(tester.getRect(text).bottom));
      expect(tester.getRect(button).right, tester.getRect(text).right);
    });
  }

  // Whether the rows fit with their detail depends on the width (which Android's
  // display size narrows), the language and the text size: a body as tall as the
  // whole panel shows it whole, and one dp less gets the compact rows, not a scroll.
  for (final (width, scale) in const [(320.0, 1.0), (360.0, 1.0), (360.0, 1.3), (412.0, 1.0)]) {
    testWidgets('the rows keep their detail just while it fits, at $width dp and text x$scale', (tester) async {
      for (final (locale, detail) in const [(Locale('en'), 'of 2 materials'), (Locale('es'), 'de 2 materiales')]) {
        await pumpHome(tester, Size(width, 2000), locale: locale, textScale: scale);
        final body = tester.getRect(find.byType(CustomScrollView));
        final lastRow = find.ancestor(of: find.text(detail), matching: find.byType(InkWell)).first;
        final tall = (2000 - body.height + tester.getRect(lastRow).bottom - body.top).ceilToDouble();

        await pumpHome(tester, Size(width, tall), locale: locale, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.text(detail), findsOneWidget, reason: 'whole in $locale');
        expect(find.byType(ProportionBar), findsNWidgets(4), reason: 'whole in $locale');
        expect(scrollExtent(tester), 0, reason: 'whole in $locale');

        await pumpHome(tester, Size(width, tall - 1), locale: locale, textScale: scale);

        expect(find.text(detail), findsNothing, reason: 'compact in $locale');
        expect(find.byType(ProportionBar), findsNothing, reason: 'compact in $locale');
        expect(scrollExtent(tester), 0, reason: 'compact in $locale');
      }
    });
  }

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

  testWidgets('the batches awaiting QA take one line in Spanish', (tester) async {
    await pumpHome(tester, const Size(360, 800), locale: const Locale('es'));

    expect(find.text('En espera de QA'), findsOneWidget);
    expect(lineCount(tester, find.text('En espera de QA')), 1);
  });

  testWidgets('a count of one reads in the singular', (tester) async {
    stubSummary(_summary(open: [alertFixture(id: 1)], pending: 1, materials: [materialFixture()]));
    await pumpHome(tester, const Size(360, 800), locale: const Locale('es'));

    expect(readsAs('Requiere atención: 1 alerta crítica'), findsOneWidget);
    expect(readsAs('1 pendiente · 3 en proceso'), findsOneWidget);
    expect(find.text('de 1 material'), findsOneWidget);

    await pumpHome(tester, const Size(360, 800));

    expect(readsAs('Needs attention: 1 critical alert'), findsOneWidget);
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

  testWidgets('the operator strip counts only open alerts, not their daily batches in progress', (tester) async {
    stubSummary(_summary(openAlerts: false, inProgress: 3));
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

    await pumpHome(
      tester,
      const Size(360, 800),
      session: sessionFixture(roles: [UserRole.admin, UserRole.labOperator]),
    );

    expect(find.text('Awaiting QA release'), findsOneWidget);
  });

  group('the dashboard', () {
    /// Two critical alerts and a warning, unresolved, and an acknowledged warning.
    List<DeviationAlert> openAlerts() {
      final now = DateTime.now();
      return [
        alertFixture(id: 1, equipmentId: 1, timestamp: now.subtract(const Duration(hours: 2))),
        alertFixture(id: 2, equipmentId: 2, timestamp: now.subtract(const Duration(days: 2))),
        alertFixture(
          id: 3,
          equipmentId: 3,
          severity: AlertSeverity.warning,
          timestamp: now.subtract(const Duration(days: 4)),
        ),
        alertFixture(
          id: 4,
          equipmentId: 4,
          severity: AlertSeverity.warning,
          status: AlertStatus.acknowledged,
          timestamp: now.subtract(const Duration(hours: 3)),
        ),
      ];
    }

    /// The tile labeled [label].
    Finder tileOf(String label) => find.ancestor(of: find.text(label), matching: find.byType(Card)).first;

    setUp(() => layout.value = HomeLayout.cards);

    testWidgets('the app bar button switches the Home between the list and the dashboard', (tester) async {
      layout.value = HomeLayout.list;
      await pumpHome(tester, const Size(360, 800));
      expect(find.text('View detail'), findsOneWidget);

      await tester.tap(find.byTooltip('Show as cards'));
      await tester.pump();
      await tester.pump();

      expect(layout.value, HomeLayout.cards);
      expect(find.text('View detail'), findsNothing);
      expect(find.byType(HomeAlertCard), findsWidgets);

      await tester.tap(find.byTooltip('Show as list'));
      await tester.pump();
      await tester.pump();

      expect(layout.value, HomeLayout.list);
      expect(find.text('View detail'), findsOneWidget);
    });

    testWidgets('the dashboard lays the figures out two by two', (tester) async {
      await pumpHome(tester, const Size(412, 915));

      final alerts = tester.getRect(tileOf('Open alerts'));
      final devices = tester.getRect(tileOf('Devices online'));
      final batches = tester.getRect(tileOf('Awaiting QA release'));
      final materials = tester.getRect(tileOf('Below minimum'));
      expect(devices.top, alerts.top);
      expect(devices.left, greaterThan(alerts.right));
      expect(batches.left, alerts.left);
      expect(batches.top, greaterThan(alerts.bottom));
      expect(materials.top, batches.top);
      // Each pair is as tall as its taller tile.
      expect(devices.height, alerts.height);
      expect(materials.height, batches.height);
    });

    testWidgets("an operator's dashboard shows the open alerts and the batches in progress", (tester) async {
      await pumpHome(tester, const Size(360, 800), session: sessionFixture(roles: [UserRole.labOperator]));

      expect(tester.getRect(tileOf('Batches in progress')).top, tester.getRect(tileOf('Open alerts')).top);
      expect(find.text('Devices online'), findsNothing);
      expect(find.text('Below minimum'), findsNothing);
    });

    testWidgets('a critical alert turns the open alerts tile red and names it, with no banner', (tester) async {
      stubSummary(_summary(open: openAlerts()));
      await pumpHome(tester, const Size(412, 915));

      expect(readsAs('2 critical · 1 acknowledged'), findsOneWidget);
      expect(tester.widget<Card>(tileOf('Open alerts')).color, AppColors.criticalContainer);
      expect(find.text('View detail'), findsNothing);
    });

    testWidgets('without critical alerts the open alerts tile stays white, with the list detail', (tester) async {
      stubSummary(_summary(open: openAlerts().where((alert) => !alert.isCritical).toList()));
      await pumpHome(tester, const Size(412, 915));

      expect(readsAs('1 unresolved · 1 acknowledged'), findsOneWidget);
      expect(tester.widget<Card>(tileOf('Open alerts')).color, isNull);
    });

    testWidgets('the tile figures keep the 22 sp of the list', (tester) async {
      await pumpHome(tester, const Size(412, 915));

      for (final figure in ['4', '6/9', '5', '1']) {
        expect(tester.widget<Text>(find.text(figure)).style?.fontSize, 22, reason: figure);
      }
    });

    testWidgets('unresolved alerts come first as cards, then the acknowledged ones as one-line rows', (tester) async {
      stubSummary(_summary(open: openAlerts()));
      await pumpHome(tester, const Size(412, 2000));

      final cards = find.byType(HomeAlertCard);
      expect([for (final card in tester.widgetList<HomeAlertCard>(cards)) card.alert.id], [1, 2, 3]);
      final row = find.byType(HomeAcknowledgedAlertRow);
      expect(tester.widget<HomeAcknowledgedAlertRow>(row).alert.id, 4);
      expect(tester.getRect(row).top, greaterThan(tester.getRect(cards.last).bottom));
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    });

    testWidgets("an alert card measures its value against the alert's limit", (tester) async {
      stubSummary(_summary(open: [alertFixture(id: 1)]));
      await pumpHome(tester, const Size(412, 915));

      expect(find.text('38.6 °C'), findsOneWidget);
      expect(find.text('Limit 30 °C'), findsOneWidget);
      expect(find.text('8.6 °C above the limit'), findsOneWidget);
      // The style guide's edge of a reading card: 4 dp in the color of its state.
      final edges = [
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(of: find.byType(HomeAlertCard), matching: find.byType(DecoratedBox)),
        ))
          if (box.decoration case BoxDecoration(border: final Border border)) border.left,
      ];
      expect(edges.single.width, 4);
      expect(edges.single.color, AppColors.criticalBase);
    });

    test('outOfLimit tells how far and on which side a value is', () {
      final above = outOfLimit(38.6, low: 30, high: 30)!;
      expect(above.amount, closeTo(8.6, 1e-9));
      expect(above.above, isTrue);
      expect(outOfLimit(1, low: 2, high: 8), (amount: 1, above: false));
      expect(outOfLimit(5, low: 2, high: 8), isNull);
      expect(outOfLimit(null, low: 2, high: 8), isNull);
      // A missing side is open.
      expect(outOfLimit(9, high: 8), (amount: 1, above: true));
      expect(outOfLimit(-40, high: 8), isNull);
    });

    test('rangeBarStops puts the normal range and the value on one scale', () {
      for (final (normalMin, normalMax, value, expected) in const [
        (2.0, 8.0, 9.6, (0.1667, 0.6930, 0.8333)),
        (null, 800.0, 1450.0, (0.0, 0.1667, 0.8333)),
        (2.0, 8.0, 1.0, (0.2619, 0.8333, 0.1667)),
      ]) {
        final stops = rangeBarStops(normalMin: normalMin, normalMax: normalMax, value: value);
        final reason = '$normalMin–$normalMax, $value';
        expect(stops.bandStart, closeTo(expected.$1, 0.001), reason: reason);
        expect(stops.bandEnd, closeTo(expected.$2, 0.001), reason: reason);
        expect(stops.marker, closeTo(expected.$3, 0.001), reason: reason);
      }
    });

    testWidgets('an alert card with a profile draws its normal range and measures the value against it', (
      tester,
    ) async {
      const range = MetricThreshold(metric: MonitoredMetric.temperature, unit: '°C', normalMin: 15, normalMax: 30);
      stubSummary(_summary(open: [alertFixture(id: 1)], thresholds: {1: range}));
      await pumpHome(tester, const Size(412, 915));

      expect(find.text('normal 15–30 °C'), findsOneWidget);
      expect(find.text('8.6 °C above the limit'), findsOneWidget);
      expect(find.byType(RangeBar), findsOneWidget);
      expect(find.text('Limit 30 °C'), findsNothing);
    });

    testWidgets('an alert whose profile has no normal range keeps its limit and draws no bar', (tester) async {
      const critical = MetricThreshold(
        metric: MonitoredMetric.temperature,
        unit: '°C',
        criticalMin: 0,
        criticalMax: 35,
      );
      stubSummary(_summary(open: [alertFixture(id: 1)], thresholds: {1: critical}));
      await pumpHome(tester, const Size(412, 915));

      expect(find.text('Limit 30 °C'), findsOneWidget);
      expect(find.text('8.6 °C above the limit'), findsOneWidget);
      expect(find.byType(RangeBar), findsNothing);
    });

    testWidgets('an alert without a value or a limit shows a dash and no distance', (tester) async {
      stubSummary(_summary(open: [alertFixture(id: 1, recordedValue: null, thresholdValue: null)]));
      await pumpHome(tester, const Size(412, 915));

      expect(tester.takeException(), isNull);
      expect(find.descendant(of: find.byType(HomeAlertCard), matching: find.text('—')), findsOneWidget);
      expect(find.textContaining('limit'), findsNothing);
      expect(find.textContaining('Limit'), findsNothing);
    });

    testWidgets('an alert card names its device and its time in full, and leaves severity to its color', (
      tester,
    ) async {
      const name = 'Congeladora de vacunas del almacén';
      stubSummary(_summary(open: openAlerts(), deviceName: name));
      await pumpHome(tester, const Size(320, 2000), textScale: 1.3, locale: const Locale('es'));

      final card = find.byType(HomeAlertCard).first;
      final device = find.descendant(of: card, matching: find.text('$name 1'));
      final when = find.descendant(of: card, matching: find.text('Hace 2 h'));
      // The end of a long name tells two devices apart: it wraps instead of being cut.
      expect(lineCount(tester, device), greaterThan(1));
      expect(isCut(tester, device), isFalse);
      expect(isCut(tester, when), isFalse);
      // The icon, the color and TalkBack give the severity.
      expect(find.descendant(of: card, matching: find.textContaining('Crítica')), findsNothing);
    });

    testWidgets('the tiles give up their detail to make room for the most urgent alerts', (tester) async {
      await pumpHome(tester, const Size(360, 2000));
      final body = tester.getRect(find.byType(CustomScrollView));
      final tiles = tester.getRect(tileOf('Below minimum')).bottom - tester.getRect(tileOf('Open alerts')).top;
      // A screen that leaves the alerts their minimum only under compact tiles.
      await pumpHome(tester, Size(360, (2000 - body.height + AppSpacing.lg + tiles + 160 - 1).floorToDouble()));

      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), 0);
      expect(find.text('Most urgent'), findsOneWidget);
      expect(find.text('of 2 materials'), findsNothing);
    });

    testWidgets('with room to spare the tiles keep their detail above the most urgent alerts', (tester) async {
      await pumpHome(tester, const Size(412, 915));

      expect(find.text('Most urgent'), findsOneWidget);
      expect(find.text('of 2 materials'), findsOneWidget);
    });

    testWidgets('the tiles keep their detail when compacting would not make room for the alerts', (tester) async {
      await pumpHome(tester, const Size(360, 2000));
      final body = tester.getRect(find.byType(CustomScrollView));
      final bottom = tester.getRect(tileOf('Below minimum')).bottom;
      // A screen just as tall as the whole tiles.
      await pumpHome(tester, Size(360, (2000 - body.height + bottom - body.top).ceilToDouble()));

      expect(scrollExtent(tester), 0);
      expect(find.text('of 2 materials'), findsOneWidget);
      expect(find.text('Most urgent'), findsNothing);
    });

    testWidgets('the dashboard fits a small phone without scrolling', (tester) async {
      await pumpHome(tester, const Size(360, 640));

      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), 0);
      expect(find.text('Below minimum'), findsOneWidget);
    });

    testWidgets('the dashboard fits a 320 dp phone with text x1.3', (tester) async {
      stubSummary(_summary(open: openAlerts(), deviceName: 'Congeladora de vacunas del almacén'));
      for (final height in [640.0, 1000.0]) {
        await pumpHome(tester, Size(320, height), textScale: 1.3, locale: const Locale('es'));

        expect(tester.takeException(), isNull, reason: '$height dp');
        expect(
          tester.getRect(tileOf('Dispositivos en línea')).top,
          tester.getRect(tileOf('Alertas abiertas')).top,
          reason: '$height dp',
        );
      }
      expect(find.byType(HomeAlertCard), findsWidgets);
    });

    testWidgets('a tile and an alert card each read as one sentence', (tester) async {
      stubSummary(_summary(open: [alertFixture(id: 1)]));
      await pumpHome(tester, const Size(412, 915));

      expect(find.bySemanticsLabel('1, Open alerts, 1 critical'), findsOneWidget);
      // An alert of a device the Home did not load reads its number.
      final card = RegExp(
        r'^Critical, Temperature, 38\.6 °C, Limit 30 °C, 8\.6 °C above the limit, Equipment #10, Unresolved, ',
      );
      expect(find.bySemanticsLabel(card), findsOneWidget);
    });

    testWidgets('a count of one reads in the singular on the tiles', (tester) async {
      stubSummary(
        _summary(
          open: [
            alertFixture(id: 1),
            alertFixture(id: 4, severity: AlertSeverity.warning, status: AlertStatus.acknowledged),
          ],
          materials: [materialFixture()],
        ),
      );
      await pumpHome(tester, const Size(412, 915), locale: const Locale('es'));

      expect(readsAs('1 crítica · 1 reconocida'), findsOneWidget);
      expect(find.text('de 1 material'), findsOneWidget);
    });

    testWidgets('while it loads, the dashboard shows the shape of its tiles', (tester) async {
      whenListen(
        bloc,
        const Stream<RemoteState<CommandCenterSummary>>.empty(),
        initialState: const RemoteState<CommandCenterSummary>().loading(),
      );
      await pumpHome(tester, const Size(360, 800));

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
      expect(find.byKey(const ValueKey('tile-bone')), findsNWidgets(4));
    });

    test('the choice is kept on the device and read again at start', () async {
      final store = InMemorySecureStore();
      HomeLayoutPreference(store).value = HomeLayout.cards;
      await pumpEventQueue();

      final next = HomeLayoutPreference(store);
      await next.load();

      expect(next.value, HomeLayout.cards);
    });

    test('a missing, unknown or unreadable choice keeps the list', () async {
      for (final store in [
        InMemorySecureStore(),
        InMemorySecureStore()..values[HomeLayoutPreference.storageKey] = 'grid',
        _UnreadableStore(),
      ]) {
        final preference = HomeLayoutPreference(store);
        await preference.load();
        expect(preference.value, HomeLayout.list, reason: '${store.runtimeType}');
      }
    });

    test('a choice the keystore cannot save still holds until the app closes', () async {
      final preference = HomeLayoutPreference(_UnreadableStore())..value = HomeLayout.cards;
      await pumpEventQueue();

      expect(preference.value, HomeLayout.cards);
    });
  });
}
