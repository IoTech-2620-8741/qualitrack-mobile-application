import 'package:flutter/widgets.dart';

import '../../domain/failure.dart';
import '../l10n/app_localizations.dart';

/// Human readable, localized message for a [Failure]. Backend messages are
/// appended for validation/conflict errors because they explain the rule.
String failureMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;
  final base = switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
    TimeoutFailure() => l10n.errorTimeout,
    BadRequestFailure(code: 'CREDENTIALS_REQUIRED') => l10n.errorCredentialsRequired,
    BadRequestFailure() => l10n.errorBadRequest,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    OnboardingRequiredFailure() => l10n.errorOnboarding,
    ForbiddenFailure() => l10n.errorForbidden,
    NotFoundFailure() => l10n.errorNotFound,
    ConflictFailure() => l10n.errorConflict,
    ServerFailure() => l10n.errorServer,
    ParsingFailure() => l10n.errorParsing,
    MissingLaboratoryFailure() => l10n.errorMissingLaboratory,
    UnexpectedFailure() => l10n.errorUnexpected,
  };
  final detail = failure.message;
  final showDetail =
      detail != null &&
      detail.isNotEmpty &&
      (failure is BadRequestFailure || failure is ConflictFailure || failure is ForbiddenFailure);
  return showDetail ? '$base\n$detail' : base;
}
