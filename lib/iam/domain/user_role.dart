/// Roles defined by `iam.domain.model.valueobjects.Roles` in the backend.
enum UserRole {
  admin('ROLE_ADMIN'),
  qaManager('ROLE_QA_MANAGER'),
  labOperator('ROLE_LAB_OPERATOR');

  const UserRole(this.code);

  final String code;

  static UserRole? fromCode(String code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }

  static List<UserRole> parseAll(Iterable<String> codes) =>
      codes.map(fromCode).whereType<UserRole>().toList(growable: false);
}
