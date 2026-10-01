import 'package:flutter/foundation.dart';

import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../domain/onboarding_state.dart';
import '../domain/user_session.dart';
import 'iam_use_cases.dart';

enum SessionStatus { unknown, unauthenticated, setupRequired, authenticated }

/// Application-wide session state. It is the `refreshListenable` of the
/// router, so every status change re-evaluates route guards.
class SessionController extends ChangeNotifier {
  SessionController({
    required RestoreSession restoreSession,
    required SignOut signOut,
    required CheckOnboarding checkOnboarding,
  }) : _restoreSession = restoreSession,
       _signOut = signOut,
       _checkOnboarding = checkOnboarding;

  final RestoreSession _restoreSession;
  final SignOut _signOut;
  final CheckOnboarding _checkOnboarding;

  SessionStatus _status = SessionStatus.unknown;
  UserSession? _session;
  OnboardingStep? _pendingStep;
  bool _expired = false;

  SessionStatus get status => _status;
  UserSession? get session => _session;
  OnboardingStep? get pendingStep => _pendingStep;

  /// True when the last sign-out was caused by an expired/invalid token.
  bool get sessionExpired => _expired;

  String? get token => _session?.token.value;

  /// Laboratory of the signed-in user. Throws instead of falling back to a
  /// default laboratory.
  LaboratoryId requireLaboratoryId() {
    final id = _session?.laboratoryId;
    if (id == null) throw const MissingLaboratoryFailure();
    return id;
  }

  Future<void> restore() async {
    try {
      final session = await _restoreSession();
      if (session == null) {
        _set(SessionStatus.unauthenticated, null);
        return;
      }
      await _evaluate(session);
    } on Failure {
      _set(SessionStatus.unauthenticated, null);
    }
  }

  Future<void> signedIn(UserSession session) async {
    _expired = false;
    await _evaluate(session);
  }

  /// Re-checks onboarding (used by "Check again" on the setup page).
  Future<void> recheck() async {
    final session = _session;
    if (session == null) return;
    await _evaluate(session);
  }

  Future<void> signOut() async {
    await _signOut();
    _expired = false;
    _pendingStep = null;
    _set(SessionStatus.unauthenticated, null);
  }

  /// Called by the HTTP layer on 401. Idempotent to avoid redirect loops.
  Future<void> expire() async {
    if (_session == null) return;
    await _signOut();
    _expired = true;
    _pendingStep = null;
    _set(SessionStatus.unauthenticated, null);
  }

  void clearExpiredFlag() => _expired = false;

  Future<void> _evaluate(UserSession session) async {
    _session = session;
    if (!session.hasLaboratory) {
      _pendingStep = OnboardingStep.laboratory;
      _set(SessionStatus.setupRequired, session);
      return;
    }
    try {
      final onboarding = await _checkOnboarding();
      if (onboarding.isReady) {
        _pendingStep = null;
        _set(SessionStatus.authenticated, session);
      } else {
        _pendingStep = onboarding.nextStep;
        _set(SessionStatus.setupRequired, session);
      }
    } on UnauthorizedFailure {
      await expire();
    } on Failure {
      // Network or server problem: keep the valid session; screens will show
      // their own error states and the backend still guards every request.
      _pendingStep = null;
      _set(SessionStatus.authenticated, session);
    }
  }

  void _set(SessionStatus status, UserSession? session) {
    _status = status;
    _session = session;
    notifyListeners();
  }
}
