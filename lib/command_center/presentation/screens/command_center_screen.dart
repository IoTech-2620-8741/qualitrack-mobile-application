import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/domain/failure.dart';
import '../../../common/presentation/formatting/relative_time.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../iam/api/index.dart';
import '../../application/get_command_center_summary.dart';
import '../bloc/command_center_bloc.dart';
import '../command_center_views.dart';

/// Home panel shown after signing in (US: consult the control panel of the
/// laboratory).
///
/// The laboratory is the app bar title, with the user's role below it and how
/// long ago the figures were loaded on a third line. The body reads state, then
/// priority, then action:
/// - a strip with what the laboratory needs now (critical alerts, items to
///   review or all in order);
/// - four rows in order of importance (Report, Mobile Style Guidelines), each
///   with its figure, a short detail and a chevron to the screen that acts on
///   it: compliance alerts, IoT devices online, batches awaiting the QA
///   decision and materials below the minimum stock;
/// - the most urgent open alerts, in the rest of the screen.
/// An operator's panel keeps only the alerts and the batches in progress, and
/// an auditor's is marked read only (style guide §7).
/// The color of a state goes only to its icon and figure. The panel never
/// scrolls at the normal text size: on a short screen each row leaves out its
/// detail instead of shrinking. Only when the user's larger text does not fit
/// even then, the panel scrolls, so the text keeps the size the user chose.
/// Pull-to-refresh always works.
class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key, required this.session, required this.views});

  final UserSession session;
  final CommandCenterViews views;

  /// Height the body needs for the strip and the full rows at 100% text size;
  /// it grows with the user's text scale. Below it the rows are compact: they
  /// keep their figure and leave the detail to the screen they open.
  static const double fullHeight = 380;

  @override
  Widget build(BuildContext context) {
    void reload() => context.read<CommandCenterBloc>().add(const CommandCenterRequested(refresh: true));
    final forOperator = session.primaryRole == UserRole.labOperator;
    return Scaffold(
      appBar: AppBar(
        // Room for the three lines of the title: the Material 3 small app bar
        // height, grown with the title's text, which AppBar scales up to 1.34.
        toolbarHeight: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.34).scale(64),
        title: BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
          builder: (context, state) => _PanelTitle(session: session, views: views, summary: state.data),
        ),
        actions: [views.notificationBell, views.profileButton],
      ),
      body: BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
        builder:
            (context, state) => RemoteStateView<CommandCenterSummary>(
              state: state,
              onRetry: reload,
              // The shape of the panel while it loads, so nothing jumps when
              // the figures arrive.
              loading: const _PanelSkeleton(),
              builder:
                  (context, summary) => LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < MediaQuery.textScalerOf(context).scale(fullHeight);
                      return RefreshIndicator(
                        onRefresh: () async => reload(),
                        // The panel takes its own height and the most urgent
                        // alerts the rest of the screen, so nothing is
                        // stretched; only a panel taller than the screen
                        // (large text) scrolls.
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                              sliver: SliverToBoxAdapter(
                                child: _Panel(summary: summary, compact: compact, forOperator: forOperator),
                              ),
                            ),
                            SliverLayoutBuilder(
                              builder: (context, sliver) {
                                // Measured without the scroll offset, so it
                                // does not change while pulling to refresh.
                                final rest = sliver.viewportMainAxisExtent - sliver.precedingScrollExtent;
                                final fits = rest >= MediaQuery.textScalerOf(context).scale(_LatestAlerts.minHeight);
                                // With no open alerts (or none loaded) the
                                // alerts row already says so: the section is
                                // left out instead of repeating it.
                                final hasOpen = summary.alerts.value?.open.isNotEmpty ?? false;
                                return SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: rest > 0 ? rest : 0,
                                    child: fits && hasOpen ? _LatestAlerts(summary: summary, views: views) : null,
                                  ),
                                );
                              },
                            ),
                          ],
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

/// The laboratory as the title, the role below it (with "read only" after an
/// auditor's role) and "updated 2 min ago" on a line of its own, so neither is
/// cut on a narrow phone: a sober header for a compliance panel, which says how
/// current the figures are. The user is the avatar of the profile button.
class _PanelTitle extends StatefulWidget {
  const _PanelTitle({required this.session, required this.views, required this.summary});

  final UserSession session;
  final CommandCenterViews views;
  final CommandCenterSummary? summary;

  @override
  State<_PanelTitle> createState() => _PanelTitleState();
}

class _PanelTitleState extends State<_PanelTitle> {
  /// Rebuilds every minute so "updated 2 min ago" keeps counting between
  /// refreshes.
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final role = widget.session.primaryRole;
    final fetchedAt = widget.summary?.fetchedAt;
    final subtitle = [
      if (role != null) widget.views.roleLabel(role, i18n),
      if (widget.session.isAuditor) i18n.readOnly,
    ].join(' · ');
    return AppBarTitle(
      title: widget.summary?.laboratory.value?.name ?? i18n.navHome,
      subtitle: subtitle.isEmpty ? null : subtitle,
      caption: fetchedAt == null ? null : updatedText(context, fetchedAt),
    );
  }
}

/// The state of the laboratory in one line, and the rows to review in order of
/// importance: all four, or for an operator the open alerts and the batches in
/// progress.
class _Panel extends StatelessWidget {
  const _Panel({required this.summary, required this.compact, required this.forOperator});

  final CommandCenterSummary summary;
  final bool compact;
  final bool forOperator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusStrip(summary: summary, forOperator: forOperator),
      _gap,
      Material(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _AlertsRow(summary: summary, compact: compact),
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            if (forOperator)
              _BatchesRow(summary: summary, compact: compact, inProgressOnly: true)
            else ...[
              _TelemetryRow(summary: summary, compact: compact),
              const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _BatchesRow(summary: summary, compact: compact),
              const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              _InventoryRow(summary: summary, compact: compact),
            ],
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// What the laboratory needs now, read from the data (not a score): critical
/// alerts, anything else to review, or all in order. An operator's strip
/// counts only what their Home shows: open alerts and batches in progress.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.summary, required this.forOperator});

  final CommandCenterSummary summary;
  final bool forOperator;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final alerts = summary.alerts.value?.summary;
    final critical = alerts?.critical ?? 0;
    final equipment = summary.equipment.value;
    final batches = summary.batches.value?.summary;
    final pending = [
      alerts?.open ?? 0,
      batches?.inProgress ?? 0,
      if (!forOperator) ...[
        equipment == null ? 0 : equipment.devices - equipment.connected,
        batches?.pending ?? 0,
        summary.materials.value?.where((m) => m.isBelowMinimum).length ?? 0,
      ],
    ].any((count) => count > 0);
    final (tone, message) =
        critical > 0
            ? (BadgeTone.critical, critical == 1 ? i18n.homeStatusCriticalOne : i18n.homeStatusCritical(critical))
            : pending
            ? (BadgeTone.warning, i18n.homeStatusPending)
            : (BadgeTone.success, i18n.homeStatusAllClear);
    final urgent = critical > 0 ? summary.alerts.value?.byPriority.firstOrNull : null;
    final status = Row(
      children: [
        Icon(tone.icon, size: 20, color: tone.foreground),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: text.bodyMedium?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: AppRadius.lgAll,
          // With critical alerts the strip is the style guide's red banner, edged like Web's action banner.
          border:
              tone == BadgeTone.critical
                  ? Border(left: _bannerEdge.copyWith(width: 4), top: _bannerEdge, right: _bannerEdge, bottom: _bannerEdge)
                  : null,
        ),
        // "View detail" goes under the message, which keeps the whole width on a narrow phone.
        child:
            urgent == null
                ? status
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    status,
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tone.foreground,
                        side: BorderSide(color: tone.foreground),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      ),
                      onPressed: () => context.push('/alerts/${urgent.id}'),
                      child: Text(i18n.viewDetail, textAlign: TextAlign.center),
                    ),
                  ],
                ),
      ),
    );
  }

  static const _bannerEdge = BorderSide(color: AppColors.criticalBase);
}

/// One row of the panel: the section icon, its figure, what it counts, a
/// short detail (two lines at most, broken only between its parts; left out on
/// a short screen) and a chevron to open it.
///
/// The color of the tone goes only to the icon and the figure; a row with
/// nothing to review shows the success icon and "Nothing pending".
class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.tone,
    required this.figure,
    required this.label,
    required this.onTap,
    required this.compact,
    this.detail,
    this.badge,
  });

  final IconData icon;
  final BadgeTone tone;
  final String figure;
  final String label;
  final String? detail;
  final Widget? badge;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = tone == BadgeTone.brand ? AppColors.primaryDark : tone.foreground;
    final showDetail = !compact && detail != null && detail!.isNotEmpty;
    // A detail of several parts ("3 unresolved · 1 acknowledged") wraps only
    // between them: non-breaking spaces keep each part, and its separator, whole.
    final parts = detail?.split(' · ') ?? const <String>[];
    final shownDetail = parts.length < 2 ? detail : parts.map((part) => part.replaceAll(' ', ' ')).join(' · ');
    return Semantics(
      button: true,
      label: [figure, label, if (detail != null && detail!.isNotEmpty) detail].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 36, maxWidth: 96),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    // The style guide's H2 (18 sp), the size of a value, under the 22 sp screen title.
                    child: Text(figure, maxLines: 1, style: AppTypography.metric.copyWith(fontSize: 18, color: color)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
                      ),
                      if (showDetail)
                        Text(
                          shownDetail!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      if (badge != null) ...[const SizedBox(height: AppSpacing.xs), badge!],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1 · Compliance alerts
// ---------------------------------------------------------------------------

/// Open alerts by status, with the critical ones as a badge: severity and
/// status are told apart.
class _AlertsRow extends StatelessWidget {
  const _AlertsRow({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.alerts;
    final s = part.value?.summary;
    final open = s?.open;
    final critical = s?.critical ?? 0;
    final tone =
        s == null
            ? BadgeTone.neutral
            : (critical > 0 ? BadgeTone.critical : ((open ?? 0) > 0 ? BadgeTone.warning : BadgeTone.success));
    return _AttentionRow(
      icon: Icons.report_problem_outlined,
      tone: tone,
      figure: open == null ? '—' : '$open',
      label: s == null ? _error(context, part.failure) : (open == 0 ? i18n.noOpenAlertsShort : i18n.openAlerts),
      detail:
          s == null || open == 0
              ? null
              : s.acknowledged == 1
              ? i18n.homeAlertsDetailOneAcknowledged(s.unresolved)
              : i18n.homeAlertsDetail(s.unresolved, s.acknowledged),
      badge:
          critical > 0
              ? StatusBadge(
                label: critical == 1 ? i18n.criticalCountOne : i18n.criticalCount(critical),
                tone: BadgeTone.critical,
              )
              : null,
      compact: compact,
      onTap: () => context.go('/alerts'),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Telemetry: IoT devices
// ---------------------------------------------------------------------------

/// IoT devices online out of every device. The ones flagged for review and the
/// ones without data count together as to review, in grey.
class _TelemetryRow extends StatelessWidget {
  const _TelemetryRow({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.equipment;
    final eq = part.value;
    final none = eq == null || eq.devices == 0;
    final toReview = none ? 0 : eq.requiresReview + eq.offline;
    return _AttentionRow(
      icon: toReview > 0 ? Icons.signal_wifi_off : Icons.monitor_heart_outlined,
      tone: none || toReview > 0 ? BadgeTone.neutral : BadgeTone.success,
      figure: none ? '—' : '${eq.connected}/${eq.devices}',
      label: eq == null ? _error(context, part.failure) : (none ? i18n.noIotDevices : i18n.iotDevicesOnline),
      detail: none ? null : (toReview > 0 ? i18n.homeDevicesToReview(toReview) : i18n.homeNothingPending),
      compact: compact,
      onTap: () => context.go('/telemetry'),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Production batches
// ---------------------------------------------------------------------------

/// Batches awaiting the QA decision: pending and in progress. An operator sees
/// only the ones in progress.
class _BatchesRow extends StatelessWidget {
  const _BatchesRow({required this.summary, required this.compact, this.inProgressOnly = false});

  final CommandCenterSummary summary;
  final bool compact;
  final bool inProgressOnly;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.batches;
    final s = part.value?.summary;
    final awaiting = s == null ? null : (inProgressOnly ? s.inProgress : s.pending + s.inProgress);
    return _AttentionRow(
      icon: Icons.inventory_2_outlined,
      tone: s == null ? BadgeTone.neutral : (awaiting == 0 ? BadgeTone.success : BadgeTone.brand),
      figure: awaiting == null ? '—' : '$awaiting',
      label:
          s == null
              ? _error(context, part.failure)
              : (inProgressOnly ? i18n.homeBatchesInProgress : i18n.awaitingQaRelease),
      detail:
          s == null
              ? null
              : awaiting == 0
              ? i18n.homeNothingPending
              : inProgressOnly
              ? null
              : s.pending == 1
              ? i18n.homeBatchesDetailOnePending(s.inProgress)
              : i18n.homeBatchesDetail(s.pending, s.inProgress),
      compact: compact,
      onTap: () => context.go('/batches'),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Inventory
// ---------------------------------------------------------------------------

/// Materials below the minimum stock, out of every material.
class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.materials;
    final materials = part.value;
    final low = materials?.where((m) => m.isBelowMinimum).length;
    return _AttentionRow(
      icon: Icons.science_outlined,
      tone: low == null ? BadgeTone.neutral : (low > 0 ? BadgeTone.warning : BadgeTone.success),
      figure: low == null ? '—' : '$low',
      label: low == null ? _error(context, part.failure) : i18n.belowMinimum,
      detail:
          materials == null
              ? null
              : low == 0
              ? i18n.stockAboveMinimum
              : materials.length == 1
              ? i18n.homeMaterialsTotalOne
              : i18n.homeMaterialsTotal(materials.length),
      compact: compact,
      // Inventory is not a tab: it opens over Home, with its back arrow.
      onTap: () => context.push('/inventory'),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

/// Gray placeholders with the shape of the strip, the four rows and the most
/// urgent alerts, pulsing softly while the panel loads.
class _PanelSkeleton extends StatefulWidget {
  const _PanelSkeleton();

  @override
  State<_PanelSkeleton> createState() => _PanelSkeletonState();
}

class _PanelSkeletonState extends State<_PanelSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.5,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bone(double width, double height) => Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(color: AppColors.neutralContainer, borderRadius: AppRadius.smAll),
    );
    // One row of the panel: icon, figure, label and detail, as _AttentionRow.
    Widget row() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.neutralContainer, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          bone(36, 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bone(120, 12), const SizedBox(height: AppSpacing.xs), bone(88, 10)],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: context.i18n.loading,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _pulse,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // The status strip.
              Container(
                height: AppSpacing.minTouchTarget,
                decoration: const BoxDecoration(color: AppColors.neutralContainer, borderRadius: AppRadius.lgAll),
              ),
              _gap,
              // The four rows.
              DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.xlAll),
                child: Column(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      row(),
                    ],
                  ],
                ),
              ),
              _gap,
              // The most urgent alerts: their title and two cards.
              bone(96, 12),
              for (var i = 0; i < 2; i++) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 88,
                  decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lgAll),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Most urgent alerts, in the rest of the screen
// ---------------------------------------------------------------------------

/// The open alerts, most urgent first, as many as fit whole in the height the
/// rows leave (the same cards as the Alerts tab).
class _LatestAlerts extends StatelessWidget {
  const _LatestAlerts({required this.summary, required this.views});

  final CommandCenterSummary summary;
  final CommandCenterViews views;

  /// Alerts built at most; a phone never shows more.
  static const int _limit = 8;

  /// Height under which the section is left out: its title with the link
  /// (48dp touch target), its padding and room for a card.
  static const double minHeight = 160;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final text = Theme.of(context).textTheme;
    final open = summary.alerts.value?.byPriority ?? const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i18n.homeMostUrgent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(color: AppColors.navy),
                ),
              ),
              TextButton(onPressed: () => context.go('/alerts'), child: Text(i18n.viewAll)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _FitColumn(
              spacing: AppSpacing.sm,
              children: [
                for (final alert in open.take(_limit))
                  views.alertCard(
                    alert,
                    deviceName: summary.equipmentNames[alert.equipmentId],
                    environmentName: summary.environmentNames[alert.environmentId],
                    onTap: () => context.push('/alerts/${alert.id}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out its children top to bottom, [spacing] apart, and shows only the
/// ones that fit whole in its height: a card is never cut in half.
class _FitColumn extends MultiChildRenderObjectWidget {
  const _FitColumn({required super.children, this.spacing = 0});

  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFitColumn(spacing);

  @override
  void updateRenderObject(BuildContext context, _RenderFitColumn renderObject) => renderObject.spacing = spacing;
}

class _FitColumnParentData extends ContainerBoxParentData<RenderBox> {
  bool shown = false;
}

class _RenderFitColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitColumnParentData> {
  _RenderFitColumn(this._spacing);

  double _spacing;

  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FitColumnParentData) child.parentData = _FitColumnParentData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    var bottom = 0.0;
    var full = false;
    var index = 0;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FitColumnParentData;
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      final top = index == 0 ? 0.0 : bottom + _spacing;
      data.shown = !full && top + child.size.height <= constraints.maxHeight;
      if (data.shown) {
        data.offset = Offset(0, top);
        bottom = top + child.size.height;
      } else {
        full = true;
        data.offset = Offset.zero;
      }
      index++;
      child = data.nextSibling;
    }
    size = constraints.constrain(Size(width, bottom));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FitColumnParentData;
      if (data.shown) context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as _FitColumnParentData;
      final current = child;
      if (data.shown &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (result, transformed) => current.hitTest(result, position: transformed),
          )) {
        return true;
      }
      child = data.previousSibling;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FitColumnParentData;
      if (data.shown) visitor(child);
      child = data.nextSibling;
    }
  }
}
