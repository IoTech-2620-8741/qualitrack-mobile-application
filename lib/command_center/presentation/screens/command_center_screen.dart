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
/// The laboratory is the app bar title, with the user's role and how long ago
/// the figures were loaded below it. The body shows four cards, two per row, in order of importance read top to
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
                        // The cards take their own height and the latest
                        // alerts the rest of the screen, so nothing is
                        // stretched; only cards taller than the screen (large
                        // text) scroll.
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                              sliver: SliverToBoxAdapter(child: _Panel(summary: summary, compact: compact)),
                            ),
                            SliverLayoutBuilder(
                              builder: (context, sliver) {
                                // Measured without the scroll offset, so it
                                // does not change while pulling to refresh.
                                final rest = sliver.viewportMainAxisExtent - sliver.precedingScrollExtent;
                                final fits = rest >= MediaQuery.textScalerOf(context).scale(_LatestAlerts.minHeight);
                                // With no open alerts (or none loaded) the
                                // alerts card already says so: the section is
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

/// The laboratory as the title and "role · updated 2 min ago" below it: a
/// sober header for a compliance panel, which says how current the figures
/// are. The user is the avatar of the profile button.
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
      if (fetchedAt != null) updatedText(context, fetchedAt),
    ].join(' · ');
    return AppBarTitle(
      title: widget.summary?.laboratory.value?.name ?? i18n.navHome,
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
    // Both cards of a row are as tall as the taller one.
    Widget row(Widget start, Widget end) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: start), _gap, Expanded(child: end)],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(_AlertCard(summary: summary, compact: compact), _TelemetryCard(summary: summary, compact: compact)),
        _gap,
        row(_BatchesCard(summary: summary, compact: compact), _InventoryCard(summary: summary, compact: compact)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// Home card: white with 16dp corners, ripple + press scale. Every card has
/// the same surface; the state shows in its icon, figure and context line.
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, required this.onTap, required this.semanticLabel});

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => PressableCard(
    onTap: onTap,
    color: AppColors.surface,
    borderRadius: AppRadius.xlAll,
    semanticLabel: semanticLabel,
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}

/// Tonal round icon + title, and a chevron that says the card opens a screen.
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
        const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      ],
    );
  }
}

/// The figure that matters in a card: a big number and, below it, what it
/// counts. The figure is neutral unless it needs attention ([color]).
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
      const SizedBox(height: AppSpacing.md),
      figure,
      if (!compact && detail.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), ...detail],
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
          height: 6,
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

/// The detail of a card: the bar of [segments] and one line of context
/// instead of a full legend, which the screen the card opens already gives.
/// [attention] marks the line as needing attention (warning tone and icon).
List<Widget> _detail(BuildContext context, List<(int, Color)> segments, String? line, {bool attention = false}) {
  final text = Theme.of(context).textTheme.bodySmall;
  return [
    if (segments.isNotEmpty) _StatusBar(segments: segments),
    if (line != null) ...[
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          if (attention) ...[
            Icon(BadgeTone.warning.icon, size: 14, color: BadgeTone.warning.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: attention ? text?.copyWith(color: BadgeTone.warning.foreground, fontWeight: FontWeight.w600) : text,
            ),
          ),
        ],
      ),
    ],
  ];
}

// ---------------------------------------------------------------------------
// 1 · Compliance alerts
// ---------------------------------------------------------------------------

/// Open alerts and how many are critical; the latest ones are listed below
/// the cards.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.alerts;
    final overview = part.value;
    final open = overview?.summary.open;
    final critical = overview?.summary.critical ?? 0;
    final unresolved = overview?.summary.unresolved ?? 0;
    final tone =
        overview == null
            ? BadgeTone.neutral
            : (critical > 0 ? BadgeTone.critical : ((open ?? 0) > 0 ? BadgeTone.warning : BadgeTone.success));
    final label =
        overview == null ? _error(context, part.failure) : (open == 0 ? i18n.noOpenAlertsShort : i18n.openAlerts);
    final highlighted = tone == BadgeTone.critical || tone == BadgeTone.warning;
    final line = unresolved > 0 ? i18n.unattendedCount(unresolved) : null;
    return _HomeCard(
      onTap: () => context.go('/alerts'),
      semanticLabel: [
        i18n.navAlerts,
        if (open != null) '$open $label' else label,
        if (critical > 0) i18n.criticalCount(critical),
        if (line != null) line,
      ].join(', '),
      child: _CardBody(
        compact: compact,
        detail:
            (open ?? 0) > 0
                ? _detail(context, [
                  (unresolved, AppColors.criticalBase),
                  (overview!.summary.acknowledged, AppColors.neutralContainer),
                ], line)
                : const [],
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Telemetry: equipment and IoT devices
// ---------------------------------------------------------------------------

/// IoT devices connected, and how many need attention.
class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.equipment;
    final eq = part.value;
    final hasDevices = eq != null && eq.devices > 0;
    // Devices to review or without recent data; failing that, equipment out
    // of operation.
    final devicesAttention = eq == null ? 0 : eq.requiresReview + eq.offline;
    final equipmentAttention = eq == null ? 0 : eq.total - eq.operational;
    final tone = !hasDevices ? BadgeTone.neutral : (devicesAttention > 0 ? BadgeTone.warning : BadgeTone.success);
    final label = eq == null ? _error(context, part.failure) : (hasDevices ? i18n.iotDevicesOnline : i18n.noIotDevices);
    final String? line;
    if (devicesAttention > 0) {
      line = i18n.attentionCount(devicesAttention);
    } else if (equipmentAttention > 0) {
      line = '${i18n.navEquipment}: ${i18n.attentionCount(equipmentAttention)}';
    } else {
      line = hasDevices ? i18n.allDevicesOnline : null;
    }
    return _HomeCard(
      onTap: () => context.go('/telemetry'),
      semanticLabel: [
        i18n.navTelemetry,
        if (hasDevices) i18n.iotOnline(eq.connected, eq.devices) else label,
        if (line != null) line,
      ].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.navTelemetry, icon: Icons.monitor_heart_outlined, tone: tone),
        figure: _Figure(
          value: hasDevices ? '${eq.connected}/${eq.devices}' : '—',
          label: label,
          color: tone == BadgeTone.warning ? tone.foreground : AppColors.textPrimary,
        ),
        detail:
            eq == null
                ? const []
                : _detail(
                  context,
                  hasDevices
                      ? [
                        (eq.connected, AppColors.successBase),
                        (eq.requiresReview, AppColors.warningBase),
                        (eq.offline, AppColors.neutralContainer),
                      ]
                      : const [],
                  line,
                  attention: devicesAttention > 0 || equipmentAttention > 0,
                ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Production batches
// ---------------------------------------------------------------------------

/// Batches awaiting the QA decision, out of every batch.
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
    final label = s == null ? _error(context, part.failure) : i18n.awaitingQaRelease;
    final line = s == null ? null : i18n.ofTotalBatches(s.total);
    return _HomeCard(
      onTap: () => context.go('/batches'),
      semanticLabel: [i18n.navBatches, if (awaiting != null) '$awaiting $label' else label, if (line != null) line].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.navBatches, icon: Icons.inventory_2_outlined, tone: BadgeTone.neutral),
        // Batches awaiting QA are work to do, not an alarm: a neutral figure.
        figure: _Figure(value: awaiting == null ? '—' : '$awaiting', label: label),
        detail:
            s == null
                ? const []
                : _detail(context, [
                  (awaiting!, AppColors.primary),
                  (s.total - awaiting, AppColors.neutralContainer),
                ], line),
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
    final line = materials == null ? null : i18n.ofTotalMaterials(materials.length);
    return _HomeCard(
      // Inventory is not a tab: it opens over Home, with its back arrow.
      onTap: () => context.push('/inventory'),
      semanticLabel: [i18n.moreInventory, if (low != null) '$low $label' else label, if (line != null) line].join(', '),
      child: _CardBody(
        compact: compact,
        header: _CardHeader(title: i18n.moreInventory, icon: Icons.science_outlined, tone: tone),
        figure: _Figure(
          value: low == null ? '—' : '$low',
          label: label,
          color: tone == BadgeTone.warning ? tone.foreground : AppColors.textPrimary,
        ),
        detail:
            materials == null || low == null
                ? const []
                : _detail(context, [
                  (low, AppColors.warningBase),
                  (materials.length - low, AppColors.successBase),
                ], line),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

/// Gray placeholders with the shape of the four cards, pulsing softly while
/// the panel loads.
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
    Widget card() => DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: AppColors.neutralContainer, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                bone(64, 12),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            bone(48, 28),
            const SizedBox(height: AppSpacing.xs),
            bone(96, 10),
            const SizedBox(height: AppSpacing.md),
            bone(double.infinity, 6),
            const SizedBox(height: AppSpacing.xs),
            bone(72, 10),
          ],
        ),
      ),
    );
    Widget row() => Row(children: [Expanded(child: card()), _gap, Expanded(child: card())]);
    return Semantics(
      label: context.i18n.loading,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _pulse,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [row(), _gap, row()],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Latest alerts, in the rest of the screen
// ---------------------------------------------------------------------------

/// The open alerts, most urgent first, as many as fit whole in the height the
/// cards leave (the same cards as the Alerts tab).
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
                  i18n.latestAlerts,
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
