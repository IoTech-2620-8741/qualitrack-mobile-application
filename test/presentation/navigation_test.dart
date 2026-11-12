import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qualitrack_mobile/app/router/app_router.dart';
import 'package:qualitrack_mobile/app/router/app_routes.dart';
import 'package:qualitrack_mobile/app/router/main_shell.dart';
import 'package:qualitrack_mobile/common/presentation/i18n/app_localizations.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_theme.dart';
import 'package:qualitrack_mobile/compliance/presentation/bloc/unread_notifications_controller.dart';
import 'package:qualitrack_mobile/iam/application/iam_facade_service.dart';
import 'package:qualitrack_mobile/iam/application/session_controller.dart';
import 'package:qualitrack_mobile/profile/application/profile_facade_service.dart';
import 'package:qualitrack_mobile/profile/presentation/bloc/current_profile_controller.dart';

import '../helpers/mocks.dart';

/// Tabs of the Report (Mobile Style Guidelines): Home, Telemetry, Alerts,
/// Batches and More; equipment and inventory open from More.
const _expectedTabs = [AppRoutes.home, AppRoutes.telemetry, AppRoutes.alerts, AppRoutes.batches, AppRoutes.more];

void main() {
  test('the app router has the tabs of the Report, in its order', () {
    final router = createRouter(
      SessionController(iamService: IamFacadeService(repository: MockIamRepository())),
      notifications: UnreadNotificationsController(complianceService: complianceFacade(MockComplianceRepository())),
      currentProfile: CurrentProfileController(
        profileService: ProfileFacadeService(repository: MockProfileRepository()),
      ),
    );
    final shell = router.configuration.routes.whereType<StatefulShellRoute>().single;

    expect([for (final b in shell.branches) b.defaultRoute?.path], _expectedTabs);
    // Equipment, inventory and notifications live in the More branch.
    final more = shell.branches.last.routes.whereType<GoRoute>().map((r) => r.path);
    expect(more, containsAll([AppRoutes.equipment, AppRoutes.inventory, AppRoutes.notifications]));
    expect(more, isNot(contains(AppRoutes.alerts)));
    router.dispose();
  });

  testWidgets('each tab of the bar opens its own branch', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            for (final path in _expectedTabs)
              StatefulShellBranch(
                routes: [GoRoute(path: path, builder: (context, state) => Center(child: Text('screen $path')))],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The same icon as the section uses everywhere else (More, Home, lists).
    final tabs = {
      AppRoutes.telemetry: ('Telemetry', Icons.monitor_heart),
      AppRoutes.alerts: ('Alerts', Icons.report_problem),
      AppRoutes.batches: ('Batches', Icons.inventory_2),
      AppRoutes.more: ('More', Icons.menu_open),
      AppRoutes.home: ('Home', Icons.space_dashboard),
    };
    final bar = find.byType(NavigationBar);
    for (final MapEntry(key: path, value: (label, selectedIcon)) in tabs.entries) {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.text('screen $path'), findsOneWidget, reason: 'tab "$label"');
      expect(router.routerDelegate.currentConfiguration.uri.path, path);
      expect(find.descendant(of: bar, matching: find.byIcon(selectedIcon)), findsOneWidget, reason: 'icon of "$label"');
    }
  });

  testWidgets('content tabs keep where they were left; More always opens on its menu', (tester) async {
    Widget screen(String name) => Center(child: Text('screen $name'));
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            for (final path in _expectedTabs)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) => screen(path),
                    routes: [GoRoute(path: 'detail', builder: (context, state) => screen('$path/detail'))],
                  ),
                  // Sections of More are routes of their own in its branch.
                  if (path == AppRoutes.more)
                    GoRoute(path: AppRoutes.inventory, builder: (context, state) => screen(AppRoutes.inventory)),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byType(NavigationBar);
    Future<void> tapTab(String label) async {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    // An alert left open is still there when coming back to Alerts.
    router.go('${AppRoutes.alerts}/detail');
    await tester.pumpAndSettle();
    await tapTab('Home');
    await tapTab('Alerts');
    expect(find.text('screen ${AppRoutes.alerts}/detail'), findsOneWidget);

    // A section of More is not: More opens on its menu.
    router.go(AppRoutes.inventory);
    await tester.pumpAndSettle();
    await tapTab('Home');
    await tapTab('More');
    expect(find.text('screen ${AppRoutes.more}'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.more);
  });

  testWidgets('the tab labels grow with the text up to 115%, so no word breaks', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            for (final path in _expectedTabs)
              StatefulShellBranch(routes: [GoRoute(path: path, builder: (context, state) => Text('screen $path'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.3,
        maxScaleFactor: 1.3,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    double scaleOf(Finder text) => MediaQuery.textScalerOf(tester.element(text)).scale(100) / 100;
    expect(scaleOf(find.text('screen ${AppRoutes.home}')), closeTo(1.3, 0.001));
    expect(scaleOf(find.text('Telemetry')), closeTo(MainShell.maxLabelScale, 0.001));
  });
}

