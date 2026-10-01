import 'package:dio/dio.dart';

import '../../domain/failure.dart';
import '../configuration/api_config.dart';
import 'api_exception_mapper.dart';
import 'auth_interceptor.dart';

/// Single HTTP entry point of the app. Remote data sources depend on this
/// class, never on Dio directly, and always receive typed [Failure]s.
class ApiClient {
  ApiClient(this._dio);

  factory ApiClient.create({
    required ApiConfig config,
    required AuthInterceptor authInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );
    dio.interceptors.add(authInterceptor);
    return ApiClient(dio);
  }

  final Dio _dio;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    bool authenticated = true,
  }) {
    return _send(
      () => _dio.get<Object?>(
        path,
        queryParameters: _clean(query),
        options: _options(authenticated),
      ),
    );
  }

  Future<Object?> post(String path, {Object? body, bool authenticated = true}) {
    return _send(
      () => _dio.post<Object?>(path, data: body, options: _options(authenticated)),
    );
  }

  Future<Object?> patch(String path, {Object? body}) {
    return _send(() => _dio.patch<Object?>(path, data: body));
  }

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } catch (error) {
      throw ApiExceptionMapper.map(error);
    }
  }

  Options _options(bool authenticated) =>
      Options(extra: {AuthInterceptor.skipAuthKey: !authenticated});

  Map<String, Object?>? _clean(Map<String, Object?>? query) {
    if (query == null) return null;
    final result = <String, Object?>{};
    query.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) result[key] = value;
    });
    return result;
  }
}

/// Convenience for data sources that must map a missing resource to null.
Future<T?> nullOnNotFound<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on NotFoundFailure {
    return null;
  }
}
