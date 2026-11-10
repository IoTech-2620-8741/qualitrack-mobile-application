import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One option of a [FabMenuHost].
class FabMenuItem<T> {
  const FabMenuItem({required this.value, required this.label, required this.icon, this.count});

  final T value;
  final String label;
  final IconData icon;

  /// Optional number shown after the label (e.g. how many alerts match).
  final int? count;
}

/// M3 Expressive FAB menu over a screen's content.
///
/// Closed: a FAB (16dp rounded square) at the bottom-right corner, above the
/// navigation bar. Open: a scrim dims the content, the options slide in as
/// pills stacked above the FAB, and the FAB becomes a round close (×) button.
/// The selected option is brand filled. Choosing one closes the menu.
/// Content under it should leave [bottomClearance] of empty space at the end.
class FabMenuHost<T> extends StatefulWidget {
  const FabMenuHost({
    super.key,
    required this.child,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.icon,
    required this.tooltip,
  });

  /// Space a scrollable under the FAB should add at its end.
  static const double bottomClearance = 56 + AppSpacing.lg * 2;

  final Widget child;
  final List<FabMenuItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String tooltip;

  @override
  State<FabMenuHost<T>> createState() => _FabMenuHostState<T>();
}

class _FabMenuHostState<T> extends State<FabMenuHost<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );

  bool get _open => _anim.status == AnimationStatus.forward || _anim.status == AnimationStatus.completed;

  void _toggle() {
    // Rebuild so PopScope picks up the new open state.
    setState(() {
      if (_open) {
        _anim.reverse();
      } else {
        _anim.forward();
      }
    });
  }

  void _choose(T value) {
    widget.onSelected(value);
    setState(() {
      _anim.reverse();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return PopScope(
      // The system back gesture closes the menu first.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _toggle();
      },
      // Fills the space it is given, so the FAB sits at the screen's corner.
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // Scrim: dims the content and closes the menu when tapped.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => _anim.value == 0
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: _toggle,
                      child: ColoredBox(color: Colors.black.withValues(alpha: 0.32 * _anim.value)),
                    ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Options above the FAB; they scroll when there are more than
                // fit above it (small phones, large text). Reversed so the
                // options closest to the FAB stay visible first.
                Flexible(
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _StaggeredItem(
                            animation: _anim,
                            // The option closest to the FAB appears first.
                            index: items.length - 1 - i,
                            count: items.length,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _MenuPill(
                                item: items[i],
                                selected: items[i].value == widget.selected,
                                onTap: () => _choose(items[i].value),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final open = _anim.value > 0.5;
                    return FloatingActionButton(
                      heroTag: null,
                      tooltip: open ? MaterialLocalizations.of(context).closeButtonTooltip : widget.tooltip,
                      onPressed: _toggle,
                      // Rounded square when closed, circle when open.
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 + 12 * _anim.value)),
                      child: Icon(open ? Icons.close : widget.icon),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and slides an option in, one after the other.
class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({required this.animation, required this.index, required this.count, required this.child});

  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index / count) * 0.5;
    final curve = CurvedAnimation(parent: animation, curve: Interval(start, start + 0.5, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        if (curve.value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - curve.value)), child: child),
        );
      },
      child: child,
    );
  }
}

/// One option: 56dp pill with icon, label and optional count.
class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({required this.item, required this.selected, required this.onTap});

  final FabMenuItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primaryDark;
    final count = item.count;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? item.label : '${item.label}, $count',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primaryDark : AppColors.primaryContainer,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: StadiumBorder(
          side: selected ? BorderSide.none : BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 22, color: fg),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withValues(alpha: 0.2) : AppColors.surface,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
