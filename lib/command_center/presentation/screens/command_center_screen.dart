import 'dart:async';
import 'dart:math' as math;

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
import '../../../compliance/api/index.dart';
import '../../../iam/api/index.dart';
import '../../application/get_command_center_summary.dart';
import '../bloc/command_center_bloc.dart';
import '../command_center_views.dart';
import '../widgets/home_alert_card.dart';
import '../widgets/proportion_bar.dart';

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
/// A button of the app bar switches between this list and a dashboard, as the
/// user prefers: the figures as tiles two per row, with no strip (the open
/// alerts tile turns red instead), over the unresolved alerts as reading cards
/// and the acknowledged ones as one-line rows.
/// The color of a state goes only to its icon and figure. When the whole panel
/// does not fit the screen, each row leaves out its detail instead of
/// shrinking. Only when the user's larger text does not fit even then, the
/// panel scrolls, so the text keeps the size the user chose.
/// Pull-to-refresh always works.
class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key, required this.session, required this.views, required this.layout});

  final UserSession session;
  final CommandCenterViews views;
  final ValueNotifier<HomeLayout> layout;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: layout,
    builder: (context, chosen, _) => _home(context, cards: chosen == HomeLayout.cards),
  );

  Widget _home(BuildContext context, {required bool cards}) {
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Out of the app bar, whose width the title needs on a small phone.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SegmentedButton<HomeLayout>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: HomeLayout.list,
                    icon: const Icon(Icons.view_agenda_outlined),
                    label: Text(context.i18n.homeLayoutList),
                  ),
                  ButtonSegment(
                    value: HomeLayout.cards,
                    icon: const Icon(Icons.grid_view_outlined),
                    label: Text(context.i18n.homeLayoutDashboard),
                  ),
                ],
                selected: {layout.value},
                onSelectionChanged: (selection) => layout.value = selection.single,
              ),
            ),
          ),
          Expanded(child: _content(cards: cards, forOperator: forOperator, reload: reload)),
        ],
      ),
    );
  }

  Widget _content({required bool cards, required bool forOperator, required VoidCallback reload}) =>
      BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
        builder:
            (context, state) => RemoteStateView<CommandCenterSummary>(
              state: state,
              onRetry: reload,
              // The shape of the panel while it loads, so nothing jumps when
              // the figures arrive.
              loading: _PanelSkeleton(dashboard: cards),
              builder:
                  (context, summary) => LayoutBuilder(
                    builder: (context, constraints) {
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
                                child: _FittedPanel(
                                  summary: summary,
                                  forOperator: forOperator,
                                  cards: cards,
                                  // The body under the top padding.
                                  maxHeight: constraints.maxHeight - AppSpacing.lg,
                                ),
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
                                    child:
                                        fits && hasOpen
                                            ? _LatestAlerts(summary: summary, views: views, dashboard: cards)
                                            : null,
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
      );
}

/// How the Home lays out its figures: the list of rows or the dashboard.
enum HomeLayout { list, cards }

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

/// The panel whole when it fits [maxHeight], or with compact rows when it does
/// not. Whether it fits depends on the width, the language and the text size,
/// so the whole panel is laid out offstage and measured, not assumed. The
/// dashboard's tiles are compact also when that leaves under them the room of
/// the most urgent alerts, which the style guide puts on Home.
class _FittedPanel extends StatefulWidget {
  const _FittedPanel({required this.summary, required this.forOperator, required this.cards, required this.maxHeight});

  final CommandCenterSummary summary;
  final bool forOperator;
  final bool cards;
  final double maxHeight;

  @override
  State<_FittedPanel> createState() => _FittedPanelState();
}

class _FittedPanelState extends State<_FittedPanel> {
  final _whole = GlobalKey();
  final _compact = GlobalKey();

  /// Heights of the whole and the compact panel at the last layout; unknown
  /// before the first.
  double? _wholeHeight;
  double? _compactHeight;

  @override
  Widget build(BuildContext context) {
    // A layout cannot rebuild the tree: the heights are read after the frame,
    // and a change shows on the next one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final whole = _whole.currentContext?.size?.height;
      final compact = _compact.currentContext?.size?.height;
      if (mounted && (whole != _wholeHeight || compact != _compactHeight)) {
        setState(() {
          _wholeHeight = whole;
          _compactHeight = compact;
        });
      }
    });
    final whole = _Panel(summary: widget.summary, compact: false, forOperator: widget.forOperator, cards: widget.cards);
    final compact =
        _Panel(summary: widget.summary, compact: true, forOperator: widget.forOperator, cards: widget.cards);
    final makeRoom = widget.cards && (widget.summary.alerts.value?.open.isNotEmpty ?? false);
    // The height that leaves the most urgent alerts their minimum under the panel.
    final aboveAlerts = widget.maxHeight - MediaQuery.textScalerOf(context).scale(_LatestAlerts.minHeight);
    final wholeHeight = _wholeHeight ?? 0;
    final useCompact =
        wholeHeight > widget.maxHeight ||
        (makeRoom && wholeHeight > aboveAlerts && (_compactHeight ?? double.infinity) <= aboveAlerts);
    return Stack(
      children: [
        Offstage(child: ExcludeFocus(child: KeyedSubtree(key: _whole, child: whole))),
        if (makeRoom) Offstage(child: ExcludeFocus(child: KeyedSubtree(key: _compact, child: compact))),
        if (useCompact) compact else whole,
      ],
    );
  }
}

/// The state of the laboratory in one line, and the rows to review in order of
/// importance: all four, or for an operator the open alerts and the batches in
/// progress. As [cards], the same figures as the dashboard's tiles, two per
/// row and each pair as tall as its taller tile, with no strip.
class _Panel extends StatelessWidget {
  const _Panel({required this.summary, required this.compact, required this.forOperator, required this.cards});

  final CommandCenterSummary summary;
  final bool compact;
  final bool forOperator;
  final bool cards;

  @override
  Widget build(BuildContext context) => cards ? _tiles() : _list();

  Widget _tiles() {
    Widget pair(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: left), const SizedBox(width: AppSpacing.sm), Expanded(child: right)],
      ),
    );
    final alerts = _AlertsRow(summary: summary, compact: compact, tile: true);
    if (forOperator) {
      return pair(alerts, _BatchesRow(summary: summary, compact: compact, inProgressOnly: true, tile: true));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pair(alerts, _TelemetryRow(summary: summary, compact: compact, tile: true)),
        const SizedBox(height: AppSpacing.sm),
        pair(
          _BatchesRow(summary: summary, compact: compact, tile: true),
          _InventoryRow(summary: summary, compact: compact, tile: true),
        ),
      ],
    );
  }

  Widget _list() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusStrip(summary: summary, forOperator: forOperator),
      _gap,
      Material(
        color: AppColors.surface,
        elevation: 1,
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
/// counts only the open alerts: their batches in progress are daily work.
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
      if (!forOperator) ...[
        batches?.inProgress ?? 0,
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
    // The count keeps its noun ("1 critical alert"): a message in two lines breaks after its colon.
    final parts = message.split(': ');
    final shownMessage = [parts.first, ...parts.skip(1).map((part) => part.replaceAll(' ', '\u00a0'))].join(': ');
    final icon = Icon(tone.icon, size: 20, color: tone.foreground);
    final label = Text(
      shownMessage,
      style: text.bodyMedium?.copyWith(color: tone.foreground, fontWeight: FontWeight.w600),
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
                  ? Border(
                    left: _bannerEdge.copyWith(width: 4),
                    top: _bannerEdge,
                    right: _bannerEdge,
                    bottom: _bannerEdge,
                  )
                  : null,
        ),
        child:
            urgent == null
                ? Row(children: [icon, const SizedBox(width: AppSpacing.sm), Expanded(child: label)])
                : _BannerLayout(
                  icon: icon,
                  message: label,
                  action: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tone.foreground,
                      side: BorderSide(color: tone.foreground),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    onPressed: () => context.push('/alerts/${urgent.id}'),
                    child: Text(i18n.viewDetail, textAlign: TextAlign.center),
                  ),
                ),
      ),
    );
  }

  static const _bannerEdge = BorderSide(color: AppColors.criticalBase);
}

/// One row of the panel: the section icon, its figure, what it counts, a
/// short detail (two lines at most, broken only between its parts) over the
/// share of its parts as a thin bar, both left out on a short screen, and a
/// chevron to open it. As a [tile] of the dashboard: what it counts on top,
/// then the figure beside the icon and the detail, with no bar nor chevron;
/// a critical tile is red.
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
    this.total,
    this.detail,
    this.segments = const [],
    this.tile = false,
  });

  final IconData icon;
  final BadgeTone tone;
  final String figure;

  /// What the figure counts out of ("/3"), smaller after it, so it does not
  /// outweigh the other figures nor crowd its label.
  final int? total;
  final String label;
  final String? detail;

  /// The count and the color of each part of the figure, for its bar.
  final List<(int, Color)> segments;
  final VoidCallback onTap;
  final bool compact;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = tone == BadgeTone.brand ? AppColors.primaryDark : tone.foreground;
    // A critical tile is red: its fill, its border and its text.
    final alarming = tile && tone == BadgeTone.critical;
    final showDetail = !compact && detail != null && detail!.isNotEmpty;
    // A detail of several parts ("3 unresolved · 1 acknowledged") wraps only
    // between them: non-breaking spaces keep each part, and its separator, whole.
    final parts = detail?.split(' · ') ?? const <String>[];
    final shownDetail =
        parts.length < 2 ? detail : parts.map((part) => part.replaceAll(' ', '\u00a0')).join('\u00a0· ');
    final figureStyle = AppTypography.metric.copyWith(fontSize: 22, color: color);
    final badge = Container(
      width: tile ? 32 : 36,
      height: tile ? 32 : 36,
      decoration: BoxDecoration(color: alarming ? AppColors.surface : tone.background, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
    final figureText = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      // 22 sp, the top of the style guide's scale, so the figures are read and compared
      // first; the total in its body size (14 sp).
      child: Text.rich(
        TextSpan(
          text: figure,
          children: [
            if (total != null)
              TextSpan(text: '/$total', style: figureStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        maxLines: 1,
        style: figureStyle,
      ),
    );
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: text.bodyMedium?.copyWith(
        color: alarming ? AppColors.critical : AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
    );
    final detailText =
        showDetail
            ? Text(
              shownDetail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: alarming ? AppColors.critical : AppColors.textMuted),
            )
            : null;
    return Semantics(
      button: true,
      label: [
        // "6 of 9" in words: a screen reader may read "6/9" as a date or a fraction.
        total == null ? figure : '$figure ${context.i18n.ofTotal(total!)}',
        label,
        if (detail != null && detail!.isNotEmpty) detail,
      ].join(', '),
      excludeSemantics: true,
      child:
          tile
              ? Card(
                color: alarming ? AppColors.criticalContainer : null,
                shape:
                    alarming
                        ? const RoundedRectangleBorder(
                          borderRadius: AppRadius.xlAll,
                          side: BorderSide(color: AppColors.criticalBase),
                        )
                        : null,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The label on top, whole: beside the icon, a long word
                        // would break on a narrow phone with a larger text.
                        labelText,
                        const SizedBox(height: AppSpacing.xs),
                        Row(children: [Expanded(child: figureText), const SizedBox(width: AppSpacing.sm), badge]),
                        if (detailText != null) ...[const SizedBox(height: AppSpacing.xs), detailText],
                      ],
                    ),
                  ),
                ),
              )
              : InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        badge,
                        const SizedBox(width: AppSpacing.md),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 36, maxWidth: 96),
                          child: figureText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              labelText,
                              if (detailText != null) detailText,
                              if (!compact && segments.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                ProportionBar(segments: segments, height: 4),
                              ],
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

/// Open alerts by status. Their severity is the red banner's: the critical
/// ones are not counted again here. The dashboard has no banner, so its tile
/// counts the critical ones and the acknowledged ones instead.
class _AlertsRow extends StatelessWidget {
  const _AlertsRow({required this.summary, required this.compact, this.tile = false});

  final CommandCenterSummary summary;
  final bool compact;
  final bool tile;

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
              : tile && critical > 0
              ? [
                critical == 1 ? i18n.criticalCountOne : i18n.criticalCount(critical),
                if (s.acknowledged > 0)
                  s.acknowledged == 1 ? i18n.homeAcknowledgedCountOne : i18n.homeAcknowledgedCount(s.acknowledged),
              ].join(' · ')
              : s.acknowledged == 1
              ? i18n.homeAlertsDetailOneAcknowledged(s.unresolved)
              : i18n.homeAlertsDetail(s.unresolved, s.acknowledged),
      segments:
          s == null || open == 0
              ? const []
              : [(s.unresolved, AppColors.criticalBase), (s.acknowledged, AppColors.neutralContainer)],
      compact: compact,
      tile: tile,
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
  const _TelemetryRow({required this.summary, required this.compact, this.tile = false});

  final CommandCenterSummary summary;
  final bool compact;
  final bool tile;

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
      figure: none ? '—' : '${eq.connected}',
      total: none ? null : eq.devices,
      label: eq == null ? _error(context, part.failure) : (none ? i18n.noIotDevices : i18n.iotDevicesOnline),
      detail: none ? null : (toReview > 0 ? i18n.homeDevicesToReview(toReview) : i18n.homeNothingPending),
      segments:
          none
              ? const []
              : [
                (eq.connected, AppColors.successBase),
                (eq.requiresReview, AppColors.warningBase),
                (eq.offline, AppColors.neutralContainer),
              ],
      compact: compact,
      tile: tile,
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
  const _BatchesRow({required this.summary, required this.compact, this.inProgressOnly = false, this.tile = false});

  final CommandCenterSummary summary;
  final bool compact;
  final bool inProgressOnly;
  final bool tile;

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
      segments:
          s == null ? const [] : [(awaiting!, AppColors.primary), (s.total - awaiting, AppColors.neutralContainer)],
      compact: compact,
      tile: tile,
      onTap: () => context.go('/batches'),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Inventory
// ---------------------------------------------------------------------------

/// Materials below the minimum stock, out of every material.
class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.summary, required this.compact, this.tile = false});

  final CommandCenterSummary summary;
  final bool compact;
  final bool tile;

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
      segments:
          materials == null || low == null
              ? const []
              : [(low, AppColors.warningBase), (materials.length - low, AppColors.successBase)],
      compact: compact,
      tile: tile,
      // Inventory is not a tab: it opens over Home, with its back arrow.
      onTap: () => context.push('/inventory'),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

/// Gray placeholders with the shape of the strip, the four rows (or the
/// dashboard's four tiles) and the most urgent alerts, pulsing softly while
/// the panel loads.
class _PanelSkeleton extends StatefulWidget {
  const _PanelSkeleton({this.dashboard = false});

  final bool dashboard;

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
    // One tile of the dashboard: label, figure and icon, as _AttentionRow's tile.
    Widget tile() => Expanded(
      child: Card(
        key: const ValueKey('tile-bone'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bone(96, 12),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  bone(36, 22),
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppColors.neutralContainer, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              bone(72, 10),
            ],
          ),
        ),
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
              if (widget.dashboard) ...[
                // The four tiles, two per row.
                Row(children: [tile(), const SizedBox(width: AppSpacing.sm), tile()]),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [tile(), const SizedBox(width: AppSpacing.sm), tile()]),
              ] else ...[
                // The status strip.
                Container(
                  height: AppSpacing.minTouchTarget,
                  decoration: const BoxDecoration(color: AppColors.neutralContainer, borderRadius: AppRadius.lgAll),
                ),
                _gap,
                // The four rows.
                Material(
                  color: AppColors.surface,
                  elevation: 1,
                  borderRadius: AppRadius.xlAll,
                  child: Column(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                        row(),
                      ],
                    ],
                  ),
                ),
              ],
              _gap,
              // The most urgent alerts: their title and two cards.
              bone(96, 12),
              for (var i = 0; i < 2; i++) ...[
                const SizedBox(height: AppSpacing.sm),
                const Material(
                  color: AppColors.surface,
                  elevation: 1,
                  borderRadius: AppRadius.lgAll,
                  child: SizedBox(height: 88),
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
/// rows leave (the same cards as the Alerts tab). On the [dashboard], the
/// unresolved ones as reading cards, then the acknowledged ones, which someone
/// is already on, as one-line rows.
class _LatestAlerts extends StatelessWidget {
  const _LatestAlerts({required this.summary, required this.views, required this.dashboard});

  final CommandCenterSummary summary;
  final CommandCenterViews views;
  final bool dashboard;

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
    bool acknowledged(DeviationAlert alert) => alert.status == AlertStatus.acknowledged;
    final shown = dashboard ? [...open.where((a) => !acknowledged(a)), ...open.where(acknowledged)] : open;
    final title = Row(
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
    );
    final cards = [
      for (final alert in shown.take(_limit))
        if (!dashboard)
          views.alertCard(
            alert,
            deviceName: summary.equipmentNames[alert.equipmentId],
            environmentName: summary.environmentNames[alert.environmentId],
            threshold: summary.alerts.value?.thresholds[alert.id],
            onTap: () => context.push('/alerts/${alert.id}'),
          )
        else if (acknowledged(alert))
          HomeAcknowledgedAlertRow(alert: alert, onTap: () => context.push('/alerts/${alert.id}'))
        else
          HomeAlertCard(
            alert: alert,
            deviceName: summary.equipmentNames[alert.equipmentId],
            threshold: summary.alerts.value?.thresholds[alert.id],
            onTap: () => context.push('/alerts/${alert.id}'),
          ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      // The title goes with the first alert: where that alert does not fit,
      // the title is left out with it instead of standing over nothing.
      child: _FitColumn(
        spacing: AppSpacing.sm,
        children: [
          for (final (index, card) in cards.indexed)
            index > 0
                ? card
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: AppSpacing.xs), card],
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

/// The critical banner: its icon and message with the action beside them while
/// the message takes two lines at most there, or under them, at their end, on a
/// narrower phone or with a larger text.
class _BannerLayout extends MultiChildRenderObjectWidget {
  _BannerLayout({required Widget icon, required Widget message, required Widget action})
    : super(children: [icon, message, action]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBannerLayout();
}

class _BannerParentData extends ContainerBoxParentData<RenderBox> {}

// shortcut: the action goes on the right only, as the app has no right-to-left language; mirror it to add one.
class _RenderBannerLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BannerParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BannerParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BannerParentData) child.parentData = _BannerParentData();
  }

  @override
  void performLayout() {
    final layout = _arrange(constraints, ChildLayoutHelper.layoutChild);
    _place(firstChild!, layout.icon);
    _place(childAfter(firstChild!)!, layout.message);
    _place(lastChild!, layout.action);
    size = layout.size;
  }

  void _place(RenderBox child, Offset offset) => (child.parentData! as _BannerParentData).offset = offset;

  /// Where the icon, the message and the action go under [constraints], with the
  /// children laid out for real or dry by [layoutChild].
  ({Size size, Offset icon, Offset message, Offset action, BoxConstraints messageConstraints}) _arrange(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final icon = firstChild!;
    final message = childAfter(icon)!;
    final action = lastChild!;
    // Unbounded, the banner is as wide as everything on one line.
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : getMaxIntrinsicWidth(double.infinity);
    final iconSize = layoutChild(icon, constraints.loosen());
    final actionSize = layoutChild(action, constraints.loosen());
    final indent = iconSize.width + AppSpacing.sm;
    // The message's own line, not the icon's 20 dp: a smaller text has shorter lines.
    final oneLine = message.getMinIntrinsicHeight(double.infinity);
    final besideWidth = math.max(0.0, width - indent - AppSpacing.sm - actionSize.width);
    var messageConstraints = BoxConstraints.tightFor(width: besideWidth);
    var messageSize = layoutChild(message, messageConstraints);
    // Two lines at most beside the action, with half a line of slack for rounding.
    final beside = messageSize.height < 2.5 * oneLine;
    if (!beside) {
      messageConstraints = BoxConstraints.tightFor(width: math.max(0.0, width - indent));
      messageSize = layoutChild(message, messageConstraints);
    }
    // The icon and the message are centred on each other, as in the strip without an action.
    final textHeight = math.max(iconSize.height, messageSize.height);
    final height = beside ? math.max(textHeight, actionSize.height) : textHeight + actionSize.height;
    final top = beside ? (height - textHeight) / 2 : 0.0;
    return (
      size: constraints.constrain(Size(width, height)),
      icon: Offset(0, top + (textHeight - iconSize.height) / 2),
      message: Offset(indent, top + (textHeight - messageSize.height) / 2),
      action: Offset(width - actionSize.width, beside ? (height - actionSize.height) / 2 : textHeight),
      messageConstraints: messageConstraints,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _arrange(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final layout = _arrange(constraints, ChildLayoutHelper.dryLayoutChild);
    final distance = childAfter(firstChild!)!.getDryBaseline(layout.messageConstraints, baseline);
    return distance == null ? null : distance + layout.message.dy;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final message = childAfter(firstChild!)!;
    final distance = message.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance + (message.parentData! as _BannerParentData).offset.dy;
  }

  // Narrowest: the action under the message. Widest: everything on one line.
  @override
  double computeMinIntrinsicWidth(double height) {
    final icon = firstChild!;
    final message = childAfter(icon)!;
    final text = icon.getMinIntrinsicWidth(height) + AppSpacing.sm + message.getMinIntrinsicWidth(height);
    return math.max(text, lastChild!.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final icon = firstChild!;
    final message = childAfter(icon)!;
    final text = icon.getMaxIntrinsicWidth(height) + AppSpacing.sm + message.getMaxIntrinsicWidth(height);
    return text + AppSpacing.sm + lastChild!.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _arrange(BoxConstraints(maxWidth: width), ChildLayoutHelper.dryLayoutChild).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
