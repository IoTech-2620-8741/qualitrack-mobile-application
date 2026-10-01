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
import '../../domain/compliance.dart';
import '../bloc/alert_detail_bloc.dart';
import '../widgets/alert_widgets.dart';

/// "Deviation Details" mockup. Review actions are shown only to QA Managers
/// and Admins ([canReview]); the backend validates every transition.
class AlertDetailPage extends StatelessWidget {
  const AlertDetailPage({super.key, required this.canReview});

  final bool canReview;

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
            equipmentName: state.equipmentName,
            canReview: canReview,
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
    required this.equipmentName,
    required this.canReview,
    required this.submitting,
  });

  final DeviationAlert alert;
  final String? equipmentName;
  final bool canReview;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                alert.severity.tone.icon,
                color: alert.severity.tone.foreground,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(alert.parameterName, style: theme.textTheme.titleLarge),
                    ),
                    Text(
                      alert.timestamp != null
                          ? Formatters.dateTime(alert.timestamp, locale)
                          : (alert.rawTimestamp ?? '—'),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(l10n.alertNumber(alert.id), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                valueWidget: StatusBadge(
                  label: alert.status.label(l10n),
                  tone: alert.status.tone,
                  icon: alert.status.icon,
                ),
              ),
              KeyValue(
                label: l10n.recordedValue,
                value: formatAlertValue(alert.recordedValue, alert.unit, locale),
              ),
              KeyValue(
                label: l10n.thresholdValue,
                value: formatAlertValue(alert.thresholdValue, alert.unit, locale),
              ),
              KeyValue(
                label: l10n.equipment,
                value: equipmentName ?? l10n.equipmentNumber(alert.equipmentId),
                valueWidget: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => context.push('/equipment/${alert.equipmentId}'),
                  child: Text(equipmentName ?? l10n.equipmentNumber(alert.equipmentId)),
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
                KeyValue(label: l10n.acknowledgedBy, value: l10n.userNumber(alert.acknowledgedBy!)),
              if (alert.resolvedBy != null)
                KeyValue(label: l10n.resolvedBy, value: l10n.userNumber(alert.resolvedBy!)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (alert.status == AlertStatus.resolved || !canReview)
          InfoCard(
            title: l10n.resolutionNotes,
            child: Text(
              alert.resolutionNotes?.isNotEmpty == true ? alert.resolutionNotes! : '—',
            ),
          ),
        if (canReview && alert.canResolve)
          _ReviewActions(alert: alert, submitting: submitting)
        else if (!canReview && alert.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(l10n.reviewRestricted, style: theme.textTheme.bodySmall),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.resolutionNotesRequired : null,
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
