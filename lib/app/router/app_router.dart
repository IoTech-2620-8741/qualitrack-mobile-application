import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../batch/presentation/bloc/batch_detail_bloc.dart';
import '../../batch/presentation/bloc/batches_bloc.dart';
import '../../batch/presentation/pages/batch_detail_page.dart';
import '../../batch/presentation/pages/batches_page.dart';
import '../../command_center/presentation/bloc/command_center_bloc.dart';
import '../../command_center/presentation/pages/command_center_page.dart';
import '../../compliance/presentation/bloc/alert_detail_bloc.dart';
import '../../compliance/presentation/bloc/alerts_bloc.dart';
import '../../compliance/presentation/pages/alert_detail_page.dart';
import '../../compliance/presentation/pages/alerts_page.dart';
import '../../equipment/presentation/bloc/equipment_detail_bloc.dart';
import '../../equipment/presentation/bloc/equipment_list_bloc.dart';
import '../../equipment/presentation/pages/equipment_detail_page.dart';
import '../../equipment/presentation/pages/equipment_list_page.dart';
import '../../iam/application/session_controller.dart';
import '../../iam/presentation/bloc/profile_bloc.dart';
import '../../iam/presentation/bloc/sign_in_bloc.dart';
import '../../iam/presentation/pages/profile_page.dart';
import '../../iam/presentation/pages/setup_required_page.dart';
import '../../iam/presentation/pages/sign_in_page.dart';
import '../../iam/presentation/pages/splash_page.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../inventory/presentation/bloc/material_detail_bloc.dart';
import '../../inventory/presentation/pages/inventory_page.dart';
import '../../inventory/presentation/pages/material_detail_page.dart';
import '../../laboratory/presentation/bloc/products_bloc.dart';
import '../../laboratory/presentation/pages/products_page.dart';
import '../../reporting/presentation/bloc/reports_bloc.dart';
import '../../reporting/presentation/pages/reports_page.dart';
import '../../shared/presentation/l10n/app_localizations.dart';
import '../../shared/presentation/widgets/state_views.dart';
import '../../subscription/presentation/bloc/billing_bloc.dart';
import '../../subscription/presentation/pages/billing_page.dart';
import '../../tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import '../../tracking/presentation/bloc/telemetry_history_bloc.dart';
import '../../tracking/presentation/pages/telemetry_dashboard_page.dart';
import '../../tracking/presentation/pages/telemetry_history_page.dart';
import '../dependency_injection/injection.dart';
import 'app_routes.dart';
import 'main_shell.dart';
import 'more_page.dart';

/// Pure redirect rule, extracted for unit testing.
String? resolveRedirect(SessionStatus status, String location) {
  final isPublic = AppRoutes.public.contains(location);
  switch (status) {
    case SessionStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionStatus.unauthenticated:
      return location == AppRoutes.signIn ? null : AppRoutes.signIn;
    case SessionStatus.setupRequired:
      return location == AppRoutes.setupRequired ? null : AppRoutes.setupRequired;
    case SessionStatus.authenticated:
      return isPublic ? AppRoutes.home : null;
  }
}

int? _intParam(String? raw) {
  final value = int.tryParse(raw ?? '');
  return value != null && value > 0 ? value : null;
}

Widget _invalidId(BuildContext context) =>
    Scaffold(appBar: AppBar(), body: EmptyView(title: context.l10n.errorNotFound));

GoRouter createRouter(SessionController session) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) => resolveRedirect(session.status, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<SignInBloc>(),
          child: SignInPage(sessionExpired: session.sessionExpired),
        ),
      ),
      GoRoute(
        path: AppRoutes.setupRequired,
        builder: (context, state) => SetupRequiredPage(session: session),
      ),
      // Secondary screens are pushed on the root navigator (above the shell).
      GoRoute(
        path: '/telemetry/history',
        builder: (context, state) {
          final id = _intParam(state.uri.queryParameters['equipmentId']);
          return BlocProvider(
            create: (_) =>
                sl<TelemetryHistoryBloc>()..add(TelemetryHistoryStarted(equipmentId: id)),
            child: const TelemetryHistoryPage(),
          );
        },
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (context, state) {
          final id = _intParam(state.pathParameters['id']);
          if (id == null) return _invalidId(context);
          return BlocProvider(
            create: (_) =>
                sl<AlertDetailBloc>(param1: id)..add(const AlertDetailRequested()),
            child: AlertDetailPage(canReview: session.session?.canReview ?? false),
          );
        },
      ),
      GoRoute(
        path: '/batches/:id',
        builder: (context, state) {
          final id = _intParam(state.pathParameters['id']);
          if (id == null) return _invalidId(context);
          return BlocProvider(
            create: (_) =>
                sl<BatchDetailBloc>(param1: id)..add(const BatchDetailRequested()),
            child: BatchDetailPage(canReview: session.session?.canReview ?? false),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.equipment,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<EquipmentListBloc>()..add(const EquipmentListRequested()),
          child: const EquipmentListPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _invalidId(context);
              return BlocProvider(
                create: (_) =>
                    sl<EquipmentDetailBloc>(param1: id)..add(const EquipmentDetailRequested()),
                child: const EquipmentDetailPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<InventoryBloc>()..add(const InventoryRequested()),
          child: const InventoryPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _invalidId(context);
              return BlocProvider(
                create: (_) =>
                    sl<MaterialDetailBloc>(param1: id)..add(const MaterialDetailRequested()),
                child: const MaterialDetailPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ProductsBloc>()..add(const ProductsRequested()),
          child: const ProductsPage(),
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
          child: const ReportsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billing,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<BillingBloc>()..add(const BillingRequested()),
          child: const BillingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
          child: ProfilePage(onSignOut: session.signOut),
        ),
      ),
      GoRoute(path: AppRoutes.about, builder: (context, state) => const AboutPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<CommandCenterBloc>()..add(const CommandCenterRequested()),
                  child: session.session == null
                      ? const SplashPage()
                      : CommandCenterPage(session: session.session!),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.telemetry,
                builder: (context, state) {
                  final id = _intParam(state.uri.queryParameters['equipmentId']);
                  return BlocProvider(
                    key: ValueKey('telemetry-$id'),
                    create: (_) => sl<TelemetryDashboardBloc>()..add(TelemetryStarted(equipmentId: id)),
                    child: const TelemetryDashboardPage(),
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
                  child: const AlertsPage(),
                ),
             ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.batches,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<BatchesBloc>()..add(const BatchesRequested()),
                  child: const BatchesPage(),
                ),
             ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => session.session == null
                    ? const SplashPage()
                    : MorePage(session: session.session!, onSignOut: session.signOut),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
