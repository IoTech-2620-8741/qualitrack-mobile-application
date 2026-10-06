import 'dart:typed_data';

import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../domain/profile.dart';

/// `ProfileResource {userId, staffId, username, email, roles, fullName, dni,
/// phoneNumber, location, position, hasPhoto, photoUpdatedAt, updatedAt}`.
class ProfileDto {
  const ProfileDto(this.json);

  final Map<String, dynamic> json;

  UserProfile toDomain() => UserProfile(
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

  static Map<String, dynamic> body(PersonalData data) => {
    'fullName': data.fullName,
    'dni': data.dni,
    'phoneNumber': data.phoneNumber,
    'location': data.location,
  };
}

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._client);

  final ApiClient _client;

  static const String _profile = '/users/me/profile';

  Future<ProfileDto> getMine() async => ProfileDto(Json.asMap(await _client.get(_profile)));

  Future<ProfileDto> updateMine(PersonalData data) async =>
      ProfileDto(Json.asMap(await _client.put(_profile, body: ProfileDto.body(data))));

  Future<Uint8List> getPhoto() => _client.getBytes('$_profile/photo');

  Future<void> uploadPhoto(ProfilePhoto photo) =>
      _client.putBytes('$_profile/photo', photo.bytes, contentType: photo.contentType);

  Future<void> removePhoto() => _client.delete('$_profile/photo');
}

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfile> getMine() async => (await _remote.getMine()).toDomain();

  @override
  Future<UserProfile> updateMine(PersonalData data) async => (await _remote.updateMine(data)).toDomain();

  @override
  Future<Uint8List?> getMyPhoto() => nullOnNotFound(_remote.getPhoto);

  @override
  Future<void> uploadMyPhoto(ProfilePhoto photo) => _remote.uploadPhoto(photo);

  @override
  Future<void> removeMyPhoto() => _remote.removePhoto();
}
