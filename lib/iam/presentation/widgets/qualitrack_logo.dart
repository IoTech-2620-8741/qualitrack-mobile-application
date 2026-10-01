import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class QualiTrackLogo extends StatelessWidget {
  const QualiTrackLogo({super.key, this.size = 96});

  static const String assetPath = 'assets/images/qualitrack_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'QualiTrack',
      image: true,
      child: Image.asset(
        assetPath,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.verified_user_rounded, size: size * 0.6, color: AppColors.primary),
      ),
    );
  }
}
