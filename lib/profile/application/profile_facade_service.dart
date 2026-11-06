import 'dart:typed_data';

import '../domain/entities/personal_data.dart';
import '../domain/entities/profile_photo.dart';
import '../domain/entities/user_profile.dart';
import '../domain/interfaces/profile_interface.dart';
import '../domain/logic/profile_logic.dart';

/// Use cases of the Profile context exposed to the presentation layer. It only
/// orchestrates: the rules live in [ProfileLogic] and the data access behind
/// [ProfileInterface].
class ProfileFacadeService with ProfileLogic {
  const ProfileFacadeService({required ProfileInterface repository}) : _repository = repository;

  final ProfileInterface _repository;

  Future<UserProfile> getMyProfile() => _repository.getMine();

  /// Command: update the personal data of the user.
  Future<UserProfile> updateMyProfile(PersonalData data) => _repository.updateMine(cleanPersonalData(data));

  /// Null when the user has no photo.
  Future<Uint8List?> getMyPhoto() => _repository.getMyPhoto();

  /// Command: replace the photo.
  Future<void> uploadMyPhoto(ProfilePhoto photo) => _repository.uploadMyPhoto(requireValidPhoto(photo));

  Future<void> removeMyPhoto() => _repository.removeMyPhoto();
}
