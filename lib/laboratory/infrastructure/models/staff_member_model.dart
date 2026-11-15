import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/staff_member.dart';

/// `StaffMemberResource {id, laboratoryId, fullName, role, email, active, accessRole, userId}`.
class StaffMemberModel extends StaffMember {
  const StaffMemberModel({
    required super.id,
    required this.laboratoryId,
    required super.fullName,
    required super.active,
    super.position,
    super.email,
    super.accessRole,
    super.userId,
  });

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) => StaffMemberModel(
    id: Json.requireInt(json, 'id'),
    laboratoryId: Json.requireInt(json, 'laboratoryId'),
    fullName: Json.requireString(json, 'fullName'),
    position: Json.optString(json, 'role'),
    email: Json.optString(json, 'email'),
    active: Json.optBool(json, 'active') ?? true,
    accessRole: Json.optString(json, 'accessRole'),
    userId: Json.optInt(json, 'userId'),
  );

  /// Laboratory the backend says the staff member belongs to.
  final int laboratoryId;
}
