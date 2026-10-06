/// Password policy of the platform (sign-up, reset and change): 8 to 72
/// characters with at least one letter and one number. The backend enforces
/// it; the app checks it first to explain the rule before sending.
abstract final class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 72;

  static bool isSatisfiedBy(String password) =>
      password.length >= minLength &&
      password.length <= maxLength &&
      RegExp(r'\p{L}', unicode: true).hasMatch(password) &&
      RegExp(r'\p{Nd}', unicode: true).hasMatch(password);
}
