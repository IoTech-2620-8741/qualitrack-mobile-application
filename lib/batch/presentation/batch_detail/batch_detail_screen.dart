import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/application/section.dart';
import '../../domain/entities/batch_traceability.dart';
import '../widgets/batch_labels.dart';
import '../widgets/batch_history_timeline.dart';
import '../widgets/batch_review_sheet.dart';
import 'batch_history.dart';
import 'bloc/bloc.dart';

/// Batch detail with its traceability. Only quality managers release or
/// reject a batch ([canReview]); the backend validates the decision.
class BatchDetailScreen extends StatelessWidget {
  const BatchDetailScreen({super.key, required this.canReview, required this.currentUserId});

  final bool canReview;
  final int? currentUserId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(i18n.batchDetail),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: i18n.generalInformation),
              Tab(text: i18n.traceability),
              Tab(text: i18n.history),
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
                  state.lastAction == BatchReviewAction.release ? i18n.batchReleasedMessage : i18n.batchRejectedMessage,
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
                  ? i18n.you
                  : (detail.people[userId] ?? i18n.userNumber(userId));
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
    final i18n = context.i18n;
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
                label: i18n.product,
                value: [detail.traceability.productCode, batch.productName].whereType<String>().join(' · '),
              ),
              KeyValue(
                label: i18n.quantity,
                value: '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim(),
              ),
              KeyValue(label: i18n.startDate, value: Formatters.rawDate(batch.startDate, locale)),
              if (batch.endDate?.isNotEmpty ?? false)
                KeyValue(label: i18n.endDate, value: Formatters.rawDate(batch.endDate, locale)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: i18n.bpmNotes,
          child: Text(batch.notes?.isNotEmpty == true ? batch.notes! : '—'),
        ),
        if (release != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: i18n.digitalSignature,
            color: AppColors.successContainer,
            borderColor: AppColors.success.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValue(label: i18n.signedBy, value: person(release.signedByUserId)),
                const SizedBox(height: AppSpacing.sm),
                KeyValue(label: i18n.signedAt, value: Formatters.dateTime(release.signedAt, locale)),
                const SizedBox(height: AppSpacing.sm),
                Text(i18n.signatureHash, style: Theme.of(context).textTheme.bodySmall),
                _SignatureHash(hash: release.signatureHash),
              ],
            ),
          ),
        ],
        if (rejection != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: i18n.rejectionReason,
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
            title: i18n.qaReview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(i18n.qaReviewHint, style: Theme.of(context).textTheme.bodySmall),
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
                      label: Text(i18n.rejectBatch),
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
                      label: Text(i18n.releaseBatch),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (!canReview && batch.isAwaitingReview)
          Text(i18n.reviewRestricted, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TraceabilityTab extends StatelessWidget {
  const _TraceabilityTab({required this.traceability});

  final BatchTraceability traceability;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final container = traceability.container;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard<RawMaterialUsage>(
          title: i18n.rawMaterialsUsed,
          section: Section(traceability.rawMaterials),
          emptyMessage: i18n.rawMaterialsUsedEmpty,
          itemBuilder: (context, u) => SectionRow(
            leading: const Icon(Icons.science_outlined, color: AppColors.primary),
            title: u.rawMaterialName ?? i18n.materialNumber(u.rawMaterialId),
            subtitle: [
              [
                Formatters.dateTime(u.usageDate, locale),
                if (u.inventoryReceiptId != null) i18n.receiptNumber(u.inventoryReceiptId!),
              ].join(' · '),
              if (u.stockBefore != null || u.stockAfter != null)
                i18n.stockBeforeAfter(Formatters.number(u.stockBefore, locale), Formatters.number(u.stockAfter, locale)),
            ].join('\n'),
            trailing: Text(
              '${Formatters.number(u.quantityUsed, locale)} ${u.unit ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<BatchEquipmentUsage>(
          title: i18n.equipmentUsed,
          section: Section(traceability.equipment),
          emptyMessage: i18n.noEquipmentUsed,
          itemBuilder: (context, e) => SectionRow(
            leading: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.primary),
            title: e.equipmentName,
            subtitle: Formatters.dateTime(e.registeredAt, locale),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<BatchStaffParticipation>(
          title: i18n.participatingStaff,
          section: Section(traceability.staff),
          emptyMessage: i18n.noParticipatingStaff,
          itemBuilder: (context, s) => SectionRow(
            leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
            title: s.staffName,
            subtitle: [s.staffRole, Formatters.dateTime(s.registeredAt, locale)].whereType<String>().join(' · '),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: i18n.container,
          child: container == null
              ? Text(i18n.noContainerAssigned)
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.kitchen_outlined, color: AppColors.primary),
                  title: Text(container.containerName ?? i18n.equipmentNumber(container.containerMonitorId)),
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        BatchHistoryTimeline(
          history: BatchHistory.of(auditLogs: detail.auditLogs, events: detail.events),
          person: person,
        ),
      ],
    );
  }
}

/// Release signature hash, shortened, with a button that copies it whole.
class _SignatureHash extends StatelessWidget {
  const _SignatureHash({required this.hash});

  final String hash;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final short = hash.length > 24 ? '${hash.substring(0, 12)}…${hash.substring(hash.length - 8)}' : hash;
    return Row(
      children: [
        Expanded(
          child: Text(
            short,
            semanticsLabel: hash,
            style: const TextStyle(fontFamily: AppTypography.monospace, fontSize: 12),
          ),
        ),
        IconButton(
          key: const Key('batch.copySignatureHash'),
          tooltip: i18n.copySignatureHash,
          icon: const Icon(Icons.copy_outlined, size: 18),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: hash));
            messenger.showSnackBar(SnackBar(content: Text(i18n.signatureHashCopied)));
          },
        ),
      ],
    );
  }
}
