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

/// Order of importance of the Web menu: products & batches → equipment →
/// tracking & telemetry; compliance alerts open from More and Home.
const _expectedTabs = [AppRoutes.home, AppRoutes.batches, AppRoutes.equipment, AppRoutes.telemetry, AppRoutes.more];

void main() {
  test('the app router has its tabs in the order of the Web menu', () {
    final router = createRouter(
      SessionController(iamService: IamFacadeService(repository: MockIamRepository())),
      notifications: UnreadNotificationsController(complianceService: complianceFacade(MockComplianceRepository())),
      currentProfile: CurrentProfileController(
        profileService: ProfileFacadeService(repository: MockProfileRepository()),
      ),
    );
    final shell = router.configuration.routes.whereType<StatefulShellRoute>().single;

    expect([for (final b in shell.branches) b.defaultRoute?.path], _expectedTabs);
    // Alerts and notifications live in the More branch.
    final more = shell.branches.last.routes.whereType<GoRoute>().map((r) => r.path);
    expect(more, containsAll([AppRoutes.alerts, AppRoutes.notifications]));
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

    final labels = {
      AppRoutes.batches: 'Batches',
      AppRoutes.equipment: 'Equipment',
      AppRoutes.telemetry: 'Telemetry',
      AppRoutes.more: 'More',
      AppRoutes.home: 'Home',
    };
    for (final MapEntry(key: path, value: label) in labels.entries) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.text('screen $path'), findsOneWidget, reason: 'tab "$label"');
      expect(router.routerDelegate.currentConfiguration.uri.path, path);
    }
  });
}
