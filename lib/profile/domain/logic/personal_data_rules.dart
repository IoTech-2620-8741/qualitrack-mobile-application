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
