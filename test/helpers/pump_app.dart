import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_theme.dart';
import 'package:qualitrack_mobile/common/presentation/i18n/app_localizations.dart';

const _delegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

extension PumpApp on WidgetTester {
  Future<void> pumpLocalized(
    Widget child, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 640),
  }) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _delegates,
        home: child,
      ),
    );
  }

  /// The same app as [pumpLocalized], led by [router] to follow where a screen
  /// goes.
  Future<void> pumpLocalizedRouter(
    RouterConfig<Object> router, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 640),
  }) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
    await pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _delegates,
        routerConfig: router,
      ),
    );
  }
}
