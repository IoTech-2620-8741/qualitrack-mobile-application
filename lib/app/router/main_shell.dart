import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/presentation/i18n/app_localizations.dart';
import 'app_routes.dart';

/// Icon and label of a bottom-navigation tab, by the root path of its branch.
typedef _Tab = (IconData icon, IconData selectedIcon, String Function(AppLocalizations i18n) label);

/// The icons are the ones of the Report (Mobile Style Guidelines), except
/// alerts: the bell is the notifications of the app bar, and every alert of
/// the app (More, lists, notices, batch history) uses `report_problem`.
final Map<String, _Tab> _tabs = {
  AppRoutes.home: (Icons.space_dashboard_outlined, Icons.space_dashboard, (i) => i.navHome),
  AppRoutes.telemetry: (Icons.monitor_heart_outlined, Icons.monitor_heart, (i) => i.navTelemetry),
  AppRoutes.alerts: (Icons.report_problem_outlined, Icons.report_problem, (i) => i.navAlerts),
  AppRoutes.batches: (Icons.inventory_2_outlined, Icons.inventory_2, (i) => i.navBatches),
  AppRoutes.more: (Icons.menu, Icons.menu_open, (i) => i.navMore),
};

/// Bottom navigation with the primary destinations.
///
/// The tabs are built from the branches of the StatefulShellRoute itself
/// (app_router.dart), in their order, so a tab always opens its own branch:
/// the order of the Report (Home → Telemetry → Alerts → Batches → More) is
/// defined once, in the router.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Largest text scale of the tab labels.
  static const double maxLabelScale = 1.15;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      body: shell,
      // Five labels share 360dp: past 115% a word like "Telemetry" no longer
      // fits its 72dp and breaks in the middle, so the bar stops growing there
      // (the rest of the app keeps the user's text size).
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxLabelScale,
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: [
            for (final branch in shell.route.branches)
              () {
                final path = branch.defaultRoute?.path;
                final tab = _tabs[path];
                assert(tab != null, 'No bottom-navigation tab for the branch "$path".');
                final (icon, selectedIcon, label) = tab ?? (Icons.circle_outlined, Icons.circle, (_) => path ?? '');
                return NavigationDestination(
                  key: ValueKey('nav.$path'),
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: label(i18n),
                );
              }(),
          ],
        ),
      ),
    );
  }
}
