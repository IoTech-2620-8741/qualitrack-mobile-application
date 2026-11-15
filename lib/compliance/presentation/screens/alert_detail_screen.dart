import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/labels.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/confirm_dialog.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/alert_origin.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/deviation_alert.dart';
import '../bloc/alert_detail_bloc.dart';
import '../widgets/alert_resolution_sheet.dart';
import '../widgets/alert_widgets.dart';

/// "Deviation Details" mockup. Operators and quality managers attend and
/// resolve alerts ([canAttend]); auditors only read. The backend validates
/// every transition.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.canAttend, required this.currentUserId});

  final bool canAttend;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
            appBar: AppBar(
        title: BlocBuilder<AlertDetailBloc, AlertDetailState>(
          builder: (context, state) {
            final alert = state.alert.data;
            return AppBarTitle(
              title: i18n.deviationDetails,
              subtitle: alert == null ? null : i18n.alertNumber(alert.id),
            );
          },
        ),
      ),
      // Acknowledge / resolve stay at hand at the bottom, as in the batch
      // detail, instead of at the end of the scroll.
      bottomNavigationBar: BlocBuilder<AlertDetailBloc, AlertDetailState>(
        builder: (context, state) {
          final alert = state.alert.data;
          if (!canAttend || alert == null || !alert.canResolve) return const SizedBox.shrink();
          return _ReviewBar(alert: alert, submitting: state.submitting);
        },
      ),
      body: BlocConsumer<AlertDetailBloc, AlertDetailState>(
        listenWhen: (a, b) => a.actionStatus != b.actionStatus,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.actionStatus == ReviewActionStatus.success) {
            messenger.showSnackBar(SnackBar(
              content: Text(
                state.lastAction == AlertReviewAction.acknowledge
                    ? i18n.alertAcknowledgedMessage
                    : i18n.alertResolvedMessage,
              ),
            ));
          } else if (state.actionStatus == ReviewActionStatus.failure && state.actionFailure != null) {
            messenger.showSnackBar(SnackBar(
              backgroundColor: AppColors.critical,
              content: Text(failureMessage(context, state.actionFailure!)),
            ));
          }
        },
        builder: (context, state) => RemoteStateView<DeviationAlert>(
          state: state.alert,
          onRetry: () => context.read<AlertDetailBloc>().add(const AlertDetailRequested()),
          onRefresh: () => context.read<AlertDetailBloc>().add(const AlertDetailRequested()),
          builder: (context, alert) => _AlertDetailBody(
            alert: alert,
            names: state.context,
            canAttend: canAttend,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }
}

class _AlertDetailBody extends StatelessWidget {
  const _AlertDetailBody({required this.alert, required this.names, required this.canAttend, required this.currentUserId});

  final DeviationAlert alert;
  final AlertContext names;
  final bool canAttend;
  final int? currentUserId;

  String _person(AppLocalizations i18n, int id) =>
      id == currentUserId ? i18n.you : (names.people[id] ?? i18n.userNumber(id));

  String _who(AppLocalizations i18n, String locale, int? userId, DateTime? at) {
    final person = userId == null ? '—' : _person(i18n, userId);
    return at == null ? person : '$person · ${Formatters.dateTime(at, locale)}';
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final device = names.deviceName ?? i18n.equipmentNumber(alert.equipmentId);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _AlertHeader(alert: alert, device: device, environment: names.environmentName),
        if (alert.normalizedAt != null && alert.isOpen) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            color: AppColors.successContainer,
            borderColor: AppColors.success.withValues(alpha: 0.3),
            child: Text(i18n.conditionNormalized(Formatters.dateTime(alert.normalizedAt, locale))),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: i18n.technicalInspection,
          child: DetailList(
            children: [
              DetailRow(label: i18n.deviationsLabel, value: '${alert.deviationCount}'),
              DetailRow(label: i18n.firstDetected, value: Formatters.dateTime(alert.timestamp, locale)),
              if (names.environmentName != null) DetailRow(label: i18n.environment, value: names.environmentName!),
              _LinkRow(
                key: const Key('alert.deviceLink'),
                label: alert.origin == AlertOrigin.container ? i18n.containerMonitor : i18n.environmentalDevice,
                value: device,
                onTap: () => context.push('/equipment/${alert.equipmentId}'),
              ),
              if (alert.batchId != null)
              _LinkRow(
                  key: const Key('alert.batchLink'),
                  label: i18n.batch,
                  value: i18n.batchNumberShort(alert.batchId!),
                  onTap: () => context.push('/batches/${alert.batchId}'),
                ),
              if (alert.acknowledgedBy != null)
                DetailRow(
                  label: i18n.acknowledgedBy,
                  value: _who(i18n, locale, alert.acknowledgedBy, alert.acknowledgedAt),
                ),
              if (alert.resolvedBy != null)
                DetailRow(label: i18n.resolvedBy, value: _who(i18n, locale, alert.resolvedBy, alert.resolvedAt)),
            ],
          ),
        ),
        if (alert.relatedActuations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: i18n.automaticActions,
            child: Column(
              children: [
                for (final action in alert.relatedActuations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_remote_outlined, color: AppColors.primary),
                    title: Text(actuationLabel(i18n, action.action)),
                    subtitle: Text(Formatters.dateTime(action.occurredAt, locale)),
                    trailing: StatusBadge(
                      label: action.result == 'EXECUTED' ? i18n.actionExecuted : i18n.actionFailed,
                      tone: action.result == 'EXECUTED' ? BadgeTone.success : BadgeTone.critical,
                    ),
                  ),
              ],
            ),
          ),
        ],
        // An open alert has no notes yet: an empty "—" card would only add
        // noise, so the card shows up once there is something to read.
        if (alert.status == AlertStatus.resolved || alert.resolutionNotes?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: i18n.resolutionNotes,
            child: Text(alert.resolutionNotes?.isNotEmpty == true ? alert.resolutionNotes! : '—'),
          ),
        ],
        if (!canAttend && alert.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(i18n.auditorReadOnly, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// A detail row that opens another record: the value in the brand colour and
/// a chevron, the whole row as the touch target (Material 3 list item).
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DetailRow(
          label: label,
          value: value,
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: text.bodyLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}


/// Most important first (top to bottom, left to right): severity and status,
/// the variable, the recorded value against its threshold, then where and when.
class _AlertHeader extends StatelessWidget {
  const _AlertHeader({required this.alert, required this.device, required this.environment});

  final DeviationAlert alert;
  final String device;
  final String? environment;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final text = Theme.of(context).textTheme;
    final tone = alert.severity.tone;
    final where = [device, environment].whereType<String>().join(' · ');
    final when = Formatters.dateTime(alert.lastDetectedAt ?? alert.timestamp, locale);
    return InfoCard(
      color: alert.isOpen ? tone.background : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(label: alert.severity.label(i18n), tone: tone),
              StatusBadge(label: alert.status.label(i18n), tone: alert.status.tone, icon: alert.status.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(alertVariable(i18n, alert.parameterName), style: text.titleLarge),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              Text(
                formatAlertValue(alert.recordedValue, alert.unit, locale),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: alert.isOpen ? tone.foreground : AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${i18n.thresholdValue}: ${formatAlertValue(alert.thresholdValue, alert.unit, locale)}',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(where, style: text.bodySmall),
          Text(when, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _ReviewBar extends StatelessWidget {
  const _ReviewBar({required this.alert, required this.submitting});

  final DeviationAlert alert;
  final bool submitting;

  Future<void> _acknowledge(BuildContext context) async {
    final i18n = context.i18n;
    final bloc = context.read<AlertDetailBloc>();
    final ok = await showConfirmDialog(
      context,
      title: i18n.acknowledgeAlert,
      message: i18n.acknowledgeConfirm,
      confirmLabel: i18n.acknowledge,
    );
    if (ok) bloc.add(const AlertAcknowledgeSubmitted());
  }

  Future<void> _resolve(BuildContext context) async {
    final bloc = context.read<AlertDetailBloc>();
    final notes = await showAlertResolutionSheet(context, alert: alert);
    if (notes != null) bloc.add(AlertResolveSubmitted(notes));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submitting) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  if (alert.canAcknowledge) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('alert.acknowledge'),
                        onPressed: submitting ? null : () => _acknowledge(context),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(i18n.acknowledge),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('alert.resolve'),
                      onPressed: submitting ? null : () => _resolve(context),
                      icon: const Icon(Icons.task_alt),
                      label: Text(i18n.markAsResolved),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
