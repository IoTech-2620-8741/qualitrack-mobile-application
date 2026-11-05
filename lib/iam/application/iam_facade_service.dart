import '../domain/entities/onboarding_state.dart';
import '../domain/entities/user_session.dart';
import '../domain/interfaces/iam_interface.dart';
import '../domain/logic/iam_logic.dart';

/// Use cases of Identity & Access exposed to the presentation layer. It only
/// orchestrates: the rules live in [IamLogic] and the data access behind
/// [IamInterface].
class IamFacadeService with IamLogic {
  IamFacadeService({required IamInterface repository, DateTime Function()? clock})
    : _repository = repository,
      _clock = clock ?? DateTime.now;

  final IamInterface _repository;
  final DateTime Function() _clock;

  /// Signs in against IAM and persists the session securely.
  Future<UserSession> signIn({required String username, required String password}) async {
    final user = requireCredentials(username, password);
    final session = await _repository.signIn(username: user, password: password);
    await _repository.saveSession(session);
    return session;
  }

  /// Loads a stored session and discards it if the JWT has expired.
  Future<UserSession?> restoreSession() async {
    final session = await _repository.loadSession();
    if (session == null) return null;
    if (session.isExpired(_clock().toUtc())) {
      await _repository.clearSession();
      return null;
    }
    return session;
  }

  /// Persists an updated session (e.g. once the temporary password was replaced).
  Future<void> rememberSession(UserSession session) => _repository.saveSession(session);

  Future<void> signOut() => _repository.clearSession();

  Future<OnboardingState> checkOnboarding() => _repository.getOnboarding();

  /// Replaces the password of the signed-in user (`POST /users/me/password-changes`).
  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    requirePasswords(currentPassword, newPassword);
    return _repository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}
