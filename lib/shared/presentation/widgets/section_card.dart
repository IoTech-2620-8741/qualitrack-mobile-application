import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../section.dart';
import 'failure_message.dart';
import 'layout_widgets.dart';

/// Card that renders an independently loaded [Section]: its items, an empty
/// message or the error returned for that section only.
class SectionCard<T> extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.section,
    required this.itemBuilder,
    this.emptyMessage,
    this.maxItems,
  });

  final String title;
  final Section<T> section;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String? emptyMessage;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget body;
    if (section.failure != null) {
      body = Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failureMessage(context, section.failure!),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.critical),
            ),
          ),
        ],
      );
    } else if (section.items.isEmpty) {
      body = Text(emptyMessage ?? context.l10n.noInformation, style: theme.textTheme.bodySmall);
    } else {
      final items = maxItems == null ? section.items : section.items.take(maxItems!).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg),
            itemBuilder(context, items[i]),
          ],
        ],
      );
    }
    return InfoCard(title: title, child: body);
  }
}

/// Two-line row used inside section cards.
class SectionRow extends StatelessWidget {
  const SectionRow({super.key, required this.title, this.subtitle, this.trailing, this.leading});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
      ],
    );
  }
}
