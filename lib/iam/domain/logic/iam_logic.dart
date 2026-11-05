import '../../../common/domain/failure.dart';

/// Business rules of Identity & Access. Pure Dart: the facade applies them on
/// top of the repository.
mixin IamLogic {
  /// Both credentials are required; the username is trimmed.
  String requireCredentials(String username, String password) {
    final user = username.trim();
    if (user.isEmpty || password.isEmpty) throw const BadRequestFailure(code: 'CREDENTIALS_REQUIRED');
    return user;
  }

  /// The password policy (8 to 72 characters with letters and numbers) is
  /// enforced by the backend; here only the presence of both values is checked.
  void requirePasswords(String currentPassword, String newPassword) {
    if (currentPassword.isEmpty || newPassword.isEmpty) throw const BadRequestFailure(code: 'PASSWORDS_REQUIRED');
  }
}
