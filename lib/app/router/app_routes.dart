/// Route paths used across the app.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String setupRequired = '/setup-required';

  static const String home = '/home';
  static const String telemetry = '/telemetry';
  static const String telemetryHistory = '/telemetry/history';
  static const String alerts = '/alerts';
  static const String batches = '/batches';
  static const String more = '/more';

  static const String equipment = '/equipment';
  static const String inventory = '/inventory';
  static const String products = '/products';
  static const String reports = '/reports';
  static const String billing = '/billing';
  static const String profile = '/profile';
  static const String about = '/about';

  static const Set<String> public = {splash, signIn, setupRequired};
}
