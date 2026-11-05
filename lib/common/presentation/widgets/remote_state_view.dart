import 'package:flutter/material.dart';

import '../../domain/failure.dart';
import '../remote_state.dart';
import '../view_status.dart';
import 'failure_message.dart';
import 'state_views.dart';

/// Renders the common loading / empty / error states and delegates the
/// success case to [builder]. When a refresh fails while stale data is shown,
/// a snackbar-like inline notice is displayed instead of hiding the content.
class RemoteStateView<T> extends StatelessWidget {
  const RemoteStateView({
    super.key,
    required this.state,
    required this.builder,
    required this.onRetry,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final RemoteState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingView();
      case ViewStatus.failure:
        return ErrorView(failure: state.failure ?? const UnexpectedFailure(), onRetry: onRetry);
      case ViewStatus.empty:
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: EmptyView(title: emptyTitle, message: emptyMessage, icon: emptyIcon),
        );
      case ViewStatus.success:
        final data = state.data as T;
        return Column(
          children: [
            RefreshingBar(visible: state.refreshing),
            if (state.failure != null) StaleDataNotice(failure: state.failure!),
            Expanded(child: builder(context, data)),
          ],
        );
    }
  }
}

class StaleDataNotice extends StatelessWidget {
  const StaleDataNotice({super.key, required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  failureMessage(context, failure),
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
