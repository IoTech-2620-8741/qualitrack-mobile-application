import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';

/// One horizontal bar split by the share of each part, under a figure of the
/// Home. It repeats what the text beside it says, so screen readers skip it.
class ProportionBar extends StatelessWidget {
  const ProportionBar({super.key, required this.segments, this.height = 6});

  /// The count and the color of each part, in order.
  final List<(int, Color)> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.$1);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          height: height,
          child:
              total == 0
                  ? const ColoredBox(color: AppColors.neutralContainer)
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (count, color) in segments)
                        if (count > 0) Expanded(flex: count, child: ColoredBox(color: color)),
                    ],
                  ),
        ),
      ),
    );
  }
}
