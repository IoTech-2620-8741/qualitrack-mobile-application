import 'package:equatable/equatable.dart';

/// `ProfileResource` of the Profile context: personal data of the signed-in
/// user, shown in the app bar and in the staff records.
class UserProfile extends Equatable {
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
