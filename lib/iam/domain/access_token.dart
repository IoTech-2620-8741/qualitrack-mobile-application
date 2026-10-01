import 'dart:convert';

import 'package:equatable/equatable.dart';

/// JWT issued by `POST /authentication/sign-in`. Only the `exp` claim is read
/// on the device; signature validation stays on the server.
final class AccessToken extends Equatable {
  const AccessToken(this.value, {this.expiresAt});

  factory AccessToken.fromJwt(String jwt) =>
      AccessToken(jwt, expiresAt: _readExpiration(jwt));

  final String value;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) =>
      value.isEmpty || (expiresAt != null && !now.isBefore(expiresAt!));

  static DateTime? _readExpiration(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      if (claims is Map && claims['exp'] is num) {
        final seconds = (claims['exp'] as num).toInt();
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  List<Object?> get props => [value, expiresAt];

  @override
  String toString() => 'AccessToken(expiresAt: $expiresAt)';
}
