import 'package:flutter/widgets.dart';

import '../../domain/failure.dart';
import '../i18n/app_localizations.dart';

/// Short title that names what happened ("No connection", "Access
/// restricted"…) instead of a generic "Something went wrong": the user reads
/// the cause first and the message below says what to do.
String failureTitle(BuildContext context, Failure failure) {
  final i18n = context.i18n;
  return switch (failure) {
    NetworkFailure() => i18n.errorTitleNetwork,
    TimeoutFailure() => i18n.errorTitleTimeout,
    UnauthorizedFailure() || ForbiddenFailure() || OnboardingRequiredFailure() || MissingLaboratoryFailure() =>
      i18n.errorTitleAccess,
    NotFoundFailure() => i18n.errorTitleNotFound,
    ServerFailure() => i18n.errorTitleServer,
    _ => i18n.errorTitle,
  };
}

/// Human readable, localized message for a [Failure]. Backend messages are
/// appended for validation/conflict errors because they explain the rule.
String failureMessage(BuildContext context, Failure failure) {
  final i18n = context.i18n;
  final base = switch (failure) {
    NetworkFailure() => i18n.errorNetwork,
    TimeoutFailure() => i18n.errorTimeout,
    BadRequestFailure(code: 'CREDENTIALS_REQUIRED') => i18n.errorCredentialsRequired,
    BadRequestFailure(code: 'PASSWORDS_REQUIRED') => i18n.passwordRequired,
    BadRequestFailure(code: 'INVALID_PERIOD') => i18n.periodMax31Days,
    BadRequestFailure(code: 'PAYLOAD_TOO_LARGE' || 'PHOTO_TOO_LARGE') => i18n.photoTooLarge,
    BadRequestFailure(code: 'UNSUPPORTED_MEDIA_TYPE' || 'PHOTO_TYPE_NOT_ALLOWED') => i18n.photoTypeNotAllowed,
    BadRequestFailure() => i18n.errorBadRequest,
    UnauthorizedFailure() => i18n.errorUnauthorized,
    OnboardingRequiredFailure() => i18n.errorOnboarding,
    ForbiddenFailure() => i18n.errorForbidden,
    NotFoundFailure() => i18n.errorNotFound,
    ConflictFailure() => i18n.errorConflict,
    ServerFailure() => i18n.errorServer,
    ParsingFailure() => i18n.errorParsing,
    MissingLaboratoryFailure() => i18n.errorMissingLaboratory,
    UnexpectedFailure() => i18n.errorUnexpected,
  };
  final detail = failure.message;
  final showDetail =
      detail != null &&
      detail.isNotEmpty &&
      (failure is BadRequestFailure || failure is ConflictFailure || failure is ForbiddenFailure);
  return showDetail ? '$base\n$detail' : base;
}
