import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import 'iam_dtos.dart';

class IamRemoteDataSource {
  const IamRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthenticatedUserDto> signIn(String username, String password) async {
    final data = await _client.post(
      '/authentication/sign-in',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    return AuthenticatedUserDto.fromJson(Json.asMap(data));
  }

  Future<OnboardingDto> getOnboarding() async {
    final data = await _client.get('/users/me/onboarding');
    return OnboardingDto(Json.asMap(data));
  }

  Future<UserDto> getUser(int userId) async {
    final data = await _client.get('/users/$userId');
    return UserDto(Json.asMap(data));
  }
}
