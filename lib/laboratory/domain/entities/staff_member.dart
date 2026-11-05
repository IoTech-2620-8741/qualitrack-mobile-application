import 'package:equatable/equatable.dart';

/// `StaffMemberResource`: an operator or auditor registered by the quality
/// manager. [userId] is the account used to sign in.
class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.fullName,
    required this.active,
    this.position,
    this.email,
    this.accessRole,
    this.userId,
  });

  final int id;
  final String fullName;
  final String? position;
  final String? email;
  final bool active;

  /// `OPERATOR` or `AUDITOR`.
  final String? accessRole;
  final int? userId;

  @override
  List<Object?> get props => [id, fullName, position, email, active, accessRole, userId];
}
