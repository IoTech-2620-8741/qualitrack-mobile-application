import 'package:dio/dio.dart';

/// Returns the current access token, or null when there is no session.
typedef TokenProvider = String? Function();

/// Invoked once when an authenticated request receives HTTP 401.
typedef UnauthorizedHandler = Future<void> Function();

/// Adds `Authorization: Bearer <token>` and reports 401 responses so the
/// session can be cleared and the router can return to Sign In.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider, required this.onUnauthorized});

  final TokenProvider tokenProvider;
  final UnauthorizedHandler onUnauthorized;

  static const String skipAuthKey = 'skipAuth';

  bool _handlingUnauthorized = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skip = options.extra[skipAuthKey] == true;
    final token = tokenProvider();
    if (!skip && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final skip = err.requestOptions.extra[skipAuthKey] == true;
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && !skip && hadToken && !_handlingUnauthorized) {
      // Guard against re-entrancy: several parallel requests can fail at once.
      _handlingUnauthorized = true;
      try {
        await onUnauthorized();
      } finally {
        _handlingUnauthorized = false;
      }
    }
    handler.next(err);
  }
}
