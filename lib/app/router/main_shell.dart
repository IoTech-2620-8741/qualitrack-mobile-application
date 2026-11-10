import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/presentation/i18n/app_localizations.dart';
import 'app_routes.dart';

/// Icon and label of a bottom-navigation tab, by the root path of its branch.
typedef _Tab = (IconData icon, IconData selectedIcon, String Function(AppLocalizations i18n) label);

final Map<String, _Tab> _tabs = {
  AppRoutes.home: (Icons.dashboard_outlined, Icons.dashboard, (i) => i.navHome),
  AppRoutes.batches: (Icons.inventory_2_outlined, Icons.inventory_2, (i) => i.navBatches),
  AppRoutes.equipment: (Icons.precision_manufacturing_outlined, Icons.precision_manufacturing, (i) => i.navEquipment),
  AppRoutes.telemetry: (Icons.monitor_heart_outlined, Icons.monitor_heart, (i) => i.navTelemetry),
  AppRoutes.alerts: (Icons.report_problem_outlined, Icons.report_problem, (i) => i.navAlerts),
  AppRoutes.more: (Icons.menu, Icons.menu_open, (i) => i.navMore),
};

/// Bottom navigation with the primary destinations.
///
/// The tabs are built from the branches of the StatefulShellRoute itself
/// (app_router.dart), in their order, so a tab always opens its own branch:
/// the order of importance (Web menu: products & batches → equipment →
/// tracking & telemetry) is defined once, in the router.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
