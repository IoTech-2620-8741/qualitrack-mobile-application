import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'toggle_button.dart';
export 'search_field.dart';

/// Title of a screen's top app bar, with an optional subtitle line below it
/// (count, code, context). The screen shows its title here only, never again
/// inside the body.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = subtitle;
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, height: 1.2),
          ),
          if (sub != null && sub.isNotEmpty)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, height: 1.3),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact KPI tile (Command Center, counters).
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.color = AppColors.primary,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(icon, size: 20, color: color),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AppTypography.metric),
                ),
                if (caption != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of equally sized children (2 columns on phones).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 150});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor().clamp(1, 4).toInt();
        final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

/// Compact label/value pair for small spaces inside a card (label above, in
/// sentence case, value below). For the attributes of a record use
/// [DetailList] instead.
class KeyValue extends StatelessWidget {
  const KeyValue({super.key, required this.label, required this.value, this.valueWidget});

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: valueWidget == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          valueWidget ??
              Text(value, style: text.bodyLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// One attribute of a record as a mobile list row: label on the left, value
/// on the right (or a custom widget such as a badge or a link).
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value, this.valueWidget, this.icon});

  final String label;
  final String value;
  final Widget? valueWidget;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: valueWidget == null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 5,
                child: Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                flex: 6,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget ??
                      Text(
                        value,
                        textAlign: TextAlign.end,
                        style: text.bodyLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rows of [DetailRow] separated by hairline dividers, as in the settings and
/// detail screens of Android.
class DetailList extends StatelessWidget {
  const DetailList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          children[i],
        ],
      ],
    );
  }
}

/// A section of a screen: an optional header outside the surface (as in
/// grouped mobile lists) and a borderless rounded surface with the content.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.title, this.color, this.borderColor, this.padding});

  final Widget child;
  final String? title;
  final Color? color;

  /// Only for tinted, state-carrying sections (e.g. a rejected batch).
  final Color? borderColor;

  /// Inner padding; defaults to 16dp horizontal and a little less vertical.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      color: color ?? AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
        side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: child,
      ),
    );
    if (title == null) return surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ),
        surface,
      ],
    );
  }
}

/// Horizontal, scrollable single-select chip bar used for filters.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
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
  Widget build(BuildContext context) => ToggleButtonBar<T>(
    options: options,
    selected: selected,
    labelOf: labelOf,
    onSelected: onSelected,
  );
}

/// QualiTrack wordmark for app bars.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_rounded, color: AppColors.primary),
        SizedBox(width: AppSpacing.sm),
        Text(
          'QualiTrack',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ],
    );
  }
}
