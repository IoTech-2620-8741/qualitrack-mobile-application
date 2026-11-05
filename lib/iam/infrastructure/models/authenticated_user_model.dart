import '../../../common/domain/value_objects.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/access_token.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/user_session.dart';

/// `AuthenticatedUserResource {id, username, token, roles, laboratoryId, passwordChangeRequired}`.
/// It is also the JSON stored in the keystore.
class AuthenticatedUserModel extends UserSession {
  const AuthenticatedUserModel({
    required super.userId,
    required super.username,
    required super.roles,
    required super.token,
    super.laboratoryId,
    super.passwordChangeRequired,
  });

  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) => AuthenticatedUserModel(
    userId: Json.requireInt(json, 'id'),
    username: Json.requireString(json, 'username'),
    token: AccessToken.fromJwt(Json.requireString(json, 'token')),
    roles: UserRole.parseAll(Json.stringList(json, 'roles')),
    laboratoryId: LaboratoryId.tryCreate(Json.optInt(json, 'laboratoryId')),
    passwordChangeRequired: Json.optBool(json, 'passwordChangeRequired') ?? false,
  );

  factory AuthenticatedUserModel.fromDomain(UserSession session) => AuthenticatedUserModel(
    userId: session.userId,
    username: session.username,
    roles: session.roles,
    token: session.token,
    laboratoryId: session.laboratoryId,
    passwordChangeRequired: session.passwordChangeRequired,
  );

  Map<String, dynamic> toJson() => {
    'id': userId,
    'username': username,
    'token': token.value,
    'roles': roles.map((r) => r.code).toList(),
    'laboratoryId': laboratoryId?.value,
    'passwordChangeRequired': passwordChangeRequired,
  };
}
