import '../entities/onboarding_state.dart';
import '../entities/user_session.dart';

/// Contract of the identity repository: authentication, the onboarding check
/// and the persisted session, not how they are done. Implemented by the
/// infrastructure layer.
abstract interface class IamInterface {
  Future<UserSession> signIn({required String username, required String password});
  Future<OnboardingState> getOnboarding();
  Future<void> changePassword({required String currentPassword, required String newPassword});

  /// The stored session, or null when there is none.
  Future<UserSession?> loadSession();
  Future<void> saveSession(UserSession session);
  Future<void> clearSession();
}
