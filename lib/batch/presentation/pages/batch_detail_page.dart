import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/section.dart';
import '../../domain/batch.dart';
import '../bloc/batch_detail_bloc.dart';
import '../widgets/batch_labels.dart';
import '../widgets/batch_review_sheet.dart';

/// Batch detail with its traceability. Only quality managers release or
/// reject a batch ([canReview]); the backend validates the decision.
class BatchDetailPage extends StatelessWidget {
  const BatchDetailPage({super.key, required this.canReview, required this.currentUserId});

  final bool canReview;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.batchDetail),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.generalInformation),
              Tab(text: l10n.traceability),
              Tab(text: l10n.history),
            ],
          ),
        ),
        body: BlocConsumer<BatchDetailBloc, BatchDetailState>(
          listenWhen: (a, b) => a.actionStatus != b.actionStatus,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state.actionStatus == BatchActionStatus.success) {
              messenger.showSnackBar(SnackBar(
                content: Text(
                  state.lastAction == BatchReviewAction.release ? l10n.batchReleasedMessage : l10n.batchRejectedMessage,
                ),
              ));
            } else if (state.actionStatus == BatchActionStatus.failure && state.actionFailure != null) {
              messenger.showSnackBar(SnackBar(
                backgroundColor: AppColors.critical,
                content: Text(failureMessage(context, state.actionFailure!)),
              ));
            }
          },
          builder: (context, state) => RemoteStateView<BatchDetail>(
            state: state.detail,
            onRetry: () => context.read<BatchDetailBloc>().add(const BatchDetailRequested()),
            builder: (context, detail) {
              Future<void> refresh() async => context.read<BatchDetailBloc>().add(const BatchDetailRequested(refresh: true));
              String person(int userId) => userId == currentUserId
                  ? l10n.you
                  : (detail.people[userId] ?? l10n.userNumber(userId));
              return TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: refresh,
                    child: _GeneralTab(
                      detail: detail,
                      canReview: canReview,
                      submitting: state.submitting,
                      person: person,
                    ),
                  ),
                  RefreshIndicator(onRefresh: refresh, child: _TraceabilityTab(traceability: detail.traceability)),
                  RefreshIndicator(onRefresh: refresh, child: _HistoryTab(detail: detail, person: person)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.detail, required this.canReview, required this.submitting, required this.person});

  final BatchDetail detail;
  final bool canReview;
  final bool submitting;
  final String Function(int userId) person;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final bloc = context.read<BatchDetailBloc>();
    final batch = detail.batch;
    final release = detail.traceability.release;
    final rejection = detail.traceability.rejection;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(title: batch.batchNumber, subtitle: batch.productName, trailing: BatchStatusBadge(status: batch.status)),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              KeyValue(
                label: l10n.product,
                value: [detail.traceability.productCode, batch.productName].whereType<String>().join(' · '),
              ),
              KeyValue(
                label: l10n.status,
                value: batch.status.label(l10n),
                valueWidget: BatchStatusBadge(status: batch.status),
              ),
              KeyValue(
                label: l10n.quantity,
                value: '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim(),
              ),
              KeyValue(label: l10n.startDate, value: Formatters.rawDate(batch.startDate, locale)),
              KeyValue(label: l10n.endDate, value: Formatters.rawDate(batch.endDate, locale)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.bpmNotes,
          child: Text(
            batch.notes?.isNotEmpty == true ? batch.notes! : '—',
            style: const TextStyle(fontFamily: AppTypography.monospace),
          ),
        ),
        if (release != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: l10n.digitalSignature,
            color: AppColors.successContainer,
            borderColor: AppColors.success.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValue(label: l10n.signedBy, value: person(release.signedByUserId)),
                const SizedBox(height: AppSpacing.sm),
                KeyValue(label: l10n.signedAt, value: Formatters.dateTime(release.signedAt, locale)),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.signatureHash, style: Theme.of(context).textTheme.bodySmall),
                SelectableText(
                  release.signatureHash,
                  style: const TextStyle(fontFamily: AppTypography.monospace, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        if (rejection != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: l10n.rejectionReason,
            color: AppColors.criticalContainer,
            borderColor: AppColors.critical.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rejection.reason),
                const SizedBox(height: AppSpacing.xs),
                Text(Formatters.rawDate(rejection.rejectionDate, locale), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (canReview && batch.isAwaitingReview)
          InfoCard(
            title: l10n.qaReview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.qaReviewHint, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                if (submitting) ...[const LinearProgressIndicator(), const SizedBox(height: AppSpacing.md)],
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('batch.reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                      onPressed: submitting
                          ? null
                          : () async {
                              final result = await showBatchReviewSheet(context, batch: batch, action: BatchReviewAction.reject);
                              if (result != null) bloc.add(BatchRejectSubmitted(date: result.date, reason: result.text));
                            },
                      icon: const Icon(Icons.block_outlined),
                      label: Text(l10n.rejectBatch),
                    ),
                    FilledButton.icon(
                      key: const Key('batch.release'),
                      onPressed: submitting
                          ? null
                          : () async {
                              final result = await showBatchReviewSheet(context, batch: batch, action: BatchReviewAction.release);
                              if (result != null) bloc.add(BatchReleaseSubmitted(date: result.date, notes: result.text));
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(l10n.releaseBatch),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (!canReview && batch.isAwaitingReview)
          Text(l10n.reviewRestricted, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TraceabilityTab extends StatelessWidget {
  const _TraceabilityTab({required this.traceability});

  final BatchTraceability traceability;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final container = traceability.container;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard<RawMaterialUsage>(
          title: l10n.rawMaterialsUsed,
          section: Section(traceability.rawMaterials),
          emptyMessage: l10n.rawMaterialsUsedEmpty,
          itemBuilder: (context, u) => SectionRow(
            leading: const Icon(Icons.science_outlined, color: AppColors.primary),
            title: u.rawMaterialName ?? l10n.materialNumber(u.rawMaterialId),
            subtitle: [
              Formatters.dateTime(u.usageDate, locale),
              if (u.stockBefore != null || u.stockAfter != null)
                l10n.stockBeforeAfter(Formatters.number(u.stockBefore, locale), Formatters.number(u.stockAfter, locale)),
              if (u.inventoryReceiptId != null) l10n.receiptNumber(u.inventoryReceiptId!),
            ].join(' · '),
            trailing: Text(
              '${Formatters.number(u.quantityUsed, locale)} ${u.unit ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<BatchEquipmentUsage>(
          title: l10n.equipmentUsed,
          section: Section(traceability.equipment),
          emptyMessage: l10n.noEquipmentUsed,
          itemBuilder: (context, e) => SectionRow(
            leading: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.primary),
            title: e.equipmentName,
            subtitle: Formatters.dateTime(e.registeredAt, locale),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<BatchStaffParticipation>(
          title: l10n.participatingStaff,
          section: Section(traceability.staff),
          emptyMessage: l10n.noParticipatingStaff,
          itemBuilder: (context, s) => SectionRow(
            leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
            title: s.staffName,
            subtitle: [s.staffRole, Formatters.dateTime(s.registeredAt, locale)].whereType<String>().join(' · '),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.container,
          child: container == null
              ? Text(l10n.noContainerAssigned)
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.kitchen_outlined, color: AppColors.primary),
                  title: Text(container.containerName ?? l10n.equipmentNumber(container.containerMonitorId)),
                  subtitle: Text(Formatters.dateTime(container.assignedAt, locale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/telemetry/history?deviceId=${container.containerMonitorId}'),
                ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.detail, required this.person});

  final BatchDetail detail;
  final String Function(int userId) person;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard<AuditLogEntry>(
          title: l10n.auditLog,
          section: detail.auditLogs,
          maxItems: 20,
          itemBuilder: (context, log) => SectionRow(
            title: Formatters.humanize(log.action),
            subtitle: [log.details, if (log.performedBy != null) person(log.performedBy!)].whereType<String>().join(' · '),
            trailing: Text(
              log.timestamp != null ? Formatters.dateTime(log.timestamp, locale) : (log.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<ComplianceEvent>(
          title: l10n.complianceEvents,
          section: detail.events,
          maxItems: 20,
          itemBuilder: (context, ev) => SectionRow(
            title: Formatters.humanize(ev.eventType),
            subtitle: ev.description,
            trailing: Text(
              ev.timestamp != null ? Formatters.dateTime(ev.timestamp, locale) : (ev.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
