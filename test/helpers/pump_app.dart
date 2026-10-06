import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/app/theme/app_theme.dart';
import 'package:qualitrack_mobile/shared/presentation/l10n/app_localizations.dart';

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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }
}
