import '../../domain/failure.dart';

/// Defensive JSON readers. A contract violation becomes a [ParsingFailure]
/// instead of a raw `TypeError` in presentation.
abstract final class Json {
  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    throw ParsingFailure(message: 'Expected a JSON object but got ${value.runtimeType}');
  }

  static List<Map<String, dynamic>> asList(Object? value) {
    if (value is List) return value.map(asMap).toList(growable: false);
    throw ParsingFailure(message: 'Expected a JSON array but got ${value.runtimeType}');
  }

  static int requireInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ParsingFailure(message: 'Missing or invalid integer "$key"');
  }

  static int? optInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? optDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double requireDouble(Map<String, dynamic> json, String key) {
    final value = optDouble(json, key);
    if (value == null) throw ParsingFailure(message: 'Missing or invalid number "$key"');
    return value;
  }

  static String requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    if (value != null) return value.toString();
    throw ParsingFailure(message: 'Missing string "$key"');
  }

  static String? optString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return value is String ? value : value.toString();
  }

  static bool? optBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

  static List<String> stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) return value.map((e) => e.toString()).toList(growable: false);
    return const [];
  }

  /// Parses ISO-8601 strings; returns null if the backend string is not a date.
  static DateTime? optDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
