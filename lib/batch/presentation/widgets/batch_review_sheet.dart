import 'package:flutter/material.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/confirm_dialog.dart';
import '../../domain/entities/production_batch.dart';
import '../batch_detail/bloc/batch_detail_state.dart';

final class BatchReviewInput {
  const BatchReviewInput({required this.date, required this.text});

  final DateTime date;
  final String text;
}

/// Release/Reject form (mockups "Release Batch" / "Reject Batch"). It asks
/// only for the fields required by `PATCH /batches/{id}` and confirms before
/// returning the input.
Future<BatchReviewInput?> showBatchReviewSheet(
  BuildContext context, {
  required ProductionBatch batch,
  required BatchReviewAction action,
}) {
  return showModalBottomSheet<BatchReviewInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _BatchReviewForm(batch: batch, action: action),
    ),
  );
}

class _BatchReviewForm extends StatefulWidget {
  const _BatchReviewForm({required this.batch, required this.action});

  final ProductionBatch batch;
  final BatchReviewAction action;

  @override
  State<_BatchReviewForm> createState() => _BatchReviewFormState();
}

class _BatchReviewFormState extends State<_BatchReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  DateTime _date = DateTime.now();

  bool get _isRelease => widget.action == BatchReviewAction.release;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // The decision cannot be dated before the batch started.
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.batch.firstDecisionDay(now),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final i18n = context.i18n;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: _isRelease ? i18n.releaseBatch : i18n.rejectBatch,
      message: _isRelease
          ? i18n.releaseConfirm(widget.batch.batchNumber)
          : i18n.rejectConfirm(widget.batch.batchNumber),
      confirmLabel: _isRelease ? i18n.releaseBatch : i18n.rejectBatch,
      destructive: !_isRelease,
    );
    if (!confirmed || !mounted) return;
    navigator.pop(BatchReviewInput(date: _date, text: _text.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final theme = Theme.of(context);
    final color = _isRelease ? AppColors.primary : AppColors.critical;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_isRelease ? Icons.verified_outlined : Icons.block_outlined, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isRelease ? i18n.releaseBatch : i18n.rejectBatch,
                    style: theme.textTheme.titleLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.batch.batchNumber} · ${widget.batch.productName ?? ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                '${_isRelease ? i18n.releaseDate : i18n.rejectionDate}: '
                '${Formatters.date(_date, context.localeName)}',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('batch.reviewText'),
              controller: _text,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _isRelease ? i18n.qualityReleaseNotes : i18n.rejectionReason,
                hintText: _isRelease ? i18n.releaseNotesHint : i18n.rejectionReasonHint,
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) {
                  return _isRelease ? i18n.releaseNotesRequired : i18n.rejectionReasonRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(i18n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('batch.reviewSubmit'),
                    style: _isRelease ? null : FilledButton.styleFrom(backgroundColor: AppColors.critical),
                    onPressed: _submit,
                    child: Text(_isRelease ? i18n.releaseBatch : i18n.rejectBatch),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
