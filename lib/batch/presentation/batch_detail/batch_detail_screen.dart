import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_radius.dart';
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
import '../../domain/entities/batch_status.dart';
import '../../domain/entities/batch_traceability.dart';
import '../../domain/entities/production_batch.dart';
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
          title: BlocBuilder<BatchDetailBloc, BatchDetailState>(
            builder: (context, state) {
              final batch = state.detail.data?.batch;
              return AppBarTitle(title: batch?.batchNumber ?? i18n.batchDetail, subtitle: batch?.productName);
            },
          ),
          actions: [
            BlocBuilder<BatchDetailBloc, BatchDetailState>(
              builder: (context, state) {
                final batch = state.detail.data?.batch;
                if (batch == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: Center(child: BatchStatusBadge(status: batch.status)),
                );
              },
            ),
          ],
          // Primary tabs: the three main views of the batch, icon + label.
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.info_outline), text: i18n.tabGeneral),
              Tab(icon: const Icon(Icons.account_tree_outlined), text: i18n.traceability),
              Tab(icon: const Icon(Icons.history), text: i18n.history),
            ],
          ),
        ),
        bottomNavigationBar: BlocBuilder<BatchDetailBloc, BatchDetailState>(
          builder: (context, state) {
            final batch = state.detail.data?.batch;
            if (!canReview || batch == null || !batch.isAwaitingReview) return const SizedBox.shrink();
            return _ReviewBar(batch: batch, submitting: state.submitting);
          },
        ),
        body: BlocConsumer<BatchDetailBloc, BatchDetailState>(
          listenWhen: (a, b) => a.actionStatus != b.actionStatus,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state.actionStatus == BatchActionStatus.success) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    state.lastAction == BatchReviewAction.release
                        ? i18n.batchReleasedMessage
                        : i18n.batchRejectedMessage,
                  ),
                ),
              );
            } else if (state.actionStatus == BatchActionStatus.failure && state.actionFailure != null) {
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.critical,
                  content: Text(failureMessage(context, state.actionFailure!)),
                ),
              );
            }
          },
          builder:
              (context, state) => RemoteStateView<BatchDetail>(
                state: state.detail,
                onRetry: () => context.read<BatchDetailBloc>().add(const BatchDetailRequested()),
                builder: (context, detail) {
                  Future<void> refresh() async =>
                      context.read<BatchDetailBloc>().add(const BatchDetailRequested(refresh: true));
                  String person(int userId) =>
                      userId == currentUserId ? i18n.you : (detail.people[userId] ?? i18n.userNumber(userId));
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
    final batch = detail.batch;
    final release = detail.traceability.release;
    final rejection = detail.traceability.rejection;
    final trace = detail.traceability;
    final hasEnd = batch.endDate?.isNotEmpty ?? false;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary: product, where the batch is in its cycle, and key data.
        InfoCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.medication_outlined, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.productName ?? '—',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (trace.productCode != null)
                          Text(
                            trace.productCode!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: AppTypography.monospace),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(i18n.batchCycle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              _BatchCycle(status: batch.status),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: KeyValue(
                      label: i18n.quantity,
                      value: '${Formatters.number(batch.quantity, locale)} ${batch.unit ?? ''}'.trim(),
                    ),
                  ),
                  Expanded(child: KeyValue(label: i18n.startDate, value: Formatters.rawDate(batch.startDate, locale))),
                  Expanded(
                    child: KeyValue(
                      label: i18n.endDate,
                      value: hasEnd ? Formatters.rawDate(batch.endDate, locale) : '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // What the batch was made with; each count opens the Traceability tab.
        Row(
          children: [
            Expanded(
              child: _TraceCount(
                icon: Icons.science_outlined,
                label: i18n.traceMaterials,
                count: trace.rawMaterials.length,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TraceCount(
                icon: Icons.precision_manufacturing_outlined,
                label: i18n.navEquipment,
                count: trace.equipment.length,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _TraceCount(icon: Icons.badge_outlined, label: i18n.traceStaff, count: trace.staff.length)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Shown only when there are notes: no empty "—" card.
        if (batch.notes?.isNotEmpty == true) InfoCard(title: i18n.bpmNotes, child: Text(batch.notes!)),
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
        // Release / reject live in the fixed bar at the bottom of the screen.
        if (!canReview && batch.isAwaitingReview) ...[
          const SizedBox(height: AppSpacing.md),
          Text(i18n.reviewRestricted, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// The batch cycle as steps: pending → in progress → QA decision (released
/// or rejected). Past steps are filled, the current one is outlined.
class _BatchCycle extends StatelessWidget {
  const _BatchCycle({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final current = switch (status) {
      BatchStatus.pending => 0,
      BatchStatus.inProgress => 1,
      BatchStatus.released || BatchStatus.rejected => 2,
      BatchStatus.unknown => -1,
    };
    final rejected = status == BatchStatus.rejected;
    final steps = [
      (i18n.batchPending, Icons.hourglass_empty),
      (i18n.batchInProgress, Icons.autorenew),
      (
        rejected ? i18n.batchRejected : (status == BatchStatus.released ? i18n.batchReleased : i18n.qaDecision),
        rejected ? Icons.block : Icons.verified_outlined,
      ),
    ];
    final accent = rejected ? AppColors.critical : AppColors.primaryDark;
    return Semantics(
      label: '${i18n.batchCycle}: ${status.label(i18n)}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(height: 2, color: i <= current ? accent : AppColors.border),
                ),
              ),
            SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          i < current || (i == current && i == steps.length - 1)
                              ? accent
                              : (i == current ? AppColors.primaryContainer : AppColors.neutralContainer),
                      border: i == current && i < steps.length - 1 ? Border.all(color: accent, width: 2) : null,
                    ),
                    child: Icon(
                      i < current ? Icons.check : steps[i].$2,
                      size: 16,
                      color:
                          i < current || (i == current && i == steps.length - 1)
                              ? Colors.white
                              : (i == current ? accent : AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    steps[i].$1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: i == current ? accent : AppColors.textMuted,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How many materials, equipment or people took part; opens Traceability.
class _TraceCount extends StatelessWidget {
  const _TraceCount({required this.icon, required this.label, required this.count});

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => DefaultTabController.of(context).animateTo(1),
        child: Semantics(
          button: true,
          label: '$label: $count',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
            child: Column(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryDark),
                const SizedBox(height: AppSpacing.xs),
                Text('$count', style: AppTypography.metric.copyWith(fontSize: 20)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed bottom bar with the QA decision, always within reach of the thumb
/// (and above the keyboard-free area), for the quality manager while the
/// batch awaits review.
class _ReviewBar extends StatelessWidget {
  const _ReviewBar({required this.batch, required this.submitting});

  final ProductionBatch batch;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<BatchDetailBloc>();
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
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('batch.reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical),
                      onPressed:
                          submitting
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
                      label: Text(i18n.rejectBatch),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('batch.release'),
                      onPressed:
                          submitting
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
                      label: Text(i18n.releaseBatch),
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
          itemBuilder:
              (context, u) => SectionRow(
                leading: const Icon(Icons.science_outlined, color: AppColors.primary),
                title: u.rawMaterialName ?? i18n.materialNumber(u.rawMaterialId),
                subtitle: [
                  [
                    Formatters.dateTime(u.usageDate, locale),
                    if (u.inventoryReceiptId != null) i18n.receiptNumber(u.inventoryReceiptId!),
                  ].join(' · '),
                  if (u.stockBefore != null || u.stockAfter != null)
                    i18n.stockBeforeAfter(
                      Formatters.number(u.stockBefore, locale),
                      Formatters.number(u.stockAfter, locale),
                    ),
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
          itemBuilder:
              (context, e) => SectionRow(
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
          itemBuilder:
              (context, s) => SectionRow(
                leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                title: s.staffName,
                subtitle: [s.staffRole, Formatters.dateTime(s.registeredAt, locale)].whereType<String>().join(' · '),
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: i18n.container,
          padding: EdgeInsets.zero,
          child:
              container == null
                  ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(i18n.noContainerAssigned))
                  // Same row style as the other traceability lists, tappable.
                  : InkWell(
                    onTap: () => context.push('/telemetry/history?deviceId=${container.containerMonitorId}'),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: SectionRow(
                              leading: const Icon(Icons.kitchen_outlined, color: AppColors.primary),
                              title: container.containerName ?? i18n.equipmentNumber(container.containerMonitorId),
                              subtitle: Formatters.dateTime(container.assignedAt, locale),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
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
