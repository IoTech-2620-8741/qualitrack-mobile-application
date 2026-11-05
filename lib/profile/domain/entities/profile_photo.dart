import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A JPG, PNG or WebP image of up to 2 MB.
final class ProfilePhoto extends Equatable {
  const ProfilePhoto({required this.bytes, required this.contentType});

  static const int maxBytes = 2 * 1024 * 1024;
  static const Set<String> allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final Uint8List bytes;
  final String contentType;

  /// Media type of a picked file from its name, or null when not allowed.
  static String? contentTypeOf(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  @override
  List<Object?> get props => [bytes.length, contentType];
}
