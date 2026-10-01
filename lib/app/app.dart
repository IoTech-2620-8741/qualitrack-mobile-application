import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../iam/application/session_controller.dart';
import '../shared/presentation/l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme.dart';

class QualiTrackApp extends StatefulWidget {
  const QualiTrackApp({super.key, required this.session});

  final SessionController session;

  @override
  State<QualiTrackApp> createState() => _QualiTrackAppState();
}

class _QualiTrackAppState extends State<QualiTrackApp> {
  late final GoRouter _router = createRouter(widget.session);

  @override
  void initState() {
    super.initState();
    widget.session.restore();
  }

  @override
  void dispose() {
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
