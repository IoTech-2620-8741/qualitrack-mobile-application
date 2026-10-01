import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../domain/failure.dart';
import '../l10n/app_localizations.dart';
import 'failure_message.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label ?? context.l10n.loading,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: icon,
      iconColor: AppColors.textMuted,
      title: title ?? context.l10n.noInformation,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.refresh),
            ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: failure is NetworkFailure || failure is TimeoutFailure
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      iconColor: AppColors.critical,
      title: context.l10n.errorTitle,
      message: failureMessage(context, failure),
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: iconColor),
                  const SizedBox(height: AppSpacing.md),
                  Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(message!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  ],
                  if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin progress bar shown on top of already visible content while refreshing.
class RefreshingBar extends StatelessWidget {
  const RefreshingBar({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: visible
          ? Semantics(label: context.l10n.refreshing, child: const LinearProgressIndicator())
          : null,
    );
  }
}
