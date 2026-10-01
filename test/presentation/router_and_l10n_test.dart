import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/app/router/app_router.dart';
import 'package:qualitrack_mobile/app/router/app_routes.dart';
import 'package:qualitrack_mobile/iam/application/session_controller.dart';
import 'package:qualitrack_mobile/shared/presentation/l10n/app_localizations.dart';

void main() {
  group('route guard', () {
    test('protected routes require a session', () {
      expect(resolveRedirect(SessionStatus.unauthenticated, '/alerts/3'), AppRoutes.signIn);
      expect(resolveRedirect(SessionStatus.unauthenticated, AppRoutes.signIn), isNull);
      expect(resolveRedirect(SessionStatus.unknown, AppRoutes.home), AppRoutes.splash);
    });

    test('authenticated users leave public routes', () {
      expect(resolveRedirect(SessionStatus.authenticated, AppRoutes.signIn), AppRoutes.home);
      expect(resolveRedirect(SessionStatus.authenticated, AppRoutes.splash), AppRoutes.home);
      expect(resolveRedirect(SessionStatus.authenticated, '/batches/3'), isNull);
    });

    test('incomplete setup is confined to the setup page', () {
      expect(resolveRedirect(SessionStatus.setupRequired, AppRoutes.home), AppRoutes.setupRequired);
      expect(resolveRedirect(SessionStatus.setupRequired, AppRoutes.setupRequired), isNull);
    });
  });

  group('localization', () {
    test('English and Spanish define the same keys', () {
      expect(AppLocalizations.spanishKeys, AppLocalizations.englishKeys);
    });

    test('unsupported languages fall back to English', () {
      expect(
        AppLocalizations.resolve(const Locale('fr'), AppLocalizations.supportedLocales),
        const Locale('en'),
      );
      expect(
        AppLocalizations.resolve(const Locale('es', 'PE'), AppLocalizations.supportedLocales),
        const Locale('es'),
      );
    });

    test('placeholders are replaced', () {
      final es = AppLocalizations(const Locale('es'));
      expect(es.pageOf(1, 3), 'Página 1 de 3');
      expect(AppLocalizations(const Locale('en')).lowStockAlert(3), '3 materials are below the minimum stock');
    });
  });
}
