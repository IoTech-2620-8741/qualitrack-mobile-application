import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../models/authenticated_user_model.dart';
import '../models/onboarding_state_model.dart';

/// Talks to the authentication and onboarding endpoints of the QualiTrack REST API.
class IamRemoteDataProvider {
  const IamRemoteDataProvider(this._client);

  final ApiClient _client;

  Future<AuthenticatedUserModel> signIn(String username, String password) async {
    final data = await _client.post(
      '/authentication/sign-in',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    return AuthenticatedUserModel.fromJson(Json.asMap(data));
  }

  Future<OnboardingStateModel> getOnboarding() async {
    final data = await _client.get('/users/me/onboarding');
    return OnboardingStateModel.fromJson(Json.asMap(data));
  }

  Future<void> changePassword(String currentPassword, String newPassword) => _client.post(
    '/users/me/password-changes',
    body: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );
}
