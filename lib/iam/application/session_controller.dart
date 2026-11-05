import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../domain/entities/onboarding_step.dart';
import '../domain/entities/user_session.dart';
import 'iam_facade_service.dart';

enum SessionStatus { unknown, unauthenticated, passwordChangeRequired, setupRequired, authenticated }

/// Application-wide session state. The router refreshes on every change, so
/// each status change re-evaluates route guards. It is plain Dart: `app/`
/// adapts the listeners to the router.
class SessionController {
  SessionController({required IamFacadeService iamService}) : _iamService = iamService;

  final IamFacadeService _iamService;

  final _listeners = <void Function()>[];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

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
      final session = await _iamService.restoreSession();
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

  /// Called once the temporary password was replaced.
  Future<void> passwordChanged() async {
    final session = _session;
    if (session == null) return;
    final updated = session.withPasswordChanged();
    await _iamService.rememberSession(updated);
    await _evaluate(updated);
  }

  Future<void> signOut() async {
    await _iamService.signOut();
    _expired = false;
    _pendingStep = null;
    _set(SessionStatus.unauthenticated, null);
  }

  /// Called by the HTTP layer on 401. Idempotent to avoid redirect loops.
  Future<void> expire() async {
    if (_session == null) return;
    await _iamService.signOut();
    _expired = true;
    _pendingStep = null;
    _set(SessionStatus.unauthenticated, null);
  }

  void clearExpiredFlag() => _expired = false;

  Future<void> _evaluate(UserSession session) async {
    _session = session;
    try {
      final onboarding = await _iamService.checkOnboarding();
      if (onboarding.isReady) {
        _pendingStep = null;
        _set(SessionStatus.authenticated, session);
      } else if (onboarding.requiresPasswordChange) {
        _pendingStep = onboarding.nextStep;
        _set(SessionStatus.passwordChangeRequired, session);
      } else {
        _pendingStep = onboarding.nextStep;
        _set(SessionStatus.setupRequired, session);
      }
    } on UnauthorizedFailure {
      await expire();
    } on Failure {
      // Network or server problem: keep the valid session; screens will show
      // their own error states and the backend still guards every request.
      if (session.passwordChangeRequired) {
        _pendingStep = OnboardingStep.passwordChange;
        _set(SessionStatus.passwordChangeRequired, session);
      } else if (!session.hasLaboratory) {
        _pendingStep = OnboardingStep.laboratory;
        _set(SessionStatus.setupRequired, session);
      } else {
        _pendingStep = null;
        _set(SessionStatus.authenticated, session);
      }
    }
  }

  void _set(SessionStatus status, UserSession? session) {
    _status = status;
    _session = session;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
