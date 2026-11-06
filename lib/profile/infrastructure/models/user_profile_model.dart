import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/user_profile.dart';

/// `ProfileResource {userId, staffId, username, email, roles, fullName, dni,
/// phoneNumber, location, position, hasPhoto, photoUpdatedAt, updatedAt}`.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.username,
    super.staffId,
    super.email,
    super.roles,
    super.fullName,
    super.dni,
    super.phoneNumber,
    super.location,
    super.position,
    super.hasPhoto,
    super.photoUpdatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
    userId: Json.requireInt(json, 'userId'),
    staffId: Json.optInt(json, 'staffId'),
    username: Json.requireString(json, 'username'),
    email: Json.optString(json, 'email'),
    roles: Json.stringList(json, 'roles'),
    fullName: Json.optString(json, 'fullName'),
    dni: Json.optString(json, 'dni'),
    phoneNumber: Json.optString(json, 'phoneNumber'),
    location: Json.optString(json, 'location'),
    position: Json.optString(json, 'position'),
    hasPhoto: Json.optBool(json, 'hasPhoto') ?? false,
    photoUpdatedAt: Json.optDateTime(json, 'photoUpdatedAt'),
  );
}
