import 'onboarding_state.dart';
import 'user_session.dart';

abstract interface class AuthRepository {
  Future<UserSession> signIn({required String username, required String password});
  Future<OnboardingState> getOnboarding();
  Future<void> changePassword({required String currentPassword, required String newPassword});
}

abstract interface class SessionRepository {
  Future<UserSession?> load();
  Future<void> save(UserSession session);
  Future<void> clear();
}
