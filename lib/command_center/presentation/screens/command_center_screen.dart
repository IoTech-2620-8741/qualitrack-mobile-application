import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/domain/failure.dart';
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
/// body shows four cards, two per row, in order of importance read top to
/// bottom and left to right (Report, Mobile Style Guidelines):
/// 1. Compliance alerts: open alerts, the critical ones and the most urgent.
/// 2. Telemetry: IoT devices connected, to review and without data.
/// 3. Production batches awaiting the QA decision.
/// 4. Inventory: materials below the minimum stock.
/// The cards fill the screen and never scroll at the normal text size: on a
/// short screen each card leaves out its detail instead of shrinking. Only
/// when the user's larger text does not fit even then, the panel scrolls, so
/// the text keeps the size the user chose. Pull-to-refresh always works.
class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key, required this.session, required this.views});

  final UserSession session;
  final CommandCenterViews views;

  /// Height the body needs for the full cards at 100% text size (494 with
  /// Roboto at 360dp in Spanish); it grows with the user's text scale. Below
  /// it the cards are compact: they keep their figure and leave the detail to
  /// the screen they open.
  static const double fullHeight = 520;

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
                      final compact = constraints.maxHeight < MediaQuery.textScalerOf(context).scale(fullHeight);
                      return RefreshIndicator(
                        onRefresh: () async => reload(),
                        // At least one viewport tall: the cards share the
                        // whole height, and only content taller than the
                        // screen (large text) scrolls.
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(child: _Panel(summary: summary, compact: compact)),
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

/// The four cards, two per row, in order of importance.
class _Panel extends StatelessWidget {
  const _Panel({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget row(Widget start, Widget end) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: start), _gap, Expanded(child: end)],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(_AlertCard(summary: summary, compact: compact), _TelemetryCard(summary: summary, compact: compact)),
          _gap,
          row(_BatchesCard(summary: summary, compact: compact), _InventoryCard(summary: summary, compact: compact)),
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

/// Tonal round icon + title.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.icon, required this.tone});

  final String title;
  final IconData icon;
  final BadgeTone tone;

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
      ],
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
      // A half-width card may be narrower than a long label: it wraps.
      Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

/// The figure that matters in a card: a big number and, below it, what it
/// counts.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.color = AppColors.textPrimary});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(value, maxLines: 1, style: AppTypography.metric.copyWith(fontSize: 32, color: color)),
      ),
      Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Content of a home card: the header, the figure, and below it the detail,
/// which a compact card leaves out.
class _CardBody extends StatelessWidget {
  const _CardBody({required this.header, required this.figure, required this.compact, this.detail = const []});

  final Widget header;
  final Widget figure;
  final bool compact;
  final List<Widget> detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header,
      const SizedBox(height: AppSpacing.sm),
      const Spacer(),
      figure,
      if (!compact && detail.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), ...detail],
      const Spacer(), // centers the content in the card
    ],
  );
}

/// One horizontal bar split by the share of each part.
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

/// The bar of [segments] and its legend.
List<Widget> _breakdown(List<(int, Color, String)> segments) => [
  _StatusBar(segments: [for (final (count, color, _) in segments) (count, color)]),
  const SizedBox(height: AppSpacing.sm),
  Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.xxs,
    children: [for (final (count, color, label) in segments) _Legend(color: color, label: '$label $count')],
  ),
];

// ---------------------------------------------------------------------------
// 1 · Compliance alerts
// ---------------------------------------------------------------------------

/// Open alerts, how many are critical and the one to look at first.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final part = summary.alerts;
    final overview = part.value;
    final open = overview?.summary.open;
    final critical = overview?.summary.critical ?? 0;
    final alert = overview?.mostUrgent;
    final tone =
        overview == null
            ? BadgeTone.neutral
            : (critical > 0 ? BadgeTone.critical : (alert != null ? BadgeTone.warning : BadgeTone.success));
    final variable = alert == null ? null : alertVariable(i18n, alert.parameterName);
    final device = alert == null ? null : summary.equipmentNames[alert.equipmentId];
    final label =
        overview == null ? _error(context, part.failure) : (open == 0 ? i18n.noOpenAlertsShort : i18n.openAlerts);
    final highlighted = tone == BadgeTone.critical || tone == BadgeTone.warning;
    return _HomeCard(
      onTap: () => context.go('/alerts'),
      color: critical > 0 ? tone.background : null,
      semanticLabel: [
        i18n.navAlerts,
        if (open != null) '$open $label' else label,
        if (critical > 0) i18n.criticalCount(critical),
        if (variable != null) '${i18n.mostUrgentAlert}: ${[variable, device].whereType<String>().join(', ')}',
      ].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.navAlerts, icon: Icons.report_problem_outlined, tone: tone),
        figure: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Figure(
              value: open == null ? '—' : '$open',
              label: label,
              color: highlighted ? tone.foreground : AppColors.textPrimary,
            ),
            if (critical > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(label: i18n.criticalCount(critical), tone: BadgeTone.critical),
            ],
          ],
        ),
        detail: [
          if (variable != null) ...[
            Text(
              variable,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(color: tone.foreground, fontWeight: FontWeight.w700),
            ),
            if (device != null) Text(device, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Telemetry: equipment and IoT devices
// ---------------------------------------------------------------------------

/// IoT devices connected, to review and without recent data.
class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final part = summary.equipment;
    final eq = part.value;
    final attention = eq == null ? 0 : eq.total - eq.operational;
    final segments =
        eq == null
            ? const <(int, Color, String)>[]
            : [
              (eq.connected, AppColors.successBase, i18n.connected),
              (eq.requiresReview, AppColors.warningBase, i18n.requiresReview),
              (eq.offline, AppColors.textMuted, i18n.noData),
            ];
    final label =
        eq == null ? _error(context, part.failure) : (eq.devices == 0 ? i18n.noIotDevices : i18n.iotDevicesOnline);
    final equipmentLine = '${i18n.navEquipment}: ${i18n.attentionCount(attention)}';
    return _HomeCard(
      onTap: () => context.go('/telemetry'),
      semanticLabel: [
        i18n.navTelemetry,
        if (eq != null && eq.devices > 0) i18n.iotOnline(eq.connected, eq.devices) else label,
        for (final (count, _, name) in segments.skip(1)) '$name: $count',
        if (attention > 0) equipmentLine,
      ].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.navTelemetry, icon: Icons.monitor_heart_outlined, tone: BadgeTone.neutral),
        figure: _Figure(value: eq == null || eq.devices == 0 ? '—' : '${eq.connected}/${eq.devices}', label: label),
        detail: [
          if (eq != null && eq.devices > 0) ..._breakdown(segments),
          if (attention > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(BadgeTone.warning.icon, size: 14, color: BadgeTone.warning.foreground),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    equipmentLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: BadgeTone.warning.foreground, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Production batches
// ---------------------------------------------------------------------------

/// Batches awaiting the QA decision, and every batch by status.
class _BatchesCard extends StatelessWidget {
  const _BatchesCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.batches;
    final s = part.value?.summary;
    final awaiting = s == null ? null : s.pending + s.inProgress;
    final segments =
        s == null
            ? const <(int, Color, String)>[]
            : [
              (s.pending, AppColors.warningBase, i18n.batchPending),
              (s.inProgress, AppColors.info, i18n.batchInProgress),
              (s.released, AppColors.successBase, i18n.batchReleased),
              (s.rejected, AppColors.criticalBase, i18n.batchRejected),
            ];
    final label = s == null ? _error(context, part.failure) : i18n.awaitingQaRelease;
    return _HomeCard(
      onTap: () => context.go('/batches'),
      semanticLabel: [
        i18n.navBatches,
        if (awaiting != null) '$awaiting $label' else label,
        for (final (count, _, name) in segments) '$name: $count',
      ].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.navBatches, icon: Icons.inventory_2_outlined, tone: BadgeTone.neutral),
        figure: _Figure(value: awaiting == null ? '—' : '$awaiting', label: label, color: AppColors.primaryDark),
        detail: s == null ? const [] : _breakdown(segments),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Inventory
// ---------------------------------------------------------------------------

/// Materials below the minimum stock, out of every material.
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.materials;
    final materials = part.value;
    final low = materials?.where((m) => m.isBelowMinimum).length;
    final tone = low == null ? BadgeTone.neutral : (low > 0 ? BadgeTone.warning : BadgeTone.success);
    final label = low == null ? _error(context, part.failure) : i18n.belowMinimum;
    final detail =
        materials == null ? null : (low == 0 ? i18n.stockAboveMinimum : i18n.materialsCount(materials.length));
    return _HomeCard(
      // Inventory is not a tab: it opens over Home, with its back arrow.
      onTap: () => context.push('/inventory'),
      semanticLabel: [i18n.moreInventory, if (low != null) '$low $label' else label, if (detail != null) detail].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.moreInventory, icon: Icons.science_outlined, tone: tone),
        figure: _Figure(
          value: low == null ? '—' : '$low',
          label: label,
          color: tone == BadgeTone.warning ? tone.foreground : AppColors.textPrimary,
        ),
        detail: [
          if (detail != null)
            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
