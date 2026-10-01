import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/failure.dart';

/// Translates Dio errors and QualiTrack `ErrorResource` bodies
/// (`{code, message, details}`) into typed [Failure]s.
abstract final class ApiExceptionMapper {
  static Failure map(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    if (error is SocketException) return NetworkFailure(message: error.message);
    if (error is FormatException || error is TypeError) {
      return ParsingFailure(message: error.toString());
    }
    return UnexpectedFailure(message: error.toString());
  }

  static Failure _fromDio(DioException error) {
    // Not a switch: `DioExceptionType` gains values between Dio releases and
    // an exhaustive switch would stop compiling on an upgrade.
    final type = error.type;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.badCertificate) {
      return NetworkFailure(message: error.message);
    }
    if (type == DioExceptionType.cancel) {
      return const UnexpectedFailure(message: 'Request cancelled');
    }
    if (type == DioExceptionType.badResponse) {
      return fromResponse(error.response);
    }
    final inner = error.error;
    if (inner is SocketException) return NetworkFailure(message: inner.message);
    if (inner is Failure) return inner;
    if (inner is FormatException) return ParsingFailure(message: inner.message);
    return UnexpectedFailure(message: error.message);
  }

  static Failure fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final body = response?.data;
    String? code;
    String? message;
    String? nextStep;
    if (body is Map) {
      code = body['code']?.toString();
      final details = body['details']?.toString();
      final msg = body['message']?.toString();
      message = _join(msg, details);
      nextStep = body['nextStep']?.toString();
    } else if (body is String && body.trim().isNotEmpty && !body.trimLeft().startsWith('<')) {
      message = body.trim();
    }

    if (status == 400) return BadRequestFailure(message: message, code: code);
    if (status == 401) return UnauthorizedFailure(message: message, code: code);
    if (status == 403) {
      if (code == 'ONBOARDING_REQUIRED') {
        return OnboardingRequiredFailure(nextStep: nextStep, message: message);
      }
      return ForbiddenFailure(message: message, code: code);
    }
    if (status == 404) return NotFoundFailure(message: message, code: code);
    if (status == 409) return ConflictFailure(message: message, code: code);
    if (status >= 500) {
      return ServerFailure(message: message, code: code, statusCode: status);
    }
    return UnexpectedFailure(message: message ?? 'HTTP $status');
  }

  static String? _join(String? message, String? details) {
    final parts = [message, details]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'null')
        .toSet()
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' — ');
  }
}
