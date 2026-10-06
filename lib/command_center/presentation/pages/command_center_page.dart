import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../batch/presentation/widgets/batch_labels.dart';
import '../../../compliance/presentation/bloc/unread_notifications_controller.dart';
import '../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../compliance/presentation/widgets/notification_bell.dart';
import '../../../iam/domain/user_session.dart';
import '../../../iam/presentation/widgets/role_labels.dart';
import '../../../profile/presentation/bloc/current_profile_controller.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../application/get_command_center_summary.dart';
import '../bloc/command_center_bloc.dart';

/// Panel shown after signing in (US: consult the control panel of the
/// laboratory), with the same cards as the Web dashboard.
class CommandCenterPage extends StatelessWidget {
  const CommandCenterPage({
    super.key,
    required this.session,
    required this.currentProfile,
    required this.notifications,
  });

  final UserSession session;
  final CurrentProfileController currentProfile;
  final UnreadNotificationsController notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<CommandCenterBloc>().add(const CommandCenterRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          NotificationBell(controller: notifications),
          IconButton(tooltip: l10n.refresh, onPressed: reload, icon: const Icon(Icons.refresh)),
          ListenableBuilder(
            listenable: currentProfile,
            builder: (context, _) => IconButton(
              tooltip: l10n.profile,
              onPressed: () => context.push('/profile'),
              icon: ProfileAvatar(
                radius: 16,
                photo: currentProfile.photo,
                initials: currentProfile.profile?.initials ??
                    (session.username.isEmpty ? '?' : session.username[0].toUpperCase()),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CommandCenterBloc, RemoteState<CommandCenterSummary>>(
        builder: (context, state) => RemoteStateView<CommandCenterSummary>(
          state: state,
          onRetry: reload,
          builder: (context, summary) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                ListenableBuilder(
                  listenable: currentProfile,
                  builder: (context, _) => _Hero(
                    session: session,
                    name: currentProfile.profile?.displayName ?? session.username,
                    summary: summary,
                  ),
                ),
                SectionHeader(title: l10n.keyOperationalMetrics),
                _Metrics(summary: summary),
                SectionHeader(title: l10n.openAlerts, subtitle: l10n.openAlertsHint),
                _OpenAlerts(summary: summary),
                SectionHeader(title: l10n.liveTelemetry, subtitle: l10n.liveTelemetryHint),
                _TelemetryCard(summary: summary),
                SectionHeader(title: l10n.recentBatches),
                _RecentBatches(summary: summary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _error(BuildContext context, Failure? failure) =>
    failure == null ? '' : failureMessage(context, failure).split('\n').first;

class _Hero extends StatelessWidget {
  const _Hero({required this.session, required this.name, required this.summary});

  final UserSession session;
  final String name;
  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final lab = summary.laboratory.value;
    final alerts = summary.alerts.value;
    final billing = summary.subscription;
    final active = billing?.value?.active;
    const light = TextStyle(color: Colors.white70, fontSize: 12);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.xlAll,
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeUser(name),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [session.primaryRole?.label(l10n), lab?.name].whereType<String>().join(' · '),
            style: light,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (alerts != null)
                StatusBadge(
                  label: alerts.summary.critical > 0
                      ? l10n.criticalAlertsCount(alerts.summary.critical)
                      : l10n.noCriticalAlerts,
                  tone: alerts.summary.critical > 0 ? BadgeTone.critical : BadgeTone.success,
                ),
              if (billing != null && billing.isOk)
                StatusBadge(
                  label: active == null
                      ? l10n.noActiveSubscription
                      : '${l10n.plan}: ${billing.value!.plan?.name ?? active.planCode} · ${l10n.until(Formatters.date(active.currentPeriodEnd, locale))}',
                  tone: active == null ? BadgeTone.warning : BadgeTone.brand,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary});

  final CommandCenterSummary summary;

  String _value<T>(Part<T> part, String Function(T value) read) =>
      part.isOk && part.value != null ? read(part.value as T) : '—';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eq = summary.equipment;
    final batches = summary.batches;
    final alerts = summary.alerts;
    final materials = summary.materials;
    final lowStock = materials.value?.where((m) => m.isBelowMinimum).length;
    return ResponsiveGrid(
      children: [
        MetricTile(
          label: l10n.equipmentTitle,
          value: _value(eq, (v) => '${v.total}'),
          caption: eq.isOk ? l10n.operationalCount(eq.value!.operational) : _error(context, eq.failure),
          icon: Icons.precision_manufacturing_outlined,
          color: AppColors.info,
          onTap: () => context.push('/equipment'),
        ),
        MetricTile(
          label: l10n.batchesInProgress,
          value: _value(batches, (v) => '${v.summary.inProgress}'),
          caption: batches.isOk ? l10n.pendingCount(batches.value!.summary.pending) : _error(context, batches.failure),
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
          onTap: () => context.go('/batches'),
        ),
        MetricTile(
          label: l10n.openAlerts,
          value: _value(alerts, (v) => '${v.summary.open}'),
          caption: alerts.isOk ? l10n.criticalCount(alerts.value!.summary.critical) : _error(context, alerts.failure),
          icon: Icons.notifications_active_outlined,
          color: AppColors.critical,
          onTap: () => context.go('/alerts'),
        ),
        MetricTile(
          label: l10n.lowStock,
          value: lowStock == null ? '—' : '$lowStock',
          caption: materials.isOk ? l10n.materialsCount(materials.value!.length) : _error(context, materials.failure),
          icon: Icons.science_outlined,
          color: AppColors.warning,
          onTap: () => context.push('/inventory'),
        ),
      ],
    );
  }
}

class _OpenAlerts extends StatelessWidget {
  const _OpenAlerts({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final part = summary.alerts;
    if (!part.isOk) return InfoCard(child: Text(failureMessage(context, part.failure!)));
    final open = part.value!.open;
    if (open.isEmpty) return InfoCard(child: Text(l10n.noOpenAlerts));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final alert in open.take(3)) ...[
          AlertCard(
            alert: alert,
            environmentName: summary.environmentNames[alert.environmentId],
            onTap: () => context.push('/alerts/${alert.id}'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (open.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => context.go('/alerts'), child: Text(l10n.viewAll)),
          ),
      ],
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eq = summary.equipment;
    if (!eq.isOk) return InfoCard(child: Text(failureMessage(context, eq.failure!)));
    final snapshot = eq.value!;
    final review = snapshot.requiresReview;
    final tone = snapshot.devices == 0
        ? BadgeTone.neutral
        : (review > 0 ? BadgeTone.warning : BadgeTone.success);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/telemetry'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi_tethering, color: tone.foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      snapshot.devices == 0
                          ? l10n.telemetryNoDevices
                          : l10n.connectedOfTotal(snapshot.connected, snapshot.devices),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: l10n.iotDevices, value: snapshot.devices)),
                  Expanded(child: _MiniStat(label: l10n.connected, value: snapshot.connected)),
                  Expanded(child: _MiniStat(label: l10n.requiresReview, value: review, alert: review > 0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.alert = false});

  final String label;
  final int value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.metric.copyWith(fontSize: 22, color: alert ? AppColors.critical : AppColors.textPrimary),
          ),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentBatches extends StatelessWidget {
  const _RecentBatches({required this.summary});

  final CommandCenterSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final part = summary.batches;
    if (!part.isOk) return InfoCard(child: Text(failureMessage(context, part.failure!)));
    final recent = part.value!.recent;
    if (recent.isEmpty) return InfoCard(child: Text(l10n.batchesEmpty));
    return Card(
      child: Column(
        children: [
          for (final batch in recent)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              title: Text(batch.batchNumber),
              subtitle: Text(batch.productName ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: BatchStatusBadge(status: batch.status),
              onTap: () => context.push('/batches/${batch.id}'),
            ),
        ],
      ),
    );
  }
}
