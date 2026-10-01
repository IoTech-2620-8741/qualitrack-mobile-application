import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../compliance/presentation/widgets/alert_widgets.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/failure_message.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../domain/batch.dart';
import '../bloc/batch_detail_bloc.dart';
import '../widgets/batch_labels.dart';
import '../widgets/batch_review_sheet.dart';

class BatchDetailPage extends StatelessWidget {
  const BatchDetailPage({super.key, required this.canReview});

  final bool canReview;

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
              Tab(text: l10n.rawMaterialsUsed),
              Tab(text: l10n.traceability),
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
                  state.lastAction == BatchReviewAction.release
                      ? l10n.batchReleasedMessage
                      : l10n.batchRejectedMessage,
                ),
              ));
            } else if (state.actionStatus == BatchActionStatus.failure &&
                state.actionFailure != null) {
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
              Future<void> refresh() async =>
                  context.read<BatchDetailBloc>().add(const BatchDetailRequested(refresh: true));
              return TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: refresh,
                    child: _GeneralTab(
                      batch: detail.batch,
                      canReview: canReview,
                      submitting: state.submitting,
                    ),
                  ),
                  RefreshIndicator(onRefresh: refresh, child: _RawMaterialsTab(detail: detail)),
                  RefreshIndicator(onRefresh: refresh, child: _TraceabilityTab(detail: detail)),
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
  const _GeneralTab({required this.batch, required this.canReview, required this.submitting});

  final ProductionBatch batch;
  final bool canReview;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final bloc = context.read<BatchDetailBloc>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(
          title: batch.batchNumber,
          subtitle: batch.productName,
          trailing: BatchStatusBadge(status: batch.status),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              KeyValue(label: l10n.product, value: batch.productName ?? '—'),
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
        const SizedBox(height: AppSpacing.md),
        if (canReview && batch.isAwaitingReview)
          InfoCard(
            title: l10n.qaReview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.qaReviewHint, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                if (submitting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                ],
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
                              final result = await showBatchReviewSheet(
                                context,
                                batch: batch,
                                action: BatchReviewAction.reject,
                              );
                              if (result != null) {
                                bloc.add(BatchRejectSubmitted(date: result.date, reason: result.text));
                              }
                            },
                      icon: const Icon(Icons.block_outlined),
                      label: Text(l10n.rejectBatch),
                    ),
                    FilledButton.icon(
                      key: const Key('batch.release'),
                      onPressed: submitting
                          ? null
                          : () async {
                              final result = await showBatchReviewSheet(
                                context,
                                batch: batch,
                                action: BatchReviewAction.release,
                              );
                              if (result != null) {
                                bloc.add(BatchReleaseSubmitted(date: result.date, notes: result.text));
                              }
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

class _RawMaterialsTab extends StatelessWidget {
  const _RawMaterialsTab({required this.detail});

  final BatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard<RawMaterialUsage>(
          title: l10n.rawMaterialUsageHistory,
          section: detail.rawMaterials,
          emptyMessage: l10n.rawMaterialsUsedEmpty,
          itemBuilder: (context, u) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionRow(
                leading: const Icon(Icons.science_outlined, color: AppColors.primary),
                title: u.rawMaterialName ?? l10n.materialNumber(u.rawMaterialId),
                subtitle: u.usageDate != null
                    ? Formatters.dateTime(u.usageDate, locale)
                    : (u.rawUsageDate ?? '—'),
                trailing: Text(
                  '${Formatters.number(u.quantityUsed, locale)} ${u.unit ?? ''}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (u.stockBefore != null || u.stockAfter != null || u.inventoryReceiptId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: AppSpacing.xs),
                  child: Text(
                    [
                      if (u.stockBefore != null || u.stockAfter != null)
                        l10n.stockBeforeAfter(
                          Formatters.number(u.stockBefore, locale),
                          Formatters.number(u.stockAfter, locale),
                        ),
                      if (u.inventoryReceiptId != null) l10n.receiptNumber(u.inventoryReceiptId!),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TraceabilityTab extends StatelessWidget {
  const _TraceabilityTab({required this.detail});

  final BatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard<DeviationAlert>(
          title: l10n.alertsTitle,
          section: detail.alerts,
          emptyMessage: l10n.batchNoAlerts,
          itemBuilder: (context, a) => AlertCard(
            alert: a,
            onTap: () => context.push('/alerts/${a.id}'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<ComplianceEvent>(
          title: l10n.complianceEvents,
          section: detail.events,
          maxItems: 15,
          itemBuilder: (context, ev) => SectionRow(
            title: Formatters.humanize(ev.eventType),
            subtitle: ev.description,
            trailing: Text(
              ev.timestamp != null ? Formatters.dateTime(ev.timestamp, locale) : (ev.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<AuditLogEntry>(
          title: l10n.auditLog,
          section: detail.auditLogs,
          maxItems: 15,
          itemBuilder: (context, log) => SectionRow(
            title: Formatters.humanize(log.action),
            subtitle: [
              log.details,
              if (log.performedBy != null) l10n.userNumber(log.performedBy!),
            ].whereType<String>().join(' · '),
            trailing: Text(
              log.timestamp != null ? Formatters.dateTime(log.timestamp, locale) : (log.rawTimestamp ?? '—'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
