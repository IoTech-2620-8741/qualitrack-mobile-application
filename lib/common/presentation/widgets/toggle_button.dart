import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// M3 Expressive toggle button, used for filters and single choices.
///
/// Unselected: neutral pill. Selected: brand filled, and the shape morphs to a
/// rounded square (12dp) so the state never depends on color alone. Pressing
/// squares it a bit more. 40dp tall with a 48dp touch target.
class ToggleButton extends StatefulWidget {
  const ToggleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final IconData? icon;

  static final ButtonStyle _style = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
    tapTargetSize: MaterialTapTargetSize.padded,
    elevation: const WidgetStatePropertyAll(0),
    textStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 14,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
      ),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return AppColors.neutralContainer;
      return states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.neutralContainer;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
      return states.contains(WidgetState.selected) ? Colors.white : AppColors.textPrimary;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      if (states.contains(WidgetState.pressed)) return selected ? AppColors.primaryHover : const Color(0x1F0F766E);
      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
        return selected ? const Color(0x14FFFFFF) : const Color(0x140F766E);
      }
      return null;
    }),
    shape: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return const RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
      if (states.contains(WidgetState.selected)) return const RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
      return const StadiumBorder();
    }),
  );

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  // Feeds `selected` into the button's widget states so the style resolves it.
  late final WidgetStatesController _states = WidgetStatesController({
    if (widget.selected) WidgetState.selected,
  });

  @override
  void didUpdateWidget(ToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _states.update(WidgetState.selected, widget.selected);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final label = Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Semantics(
      selected: widget.selected,
      child: TextButton(
        onPressed: widget.onPressed,
        statesController: _states,
        style: ToggleButton._style,
        child: icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: label),
                ],
              ),
      ),
    );
  }
}

/// Horizontal, scrollable row of [ToggleButton]s (standard button group)
/// with a single selected option.
class ToggleButtonBar<T> extends StatelessWidget {
  const ToggleButtonBar({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ToggleButton(
                label: labelOf(option),
                selected: option == selected,
                onPressed: () => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}
