import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/confirm_dialog.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../../tracking/presentation/widgets/telemetry_labels.dart';
import '../../domain/compliance.dart';
import '../bloc/alert_detail_bloc.dart';
import '../widgets/alert_widgets.dart';

/// "Deviation Details" mockup. Operators and quality managers attend and
/// resolve alerts ([canAttend]); auditors only read. The backend validates
/// every transition.
class AlertDetailPage extends StatelessWidget {
  const AlertDetailPage({super.key, required this.canAttend, required this.currentUserId});

  final bool canAttend;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviationDetails)),
      body: BlocConsumer<AlertDetailBloc, AlertDetailState>(
        listenWhen: (a, b) => a.actionStatus != b.actionStatus,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.actionStatus == ReviewActionStatus.success) {
            messenger.showSnackBar(SnackBar(
              content: Text(
                state.lastAction == AlertReviewAction.acknowledge
                    ? l10n.alertAcknowledgedMessage
                    : l10n.alertResolvedMessage,
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
          builder: (context, alert) => _AlertDetailBody(
            alert: alert,
            names: state.context,
            canAttend: canAttend,
            currentUserId: currentUserId,
            submitting: state.submitting,
          ),
        ),
      ),
    );
  }
}

class _AlertDetailBody extends StatelessWidget {
  const _AlertDetailBody({
    required this.alert,
    required this.names,
    required this.canAttend,
    required this.currentUserId,
    required this.submitting,
  });

  final DeviationAlert alert;
  final AlertContext names;
  final bool canAttend;
  final int? currentUserId;
  final bool submitting;

  String _person(AppLocalizations l10n, int id) =>
      id == currentUserId ? l10n.you : (names.people[id] ?? l10n.userNumber(id));

  String _who(AppLocalizations l10n, String locale, int? userId, DateTime? at) {
    final person = userId == null ? '—' : _person(l10n, userId);
    return at == null ? person : '$person · ${Formatters.dateTime(at, locale)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final device = names.deviceName ?? l10n.equipmentNumber(alert.equipmentId);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(alert.severity.tone.icon, color: alert.severity.tone.foreground, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(alertVariable(l10n, alert.parameterName), style: theme.textTheme.titleLarge),
                    ),
                    Text(
                      Formatters.dateTime(alert.lastDetectedAt ?? alert.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(l10n.alertNumber(alert.id), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (alert.normalizedAt != null && alert.isOpen) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            color: AppColors.successContainer,
            borderColor: AppColors.success.withValues(alpha: 0.3),
            child: Text(l10n.conditionNormalized(Formatters.dateTime(alert.normalizedAt, locale))),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.technicalInspection,
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              KeyValue(
                label: l10n.severity,
                value: alert.severity.label(l10n),
                valueWidget: StatusBadge(label: alert.severity.label(l10n), tone: alert.severity.tone),
              ),
              KeyValue(
                label: l10n.status,
                value: alert.status.label(l10n),
                valueWidget: StatusBadge(label: alert.status.label(l10n), tone: alert.status.tone, icon: alert.status.icon),
              ),
              KeyValue(label: l10n.recordedValue, value: formatAlertValue(alert.recordedValue, alert.unit, locale)),
              KeyValue(label: l10n.thresholdValue, value: formatAlertValue(alert.thresholdValue, alert.unit, locale)),
              KeyValue(label: l10n.deviationsLabel, value: '${alert.deviationCount}'),
              KeyValue(label: l10n.firstDetected, value: Formatters.dateTime(alert.timestamp, locale)),
              if (names.environmentName != null) KeyValue(label: l10n.environment, value: names.environmentName!),
              KeyValue(
                label: alert.origin == AlertOrigin.container ? l10n.containerMonitor : l10n.environmentalDevice,
                value: device,
                valueWidget: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => context.push('/equipment/${alert.equipmentId}'),
                  child: Text(device),
                ),
              ),
              if (alert.batchId != null)
                KeyValue(
                  label: l10n.batch,
                  value: l10n.batchNumberShort(alert.batchId!),
                  valueWidget: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => context.push('/batches/${alert.batchId}'),
                    child: Text(l10n.batchNumberShort(alert.batchId!)),
                  ),
                ),
              if (alert.acknowledgedBy != null)
                KeyValue(
                  label: l10n.acknowledgedBy,
                  value: _who(l10n, locale, alert.acknowledgedBy, alert.acknowledgedAt),
                ),
              if (alert.resolvedBy != null)
                KeyValue(label: l10n.resolvedBy, value: _who(l10n, locale, alert.resolvedBy, alert.resolvedAt)),
            ],
          ),
        ),
        if (alert.relatedActuations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: l10n.automaticActions,
            child: Column(
              children: [
                for (final action in alert.relatedActuations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_remote_outlined, color: AppColors.primary),
                    title: Text(actuationLabel(l10n, action.action)),
                    subtitle: Text(Formatters.dateTime(action.occurredAt, locale)),
                    trailing: StatusBadge(
                      label: action.result == 'EXECUTED' ? l10n.actionExecuted : l10n.actionFailed,
                      tone: action.result == 'EXECUTED' ? BadgeTone.success : BadgeTone.critical,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (alert.status == AlertStatus.resolved || !canAttend)
          InfoCard(
            title: l10n.resolutionNotes,
            child: Text(alert.resolutionNotes?.isNotEmpty == true ? alert.resolutionNotes! : '—'),
          ),
        if (canAttend && alert.canResolve)
          _ReviewActions(alert: alert, submitting: submitting)
        else if (!canAttend && alert.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(l10n.auditorReadOnly, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _ReviewActions extends StatefulWidget {
  const _ReviewActions({required this.alert, required this.submitting});

  final DeviationAlert alert;
  final bool submitting;

  @override
  State<_ReviewActions> createState() => _ReviewActionsState();
}

class _ReviewActionsState extends State<_ReviewActions> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _acknowledge() async {
    final l10n = context.l10n;
    final bloc = context.read<AlertDetailBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.acknowledgeAlert,
      message: l10n.acknowledgeConfirm,
      confirmLabel: l10n.acknowledge,
    );
    if (ok) bloc.add(const AlertAcknowledgeSubmitted());
  }

  Future<void> _resolve() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final bloc = context.read<AlertDetailBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.markAsResolved,
      message: l10n.resolveConfirm,
      confirmLabel: l10n.markAsResolved,
    );
    if (ok) bloc.add(AlertResolveSubmitted(_notes.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = widget.submitting;
    return InfoCard(
      title: l10n.reviewActions,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('alert.resolutionNotes'),
              controller: _notes,
              enabled: !busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: l10n.resolutionNotes,
                hintText: l10n.resolutionNotesHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.resolutionNotesRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            if (busy) const LinearProgressIndicator(),
            if (busy) const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (widget.alert.canAcknowledge)
                  OutlinedButton.icon(
                    key: const Key('alert.acknowledge'),
                    onPressed: busy ? null : _acknowledge,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.acknowledge),
                  ),
                FilledButton.icon(
                  key: const Key('alert.resolve'),
                  onPressed: busy ? null : _resolve,
                  icon: const Icon(Icons.task_alt),
                  label: Text(l10n.markAsResolved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
