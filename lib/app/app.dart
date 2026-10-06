import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../compliance/presentation/bloc/unread_notifications_controller.dart';
import '../iam/application/session_controller.dart';
import '../profile/presentation/bloc/current_profile_controller.dart';
import '../shared/presentation/l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme.dart';

class QualiTrackApp extends StatefulWidget {
  const QualiTrackApp({
    super.key,
    required this.session,
    required this.notifications,
    required this.currentProfile,
  });

  final SessionController session;
  final UnreadNotificationsController notifications;
  final CurrentProfileController currentProfile;

  @override
  State<QualiTrackApp> createState() => _QualiTrackAppState();
}

class _QualiTrackAppState extends State<QualiTrackApp> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter(
    widget.session,
    notifications: widget.notifications,
    currentProfile: widget.currentProfile,
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_onSessionChanged);
    widget.session.restore();
  }

  /// The bell and the profile of the menu follow the session: they load once
  /// operational access is ready and are cleared on sign-out.
  void _onSessionChanged() {
    final ready = widget.session.status == SessionStatus.authenticated;
    if (ready == _ready) return;
    _ready = ready;
    if (ready) {
      widget.notifications.start();
      widget.currentProfile.load();
    } else {
      widget.notifications.reset();
      widget.currentProfile.reset();
    }
  }

  /// No polling while the app is in background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.resumed) {
      widget.notifications.start();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      widget.notifications.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_onSessionChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // English is the default for any unsupported device language.
      localeResolutionCallback: AppLocalizations.resolve,
    );
  }
}
