import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'status_badge.dart';

/// Compact, one-row card that says what a list is showing: the filter in use
/// (chosen from a FAB menu), how many items match and out of how many.
///
/// Tinted with the filter's tone; an optional badge (e.g. critical alerts)
/// sits at the end. It animates when the filter changes and the change is
/// announced to screen readers.
class FilterSummaryCard extends StatelessWidget {
  const FilterSummaryCard({
    super.key,
    required this.filterLabel,
    required this.icon,
    required this.tone,
    required this.count,
    required this.total,
    this.badge,
  });

  final String filterLabel;
  final IconData icon;
  final BadgeTone tone;

  /// Items currently shown (after the filter and the search).
  final int count;

  /// Every item of the list.
  final int total;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final neutral = tone == BadgeTone.neutral;
    final accent = neutral ? AppColors.navy : tone.foreground;
    final ofTotal = i18n.ofTotal(total);
    return Semantics(
      liveRegion: true,
      label: '${i18n.showingFilter(filterLabel)}, $count $ofTotal',
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey('$filterLabel·$count·$total'),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xxs),
          decoration: BoxDecoration(
            color: neutral ? AppColors.surface : tone.background,
            borderRadius: AppRadius.lgAll,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.showingFilter(filterLabel).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$count', style: AppTypography.metric.copyWith(fontSize: 22, color: accent)),
                          TextSpan(text: '  $ofTotal', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
            ],
          ),
        ),
      ),
    );
  }
}
