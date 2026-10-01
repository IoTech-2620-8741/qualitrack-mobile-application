import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// `UserResource` from `GET /users/{userId}`.
final class UserAccount extends Equatable {
  const UserAccount({
    required this.id,
    required this.username,
    required this.roles,
    this.laboratoryId,
    this.status,
  });

  final int id;
  final String username;
  final List<UserRole> roles;
  final int? laboratoryId;
  final String? status;

  @override
  List<Object?> get props => [id, username, roles, laboratoryId, status];
}
