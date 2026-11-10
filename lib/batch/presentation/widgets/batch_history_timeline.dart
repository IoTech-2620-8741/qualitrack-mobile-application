import 'package:flutter/material.dart';

import '../../../common/domain/failure.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/widgets/failure_message.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../batch_detail/batch_history.dart';

/// History of a batch as a timeline: what happened, its key detail, who did it
/// and when. Shows the newest [limit] entries until the user asks for the rest.
class BatchHistoryTimeline extends StatefulWidget {
  const BatchHistoryTimeline({super.key, required this.history, required this.person, this.limit = 20});

  final BatchHistory history;
  final String Function(int userId) person;
  final int limit;

  @override
  State<BatchHistoryTimeline> createState() => _BatchHistoryTimelineState();
}

class _BatchHistoryTimelineState extends State<BatchHistoryTimeline> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final history = widget.history;
    final total = history.entries.length;
    final shown = _showAll ? history.entries : history.entries.take(widget.limit).toList();
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (history.auditFailure != null) _FailureRow(source: i18n.auditLog, failure: history.auditFailure!),
          if (history.eventsFailure != null)
            _FailureRow(source: i18n.complianceEvents, failure: history.eventsFailure!),
          if (total == 0 && history.auditFailure == null && history.eventsFailure == null)
            Text(i18n.historyEmpty, style: theme.textTheme.bodySmall),
          for (var i = 0; i < shown.length; i++)
            _TimelineEntry(entry: shown[i], person: widget.person, last: i == shown.length - 1),
          if (shown.length < total) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(i18n.historyShowing(shown.length, total), style: theme.textTheme.bodySmall),
                ),
                TextButton(
                  key: const Key('batch.history.showAll'),
                  onPressed: () => setState(() => _showAll = true),
                  child: Text(i18n.seeMoreCount(total - shown.length)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.person, required this.last});

  final BatchHistoryEntry entry;
  final String Function(int userId) person;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final theme = Theme.of(context);
    final (icon, color) = _look(entry.kind);
    final detail = _detail(entry, i18n, locale) ?? entry.description;
    final when = entry.at != null ? Formatters.dateTime(entry.at, locale) : (entry.rawAt ?? '—');
    final meta = [if (entry.actorUserId != null) person(entry.actorUserId!), when].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (!last) Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs, bottom: last ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(entry, i18n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (detail != null && detail.isNotEmpty)
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      if (entry.fromCompliance) _ComplianceLabel(text: i18n.historyCompliance),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _look(BatchHistoryKind kind) => switch (kind) {
    BatchHistoryKind.created => (Icons.add_circle_outline, AppColors.primary),
    BatchHistoryKind.started => (Icons.play_circle_outline, AppColors.info),
    BatchHistoryKind.rawMaterialUsed => (Icons.science_outlined, AppColors.primary),
    BatchHistoryKind.equipmentRegistered => (Icons.precision_manufacturing_outlined, AppColors.primary),
    BatchHistoryKind.staffRegistered => (Icons.badge_outlined, AppColors.primary),
    BatchHistoryKind.released => (Icons.verified_outlined, AppColors.success),
    BatchHistoryKind.rejected => (Icons.block_outlined, AppColors.critical),
    BatchHistoryKind.stored => (Icons.kitchen_outlined, AppColors.info),
    BatchHistoryKind.blocked => (Icons.lock_outline, AppColors.warning),
    BatchHistoryKind.compliance => (Icons.report_problem_outlined, AppColors.warning),
    BatchHistoryKind.other => (Icons.history, AppColors.textMuted),
  };

  static String _title(BatchHistoryEntry entry, AppLocalizations i18n) => switch (entry.kind) {
    BatchHistoryKind.created => i18n.historyBatchCreated,
    BatchHistoryKind.started => i18n.historyBatchStarted,
    BatchHistoryKind.rawMaterialUsed => i18n.historyRawMaterialUsed,
    BatchHistoryKind.equipmentRegistered => i18n.historyEquipmentRegistered,
    BatchHistoryKind.staffRegistered => i18n.historyStaffRegistered,
    BatchHistoryKind.released => i18n.historyBatchReleased,
    BatchHistoryKind.rejected => i18n.historyBatchRejected,
    BatchHistoryKind.stored => i18n.historyBatchStored,
    BatchHistoryKind.blocked => i18n.historyBatchBlocked,
    BatchHistoryKind.compliance || BatchHistoryKind.other => entry.label,
  };

  /// The key value of the event; null when it has none, so the description is shown instead.
  static String? _detail(BatchHistoryEntry entry, AppLocalizations i18n, String locale) {
    final values = entry.values;
    switch (entry.kind) {
      case BatchHistoryKind.rawMaterialUsed:
        final quantity = double.tryParse(values['quantityUsed'] ?? '');
        final amount =
            quantity == null ? null : '${Formatters.number(quantity, locale)} ${values['unit'] ?? ''}'.trim();
        final parts = [values['rawMaterialName'], amount].whereType<String>();
        return parts.isEmpty ? null : parts.join(' · ');
      case BatchHistoryKind.equipmentRegistered || BatchHistoryKind.staffRegistered:
        return values['resourceName'];
      case BatchHistoryKind.released:
        final date = values['releaseDate'];
        return date == null ? null : i18n.historyDecisionDate(Formatters.rawDate(date, locale));
      case BatchHistoryKind.rejected:
        return values['reason'];
      case BatchHistoryKind.stored:
        return values['containerName'];
      case BatchHistoryKind.created ||
          BatchHistoryKind.started ||
          BatchHistoryKind.blocked ||
          BatchHistoryKind.compliance ||
          BatchHistoryKind.other:
        return null;
    }
  }
}

class _ComplianceLabel extends StatelessWidget {
  const _ComplianceLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.warning),
      ),
    );
  }
}

class _FailureRow extends StatelessWidget {
  const _FailureRow({required this.source, required this.failure});

  final String source;
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$source: ${failureMessage(context, failure)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.critical),
            ),
          ),
        ],
      ),
    );
  }
}
