import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';
import 'access_token.dart';
import 'user_role.dart';

/// Authenticated user as returned by the IAM context.
final class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.username,
    required this.roles,
    required this.token,
    this.laboratoryId,
  });

  final int userId;
  final String username;
  final List<UserRole> roles;
  final AccessToken token;
  final LaboratoryId? laboratoryId;

  bool get hasLaboratory => laboratoryId != null;

  /// UI-only hint: review actions (release/reject, acknowledge/resolve) are
  /// shown to QA Managers and Admins. The backend remains the authority.
  bool get canReview => roles.contains(UserRole.admin) || roles.contains(UserRole.qaManager);

  UserRole? get primaryRole {
    for (final role in const [UserRole.admin, UserRole.qaManager, UserRole.labOperator]) {
      if (roles.contains(role)) return role;
    }
    return null;
  }

  bool isExpired(DateTime now) => token.isExpired(now);

  @override
  List<Object?> get props => [userId, username, roles, token, laboratoryId];
}
