import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Photo of the user, or the initials when there is none.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, this.photo, this.radius = 20});

  final String initials;
  final Uint8List? photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = photo;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryContainer,
      foregroundImage: image == null ? null : MemoryImage(image),
      child: Text(
        initials,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: radius * 0.75),
      ),
    );
  }
}
