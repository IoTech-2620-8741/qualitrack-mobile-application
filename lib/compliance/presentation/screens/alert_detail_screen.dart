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
      appBar: AppBar(title: Text(i18n.deviationDetails)),
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
              DetailRow(
                label: alert.origin == AlertOrigin.container ? i18n.containerMonitor : i18n.environmentalDevice,
                value: device,
                valueWidget: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => context.push('/equipment/${alert.equipmentId}'),
                  child: Text(device),
                ),
              ),
              if (alert.batchId != null)
                DetailRow(
                  label: i18n.batch,
                  value: i18n.batchNumberShort(alert.batchId!),
                  valueWidget: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => context.push('/batches/${alert.batchId}'),
                    child: Text(i18n.batchNumberShort(alert.batchId!)),
                  ),
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
        const SizedBox(height: AppSpacing.md),
        if (alert.status == AlertStatus.resolved || !canAttend)
          InfoCard(
            title: i18n.resolutionNotes,
            child: Text(alert.resolutionNotes?.isNotEmpty == true ? alert.resolutionNotes! : '—'),
          ),
        if (canAttend && alert.canResolve)
          _ReviewActions(alert: alert, submitting: submitting)
        else if (!canAttend && alert.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(i18n.auditorReadOnly, style: theme.textTheme.bodySmall),
          ),
      ],
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
          Text('$when · ${i18n.alertNumber(alert.id)}', style: text.bodySmall),
        ],
      ),
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

  Future<void> _resolve() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final i18n = context.i18n;
    final bloc = context.read<AlertDetailBloc>();
    final ok = await showConfirmDialog(
      context,
      title: i18n.markAsResolved,
      message: i18n.resolveConfirm,
      confirmLabel: i18n.markAsResolved,
    );
    if (ok) bloc.add(AlertResolveSubmitted(_notes.text));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final busy = widget.submitting;
    return InfoCard(
      title: i18n.reviewActions,
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
                labelText: i18n.resolutionNotes,
                hintText: i18n.resolutionNotesHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? i18n.resolutionNotesRequired : null,
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
                    label: Text(i18n.acknowledge),
                  ),
                FilledButton.icon(
                  key: const Key('alert.resolve'),
                  onPressed: busy ? null : _resolve,
                  icon: const Icon(Icons.task_alt),
                  label: Text(i18n.markAsResolved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
