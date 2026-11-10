import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/domain/failure.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/labels.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/pressable_card.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../iam/api/index.dart';
import '../../application/get_command_center_summary.dart';
import '../bloc/command_center_bloc.dart';
import '../command_center_views.dart';

/// Home panel shown after signing in (US: consult the control panel of the
/// laboratory).
///
/// The greeting and the user's role · laboratory are the app bar title. The
/// body is exactly one viewport tall and never scrolls (pull-to-refresh still
/// works). It follows the order of importance of the Web menu (Operation),
/// one card per area and nothing else:
/// 1. Production batches (hero): status of every batch.
/// 2. Equipment · Tracking & telemetry, side by side.
/// 3. Compliance alerts: the one to look at first.
/// 4. Inventory: materials below the minimum stock.
/// On very short viewports (landscape, large text) the whole panel is laid
/// out at [_baseDesignHeight] (times the text scale) and scaled down to fit
/// instead of scrolling.
class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key, required this.session, required this.views});

  final UserSession session;
  final CommandCenterViews views;

  /// Smallest height at which every card shows its full content at 100% text
  /// size; it grows with the user's text scale.
  static const double _baseDesignHeight = 600;

  @override
  Widget build(BuildContext context) {
    void reload() => context.read<CommandCenterBloc>().add(const CommandCenterRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: views.profileChanges,
          builder:
              (context, _) => BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
                builder:
                    (context, state) =>
                        _GreetingTitle(session: session, views: views, laboratory: state.data?.laboratory.value?.name),
              ),
        ),
        actions: [views.notificationBell, views.profileButton],
      ),
      body: BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
        builder:
            (context, state) => RemoteStateView<CommandCenterSummary>(
              state: state,
              onRetry: reload,
              builder:
                  (context, summary) => LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      final designHeight = MediaQuery.textScalerOf(context).scale(_baseDesignHeight);
                      final panel = _Panel(summary: summary);
                      return RefreshIndicator(
                        onRefresh: () async => reload(),
                        // Exactly one viewport tall: the drag only triggers the
                        // refresh, the content itself never scrolls.
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: height,
                            child:
                                height >= designHeight
                                    ? panel
                                    : FittedBox(
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: constraints.maxWidth * designHeight / height,
                                        height: designHeight,
                                        child: panel,
                                      ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
      ),
    );
  }
}

String _error(BuildContext context, Failure? failure) =>
    failure == null ? '' : failureMessage(context, failure).split('\n').first;

const _gap = SizedBox.square(dimension: AppSpacing.md);

/// "Hello, {name}" with "role · laboratory" below it, as the app bar title.
class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle({required this.session, required this.views, required this.laboratory});

  final UserSession session;
  final CommandCenterViews views;
  final String? laboratory;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final role = session.primaryRole;
    final subtitle = [role == null ? null : views.roleLabel(role, i18n), laboratory].whereType<String>().join(' · ');
    return AppBarTitle(
      title: i18n.welcomeUser(views.displayName() ?? session.username),
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
  }
}

/// The whole panel, in the order of the Web menu.
class _Panel extends StatelessWidget {
  const _Panel({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 30, child: _BatchesCard(summary: summary)),
          _gap,
          Expanded(
            flex: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _EquipmentCard(summary: summary)),
                _gap,
                Expanded(child: _TelemetryCard(summary: summary)),
              ],
            ),
          ),
          _gap,
          Expanded(flex: 21, child: _AlertCard(summary: summary)),
          _gap,
          Expanded(flex: 14, child: _InventoryCard(summary: summary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// Home card: 16dp corners, white or tinted, ripple + press scale.
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, required this.onTap, required this.semanticLabel, this.color});

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) => PressableCard(
    onTap: onTap,
    color: color ?? AppColors.surface,
    borderRadius: AppRadius.xlAll,
    semanticLabel: semanticLabel,
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}

/// Tonal round icon + title, and an optional badge at the end.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.icon, required this.tone, this.badge});

  final String title;
  final IconData icon;
  final BadgeTone tone;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final neutral = tone == BadgeTone.neutral;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: neutral ? AppColors.primaryContainer : tone.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: neutral ? AppColors.primaryDark : tone.foreground),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.navy),
          ),
        ),
        if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
      ],
    );
  }
}

/// Big number followed by a short label on the same baseline.
class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.color = AppColors.textPrimary, this.size = 32});

  final String value;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value, style: AppTypography.metric.copyWith(fontSize: size, color: color)),
            TextSpan(text: '  $label', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// A colored dot and a short label, for chart legends.
class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: AppRadius.smAll)),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
    ],
  );
}

// ---------------------------------------------------------------------------
// 1 · Production batches
// ---------------------------------------------------------------------------

class _BatchesCard extends StatelessWidget {
  const _BatchesCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.batches;
    final s = part.value?.summary;
    final segments =
        s == null
            ? const <(int, Color, String)>[]
            : [
              (s.pending, AppColors.warningBase, i18n.batchPending),
              (s.inProgress, AppColors.info, i18n.batchInProgress),
              (s.released, AppColors.successBase, i18n.batchReleased),
              (s.rejected, AppColors.criticalBase, i18n.batchRejected),
            ];
    final semantic =
        s == null
            ? '${i18n.homeBatches}, ${_error(context, part.failure)}'
            : [i18n.homeBatches, for (final (count, _, label) in segments) '$label: $count'].join(', ');
    return _HomeCard(
      onTap: () => context.go('/batches'),
      semanticLabel: semantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: i18n.homeBatches,
            icon: Icons.inventory_2_outlined,
            tone: BadgeTone.neutral,
          ),
          const Spacer(),
          if (s == null)
            Text(_error(context, part.failure), maxLines: 2, overflow: TextOverflow.ellipsis)
          else ...[
            // Total as the headline; the bar and legend break it down by
            // status, so no status is repeated.
            _Metric(value: '${s.total}', label: i18n.batchesUnit, color: AppColors.primaryDark, size: 36),
            const SizedBox(height: AppSpacing.sm),
            _StatusBar(segments: [for (final (count, color, _) in segments) (count, color)]),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [for (final (count, color, label) in segments) _Legend(color: color, label: '$label $count')],
            ),
          ],
          const Spacer(), // centers the content in the card
        ],
      ),
    );
  }
}

/// One horizontal bar split by the share of each batch status.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.segments});

  final List<(int, Color)> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.$1);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          height: 8,
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

// ---------------------------------------------------------------------------
// 2 · Equipment · Tracking & telemetry
// ---------------------------------------------------------------------------

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final part = summary.equipment;
    final eq = part.value;
    final attention = eq == null ? 0 : eq.total - eq.operational;
    final tone = eq == null ? BadgeTone.neutral : (attention > 0 ? BadgeTone.warning : BadgeTone.success);
    final status =
        eq == null
            ? _error(context, part.failure)
            : (attention > 0 ? i18n.attentionCount(attention) : i18n.allEquipmentOk);
    return _HomeCard(
      onTap: () => context.go('/equipment'),
      semanticLabel: [
        i18n.navEquipment,
        if (eq != null) '${eq.operational} ${i18n.operationalOfTotal(eq.total)}',
        status,
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: i18n.navEquipment, icon: Icons.precision_manufacturing_outlined, tone: BadgeTone.neutral),
          const Spacer(),
          if (eq != null) _Metric(value: '${eq.operational}', label: i18n.operationalOfTotal(eq.total)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(tone.icon, size: 14, color: tone.foreground),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Spacer(), // centers the content in the card
        ],
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.equipment;
    final eq = part.value;
    return _HomeCard(
      onTap: () => context.go('/telemetry'),
      semanticLabel: [
        i18n.navTelemetry,
        if (eq == null) _error(context, part.failure),
        if (eq != null && eq.devices == 0) i18n.noIotDevices,
        if (eq != null && eq.devices > 0) i18n.iotOnline(eq.connected, eq.devices),
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: i18n.navTelemetry, icon: Icons.monitor_heart_outlined, tone: BadgeTone.neutral),
          const Spacer(),
          if (eq == null)
            Text(_error(context, part.failure), maxLines: 2, overflow: TextOverflow.ellipsis)
          else if (eq.devices == 0)
            Text(i18n.noIotDevices, style: Theme.of(context).textTheme.bodySmall)
          else ...[
            _Metric(value: '${eq.connected}/${eq.devices}', label: i18n.iotDevicesOnline),
          ],
          const Spacer(), // centers the content in the card
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Compliance alerts
// ---------------------------------------------------------------------------

/// The open alert to look at first, with how many critical ones are open.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final part = summary.alerts;
    final overview = part.value;
    final alert = overview?.mostUrgent;
    final critical = overview?.summary.critical ?? 0;

    if (alert == null) {
      final message = part.isOk ? i18n.noOpenAlertsShort : _error(context, part.failure);
      return _HomeCard(
        onTap: () => context.push('/alerts'),
        color: part.isOk ? AppColors.successContainer : null,
        semanticLabel: '${i18n.navAlerts}, $message',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              title: i18n.navAlerts,
              icon: Icons.verified_outlined,
              tone: part.isOk ? BadgeTone.success : BadgeTone.neutral,
            ),
            const Spacer(),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(color: part.isOk ? AppColors.success : AppColors.textMuted),
            ),
            const Spacer(), // centers the content in the card
          ],
        ),
      );
    }

    final tone = alert.isCritical ? BadgeTone.critical : BadgeTone.warning;
    final when = alert.lastDetectedAt ?? alert.timestamp;
    final variable = alertVariable(i18n, alert.parameterName);
    final where = [
      summary.equipmentNames[alert.equipmentId],
      if (when != null) Formatters.dateTime(when, context.localeName),
    ].whereType<String>().join(' · ');
    return _HomeCard(
      onTap: () => context.push('/alerts/${alert.id}'),
      color: tone.background,
      semanticLabel: [i18n.mostUrgentAlert, variable, where, if (critical > 0) i18n.criticalCount(critical)].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: i18n.mostUrgentAlert,
            icon: tone.icon,
            tone: tone,
            badge: critical > 0 ? StatusBadge(label: i18n.criticalCount(critical), tone: BadgeTone.critical) : null,
          ),
          const Spacer(),
          Text(
            variable,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(color: tone.foreground, fontWeight: FontWeight.w700),
          ),
          Text(where, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          const Spacer(), // centers the content in the card
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Inventory
// ---------------------------------------------------------------------------

/// One line: whether any material is below the minimum stock.
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.materials;
    final low = part.value?.where((m) => m.isBelowMinimum).length;
    final tone = low == null ? BadgeTone.neutral : (low > 0 ? BadgeTone.warning : BadgeTone.success);
    final message =
        low == null ? _error(context, part.failure) : (low > 0 ? i18n.lowStockAlert(low) : i18n.stockAboveMinimum);
    return _HomeCard(
      onTap: () => context.push('/inventory'),
      semanticLabel: '${i18n.moreInventory}, $message',
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone == BadgeTone.neutral ? AppColors.primaryContainer : tone.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.science_outlined,
              size: 18,
              color: tone == BadgeTone.neutral ? AppColors.primaryDark : tone.foreground,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.moreInventory,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.navy),
                ),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tone == BadgeTone.neutral ? null : tone.foreground),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
