import '../../shared/domain/failure.dart';
import '../domain/iam_repositories.dart';
import '../domain/onboarding_state.dart';
import '../domain/user_session.dart';

/// Signs in against IAM and persists the session securely.
class SignIn {
  const SignIn(this._auth, this._sessions);

  final AuthRepository _auth;
  final SessionRepository _sessions;

  Future<UserSession> call({required String username, required String password}) async {
    final user = username.trim();
    if (user.isEmpty || password.isEmpty) {
      throw const BadRequestFailure(code: 'CREDENTIALS_REQUIRED');
    }
    final session = await _auth.signIn(username: user, password: password);
    await _sessions.save(session);
    return session;
  }
}

/// Loads a stored session and discards it if the JWT has expired.
class RestoreSession {
  const RestoreSession(this._sessions, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SessionRepository _sessions;
  final DateTime Function() _clock;

  Future<UserSession?> call() async {
    final session = await _sessions.load();
    if (session == null) return null;
    if (session.isExpired(_clock().toUtc())) {
      await _sessions.clear();
      return null;
    }
    return session;
  }
}

/// Persists an updated session (e.g. once the temporary password was replaced).
class RememberSession {
  const RememberSession(this._sessions);

  final SessionRepository _sessions;

  Future<void> call(UserSession session) => _sessions.save(session);
}

class SignOut {
  const SignOut(this._sessions);

  final SessionRepository _sessions;

  Future<void> call() => _sessions.clear();
}

class CheckOnboarding {
  const CheckOnboarding(this._auth);

  final AuthRepository _auth;

  Future<OnboardingState> call() => _auth.getOnboarding();
}

/// Replaces the password of the signed-in user (`POST /users/me/password-changes`).
/// The password policy (8 to 72 characters with letters and numbers) is
/// enforced by the backend; here only the presence of both values is checked.
class ChangePassword {
  const ChangePassword(this._auth);

  final AuthRepository _auth;

  Future<void> call({required String currentPassword, required String newPassword}) {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const BadRequestFailure(code: 'PASSWORDS_REQUIRED');
    }
    return _auth.changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}
