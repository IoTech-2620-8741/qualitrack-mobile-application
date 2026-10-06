import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// `ProfileResource` of the Profile context: personal data of the signed-in
/// user, shown in the app bar and in the staff records.
final class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.username,
    this.staffId,
    this.email,
    this.roles = const [],
    this.fullName,
    this.dni,
    this.phoneNumber,
    this.location,
    this.position,
    this.hasPhoto = false,
    this.photoUpdatedAt,
  });

  final int userId;
  final int? staffId;
  final String username;
  final String? email;
  final List<String> roles;
  final String? fullName;
  final String? dni;
  final String? phoneNumber;
  final String? location;

  /// Position registered by the quality manager (staff members only).
  final String? position;
  final bool hasPhoto;
  final DateTime? photoUpdatedAt;

  String get displayName => (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : username;

  /// Initials shown when there is no photo.
  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  List<Object?> get props => [
    userId,
    staffId,
    username,
    email,
    roles,
    fullName,
    dni,
    phoneNumber,
    location,
    position,
    hasPhoto,
    photoUpdatedAt,
  ];
}

/// Personal data the user can change (US: update my personal data).
final class PersonalData extends Equatable {
  const PersonalData({required this.fullName, this.dni, this.phoneNumber, this.location});

  final String fullName;
  final String? dni;
  final String? phoneNumber;
  final String? location;

  @override
  List<Object?> get props => [fullName, dni, phoneNumber, location];
}

/// A JPG, PNG or WebP image of up to 2 MB.
final class ProfilePhoto extends Equatable {
  const ProfilePhoto({required this.bytes, required this.contentType});

  static const int maxBytes = 2 * 1024 * 1024;
  static const Set<String> allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final Uint8List bytes;
  final String contentType;

  /// Media type of a picked file from its name, or null when not allowed.
  static String? contentTypeOf(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  @override
  List<Object?> get props => [bytes.length, contentType];
}

/// Rules of the Profile context, checked before sending to explain them.
abstract final class PersonalDataRules {
  static bool isValidFullName(String value) => value.trim().length >= 2 && value.trim().length <= 120;

  static bool isValidDni(String value) => RegExp(r'^\d{8}$').hasMatch(value.trim());

  static bool isValidPhone(String value) {
    final text = value.trim();
    final digits = text.replaceAll(RegExp(r'\D'), '').length;
    return RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text) && digits >= 6 && digits <= 15;
  }

  static bool isValidLocation(String value) => value.trim().length >= 2 && value.trim().length <= 120;
}

abstract interface class ProfileRepository {
  Future<UserProfile> getMine();
  Future<UserProfile> updateMine(PersonalData data);

  /// Null when the user has no photo.
  Future<Uint8List?> getMyPhoto();
  Future<void> uploadMyPhoto(ProfilePhoto photo);
  Future<void> removeMyPhoto();
}
