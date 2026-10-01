/// API configuration injected at build time:
///
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  factory ApiConfig.fromEnvironment() {
    const raw = String.fromEnvironment('API_BASE_URL');
    return ApiConfig(baseUrl: raw);
  }

  /// Host root, e.g. `http://10.0.2.2:8080` (without `/api/v1`).
  final String baseUrl;

  static const String apiPrefix = '/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// Base URL used by Dio, always ending in `/api/v1`.
  String get apiBaseUrl {
    var root = baseUrl.trim();
    while (root.endsWith('/')) {
      root = root.substring(0, root.length - 1);
    }
    if (root.endsWith(apiPrefix)) return root;
    return '$root$apiPrefix';
  }
}
