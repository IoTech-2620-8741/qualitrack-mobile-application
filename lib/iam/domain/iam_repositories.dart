import 'onboarding_state.dart';
import 'user_account.dart';
import 'user_session.dart';

abstract interface class AuthRepository {
  Future<UserSession> signIn({required String username, required String password});
  Future<OnboardingState> getOnboarding();
  Future<UserAccount> getUser(int userId);
}

abstract interface class SessionRepository {
  Future<UserSession?> load();
  Future<void> save(UserSession session);
  Future<void> clear();
}
