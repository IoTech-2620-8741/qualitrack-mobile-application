import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/domain/failure.dart';
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
/// The greeting and the user's role · laboratory are the app bar title. The
/// body reads state, then priority, then action:
/// - a strip with what the laboratory needs now (critical alerts, items to
///   review or all in order) and when the data was read;
/// - four rows in order of importance (Report, Mobile Style Guidelines), each
///   with its figure, a short detail and a chevron to the screen that acts on
///   it: compliance alerts, IoT devices online, batches awaiting the QA
///   decision and materials below the minimum stock;
/// - the most urgent open alerts, in the rest of the screen.
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
                        // The panel takes its own height and the most urgent
                        // alerts the rest of the screen, so nothing is
                        // stretched; only a panel taller than the screen
                        // (large text) scrolls.
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
                                return SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: rest > 0 ? rest : 0,
                                    child: fits ? _LatestAlerts(summary: summary, views: views) : null,
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

/// The first word of a full name, or null if there is none.
String? _firstName(String? fullName) {
  final words = fullName?.trim().split(RegExp(r'\s+')) ?? const <String>[];
  return words.isEmpty || words.first.isEmpty ? null : words.first;
}

/// "Hello, {first name}" with "role · laboratory" below it, as the app bar
/// title; the full name stays in the profile.
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
      title: i18n.welcomeUser(_firstName(views.displayName()) ?? session.username),
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
  }
}

/// The state of the laboratory in one line, and the four rows to review in
/// order of importance.
class _Panel extends StatelessWidget {
  const _Panel({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusStrip(summary: summary),
      _gap,
      Material(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _AlertsRow(summary: summary, compact: compact),
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            _TelemetryRow(summary: summary, compact: compact),
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            _BatchesRow(summary: summary, compact: compact),
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            _InventoryRow(summary: summary, compact: compact),
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
/// alerts, anything else to review, or all in order; and when it was read.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.summary});

  final CommandCenterSummary summary;

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
      equipment == null ? 0 : equipment.devices - equipment.connected,
      batches == null ? 0 : batches.pending + batches.inProgress,
      summary.materials.value?.where((m) => m.isBelowMinimum).length ?? 0,
    ].any((count) => count > 0);
    final (tone, message) =
        critical > 0
            ? (BadgeTone.critical, i18n.homeStatusCritical(critical))
            : pending
            ? (BadgeTone.warning, i18n.homeStatusPending)
            : (BadgeTone.success, i18n.homeStatusAllClear);
    final loadedAt = summary.loadedAt;
    return Semantics(
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: tone.background, borderRadius: AppRadius.lgAll),
        child: Row(
          children: [
            Icon(tone.icon, size: 20, color: tone.foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
              ),
            ),
            if (loadedAt != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                i18n.homeUpdatedAt(TimeOfDay.fromDateTime(loadedAt).format(context)),
                style: text.bodySmall?.copyWith(color: tone.foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One row of the panel: the section icon, its figure, what it counts, a
/// short detail (left out on a short screen) and a chevron to open it.
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
    final highlighted = tone != BadgeTone.neutral && tone != BadgeTone.brand;
    final color = highlighted ? tone.foreground : AppColors.primaryDark;
    final showDetail = !compact && detail != null && detail!.isNotEmpty;
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
                  decoration: BoxDecoration(
                    color: highlighted ? tone.background : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, maxWidth: 96),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(figure, maxLines: 1, style: AppTypography.metric.copyWith(fontSize: 24, color: color)),
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
                          detail!,
                          maxLines: 1,
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
      detail: s == null || open == 0 ? null : i18n.homeAlertsDetail(s.unresolved, s.acknowledged),
      badge: critical > 0 ? StatusBadge(label: i18n.criticalCount(critical), tone: BadgeTone.critical) : null,
      compact: compact,
      onTap: () => context.go('/alerts'),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Telemetry: IoT devices
// ---------------------------------------------------------------------------

/// IoT devices online out of every device, and the ones to review or without
/// data.
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
    final tone = none ? BadgeTone.neutral : (eq.connected < eq.devices ? BadgeTone.warning : BadgeTone.success);
    final detail =
        none
            ? null
            : [
              if (eq.requiresReview > 0) i18n.homeDevicesToReview(eq.requiresReview),
              if (eq.offline > 0) i18n.homeDevicesNoData(eq.offline),
            ].join(' · ');
    return _AttentionRow(
      icon: Icons.monitor_heart_outlined,
      tone: tone,
      figure: none ? '—' : '${eq.connected}/${eq.devices}',
      label: eq == null ? _error(context, part.failure) : (none ? i18n.noIotDevices : i18n.iotDevicesOnline),
      detail: detail == null || detail.isEmpty ? (none ? null : i18n.homeNothingPending) : detail,
      compact: compact,
      onTap: () => context.go('/telemetry'),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Production batches
// ---------------------------------------------------------------------------

/// Batches awaiting the QA decision: pending and in progress.
class _BatchesRow extends StatelessWidget {
  const _BatchesRow({required this.summary, required this.compact});

  final CommandCenterSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final part = summary.batches;
    final s = part.value?.summary;
    final awaiting = s == null ? null : s.pending + s.inProgress;
    return _AttentionRow(
      icon: Icons.inventory_2_outlined,
      tone: s == null ? BadgeTone.neutral : (awaiting == 0 ? BadgeTone.success : BadgeTone.brand),
      figure: awaiting == null ? '—' : '$awaiting',
      label: s == null ? _error(context, part.failure) : i18n.awaitingQaRelease,
      detail: s == null ? null : (awaiting == 0 ? i18n.homeNothingPending : i18n.homeBatchesDetail(s.pending, s.inProgress)),
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
      detail: materials == null ? null : (low == 0 ? i18n.stockAboveMinimum : i18n.homeMaterialsTotal(materials.length)),
      compact: compact,
      // Inventory is not a tab: it opens over Home, with its back arrow.
      onTap: () => context.push('/inventory'),
    );
  }
}

// ---------------------------------------------------------------------------
// Most urgent alerts, in the rest of the screen
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
    final part = summary.alerts;
    final open = part.value?.byPriority ?? const [];
    final empty = part.isOk ? i18n.noOpenAlertsShort : _error(context, part.failure);
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
              if (open.isNotEmpty) TextButton(onPressed: () => context.go('/alerts'), child: Text(i18n.viewAll)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child:
                open.isEmpty
                    ? Text(empty, style: text.bodyMedium?.copyWith(color: AppColors.textMuted))
                    : _FitColumn(
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
