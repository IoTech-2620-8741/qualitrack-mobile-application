import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/access_token.dart';
import '../domain/onboarding_state.dart';
import '../domain/user_account.dart';
import '../domain/user_role.dart';
import '../domain/user_session.dart';

/// `AuthenticatedUserResource {id, username, token, roles, laboratoryId}`.
class AuthenticatedUserDto {
  const AuthenticatedUserDto({
    required this.id,
    required this.username,
    required this.token,
    required this.roles,
    this.laboratoryId,
  });

  factory AuthenticatedUserDto.fromJson(Map<String, dynamic> json) => AuthenticatedUserDto(
    id: Json.requireInt(json, 'id'),
    username: Json.requireString(json, 'username'),
    token: Json.requireString(json, 'token'),
    roles: Json.stringList(json, 'roles'),
    laboratoryId: Json.optInt(json, 'laboratoryId'),
  );

  final int id;
  final String username;
  final String token;
  final List<String> roles;
  final int? laboratoryId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'token': token,
    'roles': roles,
    'laboratoryId': laboratoryId,
  };

  UserSession toDomain() => UserSession(
    userId: id,
    username: username,
    roles: UserRole.parseAll(roles),
    token: AccessToken.fromJwt(token),
    laboratoryId: LaboratoryId.tryCreate(laboratoryId),
  );

  static AuthenticatedUserDto fromDomain(UserSession session) => AuthenticatedUserDto(
    id: session.userId,
    username: session.username,
    token: session.token.value,
    roles: session.roles.map((r) => r.code).toList(),
    laboratoryId: session.laboratoryId?.value,
  );
}

/// `UserOnboardingResource {userId, laboratoryId, subscriptionId, subscriptionStatus, nextStep}`.
class OnboardingDto {
  const OnboardingDto(this.json);

  final Map<String, dynamic> json;

  OnboardingState toDomain() => OnboardingState(
    nextStep: OnboardingStep.fromCode(Json.optString(json, 'nextStep')),
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    subscriptionId: Json.optInt(json, 'subscriptionId'),
    subscriptionStatus: Json.optString(json, 'subscriptionStatus'),
  );
}

/// `UserResource {id, username, roles, laboratoryId, status}`.
class UserDto {
  const UserDto(this.json);

  final Map<String, dynamic> json;

  UserAccount toDomain() => UserAccount(
    id: Json.requireInt(json, 'id'),
    username: Json.requireString(json, 'username'),
    roles: UserRole.parseAll(Json.stringList(json, 'roles')),
    laboratoryId: Json.optInt(json, 'laboratoryId'),
    status: Json.optString(json, 'status'),
  );
}
