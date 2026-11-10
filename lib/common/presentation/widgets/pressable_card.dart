import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Card surface with immediate touch feedback: the Material ripple plus a
/// subtle scale-down while pressed. Without [onTap] it renders as a plain,
/// non-interactive card.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = Colors.transparent,
    this.semanticLabel,
    this.borderRadius = AppRadius.lgAll,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  /// Read by screen readers instead of the visual content when provided.
  final String? semanticLabel;

  /// Corner radius of the card (12dp by default).
  final BorderRadius borderRadius;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: widget.color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius,
        side: BorderSide(color: widget.borderColor),
      ),
      child: widget.onTap == null
          ? widget.child
          : InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              splashColor: const Color(0x1F0F766E),
              highlightColor: const Color(0x0F0F766E),
              child: widget.child,
            ),
    );
    final scaled = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: card,
    );
    if (widget.semanticLabel == null) return scaled;
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: scaled,
    );
  }
}
