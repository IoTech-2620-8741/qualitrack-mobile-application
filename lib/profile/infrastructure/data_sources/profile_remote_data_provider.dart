import 'dart:typed_data';

import '../../../common/infrastructure/http/api_client.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/personal_data.dart';
import '../../domain/entities/profile_photo.dart';
import '../models/user_profile_model.dart';

/// Talks to the profile endpoints of the QualiTrack REST API.
class ProfileRemoteDataProvider {
  const ProfileRemoteDataProvider(this._client);

  final ApiClient _client;

  static const String _profile = '/users/me/profile';

  Future<UserProfileModel> getMine() async => UserProfileModel.fromJson(Json.asMap(await _client.get(_profile)));

  Future<UserProfileModel> updateMine(PersonalData data) async => UserProfileModel.fromJson(
    Json.asMap(
      await _client.put(
        _profile,
        body: {
          'fullName': data.fullName,
          'dni': data.dni,
          'phoneNumber': data.phoneNumber,
          'location': data.location,
        },
      ),
    ),
  );

  Future<Uint8List> getPhoto() => _client.getBytes('$_profile/photo');

  Future<void> uploadPhoto(ProfilePhoto photo) =>
      _client.putBytes('$_profile/photo', photo.bytes, contentType: photo.contentType);

  Future<void> removePhoto() => _client.delete('$_profile/photo');
}
