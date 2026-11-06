import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../batch/presentation/batch_detail/batch_detail_screen.dart';
import '../../batch/presentation/batch_detail/bloc/bloc.dart';
import '../../batch/presentation/batch_list/batch_list_screen.dart';
import '../../batch/presentation/batch_list/bloc/bloc.dart';
import '../../command_center/presentation/bloc/command_center_bloc.dart';
import '../../command_center/presentation/pages/command_center_page.dart';
import '../../iam/presentation/widgets/role_labels.dart';
import 'command_center_views.dart';
import '../../compliance/presentation/bloc/alert_detail_bloc.dart';
import '../../compliance/presentation/bloc/alerts_bloc.dart';
import '../../compliance/presentation/bloc/notification_preferences_bloc.dart';
import '../../compliance/presentation/bloc/notifications_bloc.dart';
import '../../compliance/presentation/bloc/unread_notifications_controller.dart';
import '../../compliance/presentation/screens/alert_detail_screen.dart';
import '../../compliance/presentation/screens/alerts_screen.dart';
import '../../compliance/presentation/screens/notification_preferences_screen.dart';
import '../../compliance/presentation/screens/notifications_screen.dart';
import '../../equipment/presentation/bloc/equipment_detail_bloc.dart';
import '../../equipment/presentation/bloc/equipment_list_bloc.dart';
import '../../equipment/presentation/screens/equipment_detail_screen.dart';
import '../../equipment/presentation/screens/equipment_list_screen.dart';
import '../../iam/application/session_controller.dart';
import '../../iam/presentation/bloc/change_password_bloc.dart';
import '../../iam/presentation/bloc/sign_in_bloc.dart';
import '../../iam/presentation/screens/change_password_screen.dart';
import '../../iam/presentation/screens/setup_required_screen.dart';
import '../../iam/presentation/screens/sign_in_screen.dart';
import '../../iam/presentation/screens/splash_screen.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../inventory/presentation/bloc/material_detail_bloc.dart';
import '../../inventory/presentation/screens/inventory_screen.dart';
import '../../inventory/presentation/screens/material_detail_screen.dart';
import '../../laboratory/presentation/bloc/products_bloc.dart';
import '../../laboratory/presentation/screens/products_screen.dart';
import '../../profile/presentation/bloc/current_profile_controller.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../reporting/presentation/bloc/reports_bloc.dart';
import '../../reporting/presentation/screens/reports_screen.dart';
import '../../common/presentation/i18n/app_localizations.dart';
import '../../common/presentation/widgets/state_views.dart';
import '../../subscription/presentation/bloc/billing_bloc.dart';
import '../../subscription/presentation/screens/billing_screen.dart';
import '../../tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import '../../tracking/presentation/bloc/telemetry_history_bloc.dart';
import '../../tracking/presentation/screens/telemetry_dashboard_screen.dart';
import '../../tracking/presentation/screens/telemetry_history_screen.dart';
import '../dependency_injection/injection.dart';
import 'app_routes.dart';
import 'main_shell.dart';
import 'more_page.dart';

/// Pure redirect rule, extracted for unit testing.
String? resolveRedirect(SessionStatus status, String location, {bool canManageQuality = false}) {
  final isPublic = AppRoutes.public.contains(location);
  switch (status) {
    case SessionStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionStatus.unauthenticated:
      return location == AppRoutes.signIn ? null : AppRoutes.signIn;
    case SessionStatus.passwordChangeRequired:
      return location == AppRoutes.changePassword ? null : AppRoutes.changePassword;
    case SessionStatus.setupRequired:
      return location == AppRoutes.setupRequired ? null : AppRoutes.setupRequired;
    case SessionStatus.authenticated:
      if (isPublic) return AppRoutes.home;
      // The subscription belongs to the quality manager, as in Web.
      if (location == AppRoutes.billing && !canManageQuality) return AppRoutes.more;
      return null;
  }
}

int? _intParam(String? raw) {
  final value = int.tryParse(raw ?? '');
  return value != null && value > 0 ? value : null;
}

Widget _invalidId(BuildContext context) => Scaffold(appBar: AppBar(), body: EmptyView(title: context.i18n.errorNotFound));

/// Lets the router listen to the Flutter-free [SessionController].
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(SessionController session) {
    session.addListener(notifyListeners);
  }
}

GoRouter createRouter(
  SessionController session, {
  required UnreadNotificationsController notifications,
  required CurrentProfileController currentProfile,
}) {
  int? currentUserId() => session.session?.userId;
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _SessionRefresh(session),
    redirect: (context, state) => resolveRedirect(
      session.status,
      state.matchedLocation,
      canManageQuality: session.session?.canManageQuality ?? false,
    ),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SignInBloc>(),
          child: SignInScreen(sessionExpired: session.sessionExpired),
        ),
      ),
      GoRoute(path: AppRoutes.setupRequired, builder: (context, state) => SetupRequiredScreen(session: session)),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ChangePasswordBloc>(),
          child: ChangePasswordScreen(forced: true, onChanged: session.passwordChanged, onSignOut: session.signOut),
        ),
      ),
      // Secondary screens are pushed on the root navigator (above the shell).
      GoRoute(
        path: AppRoutes.telemetryHistory,
        builder: (context, state) {
          final id = _intParam(state.uri.queryParameters['deviceId']);
          return BlocProvider(
            create: (_) => sl<TelemetryHistoryBloc>()..add(TelemetryHistoryStarted(deviceId: id)),
            child: const TelemetryHistoryScreen(),
          );
        },
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (context, state) {
          final id = _intParam(state.pathParameters['id']);
          if (id == null) return _invalidId(context);
          return BlocProvider(
            create: (_) => sl<AlertDetailBloc>(param1: id)..add(const AlertDetailRequested()),
            child: AlertDetailScreen(
              canAttend: session.session?.canAttendAlerts ?? false,
              currentUserId: currentUserId(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/batches/:id',
        builder: (context, state) {
          final id = _intParam(state.pathParameters['id']);
          if (id == null) return _invalidId(context);
          return BlocProvider(
            create: (_) => sl<BatchDetailBloc>(param1: id)..add(const BatchDetailRequested()),
            child: BatchDetailScreen(
              canReview: session.session?.canManageQuality ?? false,
              currentUserId: currentUserId(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.equipment,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<EquipmentListBloc>()..add(const EquipmentListRequested()),
          child: const EquipmentListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _invalidId(context);
              return BlocProvider(
                create: (_) => sl<EquipmentDetailBloc>(param1: id)..add(const EquipmentDetailRequested()),
                child: EquipmentDetailScreen(currentUserId: currentUserId()),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<InventoryBloc>()..add(const InventoryRequested()),
          child: const InventoryScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _invalidId(context);
              final environmentId = _intParam(state.uri.queryParameters['environmentId']);
              return BlocProvider(
                create: (_) =>
                    sl<MaterialDetailBloc>(param1: id, param2: environmentId)..add(const MaterialDetailRequested()),
                child: const MaterialDetailScreen(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ProductsBloc>()..add(const ProductsRequested()),
          child: const ProductsScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _invalidId(context);
              return BlocProvider(
                create: (_) => sl<ProductsBloc>()..add(const ProductsRequested()),
                child: ProductDetailPage(productId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ReportsBloc>()..add(const ReportsRequested()),
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billing,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<BillingBloc>()..add(const BillingRequested()),
          child: const BillingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<NotificationsBloc>()..add(const NotificationsRequested()),
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
          child: ProfileScreen(onSignOut: session.signOut, roleLabel: (role, i18n) => role.label(i18n)),
        ),
        routes: [
          GoRoute(
            path: 'password',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<ChangePasswordBloc>(),
              child: ChangePasswordScreen(
                forced: false,
                onChanged: () async {
                  if (context.canPop()) context.pop();
                },
              ),
            ),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<NotificationPreferencesBloc>()..add(const NotificationPreferencesRequested()),
              child: const NotificationPreferencesScreen(),
            ),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.about, builder: (context, state) => const AboutPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) {
                  final current = session.session;
                  if (current == null) return const SplashScreen();
                  return BlocProvider(
                    create: (_) => sl<CommandCenterBloc>()..add(const CommandCenterRequested()),
                    child: CommandCenterPage(
                      session: current,
                      views: commandCenterViews(
                        session: current,
                        currentProfile: currentProfile,
                        notifications: notifications,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.telemetry,
                builder: (context, state) {
                  final id = _intParam(state.uri.queryParameters['deviceId']);
                  return BlocProvider(
                    key: ValueKey('telemetry-$id'),
                    create: (_) => sl<TelemetryDashboardBloc>()..add(TelemetryStarted(deviceId: id)),
                    child: const TelemetryDashboardScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alerts,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<AlertsBloc>()..add(const AlertsRequested()),
                  child: AlertsScreen(notifications: notifications),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.batches,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<BatchListBloc>()..add(const BatchListRequested()),
                  child: const BatchListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) {
                  final current = session.session;
                  if (current == null) return const SplashScreen();
                  return MorePage(session: current, currentProfile: currentProfile, onSignOut: session.signOut);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
