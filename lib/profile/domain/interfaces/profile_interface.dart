import 'dart:typed_data';

import '../entities/personal_data.dart';
import '../entities/profile_photo.dart';
import '../entities/user_profile.dart';

/// Contract of the profile repository: what can be done with the profile of
/// the signed-in user, not how. Implemented by the infrastructure layer.
abstract interface class ProfileInterface {
  Future<UserProfile> getMine();
  Future<UserProfile> updateMine(PersonalData data);

  /// Null when the user has no photo.
  Future<Uint8List?> getMyPhoto();
  Future<void> uploadMyPhoto(ProfilePhoto photo);
  Future<void> removeMyPhoto();
}
