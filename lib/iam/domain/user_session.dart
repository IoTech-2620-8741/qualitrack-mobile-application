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
    this.passwordChangeRequired = false,
  });

  final int userId;
  final String username;
  final List<UserRole> roles;
  final AccessToken token;
  final LaboratoryId? laboratoryId;

  /// True while a staff member still uses the temporary password.
  final bool passwordChangeRequired;

  bool get hasLaboratory => laboratoryId != null;

  /// Quality managers release or reject batches, see the subscription and the
  /// profiles of their staff, as in QualiTrack Web. The backend remains the
  /// authority on every request.
  bool get canManageQuality => roles.contains(UserRole.admin) || roles.contains(UserRole.qaManager);

  /// Operators and quality managers attend and resolve alerts; auditors only read.
  bool get canAttendAlerts => !isAuditor && roles.isNotEmpty;

  bool get isAuditor => primaryRole == UserRole.auditor;

  UserRole? get primaryRole {
    for (final role in const [UserRole.admin, UserRole.qaManager, UserRole.labOperator, UserRole.auditor]) {
      if (roles.contains(role)) return role;
    }
    return null;
  }

  bool isExpired(DateTime now) => token.isExpired(now);

  UserSession withPasswordChanged() => UserSession(
    userId: userId,
    username: username,
    roles: roles,
    token: token,
    laboratoryId: laboratoryId,
  );

  @override
  List<Object?> get props => [userId, username, roles, token, laboratoryId, passwordChangeRequired];
}
