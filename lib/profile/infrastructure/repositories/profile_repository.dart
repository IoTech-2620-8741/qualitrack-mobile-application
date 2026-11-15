import 'dart:typed_data';

import '../../../common/infrastructure/http/api_client.dart';
import '../../domain/entities/personal_data.dart';
import '../../domain/entities/profile_photo.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/interfaces/profile_interface.dart';
import '../data_sources/profile_remote_data_provider.dart';

/// Implements [ProfileInterface] with the REST API. There is no offline cache:
/// every read goes to the remote data provider.
class ProfileRepository implements ProfileInterface {
  const ProfileRepository({required ProfileRemoteDataProvider remoteDataProvider}) : _remote = remoteDataProvider;

  final ProfileRemoteDataProvider _remote;

  @override
  Future<UserProfile> getMine() => _remote.getMine();

  @override
  Future<UserProfile> updateMine(PersonalData data) => _remote.updateMine(data);

  @override
  Future<Uint8List?> getMyPhoto() => nullOnNotFound(_remote.getPhoto);

  @override
  Future<void> uploadMyPhoto(ProfilePhoto photo) => _remote.uploadPhoto(photo);

  @override
  Future<void> removeMyPhoto() => _remote.removePhoto();
}
