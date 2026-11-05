import '../../../common/domain/failure.dart';
import '../entities/personal_data.dart';
import '../entities/profile_photo.dart';
import 'personal_data_rules.dart';

/// Business rules of the Profile context. Pure Dart: the facade applies them
/// on top of the repository.
mixin ProfileLogic {
  /// Trims the data and turns empty optional fields into null. Invalid data is
  /// rejected before reaching the backend.
  PersonalData cleanPersonalData(PersonalData data) {
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
    return clean;
  }

  /// A photo must be a JPG, PNG or WebP of up to 2 MB.
  ProfilePhoto requireValidPhoto(ProfilePhoto photo) {
    if (photo.bytes.isEmpty || !ProfilePhoto.allowedTypes.contains(photo.contentType)) {
      throw const BadRequestFailure(code: 'PHOTO_TYPE_NOT_ALLOWED');
    }
    if (photo.bytes.length > ProfilePhoto.maxBytes) throw const BadRequestFailure(code: 'PHOTO_TOO_LARGE');
    return photo;
  }
}
