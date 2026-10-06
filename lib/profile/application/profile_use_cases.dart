import 'dart:typed_data';

import '../../shared/domain/failure.dart';
import '../domain/profile.dart';

class GetMyProfile {
  const GetMyProfile(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> call() => _repository.getMine();
}

/// Updates the personal data. Empty optional fields are sent as null.
class UpdateMyProfile {
  const UpdateMyProfile(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> call(PersonalData data) {
    String? optional(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();
    final clean = PersonalData(
      fullName: data.fullName.trim(),
      dni: optional(data.dni),
      phoneNumber: optional(data.phoneNumber),
      location: optional(data.location),
    );
    final valid = PersonalDataRules.isValidFullName(clean.fullName) &&
        (clean.dni == null || PersonalDataRules.isValidDni(clean.dni!)) &&
        (clean.phoneNumber == null || PersonalDataRules.isValidPhone(clean.phoneNumber!)) &&
        (clean.location == null || PersonalDataRules.isValidLocation(clean.location!));
    if (!valid) throw const BadRequestFailure(code: 'INVALID_PERSONAL_DATA');
    return _repository.updateMine(clean);
  }
}

class GetMyPhoto {
  const GetMyPhoto(this._repository);

  final ProfileRepository _repository;

  Future<Uint8List?> call() => _repository.getMyPhoto();
}

/// Replaces the photo (US: update my profile photo): JPG, PNG or WebP of up
/// to 2 MB.
class UploadMyPhoto {
  const UploadMyPhoto(this._repository);

  final ProfileRepository _repository;

  Future<void> call(ProfilePhoto photo) {
    if (photo.bytes.isEmpty || !ProfilePhoto.allowedTypes.contains(photo.contentType)) {
      throw const BadRequestFailure(code: 'PHOTO_TYPE_NOT_ALLOWED');
    }
    if (photo.bytes.length > ProfilePhoto.maxBytes) throw const BadRequestFailure(code: 'PHOTO_TOO_LARGE');
    return _repository.uploadMyPhoto(photo);
  }
}

class RemoveMyPhoto {
  const RemoveMyPhoto(this._repository);

  final ProfileRepository _repository;

  Future<void> call() => _repository.removeMyPhoto();
}
