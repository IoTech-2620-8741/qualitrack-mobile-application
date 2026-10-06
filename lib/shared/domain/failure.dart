import 'package:equatable/equatable.dart';

/// Typed failure raised by repositories. Presentation maps each kind to a
/// localized, human readable message; raw exceptions never reach widgets.
sealed class Failure extends Equatable implements Exception {
  const Failure({this.message, this.code});

  /// Message provided by the backend (`ErrorResource.message/details`), if any.
  final String? message;

  /// Backend error code (e.g. `VALIDATION_ERROR`, `BATCH_NOT_FOUND`), if any.
  final String? code;

  @override
  List<Object?> get props => [runtimeType, message, code];

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// No network connectivity or the host could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
}

/// The request exceeded the configured timeout.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message});
}

/// HTTP 400 - the backend rejected the payload or a business rule.
final class BadRequestFailure extends Failure {
  const BadRequestFailure({super.message, super.code});
}

/// HTTP 401 - missing, invalid or expired credentials.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message, super.code});
}

/// HTTP 403 - authenticated but not allowed (tenant or role).
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message, super.code});
}

/// HTTP 403 with `ONBOARDING_REQUIRED`: account setup must be completed on Web.
final class OnboardingRequiredFailure extends Failure {
  const OnboardingRequiredFailure({this.nextStep, super.message})
    : super(code: 'ONBOARDING_REQUIRED');

  final String? nextStep;

  @override
  List<Object?> get props => [...super.props, nextStep];
}

/// HTTP 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message, super.code});
}

/// HTTP 409.
final class ConflictFailure extends Failure {
  const ConflictFailure({super.message, super.code});
}

/// HTTP 5xx.
final class ServerFailure extends Failure {
  const ServerFailure({super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// The response body did not match the expected contract.
final class ParsingFailure extends Failure {
  const ParsingFailure({super.message});
}

/// The signed-in user has no laboratory assigned; configuration happens on Web.
final class MissingLaboratoryFailure extends Failure {
  const MissingLaboratoryFailure();
}

/// Any other unexpected error.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message});
}
